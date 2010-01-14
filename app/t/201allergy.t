# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 26;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Allergy';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;

        $test->insert_data([
            'eleMentalClinic::Client',
            $CLASS,
        ]);
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'client_allergy');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id allergy created active
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# qualified fields
    can_ok( $one, 'fields_qualified' );
    is( $CLASS->fields_qualified, 'client_allergy.rec_id, client_allergy.client_id, client_allergy.allergy, client_allergy.created, client_allergy.active' );
    is( $one->fields_qualified, 'client_allergy.rec_id, client_allergy.client_id, client_allergy.allergy, client_allergy.created, client_allergy.active' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_byclient, get_byclient
    can_ok( $CLASS, 'list_byclient', 'get_byclient' );
    is( $CLASS->list_byclient, undef );
    is( $CLASS->list_byclient( 6666 ), undef );

    is( $CLASS->get_byclient, undef );
    is( $CLASS->get_byclient( 6666 ), undef );

    # list_byclient
    is_deeply( $CLASS->list_byclient( 1001 ), [
        $client_allergy->{ 1002 },
        $client_allergy->{ 1001 },
    ] );

    is_deeply( $CLASS->list_byclient( 1002 ), [
        $client_allergy->{ 1003 },
    ] );

    is( $CLASS->list_byclient( 6666 ), undef );

    # active flag
    is_deeply( $CLASS->list_byclient( 1001, 0 ), [
        $client_allergy->{ 1001 },
    ] );

    is_deeply( $CLASS->list_byclient( 1002, 0 ), [
        $client_allergy->{ 1003 },
    ] );

    is_deeply( $CLASS->list_byclient( 1001, 1 ), [
        $client_allergy->{ 1002 },
    ] );

    is( $CLASS->list_byclient( 1002, 1 ), undef );

    is( $CLASS->list_byclient( 1001, 2 ), undef );
    is( $CLASS->list_byclient( 1002, 2 ), undef );

    # get_byclient
    isa_ok( $CLASS->get_byclient( 1001 )->[0], $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
