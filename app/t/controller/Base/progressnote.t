# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 279;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, $tmp_b, $tmp_c);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::ProgressNote';
    use_ok( q/eleMentalClinic::Controller::Base::ProgressNote/ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runmodes
    can_ok( $CLASS, 'ops' );
    ok( my %ops = $CLASS->ops );
    is_deeply( [ sort keys %ops ], [ sort qw/
        home save commit
        bounce_back
        print_psych print_single
        edit view
        charge_codes charge_codes_only
        bounce_respond
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home save commit
        bounce_back
        print_psych print_single
        edit view
        charge_codes charge_codes_only
        bounce_respond
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    # home, no parameters

        $one = $CLASS->new_with_cgi_params();
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

        $tmp = $one->home;
    is( ref $tmp->{ progress_notes }, 'ARRAY' );
    for ( keys %{ $tmp->{ current } } ) {
        is( $tmp->{ current }->{ $_ }, undef );
    }

    # home, no initialization parameters, custom ProgressNote passed in

        $one = $CLASS->new_with_cgi_params();
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

        $tmp_b = eleMentalClinic::ProgressNote->new({
            note_date  => '2008-05-01',
            start_time => '01:15:00',
            end_time   => '13:16:00',
        });

        $tmp = $one->home( $tmp_b );
    is( ref $tmp->{ progress_notes }, 'ARRAY', 'is $tmp->progress_notes an array?' );
    is( $tmp->{ current }->{ start_date }, '2008-05-01 01:15:00' );
    is( $tmp->{ current }->{ end_date }, '2008-05-01 13:16:00' );

    # home, no initialization parameters, custom ProgressNote passed note_committed = true

        $one = $CLASS->new_with_cgi_params();
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

        $tmp_c = eleMentalClinic::ProgressNote->new({
            note_date  => '2008-05-01',
            start_time => '01:15:00',
            end_time   => '13:16:00',
        });
        $tmp_c->note_committed( 1 );

        $tmp = $one->home( $tmp_c );
    is( ref $tmp->{ progress_notes }, 'ARRAY', 'is $tmp->progress_notes an array?' );
    is( $tmp->{ current }->{ start_date }, undef );
    is( $tmp->{ current }->{ end_date }, undef );
    # home, parameters passed in initialization

        $one = $CLASS->new_with_cgi_params(
            op            => 'home',
            notes_from    => '2008-05-01',
            notes_to      => '2008-05-04',
            writer_filter => '1003',
        );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

        $tmp = $one->home;
    is( ref $tmp->{ progress_notes }, 'ARRAY' );
    is( $tmp->{ notes_from }, '2008-05-01' );
    is( $tmp->{ notes_to }, '2008-05-04' );
    is( $tmp->{ writer_filter }, '1003' );

    # home, explicit null parameters passed in initialization

        $one = $CLASS->new_with_cgi_params(
            op            => 'home',
            notes_from    => undef,
            notes_to      => undef,
        );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

        $tmp = $one->home;
    is( ref $tmp->{ progress_notes }, 'ARRAY' );
    is( $tmp->{ notes_from }, undef );
    is( $tmp->{ notes_to }, undef );

    # home, bad parameters passed in initialization

        $one = $CLASS->new_with_cgi_params(
            op            => 'home',
            notes_from    => '2008-05-04',
            notes_to      => '2008-05-01',
            writer_filter => '1003',
        );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

        $tmp = $one->home;
    is( ref $tmp->{ progress_notes }, 'ARRAY' );
    is( $tmp->{ notes_from }, '2008-05-04' );
    is( $tmp->{ notes_to }, '2008-05-01' );
    is( $tmp->{ writer_filter }, '1003' );
    is_deeply( $one->errors,
        [ "End date must be after start date."]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    ok( $one = $CLASS->new_with_cgi_params( op => 'save' ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
    ok( $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 ));

    warning_is { $one->save } undef; #not needing to check for warnings
    is_deeply( $one->errors, [
        "<strong>Client</strong> is required.",
        "<strong>Date</strong> is required.",
    ]);

    # save, missing client, writer, date
    ok( $one = $CLASS->new_with_cgi_params( op => 'save' ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
    ok( $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 ));

    ok( $one->save );
    is_deeply( $one->errors, [
        "<strong>Client</strong> is required.",
        "<strong>Date</strong> is required.",
    ]);

    # save, missing client, writer
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        note_date   => '2008-05-01'
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $one->save );
    is_deeply( $one->errors, [
        "<strong>Client</strong> is required.",
    ]);

    # save, missing client, date
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        writer_id   => 1003
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $one->save );
    is_deeply( $one->errors, [
        "<strong>Client</strong> is required.",
        "<strong>Date</strong> is required.",
    ]);

    # save, missing writer, date
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        client_id   => 1003
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $one->save );
    is_deeply( $one->errors, [
        "<strong>Date</strong> is required.",
    ]);

    # save, missing date
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        client_id   => 1003,
        writer_id   => 1003,
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $one->save );
    is_deeply( $one->errors, [
        "<strong>Date</strong> is required.",
    ]);

    # save, missing client
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        writer_id   => 1003,
        note_date   => '2008-05-01'
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $one->save );
    is_deeply( $one->errors, [
        "<strong>Client</strong> is required.",
    ]);

    # save, missing writer
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        client_id   => 1003,
        note_date   => '2008-05-01'
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $one->save );
    is_deeply( $one->errors || [], [
    ]);

    # save, required initialization parameters, no optional
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        client_id   => 1003,
        writer_id   => 1003,
        note_date   => '2008-05-01'
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->save( writer_id => 1003 ) );
    is( ref $tmp->{ progress_notes }, 'ARRAY' );
    is( $tmp->{ current }->{ client_id }, 1003, 'is client_id 1003?' );
    is( $tmp->{ current }->{ writer }, "Willy Writer" );

    # save, required initialization parameters, optional
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        client_id   => 1004,
        writer_id   => 1004,
        note_date   => '2008-05-01',
        goal_id     => 0,
        start_time  => '12:00:00',
        end_time    => '12:30:00',
        note_body   => 'triangle',
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    ok( $tmp = $one->save );
    is( ref $tmp->{ progress_notes }, 'ARRAY' );
    is( $tmp->{ current }->{ client_id }, 1004 );
    is( $tmp->{ current }->{ writer }, "Number Cruncher" );
    is( $tmp->{ current }->{ start_date }, '2008-05-01 12:00:00', 'start_date' );
    is( $tmp->{ current }->{ end_date }, '2008-05-01 12:30:00', 'end_date' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# print_psych
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'print_psych',
    ));
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->print_psych );
    is( $_, undef ) for ( values %{ $tmp->{ current } } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# print_single
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'print_single',
    ));
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->print_single );
    is( $_, undef ) for ( values %{ $tmp->{ current } } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bounce_respond
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'bounce_respond',
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

        $tmp_b = undef;
        $tmp_b = eleMentalClinic::ProgressNote->new();

    ok( $tmp = $one->bounce_respond( $tmp_b ) );
    is( $_, undef ) for ( values %{ $tmp->{ current } } );
    is( ref( $tmp->{ start_times } ), 'ARRAY' );
    is( ref( $tmp->{ end_times } ), 'ARRAY' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bounce_back
    # no data
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'bounce_back',
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    TODO: {
            local $TODO = "Should not call _note_action when parameters missing, currently dies and warns unnecessarily";
        warnings_like { $one->bounce_back } [];
    };

    is_deeply( $one->errors, [
        '<strong>Charge code</strong> is required.',
        '<strong>Date</strong> is required.',
        '<strong>End time</strong> is required.',
        '<strong>Goal</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Location</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note Body</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note time</strong> must be between 1 minute and 8.0 hours',
        '<strong>Response message</strong> is required.',
        '<strong>Start time</strong> is required.',
    ]);

    # good and bad data
    ok( $one = $CLASS->new_with_cgi_params(
        op                  => 'bounce_back',
        note_date           => 'foobar',
        charge_code_id      => 666,
        response_message    => 12,
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    TODO: {
            local $TODO = "Should not call _note_action when parameters missing, currently dies and warns unnecessarily";
        warnings_like { $one->bounce_back } [];
    };

    is_deeply( $one->errors, [
        '<strong>Date</strong> must include year, month, and date as YYYY-MM-DD',
        '<strong>End time</strong> is required.',
        '<strong>Goal</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Location</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note Body</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note time</strong> must be between 1 minute and 8.0 hours',
        '<strong>Start time</strong> is required.',
    ]);

    # good and bad data
    ok( $one = $CLASS->new_with_cgi_params(
        op                  => 'bounce_back',
        note_date           => '2007-05-01',
        start_time          => '07:07',
        end_time            => '15:15',
        charge_code_id      => 666,
        response_message    => 12,
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

        warnings_like { $one->bounce_back } [];

    is_deeply( $one->errors, [
        '<strong>Goal</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Location</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note Body</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note time</strong> must be between 1 minute and 8.0 hours',
    ]);

    # good and bad data
    ok( $one = $CLASS->new_with_cgi_params(
        op                  => 'bounce_back',
        note_date           => '2007-05-01',
        start_time          => '07:07',
        end_time            => '12:12',
        charge_code_id      => 666,
        response_message    => 12,
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

        warnings_like { $one->bounce_back } [];

    is_deeply( $one->errors, [
        '<strong>Goal</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Location</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note Body</strong> is required unless you select a charge code in: N/A, No Show',
    ]);

    # good data
    ok( $one = $CLASS->new_with_cgi_params(
        op                  => 'bounce_back',
        note_date           => '2007-05-01',
        start_time          => '07:07',
        end_time            => '12:12',
        charge_code_id      => 1,
        response_message    => 'parle',
        writer_id           => 1004,
        rec_id              => 1004,
    ));
    isa_ok( $one, $CLASS, 'je blah' );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

        dies_ok { $one->bounce_back } 'problem, next skip';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# charge_codes
    # bad, no writer
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'charge_codes',
    ), 'charge_codes begin' );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

        is_deeply( $one->errors, [
            '<strong>Writer</strong> is required.'
        ]);

    # good, writer
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'charge_codes',
        writer_id   => 1004,
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    ok( $one->charge_codes );

    # good, writer
    ok( $one = $CLASS->new_with_cgi_params(
        op              => 'charge_codes',
        writer_id       => 1004,
        notes_from      => '2008-05-03',
        notes_to        => '2008-08-02',
        writer_filter   => 'mauve',
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    ok( $tmp = $one->charge_codes );
    is( $tmp->{ notes_from }, '2008-05-03' );
    is( $tmp->{ notes_to }, '2008-08-02' );
    is( $tmp->{ writer_filter }, 'mauve' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# charge_codes_only
    # without params
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'charge_codes_only',
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

        is_deeply( $one->errors, [
            '<strong>Writer</strong> is required.'
        ]);

    # with params
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'charge_codes_only',
        writer_id   => 1004,
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    ok( $tmp = $one->charge_codes_only );
    is( scalar @$tmp, 2 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# commit
    # no data
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'commit',
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    ok( $one->commit );
    is_deeply( $one->errors, [
        '<strong>Charge code</strong> is required.',
        '<strong>Client</strong> is required.',
        '<strong>Date</strong> is required.',
        '<strong>End time</strong> is required.',
        '<strong>Goal</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Location</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note Body</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note time</strong> must be between 1 minute and 8.0 hours',
        '<strong>Start time</strong> is required.',
    ]);

    # no data
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'commit',
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    TODO: {
            local $TODO = "Again, shouldn't warn uninitialized values when missing parameters";
        warnings_are { $one->commit } [];
    };
    is_deeply( $one->errors, [
        '<strong>Charge code</strong> is required.',
        '<strong>Client</strong> is required.',
        '<strong>Date</strong> is required.',
        '<strong>End time</strong> is required.',
        '<strong>Goal</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Location</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note Body</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note time</strong> must be between 1 minute and 8.0 hours',
        '<strong>Start time</strong> is required.',
    ]);

    # some data good and bad
    ok( $one = $CLASS->new_with_cgi_params(
        op              => 'commit',
        charge_code_id  => 666,
        client_id       => 1004,
        note_date       => '2008-05-24',
        start_time      => '03:15:20',
        end_time        => '13:27:18',
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

        warnings_are { $one->commit } [];

    is_deeply( $one->errors, [
        '<strong>Goal</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Location</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note Body</strong> is required unless you select a charge code in: N/A, No Show',
        '<strong>Note time</strong> must be between 1 minute and 8.0 hours',
    ]);

    # yay more data
    ok( $one = $CLASS->new_with_cgi_params(
        op                  => 'commit',
        charge_code_id      => 1,
        client_id           => 1004,
        note_date           => '2008-05-24',
        start_time          => '06:08:15',
        end_time            => '09:52:03',
        writer_id           => 1004,
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    ok( $tmp = $one->commit );
    is( $one->errors, undef );
    is_deeply( $tmp, {
        'Location' => '/progress_notes.cgi?client_id=1004',
    });

    # yay most data
    ok( $one = $CLASS->new_with_cgi_params(
        op                  => 'commit',
        charge_code_id      => 1,
        client_id           => 1003,
        note_date           => '2008-05-24',
        start_time          => '06:08:15',
        end_time            => '09:52:03',
        goal_id             => 666,
        note_location_id    => 666,
        note_body           => 'triangles',
        writer_id           => 1004,
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    ok( $tmp = $one->commit );
    is_deeply( $tmp, {
        'Location' => '/progress_notes.cgi?client_id=1003',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# view
        ok( $one = $CLASS->new_with_cgi_params(
            op          => 'view',
        ));
        isa_ok( $one, $CLASS );

            # otherwise fails as there is no session
            $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

        dies_ok { $one->view };
        is_deeply( $one->errors, [
            '<strong>rec_id</strong> is required.',
        ]);

    # not dying is good
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'view',
        rec_id      => 666,
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    ok( $tmp = $one->view );
    is( ref( $tmp->{ current } ), 'eleMentalClinic::ProgressNote' );
    is( ref( $tmp->{ start_times } ), 'ARRAY' );
    is( ref( $tmp->{ end_times } ), 'ARRAY' );
    ok( defined $tmp->{ valid_charge_codes } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# edit
        ok( $one = $CLASS->new_with_cgi_params(
            op          => 'edit',
        ));
        isa_ok( $one, $CLASS );

            # otherwise fails as there is no session
            $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

        dies_ok { $one->edit };
        is_deeply( $one->errors, [
            '<strong>rec_id</strong> is required.',
        ]);

    # not dying is good
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'edit',
        rec_id      => 666,
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1004 );

    ok( $tmp = $one->edit );
    is( ref( $tmp->{ current } ), 'eleMentalClinic::ProgressNote' );
    is( ref( $tmp->{ start_times } ), 'ARRAY' );
    is( ref( $tmp->{ end_times } ), 'ARRAY' );
    ok( defined $tmp->{ valid_charge_codes } );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit();

