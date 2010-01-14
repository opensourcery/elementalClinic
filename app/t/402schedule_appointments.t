# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 68;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Schedule::Appointments';
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
    is( $one->table, 'schedule_appointments');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id schedule_availability_id client_id  confirm_code_id noshow
        fax chart payment_code_id auth_number notes appt_time staff_id
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# confirm_code and payment_code lookups
    can_ok( $one, 'confirm_code');

        $one = $CLASS->new;
    is($one->confirm_code, undef);
        $one->rec_id( 1001 )->retrieve;
    is($one->confirm_code, 
        $valid_data_confirmation_codes->{$one->confirm_code_id}->{name});

    can_ok( $one, 'payment_code');

        $one = $CLASS->new;
    is($one->payment_code, undef);
        $one->rec_id( 1001 )->retrieve;
    is($one->payment_code, 
        $valid_data_payment_codes->{$one->payment_code_id}->{name});

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_byclient
    can_ok( $one, 'list_byclient');

        $one = $CLASS->new;
    
    is($one->list_byclient, undef);
    is($one->list_byclient(9999), undef);
    is_deeply($one->list_byclient(1005), [
        $schedule_appointments->{1005},
        $schedule_appointments->{1006},
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_byclient
    can_ok( $one, 'get_byclient');

        $one = $CLASS->new;

    is($one->get_byclient, undef);
    is($one->get_byclient(9999), undef);
    is_deeply($one->get_byclient(1005), [
        $schedule_appointments->{1005},
        $schedule_appointments->{1006},
    ]);
    for( @{ $one->get_byclient(1005)}) {
        isa_ok( $_, $CLASS );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# availability
    can_ok( $one, 'schedule_availability' );
    is( $one->schedule_availability, undef );

        $one->rec_id( 1001 )->retrieve;
    isa_ok( $one->schedule_availability, 'eleMentalClinic::Schedule::Availability' );
    is_deeply( $one->schedule_availability, $schedule_availability->{ $one->schedule_availability_id });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex
        $one = $CLASS->new;
    can_ok( $one, 'rolodex' );
    is( $one->rolodex, undef );

        $one->rec_id( 1001 )->retrieve;
    isa_ok( $one->rolodex, 'eleMentalClinic::Rolodex' );
    is_deeply( $one->rolodex, $rolodex->{ $one->schedule_availability->rolodex_id });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list upcoming
        $one = $CLASS->new;
    can_ok( $one, 'list_upcoming' );
    is( $one->list_upcoming, undef );
    is( $one->list_upcoming( date => 666, days => 7 ), undef );
    is( $one->list_upcoming( date => '2006-06-31', days => 7 ), undef );
    is( $one->list_upcoming( date => '2006-01-01', days => 7), undef );
    is_deeply( $one->list_upcoming( date => '2006-06-01', days => 14 ), [
        $schedule_appointments->{ 1001 },
        $schedule_appointments->{ 1002 },
        $schedule_appointments->{ 1003 },
        $schedule_appointments->{ 1004 },
        $schedule_appointments->{ 1005 },
        $schedule_appointments->{ 1007 },
        $schedule_appointments->{ 1008 },
    ]);
    is_deeply( $one->list_upcoming( date => '2006-06-07', days => 1, fields => [ qw/ date appt_time a.rec_id client_id / ] ), [
        { date => '2006-06-07',
          appt_time => '9:00',
          rec_id => '1008',
          client_id => '1002', },
    ]);


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list by day
        $one = $CLASS->new;
    can_ok( $one, 'list_byday' );
    is( $one->list_byday, undef );
    is( $one->list_byday( date => 666 ), undef );
    is( $one->list_byday( date => '2006-06-31' ), undef );

    is_deeply( $one->list_byday( date => '2006-06-01' ), [
        $schedule_appointments->{ 1001 },
        $schedule_appointments->{ 1002 },
        $schedule_appointments->{ 1003 },
        $schedule_appointments->{ 1004 },
        $schedule_appointments->{ 1005 },
    ]);

    # location
    is_deeply( $one->list_byday(
            date        => '2006-06-01',
            location_id => 1001,
        ), [
        $schedule_appointments->{ 1001 },
        $schedule_appointments->{ 1002 },
        $schedule_appointments->{ 1003 },
    ]);
    is_deeply( $one->list_byday(
            date        => '2006-06-01',
            location_id => 1002,
        ), [
        $schedule_appointments->{ 1004 },
        $schedule_appointments->{ 1005 },
    ]);

    is( $one->list_byday(
            date        => '2006-06-01',
            location_id => 1003,
        ), undef );

    # doctor
    is_deeply( $one->list_byday(
            date        => '2006-06-01',
            rolodex_id  => 1001,
        ), [
        $schedule_appointments->{ 1004 },
        $schedule_appointments->{ 1005 },
    ]);
    is_deeply( $one->list_byday(
            date        => '2006-06-01',
            rolodex_id  => 1011,
        ), [
        $schedule_appointments->{ 1001 },
        $schedule_appointments->{ 1002 },
        $schedule_appointments->{ 1003 },
    ]);
    is( $one->list_byday(
            date        => '2006-06-01',
            rolodex_id => 1003,
        ), undef );

    # both
    is( $one->list_byday(
            date        => '2006-06-01',
            location_id => 1001,
            rolodex_id  => 1001,
        ), undef );
    is_deeply( $one->list_byday(
            date        => '2006-06-01',
            location_id => 1001,
            rolodex_id  => 1011,
        ), [
        $schedule_appointments->{ 1001 },
        $schedule_appointments->{ 1002 },
        $schedule_appointments->{ 1003 },
    ]);
    is_deeply( $one->list_byday(
            date        => '2006-06-01',
            location_id => 1002,
            rolodex_id  => 1001,
        ), [
        $schedule_appointments->{ 1004 },
        $schedule_appointments->{ 1005 },
    ]);
    is( $one->list_byday(
            date        => '2006-06-01',
            rolodex_id  => 1003,
            location_id => 1001,
        ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get by day
    can_ok( $one, 'get_byday' );
    is( $one->get_byday, undef );
    is( $one->get_byday( date => 666 ), undef );
    is( $one->get_byday( date => '2006-06-31' ), undef );

    is_deeply( $one->get_byday( date => '2006-06-01' ), [
        $schedule_appointments->{ 1001 },
        $schedule_appointments->{ 1002 },
        $schedule_appointments->{ 1003 },
        $schedule_appointments->{ 1004 },
        $schedule_appointments->{ 1005 },
    ]);

    for( @{ $one->get_byday( date => '2006-06-01' )}) {
        isa_ok( $_, $CLASS );
    }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# personnel
        $one = $CLASS->new;
    can_ok( $one, 'personnel' );
    is( $one->personnel, undef );

        $one->rec_id( 1001 )->retrieve;
    isa_ok( $one->personnel, 'eleMentalClinic::Personnel');
    is( $one->personnel->{ staff_id }, $personnel->{ 1001 }->{ staff_id });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
