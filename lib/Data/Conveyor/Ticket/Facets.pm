use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket::Facets;
BEGIN {
  $Data::Conveyor::Ticket::Facets::VERSION = '1.102250';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Class::Scaffold::Exception::Util 'assert_object_type';
use parent 'Class::Scaffold::Storable';

sub check {
    my ($self, $ticket) = @_;
    assert_object_type $ticket, 'ticket';
}

sub delete {
    my ($self, $ticket) = @_;
    $self->storage->facets_delete($ticket);
}

sub read {
    my ($self, $ticket) = @_;
    $self->storage->facets_read($ticket);
}

sub store {
    my ($self, $ticket) = @_;
    $self->storage->facets_store($ticket);
}
1;


__END__
=pod

=head1 VERSION

version 1.102250

=head1 METHODS

=head2 check

FIXME

=head2 delete

FIXME

=head2 read

FIXME

=head2 store

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

