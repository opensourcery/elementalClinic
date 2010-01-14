# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 73;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Inpatient';
    use_ok( q/eleMentalClinic::Controller::Base::Inpatient/ );
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
    ok( $one = $CLASS->new_with_cgi_params );
    isa_ok( $one, $CLASS );

    # without parameter
    is_deeply( $one->home, {
        current => undef,
        op      => 'home',
    });

    # with parameter
    is_deeply( $one->home( 'foo' ), {
        current => 'foo',
        op      => 'home',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    # missing client_id
    ok( $one = $CLASS->new_with_cgi_params( op => 'save' ) );
    isa_ok( $one, $CLASS );

    ok( $one->save );
    is_deeply( $one->errors, [
        '<strong>Client</strong> is required.',
    ]);

    # just required
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        client_id   => 1003,
    ));
    isa_ok( $one, $CLASS );

    ok( $one->save );

    # tests with varying amounts of good data
        $one = $CLASS->new_with_cgi_params( op => 'save', rec_id => 666, client_id => 1004 );
    isa_ok( $one, $CLASS, 'isa $one $CLASS' );
    is_deeply( $one->save, {
        current => {
            client_id    => 1004,
            rec_id       => 666,
            reason       => undef,
            voluntary    => 0,
            state_hosp   => 0,
            start_date   => undef,
            end_date     => undef,
            htype        => undef,
            hospital     => undef,
            comments     => undef,
            addr         => undef,
        },
        op      => 'save',
    });

        $one = $CLASS->new_with_cgi_params(
            op => 'save',
            rec_id => 666,
            client_id => 1004,
            start_date => '2008-06-01',
            end_date => '2008-06-06'
        );
    isa_ok( $one, $CLASS, 'isa $one $CLASS' );
    is_deeply( $one->save, {
        current => {
            client_id    => 1004,
            rec_id       => 666,
            reason       => undef,
            voluntary    => 0,
            state_hosp   => 0,
            start_date   => '2008-06-01',
            end_date     => '2008-06-06',
            htype        => undef,
            hospital     => undef,
            comments     => undef,
            addr         => undef,
        },
        op      => 'save',
    });

        $one = $CLASS->new_with_cgi_params(
            op           => 'save',
            rec_id       => 666,
            client_id    => 1004,
            start_date   => '2008-06-01',
            end_date     => '2008-06-06',
            reason       => 'dead',
        );
    isa_ok( $one, $CLASS, 'isa $one $CLASS' );
    is_deeply( $one->save, {
        current => {
            client_id    => 1004,
            rec_id       => 666,
            reason       => 'dead',
            voluntary    => 0,
            state_hosp   => 0,
            start_date   => '2008-06-01',
            end_date     => '2008-06-06',
            htype        => undef,
            hospital     => undef,
            comments     => undef,
            addr         => undef,
        },
        op      => 'save',
    });

    # tests with bad data
        $one = $CLASS->new_with_cgi_params(
            op           => 'save',
            rec_id       => 666,
            client_id    => 1004,
            start_date   => '2008-06-01',
            end_date     => '2008-06-06',
            reason       => 'dead',
            state_hosp   => 'foo',
            voluntary    => 'apple',
        );
    isa_ok( $one, $CLASS, 'isa $one $CLASS' );
    TODO: {
            local $TODO = "checkbox::boolean values can be anything but shouldn't";
        is_deeply( $one->save, {
            current => {
                client_id    => 1004,
                rec_id       => 666,
                reason       => 'dead',
                voluntary    => 0,
                state_hosp   => 0,
                start_date   => '2008-06-01',
                end_date     => '2008-06-06',
                addr         => undef,
            },
            op      => 'save',
        });
    };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# edit
    # missing rec_id
    ok( $one = $CLASS->new_with_cgi_params( op => 'edit' ) );
    isa_ok( $one, $CLASS );

    ok( $one->edit );
    is_deeply( $one->errors, [
        '<strong>Record ID</strong> is required.',
    ]);

    # rec_id
    ok( $one = $CLASS->new_with_cgi_params( op => 'edit', rec_id => 666 ) );
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->edit );
    is( $tmp->{ op }, 'edit' );
    is( $tmp->{ current }->{ $_ }, undef, "\$tmp{current}{$_} is undef" ) for keys %{ $tmp->{ current } };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# view
    # missing rec_id
    ok( $one = $CLASS->new_with_cgi_params( op => 'view' ) );
    isa_ok( $one, $CLASS );

    ok( $one->view );
    is_deeply( $one->errors, [
        '<strong>Record ID</strong> is required.',
    ]);

    # rec_id
    ok( $one = $CLASS->new_with_cgi_params( op => 'view', rec_id => 666 ) );
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->view );
    is( $tmp->{ op }, 'view' );
    is( $tmp->{ current }->{ $_ }, undef, "\$tmp{current}{$_} is undef" ) for keys %{ $tmp->{ current } };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create
    ok( $one = $CLASS->new_with_cgi_params( op => 'create' ));
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->create );
    is_deeply( $tmp, {
        current => undef,
        op      => 'create',
    });



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit();

