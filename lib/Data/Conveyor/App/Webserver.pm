use 5.008;
use strict;
use warnings;

package Data::Conveyor::App::Webserver;
BEGIN {
  $Data::Conveyor::App::Webserver::VERSION = '1.101690';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use Error ':try';
use parent 'Class::Scaffold::App::CommandLine';
use constant GETOPT => qw(
  engine_type|e=s
  storage_setup
  sif_web_host=s
  sif_web_port=s
  sif_web_access_log=s
  sif_web_error_log=s
  sif_web_debug
);

sub app_code {
    my $self = shift;
    $self->SUPER::app_code(@_);
    $self->delegate->core_storage->test_setup if $self->opt('storage_setup');
    my $engine_type = lc $self->opt('engine_type') || 'serversimple';
    try {
        $self->delegate->make_obj("sif_http_engine_${engine_type}")->run;
    }
    catch Error with {
        my $E = shift;
        die $E;

        # XXX
    };
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::App::Webserver - Stage-based conveyor-belt-like ticket handling system

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

