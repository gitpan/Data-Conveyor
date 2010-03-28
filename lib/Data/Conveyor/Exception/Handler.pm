use 5.008;
use strict;
use warnings;

package Data::Conveyor::Exception::Handler;
our $VERSION = '1.100870';

# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use Data::Miscellany 'class_map';
use parent 'Class::Scaffold::Storable';
use constant ERRCODE_FOR_EXCEPTION_CLASS_HASH => (
    UNIVERSAL => 'NC20000',    # fallback
);

sub RC_FOR_EXCEPTION_CLASS_HASH {
    local $_ = $_[0]->delegate;
    (   UNIVERSAL                    => $_->RC_INTERNAL_ERROR,    # fallback
        'Error::Hierarchy::Internal' => $_->RC_INTERNAL_ERROR,
        'Class::Value::Exception'    => $_->RC_ERROR,
        'Class::Scaffold::Exception::Business' => $_->RC_ERROR,
        'Data::Conveyor::Exception::Ticket'    => $_->RC_INTERNAL_ERROR,
        'Data::Conveyor::Exception::Ticket::MissingLock' => $_->RC_ERROR,
    );
}

sub STATUS_FOR_EXCEPTION_CLASS_HASH {
    local $_ = $_[0]->delegate;
    (   UNIVERSAL                              => $_->TS_ERROR,     # fallback
        'Error::Hierarchy::Internal'           => $_->TS_ERROR,
        'Class::Value::Exception'              => $_->TS_RUNNING,
        'Class::Scaffold::Exception::Business' => $_->TS_RUNNING,
        'Data::Conveyor::Exception::Ticket'    => $_->TS_ERROR,
        'Data::Conveyor::Exception::Ticket::MissingLock' => $_->TS_RUNNING,
    );
}

# Like every_hash() but also collect results from a hook. So the hash merging
# doesn't just happen vertically across the class hierarchy but also across
# plugins, which could be viewed as aspect-like crosscutting concerns.
sub every_hash_with_hook {
    my ($self, $hash_name, $hook, $args) = @_;
    my %hash = $self->every_hash($hash_name);
    for my $result ($self->delegate->plugin_handler->run_hook($hook, $args)) {

        # result is expected to be a hashref like the one returned by
        # every_hash()
        %hash = (%hash, %$result);
    }
    wantarray ? %hash : \%hash;
}

sub errcode_for_exception_class {
    my ($self, $class) = @_;
    class_map(
        $class,
        scalar $self->every_hash_with_hook(
            'ERRCODE_FOR_EXCEPTION_CLASS_HASH',
            'exception.errcode_for_class',
        )
    );
}

sub rc_for_exception_class {
    my ($self, $exception) = @_;

    # Here we don't use the payload item, but a subclass might use it to
    # change the rc depending on the object type and command found in the
    # payload item.
    $self->delegate->make_obj(
        'value_ticket_rc',
        class_map(
            $exception,
            scalar $self->every_hash_with_hook(
                'RC_FOR_EXCEPTION_CLASS_HASH', 'exception.rc_for_class',
            )
        )
    );
}

sub status_for_exception_class {
    my ($self, $exception) = @_;

    # Here we don't use the payload item, but a subclass might use it to
    # change the status depending on the object type and command found in the
    # payload item.
    $self->delegate->make_obj(
        'value_ticket_status',
        class_map(
            $exception,
            scalar $self->every_hash_with_hook(
                'STATUS_FOR_EXCEPTION_CLASS_HASH',
                'exception.status_for_class',
            )
        )
    );
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Exception::Handler - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.100870

=head1 METHODS

=head2 RC_FOR_EXCEPTION_CLASS_HASH

FIXME

=head2 STATUS_FOR_EXCEPTION_CLASS_HASH

FIXME

=head2 errcode_for_exception_class

FIXME

=head2 every_hash_with_hook

FIXME

=head2 rc_for_exception_class

FIXME

=head2 status_for_exception_class

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at
L<http://github.com/hanekomu/Data-Conveyor/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

  Marcel Gruenauer <marcel@cpan.org>
  Florian Helmberger <fh@univie.ac.at>
  Achim Adam <ac@univie.ac.at>
  Mark Hofstetter <mh@univie.ac.at>
  Heinz Ekker <ek@univie.ac.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

