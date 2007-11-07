package Data::Conveyor::Service::Result::Tabular;

# $Id: Tabular.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Text::Table;
use Data::Miscellany 'trim';


our $VERSION = '0.01';


use base 'Data::Conveyor::Service::Result';


__PACKAGE__->mk_array_accessors(qw(headers rows));


sub result_as_string {
    my $self = shift;
    unless ($self->rows_count) {
        return "No results\n";
    }
    my @fields = $self->headers;
    my $table = Text::Table->new(@fields);
    $table->load($self->rows);
    $table;
}


# Given a LoH (list of hashes, a typical DBI result set), it populates the
# result object with those rows.

sub set_from_rows {
    my ($self, %args) = @_;
    my ($did_set_headers, $count);
    my $limit  = $args{limit} if defined $args{limit};
    my @fields = @{$args{fields}} if defined $args{fields};

    for my $row (@{$args{rows}}) {
        last if defined($limit) && ++$count > $limit;
        unless ($did_set_headers) {
            scalar @fields or @fields = sort keys %$row;
            $self->headers(@fields);
            $did_set_headers++;
        }

        $self->rows_push(
            [ map { defined($row->{$_}) ? trim($row->{$_}) : '' } @fields ]
        );              
    }                   

    $self;
}


sub result { $_[0]->rows }


sub result_as_list_of_hashes {
    my $self = shift;
    my @result;
    my @headers = $self->headers; # don't call this accessor for every row

    for my $row_ref ($self->rows) {
        my $index = 0;
        my %row_hash;
        for my $header (@headers) {
            $row_hash{$header} = $row_ref->[$index++];
        }
        push @result => \%row_hash;
    }
    wantarray ? @result : \@result;
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

