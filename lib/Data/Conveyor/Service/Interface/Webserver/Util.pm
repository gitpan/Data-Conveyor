package Data::Conveyor::Service::Interface::Webserver::Util;

use strict;
use warnings;
use Carp;
use JSON::XS ();
use Encode ();
use overload ();

our $VERSION = '0.06';

use base 'Class::Scaffold::Base';

sub json_decode {
    my ($class, $str, $encode_utf8) = @_;

    $str = Encode::encode_utf8($str) if $encode_utf8;
    JSON::XS::decode_json($str);
}

sub json_encode {
    my ($class, $stuff) = @_;

    local *UNIVERSAL::TO_JSON = sub {
        my $obj = shift;
        if (my $method = overload::Method($obj, q(""))) {
            return $obj->$method();
        } else {
            # Just return an unblessed copy of the object's hash
            return +{ %$obj };
        }
    };

    # for future DBD::SQLite with proper Unicode bug fixes, this
    # SHOULD return decoded string instead of UTF-8 encoded strings
    # (with utf8 option). For now we always use ->ascii, so there's no
    # forward compatiblity problem.
    JSON::XS->new->allow_blessed->convert_blessed->ascii->encode($stuff);
}

1;
