# vim: ts=4 sts=4 sw=4
#
# mod_perl tests -- tests dispatcher and other mod_perl features we have added
#

use strict;
use warnings;

use Test::EMC;
plan tests => 32;

use File::Path;
use eleMentalClinic::Test::Mechanize;

test sub {

    args default   => [ undef ];
    args directive => [ 'etc/emc.directive.httpd.conf' ];

    run sub {
        my ($conf) = @_;

        mkdir 'localhost';

        my $mech = eleMentalClinic::Test::Mechanize->new_with_server($conf);

        $mech->response_code_ok($mech->uri_for("/"), 302, "Redirecting to login.cgi");
        $mech->header_ok($mech->uri_for("/"), "Location", "/login.cgi?previous=");

        $mech->admin_login_ok;

        $mech->response_code_ok($mech->uri_for("/"), 200, "at index");

        $mech->logout_ok();

        $mech->response_code_ok($mech->uri_for("/"), 302, "should be redirected to login");
        $mech->header_ok($mech->uri_for("/"), "Location", "/login.cgi?previous=");

        rmtree 'localhost';
    };
        
};
