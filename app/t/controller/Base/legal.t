# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 34;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Legal';
    use_ok( q/eleMentalClinic::Controller::Base::Legal/ );
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
        home save edit view create
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home save edit view create
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    # no param
    ok( $one->new_with_cgi_params() );
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->home );
    is_deeply( $tmp, {
        current     => undef,
        op          => 'home',
    });

    # one param
    ok( $one->new_with_cgi_params() );
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->home( 'triangles' ));
    is_deeply( $tmp, {
        current     => 'triangles',
        op          => 'home',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# view
    # no param
    ok( $one->new_with_cgi_params( op => 'view' ) );
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->view );
    TODO: {
            local $TODO = 'Should not create $current if missing rec_id';
        warnings_like { $tmp = $one->view } [];
    };

    TODO: {
            local $TODO = 'When skipping creating $current $tmp->{ current } will be undef';
        is_deeply( $tmp, {
            current     => undef,
            op          => 'view',
        });
    };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create
    # no param
    ok( $one->new_with_cgi_params( op => 'create' ) );
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->create );
    is_deeply( $tmp, {
        current     => undef,
        op          => 'home',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# edit
    # no param
    ok( $one->new_with_cgi_params( op => 'edit' ) );
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->edit );
    TODO: {
            local $TODO = 'Should not create $current if missing rec_id';
        warnings_like { $tmp = $one->edit } [];
    };

    TODO: {
            local $TODO = 'When skipping creating $current $tmp->{ current } will be undef';
        is_deeply( $tmp, {
            current     => undef,
            op          => 'edit',
        });
    };


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit( );

