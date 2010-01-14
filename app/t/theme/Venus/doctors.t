#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More tests => 27;

use lib 't/lib';
use Venus::Mechanize;

my $mech = Venus::Mechanize->new_with_server;

$mech->admin_login_ok;

# Go to the doctors page
$mech->follow_link_ok( { text => 'Doctors' }, 'view doctor list' );
$mech->content_contains( 'Please select a Doctor.', 'doctor list content' );

# Check if we can view a doctor.
$mech->follow_link_ok({ text => 'Batts, Barbara' }, 'view a doctor');
$mech->content_contains( '111-222-3333', 'doctor content (phone)' );
$mech->content_contains( 'Demographics', 'doctor content (demographics)' );

### Create New
$mech->form_name( 'Create Doctor' );
$mech->click_button( value => 'New Doctor' );
$mech->content_contains( 'Save Doctor', 'new doctor page content' );

### change/save demographics
my $submit = {
    fname           => 'First_name',
    lname           => 'Last_name',
    name            => 'Organization_name',
    credentials     => 'The credentials',
    comment_text    => 'Some comment',

    address1        => '999 Xxx St.',
    address2        => 'Unit 99',
    city            => 'Funkytown',
    state           => 'NY',
    post_code       => 99999,
    phone           => '555-555-5555',
    phone_2         => '565-656-5656',
};
$mech->set_fields( %$submit );
$mech->click_button( value => 'Save Doctor' );
$mech->content_contains( 'Last_name, First_name', "Make sure the doctor is saved." );
$mech->follow_link_ok({ text => 'Last_name, First_name (The credentials)' });
$mech->content_contains( 'Demographics', "Editing the doctor" );
for my $field ( keys %$submit ) {
    $mech->content_contains( $submit->{ $field }, "Checking page for: $field" );
}

$mech->id_match_ok( $submit, 'rolodex is saved' );

# use URI's query matching to grab the id
my $edit_link = $mech->tree->look_down(
    _tag => 'a',
    sub { shift->as_trimmed_text =~ /^Last_name, First_name/ },
)->attr('href');

### Follow schedule link
$mech->follow_link_ok({ text => 'Schedule' }, 'view schedule page' );

### Back to Doctors
$mech->get_ok( $edit_link );

### Modify the new one
%$submit = (
  %$submit,
  name     => 'Organization 2',
  phone    => '111-111-1111',
  phone_2  => '111-111-1112',
  address2 => 'Unit 101',
);
$mech->set_fields( %$submit );
my $res = $mech->click_button( value => 'Save Doctor' );

$mech->id_match_ok( $submit, 'doctor organization/phone/address modified' );
