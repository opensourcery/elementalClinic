# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 69;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Schedule::Availability';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->insert_data;
        
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'schedule_availability');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id rolodex_id location_id date
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# appointment_count
    can_ok( $one, 'appointment_count' );
    is( $one->appointment_count, undef );
        
        $one->rec_id( 1001 )->retrieve;
    is( $one->appointment_count, 3);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# joins
    can_ok( $one, 'rolodex' );
        $one = $CLASS->new;
    is( $one->rolodex, undef );

        $one->rec_id( 1001 )->retrieve;
    isa_ok( $one->rolodex, 'eleMentalClinic::Rolodex' );
    is_deeply( $one->rolodex, $rolodex->{ $one->rolodex_id });

        $one = $CLASS->new;

    can_ok( $one, 'location' );
    is( $one->location, undef);
        $one->rec_id( 1001 )->retrieve;
    is( $one->location, 'Client Home');

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Schedule
        $one = $CLASS->new;
    can_ok($one, 'Schedule');

    is( $one->Schedule,  undef );
    
        $one->rec_id( 1001 )->retrieve;

    isa_ok( $one->Schedule,  'eleMentalClinic::Schedule');
    is_deeply( $one->Schedule, {
                 'location_id' => '1001',
                 'month' => '06',
                 'rolodex_id' => '1011',
                 'year' => '2006'
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_appointment_slots_filled
     can_ok( $one, 'get_appointment_slots_tallied' );

        $one = $CLASS->new;
    is( $one->get_appointment_slots_tallied, undef);

        $one = $CLASS->new({ rec_id => 1002 });
    # schedule availability must be defined
    is( $one->get_appointment_slots_tallied, undef );

        $one = $CLASS->new({ rec_id => 1001 })->retrieve;
    is_deeply( $one->get_appointment_slots_tallied, [
        { appt_time => '8:00', count => 0 },
		{ appt_time => '8:15', count => 0 },
		{ appt_time => '8:30', count => 0 },
		{ appt_time => '8:45', count => 0 },
        { appt_time => '9:00', count => 2 },
		{ appt_time => '9:15', count => 0 },
		{ appt_time => '9:30', count => 0 },
		{ appt_time => '9:45', count => 0 },
        { appt_time => '10:00', count => 0 },
		{ appt_time => '10:15', count => 0 },
		{ appt_time => '10:30', count => 0 },
		{ appt_time => '10:45', count => 0 },
        { appt_time => '11:00', count => 0 },
		{ appt_time => '11:15', count => 0 },
		{ appt_time => '11:30', count => 0 },
		{ appt_time => '11:45', count => 0 },
        { appt_time => '12:00', count => 0 },
		{ appt_time => '12:15', count => 0 },
		{ appt_time => '12:30', count => 0 },
		{ appt_time => '12:45', count => 0 },
        { appt_time => '13:00', count => 0 },
		{ appt_time => '13:15', count => 0 },
		{ appt_time => '13:30', count => 0 },
		{ appt_time => '13:45', count => 0 },
        { appt_time => '14:00', count => 0 },
		{ appt_time => '14:15', count => 0 },
		{ appt_time => '14:30', count => 0 },
		{ appt_time => '14:45', count => 0 },
        { appt_time => '15:00', count => 1 },
		{ appt_time => '15:15', count => 0 },
		{ appt_time => '15:30', count => 0 },
		{ appt_time => '15:45', count => 0 },
        { appt_time => '16:00', count => 0 },
		{ appt_time => '16:15', count => 0 },
		{ appt_time => '16:30', count => 0 },
		{ appt_time => '16:45', count => 0 },
    ]);

        $one = $CLASS->new({ rec_id => 1003 })->retrieve;
    is_deeply( $one->get_appointment_slots_tallied, [
        { appt_time => '8:00', count => 0 },
		{ appt_time => '8:15', count => 0 },
		{ appt_time => '8:30', count => 0 },
		{ appt_time => '8:45', count => 0 },
        { appt_time => '9:00', count => 0 },
		{ appt_time => '9:15', count => 0 },
		{ appt_time => '9:30', count => 0 },
		{ appt_time => '9:45', count => 0 },
        { appt_time => '10:00', count => 0 },
		{ appt_time => '10:15', count => 0 },
		{ appt_time => '10:30', count => 0 },
		{ appt_time => '10:45', count => 0 },
        { appt_time => '11:00', count => 0 },
		{ appt_time => '11:15', count => 0 },
		{ appt_time => '11:30', count => 0 },
		{ appt_time => '11:45', count => 0 },
        { appt_time => '12:00', count => 0 },
		{ appt_time => '12:15', count => 0 },
		{ appt_time => '12:30', count => 0 },
		{ appt_time => '12:45', count => 0 },
        { appt_time => '13:00', count => 0 },
		{ appt_time => '13:15', count => 0 },
		{ appt_time => '13:30', count => 0 },
		{ appt_time => '13:45', count => 0 },
        { appt_time => '14:00', count => 0 },
		{ appt_time => '14:15', count => 0 },
		{ appt_time => '14:30', count => 0 },
		{ appt_time => '14:45', count => 0 },
        { appt_time => '15:00', count => 0 },
		{ appt_time => '15:15', count => 0 },
		{ appt_time => '15:30', count => 0 },
		{ appt_time => '15:45', count => 0 },
        { appt_time => '16:00', count => 0 },
		{ appt_time => '16:15', count => 0 },
		{ appt_time => '16:30', count => 0 },
		{ appt_time => '16:45', count => 0 },
    ]);
  
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
    can_ok( $one, 'get_all' );

    # SQL INJECTION test
    is($test->select_count('schedule_appointments'), keys %$schedule_appointments);
    eval{ $one->get_all('1; DELETE FROM schedule_appointments')};
    is($test->select_count('schedule_appointments'), keys %$schedule_appointments, 'hacker proof');
TODO: {
    local $TODO = 'Security Audit';
    fail("this would better done using randall's new quotme() from eleMentalClinic::Util");
}
    
    is_deeply( $one->get_all , [  
        $schedule_availability->{1006},
        $schedule_availability->{1008},
        $schedule_availability->{1004},
        $schedule_availability->{1005},
        $schedule_availability->{1007},
        $schedule_availability->{1003},
        $schedule_availability->{1001},
        $schedule_availability->{1002},
    ]);
    is_deeply( $one->get_all(3), [
        $schedule_availability->{1006},
        $schedule_availability->{1008},
        $schedule_availability->{1004},
    ]);
    # LIMIT 0 is ignored, apparently
    is_deeply( $one->get_all(0), [ 
        $schedule_availability->{1006},
        $schedule_availability->{1008},
        $schedule_availability->{1004},
        $schedule_availability->{1005},
        $schedule_availability->{1007},
        $schedule_availability->{1003},
        $schedule_availability->{1001},
        $schedule_availability->{1002},
    ]);

    foreach my $obj (@{$one->get_all(3)}) {
        isa_ok($obj, $CLASS);
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# detail
    can_ok( $CLASS, 'detail');
        $one = $CLASS->new;
    is( $one->detail, undef);
        $one = $CLASS->new( {rec_id => 1001} )->retrieve;
    is( $one->detail, 
        join( ' : ', 
           ($schedule_availability->{1001}->{date},
            $valid_data_prognote_location->{$schedule_availability->{1001}->{location_id}}->{name},
            $rolodex->{$schedule_availability->{1001}->{rolodex_id}}->{name})),
        'detail string' );
    is( $one->detail(', '), 
        join( ', ', 
           ($schedule_availability->{1001}->{date},
            $valid_data_prognote_location->{$schedule_availability->{1001}->{location_id}}->{name},
            $rolodex->{$schedule_availability->{1001}->{rolodex_id}}->{name})),
        'detail string' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get one
    can_ok( $CLASS, 'get_one' );
    # missing required data
    is( $CLASS->get_one( year => 0, month => 6, date => 1, location_id => 1001, rolodex_id => 1011 ),
        undef
    );
    is( $CLASS->get_one( year => 2006, month => 0, date => 1, location_id => 1001, rolodex_id => 1011 ),
        undef
    );
    is( $CLASS->get_one( year => 2006, month => 6, date => 0, location_id => 1001, rolodex_id => 1011 ),
        undef
    );
    is( $CLASS->get_one( year => 2006, month => 6, date => 1 ),
        undef
    );

# TODO - I no longer understand these tests.  get_one with only a rolodex or a location id would return a record, but no guarrantee it would be the same on, since you could have several records for that date and rolodex or location id.
#    # only location
#    is_deeply( $CLASS->get_one( year => 2006, month => 6, date => 1, location_id => 1001 ),
#        $schedule_availability->{ 1001 }
#    );
#    is_deeply( $CLASS->get_one( year => 2006, month => 6, date => 1, location_id => 1002 ),
#        $schedule_availability->{ 1002 }
#    );
#    is( $CLASS->get_one( year => 2006, month => 6, date => 1, location_id => 1003 ),
#        undef
#    );
#
#    # only doctor
#    is_deeply( $CLASS->get_one( year => 2006, month => 6, date => 1, rolodex_id => 1001 ),
#        $schedule_availability->{ 1002 }
#    );
#    is_deeply( $CLASS->get_one( year => 2006, month => 6, date => 1, rolodex_id => 1011 ),
#        $schedule_availability->{ 1001 }
#    );
#    is( $CLASS->get_one( year => 2006, month => 6, date => 1, rolodex_id => 1002 ),
#        undef
#    );

    # both
    is_deeply( $CLASS->get_one( year => 2006, month => 6, date => 1, location_id => 1001, rolodex_id => 1011 ),
        $schedule_availability->{ 1001 }
    );
    is_deeply( $CLASS->get_one( year => 2006, month => 6, date => 1, location_id => 1002, rolodex_id => 1001 ),
        $schedule_availability->{ 1002 }
    );
    is_deeply( $CLASS->get_one( year => 2006, month => 6, date => 2, location_id => 1002, rolodex_id => 1001 ),
        $schedule_availability->{ 1003 }
    );
    is( $CLASS->get_one( year => 2006, month => 6, date => 1, location_id => 1001, rolodex_id => 1001 ),
        undef
    );

    # isa
    isa_ok( $CLASS->get_one( year => 2006, month => 6, date => 2, location_id => 1002, rolodex_id => 1001 ),
        $CLASS
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_bydoctor, list_bylocation
    can_ok( $CLASS, 'list_bydoctor', 'list_bylocation', 'list_bydate', 'list_formonth' );
    is( $CLASS->list_bydoctor, undef );
    is( $CLASS->list_bydoctor( 6666 ), undef );

    is( $CLASS->list_bylocation, undef );
    is( $CLASS->list_bylocation( 6666 ), undef );
    
    is( $CLASS->list_bydate, undef );
    #is( $CLASS->get_bydate( '1964-01-01' ), undef );

    # list_bydoctor
    is_deeply( $CLASS->list_bydoctor( 1011 ), [
        $schedule_availability->{ 1001 },
        $schedule_availability->{ 1007 },
        $schedule_availability->{ 1005 },
        $schedule_availability->{ 1006 },
    ] );

    is_deeply( $CLASS->list_bylocation( 1002 ), [
        $schedule_availability->{ 1002 },
        $schedule_availability->{ 1003 },
        $schedule_availability->{ 1005 },
        $schedule_availability->{ 1008 },
        $schedule_availability->{ 1006 },
    ] );

    is_deeply($CLASS->list_bydate( '2006-06-01' ), [
        $schedule_availability->{ 1001 },
        $schedule_availability->{ 1002 },
    ]);
    
    is_deeply($CLASS->list_bydate( '2006-06-05' ), [
        $schedule_availability->{ 1004 },
        $schedule_availability->{ 1005 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list for month
    is( $CLASS->list_formonth, undef );
    is( $CLASS->list_formonth( 6,6666), undef );

    is_deeply($CLASS->list_formonth( month => 6, year => 2006 ), [
        $schedule_availability->{ 1002 },
        $schedule_availability->{ 1001 },
        $schedule_availability->{ 1003 },
        $schedule_availability->{ 1007 },
        $schedule_availability->{ 1004 },
        $schedule_availability->{ 1005 },
        $schedule_availability->{ 1008 },
    ]);

    # bad location
    is( $CLASS->list_formonth( month => 6, year => 2006, location_id => 666 ), undef );

    # location
    is_deeply($CLASS->list_formonth( month => 6, year => 2006, location_id => 1001 ), [
        $schedule_availability->{ 1001 },
        $schedule_availability->{ 1007 },
        $schedule_availability->{ 1004 },
    ]);

    # doctor 
    is_deeply($CLASS->list_formonth( month => 6, year => 2006, rolodex_id => 1001 ), [
        $schedule_availability->{ 1002 },
        $schedule_availability->{ 1003 },
        $schedule_availability->{ 1004 },
        $schedule_availability->{ 1008 },
    ]);

    # both
    is_deeply($CLASS->list_formonth( month => 6, year => 2006, location_id => 1001, rolodex_id => 1011 ), [
        $schedule_availability->{ 1001 },
        $schedule_availability->{ 1007 },
    ]);
    is_deeply($CLASS->list_formonth( month => 6, year => 2006, location_id => 1002, rolodex_id => 1001 ), [
        $schedule_availability->{ 1002 },
        $schedule_availability->{ 1003 },
        $schedule_availability->{ 1008 },
    ]);
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
