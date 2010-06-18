use 5.008;
use strict;
use warnings;

package Data::Conveyor::Exception::Ticket::MissingLock;
BEGIN {
  $Data::Conveyor::Exception::Ticket::MissingLock::VERSION = '1.101690';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Data::Conveyor::Exception::Ticket';
__PACKAGE__->mk_scalar_accessors(qw(object_type object_id));
use constant default_message => 'Missing lock for [%s] [%s]';
use constant PROPERTIES      => (qw/object_type object_id/);
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Exception::Ticket::MissingLock - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.101690

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at
L<http://github.com/hanekomu/Data-Conveyor/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

  Marcel Gruenauer <marcel@cpan.org>
  Florian Helmberger <fh@univie.ac.at>
  Achim Adam <ac@univie.ac.at>
  Mark Hofstetter <mh@univie.ac.at>
  Heinz Ekker <ek@univie.ac.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

