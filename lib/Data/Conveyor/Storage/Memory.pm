package Data::Conveyor::Storage::Memory;

# $Id: Memory.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Error::Hierarchy::Util 'assert_defined';
use Class::Scaffold::Exception::Util 'assert_object_type';


our $VERSION = '0.01';


use base qw(
    Data::Storage::Memory
    Data::Conveyor::Storage
);


sub parse_table {
    my ($self, $table) = @_;

    for (split /\n/ => $table) {
         next if /^\s*#/o;
         next if /^\s*$/o;
         s/#.*$//o;
         s/^\s+|\s+$//go;
         my ($from, $rc, $to, $status, $shift) = split /\s+/;
         assert_defined $_, 'syntax error in transition table'
             for ($from, $rc, $to, $status, $shift);
         for my $value ($from, $to) {
             # blow up on garbled input.
             # note: the object knows sh** about valid stage names (?).
             $self->delegate->make_obj('value_ticket_stage')->value($value);
         }
         my $state = sprintf '%s-%s' => $from, $self->delegate->$rc;
         # check supplied status value
         $self->delegate->$status if $status ne '-';
         (our $transition_cache)->{$state} = {
             stage => $to,
             shift => $shift eq 'Y' ? 1 : 0,
            ($status eq '-' ? ( ) : (status => $status)),
         };
    }
}


sub get_next_stage {
    my ($self, $stage, $rc) = @_;

    assert_object_type $stage, 'value_ticket_stage';
    assert_defined $rc, 'called without return code';

    my $state  = sprintf '%s-%s' => $stage, $rc;
    # return undef if the transition is not defined.
    return unless (my $target = (our $transition_cache)->{$state});
    return unless $target->{shift};
    [ $self->delegate->
         make_obj('value_ticket_stage')->value($target->{stage}), $target->{status} ];
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

