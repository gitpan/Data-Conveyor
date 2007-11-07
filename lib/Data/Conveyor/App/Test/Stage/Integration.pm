package Data::Conveyor::App::Test::Stage::Integration;

# $Id: Integration.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;
use Test::More;
use Test::Builder;


our $VERSION = '0.01';


use base 'Data::Conveyor::App::Test::Stage';


__PACKAGE__
    ->mk_scalar_accessors(qw(dispatcher next_open_stage failed_tests))
    ->mk_array_accessors(qw(expect_list));


use constant runs => 1;


sub plan_test {
    my ($self, $test, $run) = @_;

    # For integration tests, the expect block consists of several more expect
    # blocks, which are checked while the ticket is processed repeatedly by
    # the test dispatcher.

    # There's at least one test (we do expect at least an expected stage in
    # each expect sub-block).

    my $plan = 0;
    for (grep { !exists $_->{initial_stage} } @{ $test->{expect} || [] }) {
        # plan_ticket_* needs a hash with an 'expect' key
        my $subexpect = { expect => $_ };
        $plan +=
            $self->plan_ticket_expected_container($subexpect, $run) +
            $self->plan_ticket_tx($subexpect) +
            1;      # stage
    }

    $plan;
}


sub run_test {
    my $self = shift;

    # We can create the dispatcher only here, not in init(), because there's
    # not storage yet in init(). The storage is created only in the
    # superclass's run() method, during Class::Scaffold::App::app_code(). But
    # to simulate realistic conditions, we only create the dispatcher object
    # once, i.e. it's expected to handle many requests.

    $self->dispatcher($self->delegate->make_obj('ticket_dispatcher_test')->new(
        # storage  => $self->storage,
        callback => $self)
    ) unless defined $self->dispatcher;

    # For integration tests, the expect block should be an array reference,
    # where each element contains the expect block that we check the ticket
    # against during each phase of the ticket's life cycle. The check_*
    # methods in Data::Conveyor::App::Test::Stage (e.g.,
    # check_ticket_rc_status()) need to have that single expect block in the
    # expect() accessor, however. So we remember the list of expect blocks in
    # another accessor, expect_list(). See check_dispatched_ticket() for the
    # rest of the story.

    $self->expect_list(@{ $self->expect });

    # Get the first expect element; it should contain the initial stage. We
    # need it so we can open() the ticket. Later, after_ticket_finished() will
    # update the value so that we always know which stage to open the ticket
    # in.

    $self->next_open_stage(
        $self->delegate->make_obj('value_ticket_stage')->new(value =>
            $self->expect_list_shift->{initial_stage})->name
    );

    # Repeatedly call the dispatcher until we don't have any more expect
    # blocks or until a test failed within this run.

    while ($self->expect_list_count && !$self->failed_tests) {
        $self->run_stage_test;
    }
}


sub run_stage_test {
    my $self = shift;

    my $ticket = $self->delegate->make_obj('ticket', 
        ticket_no => $self->ticket_no,
    );
    $ticket->open($self->next_open_stage);

    $self->dispatcher->dispatch($ticket);

    # Did any tests already fail within this run? If we have a lot of
    # tests, the grep for tests starting with the current test name could
    # be expensive, so first grep for tests that are not ok - should weed
    # out a lot.

    my $testname = $self->testname;
    $self->failed_tests(
        grep { substr($_->{name}, 0, length($testname)) eq $testname }
        grep { !$_->{ok} }
        Test::Builder->new->details
    );
}


sub check_ticket_stage {
    my $self = shift;
    is($self->ticket->stage, $self->expect->{stage},
        $self->named_test(sprintf 'stage %s', $self->expect->{stage}));
}


sub check_dispatched_ticket {
    my $self = shift;

    # Get the next expect block from the expect block list and set it on the
    # expect() accessor so that the check_* methods that follow will know what
    # to check against.

    # Stop when we don't have any more expect blocks

    my $expect = $self->expect_list_shift;
    return unless defined $expect;

    $self->expect($expect);

    # Get the ticket from the dispatcher (it's a new object every time around)
    # and set it on our ticket() accessor so that the check_* methods that
    # follow can do their work. Also set the stage object, needed by
    # check_ticket_expected_container().

    $self->ticket($self->dispatcher->ticket);
    $self->stage($self->dispatcher->stage);

    $self->check_ticket_stage;
    $self->check_ticket_expected_container;
    $self->check_ticket_tx;
}


# Callback methods from test ticket dispatcher; callback was set up
# in this object's init() method.

sub after_ticket_closed {
    my $self = shift;
    print "# ticket closed\n";
    $self->check_dispatched_ticket;
}


sub after_ticket_finished {
    my $self = shift;
    print "# ticket finished\n";
    $self->check_dispatched_ticket;

    # Remember the stage the ticket should be opened in during the next
    # dispatcher run.

    $self->next_open_stage(
        $self->delegate->make_obj('value_ticket_stage')->new(
            value => $self->expect->{stage}
        )->name
    );
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
