# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Carp;

use Test::More tests => 198;
use Test::Exception;
use Test::Warn;
use eleMentalClinic::Test;
our ($CLASS, $one, %tables, $tmp, @testarray, $dblah);
# TODO:
# actually implement real tests for package eleMentalClinic::Fixtures

BEGIN {
    *CLASS = \'eleMentalClinic::Fixtures';
    use_ok( $CLASS );
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift or clean_dir() and rmdir( 'fixtures/testdata-jazz-export' );
}
dbinit( 1 );

sub clean_dir {
    opendir( DIR, 'fixtures/testdata-jazz-export' ) or die( "couldn't open fixtures/testdata-jazz-export" );
    foreach my $entry ( readdir( DIR )) {
        next unless $entry =~ /\.yaml$/;
        unlink( "fixtures/testdata-jazz-export/$entry" ) or warn "failed to unlink $entry: $!";
    }
    closedir( DIR );
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for constructor
#
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for insert_order
#
    can_ok( $one, 'insert_order' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for load_fixtures
#
    can_ok( $one, 'load_fixtures' );
    is( $one->load_fixtures, undef );
    is( ref( ${ $one->load_fixtures( 'fixtures/testdata-jazz' ) }{ 'client' } ), 'HASH' );
    {
        open( FH, '+>', "t/resource/test3.yaml.compiled" )
            or die "Couldn't open t/resource/test3.yaml.compiled for writing!";
        print( FH '');
        close FH;
    }
    ok( -f 't/resource/test3.yaml' );
    ok( -z 't/resource/test3.yaml.compiled' );
    ok( $one->load_fixtures( 't/resource', 1 ));
    ok( -f 't/resource/test3.yaml.compiled' );
    ok( not -z 't/resource/test3.yaml.compiled' );
    dies_ok{ $one->load_fixtures( 'fake' ) };
    like( $@, qr/Couldn't open directory 'fake':.*/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests of data success
#
    ok( $tmp = $one->load_fixtures( 't/resource' ));
    is( $$tmp{ 'test'  }{ '1001' }{ 'dob' }, '1926-05-25' );
    is( $$tmp{ 'test'  }{ '1002' }{ 'dob' }, '1922-04-21' );
    is( $$tmp{ 'test'  }{ '1003' }{ 'dob' }, '1917-10-10' );
    # these need betterness
    my @thetime = localtime( time );
    is( $$tmp{ 'test2' }{ '1001' }{ 'dob' }, ( 1900 + $thetime[5] ) . '-' . $thetime[4] . '-' . ( $thetime[3] ));
    @thetime = localtime( time - 7*86400 );
    is( $$tmp{ 'test2' }{ '1002' }{ 'dob' }, ( 1900 + $thetime[5] ) . '-' . $thetime[4] . '-' . ( $thetime[3] ));
    @thetime = localtime( time + 7*86400 );
    is( $$tmp{ 'test2' }{ '1003' }{ 'dob' }, ( 1900 + $thetime[5] ) . '-' . $thetime[4] . '-' . ( $thetime[3] ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DB Tests
# ................................................

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for insert_fixture_data
#
    can_ok( $one, 'insert_fixture_data' );
    #dies_ok{ $one->insert_fixture_data( '', 'fake ' ) };
    #like( $@, qr/Second parameter to insert_fixture_data must be arrayref.*/ );
    ok( $one->insert_fixture_data( 'fixtures/testdata-jazz' ));

    # these tables do not have a serial primary key
    my %skip = (
        personnel_security_role => 1,
        security_role           => 1,
    );
        
    for my $table (
        grep { ! $skip{$_} }
        map  { eval { $_->table } || $_ }
        eleMentalClinic::Fixtures->insert_order
    ) {
        my $key = eleMentalClinic::Fixtures->get_pkey_name( $table );
        my $seq = $one->db->do_sql(
            "SELECT pg_get_serial_sequence('$table', '$key')"
        )->[0]->{pg_get_serial_sequence};
        if ($seq) {
            my $next = $one->db->do_sql(
                "SELECT nextval('$seq')"
            )->[0]->{nextval};
            my $max = $one->db->do_sql(
                "SELECT MAX($key) AS $key FROM $table"
            )->[0]->{$key};
            $max ||= 0;
            cmp_ok(
                $next, '>', $max, 
                "$table: next $key\[$next] > max $key\[$max]"
            );
        } else {
            TODO: {
                local $TODO = "Handle objects that are views";
                ok( 0, "missing sequence for $table.$key" );
            }
        }
    }

    #ok( $one->insert_fixture_data( 'fixtures/testdata-jazz', \@testarray ));
    ok( $one->insert_fixture_data( 'fixtures/testdata-jazz', 0 ), 'insert none' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for insert_
#
    can_ok( $one, 'insert_' );
    is( $one->insert_, undef );
    is( $one->insert_( 'fake' ), 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for insert_table
#
    can_ok( $one, 'insert_table' );
    is( $one->insert_table, undef );
    is( $one->insert_table( 'fake', ), 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for get_test_info
#
    can_ok( $one, 'get_test_info' );
    is( $one->get_test_info, undef );
    is( $one->get_test_info( '' ), undef );
    is( ref( $one->get_test_info( 'client' ) ), 'ARRAY' );
    is( ref( $one->get_test_info( 'client, fake' ) ), 'ARRAY' );
    is( ref( $one->get_test_info( 'client', '', \@testarray )), 'ARRAY' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for get_table_names
#
    can_ok( $one, 'get_table_names' );
    is( ref( $one->get_table_names ), 'ARRAY' );
    is( ${ $one->get_table_names }[1], 'address' );
    is( ${ $one->get_table_names }[15], 'claims_processor' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for get_field_names
#
    can_ok( $one, 'get_field_names' );
    dies_ok{ $one->get_field_names };
    like( $@, qr/Table name required to get field names.*/ );
    is( ref( $one->get_field_names( 'client' )), 'ARRAY' );
    is( ${ $one->get_field_names( 'client' ) }[0], 'acct_id' );
    is( ref( $one->get_field_names( 'groups' )), 'ARRAY' );
    is( ${ $one->get_field_names( 'groups' ) }[0], 'active' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for get_pkey_name
#
    can_ok( $one, 'get_pkey_name' );
    is( $one->get_pkey_name( 'client' ), 'client_id' );
    is( $one->get_pkey_name( 'groups' ), 'rec_id' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for reset_pkey_seq
#
    can_ok( $one, 'reset_pkey_seq' );
        $one->reset_pkey_seq( 'client' );
    ok(
        $one->db->do_sql(
            "SELECT nextval('client_client_id_seq')"
        )->[0]->{ 'nextval' }
        > # the test
        $one->db->select_many_arrayref(
            [ "MAX(client_id)" ],
            'client',
            '',
            ''
        )->[0]
    );
    ok(
        $one->db->do_sql(
            "SELECT nextval('personnel_staff_id_seq')"
        )->[0]->{ 'nextval' }
        > # the test
        $one->db->select_many_arrayref(
            [ "MAX(staff_id)" ],
            'personnel',
            '',
            ''
        )->[0]
    );
    ok(
        $one->db->do_sql(
            "SELECT nextval('access_log_rec_id_seq')"
        )->[0]->{ 'nextval' }
        > # the test
        $one->db->select_many_arrayref(
            [ "MAX(rec_id)" ],
            'access_log',
            '',
            ''
        )->[0]
    );
    #is( $one->reset_pkey_seq( 'client' ), 1007 );
    #is( $one->reset_pkey_seq( 'personnel' ), 1006 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests for export_db
#

# tests for white/black list

    # white
    mkdir( 'fixtures/testdata-jazz-export' ) unless -d 'fixtures/testdata-jazz-export';
    ok( -d 'fixtures/testdata-jazz-export' );
    ok( clean_dir, 'clean_dir' );
    ok( not -e 'fixtures/testdata-jazz-export/client.yaml' );
    ok( not -e 'fixtures/testdata-jazz-export/groups.yaml' );
    ok( $one->export_db( 'fixtures/testdata-jazz-export', 1,
            {
                type => 'white',
                client => 1,
            }
    ));
    ok( -f 'fixtures/testdata-jazz-export/client.yaml' );
    ok( not -e 'fixtures/testdata-jazz-export/groups.yaml' );
    ok( not -e 'fixtures/testdata-jazz-export/client_assessment_old.yaml' );

    # black
    ok( -d 'fixtures/testdata-jazz-export' );
    ok( clean_dir, 'clean_dir' );
    ok( not -e 'fixtures/testdata-jazz-export/client.yaml' );
    ok( not -e 'fixtures/testdata-jazz-export/groups.yaml' );
    ok( $one->export_db( 'fixtures/testdata-jazz-export', 1,
            {
                type => 'black',
                client => 0,
            }
    ));
    ok( not -e 'fixtures/testdata-jazz-export/client.yaml' );
    ok( -f 'fixtures/testdata-jazz-export/groups.yaml' );

    ok( clean_dir, 'clean_dir' );
    ok( not -e 'fixtures/testdata-jazz-export/client.yaml' );
    ok( not -e 'fixtures/testdata-jazz-export/groups.yaml' );
    ok( $one->export_db( 'fixtures/testdata-jazz-export', 1,
            {
                type => 'black',
                client => 1,
            }
    ));
    ok( -e 'fixtures/testdata-jazz-export/client.yaml' );

# tests for export_db exporting

    can_ok( $one, 'export_db' );
    dies_ok { $one->export_db };
    like( $@, qr/Path to save directory needed!.*/ );

    ok( -e 'fixtures' );
    ok( -d 'fixtures/testdata-jazz-export' );

    ok( clean_dir, 'clean_dir' );
    ok( not -e 'fixtures/testdata-jazz-export/client.yaml' );
    ok( not -e 'fixtures/testdata-jazz-export/groups.yaml' );
    ok( $one->export_db( 'fixtures/testdata-jazz-export/' ), 'exportdb' );
    ok( -f 'fixtures/testdata-jazz-export/client.yaml', 'exists client.yaml?' );
    ok( -f 'fixtures/testdata-jazz-export/groups.yaml', 'exists groups.yaml?' );

dbinit( );

