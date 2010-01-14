# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 34;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Verification';
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
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'client_verification');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id apid_num verif_date rolodex_treaters_id created staff_id
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_byclient, get_byclient
    can_ok( $CLASS, 'list_byclient', 'get_byclient' );
    is( $CLASS->list_byclient, undef );
    is( $CLASS->list_byclient( 6666 ), undef );

    is( $CLASS->get_byclient, undef );
    is( $CLASS->get_byclient( 6666 ), undef );

    # list_byclient
    is_deeply( $CLASS->list_byclient( 1001 ), [
        $client_verification->{ 1001 },
        $client_verification->{ 1002 },
    ] );

    is_deeply( $CLASS->list_byclient( 1002 ), [
        $client_verification->{ 1003 },
    ] );

	is_deeply( $CLASS->list_byclient( 1003 ), [
        $client_verification->{ 1004 },
        $client_verification->{ 1005 },
		$client_verification->{ 1006 },
    ] );

    is( $CLASS->list_byclient( 6666 ), undef );

    # active flag
    #is_deeply( $CLASS->list_byclient( 1001, 0 ), [
    #    $client_verification->{ 1001 },
    #] );

    #is_deeply( $CLASS->list_byclient( 1002, 0 ), [
    #    $client_verification->{ 1003 },
    #] );

    #is_deeply( $CLASS->list_byclient( 1001, 1 ), [
    #    $client_verification->{ 1002 },
    #] );

    #is( $CLASS->list_byclient( 1002, 1 ), undef );

    #is( $CLASS->list_byclient( 1001, 2 ), undef );
    #is( $CLASS->list_byclient( 1002, 2 ), undef );

    # get_byclient
    isa_ok( $CLASS->get_byclient( 1001 )->[0], $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# verify
    can_ok($CLASS, 'verify');

    is($one->verify, undef);

        # setup Auditor to use the given current_user rather
        # than having it try to get something out of the 
        # CGI session.
        my $current_user = eleMentalClinic::Personnel->new( $personnel->{1001} )->retrieve;
        $eleMentalClinic::Auditor::Test_Current_User = $current_user;

    my $verification = $CLASS->new( { rec_id => 1001 } )->retrieve;
    my $updated = $CLASS->new( { rec_id => 1001 } )->retrieve;
    is_deeply( $verification, $updated);
    $updated->apid_num(999999);
    isnt($verification->apid_num, $updated->apid_num);
    my $note_id = $updated->verify($verification);
 
    my $note = eleMentalClinic::ProgressNote->new( { rec_id => $note_id } )->retrieve;
    is( $note->id, $note_id);
    is( $note->client_id, $verification->client_id);
    is( $note->note_header, 'VERIFIED');
    is( $note->note_body, "APID: 999999, Date: ".$updated->verif_date.", Doctor: ".$rolodex->{1011}->{name});
    my $today = $one->today;
    like( $note->start_date, qr/$today.*/);
    is( $note->staff_id, $current_user->staff_id );

    # testing through a call to update
    $updated->update( { verif_date => "$today" } );
    my $next_id = $note_id + 1;
    $note = eleMentalClinic::ProgressNote->new( { rec_id => $next_id } )->retrieve;
    is( $note->id, $next_id);
    is( $note->client_id, $updated->client_id);
    is( $note->note_header, 'VERIFIED');
    is( $note->note_body, "APID: 999999, Date: ".$updated->verif_date.", Doctor: ".$rolodex->{1011}->{name});
    like( $note->start_date, qr/$today.*/);
    is( $note->staff_id, $current_user->staff_id );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
