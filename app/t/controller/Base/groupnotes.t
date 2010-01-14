# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 43;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::GroupNotes';
    use_ok( q/eleMentalClinic::Controller::Base::GroupNotes/ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runmodes
    can_ok( $CLASS, 'ops' );
    ok( my %ops = $CLASS->ops );
    my @oplist = qw/
        home
        save_group_note
        commit_group_note
        save_prognote
        commit_prognote
        prognote_detail
        group_note_detail
        client_prognote_detail
    /;
    #Make sure the same list is available
    is_deeply( [ sort keys %ops ], [ sort @oplist ]);

    #Make sure the controller has each method
    can_ok( $CLASS, $_ ) for @oplist;

    #Make sure each method runs
    ok( $CLASS, $_ ) for @oplist;

    #Make sure it all works w/ cgi params
    for ( @oplist ) {
        $one = $CLASS->new_with_cgi_params(
            op => $_,
        );
        ok( $one->isa( $CLASS ));
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_attendee

    $one = $CLASS->new_with_cgi_params(
        attendee_id => '1001',
    );
    is_deeply( $one->get_attendee, $group_attendance->{ 1001 } );
    $one = $CLASS->new_with_cgi_params(
        attendee_id => '1004',
    );
    is_deeply( $one->get_attendee, $group_attendance->{ 1004 } );

    # Get an attendee that does not exist
    # This test was written LONG after the function, so the test reflects
    # current behavior, not necessarily desired behavior.
    # The desired behavior may have changed, or not been programmed in initially
    # But the function as it stands will return an object w/o a valid ID
    # and give an error message
    $one = $CLASS->new_with_cgi_params(
        attendee_id => '1020',
    );
    ok( not $one->errors ); #Should be no error messages priort to function we are testing.
    is_deeply( $one->get_attendee, eleMentalClinic::Group::Attendee->new );
    ok( $one->errors );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_group_note

    $one = $CLASS->new_with_cgi_params(
        group_note_id => '1002',
    );
    is_deeply( $one->get_group_note, $group_notes->{ 1002 } );

    is_deeply( $one->get_group_note( 1001 ), $group_notes->{ 1001 } );

    # Get a note that does not exist
    # This test was written LONG after the function, so the test reflects
    # current behavior, not necessarily desired behavior.
    # The desired behavior may have changed, or not been programmed in initially
    # But the function as it stands will return an object
    # and give an error message
    $one = $CLASS->new_with_cgi_params(
        group_note_id => '1005',
    );
    is_deeply( $one->get_group_note, eleMentalClinic::Group::Note->new );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Untested!
# I am writing these tests well after the controller and functions were written
# comming in I am unsure how to test these, or for various reasons I chose not to test.

 TODO: {
    local $TODO = "Test get_prognote.";
    ok( 0 );
 }

 TODO: {
    local $TODO = "Test get_chargecode.";
    ok( 0 );
 }

 TODO: {
    local $TODO = "Test validate_note.";
    ok( 0 );
 }

 TODO: {
    local $TODO = "Test start_times.";
    ok( 0 );
 }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit();
