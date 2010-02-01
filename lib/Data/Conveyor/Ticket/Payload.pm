package Data::Conveyor::Ticket::Payload;

# ptags: DCTP
# $Id: Payload.pm 13653 2007-10-22 09:11:20Z gr $
#
# This class houses the ticket payload objects
use warnings;
use strict;
use Error::Hierarchy::Util 'assert_defined';
use Data::Miscellany 'flatten';
use once;
our $VERSION = '0.11';
use base qw(
  Class::Scaffold::Storable
  Class::Scaffold::HierarchicalDirty
);
__PACKAGE__->mk_scalar_accessors(qw(version))
  ->mk_framework_object_accessors(payload_common => 'common')
  ->mk_framework_object_array_accessors(
    payload_transaction => 'transactions',
    payload_lock        => 'locks',
  );

# Generate add_* methods for each payload item. The method can be called in
# various ways:
#
# 1) Without any arguments: will push a new and empty payload item into the
# according payload item list.
#
# 2) With an payload item data object (eg. a Registry::Person) as first
# argument: will push the given object into the according payload item list.
#
# 3) With any number of arguments of which the first one isn't a reference:
# will create a new payload item with given arguments passed to the
# constructor. This item is pushed into the according payload item list.
sub generate_add_method {
    my ($self, $object_type, $method, $payload_object_type, $push_method) = @_;

    # FIXME: these PTAGS aren't going to work, as the methods are only
    # generated when the application is really running, not when ptags
    # loads the module.
    no strict 'refs';
    $::PTAGS && $::PTAGS->add_tag($method, __FILE__, __LINE__ + 1);
    *$method = sub {
        my $self           = shift;
        my $payload_object = $self->delegate->make_obj($payload_object_type);

        # If at least one argument is given, check if it's a reference. If
        # it is, use it as our object to set, Otherwise create a new
        # payload item supplying all the arguments we might have gotten.
        my $object =
          defined $_[0] && ref $_[0]
          ? $_[0]
          : $self->delegate->make_obj($object_type, @_);
        $payload_object->$object_type($object);
        $self->$push_method($payload_object);
        return $payload_object;
      }
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    ONCE {
        for my $object_type ($self->delegate->OT) {
            my $add_method          = sprintf("add_%s",        $object_type);
            my $add_unique_method   = sprintf("add_unique_%s", $object_type);
            my $payload_object_type = sprintf("payload_%s",    $object_type);
            my $push_method         = sprintf("%ss_push",      $object_type);
            my $set_push_method     = sprintf("%ss_set_push",  $object_type);
            $self->generate_add_method(
                $object_type,         $add_method,
                $payload_object_type, $push_method
            );
            $self->generate_add_method(
                $object_type,         $add_unique_method,
                $payload_object_type, $set_push_method
            );
        }
    };
}

sub LIST_ACCESSOR_FOR_OBJECT_TYPE {
    local $_ = $_[0]->delegate;
    (   $_->OT_LOCK        => 'locks',
        $_->OT_TRANSACTION => 'transactions',
    );
}

sub get_list_name_for_object_type {
    my ($self, $object_type) = @_;
    my $list_accessor = $self->every_hash('LIST_ACCESSOR_FOR_OBJECT_TYPE');
    assert_defined my $method = $list_accessor->{$object_type},
      "unknown payload object type [$object_type]";
    $method;
}

sub get_list_for_object_type {
    my ($self, $object_type) = @_;
    our %cache_list_name_for_object_type;
    my $method = $cache_list_name_for_object_type{$object_type} ||=
      $self->get_list_name_for_object_type($object_type);
    $self->$method;
}

# Take a list of payload items and add it to the appropriate array slots in
# the payload object
sub add_items_from_list {
    my $self = shift;
    for my $item (flatten(@_)) {
        (my $factory_type = $item->get_my_factory_type) =~ s/^payload_//;
        my $list_accessor = $self->get_list_name_for_object_type($factory_type);
        my $push_method   = $list_accessor . '_push';
        $self->$push_method($item);
    }
}

sub get_transactions_with_data_object_type {
    my ($self, $object_type) = @_;
    grep { $_->data->object_type eq $object_type } $self->transactions;
}

sub get_transactions_with_data_object_type_and_cmd {
    my ($self, $object_type, $cmd) = @_;
    grep { $_->data->command eq $cmd }
      $self->get_transactions_with_data_object_type($object_type);
}

sub check {
    my ($self, $ticket) = @_;

    # check object limits; also check the payload items while we're at it
    for my $object_type ($self->delegate->OT) {
        my $limit =
          $self->delegate->get_object_limit($ticket->type, $object_type);
        my $index;
        for my $item ($self->get_list_for_object_type($object_type)) {
            $index++;

            # Ask the business object to check itself, accumulating exceptions
            # into the business object's exception container.
            $item->check($ticket);
            next if $index <= $limit;
            $item->exception_container->record(
                'Data::Conveyor::Exception::ObjectLimitExceeded',
                ticket_type => $ticket->type,
                object_type => $object_type,
                limit       => $limit,
            );
        }
    }
    $self->common->check($ticket);
}

# determines the overall payload rc
sub rc {
    my ($self, $ticket) = @_;

    # Start with RC_OK; if a stage wants to use another default rc, it can do
    # so by setting the common payload item's default_rc.
    my $rc =
      $self->delegate->make_obj('value_ticket_rc', $self->delegate->RC_OK) +
      $self->common->rc($ticket);
    for my $object_type ($self->delegate->OT) {
        $rc += $_->rc($ticket)
          for $self->get_list_for_object_type($object_type);
    }
    $rc;
}

# determines the overall payload status
sub status {
    my ($self, $ticket) = @_;

    # Start with TS_RUNNING; if a stage wants to use another default status,
    # it can do so by setting the common payload item's default_status.
    my $status =
      $self->delegate->make_obj('value_ticket_status',
        $self->delegate->TS_RUNNING) + $self->common->status($ticket);
    for my $object_type ($self->delegate->OT) {
        $status += $_->status($ticket)
          for $self->get_list_for_object_type($object_type);
    }
    $status;
}

sub update_transaction_stati {
    my ($self, $ticket) = @_;
    $_->transaction->update_status($ticket) for $self->transactions;
}

sub filter_exceptions_by_rc {
    my ($self, $ticket, @filter) = @_;
    my $result = $self->delegate->make_obj('exception_container');
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $result->items_push(
                $payload_item->exception_container->filter_exceptions_by_rc(
                    $ticket, @filter
                )
            );
        }
    }
    $result->items_push(
        $self->common->exception_container->filter_exceptions_by_rc(
            $ticket, @filter
        )
    );
    $result;
}

sub filter_exceptions_by_status {
    my ($self, $ticket, @filter) = @_;
    my $result = $self->delegate->make_obj('exception_container');
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $result->items_push(
                $payload_item->exception_container->filter_exceptions_by_status(
                    $ticket, @filter
                )
            );
        }
    }
    $result->items_push(
        $self->common->exception_container->filter_exceptions_by_status(
            $ticket, @filter
        )
    );
    $result;
}

sub get_all_exceptions {
    my $self   = shift;
    my $result = $self->delegate->make_obj('exception_container');
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $result->items_push($payload_item->exception_container->items);
        }
    }
    $result->items_push($self->common->exception_container->items);
    $result;
}

sub clear_all_exceptions {
    my $self = shift;
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $payload_item->exception_container->clear_items;
        }
    }
}

# Iterates over all payload items and deletes all exceptions whose uuid is one
# of those given in the argument list
sub delete_exceptions_by_uuid {
    my ($self, @uuid) = @_;
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $payload_item->exception_container->delete_by_uuid(@uuid);
        }
    }
}

sub delete_implicit_items {
    my $self = shift;
    for my $object_type ($self->delegate->OT) {
        my $list_name = $self->get_list_name_for_object_type($object_type);
        $self->$list_name([ grep { !$_->implicit } $self->$list_name ]);
    }
}

sub prepare_comparable {
    my $self = shift;
    $self->SUPER::prepare_comparable(@_);
    $self->version($self->delegate->PAYLOAD_VERSION);

    # Touch various accessors that will autovivify hash keys so we can be sure
    # they exist, which is a kind of normalization for the purpose of
    # comparing two objects of this class.
    $self->common;
    $self->transactions;
    $self->locks;

    # Touch the items of all exception containers so comparsions work (if the
    # ticket is stored, the items of all exception containers at least exist).
    $self->get_all_exceptions;
    for my $object_type ($self->delegate->OT) {
        my $list_name = $self->get_list_name_for_object_type($object_type);
        $self->$list_name;
    }
}

sub apply_instruction_containers {
    my $self = shift;
    for my $object_type ($self->delegate->OT) {
        for my $payload_item ($self->get_list_for_object_type($object_type)) {
            $payload_item->apply_instruction_container;
        }
    }
}

# Override this method to handle different payload versions: A payload may
# have been written months ago, but in the meantime the code might have
# changed. Therefore the old payload needs to be adapted to work with the new
# code.
sub upgrade { }
1;
__END__

=head1 NAME

Data::Conveyor::Ticket::Payload - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Ticket::Payload->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::Ticket::Payload inherits from L<Class::Scaffold::Storable>
and L<Class::Scaffold::HierarchicalDirty>.

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

    new(), FIRST_CONSTRUCTOR_ARGS(), add_autoloaded_package(), log()

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

The superclass L<Data::Comparable> defines these methods and functions:

    comparable(), comparable_scalar(), dump_comparable(),
    yaml_dump_comparable()

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

