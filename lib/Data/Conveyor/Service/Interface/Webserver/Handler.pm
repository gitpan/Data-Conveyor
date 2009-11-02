package Data::Conveyor::Service::Interface::Webserver::Handler;

use strict;
use warnings;
use attributes ();
use HTTP::Engine::Response;
use MIME::Types;
use Path::Class::Unicode;
use String::CamelCase;
use HTTP::Date;
use URI::Escape;
use HTTP::Engine::FirePHP;

our $VERSION = '0.08';

use base 'Class::Scaffold::Base';

use constant default_root => '/static/html/index.html';

sub handle_request {
    my ($self, $req) = @_;

    my $path = $req->path;

    my $res = HTTP::Engine::Response->new;
    $path = $self->default_root($req) if $path eq "/";

    eval {
        if ($path =~ s!^/rpc/!!) {
            $self->dispatch_rpc($path, $req, $res);
        } elsif ($path =~ s!^/static/!!) {
            $self->serve_static_file($path, $req, $res);
        } else {
            die "Not found";
        }
    };

    if ($@ && $@ =~ /Not found/) {
        $res->status(404);
        $res->body("404 Not Found");
    } elsif ($@ && $@ =~ /Forbidden/) {
        $res->status(403);
        $res->body("403 Forbidden");
    } elsif ($@) {
        $res->status(500);
        $res->body("Internal Server Error: $@");
        $self->delegate->make_obj('sif_http_engine_log')->log(error => $@);
    }
    $self->delegate->make_obj('sif_http_engine_log')->log_request($req, $res);

    $res;
}

sub dispatch_rpc {
    my($self, $method, $req, $res) = @_;

    die "Access to non-public methods" if $method =~ /^_/;
    $res->fire_php->log("rpc method [$method]");

    my $rpc = $self->delegate->make_obj('sif_http_engine_rpc');
    my $result;
    eval {
        my $code = $rpc->can($method) or die "Not found";
        my @attr = attributes::get($code);
        if ( grep $_ eq 'POST', @attr ) {
            die "Request should be POST and have X-Registry-Client header"
                unless $req->method eq 'POST' && $req->header('X-Registry-Client');
        }
        $result = $rpc->$method($req, $res);
    };

    if ($@) {
        warn "Error during RPC call [$method]:\n$@\n";
        $result->{error} = $@;
    } else {
        $result->{success} = 1 unless defined $result->{success};
    }

    unless ($res->body) {
        $res->status(200);
        $res->content_type("application/json; charset=utf-8");
        $res->body($self->delegate->make_obj('sif_http_engine_util')
            ->json_encode($result)
        );
        $self->delegate->make_obj('sif_http_engine_log')
            ->log(debug => $res->body);
    }
}

sub serve_static_file {
    my($self, $path, $req, $res) = @_;

    my $root = $self->delegate->sif_web_root;
    my $file = ufile($root, "static", $path);

    $self->do_serve_static($file, $req, $res);
}

sub do_serve_static {
    my($self, $file, $req, $res) = @_;

    my $exists      = -e $file;
    my $is_dir      = -d _;
    my $is_readable = -r _;

    if ($exists) {
        if ($is_dir || !$is_readable) {
            die "Forbidden";
        }
        my $size  = -s _;
        my $mtime = (stat(_))[9];
        my $ext = ($file =~ /\.(\w+)$/)[0];
        $res->content_type(
            MIME::Types->new->mimeTypeOf($ext) || 'text/plain'
        );

        if (my $ims = $req->headers->header('If-Modified-Since')) {
            my $time = HTTP::Date::str2time($ims);
            if ($mtime <= $time) {
                $res->status(304);
                return;
            }
        }

        open my $fh, "<:raw", $file or die "$file: $!";
        $res->headers->header('Last-Modified' => HTTP::Date::time2str($mtime));
        $res->headers->header('Content-Length' => $size);
        $res->body( join '', <$fh> );
    } else {
        die "Not found";
    }
}

1;
