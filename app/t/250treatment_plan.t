# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 132;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::TreatmentPlan';
    use_ok( $CLASS );
    $CLASSDATA = $tx_plan;
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
    is( $one->table, 'tx_plan');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        client_id chart_id staff_id rec_id start_date end_date period esof_id
        esof_date esof_name esof_note assets debits case_worker src_worker
        supervisor meets_dsm4 needs_selfcare needs_skills needs_support
        needs_adl needs_focus active
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    $one->rec_id( 1001 )->retrieve;
    is_deeply( $one, $CLASSDATA->{ 1001 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clone
    can_ok( $one, 'clone' );
    ok( $tmp = $one->clone );
    
        verify_plan( $one, $tmp );
    ok( $tmp->rec_id );
    like( $tmp->rec_id, qr/^\d+$/, $tmp->rec_id .' should be unique' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clone with goals
    is_deeply( $one->goals, [
        $tx_goals->{ 1002 },
        $tx_goals->{ 1001 },
    ]);

    ok( $tmp = $one->clone( [ qw/ 1001 /]));
    verify_plan( $one, $tmp );
    ok( $tmp->goals );
    verify_goal( @{ $tmp->goals }[ 0 ], @{ $one->goals }[ 1 ]);

    ok( $tmp = $one->clone( [ qw/ 1001 1002 /]));
        verify_plan( $one, $tmp );
    ok( $tmp->goals );
    verify_goal( @{ $tmp->goals }[ 0 ], @{ $one->goals }[ 0 ]);
    verify_goal( @{ $tmp->goals }[ 1 ], @{ $one->goals }[ 1 ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub verify_plan {
    my( $a, $b ) = @_;

    for my $field( qw/
        client_id chart_id staff_id start_date end_date esof_id
        esof_date esof_name esof_note assets debits case_worker src_worker
        supervisor meets_dsm4 needs_selfcare needs_skills needs_support
        needs_adl needs_focus active
    /) {
        is( $a->$field, $b->$field, $field );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub verify_goal {
    my( $a, $b ) = @_;

    for my $field( qw/
        client_id staff_id problem_description medicaid
        start_date end_date goal goal_stat goal_header eval comment_text
        goal_code rstat serv audit_trail goal_name active
    /) {
        is( $a->$field, $b->$field, $field );
    }
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->delete_( 'tx_goals', '*' );
        $test->delete_( $CLASS, '*' );
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


