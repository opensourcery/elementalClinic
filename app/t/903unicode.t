# vim: ts=4 sts=4 sw=4
use strict;
use warnings;
use Test::More 'no_plan';

use eleMentalClinic::Test;
use eleMentalClinic::Test::Mechanize;
use HTML::Entities qw(encode_entities);
use Encode;
use encoding 'utf-8';

my $c = $client->{1001}; # Miles Davis

# this is just some random non-Latin-1 \w character
my $str = "I Ӂ U";

my $mech = eleMentalClinic::Test::Mechanize->new_with_server;

$mech->admin_login_ok;
$mech->get_script_ok( 'intake.cgi', op => 'step1' );

$mech->submit_form_ok(
    {
        form_number => 1,
        fields => {
            fname => $str,
            lname => "there",
            sex   => "Male",
            ssn   => "123-45-6789",
            dob   => "1970-01-01",
        },
    },
    'intake step 1',
);

TODO: {
    # This test never appears to have worked
    local $TODO = "Unicode fields are broken";

    $mech->content_unlike(qr/only words are allowed/i);
    # HTML-encoded UTF-8 encoded is wrong
    $mech->content_lacks(encode_entities(encode("utf-8", $str)));
}

$mech->get_script_ok(
    'demographics.cgi',
    client_id => $c->{client_id},
    op        => 'edit'
);
$mech->submit_form_ok(
    {
        form_number => 1,
        fields => {
            fname => $str, #decode("utf-8" => $str),
        },
        button => 'op',
    },
    'edit existing client',
);

TODO: {
    my $reason = "Unicode fields are broken";
    local $TODO = $reason;

    $mech->content_contains(encode("utf-8", $str));

    $TODO = '';
    $mech->get_script_ok(
        'demographics.cgi',
        client_id => $c->{client_id},
    );

    $TODO = $reason;
    $mech->content_contains(encode("utf-8", $str));
}
