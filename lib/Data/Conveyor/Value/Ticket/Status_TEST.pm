package Data::Conveyor::Value::Ticket::Status_TEST;

# $Id: Status_TEST.pm 12315 2006-12-12 14:16:26Z gr $

use strict;
use warnings;


our $VERSION = '0.05';


use base 'Data::Conveyor::Test';


use constant PLAN => 14;


sub run {
    my $self = shift;
    $self->SUPER::run(@_);

    # Note that there are no tests for adding TS_HOLD and TS_PENDING; that's
    # undefined so far because we don't really use TS_HOLD anymore.

    $self->apply_status_ok('TS_RUNNING' , 'TS_RUNNING' , 'TS_RUNNING' , 1);
    $self->apply_status_ok('TS_RUNNING' , 'TS_HOLD'    , 'TS_HOLD'    , 1);
    $self->apply_status_ok('TS_RUNNING' , 'TS_PENDING' , 'TS_PENDING' , 1);
    $self->apply_status_ok('TS_RUNNING' , 'TS_ERROR'   , 'TS_ERROR'   , 1);

    $self->apply_status_ok('TS_HOLD'    , 'TS_RUNNING' , 'TS_HOLD'    , 1);
    $self->apply_status_ok('TS_HOLD'    , 'TS_HOLD'    , 'TS_HOLD'    , 1);
    $self->apply_status_ok('TS_HOLD'    , 'TS_ERROR'   , 'TS_ERROR'   , 1);

    $self->apply_status_ok('TS_PENDING' , 'TS_RUNNING' , 'TS_PENDING' , 1);
    $self->apply_status_ok('TS_PENDING' , 'TS_PENDING' , 'TS_PENDING' , 1);
    $self->apply_status_ok('TS_PENDING' , 'TS_ERROR'   , 'TS_ERROR'   , 1);

    $self->apply_status_ok('TS_ERROR'   , 'TS_RUNNING' , 'TS_ERROR'   , 1);
    $self->apply_status_ok('TS_ERROR'   , 'TS_HOLD'    , 'TS_ERROR'   , 1);
    $self->apply_status_ok('TS_ERROR'   , 'TS_PENDING' , 'TS_ERROR'   , 1);
    $self->apply_status_ok('TS_ERROR'   , 'TS_ERROR'   , 'TS_ERROR'   , 1);


}


1;


__END__



=head1 NAME

Data::Conveyor::Value::Ticket::Status_TEST - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Value::Ticket::Status_TEST->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::Value::Ticket::Status_TEST inherits from
L<Data::Conveyor::Test>.

The superclass L<Data::Conveyor::Test> defines these methods and functions:

    apply_rc_ok(), apply_status_ok(), factory_gen_template_handler_ok(),
    factory_gen_transaction_handler_ok(),
    factory_gen_txsel_handler_iterate(), factory_gen_txsel_handler_ok(),
    object_limit_ok(), rc_for_exception_class_ok(), stage_basics_ok(),
    transition_ok(), transition_ok_bare()

The superclass L<Class::Scaffold::Test> defines these methods and
functions:

    obj_ok(), planned_test_count()

The superclass L<Class::Scaffold::Base> defines these methods and
functions:

    new(), FIRST_CONSTRUCTOR_ARGS(), MUNGE_CONSTRUCTOR_ARGS(),
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

The superclass L<Test::CompanionClasses::Base> defines these methods and
functions:

    clear_package(), make_real_object(), package(), package_clear()

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

