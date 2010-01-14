# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 13;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::IncomeMetadata';
    use_ok( $CLASS );
    $CLASSDATA = $client_income_metadata;
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
    is( $one->table, 'client_income_metadata');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id self_pay rep_payee
        bank_account css_id
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_byclient
    can_ok( $one, 'get_byclient' );

    is( $one->get_byclient, undef );

    is( $one->get_byclient( 6666 ), undef );

        $tmp = $one->get_byclient( 1004 );
    is_deeply( $tmp, $CLASSDATA->{ 1001 } );
    isa_ok( $tmp, $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
