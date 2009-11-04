package Data::Conveyor::Service::Interface::Webserver::Test;

use strict;
use warnings;

our $VERSION = '0.09';

use base 'Data::Conveyor::Service::Interface::Webserver';

sub create_engine {
    my $self = shift;
    $self->SUPER::create_engine(
        module => 'Test',
    );
}

1;
