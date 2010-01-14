# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 24;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Log::Access';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}

dbinit( 1 );

# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'access_log' );
    is( $one->primary_key, 'rec_id' );
    is_deeply( $one->fields, [qw/
        rec_id logged from_session object_id object_type staff_id
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    $one = $CLASS->new;
    ok( $one->update_from_log({
        user => undef,
        action => 'load',
        object => eleMentalClinic::Personnel->retrieve( 1001 ),
    }), "Update from log");
    ok( $one->rec_id, "saved" );
    ok( $one = $CLASS->retrieve( $one->rec_id ), "reload");
    is( $one->staff_id, undef, "no user" );
    ok( $one->logged, "Timestamp" );
    is( $one->object_type, 'eleMentalClinic::Personnel', "object type" );
    is( $one->object_id, 1001, "object id" );
    is( $one->from_session, undef, "not from session" );

    $one = $CLASS->new;
    ok( $one->update_from_log({
        user => eleMentalClinic::Personnel->retrieve( 1001 ),
        action => 'reload',
        object => eleMentalClinic::Client->retrieve( 1002 ),
    }), "Update from log");
    ok( $one->rec_id, "saved" );
    ok( $one = $CLASS->retrieve( $one->rec_id ), "reload");
    is( $one->staff_id, 1001, "user" );
    ok( $one->logged, "Timestamp" );
    is( $one->object_type, 'eleMentalClinic::Client', "object type" );
    is( $one->object_id, 1002, "object id" );
    is( $one->from_session, 1, "from session" );

dbinit( );
