# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 46;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Log;

our ($tmp);
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Description of testdata that will apply in the billing
# cycles being tested by this file is available here:
# https://prefect.opensourcery.com:444/projects/elementalclinic/wiki/EcsBilling/TestDataJazz
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Turn off the warnings coming from validation during financial setup.
$eleMentalClinic::Base::TESTMODE = 1;

=for docs

This test doesn't exercise any one object, but contains functional tests of combining notes
and checking that 837s are generated properly.

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
    financial_reset_sequences();
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $test->financial_setup( 1 );
        $test->financial_setup( 2 );
        $test->financial_setup( 3 );

        # test the 837 that results from the 3rd billing cycle
        my $test_file_path = $test->config->edi_out_root . '/1004t837P0815.txt';
    eleMentalClinic::Test->compare_837s_byline( 't/resource/sample_837.3.txt', $test_file_path );

        $test->financial_setup( 4 );

        # test the 837 that results from the 4th billing cycle
        $test_file_path = $test->config->edi_out_root . '/1005t837P0906.txt';
    eleMentalClinic::Test->compare_837s_byline( 't/resource/sample_837.4.txt', $test_file_path );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Reset the database and run billing cycles again
#
# To test that an exception is thrown if:
# 1) a payer is billed who does not require NPIs 
# AND THEN
# 2) a payer is billed who does require NPIs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        dbinit( 1 );

        $test->financial_setup( 1 );
        $test->financial_setup( 2 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Make PhTech 1st and Medicare 2nd, instead of the other way round

        $tmp = eleMentalClinic::Client::Insurance->retrieve( 1003 );
    is( $tmp->rank, 1 );
        $tmp->rank( 2 );
        $tmp->save;

        $tmp = eleMentalClinic::Client::Insurance->retrieve( 1004 );
    is( $tmp->rank, 2 );
        $tmp->rank( 1 );
        $tmp->save;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Beginning Third Billing Cycle

        my $billing_cycle = $test->financial_setup_billingcycle( creation_date => '2006-07-31', from_date => '2006-07-16', to_date => '2006-07-31' );
        $test->financial_setup_system_validation( $billing_cycle, [ qw/ 1001 1003 1004 / ] );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1006 ], [ 1014 ] );
        $test->financial_setup_bill( $billing_cycle, [ 1004 ], [], '2006-08-15 18:04:25' );
        $billing_cycle->validation_set->finish;

# process payment
        my $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.3Phtech.txt', '2006-09-05' ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Beginning Fourth Billing Cycle

        $billing_cycle = $test->financial_setup_billingcycle( creation_date => '2006-07-31', from_date => '2006-07-16', to_date => '2006-07-31' );
        $test->financial_setup_system_validation( $billing_cycle, [ qw/ 1001 1003 1004 / ] );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1006 ], [ 1015 ] );
        $test->financial_setup_bill( $billing_cycle, [ 1005 ], [], '2006-08-30 18:04:25' );
        $billing_cycle->validation_set->finish;

        # Should get an error here
    like( Retrieve_deferred->[0], qr/Error getting subscriber data, client 1003, client_insurance 1003: Notes previously sent combined are now sent individually; not supported/ );

        # test the 837 that results - should skip all services for client 1003 because of 1051/1351
        $test_file_path = $test->config->edi_out_root . '/1005t837P0830.txt';
    eleMentalClinic::Test->compare_837s_byline( 't/resource/sample_837.4Medicare.txt', $test_file_path );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Reset the database and run the first billing cycle
#
# To test validation rule 1013: 
# rule to find 'identical' prognotes for a client, when one has been previously billed, and this one hasn't
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        dbinit( 1 );
        $test->financial_setup( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start a new cycle

        $billing_cycle = $test->financial_setup_billingcycle;

    # verify that we have the notes that we expect in the validation set
    # (these are the notes that are still due to be billed after first billing)
        my @prognotes = map { $_->{ id } } @{ $billing_cycle->validation_set->prognotes };
    is_deeply( [ sort @prognotes ],
        [ qw/ 1043 1056 1057 1058 1059 1143 1144 1145 1157 1158 1159 /],
        "new cycle, have expected notes"
    );

    # all pass at first
    is_deeply( $billing_cycle->validation_set->test_validate_sql( $validation_rule->{ 1013 } ),
        [ qw/ 1144 1043 1056 1143 1145 1159 1057 1157 1158 1058 1059 /],
        "new cycle, all pass at first"
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# change note dates and start a new cycle

        # move 1444 into the billing date range, makes it 'identical' to 1044 
        eleMentalClinic::ProgressNote->retrieve( 1444 )->start_date( '2006-07-05 14:00:00' )->save;
        eleMentalClinic::ProgressNote->retrieve( 1444 )->end_date( '2006-07-05 15:00:00' )->save;
        $prognote->{ 1444 }->{ start_date } = '2006-07-05 14:00:00';
        $prognote->{ 1444 }->{ end_date } = '2006-07-05 15:00:00';  

        # move 1445 into the billing date range, it would be 'identical' to 1045 but it has different staff_id;
        # however - for our purposes now we are ignoring staff_id
        eleMentalClinic::ProgressNote->retrieve( 1445 )->start_date( '2006-07-07 14:00:00' )->save;
        eleMentalClinic::ProgressNote->retrieve( 1445 )->end_date( '2006-07-07 15:00:00' )->save;
        $prognote->{ 1445 }->{ start_date } = '2006-07-07 14:00:00';
        $prognote->{ 1445 }->{ end_date } = '2006-07-07 15:00:00';

        # start the cycle again
        $billing_cycle->finish;
        $billing_cycle = $test->financial_setup_billingcycle;

    # verify that we have the notes that we expect in the validation set
        @prognotes = map { $_->{ id } } @{ $billing_cycle->validation_set->prognotes };
    is_deeply( [ sort @prognotes ], 
        [ qw/ 1043 1056 1057 1058 1059 1143 1144 1145 1157 1158 1159 1444 1445 /],
        'change note dates: verify that we have expected notes'
    );

    # now 1444 fails (results look the same because these are the notes that pass)
    # and 1445 does too (even though 1045's payer sends NPI, we don't know what future payers do)
    is_deeply( $billing_cycle->validation_set->test_validate_sql( $validation_rule->{ 1013 } ),
        [ qw/ 1144 1043 1056 1143 1145 1159 1057 1157 1158 1058 1059 /]
    );

    # 1143, 1144, 1145 are 'identical' to each other. 1157, 1158, 1159 are 'identical' to each other.
    # but only 1444 is unbilled and 'identical' to a billed note
    
    # note that results return all notes in the date range, not just ones in the validation set
    is_deeply_except( { previous_billing_status => undef, billing_status => undef, modified => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1013 )->results( '2006-07-01', '2006-07-15' ),
        [
            { %{ $prognote->{ 1144 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1444 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1159 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1157 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1057 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1045 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1158 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1445 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1058 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1059 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }}, rule_1013 => 1, pass => 1 },
        ],
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# change Medicare so it doesn't send NPI and start a new cycle
# NOTE: These tests are not nearly as interesting as when we were comparing staff_ids and checking a previous payer's NPI requirement. 

        eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1003 )->requires_rendering_provider_ids( 0 )->save;

        # start the cycle again
        $billing_cycle->finish;
        $billing_cycle = $test->financial_setup_billingcycle;

    # verify that we have the notes that we expect in the validation set
        @prognotes = map { $_->{ id } } @{ $billing_cycle->validation_set->prognotes };
    is_deeply( [ sort @prognotes ], 
        [ qw/ 1043 1056 1057 1058 1059 1143 1144 1145 1157 1158 1159 1444 1445 /]
    );

    # both 1444 and 1445 should fail
    is_deeply( $billing_cycle->validation_set->test_validate_sql( $validation_rule->{ 1013 } ),
        [ qw/ 1144 1043 1056 1143 1145 1159 1057 1157 1158 1058 1059 /]
    );

    is_deeply_except( { previous_billing_status => undef, billing_status => undef, modified => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1013 )->results( '2006-07-01', '2006-07-15' ),
        [
            { %{ $prognote->{ 1144 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1444 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1159 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1157 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1057 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1045 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1158 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1445 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1058 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1059 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }}, rule_1013 => 1, pass => 1 },
        ],
    );

        eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1003 )->requires_rendering_provider_ids( 1 )->save;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make the old 'identical' note be not fully paid and start a new cycle

        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->paid_amount( '100.00' )->save;
        eleMentalClinic::ProgressNote->retrieve( 1044 )->billing_status( 'Partial' )->save;

        # start the cycle again
        $billing_cycle->finish;
        $billing_cycle = $test->financial_setup_billingcycle;

    # verify that we have the notes that we expect in the validation set
    # (verify that 1044 is actually in it) 
        @prognotes = map { $_->{ id } } @{ $billing_cycle->validation_set->prognotes };
    is_deeply( [ sort @prognotes ], 
        [ qw/ 1043 1044 1056 1057 1058 1059 1143 1144 1145 1157 1158 1159 1444 1445 /]
    );

    # 1044 and 1444 should fail (as well as 1445)
    is_deeply( $billing_cycle->validation_set->test_validate_sql( $validation_rule->{ 1013 } ),
        [ qw/ 1144 1043 1056 1143 1145 1159 1057 1157 1158 1058 1059 /]
    );

    is_deeply_except( { previous_billing_status => undef, billing_status => undef, modified => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1013 )->results( '2006-07-01', '2006-07-15' ),
        [
            { %{ $prognote->{ 1144 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1444 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1159 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1157 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1057 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1045 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1158 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1445 }}, rule_1013 => 0, pass => 0 },
            { %{ $prognote->{ 1058 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1059 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }}, rule_1013 => 1, pass => 1 },
        ],
    );

        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->paid_amount( 131.44 )->save;
        eleMentalClinic::ProgressNote->retrieve( 1044 )->billing_status( 'Paid' )->save;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Reset the database and run the first two billing cycles
#
# To test validation rule 1013, and make sure it doesn't catch combined notes 
# that have both been billed before
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        dbinit( 1 );
        $test->financial_setup( 1 );
        $test->financial_setup( 2 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start the third cycle

        $billing_cycle = $test->financial_setup_billingcycle( 
            creation_date => '2006-07-31', 
            from_date => '2006-07-16', 
            to_date => '2006-07-31' 
        );

    # verify that we have the notes that we expect in the validation set
        @prognotes = map { $_->{ id } } @{ $billing_cycle->validation_set->prognotes };
    is_deeply( [ sort @prognotes ],
        [ qw/ 1049 1050 1051 1052 1053 1054 1055 1060 1061 1062 1063 1064 1067 1068 1350 1351 /]
    );

    # all should pass - notes to combine are both unbilled
    is_deeply( $billing_cycle->validation_set->test_validate_sql( $validation_rule->{ 1013 } ),
        [ qw/ 1049 1060 1050 1067 1350 1051 1061 1351 1052 1062 1053 1068 1054 1063 1055 1064 /]
    );

    is_deeply_except( { previous_billing_status => undef, billing_status => undef, modified => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1013 )->results( '2006-07-16', '2006-07-31' ),
        [
            { %{ $prognote->{ 1060 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1049 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1067 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1050 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1350 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1061 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1051 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1351 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1062 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1052 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1068 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1053 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1063 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1054 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1064 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1055 }}, rule_1013 => 1, pass => 1 },
        ],
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# run the third cycle, start the fourth

        $billing_cycle->finish;
        $test->financial_setup( 3 );
        $billing_cycle = $test->financial_setup_billingcycle( 
            creation_date => '2006-07-31', 
            from_date => '2006-07-16', 
            to_date => '2006-07-31' 
        );

        @prognotes = map { $_->{ id } } @{ $billing_cycle->validation_set->prognotes };
    is_deeply( [ sort @prognotes ],
        [ qw/ 1050 1051 1052 1067 1068 1350 1351 /]
    );

    # all should pass - notes to combine have both been billed together before
    is_deeply( $billing_cycle->validation_set->test_validate_sql( $validation_rule->{ 1013 } ),
        [ qw/ 1050 1067 1350 1051 1351 1052 1068 /]
    );

    is_deeply_except( { previous_billing_status => undef, billing_status => undef, modified => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1013 )->results( '2006-07-16', '2006-07-31' ),
        [
            { %{ $prognote->{ 1060 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1049 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1067 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1050 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1350 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1061 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1051 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1351 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1062 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1052 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1068 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1053 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1063 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1054 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1064 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1055 }}, rule_1013 => 1, pass => 1 },
        ],
    );

        $test->delete_( 'validation_result', '*' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Reset the database and run the first billing cycle
#
# To test payment for manual billing of 'identical' prognotes
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        dbinit( 1 );
        $test->financial_setup( 1 );

        # move 1444 into the billing date range, makes it 'identical' to 1044 
        eleMentalClinic::ProgressNote->retrieve( 1444 )->start_date( '2006-07-05 14:00:00' )->save;
        eleMentalClinic::ProgressNote->retrieve( 1444 )->end_date( '2006-07-05 15:00:00' )->save;

        # start a new cycle, validate with 1013
        $billing_cycle = $test->financial_setup_billingcycle;
        $test->financial_setup_system_validation( $billing_cycle, [ qw/ 1013 / ] );
       
        # the user does this in the UI, in failed notes from system validation
        eleMentalClinic::ProgressNote->retrieve( 1444 )->bill_manually( 1 )->save;

        # check that they show up in the manual combined notes tool
    is_deeply( eleMentalClinic::ProgressNote->get_manual_to_bill, {
        1003 => { 
            '2006-07-05' => {
                deferred => 0,
                deferred_ids => [],
                notes => [
                   eleMentalClinic::ProgressNote->retrieve( 1044 ),
                   eleMentalClinic::ProgressNote->retrieve( 1444 ),
                ],
            }
        },
    } );

        # the user does this in the UI, in tools -> manual combined notes
    is_deeply( $billing_cycle->bill_manual_combined_notes( 
            [ 1044, 1444 ], # note ids
            1001,           # user id
            1003,           # client_insurance_id
        ), {
            rec_id      => 1003,
            creation_date => $billing_cycle->today,
            staff_id    => 1001,
            step        => 0,
            status      => 'Closed',
        });
    is_deeply( my $billing_service = eleMentalClinic::Financial::BillingService->retrieve( 1013 ), {
        rec_id          => 1013,
        billing_claim_id => 1004,
        billed_amount   => 262.88,
        billed_units    => 4,
        line_number     => 1,
    });

        # now test payment 

        # the user creates a billing_payment first, in the UI in payments -> master payments
    is( eleMentalClinic::Financial::BillingPayment->retrieve( 1002 )->rec_id, undef );
    ok( eleMentalClinic::Financial::BillingPayment->new( {
        payment_amount          => 262.88,
        payment_date            => '2006-08-31',
        payment_number          => '12345',
        date_received           => '2006-09-01',
        rolodex_id              => 1015,
        entered_by_staff_id     => 1001,
    })->save );
    is( eleMentalClinic::Financial::BillingPayment->retrieve( 1002 )->rec_id, 1002 );

        # these shouldn't exist yet
    is( eleMentalClinic::Financial::Transaction->retrieve( 1011 )->rec_id, undef );
    is( eleMentalClinic::Financial::TransactionDeduction->retrieve( 1007 )->rec_id, undef );

        # the user does this in the UI, in payments -> outstanding
    is( $billing_service->save_manual_payment({
        paid_charge_code    => '',
        paid_amount         => 162.88,
        submitted_charge_code_if_applicable => '90862',
        paid_units          => 2,
        deduction_1         => 100,
        reason_1            => 1,
        payer_claim_control_number => 'ABCD123',
        patient_responsibility_amount => '',
        remarks             => "M137:M1",
        billing_service_id  => 1013,
        billing_payment_id  => 1001,
        claim_status_code   => 1,
    }), undef );

    # test that the transaction record got created
    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1011 ), {
        rec_id                              => 1011,
        billing_service_id                  => 1013,
        billing_payment_id                  => 1001,
        paid_amount                         => 162.88,
        paid_units                          => 2,
        claim_status_code                   => 1,
        patient_responsibility_amount       => undef,
        payer_claim_control_number          => 'ABCD123',
        paid_charge_code                    => undef,
        submitted_charge_code_if_applicable => undef,
        remarks                             => "M137:M1",
        entered_in_error                    => 0,
        refunded                            => 0,
    });

    # and that the transaction_deduction got created
    is_deeply( eleMentalClinic::Financial::TransactionDeduction->retrieve( 1007 ), {
        rec_id          => 1007,
        transaction_id  => 1011,
        amount          => '100.00',
        units           => undef,
        group_code      => undef,
        reason_code     => 1,
    } );

    is( $billing_service->retrieve( 1013 )->is_fully_paid, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
