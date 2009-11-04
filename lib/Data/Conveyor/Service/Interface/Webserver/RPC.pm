package Data::Conveyor::Service::Interface::Webserver::RPC;

use strict;
use warnings;

our $VERSION = '0.09';

use base 'Class::Scaffold::Base';

my $attr_cache = {};

sub MODIFY_CODE_ATTRIBUTES {
    my($class, $code, @attr) = @_;
    $attr_cache->{$class}{$code} = \@attr;
    return ();
}

sub FETCH_CODE_ATTRIBUTES {
    my($class, $code) = @_;
    @{ $attr_cache->{$class}{$code} || [] };
}

sub methods_show {
    my($self, $req, $res) = @_;
    my $svc = $self->delegate->make_obj('service_methods');
    return { methods => [
        map {
            +{
                name        => $self->method_name_for_display($_),
                description => $svc->get_description_for_method($_)
            },
        }
        sort $svc->get_method_names
    ] };
}

sub method_name_for_display {
    my ($self, $name) = @_;
    $name =~ s/_/ /g;
    $name;
}

sub registrar_show : POST {
    my ($self, $req, $res) = @_;
    my $id = $req->param('id') or die "Missing param 'id'";
    my $registrar = $self->delegate->make_obj('registrar', protocol_id => $id);
    $registrar->read;
    $registrar;
}

sub person_show : POST {
    my ($self, $req, $res) = @_;
    my $handle = $req->param('handle') or die "Missing param 'handle'";
    my $person = $self->delegate->make_obj('person', handle => $handle);
    $person->read;
    $person;
}

1;
