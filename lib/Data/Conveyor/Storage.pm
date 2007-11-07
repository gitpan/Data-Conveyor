package Data::Conveyor::Storage;

# $Id: Storage.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Error::Hierarchy::Util 'assert_defined';
use Class::Scaffold::Exception::Util 'assert_object_type';


our $VERSION = '0.01';


use base 'Class::Scaffold::Base';


__PACKAGE__->mk_abstract_accessors(qw(
    ticket_update ticket_insert get_ticket_shift_data
));


# Within Data-Conveyor, rollback_mode isn't taken from the superclass'
# property of the same name, but we ask the delegate.
# Class::Scaffold::App::Test will set the rollback_mode on the Environment
# (which is the delegate), for example.  Just be sure to place
# Data::Conveyor::Storage first in multiple inheritance, e.g., when inheriting
# both from Data::Conveyor::Storage and Data::Storage::*

sub rollback_mode       { $_[0]->delegate->rollback_mode       }
sub set_rollback_mode   { $_[0]->delegate->set_rollback_mode   }
sub clear_rollback_mode { $_[0]->delegate->clear_rollback_mode }


sub ticket_store {
    my ($self, $ticket) = @_;

    $ticket->assert_ticket_no;

    if ($self->ticket_exists($ticket)) {
        $self->ticket_update($ticket);
    } else {
        $self->ticket_insert($ticket);
    }
}


sub ticket_serialized_payload {
    my ($self, $payload) = @_;

    assert_object_type $payload, 'ticket_payload';

    # Serialize the ticket payload using Storable. The serialized version is
    # stored in the dem_payload table. We need to enable the serialization of
    # code references.

    require Storable;
    $Storable::Deparse = 1;

    $payload = Storable::nfreeze($payload);

    # compression
    require Compress::Zlib;
    Compress::Zlib::compress($payload) ||
        throw Error::Hierarchy::Internal::CustomMessage(
            custom_message => 'zlib compress() failure'
        );
}


sub ticket_deserialized_payload {
    my ($self, $payload) = @_;

    assert_defined $payload, 'called without defind serialized payload.';

    # compression
    require Compress::Zlib;
    $payload = Compress::Zlib::uncompress($payload) ||
        throw Error::Hierarchy::Internal::CustomMessage(
            custom_message => 'zlib uncompress() failure'
        );

    # deserialize the ticket payload using Storable if it exists.
    # we need to enable the deserialization of code references.

    require Storable;
    $Storable::Eval = 1;

    Storable::thaw($payload);
}


sub ticket_handle_exception {
    my ($self, $E, $ticket) = @_;
    throw $E;
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

