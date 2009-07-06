package Data::Conveyor::Service::Util;

# $Id: Interface.pm 13294 2007-07-02 11:36:29Z gr $
#
# Mixin class for making service interface method implementations easier. It
# helps in interacting with the storage object. However, these helper methods
# make assumptions about the structure of the underlying storage calls. If
# these assumptions apply to your storage, you may find these methods useful.

use strict;
use warnings;
use Error ':try';
use Error::Hierarchy::Util 'assert_nonempty_arrayref';


our $VERSION = '0.06';


sub svc_check_arguments {
    my ($self, $passed_args, $supported_list) = @_;

    assert_nonempty_arrayref $supported_list,
        'list of supported parameters is empty';

    my $container = $self->delegate->make_obj('exception_container');
    my %supported = map { $_ => 1 } @$supported_list;
    my $exception;
    for my $arg (keys %$passed_args) {
        next if exists $supported{$arg};
        $container->record('Error::Hierarchy::Internal::CustomMessage',
                custom_message  =>
                sprintf("Unsupported parameter '%s'. (Supported: %s)" =>
                $arg, join ', ' => @$supported_list));
        $exception++;
    }
    $container->throw if $exception;
}

# FIXME
#
# This method makes assumptions on the structure of underlying storage calls,
# and is used by Registry::NICAT::Channel::Mail::Output and
# Registry::NICAT::Confirm.
#
# Is there a better place for it?

sub svc_result_for_storage_call {
    my ($self, $storage_call, $supported_args, %args) = @_;

    assert_nonempty_arrayref $supported_args,
        'list of supported parameters is empty';
    $storage_call || throw Error::Hierarchy::Internal::CustomMessage
        (custom_message => sprintf "bad call parameter '$storage_call'");

    $self->svc_check_arguments(\%args, $supported_args);
    $self->delegate->make_obj('service_result_scalar', result => 
        scalar $self->storage->$storage_call(@args{@$supported_args})
    );
}


1;


__END__



=head1 NAME

Data::Conveyor::Service::Util - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Service::Util->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::Service::Util inherits from .

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHORS

Florian Helmberger C<< <fh@univie.ac.at> >>

Achim Adam C<< <ac@univie.ac.at> >>

Mark Hofstetter C<< <mh@univie.ac.at> >>

Heinz Ekker C<< <ek@univie.ac.at> >>

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2008 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

