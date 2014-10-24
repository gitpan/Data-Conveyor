use 5.008;
use strict;
use warnings;

package Data::Conveyor::Charset::ViaHash::LatinSmallLetters;
BEGIN {
  $Data::Conveyor::Charset::ViaHash::LatinSmallLetters::VERSION = '1.102250';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Data::Conveyor::Charset::ViaHash';
use constant CHARACTERS => (
    a => 'LATIN SMALL LETTER A',
    b => 'LATIN SMALL LETTER B',
    c => 'LATIN SMALL LETTER C',
    d => 'LATIN SMALL LETTER D',
    e => 'LATIN SMALL LETTER E',
    f => 'LATIN SMALL LETTER F',
    g => 'LATIN SMALL LETTER G',
    h => 'LATIN SMALL LETTER H',
    i => 'LATIN SMALL LETTER I',
    j => 'LATIN SMALL LETTER J',
    k => 'LATIN SMALL LETTER K',
    l => 'LATIN SMALL LETTER L',
    m => 'LATIN SMALL LETTER M',
    n => 'LATIN SMALL LETTER N',
    o => 'LATIN SMALL LETTER O',
    p => 'LATIN SMALL LETTER P',
    q => 'LATIN SMALL LETTER Q',
    r => 'LATIN SMALL LETTER R',
    s => 'LATIN SMALL LETTER S',
    t => 'LATIN SMALL LETTER T',
    u => 'LATIN SMALL LETTER U',
    v => 'LATIN SMALL LETTER V',
    w => 'LATIN SMALL LETTER W',
    x => 'LATIN SMALL LETTER X',
    y => 'LATIN SMALL LETTER Y',
    z => 'LATIN SMALL LETTER Z',
);
1;


__END__
=pod

=head1 VERSION

version 1.102250

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

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

