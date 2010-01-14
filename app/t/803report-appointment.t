# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 5;
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

    my $results = eleMentalClinic::Schedule::Appointments->list_byday( date => '2006-06-01' );
    my $by_staff = {};
    for my $res ( @$results ) {
        $res->{ staff } = eleMentalClinic::Personnel->retrieve( $res->{ staff_id });
        $res->{ client } = eleMentalClinic::Client->retrieve( $res->{ client_id });
        $by_staff->{ $res->{ staff_id }} ||= { staff => $res->{ staff }, list => [] };
        my $staff_list = $by_staff->{ $res->{ staff_id }}->{ list };
        push( @$staff_list, $res );
    }

    throws_ok { $one->appointments } qr/Attribute \(date\) is required/;
    is_deeply(
        $one->appointments({
            date => '2006-06-01',
        }),
        [
            {
                staff => { name => 'All Staff' },
                list => $results,
            }
        ],
        "Only Date"
    );

    is_deeply(
        [ sort { $a->{ staff }->staff_id <=> $b->{ staff }->staff_id } @{
            $one->appointments({
                date => '2006-06-01',
                group => 'Staff',
            }),
        }],
        [
            sort { $a->{ staff }->staff_id <=> $b->{ staff }->staff_id } values %$by_staff,
        ],
        "Grouped by Staff"
    );

    is_deeply(
        $one->appointments({
            date => '2006-06-01',
            user => 'betty',
        }),
        [
            $by_staff->{ eleMentalClinic::Personnel->new->get_one_by_( 'login', 'betty' )->staff_id },
        ],
        "One Specific Staff Member"
    );

