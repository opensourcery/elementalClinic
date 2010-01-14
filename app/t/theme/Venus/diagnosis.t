#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More tests => 15;

use lib 't/lib';
use Venus::Mechanize;
use POSIX qw(strftime);

my $mech = Venus::Mechanize->new_with_server;

sub current_diagnosis_date_is {
    my ( $date, $label ) = @_;
    use Data::Dumper;
    is(
        $mech->look_down(_tag => 'form', id => 'diag_select_form')
             ->look_down(_tag => 'option', selected => 'selected')->as_trimmed_text,
        $date,
        $label,
    );
}

$mech->admin_login_ok;

$mech->get_script_ok( 'diagnosis.cgi', ( client_id => 1001 ) );

current_diagnosis_date_is(
    'Jul 20, 2005',
    'default diagnosis date',
);

is_deeply(
    [
        map { $_->as_trimmed_text }
            $mech->tree->look_down( _tag => 'form', id => "diag_select_form" )
                       ->look_down(_tag => 'option')
    ],
    [
        'Jul 20, 2005',
        'May 4, 2005',
    ],
    'found available diagnosis dates',
);

$mech->submit_form_ok(
    {
        form_name => 'diag_select_form',
        fields => {
            diagnosis_id => 1003,
        },
    },
    'view earlier diagnosis',
);

current_diagnosis_date_is(
    'May 4, 2005',
    'earlier diagnosis date',
);

$mech->follow_link_ok(
    { text => 'Edit' },
    'click to edit diagnosis',
);

$mech->submit_form_ok(
    {
        form_name => 'diagnosis_form',
        fields => {
            comment_text => 'this is a diagnosis',
        },
        button => 'op',
    },
    'edit diagnosis',
);

$mech->content_contains( 'this is a diagnosis' );

$mech->follow_link_ok(
    { text => 'Clone' },
    'clone diagnosis',
);

$mech->id_match_ok(
    {
        diagnosis_1a => '292.89 Other/Unknown Substance Intoxication',
        diagnosis_1b => '300.30 Obsessive Compulsive Disorder',
        diagnosis_1c => '000.00 No Data Available',
        diagnosis_date => strftime('%Y-%m-%d', localtime),
        diagnosis_5_current => 25,
        comment_text => 'this is a diagnosis',
    },
);

$mech->follow_link_ok(
    { text => 'Cancel' },
    'cancel',
);

$mech->follow_link_ok(
    { text => 'New' },
    'create new',
);

$mech->id_match_ok(
    {
        diagnosis_1a => undef,
        diagnosis_1b => undef,
        diagnosis_1c => undef,
        diagnosis_date => strftime('%Y-%m-%d', localtime),
        diagnosis_5_current => '',
        comment_text => '',
    },
);

