package Data::Conveyor::Exception::Container;

# $Id: Container.pm 13653 2007-10-22 09:11:20Z gr $

# implements a container object.

use strict;
use warnings;
use Data::Miscellany qw/set_push flex_grep/;


our $VERSION = '0.10';


use base 'Class::Scaffold::Exception::Container';


sub get_disruptive_items {
    my ($self, $ticket) = @_;
    return
        grep { !$ticket->ignores_exception($_) && !$_->is_optional }
        $self->items;
}


# determines the overall rc of the item's exceptions

sub rc {
    my ($self, $ticket, $payload_item) = @_;
    my $handler = $self->delegate->make_obj('exception_handler');
    my $rc = $self->delegate->make_obj('value_ticket_rc', 
        $self->delegate->RC_OK);
    $rc += $handler->rc_for_exception_class($_, $payload_item)
        for $self->get_disruptive_items($ticket);
    $rc;
}


# determines the overall status of the item's exceptions

sub status {
    my ($self, $ticket, $payload_item) = @_;
    my $handler = $self->delegate->make_obj('exception_handler');
    my $status = $self->delegate->make_obj('value_ticket_status', 
        $self->delegate->TS_RUNNING);

    # Add the status only for exceptions that have an rc that's equal to the
    # ticket's rc -- assuming the ticket's rc has been calculated before, of
    # course. For an explanation, assume the following situation:
    #
    # A ticket has recorded two exceptions: One with RC_OK and TS_HOLD, the
    # other with RC_ERROR and TS_RUNNING. If we just added rc's and stati
    # independently of each other, we'd end up with RC_ERROR and TS_HOLD. This
    # is not what we want. The ticket should go on hold -- for manual
    # inspection -- only if there weren't more serious issues. After all, we
    # don't want to waste a person's time only to later declare that the
    # ticket has serious problems anyway and to abort processing.
    #
    # What we want to end up with in the above situation is RC_ERROR and
    # TS_RUNNING so that the ticket is aborted. We do this by applying the
    # stati of only those exceptions that caused the ticket's overall rc.
    #
    # In our example, that's the exception that caused the RC_ERROR. Since
    # that exception has TS_RUNNING, that's the status we end up with. Which
    # is nice.

    $status += $handler->status_for_exception_class($_, $payload_item)
        for $self->filter_exceptions_by_rc($ticket, $ticket->rc);
    $status;
}


sub filter_exceptions_by_rc {
    my ($self, $ticket, @filter) = @_;
    my $handler = $self->delegate->make_obj('exception_handler');
    grep {
        flex_grep ($handler->rc_for_exception_class($_), @filter)
    } $self->get_disruptive_items($ticket);
}


sub filter_exceptions_by_status {
    my ($self, $ticket, @filter) = @_;
    my $handler = $self->delegate->make_obj('exception_handler');
    grep {
        flex_grep ($handler->status_for_exception_class($_), @filter)
    } $self->get_disruptive_items($ticket);
}


# Transactions ask their item (which asks their exception container) whether
# it has problematic exceptions that should cause the transaction's status to
# be set to $self->delegate->TXS_ERROR. See Data::Conveyor::Ticket::Transaction.
#
# Ordinarily, exceptions with an rc of RC_ERROR or RC_INTERNAL_ERROR are
# considered problematic. The exception's status can also have an effect on
# the tx's status. For example, in NICAT, an ::Onwait exception will have
# RC_OK and TS_HOLD, which should leave the tx on TXS_RUNNING in non-mass
# tickets (i.e., the legal department will decide whether to shift the ticket
# to the delegation stage). Same for RC_MANUAL. I.e., set the tx status only
# to TXS_ERROR if the exception indicates an RC_ERROR or an RC_INTERNAL_ERROR.
# In mass tickets, we don't want to hold up the ticket - just set the
# corresponding exception to TXS_ERROR - but only for optional exceptions.

sub has_problematic_exceptions {
    my ($self, $ticket, $payload_item) = @_;
    my $handler         = $self->delegate->make_obj('exception_handler');

    # Don't use get_disruptive_items() because that would weed out exceptions
    # marked with is_optional() as well. But even optional exceptions should
    # cause a TXS_ERROR, if they aren't RC_OK.

    my @exceptions =
        grep { !$ticket->ignores_exception($_) }
        $self->items;

    for my $exception (@exceptions) {
        my $rc     = $handler->rc_for_exception_class(
            $exception, $payload_item);
        my $status = $handler->status_for_exception_class($exception);

        return 1 if
            $rc     eq $self->delegate->RC_ERROR          ||
            $rc     eq $self->delegate->RC_INTERNAL_ERROR ||
            !($status eq $self->delegate->TS_RUNNING      ||
              $status eq $self->delegate->TS_HOLD         ||
              $status eq $self->delegate->TS_PENDING);
    }

    return 0;
}


1;


__END__



=head1 NAME

Data::Conveyor::Exception::Container - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Exception::Container->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::Exception::Container inherits from
L<Class::Scaffold::Exception::Container>.

The superclass L<Error::Hierarchy::Container> defines these methods and
functions:

    delete_by_uuid(), record()

The superclass L<Data::Container> defines these methods and functions:

    new(), clear_items(), count_items(), index_items(), item_grep(),
    items(), items_clear(), items_count(), items_index(), items_pop(),
    items_push(), items_set(), items_set_push(), items_shift(),
    items_splice(), items_unshift(), pop_items(), prepare_comparable(),
    push_items(), set_items(), shift_items(), splice_items(), stringify(),
    unshift_items()

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

The superclass L<Error::Hierarchy::Base> defines these methods and
functions:

    dump_as_yaml(), dump_raw()

The superclass L<Error> defines these methods and functions:

    _throw_Error_Simple(), associate(), catch(), file(), flush(), import(),
    line(), object(), prior(), stacktrace(), text(), throw(), value(),
    with()

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

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

    FIRST_CONSTRUCTOR_ARGS(), add_autoloaded_package(), init(), log()

The superclass L<Data::Comparable> defines these methods and functions:

    comparable(), comparable_scalar(), dump_comparable(),
    yaml_dump_comparable()

The superclass L<Class::Scaffold::Delegate::Mixin> defines these methods
and functions:

    delegate()

The superclass L<Class::Scaffold::Accessor> defines these methods and
functions:

    mk_framework_object_accessors(), mk_framework_object_array_accessors(),
    mk_readonly_accessors()

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

