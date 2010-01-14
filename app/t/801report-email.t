# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 20;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use String::Diff;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Report';
    use_ok( $CLASS );
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    $one = $CLASS;

    my $results = $one->email({
        'sort' => 'date',
        'order' => 'ASC',
    });
    is( @$results, keys %$email, 'Sorting by date gives us each message once.' );

    is_deeply(
        $results->[0],
        {
            email_id => 1001,
            subject => 'Appointment',
            body => "You have an appointment!
 =======================================================
 Appointment Information
 Date: 2005-04-10
 Time: 2:00
 =======================================================
 
 Thank you,
 Clinic",
            send_date => '2005-04-04',
            sender_id => 1001,
            recipient_data => [{
                client_id => 1001,
                email => 'miles@davis.com',
                lname => 'Davis',
                fname => 'Miles',
                recipient_id => 1001,
            }],
        },
        "First result is as expected.",
    );

    is_deeply(
        $results->[-1]->{ recipient_data },
        [
            {
                client_id => undef,
                email => 'test@eleMentalClinic.com',
                lname => undef,
                fname => undef,
                recipient_id => 1010,
            },
            {
                client_id => undef,
                email => 'admin@eleMentalClinic.com',
                lname => undef,
                fname => undef,
                recipient_id => 1011,
            },
            {
                client_id => undef,
                email => 'system@eleMentalClinic.com',
                lname => undef,
                fname => undef,
                recipient_id => 1012,
            },
        ],
        "last result has multiple recipients"
    );

    $results = $one->email({
        'sort' => 'client',
        order => 'ASC',
    });
    is( @$results, (keys %$email) - 2, "Results only contain messages w/ clients as recipients" );

    $results = $one->email({
        'sort' => 'date',
        order => 'ASC',
        start_date => '2008-01-01'
    });
    is( @$results, 2, "Only 2 messages from 2008 onword." );

    $results = $one->email({
        'sort' => 'date',
        order => 'ASC',
        start_date => '2005-07-01',
        end_date => '2005-07-28',
    });
    is( @$results, 2, "Only 2 messages from 2005-07-[1-28]" );
    is( $results->[0]->{ send_date }, '2005-07-04' );
    is( $results->[1]->{ send_date }, '2005-07-10' );

    $results = $one->email({
        'sort' => 'date',
        order => 'ASC',
        client => 1001,
    });
    for my $result ( @$results ) {
        is( $result->{ recipient_data }->[0]->{ client_id }, 1001, "Right Client" );
    }

    $results = $one->email({
        'sort' => 'date',
        order => 'ASC',
        search => 'Test',
        contained_in => [ 'subject' ],
    });
    is( @$results, 2, "Only 2 messages match 'Test'" );

    $results = $one->email({
        'sort' => 'date',
        order => 'ASC',
        search => 'Test',
        contained_in => [ 'body' ],
    });
    is( @$results, 2, "Only 2 messages match 'Test'" );

    $results = $one->email({
        'sort' => 'date',
        order => 'ASC',
        search => 'Test',
    });
    is( @$results, 0, "no results w/o contained_in" );

    $results = $one->email({
        'sort' => 'date',
        order => 'ASC',
        search => 'admin',
        contained_in => [ 'address' ],
    });
    is( @$results, 1, "one address contains admin" );

    $results = $one->email({
        'sort' => 'date',
        order => 'ASC',
        search => 'davis.com',
        contained_in => [ 'address' ],
    });
    is( @$results, 4, "4 messages for miles davis" );

    $results = $one->email({
        'sort' => 'address',
        order => 'ASC',
        search => 'eleMentalClinic.com',
        contained_in => [ 'address' ],
    });
    is( @$results, 4, "4 messages for emc.com" );

    $results = $one->email({
        'sort' => 'date',
        order => 'ASC',
        search => '@',
        contained_in => [ 'address' ],
    });
    is( @$results, keys %$email, "all addresses contain '\@'" );

dbinit();
