package Data::Conveyor::Ticket::Provider;

# $Id: Provider.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;


our $VERSION = '0.02';


use base 'Class::Scaffold::Storable';


__PACKAGE__
    ->mk_scalar_accessors(qw(
        handle prefetch supported timestamp lagmax clause
    ))
    ->mk_array_accessors(qw(accepted_stages stack));


use constant INFO => qw/
    ticket_no
    stage
    rc
    status
    nice
/;
use constant PREFETCH_MAX => 12;

use constant DEFAULTS => (
    prefetch => 5,
    lagmax   => 8
);

use constant NULLCLAUSE => '0=0';

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->storage_type('core_storage');
    $self->clause($self->delegate->ticket_provider_clause || NULLCLAUSE);
    die sprintf "prefetch value too large: %d",
           $self->prefetch
        if $self->prefetch > PREFETCH_MAX;
}


sub get_next_ticket {
    my $self = shift;
    my $supported = join ",", map {
           "'starten_$_'"
    } @{shift(@_)};
    my $succeeded = shift;

    $self->stack_clear if $succeeded;

    my $info = $self->_next_unit($supported);
    return unless $info;
    my $ticket = $self->delegate->make_obj('ticket', 
        map { $_ => $info->{$_} } INFO
    );
    $ticket;
}


sub _next_unit {
    my ($self, $supported) = @_;

    $self->handle(
       $self->storage->prepare('
           begin
           ticket_pck.next_ticketblock_select (
                  :supported
                , :prefetch
                , :clause
                , :nextblock
           );
           end;
       ')
    ) unless $self->handle;

    if ($self->stack_count
           && $self->fresh
           && $supported eq $self->supported) {

        return $self->stack_shift;
    }
    else {

        $self->supported($supported);

        my $nextblock;
        $self->handle->bind_param(':supported', $supported);
        $self->handle->bind_param(':prefetch',  $self->prefetch);
        $self->handle->bind_param(':clause',    $self->clause);
        $self->handle->bind_param_inout(':nextblock', \$nextblock, 4096);
        $self->handle->execute;

        $self->stack_clear;
        $self->timestamp(time());

        return unless $nextblock;

        for my $token (split /#/, $nextblock) {
            my (%entry, @info);
            @info = split / /, $token;
            die sprintf "severe provider error"
                unless @info == 5;
            @entry{(INFO)} = @info;
            $self->stack_push(\%entry);
        }

        return $self->_next_unit($supported);

    }
}


sub fresh {
    my $self = shift;
    return (time() - $self->timestamp <= $self->lagmax);
}


sub DESTROY {
    my $self = shift;
    defined $self->handle
         && $self->handle->finish;
}


1;


__END__



=head1 NAME

Data::Conveyor::Ticket::Provider - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Ticket::Provider->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item accepted_stages

    my @values    = $obj->accepted_stages;
    my $array_ref = $obj->accepted_stages;
    $obj->accepted_stages(@values);
    $obj->accepted_stages($array_ref);

Get or set the array values. If called without an arguments, it returns the
array in list context, or a reference to the array in scalar context. If
called with arguments, it expands array references found therein and sets the
values.

=item accepted_stages_clear

    $obj->accepted_stages_clear;

Deletes all elements from the array.

=item accepted_stages_count

    my $count = $obj->accepted_stages_count;

Returns the number of elements in the array.

=item accepted_stages_index

    my $element   = $obj->accepted_stages_index(3);
    my @elements  = $obj->accepted_stages_index(@indices);
    my $array_ref = $obj->accepted_stages_index(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item accepted_stages_pop

    my $value = $obj->accepted_stages_pop;

Pops the last element off the array, returning it.

=item accepted_stages_push

    $obj->accepted_stages_push(@values);

Pushes elements onto the end of the array.

=item accepted_stages_set

    $obj->accepted_stages_set(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item accepted_stages_shift

    my $value = $obj->accepted_stages_shift;

Shifts the first element off the array, returning it.

=item accepted_stages_splice

    $obj->accepted_stages_splice(2, 1, $x, $y);
    $obj->accepted_stages_splice(-1);
    $obj->accepted_stages_splice(0, -1);

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

=item accepted_stages_unshift

    $obj->accepted_stages_unshift(@values);

Unshifts elements onto the beginning of the array.

=item clause

    my $value = $obj->clause;
    $obj->clause($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item clause_clear

    $obj->clause_clear;

Clears the value.

=item clear_accepted_stages

    $obj->clear_accepted_stages;

Deletes all elements from the array.

=item clear_clause

    $obj->clear_clause;

Clears the value.

=item clear_handle

    $obj->clear_handle;

Clears the value.

=item clear_lagmax

    $obj->clear_lagmax;

Clears the value.

=item clear_prefetch

    $obj->clear_prefetch;

Clears the value.

=item clear_stack

    $obj->clear_stack;

Deletes all elements from the array.

=item clear_supported

    $obj->clear_supported;

Clears the value.

=item clear_timestamp

    $obj->clear_timestamp;

Clears the value.

=item count_accepted_stages

    my $count = $obj->count_accepted_stages;

Returns the number of elements in the array.

=item count_stack

    my $count = $obj->count_stack;

Returns the number of elements in the array.

=item handle

    my $value = $obj->handle;
    $obj->handle($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item handle_clear

    $obj->handle_clear;

Clears the value.

=item index_accepted_stages

    my $element   = $obj->index_accepted_stages(3);
    my @elements  = $obj->index_accepted_stages(@indices);
    my $array_ref = $obj->index_accepted_stages(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item index_stack

    my $element   = $obj->index_stack(3);
    my @elements  = $obj->index_stack(@indices);
    my $array_ref = $obj->index_stack(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item lagmax

    my $value = $obj->lagmax;
    $obj->lagmax($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item lagmax_clear

    $obj->lagmax_clear;

Clears the value.

=item pop_accepted_stages

    my $value = $obj->pop_accepted_stages;

Pops the last element off the array, returning it.

=item pop_stack

    my $value = $obj->pop_stack;

Pops the last element off the array, returning it.

=item prefetch

    my $value = $obj->prefetch;
    $obj->prefetch($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item prefetch_clear

    $obj->prefetch_clear;

Clears the value.

=item push_accepted_stages

    $obj->push_accepted_stages(@values);

Pushes elements onto the end of the array.

=item push_stack

    $obj->push_stack(@values);

Pushes elements onto the end of the array.

=item set_accepted_stages

    $obj->set_accepted_stages(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item set_stack

    $obj->set_stack(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item shift_accepted_stages

    my $value = $obj->shift_accepted_stages;

Shifts the first element off the array, returning it.

=item shift_stack

    my $value = $obj->shift_stack;

Shifts the first element off the array, returning it.

=item splice_accepted_stages

    $obj->splice_accepted_stages(2, 1, $x, $y);
    $obj->splice_accepted_stages(-1);
    $obj->splice_accepted_stages(0, -1);

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

=item splice_stack

    $obj->splice_stack(2, 1, $x, $y);
    $obj->splice_stack(-1);
    $obj->splice_stack(0, -1);

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

=item stack

    my @values    = $obj->stack;
    my $array_ref = $obj->stack;
    $obj->stack(@values);
    $obj->stack($array_ref);

Get or set the array values. If called without an arguments, it returns the
array in list context, or a reference to the array in scalar context. If
called with arguments, it expands array references found therein and sets the
values.

=item stack_clear

    $obj->stack_clear;

Deletes all elements from the array.

=item stack_count

    my $count = $obj->stack_count;

Returns the number of elements in the array.

=item stack_index

    my $element   = $obj->stack_index(3);
    my @elements  = $obj->stack_index(@indices);
    my $array_ref = $obj->stack_index(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item stack_pop

    my $value = $obj->stack_pop;

Pops the last element off the array, returning it.

=item stack_push

    $obj->stack_push(@values);

Pushes elements onto the end of the array.

=item stack_set

    $obj->stack_set(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item stack_shift

    my $value = $obj->stack_shift;

Shifts the first element off the array, returning it.

=item stack_splice

    $obj->stack_splice(2, 1, $x, $y);
    $obj->stack_splice(-1);
    $obj->stack_splice(0, -1);

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

=item stack_unshift

    $obj->stack_unshift(@values);

Unshifts elements onto the beginning of the array.

=item supported

    my $value = $obj->supported;
    $obj->supported($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item supported_clear

    $obj->supported_clear;

Clears the value.

=item timestamp

    my $value = $obj->timestamp;
    $obj->timestamp($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item timestamp_clear

    $obj->timestamp_clear;

Clears the value.

=item unshift_accepted_stages

    $obj->unshift_accepted_stages(@values);

Unshifts elements onto the beginning of the array.

=item unshift_stack

    $obj->unshift_stack(@values);

Unshifts elements onto the beginning of the array.

=back

Data::Conveyor::Ticket::Provider inherits from
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

    new(), add_autoloaded_package(), log()

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

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<dataconveyor> tag.

=head1 VERSION 
                   
This document describes version 0.02 of L<Data::Conveyor::Ticket::Provider>.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<<bug-data-conveyor@rt.cpan.org>>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

Florian Helmberger C<< <fh@univie.ac.at> >>

Achim Adam C<< <ac@univie.ac.at> >>

Mark Hofstetter C<< <mh@univie.ac.at> >>

Heinz Ekker C<< <ek@univie.ac.at> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2008 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

