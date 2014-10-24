use 5.008;
use strict;
use warnings;

package Data::Conveyor::App::Test::SIF::Unit;
BEGIN {
  $Data::Conveyor::App::Test::SIF::Unit::VERSION = '1.102250';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use Test::More;
use parent 'Class::Scaffold::App::Test::YAMLDriven';

sub run_subtest {
    my $self     = shift;
    my $test_def = $self->current_test_def->{execute};
    my $meth     = $test_def->{method};
    $self->expect($self->current_test_def->{expect});
    my $sif = $self->delegate->make_obj('service_interface_soap');
    $sif->args(%{ $test_def->{param} }) if $test_def->{param};
    my $result = $sif->$meth;
    foreach my $check (keys %{ $self->{expect} }) {
        my $call = "check_$check";
        $self->$call($result);
    }
}
1;


__END__
=pod

=head1 VERSION

version 1.102250

=head1 METHODS

=head2 run_subtest

FIXME

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

