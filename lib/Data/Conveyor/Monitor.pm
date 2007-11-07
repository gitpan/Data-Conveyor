package Data::Conveyor::Monitor;

# $Id: Monitor.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;


our $VERSION = '0.01';


use base 'Class::Scaffold::Storable';


sub sort_by_stage_order {
    my ($self, @activity) = @_;

    my %stage_order;
    my $order = 1;
    $stage_order{$_} = sprintf "%02d" => $order++ for
        map { "$_" }
        map {
            $self->delegate->make_obj('value_ticket_stage')->new_start($_),
            $self->delegate->make_obj('value_ticket_stage')->new_active($_),
            $self->delegate->make_obj('value_ticket_stage')->new_end($_),
        } $self->delegate->STAGE_ORDER;

    my @sorted =
        map  { $_->[0] }
        sort { $a->[1] cmp $b->[1] }
        map  { [ $_,
                 ($stage_order{$_->{stage}} || '00') . ($_->{status} || ' ')
               ] }
        @activity;

    wantarray ? @sorted : \@sorted;
}


sub sif_top {
    my ($self, %opt) = @_;

    my $result = $self->delegate->make_obj('service_result_container');

    my @activity = $opt{all}
        ? $self->storage->get_activity
        : $self->storage->get_activity_running;

    $result->result_push(
        $self->delegate->make_obj('service_result_tabular')->set_from_rows(
            fields => [ qw/count stage status rc oticket ochanged/ ],
            rows   => [ $self->sort_by_stage_order(@activity) ],
        )
    );

    $result->result_push(
        $self->delegate->make_obj('service_result_scalar', result =>
            sprintf("%d open regtransfers\n",
                $self->storage->count_open_regtransfers)
        )
    );

    $result;
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

