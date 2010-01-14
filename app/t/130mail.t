# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 22;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Mail::Recipient;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Mail';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    $test->delete_( 'email_recipients', '*' );
    $test->delete_( 'email', '*' );
    shift and $test->insert_data;
}

dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new ); 
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    is_deeply( $one->fields, [ qw/ rec_id sender_id subject body send_date / ]);
    is( $one->table, 'email' );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Check header generation.

    $one = $CLASS->new({
        sender_id => 1001,
        subject => 'test',
        body => 'Test Message',
    });
    ok( $one->_save );
    $one = $CLASS->retrieve( $one->id );
    ok( not $one->header ); #Cannot generate a header w/o a recipient.

    my $address = eleMentalClinic::Client->retrieve( 1001 )->email;
    $one->recipients([ qw/ 1001 / ]);
    is_deeply( $one->header, "From: fake\@fake.fke\nSubject: test\nTo: " . $address . "\n" );

    $one->recipients([ 1001, 1002 ]);
    is_deeply( 
        $one->header, 
        "From: fake\@fake.fke\nSubject: test\nTo: "
        . join( ', ', map { eleMentalClinic::Client->retrieve( $_ )->email } @{ $one->recipients })
        ."\n" 
    );
    ok( $one->_save );
    is_deeply(
        [ map { $_->client_id } @{ $one->stored_recipients }],
        [
            1001,
            1002,
        ]
    );

    $one = $CLASS->new({
        sender_id => 1001,
        subject => 'test',
        body => 'Test Message',
    });
    ok( $one->_save );
    $one = $CLASS->retrieve( $one->id );
    ok( not $one->header ); #Cannot generate a header w/o a recipient.
   
    $one->recipients([ qw/ bob@bob.com / ]);
    is_deeply( $one->header, "From: fake\@fake.fke\nSubject: test\nTo: bob\@bob.com\n" );

    $one->recipients([ 1001, 'bob1@bob.com', 1002, 'fred@bob.com' ]);
    is_deeply( 
        $one->header, 
        "From: fake\@fake.fke\nSubject: test\nTo: "
        . join( ', ', map { $_ =~ m/\@/ ? $_ : eleMentalClinic::Client->retrieve( $_ )->email } @{ $one->recipients })
        ."\n" 
    );

    ok( $one->_save );
    is_deeply(
        [ map { $_->client_id || $_->email_address } @{ $one->stored_recipients }],
        [
            1001,
            'bob1@bob.com',
            1002,
            'fred@bob.com',
        ]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Check message

    is_deeply(
        $one->message,
        $one->header . "\nTest Message",
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# send should save, and a new id each time.
    eleMentalClinic::Mail::disable_send;

    ok( $one->send );
    my $rec_id = $one->rec_id;
    ok( $one->send );
    is( $one->rec_id, $rec_id + 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Send message is not testable, we don't want to be sending out email all the time.
# As such the function she be kept as small and simple as possible.

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
