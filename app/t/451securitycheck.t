# vim: ts=4 sts=4 sw=4
# Copyright (C) 2004-2009 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 63;
use Test::Exception;
use eleMentalClinic::Test;
use eleMentalClinic::Personnel;
use Data::Dumper;

our ($CLASS, $one, $tmp);

BEGIN {
    *CLASS = \'eleMentalClinic::Watchdog::SecurityCheck';
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

    is_deeply( $CLASS->methods, [ qw/params cache watchdog client_id / ]);
    can_ok( $CLASS, @{ $CLASS->methods });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

{
    package Fake::Object;
    sub new { bless( $_[1], $_[0] )};
    sub current_user { shift->{ current_user }};
    sub sub { shift->{ sub }};
    sub kill { 1 };
    sub watchdog { return shift };
    sub package { 'eleMentalClinic::Client' };
    sub clean_watchdog {};
}

is_deeply(
    [ $CLASS->parse_sub_params( 'Fake::Object', [ 'Fake::Object', 'a' .. 'z' ] )],
    [ 'Fake::Object', [ 'a' .. 'z' ]],
    "Parses out class",
);

my $obj = Fake::Object->new({});
is_deeply(
    [ $CLASS->parse_sub_params( 'Fake::Object', [ $obj, 'a' .. 'z' ] )],
    [ $obj, [ 'a' .. 'z' ]],
    "Parses out object",
);

is_deeply(
    [ $CLASS->parse_sub_params( 'Fake::Object', [ 'a' .. 'z' ] )],
    [ undef, [ 'a' .. 'z' ]],
    "Leaves params alone on non-method",
);

my $rootuser = eleMentalClinic::Personnel->retrieve(1);

sub build_class {
    my $obj = $CLASS->new();
    $obj->parse_params(
        Fake::Object->new({ name => 'watchdog' }),
        {},
        a => 'a',
        b => 'b',
        watched => Fake::Object->new({ sub => 'csub' }),
        watched_params => [ Fake::Object->new({ current_user => $rootuser })],
        forbidden => Fake::Object->new({ sub => 'asub' }),
    );
    return $obj;
}

$one = build_class();

is_deeply( $one->watchdog, { name => 'watchdog' }, "Watchdog parsed" );
is_deeply( $one->cache, {}, "cache parsed" );
is_deeply(
    $one->params,
    {
        a => 'a',
        b => 'b',
        watched => { sub => 'csub' },
        watched_params => [ { current_user => $rootuser }],
        forbidden => { sub => 'asub' },
    },
    "params parsed"
);
is_deeply( $one->forbidden, { sub => 'asub' }, "found forbidden" );
is_deeply( $one->sub, 'asub', 'found sub' );
is_deeply( $one->controller, { current_user => $rootuser }, "found controller" );
is_deeply( $one->user, $rootuser, "found user" );
is_deeply( $CLASS->safe_subs, [ qw/primary_key client_id table methods fields accessors_retrieve_many fields_required/ ], "Some fields are safe w/o checking");
for my $sub ( @{ $CLASS->safe_subs }) {
    $one->forbidden->{ sub } = $sub;
    ok( $one->safe_sub, "$sub is safe" );
};

for my $sub ( qw/x y z/ ) {
    $one->forbidden->{ sub } = $sub;
    ok( !$one->safe_sub, "$sub is not safe" );
};

$one->forbidden->{ sub } = 'new';
$one->params->{ forbidden_params } = [ 'eleMentalClinic::Client', { x => 'x' }];
ok( !$one->actual_client_id, 'no id on new()' );

$one = build_class();
$one->forbidden->{ sub } = 'new';
$one->params->{ forbidden_params } = [ 'eleMentalClinic::Client', { client_id => 1001 }];
is( $one->actual_client_id, 1001, 'found id on new()' );

$one = build_class();
$one->forbidden->{ sub } = 'retrieve';
$one->params->{ forbidden_params } = [];
ok( !$one->actual_client_id, 'no id on retrieve()' );

$one = build_class();
$one->forbidden->{ sub } = 'retrieve';
$one->params->{ forbidden_params } = [ 1001 ];
is( $one->actual_client_id, 1001, 'found id on retrieve(#)' );

$one = build_class();
$one->forbidden->{ sub } = 'fname';
$one->params->{ forbidden_params } = [];
ok( !$one->actual_client_id, 'no actual client' );

$one = build_class();
$one->forbidden->{ sub } = 'fname';
my $client = eleMentalClinic::Client->retrieve( 1001 );
$one->params->{ forbidden_params } = [ $client ];
is( $one->actual_client_id, 1001, 'found id on actual client' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$one = build_class();
$one->controller->{ current_user } = undef;
ok( !$one->all_clients, "no user, so not all_clients" );

$one = build_class();
$one->controller->{ current_user } = eleMentalClinic::Personnel->retrieve( 1 ); #admin
ok( $one->all_clients, "admin, all_clients" );
is_deeply( $one->cache, { 1 => { all_users => 1 }}, "Cache is set properly");

$tmp = eleMentalClinic::Personnel->new({
    (map { $_ => 'test' } qw/fname lname mname login/),
    (map { $_ => 1001 } qw/unit_id dept_id/),
});
$tmp->save;

$one = build_class();
$one->controller->{ current_user } = $tmp;
ok( !$one->all_clients, "new user, not all_clients" );
is_deeply( $one->cache, { $tmp->id => { all_users => 0 }}, "Cache is set properly");
eleMentalClinic::Role->retrieve( 2 )->add_personnel( $tmp );
ok( !$one->all_clients, "cached old value" );

$one = build_class();
$one->controller->{ current_user } = $tmp;
ok( $one->all_clients, "new user, added to all, cache cleared" );
is_deeply( $one->cache, { $tmp->id => { all_users => 1 }}, "Cache is set properly");


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

eleMentalClinic::Role->retrieve( 2 )->del_personnel( $tmp );
$tmp->primary_role->grant_client_permission( 1001 );

$one = build_class();
$one->controller->{ current_user } = $tmp;
$one->forbidden->{ sub } = 'retrieve';
$one->params->{ forbidden_params } = [ 1001 ];
is( $one->actual_client_id, 1001, "client id found" );
ok( $one->valid_permissions, "This user can view this client" );

$one = build_class();
$one->forbidden->{ sub } = 'retrieve';
$one->controller->{ current_user } = $tmp;
$one->params->{ forbidden_params } = [ 1002 ];
ok( !$one->valid_permissions, "This user can not view this client" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$one = build_class();
dies_ok { $one->security_exception( 'test' ) } "Security exception thrown";
like( $@, qr/Catchable Exception/, "Catchable death" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub params {
    my ( $client_id, $user ) = @_;
    return (
        Fake::Object->new({ name => 'watchdog' }),
        {},
        a => 'a',
        b => 'b',
        forbidden_params => [ $client_id ],
        watched_params => [ Fake::Object->new({ current_user => $user })],
        forbidden => Fake::Object->new({ sub => 'retrieve' }),
    );
}

$one = build_class();
lives_ok {
    $one->run_checks(
        'x',
        {},
        forbidden_params => [],
        watched_params => [ Fake::Object->new({ current_user => $tmp })],
        forbidden => Fake::Object->new({ sub => 'client_id' })
    )
} "Good with safe sub";
$one = build_class();
lives_ok { $one->run_checks( params( 1001, $tmp ))} "Good with client and permissible personnel";

$one = build_class();
dies_ok { $one->run_checks( params( 1002, $tmp ))} "bad with client and non-permissible personnel";
$one = build_class();
dies_ok { $one->run_checks( params( 1002, undef ))} "bad with no personnel";

eleMentalClinic::Role->retrieve( 2 )->add_personnel( $tmp );
$one = build_class();
lives_ok { $one->run_checks( params( 1002, $tmp ))} "Good with user in all_clients";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$one = build_class();
$client = eleMentalClinic::Client->retrieve( 1004 );
$one->parse_params(
    Fake::Object->new({ name => 'watchdog' }),
    'cache',
    a => 'a',
    b => 'b',
    watched_params => [ Fake::Object->new({ current_user => 'a user' })],
    forbidden_params => [ 'eleMentalClinic::Client', { %$client }],
    forbidden => Fake::Object->new({ sub => 'new' }),
    watched => Fake::Object->new({ sub => 'csub' }),
);

is( $one->actual_client_id, 1004, "Found client_id" );

$one->client_id( 22 );
is( $one->actual_client_id, 22, "Can set client_id" );

for my $staff_id ( 1001 .. 1005 ) {
    my $personnel = eleMentalClinic::Personnel->retrieve( $staff_id );

    $one = build_class();
    $one->controller->{ current_user } = $personnel;
    $one->forbidden->{ sub } = 'retrieve';
    $one->params->{ forbidden_params } = [ 1001 ];
    is( $one->actual_client_id, 1001, "client id found" );
    ok( $one->valid_permissions, "User $staff_id can view client 1001" );
}
