# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 84;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Notification::Appointment';
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
# constructor
    ok( $one = $CLASS->new ); 
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    is_deeply( $one->fields, [ qw/ rec_id client_id appointment_id email_id days / ] );
    is( $one->table, 'notification_appointment' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Simple methods

    $one->client_id( 1001 );
    $one->appointment_id( 1001 );
    my $date = $one->appointment->schedule_availability->date;
    my $time = $one->appointment->appt_time;
    is( 
        $one->subject_addon,
        "Appointment reminder: "
        .$date
        ." " 
        .$time
    );
    
    is( 
        $one->message_addon,
<<EOT
=======================================================
Appointment Information
Date: $date
Time: $time
=======================================================
EOT
    );

    is(
        $one->template_id,
        1002
    );

    is_deeply(
        $one->template,
        eleMentalClinic::Mail::Template->retrieve( 1002 )
    );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Complicated methods

# This is a full, but bad test.. the reason it is bad is because the addition
# of any appointment to the test data will break it. If you are reading this
# because the test is failing, check that first.

my $loop = 1;
my $total;
#Try 2 different intervals, make sure both send, then make sure a repeat interval does not
for my $days ( 100000, 100001, 100000 ) { 
    $CLASS->notify( '1970-01-01', $days ); #Notify of every appointment in the system...
    my $appointments = eleMentalClinic::Schedule::Appointments->list_upcoming( 
        date => '1970-01-01', 
        days => $days, 
        fields => [ qw/ a.rec_id / ]
    );
    $appointments = [ map { $_->{ rec_id }} @$appointments ];

    for my $appt_id ( @$appointments ) {
        my $notification; 
        for my $item ( @{ $CLASS->get_by_( 'appointment_id', $appt_id )}) {
            $notification = $item if $item->days == $days;
        }
        ok( $notification );
        is( $notification->days, $days, "Days were saved in the notification" );
        if ( $notification->sendable ) {
            ok( $notification->sent );
        }
        else {
            ok( not $notification->sent );
        }
    }

    if ( $loop == 1 ) {
        $total = @{ $CLASS->get_all };
    }
    else {
        # Loop 2 should make it so there is double the total from loop 1,
        # loop 3 is a repeat, no change from loop2
        is( @{ $CLASS->get_all } , ( $total * 2 ), "Make sure the correct number of notifications exist" );
    }
    $loop++;
}
dbinit( 0 );
