package Data::Conveyor::Ticket;

# $Id: Ticket.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Data::Miscellany 'is_defined';
use Error::Hierarchy;
use Error::Hierarchy::Util qw/assert_defined assert_is_integer assert_getopt/;
use Data::Dumper;   # needed for service method 'data_dump'
use Error ':try';
use Hash::Flatten;
use Class::Value::Exception::NotWellFormedValue;


our $VERSION = '0.08';


use base 'Class::Scaffold::Storable';


__PACKAGE__
    ->mk_abstract_accessors(qw(request_as_string))
    ->mk_framework_object_accessors(
        ticket_payload           => 'payload',
        ticket_facets            => 'facets',
        value_ticket_stage       => 'stage',
        value_ticket_type        => 'type',
        value_ticket_origin      => 'origin',
        value_ticket_number      => 'ticket_no',
        value_ticket_rc          => 'rc',
        value_ticket_status      => 'status',
    )
    ->mk_scalar_accessors(qw(received_date));


sub key { $_[0]->ticket_no }


sub assert_ticket_no {
    my $self = shift;
    local $Error::Depth = $Error::Depth + 1;
    assert_defined $self->ticket_no, 'called without defined ticket number';
}


sub read {
    my $self = shift;
    $self->assert_ticket_no;
    $self->storage->ticket_read_from_object($self);
}


# generates new ticket

sub gen_ticket_no {
    my $self = shift;

    my $ticket_no = $self->storage->generate_ticket_no;
    try {
        $self->ticket_no($ticket_no);
    } catch Class::Value::Exception::NotWellFormedValue with {
        throw Data::Conveyor::Exception::Ticket::GenFailed(
            ticket_no => $ticket_no
        );
    };

    # don't return $ticket_no; the value object might have normalized the
    # value
    $self->ticket_no;
}


# opens (sets the stage on 'aktiv_[% stage %]') either given ticket or
# the oldest ticket in given stage. sets $self->ticket_no on success
# or throws Data::Conveyor::Exception::Ticket::NoSuchTicket otherwise.
#
# if a ticket has been opened, it will be read.
#
# NOTE: this method commits (but respects the rollback flag).
#
# accepts one parameter:
#     stage_name [mandatory]
#
# fails if stage isn't given.

sub open {
    my ($self, $stage_name) = @_;

    assert_defined $stage_name, 'called without stage name.';

    my ($new_stage, $ticket_no) = $self->storage->ticket_open(
        $stage_name, $self->ticket_no);

    if (is_defined($ticket_no)) {
        $self->stage($new_stage);
        $self->ticket_no($ticket_no);
        $self->read;
        $self->reset_default_rc_and_status;
    } else {
        $self->log->debug('HINT: Does the ticket have all required fields?');

        throw Data::Conveyor::Exception::Ticket::NoSuchTicket(
           ticket_no => $self->ticket_no || 'n/a',
           stage     => $stage_name,
        );
    }
}


sub try_open {
    my $self = shift;

    assert_defined $self->$_, sprintf "called without %s argument.", $_
        for qw/ticket_no stage rc status/;

    my $ticket_no = $self->storage->ticket_set_active($self);
    return unless defined $ticket_no && $ticket_no eq $self->ticket_no;

    $self->read;
    $self->reset_default_rc_and_status;
    1;
}


# stores the whole ticket.

sub store {
    my $self = shift;

    $self->assert_ticket_no;

    $self->update_calculated_values;
    $self->storage->ticket_store($self);
    $self->storage->facets_store($self);
}


# Store everything about the ticket. Used by test code when we want to make
# sure everything we specified in the YAML test files gets stored. Here we
# just store the ticket itself; subclasses can add their things.

sub store_full {
    my $self = shift;
    $self->store;
}


# Writes the ticket's stage, status, and rc to the database, and ensures that
# the new stage is the end_* version of the current stage.

sub close {
    my $self = shift;

    $self->assert_ticket_no;
    assert_defined $self->stage, 'called without set stage.';
    assert_defined $self->rc, 'called without set returncode.';
    assert_defined $self->status, 'called without set status.';

    unless ($self->stage->is_active) {
        throw Data::Conveyor::Exception::Ticket::InvalidStage(
           stage => $self->stage,
        );
    }

    $self->stage->set_end;
    $self->close_basic;
}


# Sets only stage, rc and status.
# Low-level method that can be called instead of close() when you want to set
# the ticket to some other stage, rc and status than close() would mandate.

sub close_basic {
    my $self = shift;
    $self->storage->ticket_close($self);
}


# Does this ticket ignore the given exception?
# Fails if the exception name isn't provided.

sub ignores_exception {
    my ($self, $exception) = @_;

    # we ignore it if it is acknowledged
    if (ref $exception && UNIVERSAL::can($exception, 'acknowledged')) {
        return 1 if $exception->acknowledged;
    }
}


# XXX: could this, along with wrote_billing_lock and other methods, be
# forwarded directly to $self->payload->common->* ?

sub set_log_level {
    my ($self, $log_level) = @_;
    assert_is_integer($log_level);
    $self->payload->common->log_level($log_level);
}


sub get_log_level {
    my $self = shift;
    $self->payload->common->log_level || 1;
}


# shifts a ticket to the next stage.
#
# fails if the ticket_no isn't defined.

sub shift_stage {
    my $self = shift;
    $self->assert_ticket_no;

    # Can't shift to an undefined stage -> do nothing in this case. Could
    # happen if a ticket has RC_INTERNAL_ERROR, for example.

    # get_next_stage() now returns an arrayref with [ stage-object,
    # status-constant-name ] so the special stati E,D can be supported by
    # shift at the end of the ticket lifecycle.  status is undefined if
    # nothing was specified in the memory storage's mapping.

    if (my $transition = $self->delegate->make_obj('ticket_transition')->
            get_next_stage($self->stage, $self->rc)) {
        my $status = $transition->[1];
        $self->stage($transition->[0]);
        $self->status($self->delegate->$status) if defined $status;
        $self->storage->ticket_update_stage($self);
    }
}


# service method

sub object_tickets {
    my ($self, $object, $limit) = @_;
    $self->delegate->make_obj('service_result_tabular')->set_from_rows(
        limit  => $limit,
        fields => [ qw/ticket_no stage status ticket_type origin 
                       real effective cdate mdate/ ],
        rows   => scalar $self->storage->get_object_tickets(
            $object, $limit,
        ),
    );
}


sub sif_dump {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    $self->ticket_no($opt{ticket});
    $self->read;
    my $dump = $opt{raw} ? Dumper($self) : scalar($self->dump_comparable);
    $self->delegate->make_obj('service_result_scalar', result => $dump);
}


sub sif_ydump {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    $self->ticket_no($opt{ticket});
    $self->read;
    $self->delegate->make_obj('service_result_scalar', result =>
        $self->yaml_dump_comparable);
}


sub sif_exceptions {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    $self->ticket_no($opt{ticket});
    $self->read;
    local $Data::Dumper::Indent = 1;
    my $container = $self->payload->get_all_exceptions;

    $self->delegate->make_obj('service_result_scalar', result =>
        $opt{raw} ? Dumper($container) : "$container\n");
}


sub sif_clear_exceptions {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    $self->ticket_no($opt{ticket});
    $self->read;
    $self->payload->clear_all_exceptions;
    $self->store;
    $self->delegate->make_obj('service_result_scalar', result => 'OK');
}


sub sif_exceptions_structured {
    my ($self, %args) = @_;
    my $result = $self->delegate->make_obj('service_result_scalar');

    $self->ticket_no($args{ticket});
    $self->read;

    my $res = {};

    for my $ot ($args{object} || $self->delegate->OT, 'common') {
        my $item_count = 1;
        for my $item ($ot eq 'common' ? $self->payload->common : 
                $self->payload->get_list_for_object_type($ot)) {

            my $h_item = sprintf "%s.%s", $ot, $item_count++;
            $res->{$h_item}=[];
            for my $E ($item->exception_container->items) {
                my $ex = {
                    class => ref $E,
                    uuid  => $E->uuid,
                    attrs => {
                        map { $_ => $E->$_ } $E->get_properties
                    }
                };
                push(@{$res->{$h_item}}, $ex);
            }
        }
    }
    $self->delegate->make_obj('service_result_scalar', result => $res);
}


sub sif_delete_exception {
    my ($self, %args) = @_;

    $self->ticket_no($args{ticket});
    $self->read;
    $self->payload->delete_by_uuid($args{uuid});
    $self->store;
    $self->delegate->make_obj('service_result_scalar');
}


sub sif_journal {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    $self->ticket_no($opt{ticket});
    $self->delegate->make_obj('service_result_tabular')->set_from_rows(
        rows   => scalar $self->storage->get_ticket_journal($self),
        fields => [ qw/stage status rc ts osuser oshost/ ],
    );
}


# This is a service method, which doesn't just set the state attribute, so it
# gets its own method (as opposed to just setting state() from within a
# service interface).
#
# FIXME: Doesn't write sif log yet.

sub sif_set_stage {
    my ($self, %opt) = @_;
    assert_getopt $opt{ticket}, 'Called without ticket number.';
    assert_getopt $opt{stage}, 'Called without stage.';
    $self->ticket_no($opt{ticket});
    $self->read;
    my $prev_stage = $self->stage;
    $self->stage($opt{stage});
    $self->store;
    $self->delegate->make_obj('service_result_scalar', result =>
        sprintf "Ticket [%s]: Previous stage [%s]\n",
            $self->ticket_no, $prev_stage);
}


sub sif_get_ticket_payload {
    my ($self, %args) = @_;
    my $ticket = $self->delegate->make_obj('ticket', );
    my $res = {};
    $ticket->ticket_no($args{ticket});
    $ticket->read;
    for my $object_type ($self->delegate->OT) {
        next if $object_type eq $self->delegate->OT_LOCK;
        next if $object_type eq $self->delegate->OT_TRANSACTION;

        for my $payload_item (
            $ticket->payload->get_list_for_object_type($object_type)) {

            my $pref = $payload_item->comparable(1);
            $pref = Hash::Flatten::flatten $pref;
            $res->{$object_type} = $pref;
        }
    }

    foreach my $facet (
        qw/authoritative_registrar ignore_exceptions_as_registrar/) {

        $res->{facets}->{$facet} =
            sprintf("%s", $ticket->facets->$facet->protocol_id);
    }

    $res->{protokoll_id} = $ticket->registrar->protocol_id; 
    $self->delegate->make_obj('service_result_scalar', result => $res);
}



# rc and status are only updated from the payload; call this before storing
# the ticket whenever you change the payload's exception containers. This way,
# when you remove an exception (e.g., via a service interface), it has a
# direct effect on the ticket's rc and status.
#
# The ticket is passed to the payload method so it can pass it to the methods
# it calls; eventually the exception container will ask the ticket whether to
# ignore each exception it processes (cf. ignores_exception).

sub update_calculated_values {
    my $self = shift;
    $self->payload->update_transaction_stati($self);
    $self->calculate_status;  # calculates rc as well
}


sub calculate_rc {
    my $self = shift;
    $self->rc($self->payload->rc($self));
}


sub calculate_status {
    my $self = shift;

    $self->calculate_rc;   # since status depends on the rc

    my $status = sprintf "%s", $self->payload->status($self);
    if ($self->stage eq $self->delegate->FINAL_TICKET_STAGE) {
        $status = $self->rc eq $self->delegate->RC_ERROR
            ? $self->delegate->TS_ERROR
            : $self->delegate->TS_DONE;
    }
    $self->status($status);
}


sub set_default_rc {
    my ($self, $rc) = @_;
    assert_defined $rc, 'called without rc.';
    $self->payload->common->default_rc($rc);
}


sub set_default_status {
    my ($self, $status) = @_;
    assert_defined $status, 'called without status.';
    $self->payload->common->default_status($status);
}


sub reset_default_rc_and_status {
    my $self = shift;
    my $new_common = $self->delegate->make_obj('payload_common');
    $self->payload->common->default_rc($new_common->default_rc);
    $self->payload->common->default_status($new_common->default_status);
}


sub check {
    my $self = shift;
    $self->payload->check($self);
    $self->facets->check($self);
}


sub filter_exceptions_by_rc {
    my ($self, @filter) = @_;
    $self->payload->filter_exceptions_by_rc($self, @filter);
}


sub filter_exceptions_by_status {
    my ($self, @filter) = @_;
    $self->payload->filter_exceptions_by_status($self, @filter);
}


sub delete {
    my $self = shift;
    $self->assert_ticket_no;
    $self->storage->ticket_delete($self);
}


sub store_facets {
    my $self = shift;
    $self->facets->store($self);
}


sub read_facets {
    my $self = shift;
    $self->facets->read($self);
    $self->facets;
}


# don't call this delete_facets, because framework_object already generates a
# 'delete_*' method.

sub remove_facets {
    my $self = shift;
    $self->facets->delete($self);
}


1;


__END__



=head1 NAME

Data::Conveyor::Ticket - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Ticket->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_received_date>

    $obj->clear_received_date;

Clears the value.

=item C<received_date>

    my $value = $obj->received_date;
    $obj->received_date($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<received_date_clear>

    $obj->received_date_clear;

Clears the value.

=back

Data::Conveyor::Ticket inherits from L<Class::Scaffold::Storable>.

The superclass L<Class::Scaffold::Storable> defines these methods and
functions:

    MUNGE_CONSTRUCTOR_ARGS(), clear_storage_info(), clear_storage_type(),
    delete_storage_info(), exists_storage_info(), id(),
    keys_storage_info(), storage(), storage_info(), storage_info_clear(),
    storage_info_delete(), storage_info_exists(), storage_info_keys(),
    storage_info_values(), storage_type(), storage_type_clear(),
    values_storage_info()

The superclass L<Class::Scaffold::Base> defines these methods and
functions:

    new(), FIRST_CONSTRUCTOR_ARGS(), add_autoloaded_package(), init(),
    log()

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

The superclass L<Data::Comparable> defines these methods and functions:

    comparable(), comparable_scalar(), dump_comparable(),
    prepare_comparable(), yaml_dump_comparable()

The superclass L<Class::Scaffold::Delegate::Mixin> defines these methods
and functions:

    delegate()

The superclass L<Class::Scaffold::Accessor> defines these methods and
functions:

    mk_framework_object_accessors(), mk_framework_object_array_accessors(),
    mk_readonly_accessors()

The superclass L<Class::Accessor::Complex> defines these methods and
functions:

    mk_abstract_accessors(), mk_array_accessors(), mk_boolean_accessors(),
    mk_class_array_accessors(), mk_class_hash_accessors(),
    mk_class_scalar_accessors(), mk_concat_accessors(),
    mk_forward_accessors(), mk_hash_accessors(), mk_integer_accessors(),
    mk_new(), mk_object_accessors(), mk_scalar_accessors(),
    mk_set_accessors(), mk_singleton()

The superclass L<Class::Accessor> defines these methods and functions:

    _carp(), _croak(), _mk_accessors(), accessor_name_for(),
    best_practice_accessor_name_for(), best_practice_mutator_name_for(),
    follow_best_practice(), get(), make_accessor(), make_ro_accessor(),
    make_wo_accessor(), mk_accessors(), mk_ro_accessors(),
    mk_wo_accessors(), mutator_name_for(), set()

The superclass L<Class::Accessor::Installer> defines these methods and
functions:

    install_accessor()

The superclass L<Class::Accessor::Constructor> defines these methods and
functions:

    _make_constructor(), mk_constructor(), mk_constructor_with_dirty(),
    mk_singleton_constructor()

The superclass L<Class::Accessor::FactoryTyped> defines these methods and
functions:

    clear_factory_typed_accessors(), clear_factory_typed_array_accessors(),
    count_factory_typed_accessors(), count_factory_typed_array_accessors(),
    factory_typed_accessors(), factory_typed_accessors_clear(),
    factory_typed_accessors_count(), factory_typed_accessors_index(),
    factory_typed_accessors_pop(), factory_typed_accessors_push(),
    factory_typed_accessors_set(), factory_typed_accessors_shift(),
    factory_typed_accessors_splice(), factory_typed_accessors_unshift(),
    factory_typed_array_accessors(), factory_typed_array_accessors_clear(),
    factory_typed_array_accessors_count(),
    factory_typed_array_accessors_index(),
    factory_typed_array_accessors_pop(),
    factory_typed_array_accessors_push(),
    factory_typed_array_accessors_set(),
    factory_typed_array_accessors_shift(),
    factory_typed_array_accessors_splice(),
    factory_typed_array_accessors_unshift(),
    index_factory_typed_accessors(), index_factory_typed_array_accessors(),
    mk_factory_typed_accessors(), mk_factory_typed_array_accessors(),
    pop_factory_typed_accessors(), pop_factory_typed_array_accessors(),
    push_factory_typed_accessors(), push_factory_typed_array_accessors(),
    set_factory_typed_accessors(), set_factory_typed_array_accessors(),
    shift_factory_typed_accessors(), shift_factory_typed_array_accessors(),
    splice_factory_typed_accessors(),
    splice_factory_typed_array_accessors(),
    unshift_factory_typed_accessors(),
    unshift_factory_typed_array_accessors()

The superclass L<Class::Scaffold::Factory::Type> defines these methods and
functions:

    factory_log()

The superclass L<Class::Factory::Enhanced> defines these methods and
functions:

    add_factory_type(), make_object_for_type(), register_factory_type()

The superclass L<Class::Factory> defines these methods and functions:

    factory_error(), get_factory_class(), get_factory_type_for(),
    get_loaded_classes(), get_loaded_types(), get_my_factory(),
    get_my_factory_type(), get_registered_class(),
    get_registered_classes(), get_registered_types(),
    remove_factory_type(), unregister_factory_type()

The superclass L<Class::Accessor::Constructor::Base> defines these methods
and functions:

    STORE(), clear_dirty(), clear_hygienic(), clear_unhygienic(),
    contains_hygienic(), contains_unhygienic(), delete_hygienic(),
    delete_unhygienic(), dirty(), dirty_clear(), dirty_set(),
    elements_hygienic(), elements_unhygienic(), hygienic(),
    hygienic_clear(), hygienic_contains(), hygienic_delete(),
    hygienic_elements(), hygienic_insert(), hygienic_is_empty(),
    hygienic_size(), insert_hygienic(), insert_unhygienic(),
    is_empty_hygienic(), is_empty_unhygienic(), set_dirty(),
    size_hygienic(), size_unhygienic(), unhygienic(), unhygienic_clear(),
    unhygienic_contains(), unhygienic_delete(), unhygienic_elements(),
    unhygienic_insert(), unhygienic_is_empty(), unhygienic_size()

The superclass L<Tie::StdHash> defines these methods and functions:

    CLEAR(), DELETE(), EXISTS(), FETCH(), FIRSTKEY(), NEXTKEY(), SCALAR(),
    TIEHASH()

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHORS

Florian Helmberger C<< <fh@univie.ac.at> >>

Achim Adam C<< <ac@univie.ac.at> >>

Mark Hofstetter C<< <mh@univie.ac.at> >>

Heinz Ekker C<< <ek@univie.ac.at> >>

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2009 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

