# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 75;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Schedule';
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
    is_deeply( $one->fields, [qw/
        month year location_id rolodex_id
    /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# available_schedules
    can_ok( $one, "available_schedules" );
    is_deeply( $one->available_schedules, [
        { schedule_availability_id => 1006, 
          date => $schedule_availability->{1006}->{date},
          location => $valid_data_prognote_location->{1002}->{name},
          doctor => $rolodex->{1011}->{name},
          appointment_count => 1 },
        { schedule_availability_id => 1008, 
          date => $schedule_availability->{1008}->{date},
          location => $valid_data_prognote_location->{1002}->{name},
          doctor => $rolodex->{1001}->{name},
          appointment_count => 1 },
        { schedule_availability_id => 1004, 
          date => $schedule_availability->{1004}->{date},
          location => $valid_data_prognote_location->{1001}->{name},
          doctor => $rolodex->{1001}->{name},
          appointment_count => 0 },
        { schedule_availability_id => 1005, 
          date => $schedule_availability->{1005}->{date},
          location => $valid_data_prognote_location->{1002}->{name},
          doctor => $rolodex->{1011}->{name},
          appointment_count => 0 },
        { schedule_availability_id => 1007, 
          date => $schedule_availability->{1007}->{date},
          location => $valid_data_prognote_location->{1001}->{name},
          doctor => $rolodex->{1011}->{name},
          appointment_count => 1 },
        { schedule_availability_id => 1003,
          date => $schedule_availability->{1003}->{date},
          location => $valid_data_prognote_location->{1002}->{name},
          doctor => $rolodex->{1001}->{name},
          appointment_count => 0 },
        { schedule_availability_id => 1001, 
          date => $schedule_availability->{1001}->{date},
          location => $valid_data_prognote_location->{1001}->{name},
          doctor => $rolodex->{1011}->{name},
          appointment_count => 3 },
        { schedule_availability_id => 1002, 
          date => $schedule_availability->{1002}->{date},
          location => $valid_data_prognote_location->{1002}->{name},
          doctor => $rolodex->{1001}->{name},
          appointment_count => 2 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# appointment slots
    can_ok( $one, 'appointment_slots' );
    is( $one->appointment_slots, undef );
    is( $one->appointment_slots( 666 ), undef );

    is( $one->config->clinic_first_appointment, '8:00' );
    is( $one->config->clinic_last_appointment, '16:30' );

    is_deeply( $one->appointment_slots( 1001 ), [
        '8:00', '8:15', '8:30', '8:45',
        '9:00', '9:15', '9:30', '9:45',
        '10:00', '10:15', '10:30', '10:45',
        '11:00', '11:15', '11:30', '11:45',
        '12:00', '12:15', '12:30', '12:45',
        '13:00', '13:15', '13:30', '13:45',
        '14:00', '14:15', '14:30', '14:45',
        '15:00', '15:15', '15:30', '15:45',
        '16:00', '16:15', '16:30', '16:45',
    ]);

    is_deeply( $one->appointment_slots( 1011 ), [
        '8:00', '8:15', '8:30', '8:45',
        '9:00', '9:15', '9:30', '9:45',
        '10:00', '10:15', '10:30', '10:45',
        '11:00', '11:15', '11:30', '11:45',
        '12:00', '12:15', '12:30', '12:45',
        '13:00', '13:15', '13:30', '13:45',
        '14:00', '14:15', '14:30', '14:45',
        '15:00', '15:15', '15:30', '15:45',
        '16:00', '16:15', '16:30', '16:45',
    ]);

# No multipliers for now
#    is_deeply( $one->appointment_slots( 1011 ), [
#        '8:00',  '8:00',  '8:15',  '8:15',  '8:30',  '8:30',  '8:45',  '8:45',
#        '9:00',  '9:00',  '9:15',  '9:15',  '9:30',  '9:30',  '9:45',  '9:45',
#        '10:00', '10:00', '10:15', '10:15', '10:30', '10:30', '10:45', '10:45',
#        '11:00', '11:00', '11:15', '11:15', '11:30', '11:30', '11:45', '11:45',
#        '12:00', '12:00', '12:15', '12:15', '12:30', '12:30', '12:45', '12:45',
#        '13:00', '13:00', '13:15', '13:15', '13:30', '13:30', '13:45', '13:45',
#        '14:00', '14:00', '14:15', '14:15', '14:30', '14:30', '14:45', '14:45',
#        '15:00', '15:00', '15:15', '15:15', '15:30', '15:30', '15:45', '15:45',
#        '16:00', '16:00', '16:15', '16:15', '16:30', '16:30', '16:45', '16:45',
#    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# appointment_slots_tallied

    can_ok( $one, 'appointment_slots_tallied' );

        $one = $CLASS->new;
    is( $one->appointment_slots_tallied, undef);
    is( $one->appointment_slots_tallied( 1 ), undef);

        $one = $CLASS->new({ month => 6, year => 2006, rolodex_id => 1002 });
    # schedule availability must be defined
    is( $one->appointment_slots_tallied( 1 ), undef );

        $one = $CLASS->new({ month => 6, year => 2006, rolodex_id => 1011 });
    is_deeply( $one->appointment_slots_tallied( 666 ), [
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
    ] );

    is_deeply( $one->appointment_slots_tallied( 1 ), [
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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# days
    can_ok( $one, 'days' );
        $one = $CLASS->new;
    is( $one->days, undef );
    is( $one->days( 1 ), undef );
    is( $one->days( 1, 2006 ), undef );
    is( $one->days( 6, 2006 ), undef );

        $one->month( 6 );
        $one->year( 2006 );
    is_deeply( $one->days, {
        1 => 2,
        2 => 1,
        5 => 2,
        7 => 1,
        3 => 1,
    });

    is_deeply( $CLASS->new({ month => 6, year => 2006 })->days, {
        1 => 2,
        2 => 1,
        5 => 2,
        7 => 1,
        3 => 1,
    });

    is_deeply( $CLASS->new({ month => 6, year => 2006, location_id => 1001, rolodex_id => 1011 })->days, {
        1 => 1,
        3 => 1,
    });
    is_deeply( $CLASS->new({ month => 6, year => 2006, location_id => 1002, rolodex_id => 1011 })->days, {
        5 => 1,
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# schedule availability id
        $one = $CLASS->new;
    can_ok( $one, 'schedule_availability' );
    is( $one->schedule_availability, undef );
    is( $one->schedule_availability( 1 ), undef );

        $one->month( 6 );
    is( $one->schedule_availability( 1 ), undef );
        $one->year( 2006 );
    is( $one->schedule_availability( 1 ), undef );

    # 1001
    # The original test, and get_one method in Schedule::Availability allowed you to obtain the first Schedule::Availability row that  mached the date and either rolodex or location id.  I'm at a loss as to why, since that would not guarrantee match to a single schedule_availability row...
        $one->rolodex_id( 1011 );
    is( $one->schedule_availability( 1 ), undef );
        $one->location_id( 1001 );
    is( $one->schedule_availability( 1 )->rec_id, 1001 );
    is( $one->schedule_availability( 1 )->id, 1001 );
    is_deeply( $one->schedule_availability( 1 ), $schedule_availability->{ 1001 });
    isa_ok( $one->schedule_availability( 1 ), 'eleMentalClinic::Schedule::Availability' );

    # 1002
        $one->rolodex_id( 1001 );
    is( $one->schedule_availability( 1 ), undef );
        $one->location_id( 1002 );
    is( $one->schedule_availability( 1 )->rec_id, 1002 );

    # 1003
    is( $one->schedule_availability( 2 )->rec_id, 1003 );
        $one->rolodex_id( 1011 );
    is( $one->schedule_availability( 2 ), undef );
        $one->location_id( 1001 );
    is( $one->schedule_availability( 2 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# appointments
        $one = $CLASS->new;
    can_ok( $one, 'appointments' );
    is( $one->appointments, undef );
    is( $one->appointments( 1 ), undef );

        $one->month( 6 );
        $one->year( 2006 );
    is( $one->appointments( 31 ), undef );

    # date filter
    is_deeply( $one->appointments( 1 ), [
        $schedule_appointments->{ 1001 },
        $schedule_appointments->{ 1002 },
        $schedule_appointments->{ 1003 },
        $schedule_appointments->{ 1004 },
        $schedule_appointments->{ 1005 },
    ]);

    # location filter
        $one->location_id( 1001 );
    is_deeply( $one->appointments( 1 ), [
        $schedule_appointments->{ 1001 },
        $schedule_appointments->{ 1002 },
        $schedule_appointments->{ 1003 },
    ]);

        $one->location_id( 1002 );
    is_deeply( $one->appointments( 1 ), [
        $schedule_appointments->{ 1004 },
        $schedule_appointments->{ 1005 },
    ]);

    # doctor filter
        $one = $CLASS->new({ month => 6, year => 2006, rolodex_id => 1002 });
    is( $one->appointments, undef );

        $one = $CLASS->new({ month => 6, year => 2006, rolodex_id => 1001 });
    is_deeply( $one->appointments( 1 ), [
        $schedule_appointments->{ 1004 },
        $schedule_appointments->{ 1005 },
    ]);
        $one = $CLASS->new({ month => 6, year => 2006, rolodex_id => 1011 });
    is_deeply( $one->appointments( 1 ), [
        $schedule_appointments->{ 1001 },
        $schedule_appointments->{ 1002 },
        $schedule_appointments->{ 1003 },
    ]);

    # both
        $one = $CLASS->new({ month => 6, year => 2006, location_id => 1001, rolodex_id => 1002 });
    is( $one->appointments, undef );

        $one = $CLASS->new({ month => 6, year => 2006, location_id => 1002, rolodex_id => 1001 });
    is_deeply( $one->appointments( 1 ), [
        $schedule_appointments->{ 1004 },
        $schedule_appointments->{ 1005 },
    ]);
        $one = $CLASS->new({ month => 6, year => 2006, location_id => 1001, rolodex_id => 1011 });
    is_deeply( $one->appointments( 1 ), [
        $schedule_appointments->{ 1001 },
        $schedule_appointments->{ 1002 },
        $schedule_appointments->{ 1003 },
    ]);

    for( @{ $one->appointments( 1 )}) {
        isa_ok( $_, 'eleMentalClinic::Schedule::Appointments' );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# fill appointment slots
        $one = $CLASS->new;
    can_ok( $one, 'appointment_slots_filled' );
    is( $one->appointment_slots_filled, undef );
    is( $one->appointment_slots_filled, undef );
    is( $one->appointment_slots_filled, undef );

        $one = $CLASS->new({ month => 6, year => 2006, rolodex_id => 1002 });
    is( $one->appointment_slots_filled, undef );

        $one = $CLASS->new({ month => 6, year => 2006, rolodex_id => 1001 });
    # even with a non-existent date, we get the empty slots
    is_deeply( $one->appointment_slots_filled( 666 ), [
        '8:00', '8:15', '8:30', '8:45',
        '9:00', '9:15', '9:30', '9:45',
        '10:00', '10:15', '10:30', '10:45',
        '11:00', '11:15', '11:30', '11:45',
        '12:00', '12:15', '12:30', '12:45',
        '13:00', '13:15', '13:30', '13:45',
        '14:00', '14:15', '14:30', '14:45',
        '15:00', '15:15', '15:30', '15:45',
        '16:00', '16:15', '16:30', '16:45',
    ]);

    # Can always make new appointments for a given time slot.
    is_deeply( $one->appointment_slots_filled( 1 ), [
        '8:00', '8:15', '8:30', '8:45',
        '9:00', '9:15', '9:30', '9:45',
        $schedule_appointments->{ 1004 }, '10:00', '10:15', '10:30', '10:45',
        '11:00', '11:15', '11:30', '11:45',
        '12:00', '12:15', '12:30', '12:45',
        '13:00', '13:15', '13:30', '13:45',
        '14:00', '14:15', '14:30', '14:45',
        $schedule_appointments->{ 1005 }, '15:00', '15:15', '15:30', '15:45',
        '16:00', '16:15', '16:30', '16:45',
    ]);

        $one = $CLASS->new({ month => 6, year => 2006, rolodex_id => 1011 });
    is_deeply( $one->appointment_slots_filled( 1 ), [
        '8:00', '8:15',  '8:30',  '8:45', 
        $schedule_appointments->{ 1001 }, $schedule_appointments->{ 1002 }, '9:00', '9:15',  '9:30',  '9:45',
        '10:00', '10:15', '10:30', '10:45',
        '11:00', '11:15', '11:30', '11:45',
        '12:00', '12:15', '12:30', '12:45',
        '13:00', '13:15', '13:30', '13:45',
        '14:00', '14:15', '14:30', '14:45',
        $schedule_appointments->{ 1003 }, '15:00', '15:15', '15:30', '15:45',
        '16:00', '16:15', '16:30', '16:45',
    ]);

#    is_deeply( $one->appointment_slots_filled( 1 ), [
#        '8:00', '8:00', '8:15',  '8:15',  '8:30',  '8:30',  '8:45',  '8:45',
#        $schedule_appointments->{ 1001 },  $schedule_appointments->{ 1002 }, '9:15',  '9:15',  '9:30',  '9:30',  '9:45',  '9:45',
#        '10:00', '10:00', '10:15', '10:15', '10:30', '10:30', '10:45', '10:45',
#        '11:00', '11:00', '11:15', '11:15', '11:30', '11:30', '11:45', '11:45',
#        '12:00', '12:00', '12:15', '12:15', '12:30', '12:30', '12:45', '12:45',
#        '13:00', '13:00', '13:15', '13:15', '13:30', '13:30', '13:45', '13:45',
#        '14:00', '14:00', '14:15', '14:15', '14:30', '14:30', '14:45', '14:45',
#        $schedule_appointments->{ 1003 }, '15:00', '15:15', '15:15', '15:30', '15:30', '15:45', '15:45',
#        '16:00', '16:00', '16:15', '16:15', '16:30', '16:30', '16:45', '16:45',
#    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set schedule type association
    can_ok( $one,'set_schedule_type' );
    can_ok( $one,'get_schedule_type' );
    
    is( $one->set_schedule_type, undef );
    is( $one->get_schedule_type, undef );
    is( $one->get_schedule_type( 666 ), undef );
    
    $one = $CLASS->new({ rolodex_id => 1001 });
    $one->set_schedule_type( 1001 );
    is( $one->get_schedule_type( 1001 ), 1001 );
    $one->set_schedule_type( 1002 );
    is( $one->get_schedule_type( 1001 ), 1002 );
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
