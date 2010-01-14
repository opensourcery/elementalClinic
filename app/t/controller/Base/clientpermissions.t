# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 15;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, $c );
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::ClientPermissions';
    use_ok( q/eleMentalClinic::Controller::Base::ClientPermissions/ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new, '$one = $CLASS->new' );
    ok( defined( $one ), '$one is defined' );
    ok( $one->isa( $CLASS ), '$one isa $CLASS' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runmodes
    can_ok( $CLASS, 'ops', );
    ok( my %ops = $CLASS->ops, 'assign %ops to $CLASS->ops' );
    is_deeply( [ sort keys %ops ], [ sort qw/ home add remove /], 'ops are correct');
    can_ok( $CLASS, qw/ home add remove / );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    my $client = eleMentalClinic::Client->retrieve( 1001 );
    my $personnel = eleMentalClinic::Personnel->retrieve( 1 );

    $personnel->primary_role->grant_client_permission( $client );

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,
    );

    $personnel->primary_role->revoke_client_permission( $client );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,
    );

    is_deeply(
        $one->home,
        {
            permissions => $one->client->access,
            unassociated => $one->unassociated,
        },
        "Home returns proper data structure"
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok(( grep { $_->{ staff_id } == 1 } @{ $one->unassociated } ), "user 1 appears in unassociated list");

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,
        staff_id => $personnel->id,
        op => 'add'
    );
    $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1 );

    is_deeply(
        $one->add,
        $one->home,
        "Add works and returns home"
    );

    ok(!( grep { $_->{ staff_id } == 1 } @{ $one->unassociated } ), "user 1 no longer appears in unassociated list");

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,
        staff_id => $personnel->id,
        op => 'remove'
    );
    $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1 );

    is_deeply(
        $one->remove,
        $one->home,
        "Remove works and returns home"
    );

    ok(( grep { $_->{ staff_id } == 1 } @{ $one->unassociated } ), "user 1 appears in unassociated list again");

    is_deeply( $one->personnel, $personnel, "retrieved personnel" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
