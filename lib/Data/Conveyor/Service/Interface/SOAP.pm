package Data::Conveyor::Service::Interface::SOAP;

# $Id: SOAP.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Error ':try';


our $VERSION = '0.01';


use base 'Data::Conveyor::Service::Interface';


sub init {
    my $self = shift;

    our $did_generate_methods;
    if (!$did_generate_methods++) {

        # Generate handlers for all methods listed in the Service Methods
        # object. They are being generated into this package. If you need
        # custom implementations for some handlers, override them in the
        # appropriate subclass.

        for my $command ($self->svc->get_method_names) {

            # Generate a separate method for each alias, but not that the
            # service method for the standard name will be called!

            for my $method ($command, $self->svc->get_aliases_for_method($command)) {

                no strict 'refs';

                # separate lexical var ($meth1) for closures

                my $meth1 = $method;
                unless (defined *{$meth1}{CODE}) {
                    $::PTAGS && printf "%s\t%s\t%s\n", $meth1, __FILE__, __LINE__+1;
                    *$meth1 = sub {
                        local $DB::sub = local *__ANON__ =
                            "Data::Conveyor::Service::Interface::SOAP::${meth1}"
                            if defined &DB::DB && !$Devel::DProf::VERSION;
                        my $self = shift;
                        $self->run_service_method($command, $self->args);
                    };
                }
            }
        }
    }
}


sub run_service_method {
    my ($self, $method, %opt) = @_;
    $self->svc->apply_param_aliases_and_defaults($method => \%opt);
    my $result_object;
    try {
        $result_object = $self->svc->run_method($method, %opt);
    } catch Error::Hierarchy with {
        my $E = shift;
        $result_object = $self->delegate->make_obj('service_result_scalar');
        $result_object->exception($E);
    };

    # Apparently the most preferred of all the fucked-up output formats, so we
    # use it as a default here. If the SOAP user expects something even more
    # idiotic, subclass the specific SOAP method and munge the output.

    unless ($result_object->is_ok) {
        return +{
            message  => sprintf("%s", $result_object->exception),
            state    => 1,
        };
    }

    if (exists($opt{pure_result}) && $opt{pure_result}) {
        return +{
            state  => 0,
            result => $result_object,
        }
    }

    # FIXME: Convince the SOAP user to accept standard results, then make this
    # cruft go away.

    my $soap_result;
    if ($self->delegate->isa_type($result_object, 'service_result_tabular')) {
        $soap_result = {
            state  => 0,
            result => scalar($result_object->result_as_list_of_hashes),
        }
    } elsif (ref $result_object->result eq 'HASH') {
        # scalar result object, but contains a hash
        $soap_result = {
            state => 0,
            %{ $result_object->result },
        }
    } else {
        # scalar result object, doesn't contain a hash
        $soap_result = {
            state  => 0,
            result => scalar($result_object->result),
        }
    }

    # Something to munge, sir?

    # You can specify something like
    #
    # use constant MUNGE_OUTPUT => (
    #     foobar => [ frobnicate => 'some_key1', 'some_key2' ],
    # );
    #
    # and this code will effectively call
    #
    # $self->munge_frobnicate($soap_result, 'some_key1', 'some_key2');

    my %munge_output = $self->every_hash('MUNGE_OUTPUT');
    return $soap_result unless exists $munge_output{$method};
    my ($munge_method, @munge_args) = @{ $munge_output{$method} };
    $munge_method = "munge_$munge_method";
    $self->$munge_method($soap_result, @munge_args);
}

# keep this close to the code where it is being used so that when sanity
# prevails, it can be deleted quickly.

use constant MUNGE_OUTPUT => ();


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

