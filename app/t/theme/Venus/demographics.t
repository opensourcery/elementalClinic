# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::EMC;
plan 'no_plan';

test sub {
    my $self = shift;

    run sub {
        my $mech = $self->mech;
        
        $mech->admin_login_ok;
        $mech->get_script_ok('demographics.cgi' => ( client_id => 1001 ));

        $mech->form_name( 'demographics' );

        my %input = (
            lname    => 'Daviss',
            address2 => 'Apt 101',
            phone    => '111-111-1111',
            phone_2  => '111-111-1111',
        );

        $mech->set_fields( %input );

        $mech->click_button( value => 'Save Patient' );

        $mech->id_match_ok( \%input );
    }
};

1;
