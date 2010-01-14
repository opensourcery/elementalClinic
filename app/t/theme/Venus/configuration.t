#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';
use Venus::Mechanize;

my $mech = Venus::Mechanize->new_with_server;

$mech->admin_login_ok;

$mech->follow_link_ok({ text => 'Admin & Setup' });
$mech->follow_link_ok({ text => 'Configuration' });

$mech->content_contains( 'Admin: Configuration', 'did not die' );

$mech->submit_form_ok(
    {
        form_name => 'config_form',
        button => 'op',
    },
);

$mech->content_contains( 'Admin: Configuration', 'did not die' );
