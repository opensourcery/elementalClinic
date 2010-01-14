# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 68;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::ScannedRecord';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    $test->db->do_sql(qq/ SELECT setval( 'client_scanned_record_rec_id_seq', 1001, false ) /);
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
    is( $one->table, 'client_scanned_record');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id filename description created created_by
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clean up in case this test file failed to run completely

        unlink 't/resource/1003a.jpg';
        unlink 't/resource/storetest/client1003/1003a.jpg';
        rmdir 't/resource/storetest/client1003';
        rmdir 't/resource/storetest';
        rmdir 't/resource/scantest';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# do some common setup of the config to known directories

        $one->config->scanned_record_root( 't/resource' );
        $one->config->stored_record_root( 't/resource/storetest' );

        # create the test directories 
        mkdir 't/resource/storetest' or die $!;
        mkdir 't/resource/scantest' or die $!;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_oldest_file
    can_ok( $CLASS, 'get_oldest_file' );

        # reset dir to one with no files
        $one->config->scanned_record_root( 't/resource/scantest' );
    is( $CLASS->get_oldest_file, undef );
        $one->config->scanned_record_root( 'doesntactuallyexist' );
    is( $CLASS->get_oldest_file, undef );

        $one->config->scanned_record_root( 't/resource' );
    is( $CLASS->get_oldest_file, 'log.conf' );
        
        # create a test file there, to test that we get the older file
        open( TESTFILE, ">> t/resource/a.new.file" );
        print TESTFILE "something";
        close TESTFILE;

    is( $CLASS->get_oldest_file, 'log.conf' );

        unlink 't/resource/a.new.file';
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_history
    can_ok( $CLASS, 'get_history' );

    is_deeply( $CLASS->get_history, [] );

        # put in a file
        $CLASS->new({ 
            client_id   => 1001,
            filename    => 'test.jpg',
            description => 'This is one of those test files.',
            created     => '2007-11-20 00:00:00',
            created_by  => 1001,
        })->save;

    is_deeply( $CLASS->get_history, [{
        filename        => 'test.jpg',
        rec_id          => 1001,
        client_id       => 1001,
        client_name     => 'Miles Davis',
        created         => '2007-11-20 00:00:00',
    }] );

        # and add another
        $one = $CLASS->new({ 
            client_id       => 1002,
            filename        => 'testagain.jpg',
            description     => 'This is another one of those test files.',
            created         => '2007-12-20 00:00:00',
            created_by      => 1002,
        })->save;

    is_deeply( $CLASS->get_history, [{
        filename        => 'testagain.jpg',
        rec_id          => 1002,
        client_id       => 1002,
        client_name     => 'Charles Mingus',
        created         => '2007-12-20 00:00:00',
    }, {
        filename        => 'test.jpg',
        rec_id          => 1001,
        client_id       => 1001,
        client_name     => 'Miles Davis',
        created         => '2007-11-20 00:00:00',
    }] );

        # add in more so there are more than 10
        for( 1 .. 10 ){
            $one->{ filename } = 'test' . $_ . '.jpg';
            $one->{ rec_id } = '';
            $one->{ created } = '2007-12-20 ' . $_ . ':00:00';
            $one->save;
        }

    # there should be at most 4 returned
    is( @{ $CLASS->get_history }, 4 );
    is_deeply( $CLASS->get_history->[0], {
        filename        => 'test10.jpg',
        rec_id          => 1012,
        client_id       => 1002,
        client_name     => 'Charles Mingus',
        created         => '2007-12-20 10:00:00',
    } );

    dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_byclient
    can_ok( $CLASS, 'get_byclient' );
    is( $CLASS->get_byclient, undef );
    is( $CLASS->get_byclient( 6666 ), undef );

    is( $CLASS->get_byclient( 1002 ), undef );

        # test with one entry
        $one = $CLASS->new({
            client_id   => 1002,
            filename    => '1002a.jpg',
            created     => '2007-11-20 00:00:00',
            created_by  => 1001,
        })->save;
    isa_ok( $CLASS->get_byclient( 1002 )->[0], $CLASS );
    is_deeply( $CLASS->get_byclient( 1002 ), [{
        rec_id      => 1001,
        client_id   => 1002,
        filename    => '1002a.jpg',
        created     => '2007-11-20 00:00:00',
        created_by  => 1001,
        description => undef,
    }] );

        # test with two entries for same client
        $one = $CLASS->new( {
            client_id   => 1002,
            filename    => '1002b.jpg',
            created     => '2007-11-20 00:00:00',
            created_by  => 1001,
        } )->save;
    is_deeply( $CLASS->get_byclient( 1002 ), [{
        rec_id      => 1001,
        client_id   => 1002,
        filename    => '1002a.jpg',
        created     => '2007-11-20 00:00:00',
        created_by  => 1001,
        description => undef,
    },
    {
        rec_id      => 1002,
        client_id   => 1002,
        filename    => '1002b.jpg',
        created     => '2007-11-20 00:00:00',
        created_by  => 1001,
        description => undef,
    }] );

        # test with an entry for a different client
        $one = $CLASS->new({
            client_id   => 1004,
            filename    => '1004a.jpg',
            created     => '2007-11-20 00:00:00',
            created_by  => 1001,
        })->save;
    is_deeply( $CLASS->get_byclient( 1004 ), [{
        rec_id      => 1003,
        client_id   => 1004,
        filename    => '1004a.jpg',
        created     => '2007-11-20 00:00:00',
        created_by  => 1001,
        description => undef,
    }] );

        # test that we aren't allowed to create a record for the same filename
    dies_ok{ $CLASS->new({
            client_id   => 1005,
            filename    => '1004a.jpg',
            created     => '2007-11-20 00:00:00',
            created_by  => 1001,
        })->save };
    like( $@, qr/duplicate key (?:value )?violates unique constraint/);

    dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# associate
    can_ok( $one, 'associate' );
    
        $one = $CLASS->new;
    throws_ok{ $one->associate } qr/required/;
    
        $one = $CLASS->new({ client_id => 1003 });
    throws_ok{ $one->associate } qr/required/;
    
        $one = $CLASS->new({ filename => 'frog.jpg' });
    throws_ok{ $one->associate } qr/required/;
    
        $one = $CLASS->new({
            client_id   => 1003, 
            filename    => '1003a.jpg',
            created_by  => 1001,
        });
    throws_ok{ $one->associate } qr/does not exist/;

        # create a test file
        open( TESTFILE, ">> t/resource/1003a.jpg" );
        print TESTFILE "something";
        close TESTFILE;

    is( $CLASS->get_byclient( 1003 ), undef );
    ok( -f 't/resource/1003a.jpg' );
    is( -f 't/resource/storetest/client1003/1003a.jpg', undef );

    # associate - should move the file and create a new record
        $one = $CLASS->new({
            client_id   => 1003, 
            filename    => '1003a.jpg',
            created     => '2007-11-21 00:00:00',
            created_by  => 1001,
        });
    ok( $one->associate );

    is( -f 't/resource/1003a.jpg', undef );
    ok( -f 't/resource/storetest/client1003/1003a.jpg' );
    is_deeply( $CLASS->get_byclient( 1003 ), [{
        rec_id      => 1001,
        client_id   => 1003,
        filename    => '1003a.jpg',
        created     => '2007-11-21 00:00:00',
        created_by  => 1001,
        description => undef,
    }] );

    # test re-associating with the same filename
        open( TESTFILE, ">> t/resource/1003a.jpg" );
        print TESTFILE "something";
        close TESTFILE;

        $one = $CLASS->new({
            client_id   => 1004, 
            filename    => '1003a.jpg',
            created     => '2007-11-23 00:00:00',
            created_by  => 1001,
        });
    throws_ok{ $one->associate } qr/already associated with Thelonious Monk, client 1003/;

        # cleanup
        unlink 't/resource/1003a.jpg' or die $!;
        unlink 't/resource/storetest/client1003/1003a.jpg' or die $!;
        dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# disassociate
    can_ok( $one, 'disassociate' );

        $one = $CLASS->new;
    throws_ok{ $one->disassociate } qr/record is not associated/;

        $one = $CLASS->new({ rec_id => 1004 });
    throws_ok{ $one->disassociate } qr/missing client_id/;

        # test with a missing file
        $one = $CLASS->new({
            client_id   => 1004,
            filename    => '1004a.jpg',
            created     => '2007-11-20 00:00:00',
            created_by  => 1001,
        })->save;
    throws_ok{ $one->disassociate } qr/does not exist/;

        # create a test file
        open( TESTFILE, ">> t/resource/1003a.jpg" );
        print TESTFILE "something";
        close TESTFILE;

        $one = $CLASS->new({
            client_id   => 1003, 
            filename    => '1003a.jpg',
            created     => '2007-11-21 00:00:00',
            created_by  => 1001,
        });
    ok( $one->associate );

    # before disassociate    
    is( -f 't/resource/1003a.jpg', undef );
    ok( -f 't/resource/storetest/client1003/1003a.jpg' );
    is_deeply( $CLASS->get_byclient( 1003 ), [{
        rec_id      => 1002,
        client_id   => 1003,
        filename    => '1003a.jpg',
        created     => '2007-11-21 00:00:00',
        created_by  => 1001,
        description => undef,
    }] );

    # disassociate - should move the file and remove the record
    ok( $one->disassociate );

    # after disassociate    
    is( $CLASS->get_byclient( 1003 ), undef );
    ok( -f 't/resource/1003a.jpg' );
    is( -f 't/resource/storetest/client1003/1003a.jpg', undef );

        # cleanup
        unlink 't/resource/1003a.jpg' or die $!;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# invalid_file
    can_ok( $CLASS, 'invalid_file' );
    throws_ok{ $CLASS->invalid_file } qr/required/;

        # create a test file
        open( TESTFILE, ">> t/resource/an.invalid.file" );
        print TESTFILE "something";
        close TESTFILE;
    ok( -f 't/resource/an.invalid.file' );
    is( -f 't/resource/scantest/an.invalid.file', undef );

        $one->config->invalid_scanned_record_root( 'falsedir' );
    throws_ok{ $CLASS->invalid_file( 'an.invalid.file' ) } qr/No such file or directory/;
        $one->config->invalid_scanned_record_root( 't/resource/scantest' );

    # should move the file
    ok( $CLASS->invalid_file( 'an.invalid.file' ) );

    is( -f 't/resource/an.invalid.file', undef );
    ok( -f 't/resource/scantest/an.invalid.file' );

        # cleanup
        unlink 't/resource/scantest/an.invalid.file' or die $!;

    throws_ok{ $CLASS->invalid_file( 'nofileatall' ) } qr/file doesn't exist/;

    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_client_by_filename
    can_ok( $CLASS, 'get_client_by_filename' );

        # create a test file
        open( TESTFILE, ">> t/resource/1003a.jpg" );
        print TESTFILE "something";
        close TESTFILE;
        $one = $CLASS->new({
            client_id   => 1003, 
            filename    => '1003a.jpg',
            created     => '2007-11-21 00:00:00',
            created_by  => 1001,
        });
    ok( $one->associate );

        $one = $CLASS->new;
    throws_ok{ $one->get_client_by_filename } qr/required/;

        $one = $CLASS->new({
            client_id   => 1004, 
            filename    => 'test',
            created     => '2007-11-22 00:00:00',
            created_by  => 1001,
        });
    is( $one->get_client_by_filename, undef );

        $one->filename( '1003a.jpg' );
    is_deeply( $one->get_client_by_filename, $client->{ 1003 } );

        # cleanup
        unlink 't/resource/storetest/client1003/1003a.jpg' or die $!;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clean up of test directories

        rmdir 't/resource/storetest/client1003' or die $!;
        rmdir 't/resource/storetest' or die $!;
        rmdir 't/resource/scantest' or die $!;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
