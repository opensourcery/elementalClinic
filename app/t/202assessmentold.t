# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 75;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one, $tmp, $tmp_id, $count);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::AssessmentOld';
    use_ok( $CLASS );
    $CLASSDATA = $client_assessment_old;
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
    is( $one->table, 'client_assessment_old');
    is( $one->primary_key, 'rec_id');
    is_deeply( $CLASS->meta_fields, [ qw/
        rec_id client_id chart_id audit_trail
    /] );
    is_deeply( $CLASS->admit_fields, [ qw/
        admit_reason refer_reason social_environ esof_id
        esof_date esof_name esof_note start_date end_date staff_id
    /] );
    is_deeply( $CLASS->alert_fields, [ qw/
        danger_others danger_self chemical_abuse
        physical_abuse side_effects sharps_disposal
        special_diet alert_medical
        alert_other alert_note
    /] );
    is_deeply( $CLASS->develop_fields, [ qw/
        history_birth history_child history_milestone
        history_school history_social history_sexual
        history_dating
    /] );
    is_deeply( $CLASS->medical_fields, [ qw/
        medical_strengths medical_limits history_diag
        illness_past illness_family history_dental
        nutrition_needs
    /] );
    is_deeply( $CLASS->mental_fields, [ qw/
        appearance manner orientation functional mood
        affect mood_note relevant coherent tangential
        circumstantial blocking neologisms word_salad
        perseveration echolalia delusions hallucination
        suicidal homicidal obsessive thought_content
        psycho_motor speech_tone impulse_control
        speech_flow memory_recent memory_remote
        judgement insight intelligence
    /] );
    is_deeply( $CLASS->social_fields, [ qw/
        present_problem psych_history homeless_history
        social_portrait work_history social_skills
        mica_history social_strengths financial_status
        legal_status military_history spiritual_orient
    /] );

    is_deeply( $CLASS->fields, [
        @{ $CLASS->meta_fields },
        @{ $CLASS->admit_fields },
        @{ $CLASS->alert_fields },
        @{ $CLASS->develop_fields },
        @{ $CLASS->medical_fields },
        @{ $CLASS->mental_fields },
        @{ $CLASS->social_fields },
    ]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

    is_deeply( $CLASS->part_names, [ qw/
        admit alert develop medical mental social
    /] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    can_ok( $one, 'save' );

        $count = scalar keys %{ $CLASSDATA };
    is( $test->select_count( $CLASS->table ), $count );


    # save as insert
        $one->client_id( 1001 );
        $one->staff_id( 1001 );
    ok( $one->save );

        $count++;
    is( $test->select_count( $CLASS->table ), $count );

    # save as update
    is( $one->save, undef );
    is( $one->save( 'foo' ), undef );

        $one->social_environ( "Jimmy Mak's" );
        $one->client_id( 1002 );
    ok( $one->save( 'admit' ) );
    is( $test->select_count( $CLASS->table ), $count );

    # only attributes in that part get saved
        $one = $CLASS->new({ rec_id => $one->id })->retrieve;
    is( $one->social_environ, "Jimmy Mak's" );
    is( $one->client_id, 1001 );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
    can_ok( $one, 'get_all' );

    is( $one->get_all, undef );

    is( $one->get_all( 6666 ), undef );

        $tmp = $one->get_all( 1002 );
    is_deeply( $tmp, [
        $CLASSDATA->{ 1001 },
    ] );

        $one->client_id( 1002 );
    is_deeply( $one->get_all, $tmp );

    isa_ok( $_, $CLASS ) for @$tmp;

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_all
    can_ok( $one, 'list_all' );

    is( $one->list_all, undef );

    is( $one->list_all( 6666 ), undef );

        $tmp = $one->list_all( 1002 );
    is_deeply( $tmp, [
        $CLASSDATA->{ 1001 },
    ]);
    isa_ok( $_, 'HASH' ) for @$tmp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_staff_all
    can_ok( $one, 'get_staff_all' );

    is( $one->get_staff_all, undef );
    is( $one->get_staff_all( { staff_id => 666 } ), undef );

        $tmp = $one->get_staff_all( { staff_id => 1000 } );
    is_deeply( $tmp, [
        $CLASSDATA->{ 1001 },
    ]);
    
        $tmp = $one->get_staff_all( { staff_id => 1000, year_old => 1 } );
    is_deeply( $tmp, [
        $CLASSDATA->{ 1001 },
    ]);
    isa_ok( $_, 'HASH' ) for @$tmp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid_part
    can_ok( $one, 'valid_part' );

    is( $one->valid_part, undef );

    is( $one->valid_part( 'foo' ), 0 );

        $tmp = $one->part_names;
    is( $one->valid_part( $_ ), 1 ) for @$tmp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clone
    can_ok( $one, 'clone' );

    is( $one->clone, undef );

    # clone with an id passed in
    is( $test->select_count( $CLASS->table ), $count );
    ok( $tmp_id = $one->clone( 1001 ) ); 

        $tmp = $CLASS->new({ rec_id => $tmp_id })->retrieve;
        $tmp->rec_id( 1001 );
    is_deeply( $tmp, $CLASSDATA->{ 1001 } );

        $count++;
    is( $test->select_count( $CLASS->table ), $count );

    # clone with an id in the object
        $one->rec_id( 1001 );
    ok( $tmp_id = $one->clone );

        $tmp = $CLASS->new({ rec_id => $tmp_id })->retrieve;
    is( $tmp->rec_id, $tmp_id );

        $tmp->rec_id( 1001 );
    is_deeply( $tmp, $CLASSDATA->{ 1001 } );

        $count++;
    is( $test->select_count( $CLASS->table ), $count );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# active_alerts
        $tmp = $CLASS->new({ rec_id => $tmp_id })->retrieve;
    is( $tmp->rec_id, $tmp_id );
        $tmp->danger_self( "He's a madman" );
        $tmp->danger_others( 0 );
        $tmp->save( 'alert' );

    can_ok( $one, 'active_alerts' );

        #die Dumper $one->get_all(1002);
        $one = $one->get_all( 1002 )->[ 2 ];
    is( $one->rec_id, 1001 );
    is_deeply( $one->active_alerts, [ qw/
        chemical_abuse
        danger_others
        danger_self
        physical_abuse
    /]);

        $one = $one->get_all( 1002 )->[ 0 ];
    is( $one->rec_id, $tmp_id );
    is_deeply( $one->active_alerts, [ qw/
        chemical_abuse
        danger_self
        physical_abuse
    /]);

        $one = $one->get_all( 1002 )->[ 1 ];
    is( $one->rec_id, $tmp_id - 1 );
    is_deeply( $one->active_alerts, [ qw/
        chemical_abuse
        danger_others
        danger_self
        physical_abuse
    /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# active_alerts_labels
    can_ok( $one, 'active_alerts_labels' );

        $one = $one->get_all( 1002 )->[ 2 ];
    is( $one->rec_id, 1001 );
    is_deeply( $one->active_alerts_labels, [
        'Danger to others',
        'Danger to self',
        'Drug/alcohol abuse',
        'Physical/sexual abuse',
    ]);

        $one = $one->get_all( 1002 )->[ 0 ];
    is( $one->rec_id, $tmp_id );
    is_deeply( $one->active_alerts_labels, [
        'Danger to self',
        'Drug/alcohol abuse',
        'Physical/sexual abuse',
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->delete_( $CLASS, '*' );
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
