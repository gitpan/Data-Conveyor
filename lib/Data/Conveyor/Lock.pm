package Data::Conveyor::Lock;

# $Id: Lock.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;
use Fcntl ':flock';


our $VERSION = '0.03';


use constant PREFIX => '.lock.';
use constant GREPPX => '^%s\.lock\.';
use constant SAFETY => 25;

# This class doesn't use Class::Accessor::*, because it is
# used mainly within the "launcher" applications that go off
# up to twice a minute, just to exit immediately afterwards.

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init(@_);
    $self;
}
sub init {
    my $self = shift;
    my %args = @_;
    $self->$_($args{$_}) for keys %args;
    $self;
}
sub numlocks {
    my $self = shift;
    $self->{numlocks} = $_[0]
             if defined $_[0]
          && $_[0]+0 eq $_[0];
    $self->{numlocks};
}
sub maxlocks {
    my $self = shift;
    $self->{maxlocks} = $_[0]
             if defined $_[0]
          && $_[0]+0 eq $_[0];
    $self->{maxlocks};
}
sub lockfile {
    my $self = shift;
    $self->{lockfile} = $_[0]
                     if $_[0];
    $self->{lockfile};
}
sub lockname {
    my $self = shift;
    $self->{lockname} = $_[0]
                     if $_[0];
    $self->{lockname};
}
sub lockpath {
    my $self = shift;
    if (defined (my $path = shift)) {
        $path =~ s!/$!!go;
        die sprintf "Can't access lockdirectory '%s'",
            $path unless $path && -d $path && -w _;
        $self->{lockpath} = $path;
    }
    $self->{lockpath};
}

# call this one from launcher. it will create/remove locks
# according to the value of the numlocks accessor.

sub administrate_locks {
    my $self = shift;

    die sprintf "invalid numlocks value: '%s'",
        $self->numlocks
        unless defined $self->numlocks
            && defined $self->numlocks + 0
                    && $self->numlocks < $self->maxlocks;
    die "invalid lockpath"
        unless defined $self->lockpath;
    die "invalid lockname"
        unless $self->lockname;

    my %have;
    my %want;
    my $expr = sprintf GREPPX, $self->lockname;
    my $pref = sprintf "%s%s", $self->lockname, PREFIX;

    opendir  D, $self->lockpath;
    my @locks = grep { $_ =~ $expr } readdir D;
    closedir D;

    # be a little more restrictive here. quickly get rid
    # of invalid or superfluous files with our prefix.

    $have{sprintf("%s/%s",$self->lockpath, $_)}++
                                 for (@locks);
    $want{sprintf("%s/%s%02d",
                  $self->lockpath, $pref, $_)}++
                         for (1..$self->numlocks);

    for my $illegal (grep {!exists $want{$_}} keys %have) {
            unlink $illegal
            or die sprintf "Can't remove '%s'", $illegal;
    }
    for my $lockfile (sort keys %want) {
            next   if -f $lockfile;
            open my $lock_fh, '>', $lockfile
            or die sprintf "Can't create lockfile '%s'",
                   $lockfile;
            close $lock_fh;
    }

}

sub release_lock {
    my $self = shift;

    return unless $self->lockfile;
    flock $self->lockfile->[1], LOCK_UN;
    close $self->lockfile->[1];
    $self->{lockfile} = undef;
    1;
}

sub get_lock {
    my $self = shift;

    die "invalid lockpath"
        unless defined $self->lockpath;
    die "invalid lockname"
        unless $self->lockname;

    my $pref = sprintf "%s%s", $self->lockname, PREFIX;

    my $handle;
    my $counter = 1;
    while (1) {

        my $lockfile = sprintf "%s/%s%02d",
               $self->lockpath, $pref, $counter;
        last  unless -f $lockfile;
        open $handle, '>', $lockfile;
        if (flock $handle, LOCK_EX|LOCK_NB) {
            $self->lockfile([$lockfile, $handle]);
            return 1;
        }
        close $handle;
        die sprintf "Severe lockcount problem! N=%s",
                     $counter
                if ++$counter > $self->maxlocks;
    }
    0;

}

sub lockstate {
    my $self = shift;

    # the amazing thing here is that the stream doesn't go down
    # if the file is removed. flock and fcntl F_GETFL just keep
    # returning true; and so does a print with autoflush turned
    # on. that's a bit awkward.

    if ($self->lockfile) {
        return -f $self->lockfile->[0]
         && flock $self->lockfile->[1], LOCK_EX|LOCK_NB;
    }
    else {
        return $self->get_lock;
    }
}


1;


__END__



=head1 NAME

Data::Conveyor::Lock - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Lock->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::Lock inherits from .

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<dataconveyor> tag.

=head1 VERSION 
                   
This document describes version 0.03 of L<Data::Conveyor::Lock>.

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

