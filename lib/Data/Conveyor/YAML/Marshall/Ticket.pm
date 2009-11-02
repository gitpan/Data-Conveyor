package Data::Conveyor::YAML::Marshall::Ticket;

use warnings;
use strict;
use YAML::Marshall 'ticket';

our $VERSION = '0.08';

use base 'Class::Scaffold::YAML::Marshall';

sub yaml_load {
    my $self = shift;
    my $node = $self->SUPER::yaml_load(@_);

    my %args = %$node;
    delete @args{ qw/ticket_no prefix suffix/ };

    {
        ticket_no => $node->{ticket_no} ||
            $self->delegate->make_obj('test_ticket')->gen_temp_ticket_no(
                prefix => $node->{prefix},
                suffix => $node->{suffix},
            ),
        %args,
    }
}


1;


__END__

=head1 NAME

Data::Conveyor::YAML::Marshall::Ticket - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::YAML::Marshall::Ticket->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=back

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

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2009 by the author.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
