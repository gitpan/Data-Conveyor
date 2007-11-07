package Data::Conveyor::Value::Ticket::Number;

# $Id: Number.pm 13447 2007-08-13 13:37:27Z gr $

use strict;
use warnings;
use Date::Calc qw/Today_and_Now Decode_Date_US/;


our $VERSION = '0.01';


use base 'Class::Value';


sub is_well_formed_value {
    my ($self, $value) = @_;
    $self->SUPER::is_well_formed_value($value) && $value =~ /^\d{12}\.\d{9}$/;
}


sub new_from_now {
    my $self = shift;
    $self->new(value =>
        sprintf('%04d%02d%02d%02d%02d.%09d', (Today_and_Now)[0..4], 0));
}


sub new_from_date {
    my ($self, $date) = @_;
    if ($date =~ /^\d{8}$/) {
        $date .= '0000.000000000'
    } else {
        $date = sprintf('%04d%02d%02d%02d%02d.%09d',
            Decode_Date_US($date), 0, 0, 0);
    }
    $self->new(value => $date);
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

