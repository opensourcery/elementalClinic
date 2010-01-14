# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 40;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Discharge';
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
    is( $one->table, 'client_discharge');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id chart_id staff_name physician
        initial_diag_id final_diag_id admit_note history_clinical
        history_psych history_medical discharge_note after_care addr
        addr_2 city state post_code phone ref_agency ref_cont ref_date
        sent_summary sent_psycho_social sent_mental_stat sent_tx_plan
        sent_other sent_to sent_physical esof_id esof_date esof_name
        esof_note last_contact_date termination_notice_sent_date
        client_contests_termination education income employment_status
        employability_factor criminal_justice termination_reason
        audit_trail committed
        client_placement_event_id
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# placement_event
    can_ok( $one, 'placement_event' );
    is( $one->placement_event, undef );

    ok( $one->client_placement_event_id( 666 ));
    is( $one->placement_event, undef );

    ok( $one->client_placement_event_id( 1001 ));
    isa_ok( $one->placement_event, 'eleMentalClinic::Client::Placement::Event' );
    is_deeply( $one->placement_event, $client_placement_event->{ 1001 });

        $one = $CLASS->new({ rec_id => 1003 })->retrieve;
    is_deeply( $one->placement_event, $client_placement_event->{ 1014 });
        $one = $CLASS->new({ rec_id => 1001 })->retrieve;
    is_deeply( $one->placement_event, $client_placement_event->{ 1007 });
        $one = $CLASS->new({ rec_id => 1002 })->retrieve;
    is_deeply( $one->placement_event, $client_placement_event->{ 1008 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_by_placement_event
        $one = $CLASS->new;
    can_ok( $one, 'get_by_placement_event_id' );

    is( $one->get_by_placement_event_id, undef );
    is( $CLASS->get_by_placement_event_id, undef );

    is( $CLASS->get_by_placement_event_id( 1001 ), undef );
    isa_ok( $CLASS->get_by_placement_event_id( 1007 ), $CLASS );
    is_deeply( $CLASS->get_by_placement_event_id( 1007 ), $client_discharge->{ 1001 });
    isa_ok( $CLASS->get_by_placement_event_id( 1008 ), $CLASS );
    is_deeply( $CLASS->get_by_placement_event_id( 1008 ), $client_discharge->{ 1002 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# initial, final diagnosis
        $one = $CLASS->new;
    can_ok( $one, 'initial_diagnosis' );
    can_ok( $one, 'final_diagnosis' );
    is( $one->initial_diagnosis, undef );
    is( $one->final_diagnosis, undef );

        $one->rec_id( 1001 )->retrieve;
    is( $one->initial_diag_id, 1003 );
    is_deeply( $one->initial_diagnosis, $client_diagnosis->{ 1003 });
    is( $one->final_diag_id, 1004 );
    is_deeply( $one->final_diagnosis, $client_diagnosis->{ 1004 });

        $one->rec_id( 1002 )->retrieve;
    is( $one->initial_diag_id, 1005 );
    is_deeply( $one->initial_diagnosis, $client_diagnosis->{ 1005 });
    is( $one->final_diagnosis, undef );

        $one->rec_id( 1003 )->retrieve;
    is( $one->initial_diag_id, 1006 );
    is_deeply( $one->initial_diagnosis, $client_diagnosis->{ 1006 });
    is( $one->final_diagnosis, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# final_diagnosis

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
