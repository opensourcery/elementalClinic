# vim: ts=4 sts=4 sw=4
use strict;
use warnings;
use Test::More tests => 20;

use eleMentalClinic::Test;
use eleMentalClinic::Test::Mechanize;

my $c = $client->{1001}; # Miles Davis

for (
    [ { admission_program_id => 1002 }, 'Adolescent' ],
    [ { referral_program_id  => 1, intake_type => 'Referral' }, 'Referral' ],
) {
    my ( $fields, $program ) = @$_;

    my $mech = eleMentalClinic::Test::Mechanize->new_with_server;

    $mech->admin_login_ok;
    $mech->get_script_ok( 'placement.cgi', client_id => $c->{client_id} );

    $mech->click_button( value => 'Re-Admit Client' );

    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                level_of_care_id => 1002,
                staff_id => 1,
                %$fields,
            }
        },
    );

    my @episodes = $mech->look_down(
        _tag => 'table', class => 'episode',
    );

    is( @episodes, 2, 'two episodes found' );

    my $event = $episodes[0]->look_down( _tag => 'tr', class => 'active' );

    my @fields = map { $_->as_trimmed_text } $event->look_down( _tag => 'td' );

    is $fields[2], eleMentalClinic::Base::Time->today;
    is $fields[3], $program;
    is $fields[4], 'Root, Root';
    is $fields[5], 'Rehabilitation';
}
