package Data::Conveyor::Value::Ticket::RC;

# $Id: RC.pm 9003 2005-05-12 13:33:49Z gr $

use strict;
use warnings;


our $VERSION = '0.01';


use base 'Data::Conveyor::Value::Enum';


sub get_valid_values_list { $_[0]->delegate->RC }


sub send_notify_value_invalid {
    my ($self, $value) = @_;
    local $Error::Depth = $Error::Depth + 2;
    $self->exception_container->record(
        'Data::Conveyor::Exception::Ticket::NoSuchRC',
        rc => $value,
    );
}


# Apply a new rc to the value object's existing rc. When called by the payload
# methods this method makes sure that the resulting rc is the worst of all
# exception's associated rc's. That is, if there are only exceptions with
# RC_ERROR, the whole ticket will have RC_ERROR as its rc. But if one of those
# exceptions is associated with RC_INTERNAL_ERROR, the whole ticket will have
# RC_INTERNAL_ERROR.
#
# We use an op table for "$ticket_rc * $rc". Here, 'OK' stands for
# 'RC_OK', 'ERR' for 'RC_ERROR' and 'INT' for 'RC_INTERNAL_ERROR'.
#
#    rhs |
# lhs    |  OK    ERR    INT
# -------+---------------------------
# OK     |  OK    ERR    INT
# ERR    | ERR    ERR    INT
# INT    | INT    INT    INT
#
# The following simple code relies on the fact that RC_* are encoded as
# numbers that increase with increasing severity. If that premise doesn't
# hold anymore, we'll probably have to implement a real ops table.

sub add {
    my ($rc1, $rc2) = @_;
    $rc1 > $rc2 ? $rc1 : $rc2;
}


sub num_cmp {
    my ($rc1, $rc2) = @_;
    "$rc1" <=> "$rc2"
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

