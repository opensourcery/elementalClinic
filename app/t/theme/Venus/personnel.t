#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More tests => 25;

use lib 't/lib';
use Venus::Mechanize;
use eleMentalClinic::Role;

my $mech = Venus::Mechanize->new_with_server;

$mech->admin_login_ok; 

$mech->follow_link_ok({ text => 'Admin & Setup' });

$mech->follow_link_ok({ text => 'Personnel' });

$mech->content_contains( 'View person' );

$mech->content_contains( 'New person' );

my @ids = map { $_->attr('value') }
    $mech->tree->look_down(id => 'staff_id')->content_list;

for my $staff_id (@ids) {
    $mech->submit_form_ok(
        {
            form_name => 'chooser',
            fields => {
                staff_id => $staff_id,
                op => 'View person',
            },
        },
        "view staff id $staff_id",
    );
}

$mech->form_name( 'chooser' );
$mech->click_button( value => 'New person' );
ok(
    ! $mech->tree->look_down( id => 'chooser' ),
    'no chooser on the new person page',
);

# XXX I hate making up rolodex info in each test that wants it
# XXX I hate even more that personnel addresses aren't separate, though they
# are for rolodex and client entries. :(
my %input = (
    fname => 'Bob',
    lname => 'Bidwell',
    ssn   => '123456789',
    dob   => '1970-01-02',
    addr  => '12345 Anywhere St.',
    city  => 'Boringville',
    state => 'OH',
    zip_code => '12345',
    home_phone => '111-111-1111',
    credentials => 'ASW', # Anti-submarine warfare
    sex => 'Male',
    race => 'Alaskan native',
    marital_status => 'Single',
    next_kin => '???',
    hours_week => '37',
    job_title => 'Cactus Wrangler',
    date_employ => '1990-01-01',
    work_phone => '222-222-2222',
    work_fax   => '333-333-3333',
);

# formatting differences
my %output = (
    %input,
    dob         => 'Jan 2, 1970',
    date_employ => 'Jan 1, 1990',
);
    
$mech->submit_form_ok(
    {
        form_name => 'personnel_demographics',
        fields => \%input,
        button => 'op',
    },
    'submit new person form',
);

my $option = $mech->tree->look_down(id => 'staff_id')->look_down(
    sub {
        shift->as_trimmed_text =~ /^\Q$output{lname}\E, \Q$output{fname}\E\b/
    },
);
ok( $option, 'found entry in chooser for new person' );
my $staff_id = $option->attr('value');

$mech->id_match_ok( \%output, 'saved new person' );

$mech->submit_form_ok(
    {
        form_name => 'security_form',
        button => 'op',
    },
    'edit security form',
);

sub role_id {
    my $name = shift;
    return 'role_' . eleMentalClinic::Role->get_one_by_( name => $name )->id;
}

$mech->submit_form_ok(
    {
        form_name => 'security_form',
        fields => {
            password_expired => 'off',
            role_id('active')  => 'on',
            role_id('admin')   => 'on',
            role_id('service_coordinator') => 'on',
            role_id('scanner') => undef,
            role_id('writer')  => 'on',
        },
        button => 'op'
    },
    'save security form',
);

$mech->id_match_ok(
    {
        role_id('active') => 'Yes',
        role_id('admin')  => 'Yes',
        role_id('service_coordinator') => 'Yes',
        role_id('scanner') => 'No',
        role_id('writer') => 'Yes',
    },
    'security saved',
);

$mech->submit_form_ok(
    {
        form_name => 'tableform',
        fields => {
            # XXX look these up from fixtures?
            item_1004 => 'on', # Assessment,
            item_1006 => 'on', # Consultation
        },
    },
    'change charge codes',
);

$mech->id_match_ok(
    {
        item_1004 => 1,
        item_1006 => 1,
    },
    'charge codes saved',
);

$mech->form_name( 'personnel_demographics' );
$mech->click_button( value => 'Edit' );

$mech->id_match_ok( \%input, 'saved new person (edit)' );

$mech->submit_form_ok(
    {
        form_name => 'personnel_demographics',
        fields => \%input,
        button => 'op',
    },
    '"edit" person',
);

$mech->id_match_ok( \%output, 'saved new person' );

