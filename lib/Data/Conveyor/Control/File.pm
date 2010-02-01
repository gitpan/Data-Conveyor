package Data::Conveyor::Control::File;

# $Id: File.pm 13653 2007-10-22 09:11:20Z gr $
use strict;
use warnings;
our $VERSION = '0.11';
use base 'Data::Conveyor::Control';
__PACKAGE__->mk_scalar_accessors(qw(filename));

sub read {
    my $self = shift;

    # Read the file indicated by $self->filename, which has an entry for
    # each stage to be disabled, or 'ALL' to disable all stages. As soon as
    # the word 'all' is found, the rest of the file is discarded!
    #
    # The line '__end__' signals the end of the stage list; anything below is
    # ignored. If there is no such line, the whole file will be read - this
    # works like the __END__ directive in a perl program.
    #
    #
    #
    # This method is pretty strict; if you misspell a stage or include it more
    # than once, it aborts. Here we feel it is better to err on the cautious
    # side. Suppose you'd like to disable the 'keywords_end' stage but mistype
    # it as 'keyword_end'. If we didn't abort on an unknown stage name, we
    # might record an error in the logs but the 'keywords_end' stage would
    # still run.
    $self->ignore_ticket_no_clear;
    $self->allowed_stages_clear;
    $self->allowed_stages(map { $_ => 1 }
          $self->delegate->allowed_dispatcher_stages);

    # It's ok for the file not to be there.
    return unless -e $self->filename;
    my ($fh, $error);
    unless (open $fh, '<', $self->filename) {
        $self->log->info("can't open %s: %s", $self->filename, $!);
        return 0;
    }
    while (<$fh>) {
        chomp;
        s/#.*$//;    # comments are being ignored
        s/^\s*//;
        s/\s*$//;
        next unless length;
        $_ = lc;
        if ($_ eq 'all') {
            $self->log->info("disallowing all stages");
            $self->allowed_stages_clear;
            last;
        } elsif ($_ eq '__end__') {
            last;
        } elsif ($self->allowed_stages($_)) {
            $self->allowed_stages_delete($_);
        } elsif ($self->make_obj('value_ticket_number')->check($_)) {
            $self->ignore_ticket_no($_ => 1);
        } else {
            $self->log->info(
                "[%s] isn't a ticket number or a known stage, or a duplicate",
                $_);
            $error++;
            last;
        }
    }
    unless (close $fh) {
        $self->log->info("can't close %s: %s", $self->filename, $!);
        return 0;
    }
    return 0 if $error;
    1;
}
1;
__END__

=head1 NAME

Data::Conveyor::Control::File - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Control::File->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_filename>

    $obj->clear_filename;

Clears the value.

=item C<filename>

    my $value = $obj->filename;
    $obj->filename($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<filename_clear>

    $obj->filename_clear;

Clears the value.

=back

Data::Conveyor::Control::File inherits from L<Data::Conveyor::Control>.

The superclass L<Data::Conveyor::Control> defines these methods and
functions:

    instance(), new(), allowed_stages(), allowed_stages_clear(),
    allowed_stages_delete(), allowed_stages_exists(),
    allowed_stages_keys(), allowed_stages_values(), clear_allowed_stages(),
    clear_ignore_ticket_no(), delete_allowed_stages(),
    delete_ignore_ticket_no(), exists_allowed_stages(),
    exists_ignore_ticket_no(), ignore_ticket_no(),
    ignore_ticket_no_clear(), ignore_ticket_no_delete(),
    ignore_ticket_no_exists(), ignore_ticket_no_keys(),
    ignore_ticket_no_values(), init(), instance_instance(),
    keys_allowed_stages(), keys_ignore_ticket_no(), log(), new_instance(),
    values_allowed_stages(), values_ignore_ticket_no(), write()

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

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

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

