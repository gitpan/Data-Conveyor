package Data::Conveyor::Stage::TransactionIterator;

# $Id: TransactionIterator.pm 13653 2007-10-22 09:11:20Z gr $


use warnings;
use strict;
use Error::Hierarchy::Util 'assert_defined';
use Error::Hierarchy;
use Error ':try';


our $VERSION = '0.05';


use base 'Data::Conveyor::Stage::SingleTicket';


__PACKAGE__
    ->mk_scalar_accessors(qw(factory_method))
    ->mk_boolean_accessors(qw(done));


# Subclasses can override this if they don't want to process certain
# transactions, e.g., a notify stage might want to process all transactions,
# regardless of their status.

sub should_process_transaction {
    my ($self, $transaction) = @_;
    $transaction->status eq $self->delegate->TXS_RUNNING;
}


# Give subclasses a chance to do transaction-wide processing. Normally you
# could do this by subclassing main() and doing your special stuff after
# $self->SUPER::main(@_), but some things affect the transaction handlers
# themselves. Still we don't want to do this before $self->SUPER::main(@_)
# because that would preclude more basic checks (such as done by this class's
# superclass).

sub before_iteration {}


sub main {
    my $self = shift;
    $self->SUPER::main(@_);

    $self->before_iteration;

    # Skip the rest of the stage run if we're marked as done. this might
    # happen if very basic things didn't work out.

    return if $self->done;

    $self->delegate->plugin_handler->run_hook(
        $self->ticket->stage->name . '.start',
        { stage => $self },
    );

    my @extra_tx;
    our $factory ||= $self->delegate->make_obj('transaction_factory');
    my $factory_method = $self->factory_method;
    for my $payload_tx ($self->ticket->payload->transactions) {
        next unless $self->should_process_transaction($payload_tx->transaction);
        try {
            my $transaction_handler = $factory->$factory_method(
                tx     => $payload_tx,
                ticket => $self->ticket,
                stage  => $self,
            );

            $transaction_handler->run;

            $self->delegate->plugin_handler->run_hook(
                sprintf('%s.%s.%s',
                    $self->ticket->stage->name,
                    $payload_tx->transaction->object_type,
                    $payload_tx->transaction->command),
                {
                    transaction_handler => $transaction_handler,
                    stage               => $self,
                }
            );

            # The transaction handler will accumulate exceptions in the
            # exception container of the payload item pointed to by the
            # current transaction.
            #
            # Transaction handlers can ask for extra tx to be run by further
            # stages.  For example, the policy transaction handler for
            # person.update can, when asked to modify otherwise immutable
            # owner fields, downgrade an owner to a contact when that owner
            # isn't used in a delegation. To do so, it adds a
            # person.set-contact tx so that the delegation can downgrade the
            # person.
            #
            # Transaction handlers do so via an extra_tx_list attribute, which
            # is processed here. We don't just push onto
            # $self->ticket->payload->transactions because we are iterating
            # over just that, and it's not recommended to change a list while
            # iterating over it.
            #
            # A null transaction handler - produced by a Class::Null entry in
            # the relevant hashes of the transaction factory - returns another
            # Class::Null object on each of its method calls, so here we'd be
            # pushing a Class::Null object onto @extra_tx. Avoid that.

            if ($transaction_handler->extra_tx_list_count) {
                push @extra_tx =>
                    grep { !UNIVERSAL::isa($_, 'Class::Null') }
                    $transaction_handler->extra_tx_list;
            }

        } catch Error::Hierarchy with {
            # Exception that was thrown, not recorded.
            $payload_tx->transaction->payload_item->exception_container->
                items_set_push($_[0]);
        };
    }

    $self->ticket->payload->add_transaction($_) for @extra_tx;

    $self->delegate->plugin_handler->run_hook(
        $self->ticket->stage->name . '.end',
        { stage => $self },
    );

}


1;


__END__



=head1 NAME

Data::Conveyor::Stage::TransactionIterator - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Stage::TransactionIterator->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item clear_done

    $obj->clear_done;

Clears the boolean value by setting it to 0.

=item clear_factory_method

    $obj->clear_factory_method;

Clears the value.

=item done

    $obj->done($value);
    my $value = $obj->done;

If called without an argument, returns the boolean value (0 or 1). If called
with an argument, it normalizes it to the boolean value. That is, the values
0, undef and the empty string become 0; everything else becomes 1.

=item done_clear

    $obj->done_clear;

Clears the boolean value by setting it to 0.

=item done_set

    $obj->done_set;

Sets the boolean value to 1.

=item factory_method

    my $value = $obj->factory_method;
    $obj->factory_method($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item factory_method_clear

    $obj->factory_method_clear;

Clears the value.

=item set_done

    $obj->set_done;

Sets the boolean value to 1.

=back

Data::Conveyor::Stage::TransactionIterator inherits from
L<Data::Conveyor::Stage::SingleTicket>.

The superclass L<Data::Conveyor::Stage::SingleTicket> defines these methods
and functions:

    MUNGE_CONSTRUCTOR_ARGS(), clear_expected_stage(),
    clear_log_max_level_previous(), end(), expected_stage(),
    expected_stage_clear(), log_max_level_previous(),
    log_max_level_previous_clear(), stage_delegate(),
    stage_delegate_clear(), stage_delegate_exists(), ticket(),
    ticket_clear(), ticket_exists()

The superclass L<Data::Conveyor::Stage> defines these methods and
functions:

    begin(), clear_will_shift_ticket(), run(), will_shift_ticket(),
    will_shift_ticket_clear()

The superclass L<Class::Scaffold::Storable> defines these methods and
functions:

    clear_storage_info(), clear_storage_type(), delete_storage_info(),
    exists_storage_info(), id(), keys_storage_info(), storage(),
    storage_info(), storage_info_clear(), storage_info_delete(),
    storage_info_exists(), storage_info_keys(), storage_info_values(),
    storage_type(), storage_type_clear(), values_storage_info()

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

