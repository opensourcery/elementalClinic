# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 40;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one, $tmp, $count);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Diagnosis';
    use_ok( $CLASS );
    $CLASSDATA = $client_diagnosis;
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
    is( $one->table, 'client_diagnosis');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id diagnosis_date
        diagnosis_1a diagnosis_1b diagnosis_1c
        diagnosis_2a diagnosis_2b diagnosis_3
        diagnosis_4 diagnosis_5_highest
        diagnosis_5_current comment_text
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# code
    can_ok( $one, 'code' );
    is( $one->code, undef );
    is( $one->code( '1a' ), undef );
    is( $one->code( '1b' ), undef );
    is( $one->code( '1c' ), undef );
    is( $one->code( '2a' ), undef );
    is( $one->code( '2b' ), undef );
    throws_ok{ $one->code( '3' )} qr/Invalid diagnosis type/;
    throws_ok{ $one->code( '4' )} qr/Invalid diagnosis type/;
    throws_ok{ $one->code( '666' )} qr/Invalid diagnosis type/;

    is( $CLASS->retrieve( 1001 )->code( '1a' ), '296.80' );
    is( $CLASS->retrieve( 1001 )->code( '1b' ), '295.14' );
    is( $CLASS->retrieve( 1001 )->code( '1c' ), '295.12' );
    is( $CLASS->retrieve( 1001 )->code( '2a' ), '301.90' );
    is( $CLASS->retrieve( 1001 )->code( '2b' ), '301.20' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_current_byclient
    can_ok( $one, 'get_current_byclient' );
    is( $CLASS->get_current_byclient, undef);
    is( $CLASS->get_current_byclient( 6666 ), undef);
    is_deeply( $CLASS->get_current_byclient( 1003 ), $CLASSDATA->{ 1002 } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_byclient
    can_ok( $one, 'get_byclient' );
    is( $one->get_byclient, undef );
    is( $one->get_byclient( 6666 ), undef );
    is_deeply( $one->get_byclient( 1003 ), [
        $CLASSDATA->{ 1002 },
        $CLASSDATA->{ 1001 },
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clone
    can_ok( $one, 'clone' );

    is( $one->clone, undef );

    # clone with an id passed in
        $count = scalar keys %{ $CLASSDATA };
    is( $test->select_count( $CLASS->table ), $count );
    ok( $tmp = $one->clone( 1001 ) ); 

        $tmp = $CLASS->new({ rec_id => $tmp })->retrieve;
        $tmp->rec_id( 1001 );
    is_deeply( $tmp, $CLASSDATA->{ 1001 } );

        $count++;
    is( $test->select_count( $CLASS->table ), $count );

    # clone with an id in the object
        $one->rec_id( 1001 );
    ok( $tmp = $one->clone );

        $tmp = $CLASS->new({ rec_id => $tmp })->retrieve;
        $tmp->rec_id( 1001 );
    is_deeply( $tmp, $CLASSDATA->{ 1001 } );

        $count++;
    is( $test->select_count( $CLASS->table ), $count );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->delete_( $CLASS, '*' );
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
