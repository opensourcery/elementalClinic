# vim: ts=4 sts=4 sw=4
# Copyright (C) 2004-2009 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 25;
use Test::Exception;
use Test::Warn;
use eleMentalClinic::Test;
use Data::Dumper;

our ($CLASS, $one, $tmp);

BEGIN {
    *CLASS = \'eleMentalClinic::Role::Access';
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
    is( $one->table, 'client_user_role_map');
    is( $one->primary_key, undef);
    is_deeply( $one->fields, [qw/ role_id client_id reason id staff_id /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

    can_ok( $CLASS, @{ $CLASS->fields } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->get_all->[0];
    isa_ok( $one->role, 'eleMentalClinic::Role' );
    isa_ok( $one->client, 'eleMentalClinic::Client' );
    isa_ok( $one->staff, 'eleMentalClinic::Personnel' );
    is( $one->id, $one->{ id }, "id remapped" );

    $one = $CLASS->get_one_by_( reason => 'direct' );
    is( $one->reason, 'direct', "Got direct access" );
    is( $one->reason_name, 'Direct Access', "reason name - direct" );
    isa_ok( $one->fetch_reason, 'eleMentalClinic::Role::DirectClientPermission' );

    $one = $CLASS->get_one_by_( reason => 'membership' );
    is( $one->reason, 'membership', "Got Membership" );
    isa_ok( $one->fetch_reason, 'eleMentalClinic::Role' );
    is(
        $one->reason_name,
        "Role Membership (" . $one->fetch_reason->name . ")",
        "reason name - membership"
    );

    $one = $CLASS->get_one_by_( reason => 'group' );
    is( $one->reason, 'group', "Got group" );
    isa_ok( $one->fetch_reason, 'eleMentalClinic::Group' );
    my $want_name = $one->fetch_reason->name;
    $want_name =~ s/\s*group\s*$//;
    is(
        $one->reason_name,
        "Writer ($want_name)",
        "reason name - group"
    );

    $one = $CLASS->get_one_by_( reason => 'coordinator' );
    is( $one->reason, 'coordinator', "Got coordinator" );
    isa_ok( $one->fetch_reason, 'eleMentalClinic::Client::Placement::Event' );
    is(
        $one->reason_name,
        "Service Coordinator (" . $one->fetch_reason->event_date . ")",
        "reason name - Coordinator"
    );

dbinit( 0 );
