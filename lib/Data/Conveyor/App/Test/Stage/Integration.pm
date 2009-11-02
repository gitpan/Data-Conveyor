package Data::Conveyor::App::Test::Stage::Integration;

# $Id: Integration.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;
use Test::More;
use Test::Builder;


our $VERSION = '0.08';


use base 'Data::Conveyor::App::Test::Stage';


__PACKAGE__
    ->mk_scalar_accessors(qw(dispatcher next_open_stage failed_tests))
    ->mk_array_accessors(qw(expect_list));


use constant runs => 1;


sub plan_test {
    my ($self, $test, $run) = @_;

    # For integration tests, the expect block consists of several more expect
    # blocks, which are checked while the ticket is processed repeatedly by
    # the test dispatcher.

    # There's at least one test (we do expect at least an expected stage in
    # each expect sub-block).

    my $plan = 0;
    for (grep { !exists $_->{initial_stage} } @{ $test->{expect} || [] }) {
        # plan_ticket_* needs a hash with an 'expect' key
        my $subexpect = { expect => $_ };
        $plan +=
            $self->plan_ticket_expected_container($subexpect, $run) +
            $self->plan_ticket_tx($subexpect) +
            1;      # stage
    }

    $plan;
}


sub run_subtest {
    my $self = shift;

    # We can create the dispatcher only here, not in init(), because there's
    # not storage yet in init(). The storage is created only in the
    # superclass's run() method, during Class::Scaffold::App::app_code(). But
    # to simulate realistic conditions, we only create the dispatcher object
    # once, i.e. it's expected to handle many requests.

    $self->dispatcher($self->delegate->make_obj('ticket_dispatcher_test')->new(
        # storage  => $self->storage,
        callback => $self)
    ) unless defined $self->dispatcher;

    # For integration tests, the expect block should be an array reference,
    # where each element contains the expect block that we check the ticket
    # against during each phase of the ticket's life cycle. The check_*
    # methods in Data::Conveyor::App::Test::Stage (e.g.,
    # check_ticket_rc_status()) need to have that single expect block in the
    # expect() accessor, however. So we remember the list of expect blocks in
    # another accessor, expect_list(). See check_dispatched_ticket() for the
    # rest of the story.

    $self->expect_list(@{ $self->expect });

    # Get the first expect element; it should contain the initial stage. We
    # need it so we can open() the ticket. Later, after_ticket_finished() will
    # update the value so that we always know which stage to open the ticket
    # in.

    $self->next_open_stage(
        $self->delegate->make_obj('value_ticket_stage')->new(value =>
            $self->expect_list_shift->{initial_stage})->name
    );

    # Repeatedly call the dispatcher until we don't have any more expect
    # blocks or until a test failed within this run.

    while ($self->expect_list_count && !$self->failed_tests) {
        $self->run_stage_test;
    }
}


sub run_stage_test {
    my $self = shift;

    my $ticket = $self->delegate->make_obj('ticket', 
        ticket_no => $self->ticket_no,
    );
    $ticket->open($self->next_open_stage);

    $self->dispatcher->dispatch($ticket);

    # Did any tests already fail within this run?
    $self->failed_tests(grep { !$_->{ok} } Test::Builder->new->details);
}


sub check_ticket_stage {
    my $self = shift;
    is($self->ticket->stage, $self->expect->{stage},
        sprintf 'stage %s', $self->expect->{stage});
}


sub check_dispatched_ticket {
    my $self = shift;

    # Get the next expect block from the expect block list and set it on the
    # expect() accessor so that the check_* methods that follow will know what
    # to check against.

    # Stop when we don't have any more expect blocks

    my $expect = $self->expect_list_shift;
    return unless defined $expect;

    $self->expect($expect);

    # Get the ticket from the dispatcher (it's a new object every time around)
    # and set it on our ticket() accessor so that the check_* methods that
    # follow can do their work. Also set the stage object, needed by
    # check_ticket_expected_container().

    $self->ticket($self->dispatcher->ticket);
    $self->stage($self->dispatcher->stage);

    $self->check_ticket_stage;
    $self->check_ticket_expected_container;
    $self->check_ticket_tx;
}


# Callback methods from test ticket dispatcher; callback was set up
# in this object's init() method.

sub after_ticket_closed {
    my $self = shift;
    print "# ticket closed\n";
    $self->check_dispatched_ticket;
}


sub after_ticket_finished {
    my $self = shift;
    print "# ticket finished\n";
    $self->check_dispatched_ticket;

    # Remember the stage the ticket should be opened in during the next
    # dispatcher run.

    $self->next_open_stage(
        $self->delegate->make_obj('value_ticket_stage')->new(
            value => $self->expect->{stage}
        )->name
    );
}


1;


__END__



=head1 NAME

Data::Conveyor::App::Test::Stage::Integration - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::App::Test::Stage::Integration->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_dispatcher>

    $obj->clear_dispatcher;

Clears the value.

=item C<clear_expect_list>

    $obj->clear_expect_list;

Deletes all elements from the array.

=item C<clear_failed_tests>

    $obj->clear_failed_tests;

Clears the value.

=item C<clear_next_open_stage>

    $obj->clear_next_open_stage;

Clears the value.

=item C<count_expect_list>

    my $count = $obj->count_expect_list;

Returns the number of elements in the array.

=item C<dispatcher>

    my $value = $obj->dispatcher;
    $obj->dispatcher($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<dispatcher_clear>

    $obj->dispatcher_clear;

Clears the value.

=item C<expect_list>

    my @values    = $obj->expect_list;
    my $array_ref = $obj->expect_list;
    $obj->expect_list(@values);
    $obj->expect_list($array_ref);

Get or set the array values. If called without an arguments, it returns the
array in list context, or a reference to the array in scalar context. If
called with arguments, it expands array references found therein and sets the
values.

=item C<expect_list_clear>

    $obj->expect_list_clear;

Deletes all elements from the array.

=item C<expect_list_count>

    my $count = $obj->expect_list_count;

Returns the number of elements in the array.

=item C<expect_list_index>

    my $element   = $obj->expect_list_index(3);
    my @elements  = $obj->expect_list_index(@indices);
    my $array_ref = $obj->expect_list_index(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item C<expect_list_pop>

    my $value = $obj->expect_list_pop;

Pops the last element off the array, returning it.

=item C<expect_list_push>

    $obj->expect_list_push(@values);

Pushes elements onto the end of the array.

=item C<expect_list_set>

    $obj->expect_list_set(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item C<expect_list_shift>

    my $value = $obj->expect_list_shift;

Shifts the first element off the array, returning it.

=item C<expect_list_splice>

    $obj->expect_list_splice(2, 1, $x, $y);
    $obj->expect_list_splice(-1);
    $obj->expect_list_splice(0, -1);

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

=item C<expect_list_unshift>

    $obj->expect_list_unshift(@values);

Unshifts elements onto the beginning of the array.

=item C<failed_tests>

    my $value = $obj->failed_tests;
    $obj->failed_tests($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<failed_tests_clear>

    $obj->failed_tests_clear;

Clears the value.

=item C<index_expect_list>

    my $element   = $obj->index_expect_list(3);
    my @elements  = $obj->index_expect_list(@indices);
    my $array_ref = $obj->index_expect_list(@indices);

Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

=item C<next_open_stage>

    my $value = $obj->next_open_stage;
    $obj->next_open_stage($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<next_open_stage_clear>

    $obj->next_open_stage_clear;

Clears the value.

=item C<pop_expect_list>

    my $value = $obj->pop_expect_list;

Pops the last element off the array, returning it.

=item C<push_expect_list>

    $obj->push_expect_list(@values);

Pushes elements onto the end of the array.

=item C<set_expect_list>

    $obj->set_expect_list(1 => $x, 5 => $y);

Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.

=item C<shift_expect_list>

    my $value = $obj->shift_expect_list;

Shifts the first element off the array, returning it.

=item C<splice_expect_list>

    $obj->splice_expect_list(2, 1, $x, $y);
    $obj->splice_expect_list(-1);
    $obj->splice_expect_list(0, -1);

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

=item C<unshift_expect_list>

    $obj->unshift_expect_list(@values);

Unshifts elements onto the beginning of the array.

=back

Data::Conveyor::App::Test::Stage::Integration inherits from
L<Data::Conveyor::App::Test::Stage>.

The superclass L<Data::Conveyor::App::Test::Stage> defines these methods
and functions:

    _by_dump(), before_stage_hook(), check_ticket_expected_container(),
    check_ticket_rc_status(), check_ticket_tx(),
    clear_expected_stage_const(), clear_stage(), clear_ticket(),
    clear_ticket_no(), compare_exceptions(), execute_test_def(),
    expected_stage(), expected_stage_const(), expected_stage_const_clear(),
    gen_tx_item_ref(), is_deep_set(), make_stage_object(), make_ticket(),
    plan_ticket_expected_container(), plan_ticket_tx(), stage(),
    stage_clear(), test_expectations(), ticket(), ticket_clear(),
    ticket_no(), ticket_no_clear()

The superclass L<Class::Scaffold::App::Test::YAMLDriven> defines these
methods and functions:

    app_code(), clear_current_test_def(), clear_expect(), clear_run_num(),
    clear_runs(), clear_test_def(), clear_testdir(), clear_testname(),
    current_test_def(), current_test_def_clear(), delete_test_def(),
    exists_test_def(), expect(), expect_clear(), keys_test_def(),
    make_plan(), read_test_defs(), run_num(),
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

Copyright 2004-2009 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

