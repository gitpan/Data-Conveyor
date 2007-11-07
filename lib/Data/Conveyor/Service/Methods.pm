package Data::Conveyor::Service::Methods;

# $Id: Methods.pm 13653 2007-10-22 09:11:20Z gr $
#
# Wrapper around service methods coming from different classes. This class
# exists to avoid the situation where every service interface has to know the
# location of each service methods.

use strict;
use warnings;
use Error ':try';


our $VERSION = '0.01';


use base 'Data::Conveyor::Service';


# generate parameter specs from an efficient getopt-like input format

sub PARAMS {
    my ($self, @spec) = @_;

    # spec could be something like:
    #
    # "+domain|d=s Domain name.",
    # "?logtest|l  Don't delete the domain, just write the log ticket.",
    # "?force|f    Disregard the 'SPR' flag.",
    #
    # <necessity><name>|<short>[=<type>][><default>]
    #
    # necessity:
    #   '+' = mandatory
    #   '?' = optional
    # name, short: parameter names
    # type: '=s' for string, none for boolean
    #
    # type and default are optional

    my @params;

    for my $spec (@spec) {
        my ($getopt, $description) = split /\s+/, $spec, 2;

        $getopt =~ /^([+?])(\w+)(\|\w+)?(=\w+)?(>.*)?$/ or die
            qq!Can't parse service method's parameter specification "$getopt" - use the "<necessity><name>[|<short>][=<type>][><default>]" format!;

        my ($necessity, $name, $short, $type, $default) = ($1, $2, $3, $4, $5);

        defined($_) || ($_ = '') for $necessity, $name, $short, $type, $default;
        $short =~ s/^\|//;

        my %necessity_map = (
           '+' => $self->delegate->SIP_MANDATORY,
           '?' => $self->delegate->SIP_OPTIONAL,
        );
        $necessity = length $necessity
            ? $necessity_map{$necessity}
            : $self->delegate->SIP_MANDATORY;
        
        my %type_map = (
           '=s' => $self->delegate->SIP_STRING,
        );
        $type = length $type ? $type_map{$type} : $self->delegate->SIP_BOOLEAN;
        
        $default =~ s/^>//;

        my %param;

        # The 'description' may yet contain 'alias' definitions - if so, split
        # them up. Note that not all service interfaces need to support
        # aliases - typically, a shell interface won't, but a SOAP interface
        # might, to support legacy SOAP calls.

        my $aliases = [];
        if ($description =~ /^=([\w,]+)\s+(.*)$/) {
            $description = $2;
            $aliases = [ split /,/ => $1 ];
        }

        push @params => {
            name        => $name,
            short       => $short,
            type        => $type,
            necessity   => $necessity,
            aliases     => $aliases,
            description => $description,
            (length $default ? (default => $default) : ()),
        };
    }

    return (params => \@params);
}


sub SERVICE_METHODS {
    dump => {
        object => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s Ticket number",
            "?raw|r      Dump ticket as-is, not comparable",
        ),
        description => 'Uses Data::Dumper to dump a ticket.',
    },

    ydump => {
        object => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s Ticket number",
        ),
        description => 'Uses YAML to dump a ticket.',
    },

    get_ticket_payload => {
        object => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s Ticket number",
        ),
        description => "Show the given ticket's payload.",
    },

    exceptions => {
        object => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s Ticket number",
            "?raw|r      Print raw exception, not stringified",
        ),
        description => 'Shows all exceptions of a ticket.',
    },

    clear_exceptions => {
        object => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s Ticket number",
        ),
        description => 'Shows all exceptions of a ticket.',
    },

    exceptions_structured => {
        object => 'ticket',
        aliases => [ 'get_errors' ],
        $_[0]->PARAMS(
            "+ticket|t=s  Ticket number",
            "?object|o=s  Restrict to this object type (e.g., 'person')",
        ),
        description => "Get a ticket's exceptions in a structured form.",
    },

    delete_exception => {
        object => 'ticket',
        aliases => [ 'del_error' ],
        $_[0]->PARAMS(
            "+ticket|t=s  Ticket number",
            "+uuid|u=s    UUID of the exception to delete",
        ),
        description => "Delete an exception from a ticket.",
        examples => [
            {
                ticket => '200707301444.003384594',
                uuid   => '4162F712-1DD2-11B2-B17E-C09EFE1DC403',
            },
        ],
    },

    journal => {
        object => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s Ticket number",
        ),
        description => 'Shows the journal of a ticket.',
    },

    set_stage => {
        object => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s =ticket_no Ticket number",
            "+stage|g=s  Set to this stage (e.g., 'starten_policy')",
        ),
        description => "Set a ticket's stage.",
    },

    set_state => {
        object  => 'ticket',
        $_[0]->PARAMS(
            "+ticket|t=s    Ticket number",
            "+stage|g=s     Set to this stage (e.g., 'starten_policy')",
            "?status|s=s>R  Set to this status",
            "?rc|r=s>0      Set to this rc",
        ),
        description => "Set a ticket's stage, status and/or rc.",
        examples => [
            {
                stage  => 'starten_policy',
                status => 'R',
                rc     => 3,
            },
        ],
    },

    top => {
        object => 'monitor',
        $_[0]->PARAMS(
            "?all|a  Report all relevant status values (will be slower)",
        ),
        description => "Show how many tickets there are currently in each stage. Unless the 'all' argument is given, only running and 'on hold' tickets (status 'R' and 'H') are reported.",
    },

}


sub get_method_names {
    my $self = shift;
    $self->{_service_methods} ||= $self->every_hash('SERVICE_METHODS');
    my %methods = %{ $self->{_service_methods} };
    my @keys = keys %methods;
    wantarray ? @keys : \@keys;
}


sub get_spec_for_method {
    my ($self, $method) = @_;
    $self->{_service_methods} ||= $self->every_hash('SERVICE_METHODS');
    $self->{_service_methods}{$method} or
        throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
            sprintf 'no service method [%s]', $method);
}


sub get_params_for_method {
    my ($self, $method) = @_;
    my $params = $self->get_spec_for_method($method)->{params};
    $params = [] unless defined $params;
    wantarray ? @$params : $params;
}


sub get_description_for_method {
    my ($self, $method) = @_;
    $self->get_spec_for_method($method)->{description}
}


sub get_summary_for_method {
    my ($self, $method) = @_;
    my $summary = $self->get_spec_for_method($method)->{summary};
    return $summary if defined($summary) && length($summary);

    # if we don't have a summary, lowercase the first sentence - up to the
    # first full stop - of the description

    $summary = lc($self->get_description_for_method($method));
    $summary =~ s/\..*//s;  # remove everything from the first full stop
    $summary;
}


sub get_examples_for_method {
    my ($self, $method) = @_;
    my $examples = $self->get_spec_for_method($method)->{examples};
    $examples = [] unless defined $examples;
    wantarray ? @$examples : $examples;
}


sub get_aliases_for_method {
    my ($self, $method) = @_;
    my $aliases = $self->get_spec_for_method($method)->{aliases};
    $aliases = [] unless defined $aliases;
    wantarray ? @$aliases : $aliases;
}


sub apply_param_aliases_and_defaults {
    my ($self, $method, $opts_ref) = @_;
    for my $param ($self->get_params_for_method($method)) {
        # If the parameter is defined in its standard form, don't care about
        # aliases or defaults.

        next if defined $opts_ref->{ $param->{name} };

        # If the parameter is present in one of its alias forms, copy it to
        # the standard parameter and delete the alias. We take the first
        # aliased form we encounter, in case there are several ones.

        for my $alias (@{ $param->{aliases} || [] }) {
            next unless defined $opts_ref->{$alias};
            $opts_ref->{ $param->{name} } = $opts_ref->{$alias};
            delete $opts_ref->{$alias};
        }

        next unless defined $param->{default};
        $opts_ref->{ $param->{name} } = $param->{default};
    }
}


sub run_method {
    my ($self, $method, %opt) = @_;
    my $result;
    try {
        my $spec = $self->get_spec_for_method($method);
        my $object_type = $spec->{object};
        my $object_method = exists $spec->{method}
            ? $spec->{method}
            : "sif_$method";
        
        $result = $self->delegate->make_obj($object_type)->
            $object_method(%opt);
    } catch Error::Hierarchy with {
        my $E = shift;
        $result = $self->delegate->make_obj('service_result_scalar');
        $result->exception($E);
    };

    $result;
}


# Also allow service methods to be called directly on the service methods
# object:
#
# $svc->foobar(...)
#
# is to be the same as
#
# $svc->run_method('foobar', ...);

sub DEFAULTS { () }
sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    (my $method = our $AUTOLOAD) =~ s/.*://;
    $self->run_method($method, @_);
}


1;


__END__

=head1 NAME

Data::Conveyor::Service::Methods - service method definitions

=head1 SYNOPSIS

   package My::Service::Methods;

   use warnings;
   use strict;

   use base 'Data::Conveyor::Service::Methods';

   sub SERVICE_METHODS {
     domain_tickets => {
         object => 'ticket',
         $_[0]->PARAMS(
             "+domain|d=s  Domain name.",
             "?limit|l=s   Limit number of rows returned.",
         ),
         description => <<EODESC,
 Show tickets for a domain.
 
 This function respects the limit option and shows the most recent tickets for
 the domain.
 
 If the domain name starts with ':', you can use enhanced UTF-8 notation (see
 the eutf2ace command) as well as HTML entities.
 EODESC
 
         examples => [
             { domain => 'foo.at' },
             { domain => 'xn--brse-5qa.at' },
             { domain => ':b\x{F6}rse.at' },
             { domain => ':b&ouml;rse.at' },
         ],
     };
     
     1;


=head1 DESCRIPTION

The service methods and interfaces make it possible to service the machinery
while it is running.

=head1 WRITING A NEW SERVICE METHOD

As seen in the synopsis, you're probably going to have a separate class
derived from Data::Conveyor::Service::Methods which you use to define your
custom service methods in.

In the C<SERVICE_METHODS> hash, which will be collected using
Data::Inherited's C<every_hash()>, you have to write the definition of your
service methods.

You have to specify the method name and the object type - see the environment
classes' C<GENERAL_CLASS_NAME_HASH> for details - on which the method is
called.  You also have to specify the number and types of parameters which the
method takes. You can optionally give a description and examples of usage.

There are some shorthands which make that job easier. If you adhere to certain
naming conventions, it gets easier still.

The example in the synopsis defines a service method called C<domain_tickets>,
which is called on the ticket class, meaning the class implementing the
ticket object type as defined in the environment. Because the method
name is not defined, the method is expected to be called
C<sif_domain_tickets>. If it was called something different, you could specify
the name using the C<method> key within the specification hash.

As you can see from the description, it shows tickets regarding a certain
domain - the service method is intended to be used within a domain registry.
The method takes two paramaeters.

The first one specifies the domain name. It is mandatory, indicated by the
plus sign at the beginning of the parameter specification. For service
interfaces that support parameter name abbreviations (e.g., the shell service
interface), the parameter can be abbreviated to C<d>. The C<=s> tells
us that it takes a string argument.

The second argument is used to limit the number of resulting rows that is
returned by the service method. It too has an abbreviation, C<l>, but it is
optional, as indicated by the question mark at the beginning of the parameter
specification. It too takes a string argument. Actually, only a numeric
argument will make sense, but that's for the service method implementation to
check.

Each service interface - shell and SOAP, for example - will, upon startup, ask
the service methods object for the specifications of all the service methods
it knows. This is, as has been noted, done by combining the output of all the
C<SERVICE_METHODS()> down the class hierarchy. The service interface will
then interpret these specifications according to its own design.

Therefore each service interface is just a wrapper around the service methods.

For example, for the shell service interface, there is a C<help> command
giving details about the service methods. These details are taken directly
from the specification. Parameters given to the service interface call are
also checked against the service method's parameter specifications.

A service interface doesn't have to use all of the information contained in
the specification. For example, the SOAP service interface does not support
parameter name abbreviations, so it doesn't use them.

Let's look at the actual implementation of the service method. To continue the
example given in the synopsis, here is a sample implementation of the
C<domain_tickets> service method:

    sub sif_domain_tickets {
        my ($self, %opt) = @_;
        assert_getopt $opt{domain}, 'Called without domain name.';
        assert_getopt $opt{limit},  'Called without limit.';
        $self->delegate->make_obj('service_result_tabular')->set_from_rows(
            limit  => $limit,
            fields => [ qw/ticket_no stage status ticket_type origin
                           real effective mdate/ ],
            rows   => scalar $self->storage->get_object_tickets(
                normalize_to_ace($opt{domain}), $opt{limit},
            ),
        );
    }

The relevant things here are that the service method gets its arguments in a
hash, first uses C<assert_getopt()> to check the existence of arguments,
then it constructs a tabular service result object which it populates with
the results from a storage call. Each service method gets its
arguments in a hash. Each service method needs to construct a service
result object (tabular or otherwise) in which it has to return the
results. It needs to return this result object - here, the
C<set_from_rows()> call returns the result object.

If anything goes wrong during the the service method call, the method should
throw an exception. The service interface will then act upon the exception
accordingly. For example, the shell service interface will print the
exception's text. C<assert_getopt()> also throws a special exception, if
necessary.

Here is a more detailed explanation of how to specify parameters. The
specification given in the synopsis, repeated here:

    $_[0]->PARAMS(
        "+domain|d=s  Domain name.",
        "?limit|l=s   Limit number of rows returned.",
    ),

is actually equivalent to:

    params => [
        { name        => 'domain',
          short       => 'd',
          type        => $self->delegate->SIP_STRING,
          necessity   => $self->delegate->SIP_MANDATORY,
          description => 'Domain name.',
        },
        { name        => 'limit',
          short       => 'l',
          type        => $self->delegate->SIP_STRING,
          necessity   => $self->delegate->SIP_OPTIONAL,
          description => 'Limit number of rows returned.',
        },
    ],

You can also give set a default value for a parameter using the C<default>
hash key. The short notation used in the synopsis can be defined as:

    <necessity><name>|<short>[=<type>][><default>]

The necessity can be either C<+> (mandatory) or C<?> (optional). 'name' and
'short' are the parameter names. The type can be C<=s> to indicate that the
parameter takes a string value, or empty to indicate a boolean parameter.
'type' and 'default' are optional.

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

