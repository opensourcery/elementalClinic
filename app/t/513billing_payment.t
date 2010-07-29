# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 166;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Financial::Transaction;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Financial::BillingPayment';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
    financial_reset_sequences();
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'billing_payment');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id interchange_control_number
        is_production date_received
        transaction_handling_code payment_amount
        payment_method payment_date payment_number
        payment_company_id interchange_date
        entered_by_staff_id rolodex_id edi
        edi_filename
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is electronic?
        $one = $CLASS->new;
    can_ok( $one, 'is_electronic' );
    is( $one->is_electronic, 0 ); # because it's new

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_payer_id
    can_ok( $one, 'get_payer_id' );
    is( $one->get_payer_id, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# last_received_for_rolodex
    can_ok( $CLASS, 'last_received_for_rolodex' );
    throws_ok{ $CLASS->last_received_for_rolodex } qr/required/;
    is( $CLASS->last_received_for_rolodex( 1013 ), undef );
    is( $CLASS->last_received_for_rolodex( 1014 ), undef );
    is( $CLASS->last_received_for_rolodex( 1015 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# already_processed
    can_ok( $one, 'already_processed' );
    is( $one->already_processed, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# process_remittance_advice
    can_ok( $one, 'process_remittance_advice' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start the first billing cycle 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
        my $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );
        $test->financial_setup_bill( $billing_cycle, [ 1002 ], [] ); # don't write the HCFA

        $one = $CLASS->new;
    throws_ok{ $one->process_remittance_advice } qr/required/;
    is( $one->interchange_control_number, undef );
    is( $one->already_processed, undef );
 
        $one = $CLASS->new;
    throws_ok{ $one->process_remittance_advice( 't/resource/sample_835.1claimadjust.txt', '2006-09-05' ) } 
        qr/Claim Adjustment found in the 835/, 'Cannot process an 835 that contains claim level adjustments';

        $one = $CLASS->new;
    {
        # XXX When running the test suite (as opposed to running this test from vim, or using prove),
        # all warnings are enabled across all modules. This throws off the tests for warnings below.
        # So for just these, enable all warnings across all modules so it works the same no matter how the tests are run.
        local( $^W ) = 1;

    # doing the actual processing of the 835
    warnings_like{ $one->process_remittance_advice( 't/resource/sample_835.1provideradjust.txt', '2006-09-05' ) } [
        qr/Provider Adjustment found in the 835/
    ], 'Warning when processing 835 containing a Provider Adjustment';
    throws_ok   { $one->process_remittance_advice( 't/resource/sample_835.1.txt', '2006-09-05' ) } qr/already been processed/, 'Duplicate 835 warning';

    }

    is( $one->already_processed, 1 );

    TODO: {
        local $TODO = 'Cannot rely on database to munge this correctly, as we appear to be doing now.';
        # if we can format these numbers when they are parsed from the 835, that would fix this
        is( $one->interchange_control_number, 66 );
        # is( $one->payment_amount, '683.76' ); # TODO now this one passes because the amount changed. Used to be '658.00'. Change test data to test this.
    }
        
    is( $one->get_payer_id, 1015 );
    is( $one->is_electronic, 1 );

        $one = $CLASS->new;
        $one->retrieve( 1002 );

    is( $one->is_electronic, 1 );

    is( $one->interchange_control_number, 66 );
    is( $one->is_production, 0 );
    is( $one->date_received, '2006-09-05' );
    is( $one->payment_amount, '684.91' );
    is( $one->payment_method, 'CHK' );
    is( $one->payment_date, '2006-08-31' );
    is( $one->payment_number, '12345' );
    is( $one->payment_company_id, '1930555555' );
    is( $one->rolodex_id, 1015 );

        my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
    is( $valid_data->get_byname( '_transaction_handling', $one->transaction_handling_code )->{ description }, 
        'Remittance Information Only: payment is separate' );
    
        open EDI, "< t/resource/sample_835.1provideradjust.txt";
        my $edi;
        while( my $line = <EDI> ){
            $edi .= $line;     
        }
        close EDI;
        #$edi =~ s/\n/~/g;
    is( $one->edi, $edi );

    # Test that the billing_payment database record is correct
    # This is actually duplicating some of the methods we just called, but not all
    is_deeply( eleMentalClinic::Financial::BillingPayment->retrieve( 1002 ), {
        rec_id                      => 1002,
        edi_filename                => 'sample_835.1provideradjust.txt',
        interchange_control_number  => 66,
        is_production               => 0,
        transaction_handling_code   => 'I',
        payment_amount              => '684.91',
        payment_method              => 'CHK',
        payment_date                => '2006-08-31',
        payment_number              => '12345',
        payment_company_id          => '1930555555',
        interchange_date            => '2006-09-02',
        date_received               => '2006-09-05',
        entered_by_staff_id         => undef,
        rolodex_id                  => 1015,
        edi                         => $edi,
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# process_claims
    can_ok( $one, 'process_claims' );

    # process_claims is getting called inside process_remittance_advice at the moment...
    
    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1001 ), {
        rec_id                          => 1001,
        billing_service_id              => 1003,
        billing_payment_id              => 1002,
        paid_amount                     => '7.48',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => 'M137:M1',
        entered_in_error                => 0,
        refunded                        => 0,
    }); 
 
    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1002 ), {
        rec_id                          => 1002,
        billing_service_id              => 1004,
        billing_payment_id              => 1002,
        paid_amount                     => '131.44',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    });

    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1003 ), {
        rec_id                          => 1003,
        billing_service_id              => 1005,
        billing_payment_id              => 1002,
        paid_amount                     => '131.44',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90806',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    });

    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1004 ), {
        rec_id                          => 1004,
        billing_service_id              => 1006,
        billing_payment_id              => 1002,
        paid_amount                     => '131.44',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90806',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    });

    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1005 ), {
        rec_id                          => 1005,
        billing_service_id              => 1007,
        billing_payment_id              => 1002,
        paid_amount                     => '131.44',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    });

    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1006 ), {
        rec_id                          => 1006,
        billing_service_id              => 1008,
        billing_payment_id              => 1002,
        paid_amount                     => '124.64',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    });

    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1007 ), {
        rec_id                          => 1007,
        billing_service_id              => 1009,
        billing_payment_id              => 1002,
        paid_amount                     => '0.00',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => undef,
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90806',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    });

    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1008 ), {
        rec_id                          => 1008,
        billing_service_id              => 1010,
        billing_payment_id              => 1002,
        paid_amount                     => '0.00',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => undef,
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90806',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    });

    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1009 ), {
        rec_id                          => 1009,
        billing_service_id              => 1011,
        billing_payment_id              => 1002,
        paid_amount                     => '0.00',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => undef,
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90806',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    });

    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1010 ), {
        rec_id                          => 1010,
        billing_service_id              => 1012,
        billing_payment_id              => 1002,
        paid_amount                     => '25.76',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => undef,
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90806',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test the prognotes, check the billing_status flag

    is( eleMentalClinic::ProgressNote->retrieve( $_ )->billing_status, 'Partial' )
        for ( qw/ 1043 1056 1057 1058 1059 / );

    is( eleMentalClinic::ProgressNote->retrieve( $_ )->billing_status, 'Paid' )
        for ( qw/ 1044 1045 1046 1047 1048 / );

    is( eleMentalClinic::ProgressNote->retrieve( $_ )->billing_status, 'Billing' )
        for ( qw/ 1065 1066 / );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check billing_services

    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1001 )->billing_services, [
        { rec_id => 1001, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1002, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
    ], 'list billing services for billing_claim 1001' );
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1002 )->billing_services, [
        { rec_id => 1003, billing_claim_id => 1002, billed_amount => '124.64', billed_units => 2, line_number => 1 },
        { rec_id => 1004, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 2 },
        { rec_id => 1005, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 3 },
        { rec_id => 1006, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 4 },
        { rec_id => 1007, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 5 },
        { rec_id => 1008, billing_claim_id => 1002, billed_amount => '124.64', billed_units => 2, line_number => 6 },
    ], 'list billing services for billing_claim 1002' );
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1003 )->billing_services, [
        { rec_id => 1009, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 1 },
        { rec_id => 1010, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 2 },
        { rec_id => 1011, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 3 },
        { rec_id => 1012, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 4 },
    ], 'list billing services for billing_claim 1003' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check billing_prognotes

    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->billing_prognotes, [
        { rec_id => 1001, billing_service_id => 1001, prognote_id => 1065 },
    ], );
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->billing_prognotes, [
        { rec_id => 1002, billing_service_id => 1002, prognote_id => 1066 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1003 )->billing_prognotes, [
        { rec_id => 1003, billing_service_id => 1003, prognote_id => 1043 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->billing_prognotes, [
        { rec_id => 1004, billing_service_id => 1004, prognote_id => 1044 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1005 )->billing_prognotes, [
        { rec_id => 1005, billing_service_id => 1005, prognote_id => 1045 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1006 )->billing_prognotes, [
        { rec_id => 1006, billing_service_id => 1006, prognote_id => 1046 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1007 )->billing_prognotes, [
        { rec_id => 1007, billing_service_id => 1007, prognote_id => 1047 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1008 )->billing_prognotes, [
        { rec_id => 1008, billing_service_id => 1008, prognote_id => 1048 },
    ]);

    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1009 )->billing_prognotes, [
        { rec_id => 1009, billing_service_id => 1009, prognote_id => 1056 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1010 )->billing_prognotes, [
        { rec_id => 1010, billing_service_id => 1010, prognote_id => 1057 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1011 )->billing_prognotes, [
        { rec_id => 1011, billing_service_id => 1011, prognote_id => 1058 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1012 )->billing_prognotes, [
        { rec_id => 1012, billing_service_id => 1012, prognote_id => 1059 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# last_received_for_rolodex
    is( $CLASS->last_received_for_rolodex( 1013 ), undef );
    is( $CLASS->last_received_for_rolodex( 1014 ), undef );
    is( $CLASS->last_received_for_rolodex( 1015 ), '2006-09-05', 'check date last_received_for_rolodex 1015' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Finish the first billing cycle and start the second cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_cycle->validation_set->finish;
        
        $billing_cycle = $test->financial_setup_billingcycle;
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1005 ], [ 1014 ] );
        $test->financial_setup_bill( $billing_cycle, [ 1003 ], [], '2006-08-31 18:04:25' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# process the second 835
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $one = $CLASS->new;
    is( $one->already_processed, undef );
    
    {
        local( $^W ) = 1;

        warnings_are { $one->process_remittance_advice( 't/resource/sample_835.2.txt', '2006-09-05' ) } [], 'No warning when processing 835 with no Provider Adjustment'; 
    }

    is( $one->already_processed, 1 );

    is( $one->get_payer_id, 1014 );

        # Test the billing_payment fields
        $one = $CLASS->new;
        $one->retrieve( 1003 );

    is( $one->interchange_control_number, 67 );
    is( $one->is_production, 0 );
    is( $one->date_received, '2006-09-05' );
    is( $one->payment_amount, '117.16' );
    is( $one->payment_method, 'CHK' );
    is( $one->payment_date, '2006-08-31' );
    is( $one->payment_number, '12350' );
    is( $one->payment_company_id, '1930333333' );
    is( $one->rolodex_id, 1014 );

    is( $valid_data->get_byname( '_transaction_handling', $one->transaction_handling_code )->{ description }, 
        'Remittance Information Only: payment is separate' );
    
        open EDI, "< t/resource/sample_835.2.txt";
        $edi = '';
        while( my $line = <EDI> ){
            $edi .= $line;     
        }
        close EDI;
        #$edi =~ s/\n/~/g;
    is( $one->edi, $edi );
    # Test that the billing_payment database record is correct
    # This is actually duplicating some of the methods we just called, but not all
    is_deeply( eleMentalClinic::Financial::BillingPayment->retrieve( 1003 ), {
        rec_id                      => 1003,
        edi_filename                => 'sample_835.2.txt',
        interchange_control_number  => 67,
        is_production               => 0,
        transaction_handling_code   => 'I',
        payment_amount              => '117.16',
        payment_method              => 'CHK',
        payment_date                => '2006-08-31',
        payment_number              => '12350',
        payment_company_id          => '1930333333',
        interchange_date            => '2006-09-03',
        date_received               => '2006-09-05',
        entered_by_staff_id         => undef,
        rolodex_id                  => 1014,
        edi                         => $edi,
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test the transaction records

    is_deeply( eleMentalClinic::Financial::Transaction->retrieve( 1011 ), { 
        rec_id                          => 1011,
        billing_service_id              => 1013,
        billing_payment_id              => 1003,
        paid_amount                     => '117.16',
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => undef,
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    } );
        
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test the prognotes, check the billing_status flag

    is( eleMentalClinic::ProgressNote->retrieve( $_ )->billing_status, 'Paid', "$_ was paid" )
        for ( qw/ 1043 1044 1045 1046 1047 1048 / );

    is( eleMentalClinic::ProgressNote->retrieve( $_ )->billing_status, 'Billing', "$_ is billing" )
        for ( qw/ 1056 1057 1058 1059 1065 1066 / );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check billing_services

    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1001 )->billing_services, [
        { rec_id => 1001, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1002, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1002 )->billing_services, [
        { rec_id => 1003, billing_claim_id => 1002, billed_amount => '124.64', billed_units => 2, line_number => 1 },
        { rec_id => 1004, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 2 },
        { rec_id => 1005, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 3 },
        { rec_id => 1006, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 4 },
        { rec_id => 1007, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 5 },
        { rec_id => 1008, billing_claim_id => 1002, billed_amount => '124.64', billed_units => 2, line_number => 6 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1003 )->billing_services, [
        { rec_id => 1009, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 1 },
        { rec_id => 1010, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 2 },
        { rec_id => 1011, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 3 },
        { rec_id => 1012, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 4 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1004 )->billing_services, [
        { rec_id => 1013, billing_claim_id => 1004, billed_amount => '124.64', billed_units => 2, line_number => 1 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check billing_prognotes

    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->billing_prognotes, [
        { rec_id => 1001, billing_service_id => 1001, prognote_id => 1065 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->billing_prognotes, [
        { rec_id => 1002, billing_service_id => 1002, prognote_id => 1066 },
    ]);

    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1003 )->billing_prognotes, [
        { rec_id => 1003, billing_service_id => 1003, prognote_id => 1043 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->billing_prognotes, [
        { rec_id => 1004, billing_service_id => 1004, prognote_id => 1044 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1005 )->billing_prognotes, [
        { rec_id => 1005, billing_service_id => 1005, prognote_id => 1045 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1006 )->billing_prognotes, [
        { rec_id => 1006, billing_service_id => 1006, prognote_id => 1046 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1007 )->billing_prognotes, [
        { rec_id => 1007, billing_service_id => 1007, prognote_id => 1047 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1008 )->billing_prognotes, [
        { rec_id => 1008, billing_service_id => 1008, prognote_id => 1048 },
    ]);

    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1009 )->billing_prognotes, [
        { rec_id => 1009, billing_service_id => 1009, prognote_id => 1056 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1010 )->billing_prognotes, [
        { rec_id => 1010, billing_service_id => 1010, prognote_id => 1057 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1011 )->billing_prognotes, [
        { rec_id => 1011, billing_service_id => 1011, prognote_id => 1058 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1012 )->billing_prognotes, [
        { rec_id => 1012, billing_service_id => 1012, prognote_id => 1059 },
    ]);

    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1013 )->billing_prognotes, [
        { rec_id => 1013, billing_service_id => 1013, prognote_id => 1043 },
    ]);

        $billing_cycle->validation_set->finish;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# last_received_for_rolodex
    is( $CLASS->last_received_for_rolodex( 1013 ), undef );
    is( $CLASS->last_received_for_rolodex( 1014 ), '2006-09-05' );
    is( $CLASS->last_received_for_rolodex( 1015 ), '2006-09-05' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_manual_by_rolodex
    can_ok( $CLASS, 'list_manual_by_rolodex' );
    
    is( $CLASS->list_manual_by_rolodex( 1013 ), undef );
    is( $CLASS->list_manual_by_rolodex( 1014 ), undef );
    is( $CLASS->list_manual_by_rolodex( 1015 ), undef );

        # temporarily make 1002 look like a manual payment
        $one = $CLASS->new;
        $one->retrieve( 1003 );
        $one->edi_filename( '' );
        $one->save;
    
    is_deeply_except(
        { edi => undef },
        $CLASS->list_manual_by_rolodex( 1014 ), 
        [ {
            rec_id                      => 1003,
            edi_filename                => undef,
            interchange_control_number  => 67,
            is_production               => 0,
            transaction_handling_code   => 'I',
            payment_amount              => '117.16',
            payment_method              => 'CHK',
            payment_date                => '2006-08-31',
            payment_number              => '12350',
            payment_company_id          => '1930333333',
            interchange_date            => '2006-09-03',
            date_received               => '2006-09-05',
            entered_by_staff_id         => undef,
            rolodex_id                  => 1014,
    } ]);
    
        # reset
        $one->edi_filename( 'sample_835.2.txt' );
        $one->save;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_manual_by_rolodex
    can_ok( $CLASS, 'get_manual_by_rolodex' );

    is( $CLASS->get_manual_by_rolodex( 1013 ), undef );
    is( $CLASS->get_manual_by_rolodex( 1014 ), undef );
    is( $CLASS->get_manual_by_rolodex( 1015 ), undef );
        
        # temporarily make 1002 look like a manual payment
        $one = $CLASS->new;
        $one->retrieve( 1003 );
        $one->edi_filename( '' );
        $one->save;
    
    is_deeply_except(
        { edi => undef },
        $CLASS->get_manual_by_rolodex( 1014 ), 
        [ {
            rec_id                      => 1003,
            edi_filename                => undef,
            interchange_control_number  => 67,
            is_production               => 0,
            transaction_handling_code   => 'I',
            payment_amount              => '117.16',
            payment_method              => 'CHK',
            payment_date                => '2006-08-31',
            payment_number              => '12350',
            payment_company_id          => '1930333333',
            interchange_date            => '2006-09-03',
            date_received               => '2006-09-05',
            entered_by_staff_id         => undef,
            rolodex_id                  => 1014,
    } ]);

        # reset
        $one->edi_filename( 'sample_835.2.txt' );
        $one->save;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# label
    can_ok( $one, 'label' );

        $one = $CLASS->new;
    is( $one->label, undef );

        $one->retrieve( 1002 );
    is( $one->label, '2006-08-31 | #12345' );

        $one->retrieve( 1003 );
    is( $one->label, '2006-08-31 | #12350' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# label
    is( $CLASS->new->label, undef );
    is( $CLASS->retrieve( 1002 )->label({ include_rolodex => 1 }), 'Medicare | 2006-08-31 | #12345' );
    is( $CLASS->retrieve( 1003 )->label({ include_rolodex => 1 }), 'WaCo OHP CAP | 2006-08-31 | #12350' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# final is electronic tests
# XXX these tests should remain last, as they change data
        $one = $CLASS->new;
        $one->retrieve( 1003 );

    is( $one->is_electronic, 1 );
        $one->entered_by_staff_id( 1001 )->save;
    is( $one->is_electronic, 1 );
        $one->update({ edi => undef });
    is( $one->is_electronic, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Run a billing cycle and payment where not all of the services in a claim are billed, to make sure they don't break payment  
# (fix for #623)

        # Test normal case
        dbinit( 1 );
        $test->financial_setup( 1 );
        my $billing_prognote = eleMentalClinic::Financial::BillingPrognote->retrieve( 1004 );
    is( $billing_prognote->prognote_id, 1044 );
    is( $billing_prognote->billing_service_id, 1004 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->billed_amount, 131.44 );
    is_deeply( $one->db->do_sql( 'select paid_amount from transaction where billing_service_id = 1004' ), [{ paid_amount => 131.44 }] );

        # Now run it again
        dbinit( 1 );
        # update the 1044 prognote so that it doesn't get billed
        my $prognote = eleMentalClinic::ProgressNote->retrieve( 1044 );
        $prognote->{ charge_code_id } = 2;  # No Show
        $prognote->save;

        $test->financial_setup( 1 );
        $billing_prognote = eleMentalClinic::Financial::BillingPrognote->retrieve( 1004 );
    is( $billing_prognote->prognote_id, 1044 );
    is( $billing_prognote->billing_service_id, 1004 );
    is( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->billed_amount, undef );
    is_deeply( $one->db->do_sql( 'select paid_amount from transaction where billing_service_id = 1004' ), [] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Attempt to parse a different kind of file, and a duplicate
# FIXME These test need to be run last because of an error in X12::Parser
# The parser's state gets into a weird state when we die in the middle of parsing,
# due to X12::Parser.pm using global variables.
        $one = $CLASS->new;

    throws_ok{ $one->process_remittance_advice( 't/resource/sample_837.1.txt', '2006-09-05' ) } qr/Error parsing 835: unable to find the segment name/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
