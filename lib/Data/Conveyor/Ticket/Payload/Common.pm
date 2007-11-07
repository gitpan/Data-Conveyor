package Data::Conveyor::Ticket::Payload::Common;

# $Id: Common.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;


our $VERSION = '0.01';


use base 'Data::Conveyor::Ticket::Payload::Item';


__PACKAGE__
    ->mk_scalar_accessors(qw(log_level))
    ->mk_framework_object_accessors(
        value_ticket_rc     => 'default_rc',
        value_ticket_status => 'default_status',
    );


sub DEFAULTS {
    (
        default_rc     => $_[0]->delegate->RC_OK,
        default_status => $_[0]->delegate->TS_RUNNING,
    )
}


sub check {}


# A stage can set the default rc (barring any exceptions) in the common
# payload item's; it will be applied in rc(). Ditto for status().

sub rc {
    my ($self, $ticket) = @_;
    my $rc = $self->SUPER::rc($ticket);
    $rc += $self->default_rc if defined $self->default_rc;
}


sub status {
    my ($self, $ticket) = @_;
    my $status = $self->SUPER::status($ticket);
    $status += $self->default_status if defined $self->default_status;
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

