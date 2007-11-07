package Data::Conveyor::Transaction::Factory;

# $Id: Factory.pm 11482 2006-05-22 20:55:19Z gr $

use strict;
use warnings;
use Error::Hierarchy::Util 'assert_defined';


our $VERSION = '0.01';


use base 'Class::Scaffold::Factory';


# Subclasses have to override - and therefore define - the mappings of object
# types and commands to transaction handler classes.

# For the txsel, it's ok if there is no handler for a given situation, so just
# map to Class::Null

use constant TXSEL_CLASS_FOR_TRANSACTION => (
    _AUTO => 'Class::Null',
);


sub gen_txsel_handler {
    my ($self, $object_type, $command, $context, %args) = @_;

    # object_type and command can be normal strings, shouldn't enforce
    # assert_object_type().

    assert_defined $object_type, 'called without object_type';
    assert_defined $command,     'called without command';
    assert_defined $context,     'called without context';

    $self->gen_handler(TXSEL_CLASS_FOR_TRANSACTION =>
        [ $object_type, $command, $context ], %args);
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

