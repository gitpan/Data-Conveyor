package Data::Conveyor::Environment_TEST;

# $Id: Environment_TEST.pm 13049 2007-04-10 07:09:44Z gr $

use strict;
use warnings;
use Error::Hierarchy::Test 'throws2_ok';


our $VERSION = '0.01';


use base 'Data::Conveyor::Test';


use constant PLAN => 1;


sub run {
    my $self = shift;
    $self->SUPER::run(@_);

    my $env = $self->make_real_object;
    throws2_ok { $env->make_stage_object('foobar'); }
        'Error::Hierarchy::Internal::ValueUndefined',
        qr/no stage class name found for \[foobar\]/,
        'make a stage object for a nonexistent stage';

    # We release the cache for stage class names here. The bug which prompted
    # this is a bit involved. We ran all inline pod tests - via
    # 00podtests.t -, and this test ran first, so $env was of ref
    # Data::Conveyor::Environment. The above code calls
    # make_stage_object(), which indirectly caches the stage class name
    # results, so only ST_TXSEL is cached - since that's the only thing
    # defined in the environment's STAGE_CLASS_NAME_HASH().
    #
    # The next test (from another pod test file) used the config file
    # mechanism, which pointed to a config file from a different package,
    # and that config file uses a different environment. However, the
    # settings from that environment weren't seen because of the cached.

    $env->release_stage_class_name_hash;

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

