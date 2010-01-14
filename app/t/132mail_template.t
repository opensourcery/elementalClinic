# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 12;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Mail;
use eleMentalClinic::Mail::Recipient;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Mail::Template';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    $test->delete_( 'email_recipients', '*' );
    $test->delete_( 'email', '*' );
    $test->delete_( $CLASS, '*' );
    shift and $test->insert_data;
}

dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new ); 
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    is_deeply( $one->fields, [ qw/ rec_id name subject message subject_attach message_attach clinic_attach / ]);
    is_deeply( $one->table, 'email_templates' );

    my $one = $CLASS->new({
        name => 'Test A',
        subject => 'Test A',
        message => 'Test A',
        subject_attach => 1,
        message_attach => 1,
        clinic_attach => 1,
    });
    ok( $one->save );
    is_deeply( 
        $one->mail({ subject => 'S Attach', message => 'M Attach' }),
        eleMentalClinic::Mail->new({
            subject => 'Test A S Attach',
            body => "Test A M Attach\n" . $one->config->org_name,
        }),
    );

    $one->subject_attach( -1 );
    $one->message_attach( -1 );
    ok( $one->save );
    is_deeply( 
        $one->mail({ subject => 'S Attach', message => 'M Attach' }),
        eleMentalClinic::Mail->new({
            subject => 'S Attach Test A',
            body => "M Attach Test A\n" . $one->config->org_name,
        }),
    );

    $one->subject_attach( 0 );
    $one->message_attach( 0 );
    $one->clinic_attach( 0 );
    ok( $one->save );
    is_deeply( 
        $one->mail({ subject => 'S Attach', message => 'M Attach' }),
        eleMentalClinic::Mail->new({
            subject => 'Test A',
            body => 'Test A',
        }),
    );

dbinit();
