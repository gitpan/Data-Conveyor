package Data::Conveyor::Exception::Handler;

# $Id: Handler.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;
use Data::Miscellany 'class_map';


our $VERSION = '0.01';


use base 'Class::Scaffold::Storable';


use constant ERRCODE_FOR_EXCEPTION_CLASS_HASH => (
    UNIVERSAL => 'NC20000',            # fallback
);


sub RC_FOR_EXCEPTION_CLASS_HASH {
    local $_ = $_[0]->delegate;
    (
        # fallback
        UNIVERSAL                               => $_->RC_INTERNAL_ERROR,

        'Error::Hierarchy::Internal'            => $_->RC_INTERNAL_ERROR,
        'Class::Value::Exception'               => $_->RC_ERROR,
        'Class::Scaffold::Exception::Business' => $_->RC_ERROR,
        'Data::Conveyor::Exception::Ticket'     => $_->RC_INTERNAL_ERROR,
        'Data::Conveyor::Exception::Ticket::MissingLock' => $_->RC_ERROR,
    )
}


sub STATUS_FOR_EXCEPTION_CLASS_HASH {
    local $_ = $_[0]->delegate;
    (
        UNIVERSAL                               => $_->TS_ERROR,    # fallback

        'Error::Hierarchy::Internal'            => $_->TS_ERROR,
        'Class::Value::Exception'               => $_->TS_RUNNING,
        'Class::Scaffold::Exception::Business' => $_->TS_RUNNING,
        'Data::Conveyor::Exception::Ticket'     => $_->TS_ERROR,
        'Data::Conveyor::Exception::Ticket::MissingLock' => $_->TS_RUNNING,
    )
}


sub errcode_for_exception_class {
    my ($self, $class) = @_;
    class_map(
        $class,
        scalar $self->every_hash('ERRCODE_FOR_EXCEPTION_CLASS_HASH')
    );
}


sub rc_for_exception_class {
    my ($self, $exception, $payload_item) = @_;

    # Here we don't use the payload item, but a subclass might use it to
    # change the rc depending on the object type and command found in the
    # payload item.

    $self->delegate->make_obj('value_ticket_rc', 
        class_map(
            $exception,
            scalar $self->every_hash('RC_FOR_EXCEPTION_CLASS_HASH')
        )
    );
}


sub status_for_exception_class {
    my ($self, $exception, $payload_item) = @_;

    # Here we don't use the payload item, but a subclass might use it to
    # change the status depending on the object type and command found in the
    # payload item.

    $self->delegate->make_obj('value_ticket_status', 
        class_map(
            $exception,
            scalar $self->every_hash('STATUS_FOR_EXCEPTION_CLASS_HASH')
        )
    );
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

