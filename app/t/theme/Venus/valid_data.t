#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More tests => 110;

use lib 't/lib';
use Venus::Mechanize;

my $mech = Venus::Mechanize->new_with_server;

$mech->admin_login_ok;

$mech->follow_link_ok({ text => 'Admin & Setup' });
$mech->follow_link_ok({ text => 'Lookup tables' });

my $uri = $mech->uri;

my @table_names = map {
    $_->attr('value')
} grep {
    $_->attr('value') # get rid of 'Select a table...'
} $mech->tree->look_down(id => 'table_name')->content_list;

for my $table_name ( @table_names ) {
    $mech->get( $uri );

    eval {
        $mech->submit_form_ok(
            {
                form_name => 'tableform',
                fields => {
                    table_name => $table_name,
                },
            },
            "select table $table_name",
        );
    }
    or is $@, '', "select table $table_name";

    my $select = $mech->tree->look_down(id => 'table_name');

    if ($select) {
        is(
            $select->look_down(selected => 'selected')->attr('value'),
            $table_name,
            "table $table_name is selected",
        );
        if (main->can($table_name)) {
            main->can($table_name)->($mech);
        }
    } else {
        ok( 0, "failed table $table_name (no content found)" );
    }
}

sub valid_data_prognote_location {
    my ( $mech ) = @_;

    $mech->submit_form_ok(
        {
            form_name => 'edit_item_form',
            fields => {
                name => 'a hut',
                description => 'a hut under a tree',
                facility_code => 123,
            },
        },
        'submit bogus facility code',
    );

    my $errors = $mech->look_down(_tag => 'div', class => 'errors');
    ok( $errors, 'errors present' );
    is(
        $errors->look_down(_tag => 'ul')->as_trimmed_text,
        'Facility Code length must be at most 2 characters long.',
        'correct error',
    );

    $mech->submit_form_ok(
        {
            form_name => 'edit_item_form',
            fields => {
                name => 'a hut',
                description => 'a hut by a bridge',
                facility_code => 'ZZ',
            },
        },
        'submit ok facility code',
    );

    $errors = $mech->look_down(_tag => 'div', class => 'errors');
    ok( $errors, 'errors present' );
    is(
        $errors->look_down(_tag => 'ul')->as_trimmed_text,
        'Facility Code must be an integer.',
        'correct error',
    );

    $mech->submit_form_ok(
        {
            form_name => 'edit_item_form',
            fields => {
                name => 'a hut',
                description => 'a hut by a bridge',
                facility_code => '54',
            },
        },
        'submit ok facility code',
    );

    ok( ! $mech->look_down(_tag => 'div', class => 'errors'), 'no errors' );
    my @trs = $mech->look_down(_tag => 'tr');
    ok( 
        grep( { 
            my @tds = $_->look_down(_tag => 'td');
            return unless @tds >= 4;
            return $tds[3]->as_trimmed_text eq '54'
        } @trs),
        'found saved prognote location',
    );
}
