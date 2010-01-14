# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 37;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Allergies';
    use_ok( q/eleMentalClinic::Controller::Base::Allergies/ );
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
        home save edit
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home save edit
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
        $one = $CLASS->new_with_cgi_params();
    isa_ok( $one, $CLASS );
    is_deeply( $one->home, { current => undef });
    is_deeply( $one->home( 'foo' ), { current => 'foo' });
    TODO: {
        local $TODO = 'Should only allow $current to be Allergy object';
        throws_ok{ $one->home( 'foo' )} qr/Home only accepts an Allergy object/;
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# edit
    # no ID
        $one = $CLASS->new_with_cgi_params( op => 'edit' );
    isa_ok( $one, $CLASS );
    throws_ok{ $one->edit } qr/ID is required/;

    # bad ID
        $one = $CLASS->new_with_cgi_params( op => 'edit', allergy_id => 666 );
    ok( $tmp = $one->edit );
    isa_ok( $tmp->{ current }, 'eleMentalClinic::Client::Allergy' );
    is_deeply( $tmp->{ current }, {
        rec_id => undef,
        active => undef,
        allergy => undef,
        client_id => undef,
        created => undef,
    });

    # good ID
        $one = $CLASS->new_with_cgi_params( op => 'edit', allergy_id => 1003 );
    ok( $tmp = $one->edit );
    isa_ok( $tmp->{ current }, 'eleMentalClinic::Client::Allergy' );
    is_deeply( $tmp->{ current }, {
        rec_id => 1003,
        active => 0,
        allergy => 'iodine',
        client_id => 1002,
        created => '2005-04-05',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    # no data
        $one = $CLASS->new_with_cgi_params( op => 'save' );
    isa_ok( $one, $CLASS );
    is_deeply( $one->save, { current => {
        client_id => undef,
        allergy => undef,
        active  => 0,
    } });
    is_deeply( $one->errors, [ 
        '<strong>Allergy</strong> is required.',
        '<strong>Client</strong> is required.'
    ]);

    # new allergy, no client
        $one = $CLASS->new_with_cgi_params( op => 'save', allergy => 'Peanuts' );
    is_deeply( $one->save, { current => {
        client_id => undef,
        allergy => 'Peanuts',
        active  => 0,
    } });
    is_deeply(
        $one->errors,
        [ '<strong>Client</strong> is required.' ],
    );

    # new allergy, all good data
    # first, see what allergies we have already
    is( eleMentalClinic::Client->retrieve( 1004 )->allergies, undef );
        $one = $CLASS->new_with_cgi_params( op => 'save', allergy => 'Peanuts', client_id => 1004 );
    is_deeply( $one->save, { current => undef });

    is( scalar @{ eleMentalClinic::Client->retrieve( 1004 )->allergies }, 1 );
        $tmp = eleMentalClinic::Client->retrieve( 1004 )->allergies->[ 0 ];
    is( $tmp->client_id, 1004 );
    is( $tmp->allergy, 'Peanuts' );

    # existing allergy, all good data
    is( scalar @{ eleMentalClinic::Client->retrieve( 1004 )->allergies }, 1 );
        $one = $CLASS->new_with_cgi_params( op => 'save', allergy => 'Ground nuts', client_id => 1004, allergy_id => $tmp->id );
    is_deeply( $one->save, { current => undef });

    is( scalar @{ eleMentalClinic::Client->retrieve( 1004 )->allergies }, 1 );
        $tmp = eleMentalClinic::Client->retrieve( 1004 )->allergies->[ 0 ];
    is( $tmp->client_id, 1004 );
    is( $tmp->allergy, 'Ground nuts' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
