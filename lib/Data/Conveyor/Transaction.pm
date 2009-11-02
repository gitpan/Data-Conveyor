package Data::Conveyor::Transaction;

# $Id: Transaction.pm 13653 2007-10-22 09:11:20Z gr $

# Base class for classes operating on transactions. Policy and delegation
# classes subclass this class.

use warnings;
use strict;
use Error::Hierarchy::Util 'assert_defined';


our $VERSION = '0.08';


use base 'Class::Scaffold::Storable';


__PACKAGE__
    ->mk_framework_object_accessors(
        ticket              => 'ticket',
        transaction_factory => 'factory',
    )
    ->mk_scalar_accessors(qw(tx stage))
    ->mk_array_accessors(qw(extra_tx_list));

    # ticket and tx are passed by Data::Conveyor::Transaction::Factory
    # constructor call; the factory also passes itself as the factory
    # attribute so the transaction can ask the factory to construct
    # further objects.


# shortcuts to the item and its data referenced by the current transaction

sub payload_item      { $_[0]->tx->transaction->payload_item }
sub payload_item_data { $_[0]->payload_item->data            }



# Cumulate exceptions here and throw them summarily in an exception container
# at the end. We do this because we want to be able to check as much as
# possible.

sub record {
    my $self = shift;

    # make record() invisible to caller when reporting exception location
    local $Error::Depth = $Error::Depth + 1;

    $self->payload_item->exception_container->record(
        @_,
        is_optional => $self->tx->transaction->is_optional,
    );
}


# Like record(), but records an actual exception object. This method would be
# called if you want to record an exception caught from somewhere else.

sub record_exception {
    my ($self, $E) = @_;
    $E->is_optional($self->tx->transaction->is_optional);
    $self->payload_item->exception_container->items_set_push($E);
}


sub run {}


1;


__END__



=head1 NAME

Data::Conveyor::Transaction - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Transaction->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_extra_tx_list>

    $obj->clear_extra_tx_list;

Deletes all elements from the array.

=item C<clear_stage>

    $obj->clear_stage;

Clears the value.

=item C<clear_tx>

    $obj->clear_tx;

Clears the value.

=item C<count_extra_tx_list>

    my $count = $obj->count_extra_tx_list;

Returns the number of elements in the array.

=item C<extra_tx_list>

    my @values    = $obj->extra_tx_list;
    my $array_ref = $obj->extra_tx_list;
    $obj->extra_tx_list(@values);
    $obj->extra_tx_list($array_ref);

Get or set the array values. If called without an arguments, it returns the
array in list context, or a reference to the array in scalar context. If
called with arguments, it expands array references found therein and sets the
values.

=item C<extra_tx_list_clear>

    $obj->extra_tx_list_clear;

Deletes all elements from the array.

=item C<extra_tx_list_count>

    my $count = $obj->extra_tx_list_count;

Returns the number of elements in the array.

=item C<extra_tx_list_index>

    my $element   = $obj->extra_tx_list_index(3);
    my @elements  = $obj->extra_tx_list_index(@indices);
    my $array_ref = $obj->extra_tx_list_index(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item C<extra_tx_list_pop>

    my $value = $obj->extra_tx_list_pop;

Pops the last element off the array, returning it.

=item C<extra_tx_list_push>

    $obj->extra_tx_list_push(@values);

Pushes elements onto the end of the array.

=item C<extra_tx_list_set>

    $obj->extra_tx_list_set(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item C<extra_tx_list_shift>

    my $value = $obj->extra_tx_list_shift;

Shifts the first element off the array, returning it.

=item C<extra_tx_list_splice>

    $obj->extra_tx_list_splice(2, 1, $x, $y);
    $obj->extra_tx_list_splice(-1);
    $obj->extra_tx_list_splice(0, -1);

Takes three arguments: An offset, a length and a list.

Removes the elements designated by the offset and the length from the array,
and replaces them with the elements of the list, if any. In list context,
returns the elements removed from the array. In scalar context, returns the
last element removed, or C<undef> if no elements are removed. The array grows
or shrinks as necessary. If the offset is negative then it starts that far
from the end of the array. If the length is omitted, removes everything from
the offset onward. If the length is negative, removes the elements from the
offset onward except for -length elements at the end of the array. If both the
offset and the length are omitted, removes everything. If the offset is past
the end of the array, it issues a warning, and splices at the end of the
array.

=item C<extra_tx_list_unshift>

    $obj->extra_tx_list_unshift(@values);

Unshifts elements onto the beginning of the array.

=item C<index_extra_tx_list>

    my $element   = $obj->index_extra_tx_list(3);
    my @elements  = $obj->index_extra_tx_list(@indices);
    my $array_ref = $obj->index_extra_tx_list(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item C<pop_extra_tx_list>

    my $value = $obj->pop_extra_tx_list;

Pops the last element off the array, returning it.

=item C<push_extra_tx_list>

    $obj->push_extra_tx_list(@values);

Pushes elements onto the end of the array.

=item C<set_extra_tx_list>

    $obj->set_extra_tx_list(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item C<shift_extra_tx_list>

    my $value = $obj->shift_extra_tx_list;

Shifts the first element off the array, returning it.

=item C<splice_extra_tx_list>

    $obj->splice_extra_tx_list(2, 1, $x, $y);
    $obj->splice_extra_tx_list(-1);
    $obj->splice_extra_tx_list(0, -1);

Takes three arguments: An offset, a length and a list.

Removes the elements designated by the offset and the length from the array,
and replaces them with the elements of the list, if any. In list context,
returns the elements removed from the array. In scalar context, returns the
last element removed, or C<undef> if no elements are removed. The array grows
or shrinks as necessary. If the offset is negative then it starts that far
from the end of the array. If the length is omitted, removes everything from
the offset onward. If the length is negative, removes the elements from the
offset onward except for -length elements at the end of the array. If both the
offset and the length are omitted, removes everything. If the offset is past
the end of the array, it issues a warning, and splices at the end of the
array.

=item C<stage>

    my $value = $obj->stage;
    $obj->stage($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<stage_clear>

    $obj->stage_clear;

Clears the value.

=item C<tx>

    my $value = $obj->tx;
    $obj->tx($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<tx_clear>

    $obj->tx_clear;

Clears the value.

=item C<unshift_extra_tx_list>

    $obj->unshift_extra_tx_list(@values);

Unshifts elements onto the beginning of the array.

=back

Data::Conveyor::Transaction inherits from L<Class::Scaffold::Storable>.

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

