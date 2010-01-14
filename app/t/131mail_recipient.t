# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 17;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Mail::Recipient';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    $test->delete_( $CLASS );
    shift and $test->insert_data;
}

dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new ); 
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    is_deeply( $one->fields, [ qw/ rec_id email_id client_id email_address / ]);
    is_deeply( $one->table, 'email_recipients' );

    my $mail = eleMentalClinic::Mail->new({
        sender_id => 1001, 
        subject => 'Test',
        body => 'Test Message',
    });
    $mail->_save;
    ok( $mail->id );
    $mail = $mail->retrieve( $mail->id );

    $one = $CLASS->new({
        client_id => 1001,
        email_id => $mail->id,
    });

    my $client = eleMentalClinic::Client->retrieve( 1001 );
    is_deeply( $one->client, $client );
    is( $one->address, $client->email );
    is_deeply( $one->mail, $mail );
    ok( $one->save );

    $one = $CLASS->new({
        email_address => 'bob@bob.com',
        email_id => $mail->id,
    });

    ok( not $one->client );
    is( $one->address, 'bob@bob.com' );
    is_deeply( $one->mail, $mail );
    ok( $one->save );

    $one = $CLASS->new({
        client_id => 1001,
        email_address => 'bob@bob.com',
        email_id => $mail->id,
    });

    dies_ok { $one->save };
    like( $@, qr/\QDBD::Pg::st execute failed: ERROR:  new row for relation "email_recipients" violates check constraint "email_recipients_check" at/ );
