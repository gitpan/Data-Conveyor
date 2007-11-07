package Data::Conveyor::Value::Ticket::Stage;

# $Id: Stage.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;


our $VERSION = '0.01';


# we need a delegate and therefore need the proper subclasses

use base qw(
    Class::Value
    Class::Scaffold::Storable
);


__PACKAGE__->mk_scalar_accessors(qw(name position));


# Alternative constructor: only takes a name, sets start position

sub pos_name_start {
    my $self = shift;
    $self->delegate->STAGE_START;
}


sub pos_name_active {
    my $self = shift;
    $self->delegate->STAGE_ACTIVE;
}


sub pos_name_end {
    my $self = shift;
    $self->delegate->STAGE_END;
}


sub new_from_name {
    my ($self, $name, %args) = @_;

    $self->new(
        value => sprintf('%s_%s', $self->pos_name_start, $name),
        %args
    );
}


sub new_start {
    my $self = shift;
    $self->new_from_name(@_)->set_start;
}


sub new_active {
    my $self = shift;
    $self->new_from_name(@_)->set_active;
}


sub new_end {
    my $self = shift;
    $self->new_from_name(@_)->set_end;
}


sub get_value {
    my $self = shift;
    return unless $self->position && $self->name;
    sprintf '%s_%s', $self->position, $self->name;
}


sub set_value {
    my ($self, $value) = @_;
    my ($position, $name) = $self->split_value($value);
    $self->position($position);
    $self->name($name);
    $self;
}


# expects a string like 'ende_policy'

sub is_well_formed_value {
    my ($self, $value) = @_;
    $self->SUPER::is_well_formed_value($value) &&
        defined $self->split_value($value);
}


sub split_value {
    my ($self, $value) = @_;
    our $pos_re ||= join '|' =>
        ($self->pos_name_start, $self->pos_name_active, $self->pos_name_end);
    return unless defined($value) && length($value);
    return unless $value =~ /^($pos_re)_([\w_]+)$/;
    return ($1, $2);
}


# these methods return $self to allow chaining

sub set_start  { $_[0]->position($_[0]->pos_name_start);  $_[0] }
sub set_active { $_[0]->position($_[0]->pos_name_active); $_[0] }
sub set_end    { $_[0]->position($_[0]->pos_name_end);    $_[0] }


sub is_start   { $_[0]->position eq $_[0]->pos_name_start  }
sub is_active  { $_[0]->position eq $_[0]->pos_name_active }
sub is_end     { $_[0]->position eq $_[0]->pos_name_end    }


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

