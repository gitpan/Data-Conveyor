package Data::Conveyor::Value::Ticket::Status;

# $Id: Status.pm 12010 2006-08-28 14:01:17Z gr $

use strict;
use warnings;


our $VERSION = '0.01';


use base 'Data::Conveyor::Value::Enum';


sub get_valid_values_list { $_[0]->delegate->TS }


sub send_notify_value_invalid {
    my ($self, $value) = @_;
    local $Error::Depth = $Error::Depth + 2;
    $self->exception_container->record(
        'Data::Conveyor::Exception::Ticket::NoSuchStatus',
        status => $value,
    );
}


# Apply a new status to the value object's existing status. When called by the
# payload methods this method makes sure that the resulting status is the
# worst of all exception's associated status's. That is, if there are only
# exceptions with
#
# The status is encoded as a character, but we can map each status to a
# numeric value and perform the same operation as in apply_rc(). The following
# op table holds:
#
# Again we use an op table. Here, 'RUN' stands for 'TS_RUNNING', 'HOLD' for
# 'TS_HOLD', and 'ERR' for 'TS_ERROR'. TS_PENDING is like TS_HOLD. We haven't
# decided yet what to do if a ticket has both a TS_HOLD and a TS_PENDING
# exception because we don't really use TS_HOLD anymore.
#
#    rhs |
# lhs    |  RUN   HOLD    ERR
# -------+----------------------------
# RUN    |  RUN   HOLD    ERR
# HOLD   | HOLD   HOLD    ERR
# ERR    |  ERR    ERR    ERR


sub add {
    my ($status1, $status2) = @_;
    $status1 > $status2 ? $status1 : $status2;
}


sub num_cmp {
    my ($status1, $status2) = @_;

    my $delegate = Data::Conveyor::Environment->getenv;
    my $get_status_number = sub {
        return 0 if $_[0] eq $delegate->TS_RUNNING;
        return 1 if $_[0] eq $delegate->TS_HOLD;
        return 1 if $_[0] eq $delegate->TS_PENDING;
        return 2 if $_[0] eq $delegate->TS_ERROR;
        return 0;
    };

    $get_status_number->($status1) <=> $get_status_number->($status2)
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

