package Data::Conveyor::App::Test::Stage::TxSelector;

# $Id: TxSelector.pm 9526 2005-07-01 12:41:14Z gr $

use warnings;
use strict;
use Test::More;
use Data::Dumper;


our $VERSION = '0.01';


use base 'Data::Conveyor::App::Test::Stage';


use constant DEFAULTS => (
    expected_stage_const => 'ST_TXSEL',
);


sub plan_test {
    my ($self, $test, $run) = @_;
    $self->plan_ticket_expected_container($test, $run) + 1;
}


sub test_expectations {
    my $self = shift;
    $self->SUPER::test_expectations(@_);
    $self->check_ticket_expected_container;

    is_deeply_flex(
        $self->ticket->payload->comparable,
        $self->expect->{payload}->comparable,
        'resulting payload'
    ) or print Dumper $self->ticket->payload->comparable;
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

