package Data::Conveyor::Ticket::Payload::Item;

# $Id: Item.pm 13653 2007-10-22 09:11:20Z gr $
#
# Base class for Data::Conveyor::Ticket::Payload::* items

use warnings;
use strict;


our $VERSION = '0.01';


use base 'Class::Scaffold::Storable';


__PACKAGE__
    ->mk_abstract_accessors(qw(DATA_PROPERTY))
    ->mk_framework_object_accessors(
        exception_container => 'exception_container'
    )
    ->mk_boolean_accessors(qw(implicit));

# implicit(): was this item created implicitly by txsel?


sub check {
    my ($self, $ticket) = @_;
    $self->data->check($self->exception_container, $ticket);
}


sub data {
    my $property = $_[0]->DATA_PROPERTY;
    return $_[0]->$property if @_ == 1;
    $_[0]->$property($_[1]);
}


# For rc() and status(), we pass the payload item's owning ticket object to
# the exception container. The container needs to ask the ticket whether to
# ignore an exception. Why do the payload object and the payload items have an
# owning ticket, but the exception container does not? Because exception
# containers are filled from various places, and are passed around. In
# contrast, payload containers and payload items are always tied to a ticket.
#
# We also pass the payload item itself because it will eventually be passed to
# the exception handler, which uses it to decide the rc and status of each
# exception it is ask to handle. That is, the rc and exception aren't
# determined by the exception type alone. The same exception can have
# different rc and status values depending on which object type and command it
# is associated with.

sub rc {
    my ($self, $ticket) = @_;
    $self->exception_container->rc($ticket, $self);
}


sub status {
    my ($self, $ticket) = @_;
    $self->exception_container->status($ticket, $self);
}


sub has_problematic_exceptions {
    my ($self, $ticket) = @_;
    $self->exception_container->has_problematic_exceptions($ticket, $self);
}


sub prepare_comparable {
    my $self = shift;
    $self->SUPER::prepare_comparable(@_);

    # Touch various accessors that will autovivify hash keys so we can be sure
    # they exist, which is a kind of normalization for the purpose of
    # comparing two objects of this class.

    $self->exception_container;
    $self->implicit;
}


# do nothing here; business objects will override
sub apply_instruction_container {}


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

