package Data::Conveyor::Service::Interface::Webserver::ServerSimple;

use strict;
use warnings;

our $VERSION = '0.07';

use base 'Data::Conveyor::Service::Interface::Webserver';

sub create_engine {
    my $self = shift;

    my $host = $self->delegate->sif_web_host || 'localhost';
    my $port = $self->delegate->sif_web_port || '10090';

    $self->SUPER::create_engine(
        module => 'ServerSimple',
        args      => {
            host => $host,
            port => $port,
        },
    );
}

1;
