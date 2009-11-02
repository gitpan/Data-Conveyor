package Data::Conveyor::Ticket::Dispatcher;

# $Id: Dispatcher.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;
use Error ':try';


our $VERSION = '0.08';


use base 'Class::Scaffold::Storable';


use constant DEFAULTS => (transactional_authority => 1);


__PACKAGE__
    ->mk_scalar_accessors(qw(stage))
    ->mk_framework_object_accessors(ticket => 'ticket')
    ->mk_boolean_accessors(qw(transactional_authority));


sub dispatch {
    my $self = shift;
    $self->ticket(+shift) if @_;
    my $stage_name = $self->ticket->stage->name;

    try {
        $self->stage($self->delegate->make_stage_object($stage_name));
        $self->stage->ticket($self->ticket) if $self->stage->can('ticket');
        $self->stage->run;
        $self->finish_ticket;
    } catch Error with {
        my $E = shift;
        throw $E unless $self->transactional_authority;
        require Data::Dumper;
        local $Data::Dumper::Indent = 1;
        throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
            sprintf('exception while processing stage [%s]: %s',
                $stage_name, Data::Dumper::Dumper($E))
        );
    };
}


# Close_ticket is a method so subclasses get a chance to do additional things.

sub close_ticket {
    my $self = shift;
    $self->ticket->close;
}


sub finish_ticket {
    my $self = shift;

    # If there's an internal error, rollback any actions done so far (e.g.,
    # half-finished delegations). However, do store the errors and leave the
    # ticket with RC_INTERNAL_ERROR. To do so, we explicitly store and close
    # the ticket after the rollback. Without doing so, the ticket wouldn't be
    # closed and would remain in 'aktiv_*', plus the errors wouldn't be
    # recorded.
    #
    # If the ticket has TS_RUNNING (regardless of the rc, which could be RC_OK
    # or RC_ERROR), we close and shift the ticket; in any other case (e.g.,
    # TS_HOLD), we close the ticket, but don't shift it.

    if ($self->ticket->rc eq $self->delegate->RC_INTERNAL_ERROR) {
        # special case for conveyor/epp: we want the container to be
        # thrown. the engine will log a dump of the ticket and roll it
        # back.
        my $container = $self->ticket->filter_exceptions_by_rc(
            $self->delegate->RC_INTERNAL_ERROR);
        $self->log->info($container);
        if ($self->transactional_authority) {
            $self->delegate->rollback;
            $self->ticket->store;
            $self->close_ticket;
        } else {
            throw $container;
        }
    } elsif ($self->ticket->status eq $self->delegate->TS_RUNNING) {
        $self->close_ticket;
        $self->ticket->shift_stage if $self->stage->will_shift_ticket;
    } else {
        $self->close_ticket;
    }

    # the conveyor needs the possibility to leave rollback/commit to a
    # higher instance.

    return unless $self->transactional_authority;

    # We need to commit or rollback the changes made while this ticket was
    # processed, because the dispatcher processes a potentially large number
    # of tickets and we wouldn't rollback everything just because the 300th
    # ticket has a problem. Besides, committing is necessary for the ticket
    # provider to keep handing out tickets to other processes (since the
    # transaction under which the database changes are done are limited to
    # this process only.

    # Class::Scaffold::App::Test sets the rollback_mode, which is ok since we
    # want the storages to respect that. But at this point we want to
    # commit in test mode regardless of whether rollback_mode is set (so
    # integration tests work).

    if ($self->delegate->rollback_mode && !$self->delegate->test_mode) {
        $self->delegate->rollback;
    } else {
        $self->delegate->commit;
    }
}


1;


__END__



=head1 NAME

Data::Conveyor::Ticket::Dispatcher - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Ticket::Dispatcher->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_stage>

    $obj->clear_stage;

Clears the value.

=item C<clear_transactional_authority>

    $obj->clear_transactional_authority;

Clears the boolean value by setting it to 0.

=item C<set_transactional_authority>

    $obj->set_transactional_authority;

Sets the boolean value to 1.

=item C<stage>

    my $value = $obj->stage;
    $obj->stage($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<stage_clear>

    $obj->stage_clear;

Clears the value.

=item C<transactional_authority>

    $obj->transactional_authority($value);
    my $value = $obj->transactional_authority;

If called without an argument, returns the boolean value (0 or 1). If called
with an argument, it normalizes it to the boolean value. That is, the values
0, undef and the empty string become 0; everything else becomes 1.

=item C<transactional_authority_clear>

    $obj->transactional_authority_clear;

Clears the boolean value by setting it to 0.

=item C<transactional_authority_set>

    $obj->transactional_authority_set;

Sets the boolean value to 1.

=back

Data::Conveyor::Ticket::Dispatcher inherits from
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

