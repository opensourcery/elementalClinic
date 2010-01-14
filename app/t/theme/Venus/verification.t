#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More tests => 10;

use lib 't/lib';
use Venus::Mechanize;
use POSIX qw(strftime);

my $mech = Venus::Mechanize->new_with_server;

$mech->admin_login_ok;

$mech->get_script_ok( 'verification.cgi', ( client_id => 1001 ) );

$mech->content_contains( 'New Verification Letter' );
$mech->content_contains( 'Verification Letters Received' );

is_deeply(
    [
        map { 
            [ map { $_->as_trimmed_text } $_->look_down(_tag => 'td') ]
        } $mech->look_down(id => 'right')->look_down(_tag => 'tr')
    ],
    [
        [], # the header comes out as a tr for some reason
        [
            '10/01/2005',
            '1001',
            'Clinician, Betty (MSW)',
            'ima',
            '08/01/2005',
        ],
        [
            '10/01/2006',
            '1002',
            'Batts, Barbara',
            'betty',
            '08/01/2006',
        ],
    ],
    'existing letters',
);

$mech->submit_form_ok(
    {
        form_name => 'verification_form',
        fields => {
            apid_num => '1003',
            rolodex_treaters_id => 1002, # batts
        },
    },
    'new verification letter',
);

my $today = strftime("%m/%d/%Y", localtime);
is_deeply(
    [
        map { $_->as_trimmed_text } 
            ($mech->look_down(id => 'right')->look_down(_tag => 'tr'))[-1]
            ->look_down(_tag => 'td')
    ],
    [
        $today,
        1003,
        'Batts, Barbara',
        'clinic',
        $today,
    ],
    'new verification letter saved',
);

$mech->submit_form_ok(
    {
        form_name => 'verification_form',
        fields => {
            apid_num => '1003',
            rolodex_treaters_id => 1002, # batts
        },
    },
    'duplicate verification letter',
);

$mech->content_contains( 'APID# 1003 is already in use for this patient.' );
