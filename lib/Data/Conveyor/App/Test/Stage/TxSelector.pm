package Data::Conveyor::App::Test::Stage::TxSelector;

# $Id: TxSelector.pm 9526 2005-07-01 12:41:14Z gr $

use warnings;
use strict;
use Test::More;
use Data::Dumper;


our $VERSION = '0.05';


use base 'Data::Conveyor::App::Test::Stage';


use constant DEFAULTS => (
    expected_stage_const => 'ST_TXSEL',
);


sub plan_test {
    my ($self, $test, $run) = @_;
    $self->plan_ticket_expected_container($test, $run) + 1;
}


sub test_expectations {
    my $self = shift;
    $self->SUPER::test_expectations(@_);
    $self->check_ticket_expected_container;

    is_deeply_flex(
        $self->ticket->payload->comparable,
        $self->expect->{payload}->comparable,
        'resulting payload'
    ) or print Dumper $self->ticket->payload->comparable;
}


1;


__END__



=head1 NAME

Data::Conveyor::App::Test::Stage::TxSelector - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::App::Test::Stage::TxSelector->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::App::Test::Stage::TxSelector inherits from
L<Data::Conveyor::App::Test::Stage>.

The superclass L<Data::Conveyor::App::Test::Stage> defines these methods
and functions:

    _by_dump(), before_stage_hook(), check_ticket_expected_container(),
    check_ticket_rc_status(), check_ticket_tx(),
    clear_expected_stage_const(), clear_stage(), clear_ticket(),
    clear_ticket_no(), compare_exceptions(), execute_test_def(),
    expected_stage(), expected_stage_const(), expected_stage_const_clear(),
    gen_tx_item_ref(), is_deep_set(), make_stage_object(), make_ticket(),
    plan_ticket_expected_container(), plan_ticket_tx(), run_test(),
    stage(), stage_clear(), ticket(), ticket_clear(), ticket_no(),
    ticket_no_clear()

The superclass L<Class::Scaffold::App::Test::YAMLDriven> defines these
methods and functions:

    app_code(), clear_current_test_def(), clear_expect(), clear_run_num(),
    clear_runs(), clear_test_def(), clear_testdir(), clear_testname(),
    current_test_def(), current_test_def_clear(), delete_test_def(),
    exists_test_def(), expect(), expect_clear(), keys_test_def(),
    make_plan(), named_test(), read_test_defs(), run_num(),
    run_num_clear(), runs(), runs_clear(), should_skip(),
    should_skip_testname(), test_def(), test_def_clear(),
    test_def_delete(), test_def_exists(), test_def_keys(),
    test_def_values(), testdir(), testdir_clear(), testname(),
    testname_clear(), todo_skip_test(), values_test_def()

The superclass L<Class::Scaffold::App::CommandLine> defines these methods
and functions:

    app_finish(), app_init(), clear_opt(), delete_opt(), exists_opt(),
    keys_opt(), opt(), opt_clear(), opt_delete(), opt_exists(), opt_keys(),
    opt_values(), usage(), values_opt()

The superclass L<Class::Scaffold::App> defines these methods and functions:

    clear_initialized(), initialized(), initialized_clear(),
    initialized_set(), run_app(), set_initialized()

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

