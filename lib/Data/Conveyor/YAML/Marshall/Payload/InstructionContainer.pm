package Data::Conveyor::YAML::Marshall::Payload::InstructionContainer;

use warnings;
use strict;
use YAML::Marshall 'payload/instructioncontainer';
use YAML 'Dump';

our $VERSION = '0.10';

use base 'Class::Scaffold::YAML::Marshall';

sub yaml_load {
    my $self = shift;
    my $node = $self->SUPER::yaml_load(@_);

    my $instruction_container =
        $self->delegate->make_obj('payload_instruction_container');

    our $instruction_factory ||=
        $self->delegate->make_obj('payload_instruction_factory');

    # expect an ordered list of instructions, each with name and value. The
    # YAML::Active plugin uses the payload_instruction_factory to
    # generate the right instruction object, then sets the value on it
    # and inserts it into the container. The name is prepended by 'u-'
    # for IC_UPDATE, 'a-' for IC_ADD and 'd-' for IC_DELETE to provide a
    # concise notation.
    #
    # Example:
    #
    # - u-value_person_company_no: &COMPANYNO 1234
    # - u-value_person_name_title: &TITLE Grunz
    # - u-value_person_name_firstname: &FIRSTNAME Franz
    # - u-value_person_name_lastname: &LASTNAME Testler
    # - a-value_person_email_address: &EMAIL fh@univie.ac.at
    # - a-value_person_fax_number: &FAX1 '+4311234566'
    # - a-value_person_fax_number: &FAX2 '+431242342343'

    for my $spec (@$node) {
        unless (ref $spec eq 'HASH' && scalar(keys %$spec) == 1) {
            throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
                "expected a single-item hash with the instruction, got:\n" .
                Dump($spec));
        }

        my ($key, $value) = %$spec;
        if ($key eq 'clear') {
            $instruction_container->items_push(
                    $instruction_factory->gen_instruction('clear')
            );
            next;
        }
        unless ($key =~ /^([a-z])-(.*)/) {
            throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
                "can't parse instruction key [$key]");
        }
        my ($abbrev_command, $type) = ($1, $2);

        my $command =
            $self->word_complete($abbrev_command, $self->delegate->IC) or
            throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
                "can't determine instruction command from [$abbrev_command]");

        $instruction_container->items_push(
            $instruction_factory->gen_instruction($type,
                command => $command,
                value   => $value,
            )
        );
    }

    $instruction_container;
}

sub word_complete {
    my ($self, $word, @candidates) = @_;
    for (@candidates) {
        return $_ if index($_, $word) == 0;
    }
}


1;


__END__

=head1 NAME

Data::Conveyor::YAML::Marshall::Payload::InstructionContainer - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::YAML::Marshall::Payload::InstructionContainer->new;

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
