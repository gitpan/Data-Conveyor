package Data::Conveyor::Ticket::Payload::Instruction;
# ptags: DCTPI

use warnings;
use strict;
use Class::Value;


our $VERSION = '0.01';


use base 'Class::Scaffold::Storable';


use overload
    'eq' => 'eq',
    '""' => 'stringify';


__PACKAGE__
    ->mk_framework_object_accessors(
        value_payload_instruction_command => 'command',
    )
    ->mk_object_accessors('Class::Value' => 'value');


# Override type() in subclasses. Override value() as well; should be a value
# object corresponding to the type of instruction.

use constant type  => '';

sub eq {
    my ($lhs, $rhs) = @_;
    (sprintf "%s", $lhs) eq (sprintf "%s", $rhs);
}


sub stringify {
    my $self = shift;
    sprintf 'command [%s], type [%s], value [%s]',
        $self->command, $self->type, $self->value;
}


sub check {
    my ($self, $exception_container, $ticket) = @_;
    $self->value->run_checks_with_exception_container($exception_container);

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

