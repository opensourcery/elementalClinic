#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More tests => 13;

use lib 't/lib';
use Venus::Mechanize;

sub intake_ok {
    my ($mech, $input) = @_;

    like $mech->uri, qr{/schedule\.cgi}, 'redirected to schedule';

    $mech->content_contains(
        "$input->{lname}, $input->{fname} $input->{mname}",
        'name shows up'
    );

    $mech->follow_link_ok(
        { text => 'Demographics' },
        'get client overview',
    );

    $mech->id_match_ok( $input, 'client data matches' );
}

my $mech = Venus::Mechanize->new_with_server;

$mech->admin_login_ok;

#diag $mech->uri;
$mech->follow_link_ok(
    { text => 'Long Intake' },
    'start intake',
);

my %input = (
    fname     => 'Sally',
    mname     => 'S',
    lname     => 'Smith',
    sex       => 'Female',
    dob       => '1970-01-01',
    phone     => '111-111-1111',
    phone_2   => '222-222-2222',
    address1  => '12345 A St.',
    address2  => 'Unit #16',
    city      => 'Megatown',
    state     => 'WA',
    post_code => '12345',
);

# TODO: test failure and form-refill

eval {
    $mech->submit_form_ok(
        {
            form_name => 'intake_form',
            fields => \%input,
            button => 'submit',
        },
        'add patient',
    );
}
or is $@, '', 'add patient';

intake_ok( $mech, \%input );

%input = (
    fname => 'Bob',
    mname => 'Q',
    lname => 'Jones',
    sex   => 'Male',
    dob   => '1980-01-01',
    phone => '111-111-1111',
);

$mech->submit_form_ok(
    {
        form_name => 'quick_patient_form',
        fields => \%input,
        button => 'submit',
    },
    'add patient (quick)',
);

intake_ok( $mech, \%input );
