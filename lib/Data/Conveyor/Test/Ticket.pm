package Data::Conveyor::Test::Ticket;

# $Id: Ticket.pm 13653 2007-10-22 09:11:20Z gr $

# Utilities for writing tests pertaining to tickets.

use warnings;
use strict;
use Error::Hierarchy::Util 'assert_defined';


our $VERSION = '0.01';


use base 'Class::Scaffold::Storable';


use constant TST_EMAIL => 'fh@univie.ac.at';


sub make_whole_ticket {
    my $self = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    assert_defined $self->delegate, 'called without delegate.';

    our $cnt;
    $cnt++;

    my $ticket_args = {
        $self->delegate->DEFAULT_TICKET_PROPERTIES,
        ticket_no => $args{ticket_no} ||
                        $self->gen_temp_ticket_no(suffix => $cnt),
        type      => $self->delegate->TT_PERSCREATE,
        origin    => $self->delegate->OR_TEST,
        cltid     => $self->gen_temp_ticket_no(suffix => $cnt),
        %{ $args{ticket} },
    };

    my $ticket = $self->delegate->make_obj('ticket', %$ticket_args);

    if ($args{facets}) {
        while (my ($key, $value) = each %{ $args{facets} }) {
            $ticket->facets->$key($value);
        }
    }

    if ($args{default_rc}) {
        $ticket->set_default_rc($args{default_rc});
    }

    if ($args{default_status}) {
        $ticket->set_default_status($args{default_status});
    }

    if (exists $args{payload} && exists $args{payload}{transactions}) {
        for my $payload_tx ($args{payload}->transactions) {
            my $item_spec = $payload_tx->transaction->payload_item;
            next if ref $item_spec;
            if ($item_spec =~ /^(\w+)\.(\d+)$/) {
                my ($accessor, $index) = ($1, $2-1);
                next unless $payload_tx->transaction->status eq
                    $self->delegate->TXS_ERROR;

                $args{payload}->$accessor->[$index]->
                    exception_container->record(
                        'Class::Value::Contact::Exception::Email',
                        email       => 'exception set by make_whole_ticket',
                        is_optional => 1,
                );
            }
        }
    }

    $ticket->payload($args{payload});
    $ticket;
}


sub gen_temp_ticket_no {
    my $self = shift;
    my %args = @_;

    # Make sure the pid has a maxlen of 5 digits and is zero-padded.
    # Also the suffix has to be a number and has a maxlen of 4, also
    # zero-padded.

    our $temp_ticket_no_prefix ||= '200101010101';
    $args{prefix} ||= $temp_ticket_no_prefix++;

    sprintf "%s.%05d%04d", $args{prefix}, substr($$, -5),
        substr($args{suffix} || int(rand 10000), -4);
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

