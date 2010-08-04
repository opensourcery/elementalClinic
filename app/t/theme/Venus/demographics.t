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


test sub {
    my $self = shift;

    run sub {
        my $mech = $self->mech;
        
        $mech->admin_login_ok;
        $mech->get_script_ok('demographics.cgi' => ( client_id => 1001 ));

        $mech->form_name( 'demographics' );

        # Emergency contact with no phone.  Should return us to the edit screen.
        my %first_input = (
            emergency_contact_rolodex_fname => "Foo",
            emergency_contact_rolodex_lname => "Bar",
        );
        $mech->set_fields( %first_input );
        $mech->click_button( value => 'Save Patient' );

        $mech->no_content_exceptions_ok;
        $mech->content_errors_like(
            qr/Emergency Contact Phone is required/i,
            "got error about missing emergency contact phone"
        );

        # Just add the phone number.  Leave the rest default to test the defaults.
        my %second_input = (
            emergency_contact_rolodex_phone_number => "555.555.5555"
        );
        $mech->set_fields( %second_input );
        $mech->click_button( value => 'Save Patient' );

        $mech->no_content_exceptions_ok;
        ok !$mech->content_errors, "accepted corrected emergency contact" or diag $mech->content_errors;

        $mech->id_match_ok( { %first_input, %second_input } );
    }
};

1;
