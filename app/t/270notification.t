# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 35;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Client;
use eleMentalClinic::Mail;
use eleMentalClinic::Mail::Template;
use eleMentalClinic::Mail::Recipient;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Notification';
    use_ok( $CLASS );
}

#Override e-mail send function, we do not want to actually send a message.
eleMentalClinic::Mail->disable_send;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}

dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    my $params; #In order to improve clarity I will use this variable to specify parameters for each test.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Overridable methods
    ok( $one->can( 'subject_addon' ));
    ok( $one->can( 'message_addon' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# simple methods

    ok( not $one->sent );
    $one->email_id( 1001 );
    ok( $one->sent );

    is( $one->template_id, $one->config->default_mail_template );

    is_deeply(
        $one->template,
        eleMentalClinic::Mail::Template->retrieve( $one->template_id ),
    );

    $one->email_id( undef );
    ok( not $one->email_id );
    ok( not $one->mail );
    $one->email_id( 1001 );
    is_deeply(
        $one->mail,
        eleMentalClinic::Mail->retrieve( 1001 ),
    );

    ok( not $one->client_id );
    ok( not $one->client );
    $one->client_id( 1001 );
    is_deeply(
        $one->client,
        eleMentalClinic::Client->retrieve( 1001 ),
    );

    ok( not $one->days );
    ok( $one->days( 10 ));
    is( $one->days, 10 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Sendable

    $one->client_id( undef );
    ok( not $one->client );
    ok( not $one->sendable ); # No client
    $one->client_id( 1005 );
    ok( not $one->client->email );
    ok( not $one->sendable ); # No e-mail address
    $one->client_id( 1002 );
    ok( not $one->client->send_notifications );
    ok( not $one->sendable ); # No e-mail address
    $one->client_id( 1001 );
    ok( $one->client );
    ok( $one->client->email );
    ok( $one->client->send_notifications );
    ok( $one->sendable ); # Should be good.

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Send
    $one = $CLASS->new;
    $one->client_id( 1001 );
    ok( $one->send );
    ok( $one->email_id );
    ok( $one->sent );
    is( 
        $one->mail->stored_recipients->[0]->client_id,
        1001
    );
    ok( not $one->mail->stored_recipients->[1] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Send_notifications

    # This feels like it should be tested more than this, but it essentially
    # calls 2 other functions, more testing is done there, so this is
    # *probably* all that is needed here. 

    my $check = $CLASS->send_notifications;
    my $date_used = $check->{ date_used };
    is_deeply( 
        $check,
        {
            Renewal => [
                [ $date_used, 14 ],
                [ $date_used, 7 ],
            ],
            Appointment => [
                [ $date_used, 7 ],
                [ $date_used, 1 ],
            ],
            date_used => $date_used,
        },
        "Correct intervals were used"
    );


dbinit( );
