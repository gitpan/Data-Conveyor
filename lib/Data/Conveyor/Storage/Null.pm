package Data::Conveyor::Storage::Null;

# $Id: Null.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;


our $VERSION = '0.07';


use base qw(
    Class::Scaffold::Delegate::Mixin
    Data::Storage::Null
);



sub generate_ticket_no {
    my $self = shift;
    $self->delegate->make_obj('test_ticket')->gen_temp_ticket_no;
}


sub keywords_store {
    my ($self, $ticket, $keyword_container) = @_;
    our %store;
    $store{ticket}{$ticket->ticket_no}{keyword_container} = $keyword_container;
}


sub keywords_read {
    my ($self, $ticket) = @_;
    our %store;
    my $container = $store{ticket}{$ticket->ticket_no}{keyword_container};
    $container->dirty(1);
    $ticket->keywords($container);
}


1;


__END__



=head1 NAME

Data::Conveyor::Storage::Null - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Storage::Null->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::Storage::Null inherits from
L<Class::Scaffold::Delegate::Mixin> and L<Data::Storage::Null>.

The superclass L<Class::Scaffold::Delegate::Mixin> defines these methods
and functions:

    delegate()

The superclass L<Data::Storage::Null> defines these methods and functions:

    AUTOLOAD(), is_connected()

The superclass L<Data::Storage::Memory> defines these methods and
functions:

    commit(), connect(), disconnect(), rollback()

The superclass L<Data::Storage> defines these methods and functions:

    new(), clear_log(), clear_rollback_mode(), create(), id(),
    initialize_data(), lazy_connect(), log(), log_clear(), rollback_mode(),
    rollback_mode_clear(), rollback_mode_set(), set_rollback_mode(),
    setup(), signature(), test_setup()

The superclass L<Class::Accessor::Complex> defines these methods and
functions:

    mk_abstract_accessors(), mk_array_accessors(), mk_boolean_accessors(),
    mk_class_array_accessors(), mk_class_hash_accessors(),
    mk_class_scalar_accessors(), mk_concat_accessors(),
    mk_forward_accessors(), mk_hash_accessors(), mk_integer_accessors(),
    mk_new(), mk_object_accessors(), mk_scalar_accessors(),
    mk_set_accessors(), mk_singleton()

The superclass L<Class::Accessor> defines these methods and functions:

    _carp(), _croak(), _mk_accessors(), accessor_name_for(),
    best_practice_accessor_name_for(), best_practice_mutator_name_for(),
    follow_best_practice(), get(), make_accessor(), make_ro_accessor(),
    make_wo_accessor(), mk_accessors(), mk_ro_accessors(),
    mk_wo_accessors(), mutator_name_for(), set()

The superclass L<Class::Accessor::Installer> defines these methods and
functions:

    install_accessor()

The superclass L<Class::Accessor::Constructor> defines these methods and
functions:

    _make_constructor(), mk_constructor(), mk_constructor_with_dirty(),
    mk_singleton_constructor()

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

The superclass L<Class::Accessor::Constructor::Base> defines these methods
and functions:

    STORE(), clear_dirty(), clear_hygienic(), clear_unhygienic(),
    contains_hygienic(), contains_unhygienic(), delete_hygienic(),
    delete_unhygienic(), dirty(), dirty_clear(), dirty_set(),
    elements_hygienic(), elements_unhygienic(), hygienic(),
    hygienic_clear(), hygienic_contains(), hygienic_delete(),
    hygienic_elements(), hygienic_insert(), hygienic_is_empty(),
    hygienic_size(), insert_hygienic(), insert_unhygienic(),
    is_empty_hygienic(), is_empty_unhygienic(), set_dirty(),
    size_hygienic(), size_unhygienic(), unhygienic(), unhygienic_clear(),
    unhygienic_contains(), unhygienic_delete(), unhygienic_elements(),
    unhygienic_insert(), unhygienic_is_empty(), unhygienic_size()

The superclass L<Tie::StdHash> defines these methods and functions:

    CLEAR(), DELETE(), EXISTS(), FETCH(), FIRSTKEY(), NEXTKEY(), SCALAR(),
    TIEHASH()

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

Copyright 2004-2009 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

