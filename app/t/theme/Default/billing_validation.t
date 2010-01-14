# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More 'no_plan';
use eleMentalClinic::Test::Mechanize;

my $mech = eleMentalClinic::Test::Mechanize->new_with_server;

$mech->admin_login_ok;

$mech->follow_link_ok({ text => 'Financial' });
$mech->follow_link_ok({ text => 'Billing' });

$mech->submit_form_ok(
    {
        form_number => 1,
    },
    'submit Begin',
);

$mech->submit_form_ok(
    {
        form_number => 1,
    },
    'submit Review',
);

sub submit_validation_ok {
    my ( $name ) = @_;

    my @checkboxes = $mech->look_down(_tag => 'form')
        ->look_down(_tag => 'input', type => 'checkbox');

    ok(
        $mech->look_down(_tag => 'input', value => $name),
        "found $name button",
    );

    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                map {( $_->attr('name') => 'off' )} @checkboxes
            },
        },
        "submit $name",
    );

    ok(
        $mech->look_down(_tag => 'input', value => "Confirm $name"),
        "found Confirm $name button",
    );

    $mech->submit_form_ok(
        {
            form_number => 1,
        },
        "submit Confirm $name",
    );
}

submit_validation_ok('System Validation');

ok(
    $mech->look_down(
        _tag => 'input', type => 'hidden', name => 'step', value => 4
    ),
    'found hidden step 4 value',
);

$mech->submit_form_ok(
    {
        form_number => 1,
    },
    'move on to Payer Validation',
);

submit_validation_ok('Payer Validation');
