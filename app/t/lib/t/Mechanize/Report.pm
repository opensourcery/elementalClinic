# vim: ts=4 sts=4 sw=4
package t::Mechanize::Report;
use strict;
use warnings;

use eleMentalClinic::Theme;
use Test::More;

sub run {
    my $self = shift;
    my ( $mech ) = @_;

    $mech->admin_login_ok;

    # report list page
    $mech->follow_link_ok( { text => 'Reports' }, 'view reports list' );
    $mech->content_contains( 'Choose Report', 'report list content' );

    # view each report and make sure it doesn't explode
    my $select = $mech->form_name( 'formid' )->find_input( 'report_name' );
    # mech won't return anything here if the select is empty
    ok( $select, 'found report_name select' );

    my %seen;

    for my $report_name ( $select->possible_values ) {
        $seen{ $report_name }++;

        $mech->get_script_ok( 'report.cgi' );

        $mech->form_name( 'formid' );       
        $mech->set_fields(
            report_name => $report_name,
        );

        my ($button) = $mech->tree->look_down(
            _tag => 'input',
            type => 'submit',
            sub { shift->attr('value') =~ /^Choose Report/i },
        );
        $mech->click_button( value => $button->attr('value') );
        $mech->content_contains( 'Run Report', "$report_name: chosen" );

        $mech->form_name( 'run_report' );
        eval {
            $mech->click_button( value => 'Run Report' )
        };
        if ($@) {
            is $@, "", 'error running report';
        } else {
            $mech->content_contains( 'report/display BEGIN', "$report_name: run" );
        }

        eval {
            $mech->follow_link_ok( 
                { text => 'Reports' },
                "$report_name: back to list",
            );
        };
        if ($@) {
            is $@, "", 'error following link: Reports';
        }
    }

    for my $report_name (@{ $mech->theme->available_reports( 'site' ) }) {
        ok( delete $seen{ $report_name }, "saw report $report_name" );
    }
    is_deeply(
        \%seen,
        {},
        "no extra reports seen",
    );
}

1;
