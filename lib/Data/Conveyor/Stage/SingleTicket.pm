package Data::Conveyor::Stage::SingleTicket;

# $Id: SingleTicket.pm 13653 2007-10-22 09:11:20Z gr $

# Base class for stages handling a single ticket (i.e., policy or delegation,
# but not queue).
#
# To use it, create an object of this class, set the ticket and
# call run(). You can then read the status the stage's ticket and act on it.

use warnings;
use strict;
use Error::Hierarchy::Util 'assert_defined';


our $VERSION = '0.09';


use base 'Data::Conveyor::Stage';


__PACKAGE__
    ->mk_framework_object_accessors(
        ticket         => 'ticket',
        stage_delegate => 'stage_delegate',
    )
    ->mk_scalar_accessors(qw(expected_stage log_max_level_previous));


sub MUNGE_CONSTRUCTOR_ARGS {
    my ($self, @args) = @_;
    @args = $self->SUPER::MUNGE_CONSTRUCTOR_ARGS(@args);
    push @args =>
        (stage_delegate => $self->delegate->make_delegate('stage_delegate'));
    @args;
}


sub main {
    my ($self, %args) = @_;
    $self->SUPER::main(%args);

    assert_defined $self->expected_stage, 'called without set expected_stage.';
    assert_defined $self->ticket, 'called without set ticket.';

    # Remember the log's previous max_level settings and temporarily (until
    # the end of the ticket stage) set the log's max_level to the one
    # indicated by the ticket. This mechanism can be used to increase a faulty
    # ticket's log level from the regsh so that verbose information can be
    # seen in the log. But only override with the ticket's log level if it is
    # higher than the current log level; we don't want a ticket to actually
    # reduce the current log level.

    $self->log_max_level_previous($self->log->max_level);

    if ($self->ticket->get_log_level > $self->log->max_level) {
        $self->log->max_level($self->ticket->get_log_level);
    }

    unless ($self->ticket->stage->name eq $self->expected_stage) {
        throw Data::Conveyor::Exception::Ticket::InvalidStage(
            stage => $self->ticket->stage,
        );
    }
}


sub end {
    my $self = shift;

    # After handling all exceptions, if the ticket status is anything else
    # than TS_RUNNING, but the rc is RC_ERROR, set the status to TS_RUNNING so
    # that the ticket gets passed on to the notify stage.
    #
    # The reason is that we don't want erroneous tickets to be left on hold.
    # If there's a reason it would normally go on hold and another reason it's
    # erroneous, the error takes precedence.

    $self->ticket->status($self->delegate->TS_RUNNING) if
        $self->ticket->rc eq $self->delegate->RC_ERROR;

    $self->stage_delegate->handle_stage_end($self);

    # restore the log's previous max_level setting.

    $self->log->max_level($self->log_max_level_previous);
    $self->ticket->store;
}


1;


__END__



=head1 NAME

Data::Conveyor::Stage::SingleTicket - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Stage::SingleTicket->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_expected_stage>

    $obj->clear_expected_stage;

Clears the value.

=item C<clear_log_max_level_previous>

    $obj->clear_log_max_level_previous;

Clears the value.

=item C<expected_stage>

    my $value = $obj->expected_stage;
    $obj->expected_stage($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<expected_stage_clear>

    $obj->expected_stage_clear;

Clears the value.

=item C<log_max_level_previous>

    my $value = $obj->log_max_level_previous;
    $obj->log_max_level_previous($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<log_max_level_previous_clear>

    $obj->log_max_level_previous_clear;

Clears the value.

=back

Data::Conveyor::Stage::SingleTicket inherits from L<Data::Conveyor::Stage>.

The superclass L<Data::Conveyor::Stage> defines these methods and
functions:

    begin(), clear_will_shift_ticket(), run(), will_shift_ticket(),
    will_shift_ticket_clear()

The superclass L<Class::Scaffold::Storable> defines these methods and
functions:

    clear_storage_info(), clear_storage_type(), delete_storage_info(),
    exists_storage_info(), id(), keys_storage_info(), storage(),
    storage_info(), storage_info_clear(), storage_info_delete(),
    storage_info_exists(), storage_info_keys(), storage_info_values(),
    storage_type(), storage_type_clear(), values_storage_info()

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

