# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 87;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Placement::Episode';
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

    can_ok( $one, 'client_id' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get by client
        $one = $CLASS->new;
    can_ok( $CLASS, 'get_by_client' );

    is( $CLASS->get_by_client, undef );
    is( $CLASS->get_by_client( 666 ), undef );

    # valid client_id, but not currently in an episode
    is( $CLASS->get_by_client( 1001 ), undef);
    
    isa_ok( $CLASS->get_by_client( 1003 ), 'eleMentalClinic::Client::Placement::Episode' );
    is( $CLASS->get_by_client( 1003 )->client_id, 1003 );
   
    # Test when passing in a date
    isa_ok( $CLASS->get_by_client( 1001, '2006-02-01' ), 'eleMentalClinic::Client::Placement::Episode' );
    is( $CLASS->get_by_client( 1001, '2006-02-01' )->client_id, 1001 );
    is( $CLASS->get_by_client( 1001, '2006-02-01' )->date, '2006-02-01' );

    # Date of discharge
    isa_ok( $CLASS->get_by_client( 1004, '2006-01-15' ), 'eleMentalClinic::Client::Placement::Episode' );
    is( $CLASS->get_by_client( 1004, '2006-01-15' )->client_id, 1004 );
    
    # Date of intake
    isa_ok( $CLASS->get_by_client( 1004, '2006-03-06' ), 'eleMentalClinic::Client::Placement::Episode' );
    is( $CLASS->get_by_client( 1004, '2006-03-06' )->client_id, 1004 );
    
    # Date right before an episode
    is( $CLASS->get_by_client( 1002, '2005-03-16' ), undef );
    # Date right after an episode
    is( $CLASS->get_by_client( 1004, '2006-01-16' ), undef );

    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# events
        $one = $CLASS->new;
    can_ok( $CLASS, 'events' );
    
    is( $CLASS->events, undef );
        $one->client_id( 666 );
    is( $one->events, undef );
        $one->client_id( 1001 );
    is( $one->events, undef );

    is_deeply( $CLASS->get_by_client( 1003 )->events, [ @$client_placement_event{ qw/ 1013 1012 1011 1010 1009 1003 / } ] );
    is_deeply( $CLASS->get_by_client( 1004 )->events, [ $client_placement_event->{ 1015 } ] );
    is_deeply( $CLASS->get_by_client( 1005 )->events, [ $client_placement_event->{ 1005 } ] );

    # Tests when passing in a date
    is_deeply( $CLASS->get_by_client( 1001, '2005-12-12' )->events, [ @$client_placement_event{ qw/ 1007 1001 / } ] );
    is_deeply( $CLASS->get_by_client( 1002, '2006-01-05' )->events, [ @$client_placement_event{ qw/ 1008 1002 / } ] );
    
    # test that it is getting cached (Devel::Cover will tell us)
        $one = $CLASS->get_by_client( 1004 );
        $one->events;
    is_deeply( $one->events, [ $client_placement_event->{ 1015 } ] );

    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# intake_date
        $one = $CLASS->new;
    can_ok( $CLASS, 'intake_date' );

    # most of the code in intake_date is 'cover'ed by the other subroutines
    is( $CLASS->intake_date, undef ); # no client_id
        $one->client_id( 666 );
    is( $one->intake_date, undef ); # no intake_date

    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# discharge_date
        $one = $CLASS->new;
    can_ok( $CLASS, 'discharge_date' );

    # most of the code in discharge_date is 'cover'ed by the other subroutines
    is( $CLASS->discharge_date, undef ); # no client_id
        $one->client_id( 666 );
    is( $one->discharge_date, undef ); # no intake_date
        $one->client_id( 1004 );
    is( $one->discharge_date, undef ); # no discharge_date

    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# referral
    can_ok( $CLASS, 'referral' );

    is( $CLASS->referral, undef ); # no client_id
        $one->client_id( 666 );
    is( $one->referral, undef ); # no intake_date
        $one->client_id( 1001 );
    is( $one->referral, undef ); # not valid_episode 

    # valid client_id and episode, but has no referral
    is( $CLASS->get_by_client( 1004 )->referral, undef );
    is( $CLASS->get_by_client( 1001, '2005-12-12' )->referral, undef );

    is_deeply( $CLASS->get_by_client( 1003 )->referral, $client_referral->{ 1001 } );
    is_deeply( $CLASS->get_by_client( 1005 )->referral, $client_referral->{ 1002 } );

    # test that it is getting cached (Devel::Cover will tell us)
        $one = $CLASS->get_by_client( 1005 );
        $one->referral;
    is_deeply( $one->referral, $client_referral->{ 1002 } );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# discharge
        $one = $CLASS->new;
    can_ok( $CLASS, 'discharge' );

    is( $CLASS->discharge, undef ); # no client_id
        $one->client_id( 666 );
    is( $one->discharge, undef ); # no intake_date
        $one->client_id( 1001 );
    is( $one->discharge, undef ); # not valid_episode

    # valid client_id and episode, but it has no discharge yet
    is( $CLASS->get_by_client( 1003 )->discharge, undef );

    is_deeply( $CLASS->get_by_client( 1001, '2006-01-01' )->discharge, $client_discharge->{ 1001 } );
    is_deeply( $CLASS->get_by_client( 1002, '2006-01-01' )->discharge, $client_discharge->{ 1002 } );

    # test that it is getting cached (Devel::Cover will tell us)
        $one = $CLASS->get_by_client( 1002, '2006-01-01' );
        $one->discharge;
    is_deeply( $one->discharge, $client_discharge->{ 1002 } );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# initial_diagnosis
        $one = $CLASS->new;
    can_ok( $CLASS, 'initial_diagnosis' );

    is( $CLASS->initial_diagnosis, undef ); # no client_id
        $one->client_id( 666 );
    is( $one->initial_diagnosis, undef ); # no intake_date
        $one->client_id( 1001 );
    is( $one->initial_diagnosis, undef ); # not valid_episode 

    is( $CLASS->get_by_client( 1006 )->initial_diagnosis, undef );
    is_deeply( $CLASS->get_by_client( 1003 )->initial_diagnosis, $client_diagnosis->{ 1001 } );

    is_deeply( $CLASS->get_by_client( 1001, '2005-12-12' )->initial_diagnosis, $client_diagnosis->{ 1003 } );
    is_deeply( $CLASS->get_by_client( 1002, '2005-12-12' )->initial_diagnosis, $client_diagnosis->{ 1005 } );

    # test that it is getting cached (Devel::Cover will tell us)
#         $one = $CLASS->get_by_client( 1002, '2005-12-12' );
#         $one->initial_diagnosis;
#     is_deeply( $one->initial_diagnosis, $client_diagnosis->{ 1005 } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# final_diagnosis
        $one = $CLASS->new;
    can_ok( $CLASS, 'final_diagnosis' );

    is( $CLASS->final_diagnosis, undef ); # no client_id
        $one->client_id( 666 );
    is( $one->final_diagnosis, undef ); # no intake_date
        $one->client_id( 1001 );
    is( $one->final_diagnosis, undef ); # not valid_episode 

    is_deeply( $CLASS->get_by_client( 1001, '2005-05-31' )->final_diagnosis, $client_diagnosis->{ 1004 } );
    is_deeply( $CLASS->get_by_client( 1001, '2005-12-12' )->final_diagnosis, $client_diagnosis->{ 1004 } );
    is( $CLASS->get_by_client( 1001, '2006-04-01' ), undef ); # i.e. no final diagnosis, either

    is( $CLASS->get_by_client( 1002 ), undef ); # i.e. no final diagnosis, either
    is( $CLASS->get_by_client( 1002, '2005-12-01' )->final_diagnosis, undef );

    is_deeply( $CLASS->get_by_client( 1003 )->final_diagnosis, $client_diagnosis->{ 1002 } );
    is_deeply( $CLASS->get_by_client( 1003, '2010-01-01' )->final_diagnosis, $client_diagnosis->{ 1002 } );

    is( $CLASS->get_by_client( 1004 )->final_diagnosis, undef );
    is( $CLASS->get_by_client( 1004, '2005-04-25' )->final_diagnosis, undef );

    # test that it is getting cached (Devel::Cover will tell us)
#         $one = $CLASS->get_by_client( 1002, '2005-12-12' );
#         $one->final_diagnosis;
#     is_deeply( $one->final_diagnosis, $client_diagnosis->{ 1005 } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# admit_date
    can_ok( $CLASS, 'admit_date' );

    is( $CLASS->get_by_client, undef );
    is( $CLASS->get_by_client( 1001, '2005-12-12' )->admit_date, '2005-05-04' );
    is( $CLASS->get_by_client( 1003 )->admit_date, '2005-03-17' );
    is( $CLASS->get_by_client( 1004 )->admit_date, '2006-03-06' );
    is( $CLASS->get_by_client( 1005 )->admit_date, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# referral_date
    can_ok( $CLASS, 'referral_date' );

    is( $CLASS->get_by_client, undef );
    is( $CLASS->get_by_client( 1001, '2005-12-12' )->referral_date, undef );
    is( $CLASS->get_by_client( 1003 )->referral_date, '2005-03-01' );
    is( $CLASS->get_by_client( 1004 )->referral_date, undef );
    is( $CLASS->get_by_client( 1005 )->referral_date, '2005-05-20' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->delete_( $CLASS, '*' );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
