# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 54;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::ECS::Connection';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
    financial_reset_sequences();
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor

    ok( $one = $CLASS->empty );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

    # Now turn off the warnings about Device::Modem - we only need to see that once in this test file.
    $eleMentalClinic::Base::TESTMODE = 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# init
    can_ok( $one, 'init' );
    throws_ok{ $CLASS->new } qr/required/;
    ok( $one = $CLASS->new({
        claims_processor_id => 1001
    }) );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# methods that must be subclassed
    throws_ok{ $one->connect } qr/subclass/;
    throws_ok{ $one->disconnect } qr/subclass/;
    throws_ok{ $one->put_file } qr/subclass/;
    throws_ok{ $one->get_files } qr/subclass/;
    throws_ok{ $one->get_new_files } qr/subclass/;
    throws_ok{ $one->list_files } qr/subclass/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_connection
    can_ok( $one, 'get_connection' );
    throws_ok{ $one->get_connection } qr/object/;

    ok( $one = $CLASS->new({
        claims_processor_id => 999
    }) );
    throws_ok{ $one->get_connection } qr/No SFTP or dial-up host found for this claims processor/;
    
    # 1001
    ok( $one = $CLASS->new({
        claims_processor_id => 1001
    }) );
    throws_ok{ $one->get_connection } qr/password has expired/;

        $tmp = eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1001 );
        $tmp->password_expires( $tmp->today )->save;
    is_deeply( $one->get_connection, {
        claims_processor_id => 1001
    });
    isa_ok( $one->get_connection, 'eleMentalClinic::ECS::SFTP' );

    # 1002
    ok( $one = $CLASS->new({
        claims_processor_id => 1002
    }) );
    throws_ok{ $one->get_connection } qr/password has expired/;

        $tmp = eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1002 );
        $tmp->password_expires( $tmp->today )->save;
    is_deeply( $one->get_connection, {
        claims_processor_id => 1002
    });
    isa_ok( $one->get_connection, 'eleMentalClinic::ECS::SFTP' );

    # 1003
    ok( $one = $CLASS->new({
        claims_processor_id => 1003
    }) );
    throws_ok{ $one->get_connection } qr/password has expired/;

        $tmp = eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1003 );
        $tmp->password_expires( $tmp->today )->save;
    is_deeply_except(
        { log => undef, modem => undef },  # Device::Modem may or may not be missing, causing differing log msgs
        $one->get_connection, 
        {
            baud_rate           => "38400",
            serial_port         => "/dev/modem",
            init_string         => "AT S7=45 S0=0 L1 V1 X4 &c1 E1 Q0",
            dial_wait_seconds   => 60,
            at_eol              => "\r",
            claims_processor_id => 1003
        }
    );
    isa_ok( $one->get_connection, 'eleMentalClinic::ECS::DialUp' );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# find_new_files
    can_ok( $CLASS, 'find_new_files' );
    is( $CLASS->find_new_files, undef );

    is_deeply( $CLASS->find_new_files( 
        [ 'file1' ] 
    ), [ 'file1' ] );

    is_deeply( $CLASS->find_new_files( 
        [ 'file3', 'file4', 'file5' ],
        [ 'file1', 'file2', 'file3' ],
    ), [ 'file4', 'file5' ] );

    is_deeply( $CLASS->find_new_files( 
        [ 'file2', 'file3', 'file4' ],
        [ 'file1', 'file2', 'file3' ],
    ), [ 'file4' ] );

    is_deeply( $CLASS->find_new_files( 
        [ 'file4', 'file5', 'file6' ],
        [ 'file1', 'file2', 'file3' ],
    ), [ 'file4', 'file5', 'file6' ] );

    is_deeply( $CLASS->find_new_files( 
        [ 'thisfile3', 'afile1', 'somefile2' ],
        [ 'afile1', 'somefile2', 'thisfile3' ],
    ), [] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# append_log
    can_ok( $one, 'append_log' );
    is( $one->append_log, undef );

    is( $one->append_log( '1) Test appending to log ' ), '1) Test appending to log ' );
    is( $one->append_log( '2) Test second append' ), '1) Test appending to log 2) Test second append' );
    is( $one->log, '1) Test appending to log 2) Test second append' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# record_file_receipt
    can_ok( $one, 'record_file_receipt' );

    ok( $one = $CLASS->new({
        claims_processor_id => 1001
    }) );
    throws_ok{ $one->record_file_receipt } qr/required/;

    is( $one->log, undef );
    is_deeply( $one->db->do_sql( 'select name, claims_processor_id from ecs_file_downloaded' ), [] );

    # make the file exist if it doesn't already
    my $edifile = $one->config->edi_in_root . "/sample_835.1.txt";

    open EDIFILE, ">>", $edifile or die "Can't open $edifile: $!";
    close EDIFILE;
    
    is( $one->record_file_receipt( 'sample_835.1.txt' ), 'sample_835.1.txt' );
    is( $one->log, undef );
    is_deeply( $one->db->do_sql( 'select name, claims_processor_id from ecs_file_downloaded' ), [{
        name                => 'sample_835.1.txt',
        claims_processor_id => 1001,
    }]);
    throws_ok{ $one->record_file_receipt( 't/resource/this.file.doesnt.exist' ) } qr/Received the file, but unable to open it/;
    like( $one->log, qr|^Received the file \[t/resource/this.file.doesnt.exist\], but unable to open it| );
    is_deeply( $one->db->do_sql( 'select name, claims_processor_id from ecs_file_downloaded' ), [{
        name                => 'sample_835.1.txt',
        claims_processor_id => 1001,
    }]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

