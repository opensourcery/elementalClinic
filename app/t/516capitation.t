# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 530;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

# Turn off the warnings coming from validation during financial setup.
$eleMentalClinic::Base::TESTMODE = 1;

=for docs

This test doesn't exercise any one object, but deals with capitation costs for
clients, billing services, and transactions.

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
    financial_reset_sequences();
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( 1 );
    # authorization.transaction_amount
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 )->transaction_amount, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test that billings that aren't billed (or paid) yet are not counted
my $billing_cycle = $test->financial_setup_billingcycle;
$test->financial_setup_system_validation( $billing_cycle );
$test->financial_setup_payer_validation( $billing_cycle );

    # transaction_amount
    is( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1003 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1005 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1006 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1007 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1008 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1009 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1010 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1011 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1012 )->transaction_amount, 0 );

    # authorization.transaction_amount
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 )->transaction_amount, 0 );

    # update capitation in authorization object {{{
        my $auth;
    # all these should be null
    # 1001 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1001 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1002 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1002 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1003 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1003 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1004 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    is( $auth->capitation_amount_percent, 0 );

    # 1005 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1005 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1006 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1006 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1007 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    is( $auth->capitation_amount_percent, 0 );

    # 1008 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1008 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1009 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    is( $auth->capitation_amount_percent, 0 );

    # 1010 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1010 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1011 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1011 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1012 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1012 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1013 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    is( $auth->capitation_amount_percent, 0 );

    # 1014 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1014 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1015 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1015 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    is( $auth->capitation_amount_percent, 0 );
    #}}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( 1 );
$test->financial_setup( 1 );
    # transaction_amount
    is( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1003 )->transaction_amount, 7.48 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1005 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1006 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1007 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1008 )->transaction_amount, 124.64 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1009 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1010 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1011 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1012 )->transaction_amount, 25.76 );

    # authorization.transaction_amount
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 )->transaction_amount, 657.88 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 )->transaction_amount, 25.76 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 )->transaction_amount, 0 );

    # update capitation in authorization object {{{
    # all these should be null
    # 1001 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1001 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1002 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1002 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1003 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1003 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1005 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1005 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1006 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1006 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1008 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1008 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1010 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1010 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1011 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1011 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1012 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1012 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1014 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1014 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1015 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1015 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    is( $auth->capitation_amount_percent, 0 );
    # these time calculations will do for the rest, as they're all date-dependent
    is( $auth->capitation_time_percent( '2005-02-15' ), 0 );
    is( $auth->capitation_time_percent( '2005-02-18' ), 1 );
    is( $auth->capitation_time_percent( '2005-02-21' ), 2 );
    is( $auth->capitation_time_percent( '2005-08-18' ), 50 );
    is( $auth->capitation_time_percent( '2006-02-15' ), 100 );
    is( $auth->capitation_time_percent( '2006-08-15' ), 150 );
    is( $auth->capitation_time_percent( '2007-02-15' ), 200 );

    # these should update
    # 1004
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 657.88 );
    is( $auth->capitation_last_date, '2006-07-14' );
    is( $auth->capitation_amount_percent, 66 );

    # 1007
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    is( $auth->capitation_amount_percent, 0 );

    # 1009
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 25.76 );
    is( $auth->capitation_last_date, '2006-07-14' );
    is( $auth->capitation_amount_percent, 3 );

    # 1013
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    is( $auth->capitation_amount_percent, 0 );
    #}}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$test->financial_setup( 2 );
    # transaction_amount
    is( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1003 )->transaction_amount, 7.48 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1005 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1006 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1007 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1008 )->transaction_amount, 124.64 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1009 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1010 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1011 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1012 )->transaction_amount, 25.76 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1013 )->transaction_amount, 117.16 );

    # authorization.transaction_amount
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 )->transaction_amount, 657.88 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 )->transaction_amount, 117.16 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 )->transaction_amount, 25.76 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 )->transaction_amount, 0 );
    
    # authorization.transaction_amount, edge cases and confirmations
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1001 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1002 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1003 )->transaction_amount, 0 );

    # update capitation in authorization object {{{
    # all these should be null
    # 1001 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1001 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1002 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1002 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1003 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1003 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1005 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1005 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1006 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1006 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1008 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1008 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1010 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1010 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1011 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1011 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1012 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1012 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1014 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1014 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1015 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1015 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # these should update
    # 1004
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 );
    is( $auth->capitation_amount, 657.88 );
    is( $auth->capitation_last_date, '2006-07-14' );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 657.88 );
    is( $auth->capitation_last_date, '2006-07-14' );
    is( $auth->capitation_amount_percent, 66 );

    # 1007
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 117.16 );
    is( $auth->capitation_last_date, '2006-07-03' );
    is( $auth->capitation_amount_percent, 12 );

    # 1009
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 );
    is( $auth->capitation_amount, 25.76 );
    is( $auth->capitation_last_date, '2006-07-14' );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 25.76 );
    is( $auth->capitation_last_date, '2006-07-14' );
    is( $auth->capitation_amount_percent, 3 );

    # 1013
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    #}}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$test->financial_setup( 3 );
    # transaction_amount
    is( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1003 )->transaction_amount, 7.48 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1005 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1006 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1007 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1008 )->transaction_amount, 124.64 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1009 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1010 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1011 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1012 )->transaction_amount, 25.76 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1013 )->transaction_amount, 117.16 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1014 )->transaction_amount, '100.00' );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1015 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1016 )->transaction_amount, 100.47 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1017 )->transaction_amount, '10.00' );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1018 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1019 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1020 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1021 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1022 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1023 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1024 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1025 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1026 )->transaction_amount, 131.44 );

    # transaction_amount, test with entered_in_error transaction
        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->entered_in_error( 1 )->save;
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->transaction_amount, 0 );

        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->entered_in_error( 0 )->save;
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->transaction_amount, 131.44 );

    # transaction_amount, test with refunded transaction
        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->refunded( 1 )->save;
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->transaction_amount, 0 );

        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->refunded( 0 )->save;
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->transaction_amount, 131.44 );

    # authorization.transaction_amount
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 )->transaction_amount, 1394.11 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 )->transaction_amount, 117.16 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 )->transaction_amount, 682.96 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 )->transaction_amount, 0 );

    # authorization.transaction_amount, edge cases and confirmations
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1001 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1002 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1003 )->transaction_amount, 0 );
    
    # update capitation in authorization object {{{
    # all these should be null
    # 1001 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1001 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1002 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1002 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1003 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1003 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1005 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1005 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1006 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1006 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1008 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1008 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1010 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1010 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1011 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1011 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1012 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1012 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1014 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1014 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1015 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1015 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # these should update
    # 1004
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 );
    is( $auth->capitation_amount, 657.88 );
    is( $auth->capitation_last_date, '2006-07-14' );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 1394.11 );
    is( $auth->capitation_last_date, '2006-07-31' );
    is( $auth->capitation_amount_percent, 139 );

    # 1007
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 );
    is( $auth->capitation_amount, 117.16 );
    is( $auth->capitation_last_date, '2006-07-03' );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 117.16 );
    is( $auth->capitation_last_date, '2006-07-03' );
    is( $auth->capitation_amount_percent, 12 );

    # 1009
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 );
    is( $auth->capitation_amount, 25.76 );
    is( $auth->capitation_last_date, '2006-07-14' );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 682.96 );
    is( $auth->capitation_last_date, '2006-07-31' );
    is( $auth->capitation_amount_percent, 68 );

    # 1013
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    #}}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$test->financial_setup( 4 );
    # transaction_amount
    is( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1003 )->transaction_amount, 7.48 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1005 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1006 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1007 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1008 )->transaction_amount, 124.64 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1009 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1010 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1011 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1012 )->transaction_amount, 25.76 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1013 )->transaction_amount, 117.16 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1014 )->transaction_amount, '100.00' );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1015 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1016 )->transaction_amount, 100.47 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1017 )->transaction_amount, '10.00' );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1018 )->transaction_amount, 0 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1019 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1020 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1021 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1022 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1023 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1024 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1025 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1026 )->transaction_amount, 131.44 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1027 )->transaction_amount, 148.81 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1028 )->transaction_amount, 152.88 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1029 )->transaction_amount, 131.44 );

    # authorization.transaction_amount
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 )->transaction_amount, 1394.11 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 )->transaction_amount, 550.29 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 )->transaction_amount, 682.96 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 )->transaction_amount, 0 );

    # authorization.transaction_amount, edge cases and confirmations
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1001 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1002 )->transaction_amount, 0 );
    is( eleMentalClinic::Client::Insurance::Authorization->retrieve( 1003 )->transaction_amount, 0 );
    
    # update capitation in authorization object {{{
    # all these should be null
    # 1001 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1001 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1002 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1002 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1003 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1003 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1005 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1005 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1006 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1006 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1008 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1008 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1010 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1010 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1011 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1011 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1012 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1012 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1014 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1014 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # 1015 -- null op
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1015 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );

    # these should update
    # 1004
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 );
    is( $auth->capitation_amount, 1394.11 );
    is( $auth->capitation_last_date, '2006-07-31' );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 1394.11 );
    is( $auth->capitation_last_date, '2006-07-31' );
    is( $auth->capitation_amount_percent, 139 );

    # 1007
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 );
    is( $auth->capitation_amount, 117.16 );
    is( $auth->capitation_last_date, '2006-07-03' );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 550.29 );
    is( $auth->capitation_last_date, '2006-07-24' );
    is( $auth->capitation_amount_percent, 55 );

    # 1009
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 );
    is( $auth->capitation_amount, 682.96 );
    is( $auth->capitation_last_date, '2006-07-31' );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, 682.96 );
    is( $auth->capitation_last_date, '2006-07-31' );
    is( $auth->capitation_amount_percent, 68 );

    # 1013
        $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    ok( $auth->update_capitation );
    is( $auth->capitation_amount, undef );
    is( $auth->capitation_last_date, undef );
    #}}}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
