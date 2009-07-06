package Data::Conveyor::Environment;
# ptags: DCE

# $Id: Environment.pm 13666 2007-11-07 07:53:28Z gr $

use warnings;
use strict;
use Error::Hierarchy::Util qw/assert_defined load_class/;
use Class::Scaffold::Util 'const';
use Class::Scaffold::Factory::Type;
use Class::Value;
use Data::Conveyor::Control::File; # object() doesn't load the class (?).
use Hook::Modular;

# Bring in Class::Value right now, so $Class::Value::SkipChecks can be set
# without it being overwritten, since with framework_object and
# make_obj() Class::Value is loaded only on-demand.


our $VERSION = '0.06';


use base 'Class::Scaffold::Environment';


Class::Scaffold::Base->add_autoloaded_package('Data::Conveyor::');
Class::Scaffold::Environment::gen_class_hash_accessor('STAGE');


# ptags: /(\bconst\b[ \t]+(\w+))/

__PACKAGE__->mk_object_accessors(
    'Data::Conveyor::Control::File' => 'control',
    'Class::Scaffold::Environment::Configurator' => {
        slot       => 'configurator',
        comp_mthds => [ qw/
            max_tickets_per_dispatcher
            dispatcher_sleep
            lockpath
            ignore_locks
            soap_server
            soap_path
            soap_uri
            mutex_storage_name
            mutex_storage_args
            respect_mutex
            should_send_mail
            default_object_limit
            control_filename
            ticket_provider_clause
            modular_config
            storage_init_location

            sif_web_host
            sif_web_port
            sif_web_root
            sif_web_error_log
            sif_web_access_log
            sif_web_debug
        / ]
    },
);


use constant MUTEX_STORAGE_TYPE => 'mutex_storage';

use constant DEFAULTS => (
    test_mode            => (defined $ENV{TEST_MODE} && $ENV{TEST_MODE} == 1),
    # default_object_limit => 250,
);


sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->multiplex_transaction_omit(MUTEX_STORAGE_TYPE() => 1);

    our $did_generate_methods;
    return if $did_generate_methods++;

    # require NEXT;
    # as long as the patched NEXT.pm is in Data::Inherited - i.e., until such
    # time as Damian releases the new version, we do:

    require Data::Inherited;

    # generically generate instruction classes that look like:
    #
    # package Data::Conveyor::Ticket::Payload::Instruction::value_person_organization;
    # use base 'Data::Conveyor::Ticket::Payload::Instruction';
    # __PACKAGE__->mk_framework_object_accessors(
    #     value_person_organization => 'value'
    # );
    # use constant name => 'organization';
    #
    # There are other, more specialized instruction classes like 'clear' or
    # those creating techdata items (which contain several value objects, not
    # just one). There should be one instruction class for every unit that can
    # be added, deleted or updated. A person's organization can be changed by
    # itself, so we have an instruction for that. However, a techdata item can
    # only be changed as a whole (you can't change a techdata item's
    # individual field), so we have one instruction for the whole techdata
    # item.

    # make sure the superclass is loaded so we can inherit from it
    load_class $self->INSTRUCTION_CLASS_BASE(), 1;

    for my $type ($self->generic_instruction_classes) {
        # construct instruction class

        my $class = $self->INSTRUCTION_CLASS_BASE() . '::' . $type;
        no strict 'refs';
        push @{"$class\::ISA"} => $self->INSTRUCTION_CLASS_BASE;

        my $type_method = "$class\::type";
        $::PTAGS && printf "type\t%s\t%s\n", __FILE__, __LINE__+1;
        *$type_method = sub { $type };

        $::PTAGS && printf "%s\t%s\t%s\n", 'value', __FILE__, __LINE__+3;

        # the class gets a $VERSION so that load_class() doesn't attempt to
        # load it, q.v.
        # We also make an entry in %INC so UNIVERSAL::require is happy.
        # load_class() and require() could be called for this class in
        # Data::Comparable.

        eval qq!
            package $class;
            __PACKAGE__->mk_framework_object_accessors($type => 'value');
            our \$VERSION = '0.01';
        !;

        my $file = $class . '.pm';
        $file =~ s!::!/!g;

        $INC{$file} = 1;
        die $@ if $@;
    }
}


sub generic_instruction_classes {
    my $self = shift;
    $self->every_list('INSTRUCTION_CLASS_LIST');
}


sub truth {
    my ($self, $condition) = @_;
    $condition ? $self->YES : $self->NO;
}


# locks
const LO => (
    LO_READ  => 'read',
    LO_WRITE => 'write',
);


# YAML::Active phases
const YAP => (
    YAP_MAKE_TICKET => 'make_ticket',
);


# exception ignore
const EI => ();


# context
const CTX => (
    CTX_BEFORE => 'before',
    CTX_AFTER  => 'after',
);


# ticket types (see Data::Conveyor::Value::Ticket::Type)
const TT => ();


# ticket status
const TS => (
    TS_RUNNING => 'R',
    TS_HOLD    => 'H',
    TS_ERROR   => 'E',
    TS_DONE    => 'D',
    TS_PENDING => 'P',
);


# tx status
const TXS => (
    TXS_RUNNING => 'R',
    TXS_IGNORE  => 'I',
    TXS_ERROR   => 'E',
);


# tx necessity
const TXN => (
    TXN_MANDATORY => 'M',
    TXN_OPTIONAL  => 'O',
);


# tx type
const TXT => (
    TXT_EXPLICIT => 'explicit',
    TXT_IMPLICIT => 'implicit',
);


# object types that can appear in the payload
const OT => (
    OT_LOCK        => 'lock',
    OT_TRANSACTION => 'transaction',
);


# commands
const CMD => ();


# stage return codes
const RC => (
    RC_OK             => 0,
    RC_ERROR          => 3,
    RC_MANUAL         => 7,
    RC_INTERNAL_ERROR => 8,
);


# ticket origins (see Data::Conveyor::Value::Ticket::Origin)
const OR => (
    OR_TEST      => 'tst',
    OR_SIF       => 'sif',
);


# ticket payload instruction commands
const IC => (
    IC_ADD    => 'add',
    IC_UPDATE => 'update',
    IC_DELETE => 'delete',
);


# stages (see ticket stage value object)
const stages => (
    ST_TXSEL  => 'txsel',
);


# stage position names
const stage_positions => (
    STAGE_START  => 'start',
    STAGE_ACTIVE => 'active',
    STAGE_END    => 'end',
);


# notify
const MSG => (
    MSG_NOTOK => 'not OK',
    MSG_OK    => 'OK',
);


# languages
const LANG => (
    LANG_DE => 'de',
    LANG_EN => 'en',
);


# --------------------------------------------------------------------------
# Start of Class::Value::String handling
# --------------------------------------------------------------------------


use constant CHARSET_HANDLER_HASH => (
    _AUTO => 'Data::Conveyor::Charset::ASCII',
);


use constant MAX_LENGTH_HASH => (
    _AUTO => 2000,
);


sub get_charset_handler_for {
    my ($self, $object) = @_;

    our %cache;
    my $object_type =
        Class::Scaffold::Factory::Type->get_factory_type_for($object);

    # cache the every_hash result for efficiency reasons
    unless (defined $cache{charset_handler_hash}) {
        $cache{charset_handler_hash} =
            $self->every_hash('CHARSET_HANDLER_HASH');
    }

    my $class = $cache{charset_handler_hash}{$object_type} ||
        $cache{charset_handler_hash}{_AUTO};
    
    # Cache the charset handler, because there should be only one per
    # subclass. Note that this isn't the same as making
    # Data::Conveyor::Charset::ViaHash a singleton, because there would then
    # be only one in total. We want one per subclass.

    unless (defined $cache{charset_handler}{$class}) {
        $cache{charset_handler}{$class} = $class->new;
    }
    $cache{charset_handler}{$class};
}


sub get_max_length_for {
    my ($self, $object) = @_;

    our %cache;
    my $object_type =
        Class::Scaffold::Factory::Type->get_factory_type_for($object);

    return $cache{max_length}{$object_type} if
        defined $cache{max_length}{$object_type};

    # cache the every_hash result for efficiency reasons
    unless (defined $cache{max_length_hash}) {
        $cache{max_length_hash} = $self->every_hash('MAX_LENGTH_HASH');
    }
    $cache{max_length}{$object_type} = $cache{max_length_hash}{$object_type} ||
        $cache{max_length_hash}{_AUTO};
}


sub setup {
    my $self = shift;
    $self->SUPER::setup(@_);
    require Class::Value::String;
    Class::Value::String->string_delegate($self);
}


# --------------------------------------------------------------------------
# End of Class::Value::String handling
# --------------------------------------------------------------------------


# truth: how are boolean values represented in the storage? truth() uses these
# constants. Some systems might want 1 and 0 for these values.

use constant YES => 'Y';
use constant NO  => 'N';


# service interface parameters
use constant SIP_STRING    => 'string';
use constant SIP_BOOLEAN   => 'boolean';
use constant SIP_MANDATORY => 'mandatory';
use constant SIP_OPTIONAL  => 'optional';


sub FINAL_TICKET_STAGE {
    my $self = shift;
    $self->make_obj('value_ticket_stage')->new_end('ticket');
}


# for display purposes
sub STAGE_ORDER {
    local $_ = $_[0]->delegate;
    (
        $_->ST_TXSEL,
        'ticket',
    );
}


# ----------------------------------------------------------------------
# class name-related code

sub STAGE_CLASS_NAME_HASH {
    local $_ = $_[0]->delegate;
    (
        $_->ST_TXSEL => 'Data::Conveyor::Stage::TxSelector',
    )
}


Class::Scaffold::Factory::Type->register_factory_type(
    exception_container          => 'Data::Conveyor::Exception::Container',
    exception_handler            => 'Data::Conveyor::Exception::Handler',
    lock                         => 'Data::Conveyor::Ticket::Lock',
    monitor                      => 'Data::Conveyor::Monitor',
    mutex                        => 'Data::Conveyor::Mutex',
    payload_common               => 'Data::Conveyor::Ticket::Payload::Common',
    payload_transaction          => 'Data::Conveyor::Ticket::Payload::Transaction',
    payload_lock                 => 'Data::Conveyor::Ticket::Payload::Lock',
    service_interface_shell      => 'Data::Conveyor::Service::Interface::Shell',
    service_interface_soap       => 'Data::Conveyor::Service::Interface::SOAP',
    service_methods              => 'Data::Conveyor::Service::Methods',
    service_result_container     => 'Data::Conveyor::Service::Result::Container',
    service_result_scalar        => 'Data::Conveyor::Service::Result::Scalar',
    service_result_tabular       => 'Data::Conveyor::Service::Result::Tabular',
    sif_http_engine_serversimple => 'Data::Conveyor::Service::Interface::Webserver::ServerSimple',
    sif_http_engine_test         => 'Data::Conveyor::Service::Interface::Webserver::Test',
    sif_http_engine_handler      => 'Data::Conveyor::Service::Interface::Webserver::Handler',
    sif_http_engine_util         => 'Data::Conveyor::Service::Interface::Webserver::Util',
    sif_http_engine_log          => 'Data::Conveyor::Service::Interface::Webserver::Log',
    sif_http_engine_rpc          => 'Data::Conveyor::Service::Interface::Webserver::RPC',
    template_factory             => 'Data::Conveyor::Template::Factory',
    test_ticket                  => 'Data::Conveyor::Test::Ticket',
    ticket                       => 'Data::Conveyor::Ticket',
    ticket_dispatcher            => 'Data::Conveyor::Ticket::Dispatcher',
    ticket_dispatcher_test       => 'Data::Conveyor::Ticket::Dispatcher::Test',
    ticket_facets                => 'Data::Conveyor::Ticket::Facets',
    ticket_payload               => 'Data::Conveyor::Ticket::Payload',
    payload_instruction_container =>
        'Data::Conveyor::Ticket::Payload::Instruction::Container',
    payload_instruction_factory  =>
        'Data::Conveyor::Ticket::Payload::Instruction::Factory',
    ticket_provider              => 'Data::Conveyor::Ticket::Provider',
    ticket_transition            => 'Data::Conveyor::Ticket::Transition',
    transaction                  => 'Data::Conveyor::Ticket::Transaction',
    transaction_factory          => 'Data::Conveyor::Transaction::Factory',
    value_command                => 'Data::Conveyor::Value::Command',
    value_lock_type              => 'Data::Conveyor::Value::LockType',
    value_object_type            => 'Data::Conveyor::Value::ObjectType',
    value_ticket_number          => 'Data::Conveyor::Value::Ticket::Number',
    value_ticket_origin          => 'Data::Conveyor::Value::Ticket::Origin',
    value_ticket_rc              => 'Data::Conveyor::Value::Ticket::RC',
    value_payload_instruction_command =>
        'Data::Conveyor::Value::Ticket::Payload::Instruction::Command',
    value_ticket_stage           => 'Data::Conveyor::Value::Ticket::Stage',
    value_ticket_status          => 'Data::Conveyor::Value::Ticket::Status',
    value_ticket_type            => 'Data::Conveyor::Value::Ticket::Type',
    value_transaction_necessity  => 'Data::Conveyor::Value::Transaction::Necessity',
    value_transaction_status     => 'Data::Conveyor::Value::Transaction::Status',
    value_transaction_type       => 'Data::Conveyor::Value::Transaction::Type',

    stage_delegate               => 'Data::Conveyor::Delegate::Stage',
);


use constant DELEGATE_ACCESSORS => qw(
    stage_delegate
);


use constant STORAGE_CLASS_NAME_HASH => (
    # storage names
    STG_DC_NULL   => 'Data::Conveyor::Storage::Null',
);


use constant INSTRUCTION_CLASS_BASE =>
    'Data::Conveyor::Ticket::Payload::Instruction';


# used to generate instruction classes, see init() above

sub INSTRUCTION_CLASS_LIST { () }


# ----------------------------------------------------------------------
# storage-related code

use constant STORAGE_TYPE_HASH => (
    mutex             => MUTEX_STORAGE_TYPE,
    ticket_transition => 'memory_storage',
);


sub mutex_storage {
    my $self = shift;
    $self->storage_cache->{MUTEX_STORAGE_TYPE()} ||= $self->make_storage_object(
        $self->mutex_storage_name, $self->mutex_storage_args);
}


# ----------------------------------------------------------------------
# how many transactions of a given object_type may occur in a ticket of a given
# ticket type?

use constant object_limit => {};


sub get_object_limit {
    my ($self, $ticket_type, $object_type) = @_;
    my $limit = $self->object_limit->{$ticket_type}{$object_type} ||
        $self->default_object_limit;
    return $limit if defined $limit;
    throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
        sprintf "Can't determine object limit for ticket type [%s], object type [%s]",
        $ticket_type, $object_type
    );
}


# ----------------------------------------------------------------------
# code to make objects of various types

sub make_stage_object {
    my ($self, $stage_type, @args) = @_;
    assert_defined $stage_type, 'called without stage type.';
    my $class = $self->get_stage_class_name_for($stage_type);
    assert_defined $class, "no stage class name found for [$stage_type]. Hint: did you define it in STAGE_CLASS_NAME_HASH?";
    load_class $class, $self->test_mode;
    $class->new(@args);
}


# like the generated make_*_object() methods, but cache the object.

sub make_ticket_transition_object {
    my $self = shift;
    our $ticket_transition_object ||=
        $self->make_obj(ticket_transition => @_);
};


sub allowed_dispatcher_stages {
    my $self = shift;
    $self->delegate->stages;
}


# ----------------------------------------------------------------------
# plugins

sub plugin_handler {
    my $self = shift;
    $self->{plugin_handler} ||= Hook::Modular->new(config =>
        defined $self->modular_config ? $self->modular_config : {}
    );
}


1;


__END__



=head1 NAME

Data::Conveyor::Environment - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Environment->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<clear_configurator>

    $obj->clear_configurator;

Deletes the object.

=item C<clear_control>

    $obj->clear_control;

Deletes the object.

=item C<configurator>

    my $object = $obj->configurator;
    $obj->configurator($object);
    $obj->configurator(@args);

If called with an argument object of type Class::Scaffold::Environment::Configurator it sets the object; further
arguments are discarded. If called with arguments but the first argument is
not an object of type Class::Scaffold::Environment::Configurator, a new object of type Class::Scaffold::Environment::Configurator is constructed and the
arguments are passed to the constructor.

If called without arguments, it returns the Class::Scaffold::Environment::Configurator object stored in this slot;
if there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor in this case - and stored in the configurator slot
before returning it.

=item C<configurator_clear>

    $obj->configurator_clear;

Deletes the object.

=item C<control>

    my $object = $obj->control;
    $obj->control($object);
    $obj->control(@args);

If called with an argument object of type Data::Conveyor::Control::File it sets the object; further
arguments are discarded. If called with arguments but the first argument is
not an object of type Data::Conveyor::Control::File, a new object of type Data::Conveyor::Control::File is constructed and the
arguments are passed to the constructor.

If called without arguments, it returns the Data::Conveyor::Control::File object stored in this slot;
if there is no such object, a new Data::Conveyor::Control::File object is constructed - no arguments
are passed to the constructor in this case - and stored in the control slot
before returning it.

=item C<control_clear>

    $obj->control_clear;

Deletes the object.

=item C<control_filename>

    $obj->control_filename(@args);
    $obj->control_filename;

Calls control_filename() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
control_filename() onto it.

=item C<default_object_limit>

    $obj->default_object_limit(@args);
    $obj->default_object_limit;

Calls default_object_limit() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
default_object_limit() onto it.

=item C<dispatcher_sleep>

    $obj->dispatcher_sleep(@args);
    $obj->dispatcher_sleep;

Calls dispatcher_sleep() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
dispatcher_sleep() onto it.

=item C<ignore_locks>

    $obj->ignore_locks(@args);
    $obj->ignore_locks;

Calls ignore_locks() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
ignore_locks() onto it.

=item C<lockpath>

    $obj->lockpath(@args);
    $obj->lockpath;

Calls lockpath() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
lockpath() onto it.

=item C<max_tickets_per_dispatcher>

    $obj->max_tickets_per_dispatcher(@args);
    $obj->max_tickets_per_dispatcher;

Calls max_tickets_per_dispatcher() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
max_tickets_per_dispatcher() onto it.

=item C<modular_config>

    $obj->modular_config(@args);
    $obj->modular_config;

Calls modular_config() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
modular_config() onto it.

=item C<mutex_storage_args>

    $obj->mutex_storage_args(@args);
    $obj->mutex_storage_args;

Calls mutex_storage_args() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
mutex_storage_args() onto it.

=item C<mutex_storage_name>

    $obj->mutex_storage_name(@args);
    $obj->mutex_storage_name;

Calls mutex_storage_name() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
mutex_storage_name() onto it.

=item C<respect_mutex>

    $obj->respect_mutex(@args);
    $obj->respect_mutex;

Calls respect_mutex() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
respect_mutex() onto it.

=item C<should_send_mail>

    $obj->should_send_mail(@args);
    $obj->should_send_mail;

Calls should_send_mail() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
should_send_mail() onto it.

=item C<soap_path>

    $obj->soap_path(@args);
    $obj->soap_path;

Calls soap_path() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
soap_path() onto it.

=item C<soap_server>

    $obj->soap_server(@args);
    $obj->soap_server;

Calls soap_server() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
soap_server() onto it.

=item C<soap_uri>

    $obj->soap_uri(@args);
    $obj->soap_uri;

Calls soap_uri() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
soap_uri() onto it.

=item C<ticket_provider_clause>

    $obj->ticket_provider_clause(@args);
    $obj->ticket_provider_clause;

Calls ticket_provider_clause() with the given arguments on the object stored in the configurator slot.
If there is no such object, a new Class::Scaffold::Environment::Configurator object is constructed - no arguments
are passed to the constructor - and stored in the configurator slot before forwarding
ticket_provider_clause() onto it.

=back

Data::Conveyor::Environment inherits from L<Class::Scaffold::Environment>.

The superclass L<Class::Scaffold::Environment> defines these methods and
functions:

    all_storages_are_implemented(), clear_context(),
    clear_multiplex_transaction_omit(), clear_rollback_mode(),
    clear_storage_cache(), clear_test_mode(), commit(), context(),
    context_clear(), core_storage(), core_storage_args(),
    core_storage_name(), delete_multiplex_transaction_omit(),
    delete_storage_cache(), disconnect(),
    exists_multiplex_transaction_omit(), exists_storage_cache(),
    gen_class_hash_accessor(), get_class_name_for(),
    get_storage_type_for(), getenv(), isa_type(),
    keys_multiplex_transaction_omit(), keys_storage_cache(),
    load_cached_class_for_type(), make_delegate(), make_obj(),
    make_storage_object(), memory_storage(), memory_storage_name(),
    multiplex_transaction_omit(), multiplex_transaction_omit_clear(),
    multiplex_transaction_omit_delete(),
    multiplex_transaction_omit_exists(), multiplex_transaction_omit_keys(),
    multiplex_transaction_omit_values(), rollback(), rollback_mode(),
    rollback_mode_clear(), rollback_mode_set(), set_rollback_mode(),
    setenv(), storage_cache(), storage_cache_clear(),
    storage_cache_delete(), storage_cache_exists(), storage_cache_keys(),
    storage_cache_values(), storage_for_type(), test_mode(),
    test_mode_clear(), values_multiplex_transaction_omit(),
    values_storage_cache()

The superclass L<Class::Scaffold::Base> defines these methods and
functions:

    new(), FIRST_CONSTRUCTOR_ARGS(), MUNGE_CONSTRUCTOR_ARGS(),
    add_autoloaded_package(), log()

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

