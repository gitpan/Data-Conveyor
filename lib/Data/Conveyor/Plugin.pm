package Data::Conveyor::Plugin;

use strict;
use warnings;


our $VERSION = '0.11';


# For now, just subclass Hook::Modular::Plugin, but this class is useful if we
# later want to make it a subclass of Class::Scaffold::Storable or something
# as well, without having to rewrite all plugin subclasses.

use base qw(
    Hook::Modular::Plugin
    Data::Inherited
    Class::Scaffold::Delegate::Mixin
);


sub HOOKS {
    (
        'exception.errcode_for_class' =>
            $_[0]->can('exception_errcode_for_class'),
        'exception.rc_for_class' =>
            $_[0]->can('exception_rc_for_class'),
        'exception.status_for_class' =>
            $_[0]->can('exception_status_for_class'),
    );
}


# Accumulate hook handlers across the plugin class hierarchy, so plugin
# subclasses don't need to provide their own register() methods, they can just
# populate HOOKS().

sub register {
    my ($self, $context) = @_;

    $context->register_hook(
        $self,
        $self->every_hash('HOOKS'),
    );
}


# If a plugin defines its own exceptions, it also should provide exception
# handler mappings for them. Here we implement hooks that let you use the same
# structures as in Data::Conveyor::Exception::Handler: *_FOR_EXCEPTION_HASH.
# See there for how they are accumulated.


use constant ERRCODE_FOR_EXCEPTION_CLASS_HASH => ();
use constant RC_FOR_EXCEPTION_CLASS_HASH      => ();
use constant STATUS_FOR_EXCEPTION_CLASS_HASH  => ();


sub exception_errcode_for_class {
    my ($self, $context, $args) = @_;
    scalar $self->every_hash('ERRCODE_FOR_EXCEPTION_CLASS_HASH');
}


sub exception_rc_for_class {
    my ($self, $context, $args) = @_;
    scalar $self->every_hash('RC_FOR_EXCEPTION_CLASS_HASH');
}


sub exception_status_for_class {
    my ($self, $context, $args) = @_;
    scalar $self->every_hash('STATUS_FOR_EXCEPTION_CLASS_HASH');
}


1;


__END__

=head1 NAME

Data::Conveyor::Plugin - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

    Data::Conveyor::Plugin->new;

=head1 DESCRIPTION

Data-Conveyor supports plugins. The concept of a plugin, much like an aspect
in aspect-oriented programming, is orthogonal to object-oriented programming.
That is, objects have a vertical class hierarchy while plugins are more
horizontal because their functionality cuts across the application's concerns.

First of all, plugins are optional. You don't have to use them, and if you
want to add plugins to your application, you can do so step by step without
having to rewrite large parts of your application.

L<Data::Conveyor::Plugin> uses L<Hook::Modular> to implement the plugin
mechanism, so see the L<Hook::Modular> documentation for an explanation of how
this works.

Your plugins should subclass L<Data::Conveyor::Plugin>. You can declare hooks
by implementing a C<HOOKS()> method returning a hash of hook-to-coderef
mappings. The results of C<HOOKS()> are accumulated across the plugin class
hierarchy using L<Data::Inherited>'s C<every_hash()>.

For example:

    sub HOOKS {
        (
            'some.hook'    => $_[0]->can('some_hook_method'),
            'another.hook' => $_[0]->can('another_hook_method'),
        );
    }

The Data-Conveyor distribution provides the following hooks:

=over 4

=item <stage>.start

This hook is run by C<Data::Conveyor::Stage::TransactionIterator> before
actually iterating over the transactions. C<< <stage> >> is replaced by the
stage name, that is, the stage object's associated C<ST> constant as defined
in the environment. For example, you might have C<policy.start>,
C<notify.start> etc.

Named arguments passed to the hook:

=over 4

=item C<stage>

The stage object.

=back

=item <stage>.end

This hook is run by C<Data::Conveyor::Stage::TransactionIterator> after
iterating over the transactions. C<< <stage> >> is replaced by the stage name,
that is, the stage object's associated C<ST> constant as defined in
the environment. For example, you might have C<policy.end>,
C<notify.end> etc.

Named arguments passed to the hook:

=over 4

=item C<stage>

The stage object.

=back

=item <stage>.<object-type>.<command>

This hook is run by C<Data::Conveyor::Stage::TransactionIterator> for each
transaction. C<< <stage> >> is replaced by the stage name, that is, the stage
object's associated C<ST> constant as defined in the environment. C<<
<object-type> >> is replaced by the transaction's object type as defined by
the environment's C<OT> constants. C<< <command> >> is replaced with the
transaction's command. For example, you might have
C<policy.delegation_domain.create>.

Named arguments passed to the hook:

=over 4

=item C<transaction_handler>

The transaction handler object. It has the current transaction and the current
ticket as attributes.

=item C<stage>

The stage object.

=back

=item C<exception.errcode_for_class>

This hook is run by C<Data::Conveyor::Exception::Handler> when determining the
appropriate error code for an exception. Not only are the
C<ERRCODE_FOR_EXCEPTION_CLASS_HASH> definitions traversed across the class
hierarchy, but plugins are also given the chance to define their mappings. The
hook is expected to return a hashref of class-to-error-code mappings that is
then merged with the results gathered from
C<ERRCODE_FOR_EXCEPTION_CLASS_HASH>.

However, C<Data::Conveyor::Plugin> defines this hook itself so that you can
use the familiar C<ERRCODE_FOR_EXCEPTION_CLASS_HASH> mechanism in your
plugins.

=item C<exception.rc_for_class>

Like C<exception.errcode_for_class>, but applies to
C<RC_FOR_EXCEPTION_CLASS_HASH> and return code determination, respectively.

=item C<exception.status_for_class>

Like C<exception.errcode_for_class>, but applies to
C<STATUS_FOR_EXCEPTION_CLASS_HASH> and status determination, respectively.

=back

=head1 METHODS

=over 4



=back

Data::Conveyor::Plugin inherits from L<Hook::Modular::Plugin>,
L<Data::Inherited>, and L<Class::Scaffold::Delegate::Mixin>.

The superclass L<Hook::Modular::Plugin> defines these methods and
functions:

    new(), assets_dir(), class_id(), conf(), decrypt_config(),
    dispatch_rule_on(), do_walk(), init(), load_assets(), log(),
    plugin_id(), rule(), walk_config_encryption()

The superclass L<Class::Accessor::Fast> defines these methods and
functions:

    make_accessor(), make_ro_accessor(), make_wo_accessor()

The superclass L<Class::Accessor> defines these methods and functions:

    _carp(), _croak(), _mk_accessors(), accessor_name_for(),
    best_practice_accessor_name_for(), best_practice_mutator_name_for(),
    follow_best_practice(), get(), mk_accessors(), mk_ro_accessors(),
    mk_wo_accessors(), mutator_name_for(), set()

The superclass L<Data::Inherited> defines these methods and functions:

    every_hash(), every_list(), flush_every_cache_by_key()

The superclass L<Class::Scaffold::Delegate::Mixin> defines these methods
and functions:

    delegate()

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

