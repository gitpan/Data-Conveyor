package Data::Conveyor::Charset::ViaHash::ASCIIPunctuation;

# $Id: ASCIIPunctuation.pm 9761 2005-07-11 13:22:52Z gr $

use strict;
use warnings;


our $VERSION = '0.01';


use base 'Data::Conveyor::Charset::ViaHash';


use constant CHARACTERS => (

    # 0x0020 - 0x007E
    #
    # (without all characters imported from
    # Registry::Charset::ViaHash::LatinSmallLetters,
    # Registry::Charset::ViaHash::LatinCapitalLetters and
    # Registry::Charset::ViaHash::Digits)

    '0020' => 'SPACE',
    '0021' => 'EXCLAMATION MARK',
    '0022' => 'QUOTATION MARK',
    '0023' => 'NUMBER SIGN',
    '0024' => 'DOLLAR SIGN',
    '0025' => 'PERCENT SIGN',
    '0026' => 'AMPERSAND',
    '0027' => 'APOSTROPHE',
    '0028' => 'LEFT PARENTHESIS',
    '0029' => 'RIGHT PARENTHESIS',
    '002A' => 'ASTERISK',
    '002B' => 'PLUS SIGN',
    '002C' => 'COMMA',
    '002D' => 'HYPHEN-MINUS',
    '002E' => 'FULL STOP',
    '002F' => 'SOLIDUS',
    '003A' => 'COLON',
    '003B' => 'SEMICOLON',
    '003C' => 'LESS-THAN SIGN',
    '003D' => 'EQUALS SIGN',
    '003E' => 'GREATER-THAN SIGN',
    '003F' => 'QUESTION MARK',
    '0040' => 'COMMERCIAL AT',
    '005B' => 'LEFT SQUARE BRACKET',
    '005C' => 'REVERSE SOLIDUS',
    '005D' => 'RIGHT SQUARE BRACKET',
    '005E' => 'CIRCUMFLEX ACCENT',
    '005F' => 'LOW LINE',
    '0060' => 'GRAVE ACCENT',
    '007B' => 'LEFT CURLY BRACKET',
    '007C' => 'VERTICAL LINE',
    '007D' => 'RIGHT CURLY BRACKET',
    '007E' => 'TILDE',
);


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
