#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More tests => 15;

use lib 't/lib';
use Venus::Mechanize;
use POSIX qw(strftime);


my $mech = Venus::Mechanize->new_with_server;

$mech->admin_login_ok; 
$mech->set_configuration({ quick_schedule_availability => 'off' });

$mech->follow_link_ok({ text => 'Schedule' });

is(
    $mech->tree->look_down(id => 'schedule_availability_id')->attr('value'),
    undef,
    'no appointment chosen',
);

#is(
#    $mech->tree->look_down(id => 'calendar')->look_down(_tag => 'strong')
#        ->as_trimmed_text,
#    strftime('%B %Y', localtime),
#    'calendar is on current month',
#);

# XXX no way to test calendar navigation, since the <a>s don't have hrefs

# XXX no javascript means we fake this

$mech->get_script_ok(
    '/schedule.cgi',
    (
        schedule_availability_id => 1006,
        location_id => 0,
    ),
);

my $tr = $mech->tree->look_down(_tag => 'td', class => 'client')->parent;

ok( $tr, 'found row for appointment' );

is_deeply(
    [ map { $_->as_trimmed_text } $tr->look_down(_tag => 'td') ],
    [
        '9:30 a:',
        'Powell, Bud J',
        '', '',
        '$960 Renew',
        'betty',
        'Clinician, Betty (MSW)',
        'delete',
    ],
);

$mech->follow_link_ok(
    { url_regex => qr/op=appointment_remove/ },
    'delete appointment',
);

#is(
#    $mech->tree->look_down(id => 'calendar')->look_down(_tag => 'strong')
#        ->as_trimmed_text,
#    'August 2006',
#    'calendar is still on appointment month',
#);

ok(
    ! $mech->tree->look_down(_tag => 'td', class => 'client'),
    'no appointment row',
);

$mech->submit_form_ok(
    {
        form_name => 'schedule_creation_form',
        # these values aren't magical, they're just "pick something"
        fields => {
            rolodex_id => 1001,
            location_id => 1001,
            date => '2008-01-01',
        }
    },
    'create schedule',
);
my ($option) = grep(
    { $_->as_trimmed_text eq '01/01/2008 : Client Home : Batts : 0' }
    $mech->tree
    ->look_down(id => 'schedule_availability_id')
    ->look_down(_tag => 'option'),
);
ok( $option, 'day is present in schedule dropdown' );
my $value = $option->attr('value');

$mech->submit_form_ok(
    {
        form_name => 'schedule_creation_form',
        fields => {
            rolodex_id => 1001,
            location_id => 1001,
            date => '2008-01-01',
        },
    },
    'create identical schedule',
);
$mech->content_contains(
    'The chosen doctor is already scheduled for that date and location.',
    'correct error message'
);

$mech->follow_link_ok(
    { url_regex => qr/op=delete_day/ },
    'delete entire day',
);

ok(
    ! grep(
        { $value == ($_->attr('value') || 0) }
        $mech->tree
        ->look_down(id => 'schedule_availability_id')
        ->look_down(_tag => 'option'),
    ),
    'day is gone from schedule dropdown',
);
