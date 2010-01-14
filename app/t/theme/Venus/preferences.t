#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More tests => 10;

use lib 't/lib';
use Venus::Mechanize;

my $mech = Venus::Mechanize->new_with_server;

$mech->admin_login_ok;

$mech->follow_link_ok({ text => 'preferences' });

$mech->submit_form_ok(
    {
        form_name => 'preferences_form',
        fields => {
            active_date => 'off',
        },
    },
);

$mech->content_contains( 'Preferences saved successfully.' );
$mech->id_match_ok(
    {
        active_date => 0,
    },
    'saved',
);

$mech->submit_form_ok(
    {
        form_name => 'password_form',
        fields => {
            password => 'dba',
            new_password => 'tester',
            new_password2 => 'tester',
        },
    },
);

$mech->follow_link_ok({ text => 'logout' });
$mech->login_ok( 1, 'clinic', 'tester' );
