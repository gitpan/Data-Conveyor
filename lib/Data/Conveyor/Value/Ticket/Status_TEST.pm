use 5.008;
use strict;
use warnings;

package Data::Conveyor::Value::Ticket::Status_TEST;
our $VERSION = '1.100870';
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Data::Conveyor::Test';
use constant PLAN => 14;

sub run {
    my $self = shift;
    $self->SUPER::run(@_);

    # Note that there are no tests for adding TS_HOLD and TS_PENDING; that's
    # undefined so far because we don't really use TS_HOLD anymore.
    $self->apply_status_ok('TS_RUNNING', 'TS_RUNNING', 'TS_RUNNING', 1);
    $self->apply_status_ok('TS_RUNNING', 'TS_HOLD',    'TS_HOLD',    1);
    $self->apply_status_ok('TS_RUNNING', 'TS_PENDING', 'TS_PENDING', 1);
    $self->apply_status_ok('TS_RUNNING', 'TS_ERROR',   'TS_ERROR',   1);
    $self->apply_status_ok('TS_HOLD',    'TS_RUNNING', 'TS_HOLD',    1);
    $self->apply_status_ok('TS_HOLD',    'TS_HOLD',    'TS_HOLD',    1);
    $self->apply_status_ok('TS_HOLD',    'TS_ERROR',   'TS_ERROR',   1);
    $self->apply_status_ok('TS_PENDING', 'TS_RUNNING', 'TS_PENDING', 1);
    $self->apply_status_ok('TS_PENDING', 'TS_PENDING', 'TS_PENDING', 1);
    $self->apply_status_ok('TS_PENDING', 'TS_ERROR',   'TS_ERROR',   1);
    $self->apply_status_ok('TS_ERROR',   'TS_RUNNING', 'TS_ERROR',   1);
    $self->apply_status_ok('TS_ERROR',   'TS_HOLD',    'TS_ERROR',   1);
    $self->apply_status_ok('TS_ERROR',   'TS_PENDING', 'TS_ERROR',   1);
    $self->apply_status_ok('TS_ERROR',   'TS_ERROR',   'TS_ERROR',   1);
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Value::Ticket::Status_TEST - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.100870

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

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

