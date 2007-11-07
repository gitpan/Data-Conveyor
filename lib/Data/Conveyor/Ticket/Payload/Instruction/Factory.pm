package Data::Conveyor::Ticket::Payload::Instruction::Factory;
# ptags: DCTPIF

# $Id: Factory.pm 11539 2006-05-24 11:44:03Z gr $

use warnings;
use strict;
use Error::Hierarchy::Util 'assert_defined';


our $VERSION = '0.01';


use base 'Class::Scaffold::Factory';


use constant INSTRUCTION_CLASS_FOR_NAME => (
    clear => 'Data::Conveyor::Ticket::Payload::Instruction::Clear',
);


sub gen_instruction {
    my ($self, $name, %args) = @_;
    assert_defined $name, 'instruction name';

    # Some instruction classes have a generic structure, they're called
    # Data::Conveyor::Ticket::Payload::Instruction::value_person_organization
    # and such. They're generated in Data::Conveyor::Environment, so they're
    # not in file, so we don't need to load_class() them.

    if (grep { $_ eq $name } $self->delegate->generic_instruction_classes) {
        my $class = $self->delegate->INSTRUCTION_CLASS_BASE() . '::' . $name;
        return $class->new(
            storage_type => $self->storage_type,
            %args
        );
    } else {

        # If it is not a generic value object instruction, go through the
        # normal way of generatic an object.

        return
            $self->gen_handler(INSTRUCTION_CLASS_FOR_NAME => [ $name ], %args);
    }
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

