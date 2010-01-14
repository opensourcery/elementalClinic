# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 20;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Calendar';
    use_ok( q/eleMentalClinic::Controller::Base::Calendar/ );
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
        popup
    /]);
    can_ok( $CLASS, $_ ) for qw/
        popup
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# popup
    # missing data
    ok( $one = $CLASS->new_with_cgi_params(
        op  => 'popup',
    ));
    isa_ok( $one, $CLASS );

    ok( $one->popup );
    is_deeply( $one->errors, [
        '<strong>Calendar</strong> is required.',
        '<strong>Current date</strong> is required.',
        '<strong>Date format</strong> is required.',
    ]);

    # bad data

    ok( $one = $CLASS->new_with_cgi_params(
        op              => 'popup',
        cid             => 'fake',
        current_date    => 'fake',
        date_format     => 'fake',
    ));
    isa_ok( $one, $CLASS );

    ok( $one->popup );
    TODO: {
        local $TODO = 'Needs checks to make sure params are valid';
        is_deeply( $one->errors || [], [
            'Calendar is invalid.',
            'Current date is invalid.',
            'Date format is invalid.',
        ]);
    };

    # good data
    ok( $one = $CLASS->new_with_cgi_params(
        op              => 'popup',
        cid             => 'dob',
        current_date    => '2000-5-7',
        date_format     => 'mdy',
    ));
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->popup );
    is_deeply( $tmp, {
        cid             => 'dob',
        current_date    => '2000-5-7',
        date_format     => 'mdy',
    });


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit();


