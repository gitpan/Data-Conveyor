package Data::Conveyor::Control::File;

# $Id: File.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;


our $VERSION = '0.01';


use base 'Data::Conveyor::Control';


__PACKAGE__->mk_scalar_accessors(qw(filename));


sub read {
    my $self = shift;

    # Read the file indicated by $self->filename, which has an entry for
    # each stage to be disabled, or 'ALL' to disable all stages. As soon as
    # the word 'all' is found, the rest of the file is discarded!
    #
    # The line '__end__' signals the end of the stage list; anything below is
    # ignored. If there is no such line, the whole file will be read - this
    # works like the __END__ directive in a perl program.
    #
    # This method is pretty strict; if you misspell a stage or include it more
    # than once, it aborts. Here we feel it is better to err on the cautious
    # side. Suppose you'd like to disable the 'keywords_end' stage but mistype
    # it as 'keyword_end'. If we didn't abort on an unknown stage name, we
    # might record an error in the logs but the 'keywords_end' stage would
    # still run.

    $self->ignore_ticket_no_clear;
    $self->allowed_stages_clear;

    $self->allowed_stages(
        map { $_ => 1 } $self->delegate->allowed_dispatcher_stages
    );

    # It's ok for the file not to be there.
    return unless -e $self->filename;

    my ($fh, $error);
    unless (open $fh, '<', $self->filename) {
        $self->log->info("can't open %s: %s", $self->filename, $!);
        return 0;
    }

    while (<$fh>) {
        chomp;
        s/#.*$//;             # comments are being ignored
        s/^\s*//;
        s/\s*$//;
        next unless length;
        $_ = lc;
        if ($_ eq 'all') {
            $self->log->info("disallowing all stages");
            $self->allowed_stages_clear;
            last;
        } elsif ($_ eq '__end__') {
            last;
        } elsif ($self->allowed_stages($_)) {
            $self->allowed_stages_delete($_);
        } elsif ($self->make_obj('value_ticket_number')->check($_)) {
            $self->ignore_ticket_no($_ => 1);
        } else {
            $self->log->info(
                "[%s] isn't a ticket number or a known stage, or a duplicate",
                $_);
            $error++;
            last;
        }
    }

    unless (close $fh) {
        $self->log->info("can't close %s: %s", $self->filename, $!);
        return 0;
    }

    return 0 if $error;

    1;
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

