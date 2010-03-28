use 5.008;
use strict;
use warnings;

package Data::Conveyor::YAML::Active::Payload::Common;
our $VERSION = '1.100870';
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Data::Conveyor::YAML::Active::Payload::Item';

sub make_payload_item {
    my $self = shift;
    $self->__payload_item($self->delegate->make_obj('payload_common'));
}

sub set_payload_item_properties {
    my $self = shift;
    $self->move_payload_item_property_from_hash('exception_container');
}

sub populate_payload_item_data {
    my $self = shift;
    while (my ($key, $value) = each %{ $self->__hash }) {
        $self->__payload_item->$key($value);
    }
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::YAML::Active::Payload::Common - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.100870

=head1 METHODS

=head2 make_payload_item

FIXME

=head2 populate_payload_item_data

FIXME

=head2 set_payload_item_properties

FIXME

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

