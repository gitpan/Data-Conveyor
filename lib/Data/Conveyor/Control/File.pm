use 5.008;
use strict;
use warnings;

package Data::Conveyor::Control::File;
BEGIN {
  $Data::Conveyor::Control::File::VERSION = '1.101690';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Data::Conveyor::Control';
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
    #
    #
    # This method is pretty strict; if you misspell a stage or include it more
    # than once, it aborts. Here we feel it is better to err on the cautious
    # side. Suppose you'd like to disable the 'keywords_end' stage but mistype
    # it as 'keyword_end'. If we didn't abort on an unknown stage name, we
    # might record an error in the logs but the 'keywords_end' stage would
    # still run.
    $self->ignore_ticket_no_clear;
    $self->allowed_stages_clear;
    $self->allowed_stages(map { $_ => 1 }
          $self->delegate->allowed_dispatcher_stages);

    # It's ok for the file not to be there.
    return unless -e $self->filename;
    my ($fh, $error);
    unless (open $fh, '<', $self->filename) {
        $self->log->info("can't open %s: %s", $self->filename, $!);
        return 0;
    }
    while (<$fh>) {
        chomp;
        s/#.*$//;    # comments are being ignored
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
=pod

=head1 NAME

Data::Conveyor::Control::File - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.101690

=head1 METHODS

=head2 read

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

