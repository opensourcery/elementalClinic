# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 8;
use Test::Exception;
use eleMentalClinic::Test;
use eleMentalClinic::Personnel;
use eleMentalClinic::Role;
use eleMentalClinic::Watchdog;

our ($CLASS, $one, $tmp, $client, $result, $rdx);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Intake';
    use_ok( q/eleMentalClinic::Controller::Base::Intake/ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step1

    my $user = eleMentalClinic::Personnel->retrieve( 1001 );
    eleMentalClinic::Role->admin_role->del_member( $user->primary_role );
    eleMentalClinic::Role->all_clients_role->del_member( $user->primary_role );
    ok( !eleMentalClinic::Role->all_clients_role->has_member( $user->primary_role ), "Creator of client is not super access" );

    # this is the test new client, with good data
    $client = {
        fname => 'Johnny',
        mname => 'Allen',
        lname => 'Hendrix',
        birth_name => 'Same',
        sex => 'Male',
        ssn => '121-33-4554',
        dob => '1942-11-22',
        client_id => undef,
    };
    ok( $one = $CLASS->new_with_cgi_params( op => 'step1_save', %$client ));
    $one->current_user( $user );

    ok( $result = $one->step1_save, "Saved" );
    my $client_id = $result->{ forward_args }[ 0 ]{ client_id };
    ok( $client_id, "Got client_id" );
    ok( $user->primary_role->has_client_permissions( $client_id ), "Creator of client can access client" );
    ok( $user->primary_role->has_direct_client_permissions( $client_id ), "Creator of client has direct access" );

    lives_ok {
        local $SIG{ __WARN__ } = sub { diag grep { $_ !~ m/(redefined)/ } @_ };
        $one = $CLASS->new;
        $one->{ cgi_object } = CGI->new({ op => 'step2', client_id => $client_id });

        my $watchdog = eleMentalClinic::Watchdog->new;
        $watchdog->controller_class( $CLASS );
        $watchdog->start();

        $one->current_user( $user );
        $one->step2;
    } "Don't die trying to go to step2 after creating client";
    diag $@ if $@;
