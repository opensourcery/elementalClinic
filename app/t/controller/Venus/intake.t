# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More skip_all => 'broken'; #tests => 39;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Venus::Intake';
    require_ok( 'themes/Venus/controllers/Intake.pm' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runmodes
    can_ok( $CLASS, 'ops' );
    ok( my %ops = $CLASS->ops );
    is_deeply( [ sort keys %ops ], [ sort qw/
        home intake reactivate activate_home 
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home intake reactivate activate_home program_id
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ok( $one->home ); #Can we test this further?

    $one = $CLASS->new_with_cgi_params(
        op => 'intake',
    );
    #If something is missing it should display home again.
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ) );
    is( $one->intake, $one->home );
    ok( $one->errors );

    $one = $CLASS->new_with_cgi_params(
        fname => 'bob',
        #lname => 'Marley', removed to cause error
        ssn => '555-55-5556',
        dob => '2008-1-14', 
        event_date => '2008-01-24',
        intake_type => 'Admission',
        admission_program_id => 1001,
        referral_program_id => 1,
        staff_id => 1005,
        level_of_care_id => 1002,
        submit => 'Add client',
        op => 'intake',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ) );

    #For home to display what we want it needs the same variables that intake.pm passes to it on error.
    my $vars = $one->Vars;
    $vars->{ ssn_f } = $vars->{ ssn };
    is( $one->intake, $one->home( $vars ));
    ok( $one->errors ); 

    #Do it properly this time.
    $one = $CLASS->new_with_cgi_params(
        fname => 'bob',
        lname => 'Marley',
        ssn => '555-55-5556',
        dob => '2008-1-14',
        event_date => '2008-01-24',
        intake_type => 'Admission',
        admission_program_id => 1001,
        referral_program_id => 1,
        staff_id => 1005,
        level_of_care_id => 1002,
        submit => 'Add client',
        op => 'intake',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ) );
    ok( $one->intake );
    ok( not $one->errors ); 

    TODO:{
    local $TODO="Currently the object is created even if a required field is missing. This might be the correct behavior.";
    ok( not eleMentalClinic::Client->get_one_by_( 'lname', 'Marley' )); #Make sure the object was not created improperly
    }

    #Make sure the client object was created.
    is_deeply_except( 
        { 
            client_id => qr/^\d+$/, 
            #intake initilizes these as '0' wheras new() leaves them undef.
            has_declaration_of_mh_treatment => '', 
            section_eight => '',
        },
        eleMentalClinic::Client->get_one_by_( 'lname', 'Marley' ),
        eleMentalClinic::Client->new({
            fname => 'bob',
            lname => 'Marley',
            ssn => 555555556,
            dob => '2008-01-14',
            event_date => '2008-01-24',
            admission_program_id => 1001,
            referral_program_id => 1,
            staff_id => 1005,
            level_of_care_id => 1002,
        })
    );      

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    my $client = eleMentalClinic::Client->get_one_by_( 'lname', 'Marley' );

    #Set some bogus values for now.
    my %placement = ();
    $placement{ level_of_care_id } = 3000
        if defined $one->param( 'level_of_care_id' );
    $placement{ staff_id } = 3000
        if defined $one->param( 'staff_id' );
    $client->placement->change(
        dept_id            => 3000,
        program_id         => 3000,
        event_date         => '1855-06-23',
        input_by_staff_id  => 3000,
        is_intake          => 0,
        active             => 0,
        %placement,
    );

    ok( $one->activate_home( $client ) );
    $client = eleMentalClinic::Client->get_one_by_( 'lname', 'Marley' );

    is( $client->placement->dept_id, 1001 );
    is( $client->placement->program_id, 1001 );
    is( $client->placement->event_date, '2008-01-24' );
    is( $client->placement->input_by_staff_id, 1001 );
    ok( $client->placement->is_intake );
    ok( $client->placement->active );
    is( $client->placement->level_of_care_id, 1002 );
    is( $client->placement->staff_id, 1005 );

    is_deeply_except( 
        { 
            client_id => qr/^\d+$/, 
            #intake initilizes these as '0' wheras new() leaves them undef.
            has_declaration_of_mh_treatment => '', 
            section_eight => '',
        },
        eleMentalClinic::Client->get_one_by_( 'lname', 'Marley' ),
        eleMentalClinic::Client->new({
            fname => 'bob',
            lname => 'Marley',
            ssn => 555555556,
            dob => '2008-01-14',
            event_date => '2008-01-24',
            admission_program_id => 1001,
            referral_program_id => 1,
            staff_id => 1005,
            level_of_care_id => 1002,
        })
    );      

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    $client->placement->change(
        active => 0,
    );

    ok( $one->reactivate );

    $client = eleMentalClinic::Client->get_one_by_( 'lname', 'Marley' );
    ok( $client->placement->active );

dbinit();
