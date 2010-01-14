# vim: ts=4 sts=4 sw=4
use strict;
use warnings;
use Test::More 'no_plan';

use eleMentalClinic::Test;
use eleMentalClinic::Test::Mechanize;

my $c = $client->{1001}; # Miles Davis

my $mech = eleMentalClinic::Test::Mechanize->new_with_server;

$mech->admin_login_ok;
$mech->get_script_ok( 'allergies.cgi', ( client_id => $c->{client_id} ) );

$mech->submit_form_ok(
    {
        form_number => 1,
        fields => {
            allergy => 'donuts',
        },
    },
    'save new allergy',
);

sub find_allergy_ok {
    my ( $name ) = @_;
    my ($ul) = $mech->look_down(id => 'right')->look_down(_tag => 'ul');
    ok(
        $ul->look_down(_tag => 'a', sub {
            shift->as_trimmed_text eq $name
        }),
        "found active allergy: $name",
    );
}

find_allergy_ok( 'donuts' );

$mech->follow_link_ok({ text => 'donuts' });
$mech->submit_form_ok(
    {
        form_number => 1,
        fields => {
            allergy => 'jelly donuts',
        },
    },
    'edit existing allergy',
);

find_allergy_ok( 'jelly donuts' );
