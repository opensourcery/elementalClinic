# vim: ts=4 sts=4 sw=4
use strict;
use warnings;
use Test::More 'no_plan';

use eleMentalClinic::Test;
use eleMentalClinic::Test::Mechanize;
use eleMentalClinic::Role;

my $person = $personnel->{1003}; # Willy Writer
my $password = 'blort12345';

my $admin = eleMentalClinic::Test::Mechanize->new_with_server;
my $user = $admin->clone;

# set password
$admin->admin_login_ok;
$admin->set_personnel_password( $person->{staff_id}, $password );

# turn reports security on
$admin->get_script_ok( 'admin.cgi' );
$admin->follow_link_ok({ url_regex => qr/op=configuration/ });
$admin->submit_form_ok(
    {
        form_name => 'config_form',
        fields => {
            enable_role_reports => 'on',
        },
        button => 'op',
    },
    'enable_role_reports => on',
);

# test without permission
$user->login_ok( 1, $person->{login}, $password );
$user->get_script_ok( 'report.cgi' );
$user->content_contains( 'Access denied' );

# give permission
$admin->get_script_ok( 'personnel.cgi', ( staff_id => $person->{staff_id} ) );

my $reports_id = 'role_' . eleMentalClinic::Role->get_one_by_( name => 'reports' )->id;

$admin->id_match_ok(
    {
        fname => $person->{fname},
        lname => $person->{lname},
        $reports_id => 0,
    },
    'correct state before saving',
);

$admin->submit_form_ok(
    {
        form_name => 'personnel_security_form',
        fields => {
            $reports_id => 'on',
        },
        button => 'op',
    },
    'reports => on',
);

$admin->id_match_ok(
    {
        fname => $person->{fname},
        lname => $person->{lname},
        $reports_id => 1,
    },
    'correct state after saving',
);

# test with permission
$user->get_script_ok( 'report.cgi' );
$user->content_contains( 'Site Reports' );
