package Data::Conveyor::App::Webserver;

use warnings;
use strict;
use Error ':try';

our $VERSION = '0.09';

use base 'Class::Scaffold::App::CommandLine';

use constant GETOPT => qw(
    engine_type|e=s
    storage_setup
    sif_web_host=s
    sif_web_port=s
    sif_web_access_log=s
    sif_web_error_log=s
    sif_web_debug
);

sub app_code {
    my $self = shift;
    $self->SUPER::app_code(@_);
    $self->delegate->core_storage->test_setup if $self->opt('storage_setup');
    my $engine_type = lc $self->opt('engine_type') || 'serversimple';
    try {
        $self->delegate->make_obj("sif_http_engine_${engine_type}")->run;
    } catch Error with {
        my $E = shift;
        die $E;
        # XXX
    };
}

1;
