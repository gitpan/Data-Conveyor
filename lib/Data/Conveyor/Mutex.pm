package Data::Conveyor::Mutex;

# $Id: Mutex.pm 13653 2007-10-22 09:11:20Z gr $

use strict;
use warnings;
use Sys::Hostname ();   # no import so we don't clash with our hostname()
use Error ':try';

# XXX the whole thing must be recoded with database locks.
# Note: one way or the other, this is probably not portable
# across databases.


our $VERSION = '0.09';


use base 'Class::Scaffold::Storable';


__PACKAGE__->mk_scalar_accessors(qw(
    application mutex_config_id max_parallel group_exlock program_name
    pid hostname dbinst
));


# FIXME
use constant ADMINADDR => 'service-admin@domain.univie.ac.at';

use constant DEFAULTS => (
    hostname     => Sys::Hostname::hostname(),
    pid          => $$,
    program_name => $0,
);


sub mutex_getconf {
    my $self = shift;

    $self->dbinst($self->storage->dbname);

    $self->log(
        sprintf '%s[%08d]@%s (%s) init "%s"' =>
            map($self->$_, qw/
            program_name pid hostname dbinst application/)
    );

    # get config id and parallelity
    my ($cnf_id,$parallel) = $self->storage->get_mutex_config($self);
    $self->mutex_config_id($cnf_id);
    $self->max_parallel($parallel);

    # require this to be configured.
    $self->error(
        sprintf '%s: mutex configuration: no valid entry found for "%s"' =>
            __PACKAGE__, $self->application
    )
    unless $self->mutex_config_id &&
        defined $self->max_parallel;

    # now check if we are in a group
    my $tmp = $self->storage->get_mutex_data($self);

    # test validity of mutex configuration
    if ($self->group_exlock(scalar(@$tmp) > 1)) {
        for my $cnf (@$tmp) {
           $self->error(
               sprintf "%s: mutex misconfigured for '%s':\nApplication is"
                   ." in a GROUP (%d), but MTXCNF_MAXPARALLEL=%d. Aborting." =>
                   __PACKAGE__,$cnf->[1],$self->mutex_config_id,$cnf->[2]
               )
               if $cnf->[2] > 1;
        }
    }

    # reset the transaction
    $self->storage->dbh->rollback;

    $self->log(
        sprintf '%s[%08d]@%s (%s) mutex_getconf CNFID=%d MXP=%d GROUP=%s'
            .' "%s"' => map($self->$_, qw/
            program_name pid hostname dbinst mutex_config_id max_parallel/),
           ($self->group_exlock ? 'yes' : 'no '),
            $self->application,
    );
    $self;
}


sub get_mutex {
    my $self = shift;

    # XXX: replace this with assert_defined
    $self->error(
        sprintf "%s: mutex not initialized. Aborting." => __PACKAGE__
    )
    unless $self->isa(__PACKAGE__)
        && $self->application
        && $self->storage
        && $self->mutex_config_id
        && defined $self->max_parallel;

    ## make sure previous transaction is over
    $self->storage->dbh->rollback || $self->error(
        sprintf "%s: critical rollback failed. Aborting." => __PACKAGE__
    );

    # try all slots < parallelity

    # try locks
    my $LOCKFAIL;
    my $HAVELOCK;

    for (my $slot = 0; $slot < $self->max_parallel; $slot++) {

         $LOCKFAIL = 0;
         $HAVELOCK = undef;

         local $Error::Hierarchy::Internal::DBI::SkipWarning = 1;

         my $slot_info;
         try {
             $slot_info = $self->storage->get_mutex_slot($self, $slot);
         } catch Error with {
             $LOCKFAIL++;
             # XXX: log the exception here
         };

         $self->log(
             sprintf '%s[%08d]@%s (%s) get_mutex CNFID=%d SLOT=%d: lock=%s "%s"' =>
                map($self->$_, qw/program_name pid hostname dbinst mutex_config_id/),
                $slot,($LOCKFAIL ? 'no ' : 'yes'),$self->application
         );

         ## lock failed...
         next if $LOCKFAIL;

         $self->error(
             sprintf "%s: mutex table problem. No mutex"
                 ." row could be found for MTXCNF_ID %d, slot %d" =>
                 __PACKAGE__, $self->mutex_config_id, $slot
         )
         unless $slot_info;

         $HAVELOCK = 1;
         last;
    }

    return $HAVELOCK;
}


sub release_mutex {
    my $self = shift;
    $self->log(
        sprintf '%s[%08d]@%s (%s) release_mutex "%s"' =>
          map($self->$_, qw/
          program_name pid hostname dbinst application/)
    );
    $self->storage->dbh->rollback;
    $self->storage->dbh->disconnect;
}


sub DESTROY { }

sub error {
    my ($self, $error) = @_;
    my $fatal = {
       to   => ADMINADDR,
       subj => sprintf('[%s] MUTEX', $self->hostname),
       body => sprintf('[%s] %s', $self->hostname, $error),
    };
    mail($fatal);
    die "FATAL ERROR: $fatal->{body}\n";
}


# XXX: use Log::Dispatch to log the mutex messages to the mutex log as well
sub log {
    my $self = shift;
    my $message = localtime()." ".shift(@_);
    1 while chomp $message;
    $self->SUPER::log->debug($message);
    open  my $log_fh, '>>', '/tmp/mutex.log';
    print $log_fh  "$message\n";
    close $log_fh;
}


sub mail {
    shift if $_[0] eq __PACKAGE__;
    my $init = shift;
    my %P;
    if ($init && ref $init eq 'HASH') {
        local $_;
        $P{$_} = $init->{$_} for qw/to subj body/;
        $P{to} ||= ADMINADDR;
    } else {
        $P{to}   = ADMINADDR;
        $P{subj} = "Mutex Crash";
        $P{body} = $init ? $init : 'Bitte manuell pruefen.';
    }
    my $exc; ($exc = $0) =~ s|.*/||;
    $P{body} .= "\n$exc, ".localtime()."\n";
    ## no critic (ProhibitTwoArgOpen)
    open  my $mail_fh, qq/| mail -s '$P{subj}' $P{to}/;
    print $mail_fh  $P{body};
    close $mail_fh;
}


1;


__END__



=head1 NAME

Data::Conveyor::Mutex - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Mutex->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<application>

    my $value = $obj->application;
    $obj->application($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<application_clear>

    $obj->application_clear;

Clears the value.

=item C<clear_application>

    $obj->clear_application;

Clears the value.

=item C<clear_dbinst>

    $obj->clear_dbinst;

Clears the value.

=item C<clear_group_exlock>

    $obj->clear_group_exlock;

Clears the value.

=item C<clear_hostname>

    $obj->clear_hostname;

Clears the value.

=item C<clear_max_parallel>

    $obj->clear_max_parallel;

Clears the value.

=item C<clear_mutex_config_id>

    $obj->clear_mutex_config_id;

Clears the value.

=item C<clear_pid>

    $obj->clear_pid;

Clears the value.

=item C<clear_program_name>

    $obj->clear_program_name;

Clears the value.

=item C<dbinst>

    my $value = $obj->dbinst;
    $obj->dbinst($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<dbinst_clear>

    $obj->dbinst_clear;

Clears the value.

=item C<group_exlock>

    my $value = $obj->group_exlock;
    $obj->group_exlock($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<group_exlock_clear>

    $obj->group_exlock_clear;

Clears the value.

=item C<hostname>

    my $value = $obj->hostname;
    $obj->hostname($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<hostname_clear>

    $obj->hostname_clear;

Clears the value.

=item C<max_parallel>

    my $value = $obj->max_parallel;
    $obj->max_parallel($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<max_parallel_clear>

    $obj->max_parallel_clear;

Clears the value.

=item C<mutex_config_id>

    my $value = $obj->mutex_config_id;
    $obj->mutex_config_id($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<mutex_config_id_clear>

    $obj->mutex_config_id_clear;

Clears the value.

=item C<pid>

    my $value = $obj->pid;
    $obj->pid($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<pid_clear>

    $obj->pid_clear;

Clears the value.

=item C<program_name>

    my $value = $obj->program_name;
    $obj->program_name($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<program_name_clear>

    $obj->program_name_clear;

Clears the value.

=back

Data::Conveyor::Mutex inherits from L<Class::Scaffold::Storable>.

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

    new(), FIRST_CONSTRUCTOR_ARGS(), add_autoloaded_package(), init()

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

Copyright 2004-2009 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

