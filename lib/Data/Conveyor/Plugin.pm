use 5.008;
use strict;
use warnings;

package Data::Conveyor::Plugin;
BEGIN {
  $Data::Conveyor::Plugin::VERSION = '1.101690';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# For now, just subclass Hook::Modular::Plugin, but this class is useful if we
# later want to make it a subclass of Class::Scaffold::Storable or something
# as well, without having to rewrite all plugin subclasses.
use parent qw(
  Hook::Modular::Plugin
  Data::Inherited
  Class::Scaffold::Delegate::Mixin
);

sub HOOKS {
    (   'exception.errcode_for_class' =>
          $_[0]->can('exception_errcode_for_class'),
        'exception.rc_for_class' => $_[0]->can('exception_rc_for_class'),
        'exception.status_for_class' =>
          $_[0]->can('exception_status_for_class'),
    );
}

# Accumulate hook handlers across the plugin class hierarchy, so plugin
# subclasses don't need to provide their own register() methods, they can just
# populate HOOKS().
sub register {
    my ($self, $context) = @_;
    $context->register_hook($self, $self->every_hash('HOOKS'),);
}

# If a plugin defines its own exceptions, it also should provide exception
# handler mappings for them. Here we implement hooks that let you use the same
# structures as in Data::Conveyor::Exception::Handler: *_FOR_EXCEPTION_HASH.
# See there for how they are accumulated.
use constant ERRCODE_FOR_EXCEPTION_CLASS_HASH => ();
use constant RC_FOR_EXCEPTION_CLASS_HASH      => ();
use constant STATUS_FOR_EXCEPTION_CLASS_HASH  => ();

sub exception_errcode_for_class {
    my $self = shift;
    scalar $self->every_hash('ERRCODE_FOR_EXCEPTION_CLASS_HASH');
}

sub exception_rc_for_class {
    my $self = shift;
    scalar $self->every_hash('RC_FOR_EXCEPTION_CLASS_HASH');
}

sub exception_status_for_class {
    my $self = shift;
    scalar $self->every_hash('STATUS_FOR_EXCEPTION_CLASS_HASH');
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Plugin - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.101690

=head1 METHODS

=head2 HOOKS

FIXME

=head2 exception_errcode_for_class

FIXME

=head2 exception_rc_for_class

FIXME

=head2 exception_status_for_class

FIXME

=head2 register

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at
L<http://github.com/hanekomu/Data-Conveyor/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

  Marcel Gruenauer <marcel@cpan.org>
  Florian Helmberger <fh@univie.ac.at>
  Achim Adam <ac@univie.ac.at>
  Mark Hofstetter <mh@univie.ac.at>
  Heinz Ekker <ek@univie.ac.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

