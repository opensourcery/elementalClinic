# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 43;
use Test::Exception;
use eleMentalClinic::Test;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);

our ($CLASS, $one, $tmp, $valid_connection);
BEGIN {
    *CLASS = \'eleMentalClinic::ECS::SFTP';
    use_ok( $CLASS );
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
    financial_reset_sequences();
}
dbinit( 1 );

my $cpid = 1002;

my $unix_username = 'emcsftp';
my $unix_password = 'emcsftppassword';
my $unix_dir;
my $sshd_port = 9987;
if ( $ENV{EMC_TEST_SFTP} ) {
    $unix_dir = tempdir(CLEANUP => 0);
    diag "setting up sshd in $unix_dir";
    mkpath([ map { "$unix_dir/home/$_" } qw(get put) ]);
    system("touch $unix_dir/home/get/$_")
      for qw(sample_835.1.txt sample_997.1.txt testdownload.txt);

    my $crypted = crypt($unix_password, 'Ox');
    system(qw(sudo useradd -u 27899 -p), $crypted,
        '-d', "$unix_dir/home",
        $unix_username)
        && die "Can't useradd: $?"
        unless getpwnam($unix_username);
    system(qw(sudo chown -R), "$unix_username:", $unix_dir)
        && die "Can't chown: $?";
    system(qw(sudo ssh-keygen -q -f), "$unix_dir/host_key", '-N', '')
        && die "Can't keygen: $?";
    system(qw(sudo /usr/sbin/sshd -e),
           '-p', $sshd_port, '-h', "$unix_dir/host_key")
        && die "Can't start sshd: $?"
        unless !system(qw(pgrep -f), "/usr/sbin/sshd.+-p $sshd_port");
    my $cleanup = sub {
        system(qw(sudo pkill -f),
               "/usr/sbin/sshd.+-p $sshd_port.+$unix_dir/host_key")
            && warn "can't pkill sshd: $?";
        system(qw(sudo userdel -f -r), $unix_username)
            && warn "can't userdel: $?";
    };

    $SIG{INT} = $cleanup;
    END { $cleanup->() if $cleanup }
}

sub use_valid_connection {
    skip "requires valid connection", shift unless $ENV{EMC_TEST_SFTP};
    eleMentalClinic::Financial::ClaimsProcessor
        ->retrieve($cpid)
        ->update({
            name          => 'test-valid',
            username      => $unix_username,
            password      => $unix_password,
            sftp_host     => 'localhost',
            sftp_port     => $sshd_port,
            get_directory => "$unix_dir/home/get",
            put_directory => "$unix_dir/home/put",
        });
    $one = $CLASS->new({ claims_processor_id => $cpid });
}

sub use_invalid_connection {
    return unless $ENV{EMC_TEST_SFTP};
    eleMentalClinic::Financial::ClaimsProcessor
        ->retrieve($cpid)
        ->update({ password => undef });
    $one = $CLASS->new({ claims_processor_id => $cpid });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor

    ok( $one = $CLASS->empty );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# init
    can_ok( $one, 'init' );
    throws_ok{ $CLASS->new } qr/required/;
    ok( $one = $CLASS->new({
        claims_processor_id => $cpid
    }) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# generate some files to send, first billing cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( my $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 ) );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );

    my( $test_file_path, $edi_data ) = $billing_cycle->write_837( $cpid, '2006-06-29 16:04:25' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    ok( $one = $CLASS->new({
        claims_processor_id => $cpid
    }) );
        # For testing with a real live connection
        $valid_connection = ( $one->claims_processor->sftp_host
            and $one->claims_processor->username 
            and $one->claims_processor->password 
            and $one->claims_processor->sftp_port );

    # Now turn off the warnings about Missing connection details - we only need to see that once in this test file.
    # - comment this out while testing with a real connection to get a better idea of what's going on
    $eleMentalClinic::Base::TESTMODE = 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# connect
    can_ok( $one, 'connect' );

    ok( $one = $CLASS->new({
        claims_processor_id => $cpid,
    }) );
SKIP: {
    use_invalid_connection();
    is( $one->connect, undef );
    is( $one->log, 'Missing connection details for SFTP: username, password, host and/or port' );
}
SKIP: {
    use_valid_connection(1);
    isa_ok( $one->connect, 'eleMentalClinic::ECS::SFTP::Helper' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_files
    can_ok( $one, 'list_files' );

        $one = $CLASS->empty;
    throws_ok{ $one->list_files } qr/object/;
    ok( $one = $CLASS->new({
        claims_processor_id => $cpid,
    }) );
SKIP: {
    use_invalid_connection();
    is( $one->list_files, undef );
}
SKIP: {
    use_valid_connection(1);
    is_deeply( [ sort @{ $one->list_files } ], [
        'sample_835.1.txt',
        'sample_997.1.txt',
        'testdownload.txt',
    ] );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# put_file 
    can_ok( $one, 'put_file' );

        $one = $CLASS->empty;
    throws_ok{ $one->put_file } qr/required/;
    throws_ok{ $one->put_file( $test_file_path ) } qr/object/;
    ok( $one = $CLASS->new({
        claims_processor_id => $cpid,
    }) );
SKIP: {
    use_invalid_connection();
    throws_ok{ my( $files, $result ) = $one->put_file( $test_file_path ) } qr/Unable to send billing file/;
    is( $one->log, 'Missing connection details for SFTP: username, password, host and/or port' );
}
SKIP: {
    use_valid_connection(2);
        my( $files, $result ) = $one->put_file( $test_file_path );
    like( $result , qr/Successfully sent billing file/ );
    # check if the response files came through
    unlike( $result, qr/Unable to download/ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_files
    can_ok( $one, 'get_files' );

        $one = $CLASS->empty;
    throws_ok{ $one->get_files } qr/required/;
    throws_ok{ $one->get_files( [ 'testdownload.txt' ] ) } qr/object/;
    ok( $one = $CLASS->new({
        claims_processor_id => $cpid,
    }) );
    throws_ok{ $one->get_files( 'testdownload.txt' ) } qr/ARRAY ref/;
SKIP: {
    use_invalid_connection();
    is_deeply( [ $one->get_files( [ 'testdownload.txt' ] ) ], [ [ ], 'Unable to download any files: testdownload.txt' ] );
}
SKIP: {
    use_valid_connection(4);
    is_deeply( [ $one->get_files( [ 'testdownload.txt' ] ) ], [ [ 'testdownload.txt' ], undef ] );
    is_deeply( [ $one->get_files( [ "${cpid}t835P0108.txt" ] ) ], [ 
        [ ], "Unable to download any files: ${cpid}t835P0108.txt" 
    ] );
    is_deeply( [ $one->get_files( [ 'testdownload.txt', "${cpid}t835P0108.txt" ] ) ], [ 
        [ 'testdownload.txt' ], "Unable to download all of the files. Missing: ${cpid}t835P0108.txt" 
    ] );
    is_deeply( [ $one->get_files( [ 'testdownload.txt', 'sample_835.1.txt' ] ) ], [ 
        [ 'testdownload.txt', 'sample_835.1.txt' ], undef 
    ] );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_new_files
    can_ok( $one, 'get_new_files' );

        $one = $CLASS->empty;
    throws_ok{ $one->get_new_files } qr/object/;
    ok( $one = $CLASS->new({
        claims_processor_id => $cpid,
    }) );
SKIP: {
    use_invalid_connection();
    throws_ok{ $one->get_new_files } qr/No files to download/;
}
SKIP: {
    use_valid_connection(2);
    throws_ok{ $one->get_new_files } qr/No new files to download/;
        $test->delete_( 'ecs_file_downloaded', '*' );
    my ($new, $error) = $one->get_new_files;
    is_deeply( [ [ sort @$new ], $error ], [ [
        'sample_835.1.txt',
        'sample_997.1.txt',
        'testdownload.txt',
    ], undef ] );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
