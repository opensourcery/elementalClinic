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
my $doctor2  = $f->find_one( rolodex => { lname => 'Clinician' } );
# Order is important -- to exercise #1191, $location's location_id must be
# higher than $location2's
my $location = $f->find_one(
    valid_data_prognote_location => { name => 'Other' },
);
my $location2 = $f->find_one(
    valid_data_prognote_location => { name => 'Client Home' },
);

my $mech = eleMentalClinic::Test::Mechanize->new_with_server;

sub find_appointment {
    my $time = shift;
    my $appt_row = $mech->look_down(
        _tag => 'tr',
        class => "appointment_client_$client->{KEY}",
        sub {
            my $row = shift;
            $row->look_down(
                _tag => 'td',
                sub { $_[0]->as_trimmed_text eq "$time:" }
            ) &&
            $row->look_down(
                _tag => 'a',
                sub { $_[0]->attr('href') =~ /op=appointment_edit/ }
            )
        },
    );
    ok(
        $appt_row,
        "found appointment at $time"
    );
}

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

$mech->submit_form(
    form_number => 1,
    fields => {
        rolodex_id => $doctor->{KEY},
        location_id => $location->{KEY},
        appt_time => '8:00',
        client_id => $client->{KEY},
    },
);

find_appointment('8:00 a');

$mech->submit_form(
    form_number => 1,
    fields => {
        rolodex_id => $doctor2->{KEY},
        location_id => $location->{KEY},
        appt_time => '9:00',
        client_id => $client->{KEY},
    },
);

find_appointment('9:00 a');
find_appointment('8:00 a');

$mech = undef;
sleep 1;
$mech = eleMentalClinic::Test::Mechanize->new_with_server;

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

$mech->submit_form(
    form_number => 1,
    fields => {
        rolodex_id => $doctor->{KEY},
        location_id => $location->{KEY},
        appt_time => '8:00',
        client_id => $client->{KEY},
    },
);

$mech->submit_form(
    form_number => 1,
    fields => {
        rolodex_id => $doctor->{KEY},
        location_id => $location->{KEY},
        appt_time => '9:00',
        client_id => $client->{KEY},
    },
);

$mech->submit_form(
    form_number => 1,
    fields => {
        rolodex_id => $doctor->{KEY},
        location_id => $location2->{KEY},
        appt_time => '10:00',
        client_id => $client->{KEY},
    },
);

find_appointment('10:00 a');
find_appointment('9:00 a');
find_appointment('8:00 a');
