package Data::Conveyor::Exception::Internal::NoSuchTemplateHandler;

# $Id: NoSuchTemplateHandler.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;


our $VERSION = '0.08';


use base 'Error::Hierarchy::Internal';


__PACKAGE__->mk_scalar_accessors(qw(handler_type ticket_type));


use constant default_message =>
    'No class for template handler type [%s], ticket type [%s]';

use constant PROPERTIES => ( qw/handler_type ticket_type/ );


sub init {
    my $self = shift;

    # because we call SUPER::init(), which uses caller() to set
    # package, filename and line of the exception, *plus* we don't want
    # to report the abstract method that threw this exception itself,
    # rather we want to report its caller, i.e. the one that called the
    # abstract method. So we use +2.

    local $Error::Depth = $Error::Depth + 2;
    $self->SUPER::init(@_);
}


1;


__END__



=head1 NAME

Data::Conveyor::Exception::Internal::NoSuchTemplateHandler - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Exception::Internal::NoSuchTemplateHandler->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_handler_type>

    $obj->clear_handler_type;

Clears the value.

=item C<clear_ticket_type>

    $obj->clear_ticket_type;

Clears the value.

=item C<handler_type>

    my $value = $obj->handler_type;
    $obj->handler_type($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<handler_type_clear>

    $obj->handler_type_clear;

Clears the value.

=item C<ticket_type>

    my $value = $obj->ticket_type;
    $obj->ticket_type($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<ticket_type_clear>

    $obj->ticket_type_clear;

Clears the value.

=back

Data::Conveyor::Exception::Internal::NoSuchTemplateHandler inherits from
L<Error::Hierarchy::Internal>.

The superclass L<Error::Hierarchy::Internal> defines these methods and
functions:

    is_optional(), stringify()

The superclass L<Error::Hierarchy> defines these methods and functions:

    acknowledged(), acknowledged_clear(), acknowledged_set(),
    clear_acknowledged(), clear_is_optional(), comparable(), error_depth(),
    get_properties(), is_optional_clear(), is_optional_set(),
    properties_as_hash(), set_acknowledged(), set_is_optional(),
    transmute()

The superclass L<Error::Hierarchy::Base> defines these methods and
functions:

    new(), dump_as_yaml(), dump_raw()

The superclass L<Error> defines these methods and functions:

    _throw_Error_Simple(), associate(), catch(), file(), flush(), import(),
    object(), prior(), record(), text(), throw(), value(), with()

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

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

