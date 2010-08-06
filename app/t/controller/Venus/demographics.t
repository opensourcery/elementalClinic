#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 8;
use eleMentalClinic::Test;
use eleMentalClinic::Personnel;

my $CLASS = 'eleMentalClinic::Controller::Venus::Demographics';
use_ok( $CLASS );

sub dbinit {
    $test->db_refresh;
    $test->insert_data;
}
dbinit();


# The middle name was required for some reason
{
    my $client_id = 1003;
    my $current_user = eleMentalClinic::Personnel->retrieve( 1001 );

    # Give the client a middle name
    my $demo = $CLASS->new_with_cgi_params(
        client_id       => $client_id,
        op              => "save",
        fname           => "Foo",
        mname           => "Wibble",
        lname           => "Bar",
    );
    isa_ok( $demo, $CLASS );
    $demo->current_user( $current_user );

    ok( $demo->save );
    ok( !$demo->errors, "no errors" ) || diag @{ $demo->errors };

    my $client = eleMentalClinic::Client->retrieve( $client_id );
    is $client->mname, "Wibble";

    # Now remove that middle name
    $demo = $CLASS->new_with_cgi_params(
        client_id       => $client_id,
        op              => "save",
        fname           => "Foo",
        mname           => "",
        lname           => "Bar",
    );
    $demo->current_user( $current_user );

    ok( $demo->save );
    ok( !$demo->errors, "no errors" ) || diag @{ $demo->errors };

    # Get a fresh copy from the database
    $client = eleMentalClinic::Client->retrieve( $client_id );
    is $client->mname, undef, "client's middle name removed";
}
