package Data::Conveyor::Value::Ticket::Status_TEST;

# $Id: Status_TEST.pm 12315 2006-12-12 14:16:26Z gr $

use strict;
use warnings;


our $VERSION = '0.01';


use base 'Data::Conveyor::Test';


use constant PLAN => 14;


sub run {
    my $self = shift;
    $self->SUPER::run(@_);

    # Note that there are no tests for adding TS_HOLD and TS_PENDING; that's
    # undefined so far because we don't really use TS_HOLD anymore.

    $self->apply_status_ok('TS_RUNNING' , 'TS_RUNNING' , 'TS_RUNNING' , 1);
    $self->apply_status_ok('TS_RUNNING' , 'TS_HOLD'    , 'TS_HOLD'    , 1);
    $self->apply_status_ok('TS_RUNNING' , 'TS_PENDING' , 'TS_PENDING' , 1);
    $self->apply_status_ok('TS_RUNNING' , 'TS_ERROR'   , 'TS_ERROR'   , 1);

    $self->apply_status_ok('TS_HOLD'    , 'TS_RUNNING' , 'TS_HOLD'    , 1);
    $self->apply_status_ok('TS_HOLD'    , 'TS_HOLD'    , 'TS_HOLD'    , 1);
    $self->apply_status_ok('TS_HOLD'    , 'TS_ERROR'   , 'TS_ERROR'   , 1);

    $self->apply_status_ok('TS_PENDING' , 'TS_RUNNING' , 'TS_PENDING' , 1);
    $self->apply_status_ok('TS_PENDING' , 'TS_PENDING' , 'TS_PENDING' , 1);
    $self->apply_status_ok('TS_PENDING' , 'TS_ERROR'   , 'TS_ERROR'   , 1);

    $self->apply_status_ok('TS_ERROR'   , 'TS_RUNNING' , 'TS_ERROR'   , 1);
    $self->apply_status_ok('TS_ERROR'   , 'TS_HOLD'    , 'TS_ERROR'   , 1);
    $self->apply_status_ok('TS_ERROR'   , 'TS_PENDING' , 'TS_ERROR'   , 1);
    $self->apply_status_ok('TS_ERROR'   , 'TS_ERROR'   , 'TS_ERROR'   , 1);


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

