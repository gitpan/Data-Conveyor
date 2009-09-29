package Data::Conveyor::Test::UtilLoader;

use warnings;
use strict;
use Data::Conveyor::YAML::Marshall::Ticket;
use Data::Conveyor::YAML::Marshall::TicketNumber;
use Data::Conveyor::YAML::Marshall::Payload;
use Data::Conveyor::YAML::Marshall::Payload::Transaction;
use Data::Conveyor::YAML::Marshall::Payload::Lock;
use Data::Conveyor::YAML::Marshall::Payload::InstructionContainer;
use Data::Conveyor::YAML::Marshall::Payload::Common;

use base 'Class::Scaffold::Test::UtilLoader';

our $VERSION = '0.07';

1;

__END__

=head1 NAME

Data::Conveyor::Test::UtilLoader - large-scale OOP application support

=head1 SYNOPSIS

    Data::Conveyor::Test::UtilLoader->new;

=head1 DESCRIPTION

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

