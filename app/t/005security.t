# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 11;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Log::Security';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}

dbinit( 1 );

    $one = $CLASS->new;
    ok( $one->update_from_log({
        user => 'bob',
        action => 'failure',
    }), "Update from log");
    ok( $one->rec_id, "was saved" );
    $one = $CLASS->retrieve( $one->rec_id );
    ok( $one->logged, "has datestamp" );
    is( $one->action, 'failure', "Correct action" );
    is( $one->login, 'bob' );

    $one = $CLASS->new;
    ok( $one->update_from_log({
        user => eleMentalClinic::Personnel->retrieve( 1000 ),
        action => 'login',
    }), "Update from log");
    ok( $one->rec_id, "was saved" );
    $one = $CLASS->retrieve( $one->rec_id );
    ok( $one->logged, "has datestamp" );
    is( $one->action, 'login', "Correct action" );
    is( $one->login, 'clinic' );

dbinit( );
