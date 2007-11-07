package Data::Conveyor::Ticket::Payload::Common_TEST;

# $Id: Common_TEST.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Error::Hierarchy::Test 'throws2_ok';
use Test::More;


our $VERSION = '0.01';


use base 'Data::Conveyor::Test';


sub PLAN {
    my $self = shift;
    # $::delegate->TS and ->RC in numeric context return the arrayref
    $::delegate->TS_COUNT + $::delegate->RC_COUNT + 4;
}


sub run {
    my $self = shift;
    $self->SUPER::run(@_);

    my $obj = $self->make_real_object;

    $self->obj_ok($obj->default_rc,     'value_ticket_rc');
    $self->obj_ok($obj->default_status, 'value_ticket_status');

    my $ticket = $self->delegate->make_obj('ticket');

    is($obj->rc($ticket), $self->delegate->RC_OK,
        'rc without exceptions is RC_OK');
    is($obj->status($ticket), $self->delegate->TS_RUNNING,
        'status without exceptions is TS_RUNNING');

    for my $rc (sort $self->delegate->RC) {
        $obj->default_rc($rc);
        is($obj->rc($ticket), $rc, "effect of default [$rc] on rc");
    }

    for my $status (sort $self->delegate->TS) {
        $obj->default_status($status);
        is($obj->status($ticket), $status,
            "effect of default [$status] on status");
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

