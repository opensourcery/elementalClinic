# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 23;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use CGI;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, $tmp_b, $tmp_c);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Ajax';
    use_ok( q/eleMentalClinic::Controller::Base::Ajax/ );
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
        appointment_edit client_selector
    /]);
    can_ok( $CLASS, $_ ) for qw/
        appointment_edit client_selector
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client_selector
    ok( $one = $CLASS->new_with_cgi_params( op => 'client_selector' ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    warnings_are { $tmp = $one->client_selector } [];
    is( $tmp->{ ajax }, 1 );
    is( $tmp->{ controller }, 'demographics' );
    is( $tmp->{ clients }[0]->{ client_id }, 1006 );
    is( $tmp->{ clients }[0]->{ lname }, 'zData' );

    # TODO: shouldn't warn of uninitialized value, should deal with it
    ok( $one = $CLASS->new_with_cgi_params( op => 'client_selector' ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    warnings_are { $tmp = $one->client_selector } [];
    is( $tmp->{ ajax }, 1 );
    is( $tmp->{ controller }, 'demographics' );
    is( $tmp->{ clients }[0]->{ client_id }, 1006 );
    is( $tmp->{ clients }[0]->{ lname }, 'zData' );

dbinit( );
