package Data::Conveyor::YAML::Marshall::Payload::Transaction;

use warnings;
use strict;
use YAML::Marshall 'payload/transaction';

our $VERSION = '0.08';

use base 'Class::Scaffold::YAML::Marshall';

sub yaml_load {
    my $self = shift;
    my $node = $self->SUPER::yaml_load(@_);

    my $payload_item = $self->delegate->make_obj('payload_transaction');

    for ($payload_item->transaction) {
        $_->object_type($node->{object_type});
        $_->command    ($node->{command});
        $_->type       ($node->{type}      || $self->delegate->TXT_EXPLICIT );
        $_->status     ($node->{status}    || $self->delegate->TXS_RUNNING  );
        $_->necessity  ($node->{necessity} || $self->delegate->TXN_MANDATORY);

        $_->payload_item($node->{item});
    }

    $payload_item;
}


1;


__END__

=head1 NAME

Data::Conveyor::YAML::Marshall::Payload::Transaction - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::YAML::Marshall::Payload::Transaction->new;

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
