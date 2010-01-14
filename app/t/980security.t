# vim: ts=4 sts=4 sw=4
use strict;
use warnings;
use Test::More tests => 14;

use eleMentalClinic::Test;
use eleMentalClinic::Test::Mechanize;

my $person = $personnel->{1003};
my $password = "blort123";

my $mech = eleMentalClinic::Test::Mechanize->new_with_server;

$mech->admin_login_ok;
$mech->set_personnel_password( $person->{staff_id}, $password );
$mech->logout_ok;

$mech->login_ok( 1, $person->{login}, $password );
$mech->get_script_ok( 'admin.cgi' );
$mech->content_contains( 'Access denied', 'correct error message' );
