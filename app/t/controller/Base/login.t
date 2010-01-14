# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 51;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Login';
    use_ok( q/eleMentalClinic::Controller::Base::Login/ );
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
        home expired login logout check logged_out
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home expired login logout check logged_out
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    ok( $one = $CLASS->new_with_cgi_params );
    isa_ok( $one, $CLASS );
    is_deeply( $one->home, { previous => undef } );

    ok( $one = $CLASS->new_with_cgi_params( previous => 'foo' ) );
    isa_ok( $one, $CLASS );
    is_deeply( $one->home, { previous => 'foo' } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# login
    ok( $one = $CLASS->new_with_cgi_params( op => 'login' ) );
    isa_ok( $one, $CLASS );
    ok( $one->login );
    is_deeply( $one->errors, [
        '<strong>Login</strong> is required.',
        '<strong>Password</strong> is required.',
    ], 'login, no info');

    ok( $one = $CLASS->new_with_cgi_params( op => 'login', login => 'foo' ) );
    isa_ok( $one, $CLASS );
    ok( $one->login );
    is_deeply( $one->errors, [
        '<strong>Password</strong> is required.',
    ], 'login, no password');

    ok( $one = $CLASS->new_with_cgi_params( op => 'login', login => 'foo', password => 'bar' ) );
    isa_ok( $one, $CLASS );
    ok( $one->login );
    is_deeply( $one->errors, [
        'Login or password incorrect.',
    ], 'login, bad info');

    ok( $one = $CLASS->new_with_cgi_params( op => 'login', login => 'clinic', password => 'dba' ) );
    isa_ok( $one, $CLASS );
    ok( $tmp = $one->login );
    is( $one->errors, undef, 'login, good info' );

# FIXME: This was commented out w/ __END__, it fails.
{
    local $TODO = "These are broken";
    is_deeply( $tmp, {
        previous    => undef,
        full_screen => 1,
        success     => 1,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check
    ok( $one = $CLASS->new_with_cgi_params( op => 'login' ) );
    isa_ok( $one, $CLASS );
    ok( $tmp = $one->check );
{
    local $TODO = "These are broken";
    is_deeply( $tmp, {
        previous    => undef,
        full_screen => 1,
        success     => 1,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# expire
    ok( $one = $CLASS->new_with_cgi_params( op => 'expired' ));
    is_deeply( $one->expired, $one->home, "expired returns home if it has no user." );
    $one->session->param( expired_id => 1 );
    is_deeply(
        $one->expired,
        {
            previous => undef,
        },
        "User, but no password updates provided"
    );
    is( $one->override_template_name, 'expired', "template is overriden" );

    my $user = eleMentalClinic::Personnel->retrieve( 1 );

    $one = $CLASS->new_with_cgi_params(
        op => 'Save Password',
        new_password_a => 'aaaaaaa',
        new_password_b => 'bbbbbbb',
    );
    ok( $one->expired( $user ));
    is_deeply(
        $one->errors,
        [
            '<strong>New Password</strong> and <strong>Verify New Password</strong> must match.'
        ]
    );

    $one = $CLASS->new_with_cgi_params(
        op => 'Save Password',
        new_password_a => 'aaaaaaa',
        new_password_b => 'aaaaaaa',
    );
    ok( $one->expired( $user ));

    $one = $CLASS->new_with_cgi_params(
        op => 'Save Password',
        new_password_a => 'aaaaaaa',
        new_password_b => 'aaaaaaa',
    );
    ok( $one->expired( $user ));
    is_deeply(
        $one->errors,
        [
            'New password cannot be the same as your old password.'
        ]
    );

    $user->password_expired( 1 );
    $user->save;

    $one = $CLASS->new_with_cgi_params(
        op => 'login',
        login => 'root',
        password => 'password',
    );
    is_deeply(
        $one->login,
        $one->expired( $user ),
    );
    is( $one->override_template_name, 'expired', "Expired" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit();

