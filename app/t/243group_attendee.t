# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 17;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Group::Attendee';
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
    is( $one->table, 'group_attendance');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [ qw/ 
        rec_id group_note_id client_id action prognote_id
    / ]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_bygroupnote
    is_deeply( $CLASS->new->get_bygroupnote( 1001 ), [
        $group_attendance->{ 1001 },
        $group_attendance->{ 1002 },
        $group_attendance->{ 1003 },
    ]);

    is_deeply( $CLASS->new->get_bygroupnote( 1002, 'group_note' ), [
        $group_attendance->{ 1004 },
        $group_attendance->{ 1005 },
        $group_attendance->{ 1006 },
    ]);

    ok( not $CLASS->new->get_bygroupnote( 1002, 'FAKE' ));

    is_deeply( $CLASS->new->get_bygroupnote( 1001, 'group_note', '1' ), [
        $group_attendance->{ 1001 },
        $group_attendance->{ 1002 },
        $group_attendance->{ 1003 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_bygroup

    is_deeply( $CLASS->new->get_bygroup( 1001 ), [
        $group_attendance->{ 1001 },
        $group_attendance->{ 1002 },
        $group_attendance->{ 1003 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_byclient_group

    is_deeply( $CLASS->new->get_byclient_group( 1001, 1001 ), [
        $group_attendance->{ 1001 },
        $group_attendance->{ 1004 },
    ]);

    is_deeply( $CLASS->new->get_byclient_group( 1002, 1001 ), [
        $group_attendance->{ 1002 },
        $group_attendance->{ 1005 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_groupnote

    is_deeply( $CLASS->new->get_one_by_( 'rec_id', 1001 )->get_group_note, 
        $group_notes->{ 1001 },
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_group

    is_deeply( $CLASS->new->get_one_by_( 'rec_id', 1001 )->get_group,
        $groups->{ 1001 }
    );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
