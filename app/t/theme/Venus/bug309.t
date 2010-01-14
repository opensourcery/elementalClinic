#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::EMC;
plan tests => 8;

test sub {
    my $self = shift;

    args [
        $self->fixture->random('client'),
    ];

    run sub {
        my ( $client ) = @_;

        my $mech = $self->mech;

        $mech->admin_login_ok;

        $mech->get_script_ok( 'demographics.cgi', ( client_id => $client->{KEY} ) );

        $mech->submit_form_ok(
            {
                form_name => 'demographics',
                fields => {
                    lname => ' ',
                    fname => ' ',
                },
                button => 'op',
            },
            'submit form with blanks',
        );

        like(
            $mech->look_down( _tag => 'div', class => 'errors' )->as_trimmed_text,
            qr/Only words are allowed for $_/,
        ) for 'First name', 'Last name';

        $mech->get_script_ok( 'demographics.cgi', ( client_id => $client->{KEY} ) );

        $mech->id_match_ok(
            {
                fname => $client->{fname},
                lname => $client->{lname},
            },
            'fname and lname have not changed',
        );
    }
}
