package Data::Conveyor::Service::Result;

# $Id: Result.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use YAML;


our $VERSION = '0.01';


use overload
    '""'     => 'stringify',
    fallback => 1;


use base 'Data::Conveyor::Service';


__PACKAGE__->mk_scalar_accessors(qw(result exception));


sub is_ok {
    my $self = shift;
    my $E = $self->exception;
    !(defined $E && ref $E);
}


sub stringify {
    my $self = shift;
    return sprintf("%s\n", $self->exception) unless $self->is_ok;
    $self->result_as_string;
}


# dummy; subclasses should override this

sub result_as_string { sprintf "%s" => $_[0]->result }


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

