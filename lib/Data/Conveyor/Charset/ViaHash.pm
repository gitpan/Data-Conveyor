package Data::Conveyor::Charset::ViaHash;

# $Id: ViaHash.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use charnames ':full';


our $VERSION = '0.10';


use base 'Data::Conveyor::Charset';


__PACKAGE__
    ->mk_constructor(qw(new))
    ->mk_hash_accessors(qw(character_cache))
    ->mk_scalar_accessors(qw(valid_string_re_cache));


sub CHARACTERS { () }


sub get_characters {
    my $self = shift;
    unless ($self->character_cache_keys) {

        my $characters = $self->every_hash('CHARACTERS');

        # Convert the hash values to their actual Unicode character
        # equivalent. For defining a character, we accept Unicode character
        # names (the "..." part of the "\N{...}" notation) or hex code points
        # (indicated by a leading "0x"; useful for characters that don't have
        # a name).

        for (values %$characters) {
            next if utf8::is_utf8($_);  # don't convert the already converted
            if (/^0x(.*)$/) {
                $_ = sprintf '%c' => hex($1);
            } else {
                $_ = sprintf '%c' => charnames::vianame($_);
            }
            utf8::upgrade($_);
        }

        $self->character_cache(%$characters);
    }
    return $self->character_cache;
}


sub get_character_names {
    my $self = shift;
    my %characters = $self->get_characters;
    my @names = keys %characters;
    wantarray ? @names : \@names;
}


sub get_character_values {
    my $self = shift;
    my %characters = $self->get_characters;
    my @values = values %characters;
    wantarray ? @values : \@values;
}


sub is_valid_string {
    my ($self, $string) = @_;

    unless (defined $self->valid_string_re_cache) {

        # escape critical characters so they're not interpreted as special
        # characters in the regex.

        my $chars = join '', map {
            m{^[\-.+*?()\[\]/\\]$} ? sprintf("\\%s", $_ ) : $_;
        } $self->get_character_values;

        $self->valid_string_re_cache(qr/^[$chars]+$/);
    }

    $string =~ $self->valid_string_re_cache;
}


1;


__END__



=head1 NAME

Data::Conveyor::Charset::ViaHash - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Charset::ViaHash->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<new>

    my $obj = Data::Conveyor::Charset::ViaHash->new;
    my $obj = Data::Conveyor::Charset::ViaHash->new(%args);

Creates and returns a new object. The constructor will accept as arguments a
list of pairs, from component name to initial value. For each pair, the named
component is initialized by calling the method of the same name with the given
value. If called with a single hash reference, it is dereferenced and its
key/value pairs are set as described before.

=item C<character_cache>

    my %hash     = $obj->character_cache;
    my $hash_ref = $obj->character_cache;
    my $value    = $obj->character_cache($key);
    my @values   = $obj->character_cache([ qw(foo bar) ]);
    $obj->character_cache(%other_hash);
    $obj->character_cache(foo => 23, bar => 42);

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

=item C<character_cache_clear>

    $obj->character_cache_clear;

Deletes all keys and values from the hash.

=item C<character_cache_delete>

    $obj->character_cache_delete(@keys);

Takes a list of keys and deletes those keys from the hash.

=item C<character_cache_exists>

    if ($obj->character_cache_exists($key)) { ... }

Takes a key and returns a true value if the key exists in the hash, and a
false value otherwise.

=item C<character_cache_keys>

    my @keys = $obj->character_cache_keys;

Returns a list of all hash keys in no particular order.

=item C<character_cache_values>

    my @values = $obj->character_cache_values;

Returns a list of all hash values in no particular order.

=item C<clear_character_cache>

    $obj->clear_character_cache;

Deletes all keys and values from the hash.

=item C<clear_valid_string_re_cache>

    $obj->clear_valid_string_re_cache;

Clears the value.

=item C<delete_character_cache>

    $obj->delete_character_cache(@keys);

Takes a list of keys and deletes those keys from the hash.

=item C<exists_character_cache>

    if ($obj->exists_character_cache($key)) { ... }

Takes a key and returns a true value if the key exists in the hash, and a
false value otherwise.

=item C<keys_character_cache>

    my @keys = $obj->keys_character_cache;

Returns a list of all hash keys in no particular order.

=item C<valid_string_re_cache>

    my $value = $obj->valid_string_re_cache;
    $obj->valid_string_re_cache($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<valid_string_re_cache_clear>

    $obj->valid_string_re_cache_clear;

Clears the value.

=item C<values_character_cache>

    my @values = $obj->values_character_cache;

Returns a list of all hash values in no particular order.

=back

Data::Conveyor::Charset::ViaHash inherits from L<Data::Conveyor::Charset>.

The superclass L<Class::Scaffold::Base> defines these methods and
functions:

    FIRST_CONSTRUCTOR_ARGS(), MUNGE_CONSTRUCTOR_ARGS(),
    add_autoloaded_package(), init(), log()

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

