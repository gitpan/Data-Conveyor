package Data::Conveyor::Ticket::Processor::Conveyor;

# $Id: Conveyor.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;


our $VERSION = '0.01';


use base 'Class::Scaffold::Storable';


__PACKAGE__
    ->mk_framework_object_accessors(ticket => 'ticket')
    ->mk_scalar_accessors(qw(poll_delegate))
    ->mk_boolean_accessors(qw(transactional_authority));


# the poll delegate allows the upper service layer to interrupt processing
# by throwing an exception, if it thinks it is necessary.

use constant DEFAULTS => (transactional_authority => 1);


sub run {
    my $self = shift;

    my $previous_stage = '';
    while ($self->ticket->stage ne $previous_stage) {

        last if $self->ticket->stage
             eq $self->delegate->FINAL_TICKET_STAGE;

        $previous_stage = $self->ticket->stage;

        if ($self->poll_delegate &&
            $self->poll_delegate->can('callback')) {
            $self->poll_delegate->callback($self->ticket);
        }

        # We need to set the ticket to active, because it won't have been
        # open()ed - we just process a ticket from start to end, without
        # repeatedly writing and re-reading it.

        $self->ticket->stage->set_active;
        $self->delegate->make_obj('ticket_dispatcher')->new(
            transactional_authority => $self->transactional_authority)->
            dispatch($self->ticket);


    }
    $self->ticket->store;
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

