# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 127;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Financial';
    use_ok( q/eleMentalClinic::Controller::Base::Financial/ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runmodes
    can_ok( $CLASS, 'ops' );
    ok( my %ops = $CLASS->ops );
    my @oplist = qw/
        home
        select_validation_set
        select_billing_cycle
        billing_1_select
        billing_2 
        billing_2_unselected 
        prognote_toggle_billable 
        prognote_toggle_validity 
        prognote_toggle_manual 
        billing_3_validate 
        billing_4 
        billing_4_validate 
        billing_5 
        billing_5_ecs 
        billing_5_hcfa 
        billing_load_prognotes 
        billing_show_results 
        billing_load_results 
        billing_set_failures_unbillable 
        payments_1_new 
        payments_1_save 
        payments_2_transaction_toggle_error 
        payments_3_save 
        reports_1_run 
        tools_1 
        client_insurance_authorization_request 
        client_insurance_authorization_request_save 
        client_insurance_authorization_request_print 
        tools_2 
        tools_2_save 
        tools_3_save 
        tools_3_new 
        tools_3_preview 
        tools_3_results 
        tools_4_select_notes 
        tools_4_generate_pdf 
        tools_6_bill_manually 
        finish 
        prognote_bounce_prep 
        prognote_bounce 
    /;

    #Make sure the same list is available
    is_deeply( [ sort keys %ops ], [ sort @oplist ]);

    #Make sure the controller has each method
    can_ok( $CLASS, $_ ) for @oplist;

    #Make sure each method runs
    ok( $CLASS, $_ ) for @oplist;

    #Make sure it all works w/ cgi params
    for ( @oplist ) {
        $one = $CLASS->new_with_cgi_params(
            op => $_,
        );
        ok( $one->isa( $CLASS ));
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

