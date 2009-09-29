package Data::Conveyor::Service::Interface::Webserver;

use strict;
use warnings;
use HTTP::Engine;

our $VERSION = '0.07';

use base qw(
    Class::Scaffold::Base
    Data::Conveyor::Service::Interface
);

sub create_engine {
    my ($self, @args) = @_;
    my $handler = $self->delegate->make_obj('sif_http_engine_handler');
    HTTP::Engine->new(
        interface => {
            @args,
            request_handler => sub {
                my $req = shift;
                $handler->handle_request($req);
            }
        }
    )
}

sub run {
    my $self = shift;
    $self->create_engine(@_)->run;
}

1;
