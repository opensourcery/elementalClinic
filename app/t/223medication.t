# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 24;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Medication';
    use_ok( $CLASS );
    $CLASSDATA = $client_medication;
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
    is( $one->table, 'client_medication');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id start_date end_date medication
        dosage frequency rolodex_treaters_id location
        inject_date instructions num_refills no_subs
        audit_trail quantity notes print_date print_header_id
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
    can_ok( $one, 'get_all' );

    is( $one->get_all, undef );

    is( $one->get_all({ client_id => 6666 }), undef );

    is( $one->get_all({
        client_id => 1003,
        start_date => '2005-05-31',
    }), undef );

        $tmp = $one->get_all({ client_id => 1003 });
    is_deeply( $tmp, [
        $CLASSDATA->{ 1001 },
        $CLASSDATA->{ 1002 },
    ] );
    isa_ok( $_, $CLASS ) for @$tmp;

        $one->client_id( 1003 );
    is_deeply( $one->get_all, $tmp );

        $tmp = $one->get_all({
                client_id => 1003,
                start_date => $CLASSDATA->{ 1001 }->{ start_date },
            });
    is_deeply( $tmp, [
        $CLASSDATA->{ 1001 },
    ] );

        $tmp = $one->get_all({
                client_id => 1003,
                end_date => $CLASSDATA->{ 1001 }->{ end_date },
            });
    is_deeply( $tmp, [
        $CLASSDATA->{ 1001 },
        $CLASSDATA->{ 1002 },
    ] );

        $tmp = $one->get_all({
                client_id => 1003,
                start_date => $CLASSDATA->{ 1001 }->{ start_date },
                end_date => $CLASSDATA->{ 1001 }->{ end_date },
            });
    is_deeply( $tmp, [
        $CLASSDATA->{ 1001 },
    ] );

        $tmp = $one->get_all({
                client_id => 1003,
                start_date => $CLASSDATA->{ 1001 }->{ start_date },
                end_date => $CLASSDATA->{ 1002 }->{ end_date },
            });
    is_deeply( $tmp, [
        $CLASSDATA->{ 1001 },
    ] );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# print_header
    can_ok( $one, 'print_header' );

    is( $one->print_header, undef );
    
        $one->print_header_id( 6666 );
    is( $one->print_header, undef );

        $one->print_header_id( 1 );
        $tmp = $test->db->do_sql( 'SELECT description FROM valid_data_print_header where rec_id = 1' )->[0]->{ description };
    is_deeply( $one->print_header, $tmp );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
