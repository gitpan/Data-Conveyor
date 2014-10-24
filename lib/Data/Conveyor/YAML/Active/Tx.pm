package Data::Conveyor::YAML::Active::Tx;

# $Id: Tx.pm 9275 2005-06-21 13:58:39Z gr $

use warnings;
use strict;
use YAML::Active qw/assert_hashref hash_activate/;


our $VERSION = '0.01';


use base 'Class::Scaffold::YAML::Active';


sub yaml_activate {
    my ($self, $phase) = @_;
    assert_hashref($self);
    my $hash = hash_activate($self, $phase);

    {
        object_type => $hash->{object_type} || get_objecttype($hash->{objectid}),
        objectid   => $hash->{objectid},
        command    => $hash->{command},
        txtype     => $hash->{txtype}    || $self->delegate->TXT_EXPLICIT,
        status     => $hash->{status}    || $self->delegate->TXS_RUNNING,
        necessity  => $hash->{necessity} || $self->delegate->TXN_MANDATORY,
        exists $hash->{objectcreated}
            ? (objectcreated => $hash->{objectcreated})
            : (),
    }
}


sub get_objecttype {
    my $objectid = shift;
    (my $object_type) = $objectid =~ /^(\w+)\.\d/;
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

