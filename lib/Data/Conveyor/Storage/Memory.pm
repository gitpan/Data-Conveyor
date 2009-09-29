package Data::Conveyor::Storage::Memory;

# $Id: Memory.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Error::Hierarchy::Util 'assert_defined';
use Class::Scaffold::Exception::Util 'assert_object_type';


our $VERSION = '0.07';


use base qw(
    Data::Storage::Memory
    Data::Conveyor::Storage
);


use constant TRANSITION_TABLE => '';

sub parse_table {
    my ($self, $table) = @_;

    for (split /\n/ => $table) {
         next if /^\s*#/o;
         next if /^\s*$/o;
         s/#.*$//o;
         s/^\s+|\s+$//go;
         my ($from, $rc, $to, $status, $shift) = split /\s+/;
         assert_defined $_, 'syntax error in transition table'
             for ($from, $rc, $to, $status, $shift);
         for my $value ($from, $to) {
             # blow up on garbled input.
             # note: the object knows sh** about valid stage names (?).
             $self->delegate->make_obj('value_ticket_stage')->value($value);
         }
         my $state = sprintf '%s-%s' => $from, $self->delegate->$rc;
         # check supplied status value
         $self->delegate->$status if $status ne '-';
         (our $transition_cache)->{$state} = {
             stage => $to,
             shift => $shift eq 'Y' ? 1 : 0,
            ($status eq '-' ? ( ) : (status => $status)),
         };
    }
}


# This method parses and caches the transition table. This method is called
# from get_next_stage(), so the transition table is built on-demand. It is not
# built during the storage's init() because parse_table() calls
# make_obj('value_ticket_stage'), and if the 'value_ticket_stage' object is
# also handled by the memory storage, it would cause a deep recursion.

sub assert_transition_cache {
    my $self = shift;
    our $transition_cache;
    return if (ref $transition_cache eq 'HASH') && (keys %$transition_cache);
    $self->parse_table($self->TRANSITION_TABLE);
}


sub get_next_stage {
    my ($self, $stage, $rc) = @_;

    assert_object_type $stage, 'value_ticket_stage';
    assert_defined $rc, 'called without return code';
    $self->assert_transition_cache;

    my $state  = sprintf '%s-%s' => $stage, $rc;
    # return undef if the transition is not defined.
    return unless (my $target = (our $transition_cache)->{$state});
    return unless $target->{shift};
    [ $self->delegate->
         make_obj('value_ticket_stage')->value($target->{stage}), $target->{status} ];
}


1;


__END__



=head1 NAME

Data::Conveyor::Storage::Memory - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Storage::Memory->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::Storage::Memory inherits from L<Data::Storage::Memory> and
L<Data::Conveyor::Storage>.

The superclass L<Data::Storage::Memory> defines these methods and
functions:

    commit(), connect(), disconnect(), is_connected(), rollback()

The superclass L<Data::Storage> defines these methods and functions:

    new(), clear_log(), clear_rollback_mode(), create(), id(),
    initialize_data(), lazy_connect(), log(), log_clear(), rollback_mode(),
    rollback_mode_clear(), rollback_mode_set(), set_rollback_mode(),
    setup(), signature(), test_setup()

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

The superclass L<Data::Conveyor::Storage> defines these methods and
functions:

    get_ticket_shift_data(), ticket_deserialized_payload(),
    ticket_handle_exception(), ticket_insert(),
    ticket_serialized_payload(), ticket_store(), ticket_update()

The superclass L<Class::Scaffold::Base> defines these methods and
functions:

    FIRST_CONSTRUCTOR_ARGS(), MUNGE_CONSTRUCTOR_ARGS(),
    add_autoloaded_package(), init()

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

