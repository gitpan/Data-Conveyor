package Data::Conveyor::Stage::TxSelector;

# $Id: TxSelector.pm 13653 2007-10-22 09:11:20Z gr $

# Implements the transaction selector (txsel)

use warnings;
use strict;
use Error::Hierarchy::Util 'assert_defined';


our $VERSION = '0.03';


use base 'Data::Conveyor::Stage::SingleTicket';


sub DEFAULTS {
    (expected_stage => $_[0]->delegate->ST_TXSEL)
}


# Return a list of object types that specifies in which order payload items
# should be traversed. Subclasses might need to override this with a specific
# order, for example, when new payload items are created implicitly.
#
# don't include transaction itself in calculating transactions

sub object_type_iteration_order {
    grep { $_ ne $_[0]->delegate->OT_TRANSACTION } $_[0]->delegate->OT;
}


sub main {
    my ($self, %args) = @_;
    $self->SUPER::main(%args);

    # Txsel handlers can create implicit payload items; to ensure idempotency,
    # we remove them before reprocessing the ticket.

    $self->ticket->payload->delete_implicit_items;
    $self->ticket->payload->transactions_clear;
    $self->before_object_type_iteration;

    for my $object_type ($self->object_type_iteration_order) {
        for my $payload_item ($self->ticket->payload->
            get_list_for_object_type($object_type)) {

            $self->calc_implicit_tx($object_type, $payload_item,
                $self->delegate->CTX_BEFORE);
            $self->calc_explicit_tx($object_type, $payload_item);
            $self->calc_implicit_tx($object_type, $payload_item,
                $self->delegate->CTX_AFTER);
        }
    }

    $self->after_object_type_iteration;
}


# Two events that subclasses might want to handle

sub before_object_type_iteration {}
sub after_object_type_iteration  {}


sub calc_explicit_tx {
    my ($self, $object_type, $payload_item) = @_;
    $self->ticket->payload->add_transaction(
        object_type  => $object_type,
        command      => $payload_item->command,
        type         => $self->delegate->TXT_EXPLICIT,
        status       => $self->delegate->TXS_RUNNING,
        payload_item => $payload_item,
        necessity    => $self->delegate->TXN_MANDATORY,
    );
}


# find and set implicit transactions in the current object.

sub calc_implicit_tx {
    my ($self, $object_type, $payload_item, $context) = @_;
    our $factory ||= $self->delegate->make_obj('transaction_factory');

    assert_defined $context, 'called without context.';
    assert_defined $object_type, 'called without object_type.';
    assert_defined $payload_item, 'called without payload item.';

    $factory->gen_txsel_handler(
        $object_type,
        $payload_item->{command},
        $context,

        payload_item => $payload_item,
        ticket       => $self->ticket,
    )->calc_implicit_tx;
}


1;


__END__



=head1 NAME

Data::Conveyor::Stage::TxSelector - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Stage::TxSelector->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::Stage::TxSelector inherits from
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

    new(), add_autoloaded_package(), init(), log()

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

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<dataconveyor> tag.

=head1 VERSION 
                   
This document describes version 0.03 of L<Data::Conveyor::Stage::TxSelector>.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<<bug-data-conveyor@rt.cpan.org>>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

Florian Helmberger C<< <fh@univie.ac.at> >>

Achim Adam C<< <ac@univie.ac.at> >>

Mark Hofstetter C<< <mh@univie.ac.at> >>

Heinz Ekker C<< <ek@univie.ac.at> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2008 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

