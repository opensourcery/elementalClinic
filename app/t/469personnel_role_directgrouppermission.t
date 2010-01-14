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
    *CLASS = \'eleMentalClinic::Role::DirectGroupPermission';
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
    is( $one->table, 'direct_group_permission');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/ rec_id role_id group_id /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

    can_ok( $CLASS, @{ $CLASS->fields }, 'role', 'group' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->new({ role_id => 1, group_id => 1001 });

    is( $one->role_id, 1, "Correct role_id" );
    isa_ok( $one->role, 'eleMentalClinic::Role', "role() returns a role" );
    is( $one->role->id, 1, "Correct role_id" );

    is( $one->group_id, 1001, "Correct group_id" );
    isa_ok( $one->group, 'eleMentalClinic::Group', "group() returns a group" );
    is( $one->group->id, 1001, "Correct group_id" );


    ok( $tmp = $CLASS->get_all, "Can get all" );
    ok( @$tmp, "At least one" );

    dies_ok { $CLASS->new({ role_id => 1, group_id => 1001 })->save }
        "Can not save duplicate permission";

dbinit( 0 );
