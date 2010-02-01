package Data::Conveyor::Service::Interface::Shell;

use warnings;
use strict;

use Data::Conveyor::Service::Methods;
use Data::Dumper;   # for the debug command
use Data::Miscellany 'is_defined';
use Error ':try';
use Error::Hierarchy;
use Getopt::Long;
use Pod::Text;
use IO::Pager;   # not used really, just determines a pager at BEGIN time
use once;

our $VERSION = '0.11';

# It's ok to inherit from Data::Conveyor::Service::Interface as well; new()
# will be found in Term::Shell::Enhanced first.

use base qw(
    Term::Shell::Enhanced
    Data::Conveyor::Service::Interface
);


__PACKAGE__
    ->mk_hash_accessors(qw(sth))
    ->mk_integer_accessors(qw(num))
    ->mk_scalar_accessors(qw(
        base hostname limit log name prompt_spec ticket_no pager
    ));


# These aren't the constructor()'s DEFAULTS()!  Because new() comes from
# Term::Shell, not Class::Scaffold::Base, we don't have the convenience of
# the the mk_constructor()-generated constructor. Therefore,
# Term::Shell::Enhanced defines its own mechanism.

sub DEFAULTS {
    my $self = shift;
    (
        name        => 'dcsh',
        longname    => 'Data-Conveyor Shell',
        ticket_no   => '',
        limit       => 10,
        prompt_spec => ': \n_(\d)_[\t]:\#; ',
        pager       => $ENV{PAGER},             # as set by IO::Pager
    );
}


sub PROMPT_VARS {
    my $self = shift;
    (
        t => $self->ticket_no            || '',
        d => $self->svc->storage->dbname || 'n/a',
    );
}


sub init {
    my $self = shift;
    $self->delegate->test_mode(1);      # force log to STDOUT

    # can't do $self->SUPER::init(@_), because that would find only
    # Term::Shell::Enhanced::init(), but not the
    # Data::Conveyor::Service::Interface::init().

    $self->Term::Shell::Enhanced::init(@_);
    $self->Data::Conveyor::Service::Interface::init(@_);

    my %args = @{ $self->{API}{args} };
    $self->base($args{base}) unless defined $self->base;

    # generate methods for handling generic service commands

    ONCE {

        # Generate handlers for all methods listed in the Service Methods
        # object. They are being generated into this package. If you need
        # custom implementations for some handlers, override them in the
        # appropriate subclass.

        for my $command ($self->svc->get_method_names) {

            no strict 'refs';

            # separate lexical vars ($meth1, $meth2, $meth3) for closures

            # smry_* method
            my $meth1 = sprintf "smry_%s" => $command;
            unless (defined *{$meth1}{CODE}) {
                $::PTAGS && $::PTAGS->add_tag($meth1, __FILE__, __LINE__+1);
                *$meth1 = sub {
                    local $DB::sub = local *__ANON__ =
                        "Data::Conveyor::Service::Interface::Shell::${meth1}"
                        if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    $self->summary_for_service_method($command);
                };
            }

            # help_* method
            my $meth2 = sprintf "help_%s" => $command;
            unless (defined *{$meth2}{CODE}) {
                $::PTAGS && $::PTAGS->add_tag($meth2, __FILE__, __LINE__+1);
                *$meth2 = sub {
                    local $DB::sub = local *__ANON__ =
                        "Data::Conveyor::Service::Interface::Shell::${meth2}"
                        if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    $self->get_help_for_service_method($command);
                };
            }

            # run_* method
            my $meth3 = sprintf "run_%s" => $command;
            unless (defined *{$meth3}{CODE}) {
                $::PTAGS && $::PTAGS->add_tag($meth3, __FILE__, __LINE__+1);
                *$meth3 = sub {
                    local $DB::sub = local *__ANON__ =
                        "Data::Conveyor::Service::Interface::Shell::${meth3}"
                        if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    $self->execute_service_method($command, @_);
                };
            }

            $self->{handlers}{$command} = {
                smry => $meth1,
                help => $meth2,
                run  => $meth3,
            };
        }
    };
}


# override run() to disconnect from all storages so that changes are visible
# immediately, not just when the shell exits.

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    $self->delegate->disconnect;
}


# ========================================================================
# utility methods
# ========================================================================


sub check_ticket_no {
    my ($self, $ticket_no) = @_;
    require Data::Conveyor::Value::Ticket::Number;
    return 1 if Data::Conveyor::Value::Ticket::Number->check($ticket_no);
    printf "[%s] doesn't look like a valid ticket number.\n", $ticket_no;
    return 0;
}


sub check_limit {
    my ($self, $limit) = @_;
    if ($limit =~ /^\d+$/) {
        return 1;
    } else {
        printf "[%s] doesn't look like a valid limit (should be a digit).\n",
            $limit;
        return 0;
    }
}


# ========================================================================
# service method helpers
# ========================================================================

sub getopt_spec_for_method {
    my ($self, $method) = @_;
    my @getopt;
    for my $param ($self->svc->get_params_for_method($method)) {
        my $getopt = $param->{name};
        if ($param->{short}) { $getopt .= '|' . $param->{short} }

        if ($param->{type} eq $self->delegate->SIP_STRING) {
            $getopt .= '=s';
        }

        push @getopt => $getopt;
    }
    wantarray ? @getopt: \@getopt;
}


sub get_param_help_for_method {
    my ($self, $method) = @_;
    my $help = '';
    for my $param ($self->svc->get_params_for_method($method)) {
        my $item = '--' . $param->{name};
        if ($param->{short}) { $item .= ', -' . $param->{short} }

        my %map = (
            $self->delegate->SIP_STRING    => 'String',
            $self->delegate->SIP_BOOLEAN   => 'Boolean',
            $self->delegate->SIP_MANDATORY => 'Mandatory',
            $self->delegate->SIP_OPTIONAL  => 'Optional',
        );

        my $description = '[' . $map{ $param->{type} } . '] [' .
            $map{ $param->{necessity} } . '] ';

        $description .= "[Default: $param->{default}] " if
            defined $param->{default};

        $description .= $param->{description};

        if ($param->{name} eq 'ticket' &&
            $param->{necessity} eq $self->delegate->SIP_MANDATORY) {

            my $ticket_no = $self->ticket_no;
            $ticket_no = 'none' unless
                is_defined($ticket_no) && length $ticket_no;

            $description .= sprintf
                ' Unless given, the current ticket number (%s) will be used.',
                $ticket_no;
        }

        if ($param->{name} eq 'limit') {

            $description .= sprintf
                ' Unless given, the current limit (%s) will be used.',
                (is_defined($self->limit) ? $self->limit : 'none');
        }

        $help .= "=item $item\n\n$description\n\n";
    }
    return "\n\n=over 4\n\n$help\n\n=back\n\n";
}


sub get_example_help_for_method {
    my ($self, $method) = @_;
    my $example_pod = '';
    my $example_count = 0;
    for my $example ($self->svc->get_examples_for_method($method)) {
        $example_count++;
        $example_pod .= "=item $method";
        while (my ($name, $value) = each %$example) {
            $example_pod .= " --$name";
            $example_pod .= " $value" if defined $value;
        }
        $example_pod .= "\n\n";
    }

    if (length $example_pod) {
        $example_pod = "=over 4\n\n$example_pod\n\n=back\n\n";
    }

    if ($example_count == 1) {
        $example_pod = "Example:\n\n$example_pod";
    } elsif ($example_count > 1) {
        $example_pod = "Examples:\n\n$example_pod";
    }
    $example_pod;
}


sub pod_to_text {
    my ($self, $pod) = @_;

    open my $pod_fh, '<', \$pod or
        die "can't open filehandle to scalar \$pod";
    my $text = '';
    open my $text_fh, '>', \$text or
        die "can't open filehandle to scalar \$text";
    my $parser = Pod::Text->new;
    $parser->parse_from_filehandle($pod_fh, $text_fh);
    close $pod_fh or die "can't close filehandle to scalar \$pod";
    close $text_fh or die "can't close filehandle to scalar \$text";

    $text;
}


sub summary_for_service_method {
    my ($self, $method) = @_;
    $self->svc->get_summary_for_method($method);
}


# don't call this just "help_for_service_method", or Term::Shell's
# find_handler() will find it and assume that there's a command
# "for_service_method".

sub get_help_for_service_method {
    my ($self, $method) = @_;
    my $description = $self->svc->get_description_for_method($method);
    my $param_help = $self->get_param_help_for_method($method);
    my $example_pod = $self->get_example_help_for_method($method);
    my $pod = <<EOPOD;
=pod

$method

$description

$param_help

$example_pod

=cut
EOPOD

    $self->pod_to_text($pod);
}


# Don't call this run_service_method, or Term::Shell will think it's a
# command.

sub execute_service_method {
    my $self   = shift;
    my $method = shift;
    local @ARGV = @_;

    my %opt;
    GetOptions(\%opt, $self->getopt_spec_for_method($method)) or
        return $self->run_help($method);

    if (@ARGV) {
        print "extraneous arguments [@ARGV]\n\n";
        return $self->run_help($method);
    }

    my $params = $self->svc->get_params_for_method($method);

    # if there's a mandatory 'ticket' param, it defaults to the current ticket
    # number

    if ((grep { $_->{name} eq 'ticket' &&
                $_->{necessity} eq $self->delegate->SIP_MANDATORY } @$params
        ) && !(defined $opt{ticket})) {

        my $ticket_no = $self->ticket_no;
        unless ($ticket_no) {
            print
                "--ticket not given and there is no current ticket number.\n\n";
            return $self->run_help($method);
        }
        $opt{ticket} = $ticket_no;
    }

    # if there's a 'limit' param, it defaults to the current limit

    if ((grep { $_->{name} eq 'limit' } @$params) && !(defined $opt{limit})) {
        $opt{limit} = $self->limit;
    }

    # check other mandatory parameters

    my @params = $self->svc->get_params_for_method($method);
    for my $param (@params) {
        next if defined $opt{ $param->{name} };

        # If the method only has one parameter and there is something left in
        # @ARGV (unparsed by GetOptions), assume it's that parameter's value.
        #
        # This way, you can say "somecmd somevalue" instead of "somecmd -d
        # somevalue" if "-d" is the only arguments. It's just a little bit
        # more convenient and intuitive.

        if ((@params == 1) && (@ARGV >= 1)) {
            $opt{ $param->{name} } = shift @ARGV;
            next;
        }

        next unless $param->{necessity} eq $self->delegate->SIP_MANDATORY;
        print "missing mandatory parameter [$param->{name}]\n\n";
        return $self->run_help($method);
    }

    $self->svc->apply_param_aliases_and_defaults($method, \%opt);

    try {
        $self->print_result($self->svc->run_method($method, %opt));
    } catch Data::Conveyor::Exception::ServiceMethodHelp with {
        print $_[0]->custom_message . "\n\n";
        $self->run_help($method);
    } catch Error with {
        print "$_[0]\n"
    };
}


# print a service result object
sub print_result {
    my ($self, $result) = @_;
    # just stringify, but make sure there is a newline at the end
    chomp($result);
    $result .= "\n";

    if ($self->pager) {
        my $pager = $self->pager;
        ## no critic (ProhibitTwoArgOpen)
        open my $fh, "| $pager" or die "can't pipe to $pager: $!\n";
        print $fh $result;
        # close() doesn't work because of broken pipe...
    } else {
        print $result;
    }
}


# ========================================================================
# pager
# ========================================================================


sub smry_pager { 'get or set the current pager' }
sub help_pager { <<'END' }
pager [<pager>]
  Get or set the current pager. If the value is "off", no pager will be used.

END

sub run_pager {
    my $self = shift;
    if (@_) {
        my $pager = shift;
        $pager = '' if lc($pager) eq 'off';
        $self->pager($pager);
    }

    printf "Current pager is [%s]\n", $self->pager;
}


# ========================================================================
# ticket
# ========================================================================


sub smry_ticket { 'get or set the current ticket number' }
sub help_ticket { <<'END' }
ticket [<ticket_no>]
  Get or set the current ticket number.

END

sub run_ticket {
    my $self = shift;
    if (@_) {
        my $ticket_no = shift;
        $self->check_ticket_no($ticket_no) and $self->ticket_no($ticket_no);
    }

    printf "Current ticket no is [%s]\n", $self->ticket_no;
}


# ========================================================================
# limit
# ========================================================================


sub smry_limit { 'get or set the current limit (max. rows returned by a command)' }
sub help_limit { <<'END' }
limit [<limit>]
  Get or set the current limit (max. rows returned by a command).

END

sub run_limit {
    my $self = shift;
    if (@_) {
        my $limit = shift;
        $self->check_limit($limit) and $self->limit($limit);
    }

    printf "Current limit is [%s]\n", $self->limit;
}


# ========================================================================
# debug
# ========================================================================


sub smry_debug { 'print debugging information' }
sub help_debug { <<'END' }
debug
  Prints the current state of some internal variables for debugging
  purposes.
END


# subclasses can extend this

sub debug_lines {
    my $self = shift;
    my @debug = (
        "CF_CONF: $ENV{CF_CONF}",
        sprintf("environment: %s", $self->delegate->configurator->environment),
        scalar(Data::Dumper->Dump([scalar($self->delegate->OR)], [qw/OR/])),
    );
}


sub run_debug {
    my $self = shift;
    try {
        $self->print_result($_) for $self->debug_lines;
    } catch Error with { print "$_[0]\n" };
}


1;


__END__



=head1 NAME

Data::Conveyor::Service::Interface::Shell - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Service::Interface::Shell->new;

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 METHODS

=over 4

=item C<base>

    my $value = $obj->base;
    $obj->base($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<base_clear>

    $obj->base_clear;

Clears the value.

=item C<clear_base>

    $obj->clear_base;

Clears the value.

=item C<clear_hostname>

    $obj->clear_hostname;

Clears the value.

=item C<clear_limit>

    $obj->clear_limit;

Clears the value.

=item C<clear_log>

    $obj->clear_log;

Clears the value.

=item C<clear_name>

    $obj->clear_name;

Clears the value.

=item C<clear_pager>

    $obj->clear_pager;

Clears the value.

=item C<clear_prompt_spec>

    $obj->clear_prompt_spec;

Clears the value.

=item C<clear_sth>

    $obj->clear_sth;

Deletes all keys and values from the hash.

=item C<clear_ticket_no>

    $obj->clear_ticket_no;

Clears the value.

=item C<dec_num>

    $obj->dec_num;

Decreases the value by 1.

=item C<delete_sth>

    $obj->delete_sth(@keys);

Takes a list of keys and deletes those keys from the hash.

=item C<exists_sth>

    if ($obj->exists_sth($key)) { ... }

Takes a key and returns a true value if the key exists in the hash, and a
false value otherwise.

=item C<hostname>

    my $value = $obj->hostname;
    $obj->hostname($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<hostname_clear>

    $obj->hostname_clear;

Clears the value.

=item C<inc_num>

    $obj->inc_num;

Increases the value by 1.

=item C<keys_sth>

    my @keys = $obj->keys_sth;

Returns a list of all hash keys in no particular order.

=item C<limit>

    my $value = $obj->limit;
    $obj->limit($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<limit_clear>

    $obj->limit_clear;

Clears the value.

=item C<log>

    my $value = $obj->log;
    $obj->log($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<log_clear>

    $obj->log_clear;

Clears the value.

=item C<name>

    my $value = $obj->name;
    $obj->name($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<name_clear>

    $obj->name_clear;

Clears the value.

=item C<num>

    $obj->num($value);
    my $value = $obj->num;

A basic getter/setter method. If called without an argument, it returns the
value, or 0 if there is no previous value. If called with a single argument,
it sets the value.

=item C<num_dec>

    $obj->num_dec;

Decreases the value by 1.

=item C<num_inc>

    $obj->num_inc;

Increases the value by 1.

=item C<num_reset>

    $obj->num_reset;

Resets the value to 0.

=item C<pager>

    my $value = $obj->pager;
    $obj->pager($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<pager_clear>

    $obj->pager_clear;

Clears the value.

=item C<prompt_spec>

    my $value = $obj->prompt_spec;
    $obj->prompt_spec($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<prompt_spec_clear>

    $obj->prompt_spec_clear;

Clears the value.

=item C<reset_num>

    $obj->reset_num;

Resets the value to 0.

=item C<sth>

    my %hash     = $obj->sth;
    my $hash_ref = $obj->sth;
    my $value    = $obj->sth($key);
    my @values   = $obj->sth([ qw(foo bar) ]);
    $obj->sth(%other_hash);
    $obj->sth(foo => 23, bar => 42);

Get or set the hash values. If called without arguments, it returns the hash
in list context, or a reference to the hash in scalar context. If called
with a list of key/value pairs, it sets each key to its corresponding value,
then returns the hash as described before.

If called with exactly one key, it returns the corresponding value.

If called with exactly one array reference, it returns an array whose elements
are the values corresponding to the keys in the argument array, in the same
order. The resulting list is returned as an array in list context, or a
reference to the array in scalar context.

If called with exactly one hash reference, it updates the hash with the given
key/value pairs, then returns the hash in list context, or a reference to the
hash in scalar context.

=item C<sth_clear>

    $obj->sth_clear;

Deletes all keys and values from the hash.

=item C<sth_delete>

    $obj->sth_delete(@keys);

Takes a list of keys and deletes those keys from the hash.

=item C<sth_exists>

    if ($obj->sth_exists($key)) { ... }

Takes a key and returns a true value if the key exists in the hash, and a
false value otherwise.

=item C<sth_keys>

    my @keys = $obj->sth_keys;

Returns a list of all hash keys in no particular order.

=item C<sth_values>

    my @values = $obj->sth_values;

Returns a list of all hash values in no particular order.

=item C<ticket_no>

    my $value = $obj->ticket_no;
    $obj->ticket_no($value);

A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.

=item C<ticket_no_clear>

    $obj->ticket_no_clear;

Clears the value.

=item C<values_sth>

    my @values = $obj->values_sth;

Returns a list of all hash values in no particular order.

=back

Data::Conveyor::Service::Interface::Shell inherits from
L<Term::Shell::Enhanced> and L<Data::Conveyor::Service::Interface>.

The superclass L<Term::Shell::Enhanced> defines these methods and
functions:

    catch_run(), clear_opt(), cmd(), delete_opt(), exists_opt(), expand(),
    fini(), get_history_filename(), getopt(), help_alias(), help_apropos(),
    help_cd(), help_echo(), help_eval(), help_pwd(), help_quit(),
    help_set(), keys_opt(), opt(), opt_clear(), opt_delete(), opt_exists(),
    opt_keys(), opt_values(), postloop(), precmd(), print_greeting(),
    prompt_str(), run_(), run_alias(), run_apropos(), run_cd(), run_echo(),
    run_pwd(), run_quit(), run_set(), smry_alias(), smry_apropos(),
    smry_cd(), smry_echo(), smry_eval(), smry_pwd(), smry_quit(),
    smry_set(), values_opt()

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

The superclass L<Term::Shell> defines these methods and functions:

    new(), DESTROY(), add_commands(), add_handlers(), cmd_prefix(),
    cmd_suffix(), cmdloop(), comp_(), comp_help(), complete(),
    completions(), do_action(), exact_action(), find_handlers(),
    format_pairs(), get_aliases(), handler(), has_aliases(),
    have_readkey(), help(), help_exit(), help_help(), idle(), is_alias(),
    line(), line_args(), line_parsed(), msg_ambiguous_cmd(),
    msg_unknown_cmd(), page(), page_internal(), parse_quoted(),
    possible_actions(), postcmd(), preloop(), print_pairs(), process_esc(),
    prompt(), readkey(), readline(), remove_commands(), remove_handlers(),
    rl_complete(), run_exit(), run_help(), smry_exit(), smry_help(),
    stoploop(), summary(), term(), termsize(), unalias(), uniq()

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

The superclass L<Data::Conveyor::Service::Interface> defines these methods
and functions:

    args(), args_clear(), args_delete(), args_exists(), args_keys(),
    args_values(), clear_args(), clear_svc(), delete_args(), exists_args(),
    keys_args(), svc(), svc_clear(), values_args()

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

    FIRST_CONSTRUCTOR_ARGS(), add_autoloaded_package()

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

