package Data::Conveyor::Ticket::Provider;

# $Id: Provider.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;


our $VERSION = '0.01';


use base 'Class::Scaffold::Storable';


__PACKAGE__
    ->mk_scalar_accessors(qw(
        handle prefetch supported timestamp lagmax clause
    ))
    ->mk_array_accessors(qw(accepted_stages stack));


use constant INFO => qw/
    ticket_no
    stage
    rc
    status
    nice
/;
use constant PREFETCH_MAX => 12;

use constant DEFAULTS => (
    prefetch => 5,
    lagmax   => 8
);

use constant NULLCLAUSE => '0=0';

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->storage_type('core_storage');
    $self->clause($self->delegate->ticket_provider_clause || NULLCLAUSE);
    die sprintf "prefetch value too large: %d",
           $self->prefetch
        if $self->prefetch > PREFETCH_MAX;
}


sub get_next_ticket {
    my $self = shift;
    my $supported = join ",", map {
           "'starten_$_'"
    } @{shift(@_)};
    my $succeeded = shift;

    $self->stack_clear if $succeeded;

    my $info = $self->_next_unit($supported);
    return unless $info;
    my $ticket = $self->delegate->make_obj('ticket', 
        map { $_ => $info->{$_} } INFO
    );
    $ticket;
}


sub _next_unit {
    my ($self, $supported) = @_;

    $self->handle(
       $self->storage->prepare('
           begin
           ticket_pck.next_ticketblock_select (
                  :supported
                , :prefetch
                , :clause
                , :nextblock
           );
           end;
       ')
    ) unless $self->handle;

    if ($self->stack_count
           && $self->fresh
           && $supported eq $self->supported) {

        return $self->stack_shift;
    }
    else {

        $self->supported($supported);

        my $nextblock;
        $self->handle->bind_param(':supported', $supported);
        $self->handle->bind_param(':prefetch',  $self->prefetch);
        $self->handle->bind_param(':clause',    $self->clause);
        $self->handle->bind_param_inout(':nextblock', \$nextblock, 4096);
        $self->handle->execute;

        $self->stack_clear;
        $self->timestamp(time());

        return unless $nextblock;

        for my $token (split /#/, $nextblock) {
            my (%entry, @info);
            @info = split / /, $token;
            die sprintf "severe provider error"
                unless @info == 5;
            @entry{(INFO)} = @info;
            $self->stack_push(\%entry);
        }

        return $self->_next_unit($supported);

    }
}


sub fresh {
    my $self = shift;
    return (time() - $self->timestamp <= $self->lagmax);
}


sub DESTROY {
    my $self = shift;
    defined $self->handle
         && $self->handle->finish;
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

