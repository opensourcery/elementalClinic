# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 55;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::CGI::GroupCGI';
    use_ok( $CLASS );
}

sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}

dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate_group_filter

    is( $one->validate_group_filter( 'active' ), 'active' );
    is( $one->validate_group_filter( 'inactive' ), 'inactive' );
    is( $one->validate_group_filter( 'all' ), 'all' );
    is( $one->validate_group_filter( 'FaKe' ), 'all' );
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# group_filter

    $one = $CLASS->new;
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1 ) );
    #Clear any preferences that may have been saved in other tests
    $one->current_user->pref->group_filter( '' );
    $one->current_user->pref->save;
    is( $one->group_filter, 'active' );
dbinit( 1 );


    $test->setup_cgi(
        group_filter => 'inactive',
    );
    $one = $CLASS->new;
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1 ) );
    is( $one->group_filter, 'inactive' );
dbinit( 1 );

    $test->setup_cgi(
        group_filter => 'all',
    );
    $one = $CLASS->new;
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1 ) );
    is( $one->group_filter, 'all' );
dbinit( 1 );

    $test->setup_cgi(
        group_filter => 'active',
    );
    $one = $CLASS->new;
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1 ) );
    is( $one->group_filter, 'active' );
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_group

    $test->setup_cgi(
        group_id    => 1001,
    );
    $one = $CLASS->new;
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1 ) );
    is_deeply( $one->get_group, eleMentalClinic::Group->retrieve( 1001 ) );
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# showing_active_groups

    $one = $CLASS->new;
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1 ) );
    $one->group_filter( 'active' );
    ok( $one->showing_active_groups );
    ok( not $one->showing_inactive_groups );
    ok( not $one->showing_all_groups );
    #showing_active_groups false should be a 0 and not undefined,
    #showing_active_groups true should be a 1.
    #This behavior is to make DB query's using the active
    #filter easier to read.
    is( $one->showing_active_groups, 1 );
    is( $one->showing_inactive_groups, 0 );
    is( $one->showing_all_groups, 0 );
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# showing_inactive_groups

    $one = $CLASS->new;
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1 ) );
    $one->group_filter( 'inactive' );
    ok( not $one->showing_active_groups );
    ok( $one->showing_inactive_groups );
    ok( not $one->showing_all_groups );
    #showing_inactive_groups false should be a 0 and not undefined,
    #showing_inactive_groups true should be a 1.
    #This behavior is to make DB query's using the active
    #filter easier to read.
    is( $one->showing_active_groups, 0 );
    is( $one->showing_inactive_groups, 1 );
    is( $one->showing_all_groups, 0 );
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# showing_all_groups

    $one = $CLASS->new;
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1 ) );
    $one->group_filter( 'all' );
    ok( $one->showing_active_groups );
    ok( $one->showing_inactive_groups );
    ok( $one->showing_all_groups );
    #showing_all_groups false should be a 0 and not undefined,
    #showing_all_groups true should be a 1.
    #This behavior is to make DB query's using the active
    #filter easier to read.
    is( $one->showing_active_groups, 1 );
    is( $one->showing_inactive_groups, 1 );
    is( $one->showing_all_groups, 1 );
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in_group_filter

    $one = $CLASS->new;
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1 ) );

    ####Check active filter####

    $one->group_filter( 'active' );
    #Active groups should return true
    ok( $one->in_group_filter( 1001 ));
    ok( $one->in_group_filter( 1002 ));
    ok( $one->in_group_filter( 1003 ));

    #True Return should be the groups number.
    is( $one->in_group_filter( 1001 ), 1001 );
    is( $one->in_group_filter( 1002 ), 1002 );
    is( $one->in_group_filter( 1003 ), 1003 );

    #Inactive groups should return false;
    ok( not $one->in_group_filter( 1004 ));
    ok( not $one->in_group_filter( 1005 ));
    ok( not $one->in_group_filter( 1006 ));

    ####Check inactive filter####

    $one->group_filter( 'inactive' );
    #Active groups should return false
    ok( not $one->in_group_filter( 1001 ));
    ok( not $one->in_group_filter( 1002 ));
    ok( not $one->in_group_filter( 1003 ));

    #Inactive groups should return true;
    ok( $one->in_group_filter( 1004 ));
    ok( $one->in_group_filter( 1005 ));
    ok( $one->in_group_filter( 1006 ));

    #True Return should be the groups number.
    is( $one->in_group_filter( 1004 ), 1004 );
    is( $one->in_group_filter( 1005 ), 1005 );
    is( $one->in_group_filter( 1006 ), 1006 );

    ####Check all filter####

    $one->group_filter( 'all' );
    #All groups should return true
    ok( $one->in_group_filter( 1001 ));
    ok( $one->in_group_filter( 1002 ));
    ok( $one->in_group_filter( 1003 ));
    ok( $one->in_group_filter( 1004 ));
    ok( $one->in_group_filter( 1005 ));
    ok( $one->in_group_filter( 1006 ));
dbinit(  );
    

    
