# vim: ts=4 sts=4 sw=4

use strict;
use warnings;
use Test::More 'no_plan';

use eleMentalClinic::Test;
use eleMentalClinic::Test::Mechanize;

my $c = $client->{1001};
my $pl = eleMentalClinic::Fixtures::load_fixture(
    'fixtures/base-sys/valid_data_prognote_location.yaml'
)->{1};

my $mech = eleMentalClinic::Test::Mechanize->new_with_server;

$mech->admin_login_ok;
$mech->get_script_ok( 'valid_data.cgi',
    table_name => 'valid_data_prognote_location',
);

$mech->follow_link_ok(
    { text => $pl->{name} },
    "load $pl->{name} location",
);

$mech->submit_form_ok(
    {
        form_name => 'edit_item_form',
        fields => {
            name => "New Name",
        },
    },
    "change location name",
);

$mech->get_script_ok(
    'progress_notes.cgi',
    client_id => $c->{client_id},
);

for my $div ( $mech->look_down(_tag => 'div', class => 'old_note') ) {
    my $location = ($div->look_down(_tag => 'p'))[1]
        ->look_down(_tag => 'strong')->as_trimmed_text;
    is( $location, $pl->{name}, "progress note location name is unchanged" );
}
