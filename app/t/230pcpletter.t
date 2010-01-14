# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 22;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Letter';
    use_ok( $CLASS );
    $CLASSDATA = $client_letter_history;
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
    is( $one->table, 'client_letter_history');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id rolodex_relationship_id letter_type 
        letter sent_date print_header_id relationship_role
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# history
    can_ok( $one, 'history' );

    is( $one->history, undef );

    is( $one->history( 6666 ), undef );

        $tmp = $CLASSDATA->{ 1001 }->{ client_id };
    is_deeply( $one->history( $tmp ), [
        $CLASSDATA->{ 1002 },
        $CLASSDATA->{ 1001 },
    ] );

        $one->client_id( $tmp );
    is_deeply( $one->history, $one->history( $tmp ) );

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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    can_ok( $one, 'client_relationship' );

        $one = $CLASS->new({ rec_id => 1001 })->retrieve;
    is( $one->rec_id, 1001 );
    is( $one->rolodex_relationship_id, 1001 );
    is( $one->relationship_role, 'treaters' );

    is_deeply( $one->client_relationship, $client_treaters->{ 1001 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
