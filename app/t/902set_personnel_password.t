use strict;
use warnings;

use Test::More 'no_plan';

use eleMentalClinic::Test;
use eleMentalClinic::Test::Mechanize;

my $person = $personnel->{1003}; # Willy Writer
my $password = 'blort12345';

my $admin = eleMentalClinic::Test::Mechanize->new_with_server;
my $user = $admin->clone;

$admin->admin_login_ok;
$admin->set_personnel_password( $person->{staff_id}, $password );

$user->get( $user->uri_for( '/' ) );
$user->login_ok( 1, $person->{login}, $password );
