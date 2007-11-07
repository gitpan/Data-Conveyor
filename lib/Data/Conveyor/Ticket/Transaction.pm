package Data::Conveyor::Ticket::Transaction;

# $Id: Transaction.pm 13653 2007-10-22 09:11:20Z gr $
#
# Represents a single transaction as selected by txsel

use warnings;
use strict;


our $VERSION = '0.01';


use base 'Class::Scaffold::Storable';


__PACKAGE__
    ->mk_scalar_accessors(qw(payload_item))
    ->mk_framework_object_accessors(
        value_object_type           => 'object_type',
        value_command               => 'command',
        value_transaction_type      => 'type',
        value_transaction_status    => 'status',
        value_transaction_necessity => 'necessity',
    );


sub is_optional {
    my $self = shift;
    $self->necessity eq $self->delegate->TXN_OPTIONAL;
}


sub update_status {
    my ($self, $ticket) = @_;

    # Apply a default value, but don't change transactions that are set to
    # TXS_IGNORE. This is relevant if you manually delete exceptions (via a
    # service interface) - then you also want to reset transaction stati.

    $self->status($self->delegate->TXS_RUNNING) if
        $self->status eq $self->delegate->TXS_ERROR;
    return unless $self->payload_item->has_problematic_exceptions($ticket);
    $self->status($self->delegate->TXS_ERROR);
}


# Check that the current transaction's command is allowed for the ticket's
# type. For example, a 'perscreate' must only contain 'create' commands.
#
# Don't check the value objects this transaction object consists of, like we
# do with business objects - we generated the transaction object, and we
# expect it to be correct. It should have been created with checks on, so
# illegal arguments should have been spotted then and there (probably in the
# txsel).
#
# Note that exceptions are recorded not into the exception container this
# method is given in the second arg, but into the exception container of the
# payload item this transaction points to. That's because update_status() checks
# the referenced payload item's exception container to see whether to set this
# transaction's status to TXS_ERROR; an illegal transaction given the current
# ticket type should certainly be considered a problematic exception.

sub check {
    my ($self, $exception_container, $ticket) = @_;
    $self->check_policy_allowed_tx_for_ticket_type($ticket);
}


sub check_policy_allowed_tx_for_ticket_type {
    my ($self, $ticket) = @_;

    return if $self->storage->policy_allowed_tx_for_ticket_type(
        ticket_type => $ticket->type,
        object_type => $self->object_type,
        command     => $self->command,
        txtype      => $self->type,
    );

    throw Data::Conveyor::Exception::CommandDenied(
        ticket_type    => $ticket->type,
        object_type    => $self->object_type,
        command        => $self->command,
    );
}


use constant SKIP_COMPARABLE_KEYS => ('payload_item');


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

