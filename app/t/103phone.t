# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 14;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Contact::Phone';
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
    ok( $one = $CLASS->new( {
        phone_number => '555-555-5555',
        rolodex_id   => 555,
    }) );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

    is_deeply(
        $one,
        {
            phone_number  => '555-555-5555',
            rolodex_id    => 555,
            rec_id        => undef,
            client_id     => undef,
            message_ok    => undef,
            call_ok       => undef,
            primary_entry => undef,
            active        => undef,
            phone_type    => undef,
        },
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'phone');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [ qw/ 
        rec_id client_id rolodex_id phone_number 
        message_ok call_ok active phone_type primary_entry
    / ]);

    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );
    can_ok( $one, 'phone_number' );
    can_ok( $one, 'rolodex_id' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->new( {
        phone_number => '555-555-5555',
        rolodex_id   => 99,
    });

    $one->save;

    is_deeply_except(
        {
            rec_id        => undef,
            client_id     => undef,
            message_ok    => undef,
            call_ok       => undef,
            primary_entry => undef,
            active        => undef,
            phone_type    => undef,
        },
        $one,
        $CLASS->get_one_by_( 'rolodex_id', 99 )
    );

dbinit( 1 );
