package Data::Conveyor::Test;

use strict;
use warnings;
use Test::More;
use Error::Hierarchy::Util 'load_class';


our $VERSION = '0.01';


use base 'Class::Scaffold::Test';


# e.g., stage_basics_ok($self->delegate, ST_POLICY => 1);

sub stage_basics_ok {
    my ($self, $stage_type_const, $will_shift_ticket, %stage_args) = @_;
    my $stage_type = $self->delegate->$stage_type_const;
    my $stage = $self->delegate->make_stage_object($stage_type, %stage_args);
    is($stage->expected_stage, $stage_type,
        "expected stage type [$stage_type]");
    is($stage->will_shift_ticket, $will_shift_ticket,
        "$stage_type ticket shift setting");
}


sub transition_ok {
    my ($self, $test_storage, $stage, $rc, $next_stage) = @_;
    $test_storage->transition_ok_bare(
        $test_storage,
        $test_storage->delegate->make_obj('value_ticket_stage')->
            new_end($stage),
        $rc,
        $test_storage->delegate->make_obj('value_ticket_stage')->
            new_start($next_stage),
    );
}


sub transition_ok_bare {
    my ($self, $test_storage, $stage, $rc, $next_stage) = @_;
    is($test_storage->get_next_stage($stage, $rc), $next_stage,
        sprintf('%s + %s = %s', $stage, $rc, $next_stage));
}


sub factory_gen_template_handler_ok {
    my ($self, $factory, $gen_method, $hash_name) = @_;
    my %hash_spec = $factory->every_hash($hash_name);
    while (my ($ticket_type, $class) = each %hash_spec) {
        next if $ticket_type eq '_AUTO';
        isa_ok($factory->$gen_method(ticket =>
            $factory->delegate->make_obj('ticket', type => $ticket_type),
        ), $class);
    }
}


sub factory_gen_txsel_handler_iterate {
    my ($self, $factory, $gen_method, $spec, $value) = @_;
    if (ref $value eq 'HASH') {
        while (my ($deeper_spec, $deeper_value) = each %$value) {
            next if $deeper_spec eq '_AUTO';
            $self->factory_gen_txsel_handler_iterate($factory, $gen_method,
                [ @$spec, $deeper_spec ], $deeper_value);
        }
    } else {
        # expect it to be a scalar, i.e. a leaf, so call the generator method
        isa_ok($factory->$gen_method(@$spec), $value);
    }
}


sub factory_gen_txsel_handler_ok {
    my ($self, $factory, $gen_method, $hash_name) = @_;
    my %hash_spec = $factory->every_hash($hash_name);
    $self->factory_gen_txsel_handler_iterate(
        $factory, $gen_method, [], \%hash_spec);
}


sub factory_gen_transaction_handler_ok {
    my ($self, $factory, $gen_method, $hash_name) = @_;
    my %hash_spec = $factory->every_hash($hash_name);
    while (my ($object_type, $ot_spec) = each %hash_spec) {
        next if $object_type eq '_AUTO';
        while (my ($command, $class) = each %$ot_spec) {
            next if $command eq '_AUTO';
            my $tx = $factory->delegate->make_obj('transaction', 
                object_type => $object_type,
                command     => $command,
            );
            my $payload_tx = $factory->delegate->
                make_obj('payload_transaction', transaction => $tx);
            isa_ok($factory->$gen_method(tx => $payload_tx), $class);
        }
    }
}


sub apply_rc_ok {
    my ($self, $from, $via, $to, $should_ask_delegate) = @_;

    if ($should_ask_delegate) {
        $_ = $self->delegate->$_ for $from, $via, $to;
    }

    $_ = $self->delegate->make_obj('value_ticket_rc', value => $_)
        for $from, $via, $to;
    is($from + $via, $to,
        sprintf("apply_rc: %s x %s = %s", $from, $via, $to));
}


sub apply_status_ok {
    my ($self, $from, $via, $to, $should_ask_delegate) = @_;

    if ($should_ask_delegate) {
        $_ = $self->delegate->$_ for $from, $via, $to;
    }

    $_ = $self->delegate->make_obj('value_ticket_status', value => $_)
        for $from, $via, $to;
    is($from + $via, $to,
        sprintf("apply_status: %s x %s = %s", $from, $via, $to));
}


sub object_limit_ok {
    my ($self, $ticket_type_const, $object_type_const, $expected) = @_;
    my $ticket_type = $self->delegate->$ticket_type_const;
    my $object_type = $self->delegate->$object_type_const;
    is($self->delegate->get_object_limit($ticket_type, $object_type),
       $expected,
       sprintf '%s, %s -> %s', $ticket_type, $object_type, $expected);
}


sub rc_for_exception_class_ok {
    my ($self, $handler, $exception_class, $payload_item_type,
        $command_name, $rc_name) = @_;

    # The exception class needs to be loaded so class_map() can determine its
    # superclasses.

    load_class $exception_class, 0;
    my $payload_item = $self->delegate->make_obj(
        $payload_item_type,
        command => $self->delegate->$command_name);

    my $rc = $handler->rc_for_exception_class(
        $exception_class, $payload_item);
    is($rc, $self->delegate->$rc_name,
        sprintf 'type [%s], command [%s]: exception [%s] => rc [%s]',
            $payload_item_type, $command_name, $exception_class, $rc_name);
}


1;


__END__

=head1 NAME

Data::Conveyor - stage-based conveyor-belt-like ticket handling system

=head1 SYNOPSIS

None yet (see below).

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

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

