# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 25;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Notification::Renewal';
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
    is_deeply( $one->fields, [ qw/ rec_id client_id renewal_date email_id days / ] );
    is( $one->table, 'notification_renewal' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Simple methods

    $one->client_id( 1001 );
    my $date = $one->client->renewal_date;
    is( 
        $one->subject_addon,
        "Your card expires on " . $date,
    );
    
    is( 
        $one->message_addon,
<<EOT
=======================================================
Card Expiration
Your card is going to expire on $date.
=======================================================
EOT
    );

    is(
        $one->template_id,
        1001
    );

    is_deeply(
        $one->template,
        eleMentalClinic::Mail::Template->retrieve( 1001 )
    );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Complicated methods

# Force a delete of the nasty buggers. Sometimes they still exist, sometimes they don't, wtf?
map { $_->delete } @{ $CLASS->get_all || [] };
map { $_->delete } @{ $CLASS->get_renewals( '2008-07-10', '10' ) || [] };

my $soon = "2008-07-16";

#Create 4 clients with upcomming renewals, one w/ no address, another w/ no notifications.
my $clientA = eleMentalClinic::Client->new({
    renewal_date => $soon,
    email => 'clianta@a.com',
    send_notifications => 1,
});
my $clientB = eleMentalClinic::Client->new({
    renewal_date => $soon,
    email => 'clientb@b.com',
    send_notifications => 1,
});
my $clientC = eleMentalClinic::Client->new({
    renewal_date => $soon,
    email => 'clientc@c.com',
    send_notifications => 0,
});
my $clientD = eleMentalClinic::Client->new({
    renewal_date => $soon,
    send_notifications => 1,
});
$clientA->save;
$clientB->save;
$clientC->save;
$clientD->save;

# Eval this to ensure our delete occurs in event of error.
eval {

    is_deeply( 
        [ sort( map { $_->id } @{ $CLASS->get_renewals( '2008-07-10', '10' )}) ],
        [ sort(
            $clientA->id,
            $clientB->id,
            $clientC->id,
            $clientD->id,
        )],
        'Should be 4 renewals.',
    );

    $one->config->save({ send_mail_as => 'fake@fake.com' });
    $one->notify( '2008-07-10', '10' );
    my $existing = $CLASS->get_one_by_( 'client_id', $clientA->id );
    is_deeply( 
        $one->get_existing( $clientA, 10 ),
        $existing,
        "Make sure the existing is clientA",
    );
    is( $one->get_existing( $clientA, 5 ), undef, "Do not find renewals of another interval" );
    ok( $existing->sent, "Notification sent" );
    ok( $existing->email_id, "Email id is recorded" );

    $existing = $CLASS->get_one_by_( 'client_id', $clientB->id );
    is_deeply( 
        $one->get_existing( $clientB, 10 ),
        $CLASS->get_one_by_( 'client_id', $clientB->id ),
    );
    ok( $existing->sent );
    ok( $existing->email_id );

    $existing = $CLASS->get_one_by_( 'client_id', $clientC->id );
    is_deeply( 
        $one->get_existing( $clientC, 10 ),
        $CLASS->get_one_by_( 'client_id', $clientC->id ),
    );
    ok( not $existing->sent );
    ok( not $existing->email_id );

    $existing = $CLASS->get_one_by_( 'client_id', $clientD->id );
    is_deeply( 
        $one->get_existing( $clientD, 10 ),
        $CLASS->get_one_by_( 'client_id', $clientD->id ),
    );
    ok( not $existing->sent );
    ok( not $existing->email_id );

};
ok( not $@ );
print Dumper( $@ ) if $@;

# Be Kind Rewind.
dbinit( 0 );
$clientA->delete;
$clientB->delete;
$clientC->delete;
$clientD->delete;
