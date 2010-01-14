# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 50;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Groups';
    use_ok( q/eleMentalClinic::Controller::Base::Groups/ );
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
    my @oplist = qw/
        home
        grant_access
        group_edit
        group_save
        group_create
        members_edit
        member_add
        member_remove
        group_status
        caseload_pref
        client_history
        revoke_access
    /;
    #Make sure the same list is available
    is_deeply( [ sort keys %ops ], [ sort @oplist ]);

    #Make sure the controller has each method
    can_ok( $CLASS, $_ ) for @oplist;

    #Make sure each method runs
    ok( $CLASS, $_ ) for @oplist;

    #Make sure it all works w/ cgi params
    for ( @oplist ) {
        $one = $CLASS->new_with_cgi_params(
            op => $_,
        );
        ok( $one->isa( $CLASS ));
    }
   
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_groups

    $one = $CLASS->new_with_cgi_params(
        op          => 'home',
        group_filter => 'all',
    );
    $one->session->param( 'user_id', 1 );
    is_deeply( 
        $one->get_groups, 
        eleMentalClinic::Group->new->get_all,
    );

    #Bad value should show all to ensure what they are looking for is on the list.
    $one = $CLASS->new_with_cgi_params(
        op          => 'home',
        group_filter => 'FAKE',
    );
    $one->session->param( 'user_id', 1 );
    is_deeply( 
        $one->get_groups, 
        eleMentalClinic::Group->new->get_all,
    );

    $one = $CLASS->new_with_cgi_params(
        op          => 'home',
        group_filter => 'active',
    );
    $one->session->param( 'user_id', 1 );
    is_deeply( 
        $one->get_groups, 
        eleMentalClinic::Group->new->get_by_( 'active', 1, 'name', 'ASC' ),
    );

    #Check default
    $one = $CLASS->new_with_cgi_params(
        op          => 'home',
        group_filter => '',
    );
    $one->session->param( 'user_id', 1 );
    is_deeply( 
        $one->get_groups, 
        eleMentalClinic::Group->new->get_by_( 'active', 1, 'name', 'ASC' ),
    );

    $one = $CLASS->new_with_cgi_params(
        op          => 'home',
        group_filter => 'inactive',
    );
    $one->session->param( 'user_id', 1 );
    is_deeply( 
        $one->get_groups, 
        eleMentalClinic::Group->new->get_by_( 'active', '0', 'name', 'ASC' ),
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Group active status change
    $one = $CLASS->new_with_cgi_params(
        op              => 'Apply Status Changes',
        group_id        => '1001',
        group_active    => '0',
    );
    ok( not eleMentalClinic::Group->retrieve( 1001 )->active, '0' );
    $one = $CLASS->new_with_cgi_params(
        op              => 'Apply Status Changes',
        group_id        => '1001',
        group_active    => '1',
    );
    is( eleMentalClinic::Group->retrieve( 1001 )->active, '1' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
