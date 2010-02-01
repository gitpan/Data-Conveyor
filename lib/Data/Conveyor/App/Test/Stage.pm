package Data::Conveyor::App::Test::Stage;
use strict;
use warnings;
use YAML::Active 'Dump';
use String::FlexMatch::Test;
use Test::More;
use Data::Dumper;
our $VERSION = '0.11';
use base 'Class::Scaffold::App::Test::YAMLDriven';
$Data::Dumper::Indent = 1;
__PACKAGE__->mk_scalar_accessors(
    qw(
      ticket ticket_no stage expected_stage_const
      )
);
use constant DEFAULTS => (runs => 2,);

sub expected_stage {
    my $self   = shift;
    my $method = $self->expected_stage_const;
    $self->delegate->$method;
}

sub execute_test_def {
    my ($self, $testname) = @_;
    if ($self->should_skip_testname($testname)) {
        $self->SUPER::execute_test_def($testname);
    } else {
        $self->make_ticket($testname);
        $self->SUPER::execute_test_def($testname);

        # During the test run it's not really necessary to delete the ticket
        # because we'll rollback anyway, and deleting a ticket is expensive.
        # $self->ticket->delete;
    }
}

sub make_ticket {
    my ($self, $testname) = @_;

    # No support for phases at this time - we don't need them and Reload() is
    # expensive.
    # $self->test_def($testname,
    #     Reload($self->test_def($testname), $self->delegate->YAP_MAKE_TICKET)
    # );
    my $ticket =
      $self->delegate->make_obj('test_ticket')
      ->make_whole_ticket(%{ $self->test_def($testname)->{make_whole_ticket} });
    $self->gen_tx_item_ref($ticket->payload);
    $ticket->store_full;

    # Set up some accessors so other methods can refer to them.
    $self->ticket_no($ticket->ticket_no);
}

sub gen_tx_item_ref {
    my ($self, $payload) = @_;
    for my $payload_tx ($payload->transactions) {
        my $item_spec = $payload_tx->transaction->payload_item;
        next if ref $item_spec;
        if ($item_spec =~ /^(\w+)\.(\d+)$/) {
            my ($accessor, $index) = ($1, $2 - 1);
            $payload_tx->transaction->payload_item(
                eval "\$payload->$accessor\->[$index]");
            die $@ if $@;
        }
        unless (ref $payload_tx->transaction->payload_item) {
            throw Error::Hierarchy::Internal::CustomMessage(
                custom_message => sprintf 'No such payload item [%s]',
                $item_spec,
            );
        }
    }
}

sub make_stage_object {
    my $self = shift;
    $self->stage($self->delegate->make_stage_object($self->expected_stage, @_));
}

# subclasses can do preparatory things here
sub before_stage_hook { }

sub run_subtest {
    my $self = shift;

    # At this point, set any local configuration the test yaml file might have
    # asked for.
    local %Property::Lookup::Local::opt = (
        %Property::Lookup::Local::opt,
        %{ $self->current_test_def->{opt} || {} },
    );
    my $ticket =
      $self->delegate->make_obj('ticket', ticket_no => $self->ticket_no);
    $ticket->open($self->expected_stage);
    $self->before_stage_hook($ticket);
    $self->stage($self->make_stage_object(ticket => $ticket));
    $self->stage->run;
    $ticket->store if $ticket->rc eq $self->delegate->RC_INTERNAL_ERROR;
    $ticket->close;

    # The ticket that we test our expectations against is a fresh ticket
    # object where we read the ticket we just wrote. Note that we read(), not
    # open() the ticket, because after the stage run, it will still be in
    # an 'active_*' stage, and open() wouldn't find it.
    $self->ticket(
        $self->delegate->make_obj('ticket', ticket_no => $self->ticket_no,));
    $self->ticket->read;
    $self->test_expectations;

    # To prepare for the next run, reset the ticket to the stage start and an
    # ok status and rc, just as you'd do manually when rerunning the ticket in
    # the regsh. Note that this is the same as would happen in the regsh when
    # given the command 'set_stage -g starten_<stagename>'
    for ($self->ticket) {
        $_->stage->new_start($self->expected_stage);
        $_->status($self->delegate->TS_RUNNING);
        $_->rc($self->delegate->RC_OK);
        $_->close_basic;
    }
}

# so subclasses can call SUPER::
sub test_expectations { }

sub plan_ticket_expected_container {
    my ($self, $test, $run) = @_;
    my $plan = 2;    # rc, status

    # The expected exceptions look like this in the YAML files:
    #
    #    exceptions:
    #      person:
    #        -
    #          # expect the following exceptions for the first person
    #          - ref: Registry::Exception::Person::InvalidEmail
    #            handle: ...
    #            email: ...
    #          - ref: Registry::Exception::Person::InvalidName
    #            handle: ...
    #            name ...
    #        -
    #          # expect the following exceptions for the second person
    #          - ref: ...
    #            ...
    #      domains:
    #        -
    #          # expect the following exceptions for the first domain
    #          - ref: ...
    #            ...
    #
    # Usually, we expect two tests per exception per run (one for the
    # exception's type and for for its message). There's a special
    # case that complicates the thing a bit: Some policies actually alter the
    # ticket. For example, if, in a person, we detect an alias name for a
    # country (e.g., 'Oesterreich', which is mapped to the normal name,
    # 'Austria'), the policy actually replaces the country name with the
    # normal name. So the second time around, the country name will be the
    # normal one and no exception is thrown.
    while (my ($object_type, $spec) =
        each %{ $test->{expect}{exceptions} || {} }) {
        for my $payload_item (@$spec) {
            for my $exception (
                ref $payload_item eq 'ARRAY'
                ? @$payload_item
                : $payload_item
              ) {
                next unless ref($exception) eq 'HASH';
                next
                  if $run > 1
                      && $exception->{ref} =~ /Replace(Fax|Phone)No$/;
                $plan += 2;
            }
        }
    }
    $plan;
}

sub plan_ticket_tx {
    my ($self, $test) = @_;
    exists $test->{expect}{tx};
}

sub check_ticket_rc_status {
    my $self = shift;
    is( $self->ticket->rc,
        $self->expect->{rc} || $self->delegate->RC_OK,
        'rc'
    );
    is( $self->ticket->status,
        $self->expect->{status} || $self->delegate->TS_RUNNING,
        'status'
    );
}

sub check_ticket_tx {
    my $self = shift;
    return unless exists $self->expect->{tx};
    my @tx_status =
      map { $_->transaction->status } $self->ticket->payload->transactions;

    # Dump as YAML on failure, so we see the stringified values, not the value
    # objects.
    ok(eq_array_flex(\@tx_status, $self->expect->{tx}), 'resulting tx status')
        or print Dump \@tx_status;
}

sub check_ticket_expected_container {
    my $self = shift;
    $self->check_ticket_rc_status($self->ticket);
    for my $object_type ($self->delegate->OT) {
        my $item_index = 0;
        for my $payload_item (
            $self->ticket->payload->get_list_for_object_type($object_type)) {
            $self->compare_exceptions(
                $object_type,
                $payload_item,
                (   $self->expect->{exceptions}{$object_type}[ $item_index++ ]
                      || []
                ),
            );
        }
    }
    $self->compare_exceptions(
        'common',
        $self->ticket->payload->common,
        ($self->expect->{exceptions}{common} || []),
    );
}

sub compare_exceptions {
    my ($self, $object_type, $payload_item, $expected_exceptions) = @_;
    my $exception_index = 0;
    return unless ref $expected_exceptions eq 'ARRAY';

    # Impose an order on the exceptions, namely the way they stringify for the
    # benefit of the yaml test files.
    for my $got_exception (sort { "$a" cmp "$b" }
        $payload_item->exception_container->items) {
        unless (exists $expected_exceptions->[$exception_index]) {
            fail(
                sprintf
                  "Unexpected exception on [%s] of type [%s], message [%s]",
                $object_type, ref($got_exception), $got_exception
            );
            print Dumper $got_exception;
            next;
        }

        # Ok, we did expect an exception, so check whether it's the
        # right one.
        my $expected_exception = $expected_exceptions->[$exception_index];
        isa_ok($got_exception, $expected_exception->{ref});

        # FIXME
        # hack for Class::Value::Exception::InvalidValue, which has a property
        # called 'ref'. But the test definition of the expected exception also
        # has a 'ref' property to indicate what type of exception we expect.
        # So the test def's 'p_ref' is munged to become the 'ref' of
        # Class::Value::Exception::InvalidValue. Solution: call the exception
        # property something else.
        #
        # Example:
        #
        # exceptions:
        #   person:
        #     -
        #       -
        #         ref: Class::Value::Exception::InvalidValue
        #         p_ref: Registry::NICAT::Value::Person::Handle
        #         value: *HANDLE
        my %expected_properties = %$expected_exception;
        delete $expected_properties{ref};
        $expected_properties{ref} = delete $expected_properties{p_ref}
          if $expected_properties{p_ref};
        is_deeply_flex(scalar($got_exception->properties_as_hash),
            \%expected_properties, 'exception properties')
          or print Dumper $got_exception;

        # Following the same logic as commented in
        # plan_ticket_expected_container(), eliminate those exceptions
        # from the expected list after the first run that would only
        # occur in the first run, i.e. Replace* exceptions. That way,
        # we won't even see them in the list of expected exceptions in
        # the second and subsequent runs.
        if (   $self->run_num == 1
            && defined($expected_exception)
            && $expected_exception->{ref} =~ /Replace(Fax|Phone)No$/) {
            splice @$expected_exceptions, $exception_index, 1;
        }
    } continue {
        $exception_index++;
    }

    # Now we check whether there are further expected exceptions -
    # this would be ones we expected but didn't get.
    while (defined(my $extra = $expected_exceptions->[ $exception_index++ ])) {
        fail(sprintf "Didn't see expected exception of type [%s]",
            $extra->{ref},);
    }
}

sub is_deep_set {
    my ($self, $got, $expect, $test_name) = @_;
    $got    = [ sort _by_dump @{ $got    || [] } ];
    $expect = [ sort _by_dump @{ $expect || [] } ];
    is_deeply_flex($got, $expect, $test_name)
      or print
      YAML::Active::Dump($got,    ForceBlock => 0),
      YAML::Active::Dump($expect, ForceBlock => 0);
}
sub _by_dump { YAML::Active::Dump($a) cmp YAML::Active::Dump($b) }
1;
__END__



=head1 NAME

Data::Conveyor::App::Test::Stage - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::App::Test::Stage->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_expected_stage_const>

    $obj->clear_expected_stage_const;

Clears the value.

=item C<clear_stage>

    $obj->clear_stage;

Clears the value.

=item C<clear_ticket>

    $obj->clear_ticket;

Clears the value.

=item C<clear_ticket_no>

    $obj->clear_ticket_no;

Clears the value.

=item C<expected_stage_const>

    my $value = $obj->expected_stage_const;
    $obj->expected_stage_const($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<expected_stage_const_clear>

    $obj->expected_stage_const_clear;

Clears the value.

=item C<stage>

    my $value = $obj->stage;
    $obj->stage($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<stage_clear>

    $obj->stage_clear;

Clears the value.

=item C<ticket>

    my $value = $obj->ticket;
    $obj->ticket($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<ticket_clear>

    $obj->ticket_clear;

Clears the value.

=item C<ticket_no>

    my $value = $obj->ticket_no;
    $obj->ticket_no($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<ticket_no_clear>

    $obj->ticket_no_clear;

Clears the value.

=back

Data::Conveyor::App::Test::Stage inherits from
L<Class::Scaffold::App::Test::YAMLDriven>.

The superclass L<Class::Scaffold::App::Test::YAMLDriven> defines these
methods and functions:

    app_code(), clear_current_test_def(), clear_expect(), clear_run_num(),
    clear_runs(), clear_test_def(), clear_testdir(), clear_testname(),
    current_test_def(), current_test_def_clear(), delete_test_def(),
    exists_test_def(), expect(), expect_clear(), keys_test_def(),
    make_plan(), plan_test(), read_test_defs(), run_num(),
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

