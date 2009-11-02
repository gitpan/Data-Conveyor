package Data::Conveyor::Ticket::Payload::Item;

# $Id: Item.pm 13653 2007-10-22 09:11:20Z gr $
#
# Base class for Data::Conveyor::Ticket::Payload::* items

use warnings;
use strict;


our $VERSION = '0.08';


use base 'Class::Scaffold::Storable';


__PACKAGE__
    ->mk_abstract_accessors(qw(DATA_PROPERTY))
    ->mk_framework_object_accessors(
        exception_container => 'exception_container'
    )
    ->mk_boolean_accessors(qw(implicit));

# implicit(): was this item created implicitly by txsel?


sub check {
    my ($self, $ticket) = @_;
    $self->data->check($self->exception_container, $ticket);
}


sub data {
    my $property = $_[0]->DATA_PROPERTY;
    return $_[0]->$property if @_ == 1;
    $_[0]->$property($_[1]);
}


# For rc() and status(), we pass the payload item's owning ticket object to
# the exception container. The container needs to ask the ticket whether to
# ignore an exception. Why do the payload object and the payload items have an
# owning ticket, but the exception container does not? Because exception
# containers are filled from various places, and are passed around. In
# contrast, payload containers and payload items are always tied to a ticket.
#
# We also pass the payload item itself because it will eventually be passed to
# the exception handler, which uses it to decide the rc and status of each
# exception it is ask to handle. That is, the rc and exception aren't
# determined by the exception type alone. The same exception can have
# different rc and status values depending on which object type and command it
# is associated with.

sub rc {
    my ($self, $ticket) = @_;
    $self->exception_container->rc($ticket, $self);
}


sub status {
    my ($self, $ticket) = @_;
    $self->exception_container->status($ticket, $self);
}


sub has_problematic_exceptions {
    my ($self, $ticket) = @_;
    $self->exception_container->has_problematic_exceptions($ticket, $self);
}


sub prepare_comparable {
    my $self = shift;
    $self->SUPER::prepare_comparable(@_);

    # Touch various accessors that will autovivify hash keys so we can be sure
    # they exist, which is a kind of normalization for the purpose of
    # comparing two objects of this class.

    $self->exception_container;
    $self->implicit;
}


# do nothing here; business objects will override
sub apply_instruction_container {}


1;


__END__



=head1 NAME

Data::Conveyor::Ticket::Payload::Item - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Ticket::Payload::Item->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_implicit>

    $obj->clear_implicit;

Clears the boolean value by setting it to 0.

=item C<implicit>

    $obj->implicit($value);
    my $value = $obj->implicit;

If called without an argument, returns the boolean value (0 or 1). If called
with an argument, it normalizes it to the boolean value. That is, the values
0, undef and the empty string become 0; everything else becomes 1.

=item C<implicit_clear>

    $obj->implicit_clear;

Clears the boolean value by setting it to 0.

=item C<implicit_set>

    $obj->implicit_set;

Sets the boolean value to 1.

=item C<set_implicit>

    $obj->set_implicit;

Sets the boolean value to 1.

=back

Data::Conveyor::Ticket::Payload::Item inherits from
L<Class::Scaffold::Storable>.

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

