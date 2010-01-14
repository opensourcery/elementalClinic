# vim: ts=4 sts=4 sw=4
# Copyright (C) 2004-2009 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 21;
use Test::Exception;
use eleMentalClinic::Test;
use Data::Dumper;

our ($CLASS, $one, $tmp);

BEGIN {
    *CLASS = \'eleMentalClinic::Role::DirectMember';
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
    is( $one->table, 'direct_role_member');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/ rec_id role_id member_id /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ));

    can_ok( $CLASS, @{ $CLASS->fields }, 'role', 'member', '_real' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->new({ role_id => 1, member_id => 2 });

    is( $one->role_id, 1, "Correct role_id" );
    isa_ok( $one->role, 'eleMentalClinic::Role', "role() returns a role" );
    is( $one->role->id, 1, "Correct role_id" );

    is( $one->member_id, 2, "Correct member_id" );
    isa_ok( $one->member, 'eleMentalClinic::Role', "member() returns a role" );
    is( $one->member->id, 2, "Correct member_id" );

    dies_ok { $CLASS->new({ role_id => 1, member_id => 2 })->save }
        "Recursive Membership is not allowed";
    like( $@, qr/Recursive Membership/i, "Correct Error" );

    dbinit( 1 );
    lives_ok { $CLASS->new({ role_id => 1, member_id => 1012 })->save }
        "Save";

    dies_ok { $CLASS->new({ role_id => 1, member_id => 1012 })->save }
        "Can not save duplicate membership";

    ok( $tmp = $CLASS->get_all, "Can get all" );
    ok( @$tmp, "At least one" );

dbinit( 0 );
