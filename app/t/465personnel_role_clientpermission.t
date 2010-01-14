# vim: ts=4 sts=4 sw=4
# Copyright (C) 2004-2009 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 18;
use Test::Exception;
use Test::Warn;
use eleMentalClinic::Test;
use Data::Dumper;

our ($CLASS, $one, $tmp);

BEGIN {
    *CLASS = \'eleMentalClinic::Role::ClientPermission';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'client_permission');
    is( $one->primary_key, undef, "no primary key");
    is_deeply( $one->fields, [qw/ role_id client_id /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

    can_ok( $CLASS, @{ $CLASS->fields }, 'role', 'client' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->new({ role_id => 1, client_id => 1001 });

    is( $one->role_id, 1, "Correct role_id" );
    isa_ok( $one->role, 'eleMentalClinic::Role', "role() returns a role" );
    is( $one->role->id, 1, "Correct role_id" );

    is( $one->client_id, 1001, "Correct client_id" );
    isa_ok( $one->client, 'eleMentalClinic::Client', "client() returns a client" );
    is( $one->client->id, 1001, "Correct client_id" );

    dies_ok { $CLASS->new({ role_id => 1, client_id => 1001 })->save }
        "Can not save permission";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    ok( $tmp = $CLASS->get_all, "Can get all" );
    ok( @$tmp, "At least one" );


dbinit( 0 );
