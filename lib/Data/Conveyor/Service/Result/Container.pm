package Data::Conveyor::Service::Result::Container;

# $Id: Result.pm 12894 2007-03-15 13:04:42Z gr $
#
# Contains a list of other result objects, which can include other
# containers, since they derive from the same subclass as "normal" service
# result objects such as scalars and tables.

use strict;
use warnings;
use YAML;


our $VERSION = '0.01';


use base 'Data::Conveyor::Service::Result';

# don't subclass Data::Container, since we have a slightly different API - we
# use 'result' instead of 'items', for example.


__PACKAGE__->mk_array_accessors(qw(result));


# concatenate the stringifications of the result list

sub result_as_string {
    my $self = shift;
    join "\n" => map { "$_" } $self->result;
}


# Here exception() is a method, not an attribute. You can't set an exception
# on a container directly; rather, if elements of the result list have
# exceptions, they will be returned in an exception container. If there are no
# exceptions in the results, undef will be returned.

sub exception {
    my $self = shift;
    my @exception = grep { defined } map { $_->exception } $self->result;
    return unless @exception;
    my $container = $self->delegate->make_obj('exception_container');
    $container->items(@exception);
    $container;
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

