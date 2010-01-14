# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 197;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use List::Util qw/ max /;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Placement';
    use_ok( $CLASS );
}
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

    can_ok( $one, 'client_id' );
    can_ok( $one, 'date' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# forwarded methods
    is_deeply([ $CLASS->event_methods ], [ qw/
        rec_id client_id dept_id program_id level_of_care_id
        staff_id event_date input_date 
        level_of_care_locked intake_id discharge_id
        program personnel level_of_care 
    /]);

    is_deeply([ $CLASS->episode_methods ], [ qw/
        client_id date valid_episode intake_date referral discharge
        initial_diagnosis final_diagnosis
        admit_date referral_date
    /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# event
    can_ok( $one, 'event' );
    is( $one->event, undef );

        $one->client_id( 1001 );
    isa_ok( $one->event, 'eleMentalClinic::Client::Placement::Event' );
    is_deeply( $one->event, $client_placement_event->{ 1007 });

        $one = $CLASS->new({ client_id => 1002 });
    is_deeply( $one->event, $client_placement_event->{ 1008 });

        $one = $CLASS->new({ client_id => 1003 });
    is_deeply( $one->event, $client_placement_event->{ 1013 });
    is( $one->event->dept_id, 1001 );
    is( $one->event->program_id, 1001 );
    is( $one->event->level_of_care_id, 1002 );
    is( $one->event->staff_id, 1002 );

    is( $one->dept_id, 1001 );
    is( $one->program_id, 1001 );
    is( $one->level_of_care_id, 1002 );
    is( $one->staff_id, 1002 );

        $one = $CLASS->new({ client_id => 1001, date => '2005-01-01' });
    is( $one->event, undef );

    is( $one->dept_id, undef );
    is( $one->program_id, undef );
    is( $one->level_of_care_id, undef );
    is( $one->staff_id, undef );

        $one = $CLASS->new({ client_id => 1001, date => '2005-05-04' });
    is_deeply( $one->event, $client_placement_event->{ 1001 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# event, force current
        $one = $CLASS->new({ client_id => 1001, date => '2005-05-04' });
    is_deeply( $one->event, $client_placement_event->{ 1001 });
    is_deeply( $one->event( 'current' ), $client_placement_event->{ 1007 });

        $one = $CLASS->new({ client_id => 1003 });
    is_deeply( $one->event, $client_placement_event->{ 1013 });
        $one = $CLASS->new({ client_id => 1003, date => '2005-03-18' });
    is_deeply( $one->event, $client_placement_event->{ 1010 });
    is_deeply( $one->event( 'current' ), $client_placement_event->{ 1013 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# program
        $one = $CLASS->new;
    is( $one->program, undef );

        $one = $CLASS->new({ client_id => 1001, date => '2005-05-04' });
    is( $one->program->{ rec_id }, $client_placement_event->{ 1001 }->{ program_id });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# level_of_care
        $one = $CLASS->new;
    is( $one->level_of_care, undef );

        $one = $CLASS->new({ client_id => 1001, date => '2005-05-04' });
    is( $one->level_of_care->{ rec_id }, $client_placement_event->{ 1001 }->{ level_of_care_id });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# personnel
        $one = $CLASS->new;
    is( $one->personnel, undef );

        $one = $CLASS->new({ client_id => 1001, date => '2005-05-04' });
    isa_ok( $one->personnel, 'eleMentalClinic::Personnel' );
    is_deeply( $one->personnel->staff_id, $personnel->{ 1001 }->{ staff_id });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# active
        $one = $CLASS->new;
    can_ok( $one, 'active' );
    is( $one->active, undef );

    is( $CLASS->new({ client_id => 1001 })->active, 0 );
    is( $CLASS->new({ client_id => 1002 })->active, 0 );
    is( $CLASS->new({ client_id => 1003 })->active, 1 );
    is( $CLASS->new({ client_id => 1004 })->active, 1 );
    is( $CLASS->new({ client_id => 1005 })->active, 1 );
    is( $CLASS->new({ client_id => 1006 })->active, 1 );

    is( $CLASS->new({ client_id => 1001, date => '2005-01-01' })->active, 0 );
    is( $CLASS->new({ client_id => 1002, date => '2005-01-01' })->active, 0 );
    is( $CLASS->new({ client_id => 1003, date => '2005-01-01' })->active, 0 );
    is( $CLASS->new({ client_id => 1004, date => '2005-01-01' })->active, 0 );
    is( $CLASS->new({ client_id => 1005, date => '2005-01-01' })->active, 0 );
    is( $CLASS->new({ client_id => 1006, date => '2005-01-01' })->active, 0 );

    is( $CLASS->new({ client_id => 1001, date => '2006-04-01' })->active, 0 );
    is( $CLASS->new({ client_id => 1002, date => '2006-04-01' })->active, 0 );
    is( $CLASS->new({ client_id => 1003, date => '2006-04-01' })->active, 1 );
    is( $CLASS->new({ client_id => 1004, date => '2006-04-01' })->active, 1 );
    is( $CLASS->new({ client_id => 1005, date => '2006-04-01' })->active, 1 );
    is( $CLASS->new({ client_id => 1006, date => '2006-04-01' })->active, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_admitted
    can_ok( $one, 'is_admitted' );
    is( $one->is_admitted, undef );

    is( $CLASS->new({ client_id => 1001 })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1002 })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1003 })->is_admitted, 1 );
    is( $CLASS->new({ client_id => 1004 })->is_admitted, 1 );
    is( $CLASS->new({ client_id => 1005 })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1006 })->is_admitted, 1 );

    is( $CLASS->new({ client_id => 1001, date => '2005-01-01' })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1002, date => '2005-01-01' })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1003, date => '2005-01-01' })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1004, date => '2005-01-01' })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1005, date => '2005-01-01' })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1006, date => '2005-01-01' })->is_admitted, 0 );

    is( $CLASS->new({ client_id => 1001, date => '2006-04-01' })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1002, date => '2006-04-01' })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1003, date => '2006-04-01' })->is_admitted, 1 );
    is( $CLASS->new({ client_id => 1004, date => '2006-04-01' })->is_admitted, 1 );
    is( $CLASS->new({ client_id => 1005, date => '2006-04-01' })->is_admitted, 0 );
    is( $CLASS->new({ client_id => 1006, date => '2006-04-01' })->is_admitted, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_referral
    can_ok( $one, 'is_referral' );
    is( $one->is_referral, undef );

    is( $CLASS->new({ client_id => 1001 })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1002 })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1003 })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1004 })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1005 })->is_referral, 1 );
    is( $CLASS->new({ client_id => 1006 })->is_referral, 0 );

    is( $CLASS->new({ client_id => 1001, date => '2005-01-01' })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1002, date => '2005-01-01' })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1003, date => '2005-01-01' })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1004, date => '2005-01-01' })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1005, date => '2005-01-01' })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1006, date => '2005-01-01' })->is_referral, 0 );

    is( $CLASS->new({ client_id => 1001, date => '2006-04-01' })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1002, date => '2006-04-01' })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1003, date => '2006-04-01' })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1004, date => '2006-04-01' })->is_referral, 0 );
    is( $CLASS->new({ client_id => 1005, date => '2006-04-01' })->is_referral, 1 );
    is( $CLASS->new({ client_id => 1006, date => '2006-04-01' })->is_referral, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# was_referral
    can_ok( $one, 'was_referral' );
    is( $one->was_referral, undef );

    is( $CLASS->new({ client_id => 1001 })->was_referral, 0 );
    is( $CLASS->new({ client_id => 1002 })->was_referral, 0 );
    is( $CLASS->new({ client_id => 1003 })->was_referral, 1 );
    is( $CLASS->new({ client_id => 1004 })->was_referral, 0 );
    is( $CLASS->new({ client_id => 1005 })->was_referral, 1 );
    is( $CLASS->new({ client_id => 1006 })->was_referral, 0 );

    is( $CLASS->new({ client_id => 1001, date => '2005-01-01' })->was_referral, 0 );
    is( $CLASS->new({ client_id => 1002, date => '2005-01-01' })->was_referral, 0 );
    is( $CLASS->new({ client_id => 1003, date => '2005-01-01' })->was_referral, 1 );
    is( $CLASS->new({ client_id => 1004, date => '2005-01-01' })->was_referral, 0 );
    is( $CLASS->new({ client_id => 1005, date => '2005-01-01' })->was_referral, 1 );
    is( $CLASS->new({ client_id => 1006, date => '2005-01-01' })->was_referral, 0 );

    is( $CLASS->new({ client_id => 1001, date => '2006-04-01' })->was_referral, 0 );
    is( $CLASS->new({ client_id => 1002, date => '2006-04-01' })->was_referral, 0 );
    is( $CLASS->new({ client_id => 1003, date => '2006-04-01' })->was_referral, 1 );
    is( $CLASS->new({ client_id => 1004, date => '2006-04-01' })->was_referral, 0 );
    is( $CLASS->new({ client_id => 1005, date => '2006-04-01' })->was_referral, 1 );
    is( $CLASS->new({ client_id => 1006, date => '2006-04-01' })->was_referral, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# last discharge
    can_ok( $one, 'last_discharge' );
    is( $one->last_discharge, undef );

    is_deeply(
        $CLASS->new({ client_id => 1001 })->last_discharge,
        $client_discharge->{ 1001 }
    );
    is_deeply(
        $CLASS->new({ client_id => 1002 })->last_discharge,
        $client_discharge->{ 1002 }
    );
    is( $CLASS->new({ client_id => 1003 })->last_discharge, undef );
    ok( $CLASS->new({ client_id => 1004 })->last_discharge );
    is_deeply(
        $CLASS->new({ client_id => 1004 })->last_discharge,
        $client_discharge->{ 1003 }
    );
    is( $CLASS->new({ client_id => 1005 })->last_discharge, undef );
    is( $CLASS->new({ client_id => 1006 })->last_discharge, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# episode
    can_ok( $one, 'episode' );
    is( $one->episode, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# episodes
    can_ok( $one, 'episodes' );

    is( $CLASS->new({ client_id => 666 })->episodes, undef );
        
        $tmp = [ $CLASS->new( { client_id => 1004, date => '2006-03-06' })->episode,
                 $CLASS->new( { client_id => 1004, date => '2005-04-06' })->episode,
               ];
    is_deeply( $CLASS->new({ client_id => 1004 })->episodes, $tmp );
    is_deeply( $CLASS->new({ client_id => 1004 })->episodes->[ 0 ]->events, $tmp->[ 0 ]->events );
    is_deeply( $CLASS->new({ client_id => 1004 })->episodes->[ 1 ]->events, $tmp->[ 1 ]->events );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# change
        $one = $CLASS->new({ client_id => 1003, date => '2006-04-13' });
    can_ok( $one, 'change' );
    is_deeply( $one->event, $client_placement_event->{ 1013 });

    is( $one->change, undef );
    is( $one->date, '2006-04-13' );
    is_deeply( $one->event, $client_placement_event->{ 1013 });

    for( qw/ rec_id client_id input_date /) {
        throws_ok{ $one->change( $_ => 1 )} qr/only allowed/;
    }
    is( $one->date, '2006-04-13' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# allowed changes
# program_id level_of_care_id staff_id event_date 
    ok( $one->change( program_id => 1003 ));
    is( $one->date, '2006-04-13' );
    cmp_ok( $one->event->rec_id,           '>', max( keys %{ $client_placement_event } ) );
    is( $one->event->client_id,            $client_placement_event->{ 1013 }->{ client_id });
    is( $one->event->dept_id,              $client_placement_event->{ 1013 }->{ dept_id });
    is( $one->event->program_id,           1003 );
    is( $one->event->level_of_care_id,     $client_placement_event->{ 1013 }->{ level_of_care_id });
    is( $one->event->staff_id,             $client_placement_event->{ 1013 }->{ staff_id });
    like( $one->event->event_date,         qr/\d{4}-\d{2}-\d{2}/ );
    like( $one->event->input_date,         qr/\d{4}-\d{2}-\d{2}/ );

    ok( $one->change(
        program_id          => 1002,
        level_of_care_id    => 1002,
        staff_id            => 1,
        event_date          => '2006-04-15',
    ));
    is( $one->date, '2006-04-13' );
    cmp_ok( $one->event->rec_id,           '>', max( keys %{ $client_placement_event } ) );
    is( $one->event->client_id,            $client_placement_event->{ 1013 }->{ client_id });
    is( $one->event->dept_id,              $client_placement_event->{ 1013 }->{ dept_id });
    is( $one->event->program_id,           1002 );
    is( $one->event->level_of_care_id,     1002 );
    is( $one->event->staff_id,             1 );
    is( $one->event->event_date,           '2006-04-15' );
    like( $one->event->input_date,         qr/\d{4}-\d{2}-\d{2}/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# edit placement event
        $one = $CLASS->new({ client_id => 1004 });
    can_ok( $one, 'edit' );
    is( $one->event->rec_id,               $client_placement_event->{ 1015 }->{ rec_id });
    is( $one->event->client_id,            $client_placement_event->{ 1015 }->{ client_id });
    is( $one->event->dept_id,              $client_placement_event->{ 1015 }->{ dept_id });
    is( $one->event->input_date,           $client_placement_event->{ 1015 }->{ input_date });
    is( $one->event->program_id,           $client_placement_event->{ 1015 }->{ program_id });
    is( $one->event->level_of_care_id,     $client_placement_event->{ 1015 }->{ level_of_care_id });
    is( $one->event->staff_id,             $client_placement_event->{ 1015 }->{ staff_id });
    is( $one->event->event_date,           $client_placement_event->{ 1015 }->{ event_date });

    # error handling
    for( qw/ rec_id client_id dept_id input_date /) {
        throws_ok{ $one->edit( $_ => 1 )} qr/only allowed/;
    }

    # editing current event
    ok( $one->edit(
        program_id          => 1002,
    ));
    is_deeply( $one->event, { %{ $client_placement_event->{ 1015 }},
        program_id          => 1002,
    });

    ok( $one->edit(
        program_id          => 1003,
        staff_id            => 1002,
        level_of_care_id    => 1002,
    ));
    is_deeply( $one->event, { %{ $client_placement_event->{ 1015 }},
        program_id          => 1003,
        staff_id            => 1002,
        level_of_care_id    => 1002,
    });

    ok( $one->edit(
        program_id          => 1001,
        staff_id            => 1001,
        level_of_care_id    => 1001,
        event_date          => '2000-01-01',
    ));
    is_deeply( $one->event, { %{ $client_placement_event->{ 1015 }},
        program_id          => 1001,
        staff_id            => 1001,
        level_of_care_id    => 1001,
        event_date          => '2000-01-01',
    });

        $one = $CLASS->new({ client_id => 1004, date => '2005-04-06' });
    is_deeply( $one->event, $client_placement_event->{ 1004 });
    ok( $one->edit(
        program_id          => 1002,
    ));
    is_deeply( $one->event, { %{ $client_placement_event->{ 1004 }},
        program_id          => 1002,
    });

    ok( $one->edit(
        program_id          => 1001,
        staff_id            => 1002,
        level_of_care_id    => 1003,
        event_date          => '2000-01-01',
    ));
    is_deeply( $one->event, { %{ $client_placement_event->{ 1004 }},
        program_id          => 1001,
        staff_id            => 1002,
        level_of_care_id    => 1003,
        event_date          => '2000-01-01',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# locked level of care
        $one = $CLASS->new({ client_id => 1004 });
    can_ok( $one, 'level_of_care_locked' );
    is( $one->level_of_care_locked, 0 );

    is( $one->level_of_care_locked( 1 ), 1 );
    is( $one->level_of_care_locked, 1 );
        $one = $CLASS->new({ client_id => 1004 });
    is( $one->level_of_care_locked, 1 ); # retrieve from database

    is( $one->level_of_care_locked( 0 ), 0 );
    is( $one->level_of_care_locked, 0 );
        $one = $CLASS->new({ client_id => 1004 });
    is( $one->level_of_care_locked, 0 ); # retrieve from database

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit()
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

