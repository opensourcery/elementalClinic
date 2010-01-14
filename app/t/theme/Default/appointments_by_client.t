# vim: ts=4 sts=4 sw=4
use strict;
use warnings;
use Test::More 'no_plan';
use eleMentalClinic::Test::Mechanize;
use eleMentalClinic::TestCase;
use eleMentalClinic::Schedule;

my $f = eleMentalClinic::TestCase->fixture;

my $client   = $f->find_one( client => { lname => 'Fitzgerald' } );
my $doctor   = $f->find_one( rolodex => { lname => 'Batts' } );
my $location = $f->find_one(
    valid_data_prognote_location => { name => 'Client Home' },
);

my $mech = eleMentalClinic::Test::Mechanize->new_with_server;

$mech->admin_login_ok;
$mech->set_configuration(
    { quick_schedule_availability => 'on' },
);

$mech->get_script_ok(
    'schedule.cgi', (
        client_id => $client->{KEY},
        withclient => 'yes',
        navsec => 'schedule',
    ),
);

$mech->follow_link_ok({ text => 'Overview' });

my @rows = $mech
    ->look_down( id => 'appointment_table' )
    ->look_down( _tag => 'tr' );
is(
    scalar @rows, 2,
    'found two appointments',
);
