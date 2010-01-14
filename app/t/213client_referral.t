# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 26;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Department;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Referral';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;

        $test->insert_data;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'client_referral');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [ qw/
        rec_id client_id rolodex_referral_id
        agency_contact agency_type active
        client_placement_event_id
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# placement_event
    can_ok( $one, 'placement_event' );
    is( $one->placement_event, undef );

    ok( $one->client_placement_event_id( 666 ));
    is( $one->placement_event, undef );

    ok( $one->client_placement_event_id( 1001 ));
    is_deeply( $one->placement_event, $client_placement_event->{ 1001 });

        $one = $CLASS->new({ rec_id => 1003 })->retrieve;
    is( $one->placement_event, undef );
        $one = $CLASS->new({ rec_id => 1001 })->retrieve;
    is_deeply( $one->placement_event, $client_placement_event->{ 1003 });
        $one = $CLASS->new({ rec_id => 1002 })->retrieve;
    is_deeply( $one->placement_event, $client_placement_event->{ 1005 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_by_placement_event
        $one = $CLASS->new;
    can_ok( $one, 'get_by_placement_event_id' );

    is( $one->get_by_placement_event_id, undef );
    is( $CLASS->get_by_placement_event_id, undef );

    is( $CLASS->get_by_placement_event_id( 1001 ), undef );
    isa_ok( $CLASS->get_by_placement_event_id( 1003 ), $CLASS );
    is_deeply( $CLASS->get_by_placement_event_id( 1003 ), $client_referral->{ 1001 });
    isa_ok( $CLASS->get_by_placement_event_id( 1005 ), $CLASS );
    is_deeply( $CLASS->get_by_placement_event_id( 1005 ), $client_referral->{ 1002 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex
    can_ok( $one, 'rolodex' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
