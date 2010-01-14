# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 101;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Group::Note';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;

        $test->insert_data([
            'eleMentalClinic::Personnel',
            'eleMentalClinic::Client',
            'eleMentalClinic::TreatmentGoal',
            'valid_data_prognote_location',
            $CLASS,
        ]);
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'group_notes');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id group_id staff_id start_date end_date note_body
        data_entry_id charge_code_id note_location_id
        note_committed outcome_rating
/]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# note_duration_ok
    is( $one->config->prognote_min_duration_minutes, 1 );
    is( $one->config->prognote_max_duration_minutes, 480 );
    can_ok( $one, 'note_duration_ok' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# note_duration_ok
# methods with no parameters are using the config variables
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 1 ), undef );
    is( $one->note_duration_ok( undef, 1 ), undef );
    is( $one->note_duration_ok( 0, -1 ), undef );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 7:00' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 30 ), 0 );
    is( $one->note_duration_ok( 0, 60 ), 0 );
    is( $one->note_duration_ok( 0, 120 ), 0 );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 7:59' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 30 ), 0 );
    is( $one->note_duration_ok( 0, 60 ), 0 );
    is( $one->note_duration_ok( 0, 120 ), 0 );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-5 9:00' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 30 ), 0 );
    is( $one->note_duration_ok( 0, 60 ), 0 );
    is( $one->note_duration_ok( 0, 120 ), 0 );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 8:00' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 1 );
    is( $one->note_duration_ok( 0, 30 ), 1 );
    is( $one->note_duration_ok( 0, 60 ), 1 );
    is( $one->note_duration_ok( 0, 120 ), 1 );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 8:30' );
    is( $one->note_duration_ok, 1 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 30 ), 1 );
    is( $one->note_duration_ok( 0, 60 ), 1 );
    is( $one->note_duration_ok( 0, 120 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-6 9:00' );
    is( $one->note_duration_ok, 1 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 30 ), 0 );
    is( $one->note_duration_ok( 0, 60 ), 1 );
    is( $one->note_duration_ok( 0, 120 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-6 12:00' );
    is( $one->note_duration_ok, 1 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 239 ), 0 );
    is( $one->note_duration_ok( 0, 240 ), 1 );
    is( $one->note_duration_ok( 0, 300 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-6 15:59' );
    is( $one->note_duration_ok, 1 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 420 ), 0 );
    is( $one->note_duration_ok( 0, 480 ), 1 );
    is( $one->note_duration_ok( 0, 540 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-6 16:00' );
    is( $one->note_duration_ok, 1 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 420 ), 0 );
    is( $one->note_duration_ok( 0, 480 ), 1 );
    is( $one->note_duration_ok( 0, 540 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-6 16:01' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 420 ), 0 );
    is( $one->note_duration_ok( 0, 480 ), 0 );
    is( $one->note_duration_ok( 0, 540 ), 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# init
    can_ok( $one, 'init' );
    is_deeply( $one->init, $one );

    is_deeply( $one->init({ note_date => '2005-05-05' }), $one );
    is_deeply( $one->init({ start_time => '8:00' }), $one );
    is_deeply( $one->init({ end_time => '9:00' }), $one ); 

    is_deeply( $one->init({
        start_time => '8:00',
        end_time => '9:00',
    }), $one ); 

    # TODO fix the warning that this incurrs
    is_deeply( $one->init({
        note_date => '2005-05-05',
        end_time => '9:00',
    }), $one ); 

    is_deeply( $one->init({
        note_date => '2005-05-05',
        start_time => '8:00',
    }), $one ); 

    is_deeply( $one->init({
        note_date => '2005-05-05',
        start_time => '8:00',
        end_time => '9:00',
    }), $one ); 
    is( $one->start_date, '2005-05-05 8:00' );
    is( $one->end_date, '2005-05-05 9:00' );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# commit
    can_ok( $one, 'commit' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# note_date
    can_ok( $one, 'note_date' );
    is( $one->note_date, undef );

        $one->start_date( 0 );
    is( $one->note_date, undef );

        $one->start_date( '2005-05-09 12:30:00' );
    is( $one->note_date, '2005-05-09' );

        $one->start_date( 'foo bar' );
    is( $one->note_date, 'foo' );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start_time
    can_ok( $one, 'start_time' );
    is( $one->start_time, undef );

    $one->start_date( 0 );
    is( $one->start_time, undef );

    $one->start_date( '2005-05-09 12:30:00' );
    is( $one->start_time, '12:30' );

    $one->start_date( '2005-05-09 02:00:00' );
    is( $one->start_time, '2:00' );

    $one->start_date( '2005-05-09 00:15:00' );
    is( $one->start_time, '0:15' );

    $one->start_date( 'there is a time in here 00:15:00 somewhere' );
    is( $one->start_time, '0:15' );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# end_time
    can_ok( $one, 'end_time' );
    is( $one->end_time, undef );

        $one->end_date( 0 );
    is( $one->end_time, undef );

        $one->end_date( '2005-05-09 12:30:00' );
    is( $one->end_time, '12:30' );

        $one->end_date( '2005-05-09 02:00:00' );
    is( $one->end_time, '2:00' );

        $one->end_date( '2005-05-09 00:15:00' );
    is( $one->end_time, '0:15' );

        $one->end_date( 'there is a time in here 00:15:00 somewhere' );
    is( $one->end_time, '0:15' );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    can_ok( $one, 'save' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_group
# wrapper
    can_ok( $one, 'get_group' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_bygroup
# wrapper
    can_ok( $one, 'get_bygroup' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_attendees
# wrapper
    can_ok( $one, 'get_attendees' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# all_committed
# wrapper
    can_ok( $one, 'all_committed' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->delete_( $CLASS, '*' );
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
