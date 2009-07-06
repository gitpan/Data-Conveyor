package Data::Conveyor::Service::Result::Tabular;

# $Id: Tabular.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Text::Table;
use Data::Miscellany 'trim';


our $VERSION = '0.06';


use base 'Data::Conveyor::Service::Result';


__PACKAGE__->mk_array_accessors(qw(headers rows));


sub result_as_string {
    my $self = shift;
    unless ($self->rows_count) {
        return "No results\n";
    }
    my @fields = $self->headers;
    my $table = Text::Table->new(@fields);
    $table->load($self->rows);
    $table;
}


# Given a LoH (list of hashes, a typical DBI result set), it populates the
# result object with those rows. It can also be a list of objects if those
# objects have methods that correspond to the headers.

sub set_from_rows {
    my ($self, %args) = @_;
    my ($did_set_headers, $count);
    my $limit  = $args{limit} if defined $args{limit};
    my @fields = @{$args{fields}} if defined $args{fields};

    for my $row (@{$args{rows}}) {
        last if defined($limit) && ++$count > $limit;
        unless ($did_set_headers) {
            scalar @fields or @fields = sort keys %$row;
            $self->headers(@fields);
            $did_set_headers++;
        }

        my @values;
        for (@fields) {
            if (ref $row eq 'HASH') {
                push @values => $row->{$_};
            } elsif (UNIVERSAL::can($row, $_)) {
                push @values => $row->$_;
            } else {
                throw Error::Hierarchy::Internal::CustomMessage(
                    custom_message => "can't set field [$_] from row [$row]"
                );
            }
        }

        $self->rows_push([ map { defined($_) ? $_ : '' } @values ]);
    }

    $self;
}


sub result { $_[0]->rows }


sub result_as_list_of_hashes {
    my $self = shift;
    my @result;
    my @headers = $self->headers; # don't call this accessor for every row

    for my $row_ref ($self->rows) {
        my $index = 0;
        my %row_hash;
        for my $header (@headers) {
            $row_hash{$header} = $row_ref->[$index++];
        }
        push @result => \%row_hash;
    }
    wantarray ? @result : \@result;
}


1;


__END__



=head1 NAME

Data::Conveyor::Service::Result::Tabular - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Service::Result::Tabular->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_headers>

    $obj->clear_headers;

Deletes all elements from the array.

=item C<clear_rows>

    $obj->clear_rows;

Deletes all elements from the array.

=item C<count_headers>

    my $count = $obj->count_headers;

Returns the number of elements in the array.

=item C<count_rows>

    my $count = $obj->count_rows;

Returns the number of elements in the array.

=item C<headers>

    my @values    = $obj->headers;
    my $array_ref = $obj->headers;
    $obj->headers(@values);
    $obj->headers($array_ref);

Get or set the array values. If called without an arguments, it returns the
array in list context, or a reference to the array in scalar context. If
called with arguments, it expands array references found therein and sets the
values.

=item C<headers_clear>

    $obj->headers_clear;

Deletes all elements from the array.

=item C<headers_count>

    my $count = $obj->headers_count;

Returns the number of elements in the array.

=item C<headers_index>

    my $element   = $obj->headers_index(3);
    my @elements  = $obj->headers_index(@indices);
    my $array_ref = $obj->headers_index(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item C<headers_pop>

    my $value = $obj->headers_pop;

Pops the last element off the array, returning it.

=item C<headers_push>

    $obj->headers_push(@values);

Pushes elements onto the end of the array.

=item C<headers_set>

    $obj->headers_set(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item C<headers_shift>

    my $value = $obj->headers_shift;

Shifts the first element off the array, returning it.

=item C<headers_splice>

    $obj->headers_splice(2, 1, $x, $y);
    $obj->headers_splice(-1);
    $obj->headers_splice(0, -1);

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

=item C<headers_unshift>

    $obj->headers_unshift(@values);

Unshifts elements onto the beginning of the array.

=item C<index_headers>

    my $element   = $obj->index_headers(3);
    my @elements  = $obj->index_headers(@indices);
    my $array_ref = $obj->index_headers(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item C<index_rows>

    my $element   = $obj->index_rows(3);
    my @elements  = $obj->index_rows(@indices);
    my $array_ref = $obj->index_rows(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item C<pop_headers>

    my $value = $obj->pop_headers;

Pops the last element off the array, returning it.

=item C<pop_rows>

    my $value = $obj->pop_rows;

Pops the last element off the array, returning it.

=item C<push_headers>

    $obj->push_headers(@values);

Pushes elements onto the end of the array.

=item C<push_rows>

    $obj->push_rows(@values);

Pushes elements onto the end of the array.

=item C<rows>

    my @values    = $obj->rows;
    my $array_ref = $obj->rows;
    $obj->rows(@values);
    $obj->rows($array_ref);

Get or set the array values. If called without an arguments, it returns the
array in list context, or a reference to the array in scalar context. If
called with arguments, it expands array references found therein and sets the
values.

=item C<rows_clear>

    $obj->rows_clear;

Deletes all elements from the array.

=item C<rows_count>

    my $count = $obj->rows_count;

Returns the number of elements in the array.

=item C<rows_index>

    my $element   = $obj->rows_index(3);
    my @elements  = $obj->rows_index(@indices);
    my $array_ref = $obj->rows_index(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item C<rows_pop>

    my $value = $obj->rows_pop;

Pops the last element off the array, returning it.

=item C<rows_push>

    $obj->rows_push(@values);

Pushes elements onto the end of the array.

=item C<rows_set>

    $obj->rows_set(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item C<rows_shift>

    my $value = $obj->rows_shift;

Shifts the first element off the array, returning it.

=item C<rows_splice>

    $obj->rows_splice(2, 1, $x, $y);
    $obj->rows_splice(-1);
    $obj->rows_splice(0, -1);

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

=item C<rows_unshift>

    $obj->rows_unshift(@values);

Unshifts elements onto the beginning of the array.

=item C<set_headers>

    $obj->set_headers(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item C<set_rows>

    $obj->set_rows(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item C<shift_headers>

    my $value = $obj->shift_headers;

Shifts the first element off the array, returning it.

=item C<shift_rows>

    my $value = $obj->shift_rows;

Shifts the first element off the array, returning it.

=item C<splice_headers>

    $obj->splice_headers(2, 1, $x, $y);
    $obj->splice_headers(-1);
    $obj->splice_headers(0, -1);

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

=item C<splice_rows>

    $obj->splice_rows(2, 1, $x, $y);
    $obj->splice_rows(-1);
    $obj->splice_rows(0, -1);

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

=item C<unshift_headers>

    $obj->unshift_headers(@values);

Unshifts elements onto the beginning of the array.

=item C<unshift_rows>

    $obj->unshift_rows(@values);

Unshifts elements onto the beginning of the array.

=back

Data::Conveyor::Service::Result::Tabular inherits from
L<Data::Conveyor::Service::Result>.

The superclass L<Data::Conveyor::Service::Result> defines these methods and
functions:

    clear_exception(), clear_result(), exception(), exception_clear(),
    is_ok(), result_clear(), stringify()

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

Copyright 2004-2008 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

