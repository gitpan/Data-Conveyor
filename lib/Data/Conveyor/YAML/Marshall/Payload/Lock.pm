package Data::Conveyor::YAML::Marshall::Payload::Lock;

use warnings;
use strict;
use YAML::Marshall 'payload/lock';

our $VERSION = '0.11';

use base 'Class::Scaffold::YAML::Marshall';

sub yaml_load {
    my $self = shift;
    my $node = $self->SUPER::yaml_load(@_);

    my $payload_item = $self->delegate->make_obj('payload_lock');
    while (my ($key, $value) = each %$node) {
        $payload_item->lock->$key($value);
    }

    $payload_item;
}


1;


__END__

=head1 NAME

Data::Conveyor::YAML::Marshall::Payload::Lock - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::YAML::Marshall::Payload::Lock->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2009 by the author.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
