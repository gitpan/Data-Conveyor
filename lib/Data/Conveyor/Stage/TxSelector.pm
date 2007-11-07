package Data::Conveyor::Stage::TxSelector;

# $Id: TxSelector.pm 13653 2007-10-22 09:11:20Z gr $

# Implements the transaction selector (txsel)

use warnings;
use strict;
use Error::Hierarchy::Util 'assert_defined';


our $VERSION = '0.01';


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

Data::Conveyor - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

None yet (see below).

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<dataconveyor> tag.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-conveyor@rt.cpan.org>, or through the web interface at
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

Copyright 2007 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

