package Data::Conveyor::Service::Interface::SOAP;

# $Id: SOAP.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Error ':try';


our $VERSION = '0.05';


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

Data::Conveyor::Service::Interface::SOAP - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Service::Interface::SOAP->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4



=back

Data::Conveyor::Service::Interface::SOAP inherits from
L<Data::Conveyor::Service::Interface>.

The superclass L<Data::Conveyor::Service::Interface> defines these methods
and functions:

    DEFAULTS(), args(), args_clear(), args_delete(), args_exists(),
    args_keys(), args_values(), clear_args(), clear_svc(), delete_args(),
    exists_args(), keys_args(), svc(), svc_clear(), values_args()

The superclass L<Class::Scaffold::Storable> defines these methods and
functions:

    MUNGE_CONSTRUCTOR_ARGS(), clear_storage_info(), clear_storage_type(),
    delete_storage_info(), exists_storage_info(), id(),
    keys_storage_info(), storage(), storage_info(), storage_info_clear(),
    storage_info_delete(), storage_info_exists(), storage_info_keys(),
    storage_info_values(), storage_type(), storage_type_clear(),
    values_storage_info()

The superclass L<Class::Scaffold::Base> defines these methods and
functions:

    new(), FIRST_CONSTRUCTOR_ARGS(), add_autoloaded_package(), log()

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

The superclass L<Data::Comparable> defines these methods and functions:

    comparable(), comparable_scalar(), dump_comparable(),
    prepare_comparable(), yaml_dump_comparable()

The superclass L<Class::Scaffold::Delegate::Mixin> defines these methods
and functions:

    delegate()

The superclass L<Class::Scaffold::Accessor> defines these methods and
functions:

    mk_framework_object_accessors(), mk_framework_object_array_accessors(),
    mk_readonly_accessors()

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

The superclass L<Class::Accessor::FactoryTyped> defines these methods and
functions:

    clear_factory_typed_accessors(), clear_factory_typed_array_accessors(),
    count_factory_typed_accessors(), count_factory_typed_array_accessors(),
    factory_typed_accessors(), factory_typed_accessors_clear(),
    factory_typed_accessors_count(), factory_typed_accessors_index(),
    factory_typed_accessors_pop(), factory_typed_accessors_push(),
    factory_typed_accessors_set(), factory_typed_accessors_shift(),
    factory_typed_accessors_splice(), factory_typed_accessors_unshift(),
    factory_typed_array_accessors(), factory_typed_array_accessors_clear(),
    factory_typed_array_accessors_count(),
    factory_typed_array_accessors_index(),
    factory_typed_array_accessors_pop(),
    factory_typed_array_accessors_push(),
    factory_typed_array_accessors_set(),
    factory_typed_array_accessors_shift(),
    factory_typed_array_accessors_splice(),
    factory_typed_array_accessors_unshift(),
    index_factory_typed_accessors(), index_factory_typed_array_accessors(),
    mk_factory_typed_accessors(), mk_factory_typed_array_accessors(),
    pop_factory_typed_accessors(), pop_factory_typed_array_accessors(),
    push_factory_typed_accessors(), push_factory_typed_array_accessors(),
    set_factory_typed_accessors(), set_factory_typed_array_accessors(),
    shift_factory_typed_accessors(), shift_factory_typed_array_accessors(),
    splice_factory_typed_accessors(),
    splice_factory_typed_array_accessors(),
    unshift_factory_typed_accessors(),
    unshift_factory_typed_array_accessors()

The superclass L<Class::Scaffold::Factory::Type> defines these methods and
functions:

    factory_log()

The superclass L<Class::Factory::Enhanced> defines these methods and
functions:

    add_factory_type(), make_object_for_type(), register_factory_type()

The superclass L<Class::Factory> defines these methods and functions:

    factory_error(), get_factory_class(), get_factory_type_for(),
    get_loaded_classes(), get_loaded_types(), get_my_factory(),
    get_my_factory_type(), get_registered_class(),
    get_registered_classes(), get_registered_types(),
    remove_factory_type(), unregister_factory_type()

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

Copyright 2004-2008 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

