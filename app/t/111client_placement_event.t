# Copyright (C) 2004-2009 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 136;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Placement::Event';
    use_ok( $CLASS );
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->delete_( $CLASS, '*' );
        $test->insert_data;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'client_placement_event');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id dept_id program_id level_of_care_id
        staff_id event_date input_date 
        level_of_care_locked intake_id discharge_id
    /]);
    is_deeply( [ sort @{ $CLASS->fields }], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# retrieve_one
    {
        can_ok( $CLASS, qw/client personnel/ );
        local $one = $CLASS->retrieve( 1001 );
        is_deeply(
            $one->client,
            eleMentalClinic::Client->retrieve( 1001 ),
            "Got Client"
        );

        is_deeply(
            $one->personnel,
            eleMentalClinic::Personnel->retrieve( 1001 ),
            "Got Personnel"
        );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
    is_deeply( [ @{ $one->get_all }[ 0..5 ]], [
        $client_placement_event->{ 1001 },
        $client_placement_event->{ 1002 },
        $client_placement_event->{ 1003 },
        $client_placement_event->{ 1004 },
        $client_placement_event->{ 1005 },
        $client_placement_event->{ 1006 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get all by client
    can_ok( $one, 'get_all_by_client' );

    is( $one->get_all_by_client, undef );
    is( $one->get_all_by_client( 666 ), undef );

    is_deeply( $one->get_all_by_client( 1001 ), [
        $client_placement_event->{ 1001 },
        $client_placement_event->{ 1007 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get by client
    can_ok( $CLASS, 'get_by_client' );

    is( $CLASS->get_by_client, undef );
    is( $CLASS->get_by_client( 666 ), undef );

    isa_ok( $CLASS->get_by_client( 1001 ), 'eleMentalClinic::Client::Placement::Event' );
    is( $CLASS->get_by_client( 1001 )->client_id, 1001 );
    is_deeply( $CLASS->get_by_client( 1001 ), $client_placement_event->{ 1007 });
    is_deeply( $CLASS->get_by_client( 1002 ), $client_placement_event->{ 1008 });
    is_deeply( $CLASS->get_by_client( 1003 ), $client_placement_event->{ 1013 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get by client, with date
    dies_ok{
      $test->db->transaction_do(sub { $CLASS->get_by_client( 1001, 'barf' ) })
    };
    like( $@, qr/invalid/ );

    is(        $CLASS->get_by_client( 1001, '2000-01-01' ), undef );
    is(        $CLASS->get_by_client( 1001, '2005-05-03' ), undef );
    is_deeply( $CLASS->get_by_client( 1001, '2005-05-04' ), $client_placement_event->{ 1001 });
    is_deeply( $CLASS->get_by_client( 1001, '2006-01-01' ), $client_placement_event->{ 1001 });
    is_deeply( $CLASS->get_by_client( 1001, '2006-03-14' ), $client_placement_event->{ 1001 });
    is_deeply( $CLASS->get_by_client( 1001, '2006-03-15' ), $client_placement_event->{ 1007 });
    is_deeply( $CLASS->get_by_client( 1001, '2006-03-16' ), $client_placement_event->{ 1007 });

    is(        $CLASS->get_by_client( 1003, '2000-01-01' ), undef );
    is(        $CLASS->get_by_client( 1003, '2005-02-28' ), undef );
    is_deeply( $CLASS->get_by_client( 1003, '2005-03-01' ), $client_placement_event->{ 1003 });
    is_deeply( $CLASS->get_by_client( 1003, '2005-03-16' ), $client_placement_event->{ 1003 });
    is_deeply( $CLASS->get_by_client( 1003, '2005-03-17' ), $client_placement_event->{ 1009 });
    is_deeply( $CLASS->get_by_client( 1003, '2005-03-18' ), $client_placement_event->{ 1010 });
    is_deeply( $CLASS->get_by_client( 1003, '2005-03-24' ), $client_placement_event->{ 1010 });
    is_deeply( $CLASS->get_by_client( 1003, '2005-03-25' ), $client_placement_event->{ 1012 });
    is_deeply( $CLASS->get_by_client( 1003, '2005-04-01' ), $client_placement_event->{ 1013 });
    is_deeply( $CLASS->get_by_client( 1003, '2005-05-01' ), $client_placement_event->{ 1013 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# program
    can_ok( $CLASS, 'program' );
    is( $one->program, undef );

    is( $CLASS->get_by_client( 1001 )->program, undef );
    is( $CLASS->get_by_client( 1002 )->program, undef );
    is_deeply( $CLASS->get_by_client( 1003 )->program, $valid_data_program->{ 1001 });
    is_deeply( $CLASS->get_by_client( 1004 )->program, $valid_data_program->{ 1001 });
    is( $CLASS->get_by_client( 1005 )->program->{ rec_id }, 1 );
    is( $CLASS->get_by_client( 1005 )->program->{ is_referral }, 1 );
    is( $CLASS->get_by_client( 1005 )->program->{ name }, 'Referral' );
    is_deeply( $CLASS->get_by_client( 1006 )->program, $valid_data_program->{ 1004 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# level_of_care
    can_ok( $CLASS, 'level_of_care' );
    is( $one->level_of_care, undef );

    is( $CLASS->get_by_client( 1001 )->level_of_care, undef );
    is( $CLASS->get_by_client( 1002 )->level_of_care, undef );
    is_deeply( $CLASS->get_by_client( 1003 )->level_of_care, $valid_data_level_of_care->{ 1002 });
    is_deeply( $CLASS->get_by_client( 1004 )->level_of_care, $valid_data_level_of_care->{ 1001 });
    is_deeply( $CLASS->get_by_client( 1005 )->level_of_care, $valid_data_level_of_care->{ 1004 });
    is_deeply( $CLASS->get_by_client( 1006 )->level_of_care, $valid_data_level_of_care->{ 1004 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# personnel
    can_ok( $CLASS, 'personnel' );
    is( $one->personnel, undef );

    is( $CLASS->get_by_client( 1001 )->personnel, undef );
    is( $CLASS->get_by_client( 1002 )->personnel, undef );

    isa_ok( $CLASS->get_by_client( 1003 )->personnel, 'eleMentalClinic::Personnel' );
    is( $CLASS->get_by_client( 1003 )->personnel->staff_id, 1002 );
    isa_ok( $CLASS->get_by_client( 1004 )->personnel, 'eleMentalClinic::Personnel' );
    is( $CLASS->get_by_client( 1004 )->personnel->staff_id, 1001 );
    isa_ok( $CLASS->get_by_client( 1005 )->personnel, 'eleMentalClinic::Personnel' );
    is( $CLASS->get_by_client( 1005 )->personnel->staff_id, 1001 );
    isa_ok( $CLASS->get_by_client( 1006 )->personnel, 'eleMentalClinic::Personnel' );
    is( $CLASS->get_by_client( 1006 )->personnel->staff_id, 1003 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# referral
        $one = $CLASS->new;
    can_ok( $one, 'referral' );
    is( $one->referral, undef );

    is( $CLASS->get_by_client( 1001 )->referral, undef );
    is( $CLASS->get_by_client( 1002 )->referral, undef );
    is( $CLASS->get_by_client( 1003 )->referral, undef );
    is( $CLASS->get_by_client( 1004 )->referral, undef );
    is_deeply( $CLASS->get_by_client( 1005 )->referral, $client_referral->{ 1002 });
    is( $CLASS->get_by_client( 1006 )->referral, undef );

    is_deeply( $CLASS->get_by_client( 1003, '2005-03-01' )->referral, $client_referral->{ 1001 });
    is_deeply( $CLASS->get_by_client( 1003, '2005-03-16' )->referral, $client_referral->{ 1001 });
    is( $CLASS->get_by_client( 1003, '2005-03-17' )->referral, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# discharge
        $one = $CLASS->new;
    can_ok( $one, 'discharge' );
    is( $one->discharge, undef );

    is_deeply( $CLASS->get_by_client( 1001 )->discharge, $client_discharge->{ 1001 });
    is_deeply( $CLASS->get_by_client( 1002 )->discharge, $client_discharge->{ 1002 });
    is( $CLASS->get_by_client( 1003 )->discharge, undef );
    is( $CLASS->get_by_client( 1004 )->discharge, undef );
    is( $CLASS->get_by_client( 1005 )->discharge, undef );
    is( $CLASS->get_by_client( 1006 )->discharge, undef );

    is( $CLASS->get_by_client( 1001, '2005-05-05' )->discharge, undef );
    is( $CLASS->get_by_client( 1001, '2006-03-14' )->discharge, undef );

    is( $CLASS->get_by_client( 1002, '2005-03-18' )->discharge, undef );
    is( $CLASS->get_by_client( 1002, '2006-01-04' )->discharge, undef );

    is( $CLASS->get_by_client( 1004, '2006-01-14' )->discharge, undef );
    is_deeply( $CLASS->get_by_client( 1004, '2006-01-15' )->discharge, $client_discharge->{ 1003 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dates, current
    can_ok( $one, 'previous_date_limit' );
    can_ok( $one, 'next_date_limit' );

    # intake event (referral or not)
    #     < next event
    #     > previous discharge
        $tmp = $CLASS->get_by_client( 1004, '2006-05-01' );
    is( $tmp->rec_id, 1015 );
    is( $tmp->previous_date_limit, '2006-01-15' );
    is( $tmp->next_date_limit, undef );

        $tmp = $CLASS->get_by_client( 1005, '2006-05-01' );
    is( $tmp->rec_id, 1005 );
    is( $tmp->previous_date_limit, undef );
    is( $tmp->next_date_limit, undef );

        $tmp = $CLASS->get_by_client( 1006, '2006-05-01' );
    is( $tmp->rec_id, 1006 );
    is( $tmp->previous_date_limit, undef );
    is( $tmp->next_date_limit, undef );

    # change event
    #     < next discharge
    #     > previous intake
        $tmp = $CLASS->get_by_client( 1003, '2006-05-01' );
    is( $tmp->rec_id, 1013 );
    is( $tmp->previous_date_limit, '2005-03-01' );
    is( $tmp->next_date_limit, undef );

    # discharge event
    #     < next intake event
    #     > previous event
        $tmp = $CLASS->get_by_client( 1001, '2006-05-01' );
    is( $tmp->rec_id, 1007 );
    is( $tmp->previous_date_limit, '2005-05-04' );
    is( $tmp->next_date_limit, undef );

        $tmp = $CLASS->get_by_client( 1002, '2006-05-01' );
    is( $tmp->rec_id, 1008 );
    is( $tmp->previous_date_limit, '2005-03-17' );
    is( $tmp->next_date_limit, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dates, arbitrary
    # intake
        $tmp = $CLASS->get_by_client( 1001, '2005-05-04' );
    is( $tmp->rec_id, 1001 );
    is( $tmp->previous_date_limit, undef );
    is( $tmp->next_date_limit, '2006-03-15' );

        $tmp = $CLASS->get_by_client( 1002, '2005-03-17' );
    is( $tmp->rec_id, 1002 );
    is( $tmp->previous_date_limit, undef );
    is( $tmp->next_date_limit, '2006-01-05' );

        $tmp = $CLASS->get_by_client( 1003, '2005-03-05' );
    is( $tmp->rec_id, 1003 );
    is( $tmp->previous_date_limit, undef );
    is( $tmp->next_date_limit, '2005-03-17' );

    # change
        $tmp = $CLASS->get_by_client( 1003, '2005-05-05' );
    is( $tmp->rec_id, 1013 );
    is( $tmp->previous_date_limit, '2005-03-01' );
    is( $tmp->next_date_limit, undef );

        $tmp = $CLASS->get_by_client( 1003, '2005-03-31' );
    is( $tmp->rec_id, 1012 );
    is( $tmp->previous_date_limit, '2005-03-01' );
    is( $tmp->next_date_limit, undef );

    # discharge
        $tmp = $CLASS->get_by_client( 1004, '2006-01-15' );
    is( $tmp->rec_id, 1014 );
    is( $tmp->previous_date_limit, '2005-04-06' );
    is( $tmp->next_date_limit, '2006-03-06' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->delete_( $CLASS, '*' );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

