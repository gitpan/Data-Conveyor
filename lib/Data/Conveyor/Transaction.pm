package Data::Conveyor::Transaction;

# $Id: Transaction.pm 13653 2007-10-22 09:11:20Z gr $

# Base class for classes operating on transactions. Policy and delegation
# classes subclass this class.

use warnings;
use strict;
use Error::Hierarchy::Util 'assert_defined';


our $VERSION = '0.01';


use base 'Class::Scaffold::Storable';


__PACKAGE__
    ->mk_framework_object_accessors(
        ticket              => 'ticket',
        transaction_factory => 'factory',
    )
    ->mk_scalar_accessors(qw(tx stage))
    ->mk_array_accessors(qw(extra_tx_list));

    # ticket and tx are passed by Data::Conveyor::Transaction::Factory
    # constructor call; the factory also passes itself as the factory
    # attribute so the transaction can ask the factory to construct
    # further objects.


# shortcuts to the item and its data referenced by the current transaction

sub payload_item      { $_[0]->tx->transaction->payload_item }
sub payload_item_data { $_[0]->payload_item->data            }



# Cumulate exceptions here and throw them summarily in an exception container
# at the end. We do this because we want to be able to check as much as
# possible.

sub record {
    my $self = shift;

    # make record() invisible to caller when reporting exception location
    local $Error::Depth = $Error::Depth + 1;

    $self->payload_item->exception_container->record(
        @_,
        is_optional => $self->tx->transaction->is_optional,
    );
}


# Like record(), but records an actual exception object. This method would be
# called if you want to record an exception caught from somewhere else.

sub record_exception {
    my ($self, $E) = @_;
    $E->is_optional($self->tx->transaction->is_optional);
    $self->payload_item->exception_container->items_set_push($E);
}


sub run {}


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

