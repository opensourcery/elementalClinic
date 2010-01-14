# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 38;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Group';
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
    is( $one->table, 'groups');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [ qw/ 
        rec_id name description active default_note
    / ]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_all

    is_deeply( $one->list_all , [
        $groups->{ 1003 },
        $groups->{ 1004 },
        $groups->{ 1001 },
        $groups->{ 1006 },
        $groups->{ 1005 },
        $groups->{ 1002 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all

    is_deeply( $one->get_all , [
        $groups->{ 1003 },
        $groups->{ 1004 },
        $groups->{ 1001 },
        $groups->{ 1006 },
        $groups->{ 1005 },
        $groups->{ 1002 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_members

# Member list is ordered by name
    is_deeply( $CLASS->retrieve( 1001 )->get_members, [
        $client->{ 1001 },
        $client->{ 1004 },
        $client->{ 1002 },
        $client->{ 1003 },
        $client->{ 1005 },
    ]);

    is_deeply( $CLASS->retrieve( 1002 )->get_members, [
        $client->{ 1001 },
        $client->{ 1002 },
    ]);

    is_deeply( $CLASS->retrieve( 1003 )->get_members, [
        $client->{ 1001 },
        $client->{ 1003 },
        $client->{ 1005 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add_member
# remove_member

    #Attempt to add a member to a group they are already member of
    ok( not $CLASS->retrieve( 1001 )->add_member( 1001 ) ); 

    ok( $CLASS->retrieve( 1003 )->add_member( 1002 ) ); 
    is_deeply( $CLASS->retrieve( 1003 )->get_members, [
        $client->{ 1001 },
        $client->{ 1002 }, #Verify client 1002 was added.
        $client->{ 1003 },
        $client->{ 1005 },
    ]);
    ok( $CLASS->retrieve( 1003 )->remove_member( 1002 ) ); 
    is_deeply( $CLASS->retrieve( 1003 )->get_members, [ #verify 1002 is no longer present
        $client->{ 1001 },
        $client->{ 1003 },
        $client->{ 1005 },
    ]);

    #Try to remove a client that is not a member. 
    ok( not $CLASS->retrieve( 1003 )->remove_member( 1002 ) ); 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_notes
    is_deeply( $CLASS->retrieve( 1001 )->get_notes, [
        $group_notes->{ 1001 },
        $group_notes->{ 1002 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save

    #Create a new group, then try to do it again
    ok( $CLASS->new({ name => 'test' })->save );
    ok( not $CLASS->new({ name => 'test' })->save );

    $one = $CLASS->new({ name => 'test2' });
    #The next test s to ensure the following test's results are valid
    #if this test fails then the third tests results cannot be trusted as the constructor
    #behavior would have to have changed.
    ok( not defined $one->active ); #Make sure active is not defined in the new object
    $one->save;
    is( $one->active, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# name_exists

    ok( $CLASS->new->name_exists( $groups->{ 1001 }->{ name } ));
    ok( not $CLASS->new->name_exists( 'Fake Name' ));


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_bygroupnote

    is_deeply( $CLASS->new->get_bygroupnote( 1001 ), $groups->{ 1001 });
    is_deeply( $CLASS->new->get_bygroupnote( 1002 ), $groups->{ 1001 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#show_from_str

    is( $one->show_from_str( 'active' ), 1 ); #active is 1
    is( $one->show_from_str, 1 ); #default is active
    is( $one->show_from_str( 'fake' ), 1 ); #default is active
    is( $one->show_from_str( 'inactive' ), '0' ); #inactive must return an actual '0' not just the value 0, this is for the DB
    is( $one->show_from_str( 'all' ), undef ); #show all means passing an undefined value in the right place.

dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#get_byclient 

    is_deeply( $one->get_byclient( 1001, 1 ), [
        $groups->{ 1001 },
        $groups->{ 1002 },
        $groups->{ 1003 },
    ]);

    is_deeply( $one->get_byclient( 1005, 1 ), [
        $groups->{ 1001 },
        $groups->{ 1003 },
    ]);


    is_deeply( $one->get_byclient( 1001, '0' ), [
        $groups->{ 1004 },
        $groups->{ 1005 },
        $groups->{ 1006 },
    ]);

    is_deeply( $one->get_byclient( 1005, '0' ), [
        $groups->{ 1004 },
        $groups->{ 1006 },
    ]);

    is_deeply( $one->get_byclient( 1001 ), [
        $groups->{ 1001 },
        $groups->{ 1002 },
        $groups->{ 1003 },
        $groups->{ 1004 },
        $groups->{ 1005 },
        $groups->{ 1006 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
