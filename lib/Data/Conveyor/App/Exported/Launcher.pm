package Data::Conveyor::App::Exported::Launcher;

# $Id: Launcher.pm 9617 2005-07-04 13:26:42Z ac $

use warnings;
use strict;
use Getopt::Long;
use IO::Handle;
use FindBin '$Bin';


our $VERSION = '0.01';


use base 'Exporter';


our @EXPORT = qw(start);


sub start {
    STDOUT->autoflush;
    STDERR->autoflush;

    my %opt;
    GetOptions(\%opt, qw/
         lockpath=s
         parallel=s
    /);
    usage() unless defined $opt{parallel} && $opt{lockpath};
    for (qw/PROJROOT CF_CONF PERL5OPT/) {
         die "$_ not set" unless $ENV{$_};
    }

    my @executable = (
      "$Bin/reg_dispatch.pl",
      "--lockpath=$opt{lockpath}"
    );

    require Data::Conveyor::Lock::Dispatcher;
    my $lockclass = Data::Conveyor::Lock::Dispatcher->new(
        lockpath => $opt{lockpath},
        numlocks => $opt{parallel}
    );
    $lockclass->administrate_locks;

    # we lose the lock here, of course. in the worst case
    # though, we just bloat and finally end up without the lock.

    if ($lockclass->get_lock) {
        exec $^X, @executable;
        die "exec @executable failed.";
    }
}


sub usage () {
   (my $exe = $0) =~ s|.*/||;
    printf STDERR <<'__EOF', $exe;

Usage:
 %s --lockpath=<directory> --parallel=<n>

__EOF
exit;
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
