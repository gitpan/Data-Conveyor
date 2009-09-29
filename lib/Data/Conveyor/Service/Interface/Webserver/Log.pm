package Data::Conveyor::Service::Interface::Webserver::Log;

use strict;
use warnings;
use Log::Dispatch;
use Log::Dispatch::File;
use Log::Dispatch::Screen;

our $VERSION = '0.07';

use base 'Class::Scaffold::Base';

my ($logger, $access_logger);

my %alias = (warn => 'warning');

sub init {
    my $self = shift;
    return if $logger;
    if (my $spec = $self->delegate->sif_web_error_log) {
        $logger = Log::Dispatch->new;
        if ($spec eq '-') {
            $logger->add( Log::Dispatch::Screen->new(
                name => 'error_log',
                min_level =>
                    ($self->delegate->sif_web_debug ? 'debug' : 'warning'),
                stderr => 1,
            ));
        } else {
            $logger->add( Log::Dispatch::File->new(
                name => 'error_log',
                min_level =>
                    ($self->delegate->sif_web_debug ? 'debug' : 'warning'),
                filename  => $spec,
                mode => 'append',
            ));
        }
    }

    if (my $spec = $self->delegate->sif_web_access_log) {
        $access_logger = Log::Dispatch->new;
        if ($spec eq '-') {
            $access_logger->add( Log::Dispatch::Screen->new(
                name => 'access_log',
                min_level =>
                    ($self->delegate->sif_web_debug ? 'debug' : 'warning'),
                stderr => 1,
            ));
        } else {
            $access_logger->add( Log::Dispatch::File->new(
                name => 'access_log',
                min_level => 'info',
                filename  => $spec,
                mode => 'append',
            ));
        }
    }
}

sub log {
    my($class, $level, @msg) = @_;

    my $msg = join(" ", @msg);
    chomp $msg;

    if ($logger) {
        $logger->log( level => $alias{$level} || $level, message => "$msg\n" );
    } else {
        Carp::carp($msg);
    }
}

sub log_request {
    my($class, $req, $res) = @_;

    $access_logger->log(
        level => 'info',
        message => sprintf qq(%s - %s [%s] "%s %s %s" %s %s "%s" "%s"\n),
            $req->address, ($req->user || '-'), scalar localtime, $req->method,
            $req->uri->path_query, $req->protocol, $res->status, ($res->body ? bytes::length($res->body) : "-"),
            ($req->referer || '-'), ($req->user_agent || '-'),
    );
}

for my $level ( qw(debug info notice warn warning error critical alert emergency) ) {
    no strict 'refs';
    *$level = sub {
        my $class = shift;
        $class->log( $level => @_ );
    };
}

1;
