package Data::Conveyor::Control;

# $Id: Control.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;


our $VERSION = '0.06';


use base qw(Class::Scaffold::Delegate::Mixin Class::Scaffold::Accessor);


__PACKAGE__
    ->mk_singleton_constructor(qw(new instance))
    ->mk_hash_accessors(qw(allowed_stages ignore_ticket_no));


sub log {
    require Class::Scaffold::Log;
    Class::Scaffold::Log->instance;
}


sub init  {}
sub read  {}
sub write {}


1;


__END__



=head1 NAME

Data::Conveyor::Control - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Control->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<instance>

    my $obj = Data::Conveyor::Control->instance;
    my $obj = Data::Conveyor::Control->instance(%args);

Creates and returns a new object. The object will be a singleton, so repeated
calls to the constructor will always return the same object. The constructor
will accept as arguments a list of pairs, from component name to initial
value. For each pair, the named component is initialized by calling the
method of the same name with the given value. If called with a single hash
reference, it is dereferenced and its key/value pairs are set as described
before.

=item C<new>

    my $obj = Data::Conveyor::Control->new;
    my $obj = Data::Conveyor::Control->new(%args);

Creates and returns a new object. The object will be a singleton, so repeated
calls to the constructor will always return the same object. The constructor
will accept as arguments a list of pairs, from component name to initial
value. For each pair, the named component is initialized by calling the
method of the same name with the given value. If called with a single hash
reference, it is dereferenced and its key/value pairs are set as described
before.

=item C<allowed_stages>

    my %hash     = $obj->allowed_stages;
    my $hash_ref = $obj->allowed_stages;
    my $value    = $obj->allowed_stages($key);
    my @values   = $obj->allowed_stages([ qw(foo bar) ]);
    $obj->allowed_stages(%other_hash);
    $obj->allowed_stages(foo => 23, bar => 42);

Get or set the hash values. If called without arguments, it returns the hash
in list context, or a reference to the hash in scalar context. If called
with a list of key/value pairs, it sets each key to its corresponding value,
then returns the hash as described before.

If called with exactly one key, it returns the corresponding value.

If called with exactly one array reference, it returns an array whose elements
are the values corresponding to the keys in the argument array, in the same
order. The resulting list is returned as an array in list context, or a
reference to the array in scalar context.

If called with exactly one hash reference, it updates the hash with the given
key/value pairs, then returns the hash in list context, or a reference to the
hash in scalar context.

=item C<allowed_stages_clear>

    $obj->allowed_stages_clear;

Deletes all keys and values from the hash.

=item C<allowed_stages_delete>

    $obj->allowed_stages_delete(@keys);

Takes a list of keys and deletes those keys from the hash.

=item C<allowed_stages_exists>

    if ($obj->allowed_stages_exists($key)) { ... }

Takes a key and returns a true value if the key exists in the hash, and a
false value otherwise.

=item C<allowed_stages_keys>

    my @keys = $obj->allowed_stages_keys;

Returns a list of all hash keys in no particular order.

=item C<allowed_stages_values>

    my @values = $obj->allowed_stages_values;

Returns a list of all hash values in no particular order.

=item C<clear_allowed_stages>

    $obj->clear_allowed_stages;

Deletes all keys and values from the hash.

=item C<clear_ignore_ticket_no>

    $obj->clear_ignore_ticket_no;

Deletes all keys and values from the hash.

=item C<delete_allowed_stages>

    $obj->delete_allowed_stages(@keys);

Takes a list of keys and deletes those keys from the hash.

=item C<delete_ignore_ticket_no>

    $obj->delete_ignore_ticket_no(@keys);

Takes a list of keys and deletes those keys from the hash.

=item C<exists_allowed_stages>

    if ($obj->exists_allowed_stages($key)) { ... }

Takes a key and returns a true value if the key exists in the hash, and a
false value otherwise.

=item C<exists_ignore_ticket_no>

    if ($obj->exists_ignore_ticket_no($key)) { ... }

Takes a key and returns a true value if the key exists in the hash, and a
false value otherwise.

=item C<ignore_ticket_no>

    my %hash     = $obj->ignore_ticket_no;
    my $hash_ref = $obj->ignore_ticket_no;
    my $value    = $obj->ignore_ticket_no($key);
    my @values   = $obj->ignore_ticket_no([ qw(foo bar) ]);
    $obj->ignore_ticket_no(%other_hash);
    $obj->ignore_ticket_no(foo => 23, bar => 42);

Get or set the hash values. If called without arguments, it returns the hash
in list context, or a reference to the hash in scalar context. If called
with a list of key/value pairs, it sets each key to its corresponding value,
then returns the hash as described before.

If called with exactly one key, it returns the corresponding value.

If called with exactly one array reference, it returns an array whose elements
are the values corresponding to the keys in the argument array, in the same
order. The resulting list is returned as an array in list context, or a
reference to the array in scalar context.

If called with exactly one hash reference, it updates the hash with the given
key/value pairs, then returns the hash in list context, or a reference to the
hash in scalar context.

=item C<ignore_ticket_no_clear>

    $obj->ignore_ticket_no_clear;

Deletes all keys and values from the hash.

=item C<ignore_ticket_no_delete>

    $obj->ignore_ticket_no_delete(@keys);

Takes a list of keys and deletes those keys from the hash.

=item C<ignore_ticket_no_exists>

    if ($obj->ignore_ticket_no_exists($key)) { ... }

Takes a key and returns a true value if the key exists in the hash, and a
false value otherwise.

=item C<ignore_ticket_no_keys>

    my @keys = $obj->ignore_ticket_no_keys;

Returns a list of all hash keys in no particular order.

=item C<ignore_ticket_no_values>

    my @values = $obj->ignore_ticket_no_values;

Returns a list of all hash values in no particular order.

=item C<instance_instance>

    my $obj = Data::Conveyor::Control->instance_instance;
    my $obj = Data::Conveyor::Control->instance_instance(%args);

Creates and returns a new object. The constructor will accept as arguments a
list of pairs, from component name to initial value. For each pair, the named
component is initialized by calling the method of the same name with the given
value. If called with a single hash reference, it is dereferenced and its
key/value pairs are set as described before.

=item C<keys_allowed_stages>

    my @keys = $obj->keys_allowed_stages;

Returns a list of all hash keys in no particular order.

=item C<keys_ignore_ticket_no>

    my @keys = $obj->keys_ignore_ticket_no;

Returns a list of all hash keys in no particular order.

=item C<new_instance>

    my $obj = Data::Conveyor::Control->new_instance;
    my $obj = Data::Conveyor::Control->new_instance(%args);

Creates and returns a new object. The constructor will accept as arguments a
list of pairs, from component name to initial value. For each pair, the named
component is initialized by calling the method of the same name with the given
value. If called with a single hash reference, it is dereferenced and its
key/value pairs are set as described before.

=item C<values_allowed_stages>

    my @values = $obj->values_allowed_stages;

Returns a list of all hash values in no particular order.

=item C<values_ignore_ticket_no>

    my @values = $obj->values_ignore_ticket_no;

Returns a list of all hash values in no particular order.

=back

Data::Conveyor::Control inherits from L<Class::Scaffold::Delegate::Mixin>,
L<Class::Scaffold::Accessor>, and L<Class::Accessor::Constructor::Base>.

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

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

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

