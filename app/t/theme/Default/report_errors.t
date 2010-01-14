# vim: ts=4 sts=4 sw=4

use strict;
use warnings;
use Test::More 'no_plan';

use eleMentalClinic::Test;
use eleMentalClinic::Test::Mechanize;

my $mech = eleMentalClinic::Test::Mechanize->new_with_server;

$mech->admin_login_ok;
$mech->get_script_ok( 'report.cgi' );
$mech->submit_form_ok(
    {
        form_name => 'formid',
        fields => {
            report_name => 'hospital',
        }
    },
);

$mech->submit_form_ok(
    {
        form_name => 'run_report',
        fields => {
            start_date => '2009-06-02',
            end_date   => '2009-06-01',
        },
    },
);

$mech->content_contains('End date must be after start date');
