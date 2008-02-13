package Data::Conveyor::Lock::Dispatcher;

# $Id: Dispatcher.pm 8417 2005-02-16 16:57:57Z gr $
# this is the lockhandler for reg_dispatch.pl

use warnings;
use strict;


our $VERSION = '0.02';


use base 'Data::Conveyor::Lock';


use constant DEFAULTS => (
    lockname => 'dispatcher',
    maxlocks => 25
);


sub init {
    my $self = shift;
    $self->SUPER::init(+DEFAULTS, @_);
}



1;


__END__



=head1 NAME

Data::Conveyor::Lock::Dispatcher - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Lock::Dispatcher->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::Lock::Dispatcher inherits from L<Data::Conveyor::Lock>.

The superclass L<Data::Conveyor::Lock> defines these methods and functions:

    new(), administrate_locks(), get_lock(), lockfile(), lockname(),
    lockpath(), lockstate(), maxlocks(), numlocks(), release_lock()

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<dataconveyor> tag.

=head1 VERSION 
                   
This document describes version 0.02 of L<Data::Conveyor::Lock::Dispatcher>.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<<bug-data-conveyor@rt.cpan.org>>, or through the web interface at
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

Copyright 2004-2008 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

