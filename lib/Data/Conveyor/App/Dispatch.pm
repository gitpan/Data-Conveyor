package Data::Conveyor::App::Dispatch;

# $Id: Dispatch.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Time::HiRes 'usleep';
use Data::Conveyor::Lock::Dispatcher;


our $VERSION = '0.03';


use base 'Class::Scaffold::App::CommandLine';


__PACKAGE__
    ->mk_framework_object_accessors(
        ticket_provider   => 'ticket_provider',
        ticket_dispatcher => 'dispatcher',
    )
    ->mk_scalar_accessors(qw(
        done stage_class dispatcher_sleep lockpath lockhandler
    ))
    ->mk_integer_accessors(qw(ticket_count));


use constant GETOPT => qw/lockpath=s/;


sub app_init {
    my $self = shift;
    $self->SUPER::app_init(@_);

    $self->delegate->make_obj('ticket_payload');

    # If several dispatchers are running, we want to know which log message
    # came from which process. Can be done only now that
    # Class::Scaffold::App->app_init will have instantiated the log singleton.
    $self->log->set_pid;

    $self->ticket_count(0) unless defined $self->ticket_count;
    $self->dispatcher_sleep($self->delegate->dispatcher_sleep || 10);
    $self->lockpath($self->delegate->lockpath);
    $self->delegate->control->filename($self->delegate->control_filename);
}


sub check_lockfile {
    my $self = shift;

    return 1 if $self->delegate->ignore_locks;

    $self->lockhandler ||
    $self->lockhandler(
        Data::Conveyor::Lock::Dispatcher->new(
            lockpath => $self->lockpath));

    $self->lockhandler->lockstate;
}


sub app_code {
    my $self = shift;
    $self->log->info("starting");
    $self->SUPER::app_code(@_);

    # keep EINTR from looping over into the next sleep call;
    # this also should rollback the interrupted transaction,
    # which is exactly what we want. -ac
    local $SIG{INT} = sub { exit };

    my $success;

    while (!$self->done) {

        # this could stay here
        unless ($self->check_lockfile) {
            $self->done(1);
            last;
        }

        $self->ticket_count_inc;
        $self->done(1) if $self->ticket_count >=
            $self->delegate->max_tickets_per_dispatcher;

        unless ($self->delegate->control->read) {
            $self->log->info("control returned false, exiting.");
            $self->done(1);
            last;
        }

        my $ticket;

        # If there aren't any tickets waiting to be processed, don't exit,
        # just sleep. We don't want to keep starting and stopping dispatcher
        # processes just because there are no more tickets for a few seconds.


        unless (defined($ticket = $self->ticket_provider->get_next_ticket(
                    [ $self->delegate->control->allowed_stages_keys ], $success))) {

            $self->log->info("sleep %ss", $self->dispatcher_sleep);
            sleep($self->dispatcher_sleep);
            next;
        }

        # XXX: $ticket->stage should already be a ticket stage value object,
        # so we'd only need to do $ticket->stage->name.

        #my $stage = $self->delegate->make_obj('value_ticket_stage')->new(
        #    value => $ticket->stage)->name;

        # Try to open the ticket - this can still fail if another dispatcher
        # process has already opened the ticket.

        # try_open sets the stage to aktiv_* and commits - we don't want that
        # any more in nic.at
        # we should try to get the db locks instead.
        $self->log_line($ticket, '>');
        if ($self->open_ticket($ticket)) {
            $success = 1;
            # $self->log_line($ticket, $success);
        } else {
            $success = 0;
            # $self->log_line($ticket, $success);
            # cool it a little
            usleep(200_000);
            next;
        }

        # Now we have an opened ticket; process it.
        $self->process_ticket($ticket);
    }
    $self->log->info("exiting");
}


sub log_line {
    my ($self, $ticket, $success) = @_;
    $self->log->info("%s [%s] [% 3s] %s",
        $ticket->ticket_no, $success, $ticket->nice, $ticket->stage->name);
}



sub open_ticket {
    my ($self, $ticket) = @_;
    $ticket->try_open;
}


sub process_ticket {
    my ($self, $ticket) = @_;
    $self->dispatcher->dispatch($ticket);
}


1;


__END__



=head1 NAME

Data::Conveyor::App::Dispatch - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::App::Dispatch->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item clear_dispatcher_sleep

    $obj->clear_dispatcher_sleep;

Clears the value.

=item clear_done

    $obj->clear_done;

Clears the value.

=item clear_lockhandler

    $obj->clear_lockhandler;

Clears the value.

=item clear_lockpath

    $obj->clear_lockpath;

Clears the value.

=item clear_stage_class

    $obj->clear_stage_class;

Clears the value.

=item dec_ticket_count

    $obj->dec_ticket_count;

Decreases the value by 1.

=item dispatcher_sleep

    my $value = $obj->dispatcher_sleep;
    $obj->dispatcher_sleep($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item dispatcher_sleep_clear

    $obj->dispatcher_sleep_clear;

Clears the value.

=item done

    my $value = $obj->done;
    $obj->done($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item done_clear

    $obj->done_clear;

Clears the value.

=item inc_ticket_count

    $obj->inc_ticket_count;

Increases the value by 1.

=item lockhandler

    my $value = $obj->lockhandler;
    $obj->lockhandler($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item lockhandler_clear

    $obj->lockhandler_clear;

Clears the value.

=item lockpath

    my $value = $obj->lockpath;
    $obj->lockpath($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item lockpath_clear

    $obj->lockpath_clear;

Clears the value.

=item reset_ticket_count

    $obj->reset_ticket_count;

Resets the value to 0.

=item stage_class

    my $value = $obj->stage_class;
    $obj->stage_class($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item stage_class_clear

    $obj->stage_class_clear;

Clears the value.

=item ticket_count

    $obj->ticket_count($value);
    my $value = $obj->ticket_count;

A basic getter/setter method. If called without an argument, it returns the
value, or 0 if there is no previous value. If called with a single argument,
it sets the value.

=item ticket_count_dec

    $obj->ticket_count_dec;

Decreases the value by 1.

=item ticket_count_inc

    $obj->ticket_count_inc;

Increases the value by 1.

=item ticket_count_reset

    $obj->ticket_count_reset;

Resets the value to 0.

=back

Data::Conveyor::App::Dispatch inherits from
L<Class::Scaffold::App::CommandLine>.

The superclass L<Class::Scaffold::App::CommandLine> defines these methods
and functions:

    app_finish(), clear_opt(), delete_opt(), exists_opt(), keys_opt(),
    opt(), opt_clear(), opt_delete(), opt_exists(), opt_keys(),
    opt_values(), usage(), values_opt()

The superclass L<Class::Scaffold::App> defines these methods and functions:

    clear_initialized(), initialized(), initialized_clear(),
    initialized_set(), run_app(), set_initialized()

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

    new(), add_autoloaded_package(), init(), log()

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

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<dataconveyor> tag.

=head1 VERSION 
                   
This document describes version 0.03 of L<Data::Conveyor::App::Dispatch>.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<<bug-data-conveyor@rt.cpan.org>>, or through the web interface at
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

Copyright 2004-2008 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

