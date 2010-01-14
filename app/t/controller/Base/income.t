# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 46;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Income';
    use_ok( q/eleMentalClinic::Controller::Base::Income/ );
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
        home view edit save save_meta create
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home view edit save save_meta create
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    ok( $one = $CLASS->new_with_cgi_params );
    isa_ok( $one, $CLASS );
    is_deeply( $one->home, { current => undef } );

    ok( $one = $CLASS->new_with_cgi_params );
    isa_ok( $one, $CLASS );
    is_deeply( $one->home( 'triangles' ), { current => 'triangles' } );

    ok( $one = $CLASS->new_with_cgi_params );
    isa_ok( $one, $CLASS );
        $tmp = { a => 'purple', b => 'triangle', quiet => 'socks' };
    is_deeply( $one->home( $tmp ), {
        current => $tmp,
    } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# edit
    # missing rec_id
    ok( $one = $CLASS->new_with_cgi_params( op => 'edit' ));
    isa_ok( $one, $CLASS );
    warnings_like { $one->edit } [];
    is_deeply( $one->errors || [] , [
        '<strong>Record ID</strong> is required.',
    ]);

    # have rec_id
    ok( $one = $CLASS->new_with_cgi_params(
        op      => 'edit',
        rec_id  => 1003,
    ));
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->edit );
    is( $one->errors, undef );
    is_deeply( $tmp->{ current }, eleMentalClinic::Client::Income->new({ rec_id => 1003 })->retrieve );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# view
    # missing rec_id
    ok( $one = $CLASS->new_with_cgi_params( op => 'view' ));
    isa_ok( $one, $CLASS );

    warnings_like { $one->view } [];
    is_deeply( $one->errors, [
        '<strong>Record ID</strong> is required.',
    ]);

    # have rec_id
    ok( $one = $CLASS->new_with_cgi_params(
        op      => 'view',
        rec_id  => 1003,
    ));
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->view );
    is( $one->errors, undef );
    is_deeply( $tmp->{ current }, eleMentalClinic::Client::Income->new({ rec_id => 1003 })->retrieve );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create
    ok( $one = $CLASS->new_with_cgi_params( op => 'create' ));
    isa_ok( $one, $CLASS );
    is_deeply( $one->create, { current => undef, op => 'create' } );

    ok( $one = $CLASS->new_with_cgi_params );
    isa_ok( $one, $CLASS );
    is_deeply( $one->create( 'triangles' ), { current => undef, op => 'create' } );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


dbinit( );


