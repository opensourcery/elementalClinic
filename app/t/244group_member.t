# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 15;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Group::Member';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}

dbinit( 1 );

# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'group_members');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [ qw/ 
        rec_id group_id client_id active
    / ]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_bygroup

    is_deeply( $CLASS->new->get_bygroup( 1001 ), [
        $client->{ 1001 },
        $client->{ 1004 }, #ordered by name.
        $client->{ 1002 },
        $client->{ 1003 },
        $client->{ 1005 },
    ]);

    is_deeply( $CLASS->new->get_bygroup( 1002 ), [
        $client->{ 1001 },
        $client->{ 1002 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client

    is_deeply( 
        $CLASS->new->get_one_by_( 'rec_id', 1001 )->client, 
        $client->{ 1001 }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_byclient_group 

    is_deeply(
        $CLASS->new->get_byclient_group( 1001, 1001),
        $group_members->{ 1001 }
    );

    is_deeply(
        $CLASS->new->get_byclient_group( 1002, 1001),
        $group_members->{ 1002 }
    );

    is_deeply(
        $CLASS->new->get_byclient_group( 1001, 1005),
        $group_members->{ 1016 }
    );

    #User number 1004 is not in group 1005
    ok( not $CLASS->new->get_byclient_group( 1004, 1005 ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
