# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 65;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Department;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Release';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;

        $test->insert_data([
            'eleMentalClinic::Client',
            $CLASS,
        ]);
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'client_release');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id rolodex_id
        print_date renewal_date release_list standard
        print_header_id release_from release_to
        active
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ));

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
    can_ok( $one, 'get_all' );
    is( $one->get_all, undef );

        $one->client_id( 6666 );
    is( $one->get_all, undef );
    # code has not been written to handle this scenario
    #is( $one->get_all({ foo => 'bar', 1 => 2 }), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# history
    can_ok( $one, 'history' );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# release_list_names
    can_ok( $one, 'release_list_names' );
    is( $one->release_list_names, undef );
    is( $one->release_list_names( [] ), undef );

    ok( $one->id( 1004 )->retrieve );
    is_deeply( $one->release_list_names([ 6,11,12 ]),
        [ 'Financial', 'Lab Reports', 'Legal' ]);
    is_deeply( $one->release_list_names,
        [ 'A.I.D.S. Status', 'H.I.V. test and results' ]);

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# release_list_keyval
    can_ok( $one, 'release_list_keyval' );

    is( $one->release_list_keyval, undef );

        $one->release_list( '6666' );
    is( $one->release_list_keyval, undef );

        $one->release_list( '2,3,11,9,12,5,7' );
    is_deeply( $one->release_list_keyval, [
        { 2     => 'A.I.D.S. Status' },
        { 3     => 'Drug/Alcohol abuse treatment' },
        { 11    => 'Financial' },
        { 9     => 'History and Assessments' },
        { 12    => 'Legal' },
        { 5     => 'Medical/Physical Health' },
        { 7     => 'Medication Information' },
    ]);

        $one->release_list( '2,6666' );
    is_deeply( $one->release_list_keyval, [
        {
            2 => 'A.I.D.S. Status',
        },
    ] );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client
    can_ok( $one, 'client' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# print_header
    can_ok( $one, 'print_header' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex
    can_ok( $one, 'rolodex' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# release_listref
    can_ok( $one, 'release_listref' );
    ok( $one = $CLASS->new );
    is( $one->release_listref, undef );

    ok( $one->id( 1001 )->retrieve );
    is_deeply( $one->release_listref, [ 1, 2, 3, 5, 7, 9, 11, 12 ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# release_list_sensitive_and_normal
    can_ok( $one, 'release_list_sensitive_and_normal' );
    ok( $one = $CLASS->new );
    is_deeply( $one->release_list_sensitive_and_normal, [ undef, undef ] );

    ok( $one->id( 1001 )->retrieve );
    is_deeply( $one->release_list_sensitive_and_normal,
        [[ 1, 2, 3 ], [ 5, 7, 9, 11, 12 ]]);

    ok( $one->id( 1004 )->retrieve );
    is_deeply( $one->release_list_sensitive_and_normal,
        [[ 1, 2 ], undef ]);

    ok( $one->id( 1005 )->retrieve );
    is_deeply( $one->release_list_sensitive_and_normal,
        [ undef, [ 5, 6 ]]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# release_list_sensitive
# release_list_normal
    can_ok( $one, 'release_list_sensitive' );
    can_ok( $one, 'release_list_normal' );
    ok( $one = $CLASS->new );
    is_deeply( $one->release_list_sensitive, undef );
    is_deeply( $one->release_list_normal, undef );

    ok( $one->id( 1001 )->retrieve );
    is_deeply( $one->release_list_sensitive, [ 1, 2, 3 ]);
    is_deeply( $one->release_list_normal, [ 5, 7, 9, 11, 12 ]);

    is_deeply( $one->release_list_sensitive_names,
        $one->release_list_names([ 1, 2, 3 ]));
    is_deeply( $one->release_list_normal_names,
        $one->release_list_names([ 5, 7, 9, 11, 12 ]));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# release list: only sensitive
    ok( $one->id( 1004 )->retrieve );
    is_deeply( $one->release_list_sensitive, [ 1, 2 ]);
    is( $one->release_list_normal, undef );

    is_deeply( $one->release_list_sensitive_names,
        $one->release_list_names([ 1, 2 ]));
    is( $one->release_list_normal_names, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# release list: only normal
    ok( $one->id( 1005 )->retrieve );
    is( $one->release_list_sensitive, undef );
    is_deeply( $one->release_list_normal, [ 5, 6 ]);

    is( $one->release_list_sensitive_names, undef );
    is_deeply( $one->release_list_normal_names,
        $one->release_list_names([ 5, 6 ]));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# site_release_list_sensitive_and_normal
# all sensitive and normal items for the site
    can_ok( $one, 'site_release_list_sensitive_and_normal' );
    ok( $one = $CLASS->new );

    is_deeply( $one->site_release_list_sensitive_and_normal,
        [ $site_release_sensitive, $site_release_normal ]);

    is_deeply( $one->site_release_list_sensitive, $site_release_sensitive );
    is_deeply( $one->site_release_list_normal, $site_release_normal );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
