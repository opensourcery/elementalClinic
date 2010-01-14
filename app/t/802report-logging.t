# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 37;
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

    $one = $CLASS->new(name => 'access');
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    sub client {
        my $id = shift;
        return eleMentalClinic::Client->retrieve( $id );
    }
    sub staff {
        my $id = shift;
        return eleMentalClinic::Personnel->retrieve( $id );
    }

    ok( my $results = $one->access, "Access works w/ no params" );
    is( @$results, 1, "All history has 1 result." );
    is( $results->[0]->{ date }, 'All History', "No params means all history" );
    my $list = $results->[0]->{ items };
    is( ref $list, 'ARRAY', "Got list of items" );
    is( @$list, 3, "Only 3 clients have been accessed ever in test data" );
    is_deeply(
        $list,
        [
            {
                staff => staff( 1001 ),
                objects => $one->report->access_get_objects( 1001 ),
            },
            {
                staff => staff( 1002 ),
                objects => $one->report->access_get_objects( 1002 ),
            },
            {
                staff => staff( 1005 ),
                objects => $one->report->access_get_objects( 1005 ),
            },
        ],
        "Output is right",
    );

    ok(
        $results = $one->access({
            access_by => 'Day',
        }),
        "By Day"
    );
    is( @$results, 4, "Correct number of days that have records" );
    is( $results->[0]->{ date }, "2008-11-05", "date for 0" );
    is( $results->[1]->{ date }, "2008-11-06", "date for 1" );
    is( $results->[2]->{ date }, "2008-11-10", "date for 2" );
    is( $results->[3]->{ date }, "2008-11-14", "date for 3" );

    ok(
        $results = $one->access({
            access_by => 'Day',
            start_date => '2008-11-06',
            end_date => '2008-11-11',
        }),
        "Date Range"
    );
    is( @$results, 2, "Correct number of days that have records" );
    is( $results->[0]->{ date }, "2008-11-06", "date for 0" );
    is( $results->[1]->{ date }, "2008-11-10", "date for 1" );

    ok(
        $results = $one->access({
            access_by => 'Range',
            start_date => '2008-11-06',
            end_date => '2008-11-11',
        }),
        "Date Range"
    );
    is( @$results, 1, "Once record for range" );
    is( $results->[0]->{ date }, "2008-11-06 through 2008-11-11", "date for 0" );

    ok(
        $results = $one->access({
            access_user => 1001,
        }),
        "Specific User"
    );
    is( @{ $results->[0]->{ items }}, 1, "Only 1 user" );
    is( $results->[0]->{ items }->[0]->{ staff }->id, 1001, "Correct user" );

    my $user = eleMentalClinic::Personnel->new->retrieve( 1001 );
    my $temp = eleMentalClinic::Log::Access->new;
    $temp->update_from_log({
        user => $user,
        action => 'load',
        object => $user,
    });
    ok(
        $results = $one->access({
            access_type => ref $user,
        }),
        "Object other than client"
    );
    is( @{ $results->[0]->{ items }->[0]->{ objects }}, 1, "Only 1 result" );
    is_deeply(
        $results->[0]->{ items }->[0]->{ objects }->[0],
        {
            object => $user,
            count => 1,
            name => 'Personnel: Ima Therapist',
            session_count => 0,
        },
        "User is object"
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    is_deeply(
        $one->report->access_list_from_field( 'object_type' ),
        [
            'eleMentalClinic::Client',
            'eleMentalClinic::Personnel',
        ],
        'Corrent Object Types'
    );

    dbinit( 1 );

    is_deeply(
        $one->report->access_list_from_field( 'date(logged)' ),
        [
            '2008-11-05',
            '2008-11-06',
            '2008-11-10',
            '2008-11-14',
        ],
        'Can get date from timestamp'
    );

    is_deeply(
        $one->report->access_list_from_field( 'object_id' ),
        [
            '1001',
            '1002',
            '1004',
        ],
        'Corrent Object IDs'
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    is( @{ $one->report->access_get_objects( 1001 )}, 3, "Correct entries for user 1001" );
    is_deeply(
        $one->report->access_get_objects( 1001 )->[0],
        {
            object => eleMentalClinic::Client->retrieve( 1001 ),
            count => 28,
            name => 'Client: Miles Davis',
            session_count => 9,
        },
        "Entry 0 is correct"
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $results = $one->security_log;
    is( @$results, 4, '4 dates');

    is( $results->[0]->{ name }, '2008-11-05' );
    is( $results->[1]->{ name }, '2008-11-06' );
    is( $results->[2]->{ name }, '2008-11-10' );
    is( $results->[3]->{ name }, '2008-11-14' );

    $results = $one->security_log({
        order => 'login',
        actions => [ qw/ login logout failure / ],
    });
    is_deeply (
        [ sort map { $_->{ name } } @$results ],
        [
            sort qw/
            admini barney betty
            clinic fred guest ima
            number root user user22
            whip willy
            /
        ],
        "Grouped by login"
    )
