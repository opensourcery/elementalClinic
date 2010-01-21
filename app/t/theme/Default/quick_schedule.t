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

for (qw(rolodex_id location_id schedule_availability_id)) {
    is(
        $mech->look_down(
            class => 'filters',
        )->look_down(
            id => $_,
        ),
        undef,
        "no .filters #$_"
    )
}

for my $hour (8..16) {
    for my $minute (0, 15, 30, 45) {
        my $time = sprintf "%d:%02d", $hour, $minute;
        ok(
            $mech->look_down(
                _tag => 'a',
                sub { shift->attr('href') =~ /appt_time=$time;/ }
            ),
            "link for $time",
        );
    }
}

my %ARGS = (
    rolodex_id => $doctor->{KEY},
    location_id => $location->{KEY},
    appt_time => '8:00',
    client_id => $client->{KEY},
);

use Data::Dumper;
for my $args (
    { location_id => '' },
    { rolodex_id => '' },
) {
    eval {
        $mech->submit_form_ok(
            {
                form_number => 1,
                fields => {
                    %ARGS,
                    %$args,
                },
            },
        );
    };
    is $@, '';
    ok(
        $mech->look_down(_tag => 'div', class => 'errors'),
        'found error div',
    );
    ok(
        ! $mech->look_down(
            _tag => 'tr',
            class => "appointment_client_$client->{KEY}",
        ),
        "no appointment made: " . Dumper($args)
    );
}

$mech->submit_form_ok(
    {
        form_number => 1,
        fields => \%ARGS,
    }
);

my $logged_in = 1;
{
    my $appt_row = $mech->look_down(
        _tag => 'tr',
        class => "appointment_client_$client->{KEY}",
    );

    ok( $appt_row, 'found appointment row' );

    if ($logged_in) {
        $logged_in = 0;
        $mech->logout_ok;
        $mech->admin_login_ok;
        $mech->get_script_ok(
            'demographics.cgi',
            client_id => $client->{KEY},
        );
        $mech->follow_link_ok( { text => 'Schedule' } );
        redo;
    }
}

# test for #1180

$mech->get_script_ok( 'schedule.cgi', withclient => 'no' );
$mech->submit_form_ok(
    {
        form_number => 1,
        fields => {
            %ARGS,
            appt_time => '8:15',
        },
    },
);
ok(
    !$mech->look_down(id => 'client_head'),
    'no client header after editing with no client chosen',
);

$mech->get_script_ok( 'schedule.cgi',
    withclient => 'yes', client_id => $client->{KEY},
);

$mech->submit_form_ok(
    {
        form_number => 1,
        fields => {
            %ARGS,
            appt_time => '8:00',
            client_id => 1001,
        },
    },
);
ok(
    $mech->look_down(id => 'client_head'),
    'found client header after editing with client chosen',
);
