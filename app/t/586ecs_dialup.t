# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 45;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, $valid_connection);
BEGIN {
    *CLASS = \'eleMentalClinic::ECS::DialUp';
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
    # - comment this out while testing with a real connection to get a better idea of what's going on
    $eleMentalClinic::Base::TESTMODE = 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# init
    can_ok( $one, 'init' );
    throws_ok{ $CLASS->new } qr/required/;
    ok( $one = $CLASS->new({
        claims_processor_id => 1003
    }) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# defaults
    can_ok( $one, 'defaults' );

    is_deeply_except( 
        { modem => undef, log => undef },  # Device::Modem may or may not be missing, causing differing log msgs
        $one->new({ 
            dial_wait_seconds   => 10,
            claims_processor_id => 1003
        }), 
        {
            baud_rate           => "38400",
            serial_port         => "/dev/modem",
            init_string         => "AT S7=45 S0=0 L1 V1 X4 &c1 E1 Q0",
            dial_wait_seconds   => 10,
            at_eol              => "\r",
            claims_processor_id => 1003
        }
    );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# generate some files to send, first billing cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( my $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 ) );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );

    my( $testfilepath, $edi_data ) = $billing_cycle->write_837( 1002, '2006-06-29 16:04:25' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    ok( $one = $CLASS->new({
        claims_processor_id => 1003
    }) );
        # For testing with a real live connection
        $valid_connection = ( $one->modem
            and $one->claims_processor->username 
            and $one->claims_processor->password 
            and $one->claims_processor->dialup_number );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# connect
    can_ok( $one, 'connect' );
        $one = $CLASS->empty;
    throws_ok{ $one->connect } qr/object/;
    ok( $one = $CLASS->new({
        claims_processor_id => 1003
    }) );
    SKIP: {
        skip "These tests assume there is not a valid dialup connection in the database.", 2 if $valid_connection;
        is( $one->connect, undef );
        like( $one->log, qr/missing Perl library Device\/Modem.pm.|Missing connection details for Dial Up: username, password and\/or dialup_number/ );
    }
    SKIP: {
        skip "Dialup won't work until there is a valid dialup connection in the database.", 2 unless $valid_connection;
        ok( $one->connect );
        is( $one->disconnect, '' );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# disconnect
    can_ok( $one, 'disconnect' );
        $one = $CLASS->empty;
    ok( $one = $CLASS->new({
        claims_processor_id => 1003
    }) );
    SKIP: {
        skip "This test assumes there is not a valid dialup connection in the database.", 1 if( $valid_connection or $one->modem );
        is( $one->disconnect, undef );
    }
    SKIP: {
        skip "This test assumes there is not a valid dialup connection in the database, but Device::Modem exists.", 1 if( $valid_connection or ! $one->modem );
        throws_ok{ $one->disconnect } qr/(Can't call method "purge_all" on an undefined value|Not connected)/;
    }
    SKIP: {
        skip "Dialup won't work until there is a valid dialup connection in the database.", 2 unless $valid_connection;
        ok( $one->connect );
        is( $one->disconnect, '' );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# put_file 
    can_ok( $one, 'put_file' );

        $one = $CLASS->empty;
    throws_ok{ $one->put_file } qr/required/;
    throws_ok{ $one->put_file( $testfilepath ) } qr/object/;
    ok( $one = $CLASS->new({
        claims_processor_id => 1003
    }) );
    SKIP: {
        skip "This test assumes there is not a valid dialup connection in the database.", 1 if( $valid_connection or $one->modem );
        is( $one->put_file( $testfilepath ), undef );
    }
    SKIP: {
        skip "These tests assume there is not a valid dialup connection in the database, but Device::Modem exists.", 1 if( $valid_connection or ! $one->modem );
        throws_ok{ $one->put_file( $testfilepath ) } qr/Unable to connect with dial-up/;
    }
    SKIP: {
        skip "Dialup won't work until there is a valid dialup connection in the database.", 4 unless $valid_connection;
        ok( my( $files, $result ) = $one->put_file( $testfilepath ) );
        like( $files->[0], qr/GENRPT1002t837P0629.txt_\d+\.\d+|ACK.1002t837P0629.txt_\d+\.\d+|trn\d+\.txt/ );
        like( $files->[1], qr/GENRPT1002t837P0629.txt_\d+\.\d+|ACK.1002t837P0629.txt_\d+\.\d+|trn\d+\.txt/ );
        like( $files->[2], qr/GENRPT1002t837P0629.txt_\d+\.\d+|ACK.1002t837P0629.txt_\d+\.\d+|trn\d+\.txt/ );
            warn $result if $result;
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_new_files, also tests receive_files
    can_ok( $one, 'get_new_files' );
    can_ok( $one, 'receive_files' );

        $one = $CLASS->empty;
    throws_ok{ $one->get_new_files } qr/object/;
    ok( $one = $CLASS->new({
        claims_processor_id => 1003
    }) );
    SKIP: {
        skip "These tests assume there is not a valid dialup connection in the database.", 2 if( $valid_connection or $one->modem );
        is( $one->get_new_files, undef );
        is( $one->receive_files, undef );
    }
    SKIP: {
        skip "These tests assume there is not a valid dialup connection in the database, but Device::Modem exists.", 2 if( $valid_connection or ! $one->modem );
        is( $one->get_new_files, undef );
        throws_ok{ $one->receive_files } qr/(Can't call method "read" on an undefined value|Not connected)/;
    }
    SKIP: {
        skip "Dialup won't work until there is a valid dialup connection in the database.", 1 unless $valid_connection;
        ok( my( $files, $result ) = $one->get_new_files );
        # can't be sure how many files or what they are
            warn Dumper $files;
            warn $result if $result;
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
