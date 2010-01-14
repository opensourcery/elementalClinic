# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 118;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Prescription';
    use_ok( q/eleMentalClinic::Controller::Base::Prescription/ );
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
        home create save edit view print
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home create save edit view print
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    # no params
    ok( $one = $CLASS->new_with_cgi_params );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->home );
    is( $tmp->{ current }, undef );
    is( $tmp->{ op }, 'home' );
    is( $tmp->{ staff }->{ fname }, 'Willy' );
    is( $tmp->{ staff }->{ lname }, 'Writer' );
    is( $tmp->{ staff }->{ staff_id }, 1003 );

    # pass in params
    ok( $one = $CLASS->new_with_cgi_params );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->home( 'fire', 'purple' ));
    is( $tmp->{ current }, 'fire' );
    is( $tmp->{ op }, 'purple' );
    is( $tmp->{ staff }->{ fname }, 'Willy' );
    is( $tmp->{ staff }->{ lname }, 'Writer' );
    is( $tmp->{ staff }->{ staff_id }, 1003 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create
    # no params
    ok( $one = $CLASS->new_with_cgi_params( op => 'create' ) );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->create );
    is( $tmp->{ current }, undef );
    is( $tmp->{ op }, 'create' );
    is( $tmp->{ staff }->{ fname }, 'Willy' );
    is( $tmp->{ staff }->{ lname }, 'Writer' );
    is( $tmp->{ staff }->{ staff_id }, 1003 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# edit
    # no params
    ok( $one = $CLASS->new_with_cgi_params( op => 'edit' ) );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->edit );
    is_deeply( $one->errors, [
        '<strong>Prescription</strong> is required.',
    ]);
    is( ref( $tmp->{ current } ), 'eleMentalClinic::Client::Medication' );
    is( $tmp->{ current }->{ $_ }, undef ) for ( keys %{ $tmp->{ current } } );
    is( $tmp->{ op }, 'edit' );
    is( $tmp->{ staff }->{ fname }, 'Willy' );
    is( $tmp->{ staff }->{ lname }, 'Writer' );
    is( $tmp->{ staff }->{ staff_id }, 1003 );

    # prescription id
    ok( $one = $CLASS->new_with_cgi_params(
        op              => 'edit',
        prescription_id => 1002,
    ) );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->edit );
    is( $one->errors, undef );
    is( $tmp->{ current }->{ client_id }, 1003 );
    is( $tmp->{ current }->{ rec_id }, 1002 );
    is( $tmp->{ current }->{ start_date }, '1978-03-11' );
    is( ref( $tmp->{ current } ), 'eleMentalClinic::Client::Medication' );
    is( $tmp->{ op }, 'edit' );
    is( $tmp->{ staff }->{ fname }, 'Willy' );
    is( $tmp->{ staff }->{ lname }, 'Writer' );
    is( $tmp->{ staff }->{ staff_id }, 1003 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# view
    # no params
    ok( $one = $CLASS->new_with_cgi_params( op => 'view' ) );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->view );
    is_deeply( $one->errors, [
        '<strong>Prescription</strong> is required.',
    ]);
    is( ref( $tmp->{ current } ), 'eleMentalClinic::Client::Medication' );
    is( $tmp->{ current }->{ $_ }, undef ) for ( keys %{ $tmp->{ current } } );
    is( $tmp->{ op }, 'view' );

    # prescription id
    ok( $one = $CLASS->new_with_cgi_params(
        op              => 'view',
        prescription_id => 1002,
    ) );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->view );
    is( $one->errors, undef );
    is( $tmp->{ current }->{ client_id }, 1003 );
    is( $tmp->{ current }->{ rec_id }, 1002 );
    is( $tmp->{ current }->{ start_date }, '1978-03-11' );
    is( ref( $tmp->{ current } ), 'eleMentalClinic::Client::Medication' );
    is( $tmp->{ op }, 'view' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    # missing data
    ok( $one = $CLASS->new_with_cgi_params( op => 'save' ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->save );
    is_deeply( $one->errors, [
        '<strong>Client</strong> is required.',
        '<strong>Date</strong> is required.',
    ]);
    is( $tmp->{ current }->{ $_ }, undef, "undef $_" ) for( keys %{ $tmp->{ current }});
    is( $tmp->{ op }, 'create' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit( );

