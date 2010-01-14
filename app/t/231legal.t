# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 48;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Legal';
    use_ok( $CLASS );
    $CLASSDATA = $client_legal_history;
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
    is( $one->table, 'client_legal_history');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id status_id location_id
        reason start_date end_date comment_text
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
    can_ok( $one, 'get_all' );

    is( $one->get_all, undef );

    is( $one->get_all( 6666 ), undef );

        $tmp = $one->get_all( 1002 );
    is_deeply( $tmp, [
        $CLASSDATA->{ 1002 },
        $CLASSDATA->{ 1001 },
        $CLASSDATA->{ 1003 },
    ] );
    isa_ok( $_, $CLASS ) for @$tmp;

        $one->client_id( 1002 );
    is_deeply( $one->get_all, $one->get_all( 1002 ) );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# history
# wrapper
    can_ok( $one, 'history' );

    is_deeply( $one->history( 1002 ), $one->get_all( 1002 ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# location
    can_ok( $one, 'location' );

    is( $one->location, undef );
    is( $one->location( 1001 ), undef );
        $one->location_id( 1 );
    is( $one->location, undef );

        $one->location_id( 6666 );
    is( $one->location( 1001 ), undef );

    # these die because dept_id 6666 returns no vd_vd records
    #    $one->location_id( 1 );
    #is( $one->location( 6666 ), undef );

        $tmp = $test->db->do_sql(qq/
            SELECT  name
            FROM    valid_data_legal_location
            WHERE   rec_id = 1
        /)->[ 0 ]->{ name };
        $one->location_id( 1 );
    is_deeply( $one->location( 1001 ), $tmp );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# status
    can_ok( $one, 'status' );

    is( $one->status, undef );
    is( $one->status( 1001 ), undef );

    # these die because dept_id 6666 returns no vd_vd records
    #    $one->status_id( 1 );
    #is( $one->status( 6666 ), undef );

        $tmp = $test->db->do_sql(qq/
            SELECT name FROM valid_data_legal_status WHERE rec_id = 1
        /)->[0]->{ name };
        $one->status_id( 1 );
    is_deeply( $one->status( 1001 ), $tmp );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# past_issues
    can_ok( $one, 'past_issues' );

    is( $one->past_issues, undef );
    is( $one->past_issues( 6666 ), undef );

    is_deeply( $one->past_issues( 1002 ), [
        $CLASSDATA->{ 1001 },
        $CLASSDATA->{ 1002 },
    ]);

        $one->client_id( 1002 );
    is_deeply( $one->past_issues, $one->past_issues( 1002 ) );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# current_issues
    can_ok( $one, 'current_issues' );

    is( $one->current_issues, undef );
    is( $one->current_issues( 6666 ), undef );

    is_deeply( $one->current_issues( 1002 ), [
        $CLASSDATA->{ 1003 },
    ]);

        $one->client_id( 1002 );
    is_deeply( $one->current_issues, $one->current_issues( 1002 ) );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_current
    can_ok( $one, 'is_current' );

    is( $one->is_current, undef );

    # return true with a start date before today and no end date
        $one->start_date( '2000-01-01' );
    is( $one->is_current, 1 );
    
    # return true with an end date after today and no start date
        $one->start_date( '' );
        $one->end_date( '2100-01-01' );
    is( $one->is_current, 1 );
    
    # return true with a start date before today and end date after today (duh)
        $one->start_date( '2000-01-01' );
        $one->end_date( '2100-01-01' );
    is( $one->is_current, 1 );
    
    # return false with a start date after today and no end date
        $one->start_date( '2100-01-01' );
        $one->end_date( '' );
    is( $one->is_current, undef );
    
    # return false with an end date before today and no start date
        $one->start_date( '' );
        $one->end_date( '2000-01-01' );
    is( $one->is_current, undef );
    
    # return false with an end date before today and a start date after today (shouldn't ever happen)
        $one->start_date( '2100-01-01' );
        $one->end_date( '2000-01-01' );
    is( $one->is_current, undef );
    
    # return false with both dates before today
        $one->start_date( '2000-01-01' );
        $one->end_date( '2000-01-01' );
    is( $one->is_current, undef );
    
    # return false with both dates after today
        $one->start_date( '2100-01-01' );
        $one->end_date( '2100-01-01' );
    is( $one->is_current, undef );


        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
