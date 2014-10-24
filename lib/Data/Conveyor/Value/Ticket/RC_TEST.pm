use 5.008;
use strict;
use warnings;

package Data::Conveyor::Value::Ticket::RC_TEST;
BEGIN {
  $Data::Conveyor::Value::Ticket::RC_TEST::VERSION = '1.103010';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Data::Conveyor::Test';
use constant PLAN => 16;

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    $self->apply_rc_ok('RC_OK',    'RC_OK',             'RC_OK',             1);
    $self->apply_rc_ok('RC_OK',    'RC_ERROR',          'RC_ERROR',          1);
    $self->apply_rc_ok('RC_OK',    'RC_MANUAL',         'RC_MANUAL',         1);
    $self->apply_rc_ok('RC_OK',    'RC_INTERNAL_ERROR', 'RC_INTERNAL_ERROR', 1);
    $self->apply_rc_ok('RC_ERROR', 'RC_OK',             'RC_ERROR',          1);
    $self->apply_rc_ok('RC_ERROR', 'RC_ERROR',          'RC_ERROR',          1);
    $self->apply_rc_ok('RC_ERROR', 'RC_MANUAL',         'RC_MANUAL',         1);
    $self->apply_rc_ok('RC_ERROR', 'RC_INTERNAL_ERROR', 'RC_INTERNAL_ERROR', 1);
    $self->apply_rc_ok('RC_MANUAL', 'RC_OK',     'RC_MANUAL', 1);
    $self->apply_rc_ok('RC_MANUAL', 'RC_ERROR',  'RC_MANUAL', 1);
    $self->apply_rc_ok('RC_MANUAL', 'RC_MANUAL', 'RC_MANUAL', 1);
    $self->apply_rc_ok('RC_MANUAL', 'RC_INTERNAL_ERROR', 'RC_INTERNAL_ERROR',
        1);
    $self->apply_rc_ok('RC_INTERNAL_ERROR', 'RC_OK',    'RC_INTERNAL_ERROR', 1);
    $self->apply_rc_ok('RC_INTERNAL_ERROR', 'RC_ERROR', 'RC_INTERNAL_ERROR', 1);
    $self->apply_rc_ok('RC_INTERNAL_ERROR', 'RC_MANUAL', 'RC_INTERNAL_ERROR',
        1);
    $self->apply_rc_ok('RC_INTERNAL_ERROR', 'RC_INTERNAL_ERROR',
        'RC_INTERNAL_ERROR', 1);
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Value::Ticket::RC_TEST - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103010

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

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

