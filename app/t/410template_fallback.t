#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 12;
use eleMentalClinic::Config;
use eleMentalClinic::Theme;
use eleMentalClinic::Test::Mechanize;

use Data::Dumper;

ok(
    ! -e 'themes/Test/templates/allergies',
    'themes/Test/templates/allergies does not exist'
);

sub allergy_content {
    my ( $mech ) = @_;

    $mech->admin_login_ok;

    $mech->get_script_ok( 'allergies.cgi' );

    my $content = $mech->content;

    $mech->form_number( 1 );
    $mech->field( 'allergy', 'humuhumu' );
    $mech->click_button( value => 'Save allergy' );

    ok(
        $mech->look_down(
            _tag => 'li',
            sub { shift->as_trimmed_text =~ 'Client is required' }
        ),
        'correct error message',
    );
    return $content;
}

my $test_content = allergy_content(
    eleMentalClinic::Test::Mechanize->new_with_server(undef, {
        theme => 'Test'
    })
);

my $default_content = allergy_content(
    eleMentalClinic::Test::Mechanize->new_with_server
);

$test_content =~ s/Test/Default/g;

is( $test_content, $default_content, 'Test content and Default content are the same' );

