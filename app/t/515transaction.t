# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 117;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Financial::Transaction';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
    financial_reset_sequences();
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'transaction');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id billing_service_id billing_payment_id
        paid_amount paid_units
        claim_status_code patient_responsibility_amount
        payer_claim_control_number paid_charge_code
        submitted_charge_code_if_applicable
        remarks entered_in_error refunded
    /], 'fields');

    is_deeply( $one->methods, [ qw/
        billing_claim_id billing_file_id billing_cycle_id
    /], 'methods' );
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ), 'database fields match object fields' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# run the first billing cycle and process first payment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $test->financial_setup( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# refund
    can_ok( $one, 'refund' );
        $one->empty;
    throws_ok{ $one->refund } qr/stored in the database/, 'dies if Transaction not stored.';
        $one->retrieve( 1001 );
    is( $one->refunded, 0, 'not refunded yet.' );
    ok( $one->refund );
    is( $one->refunded, 1, 'now refunded.');
    my $test_transaction = eleMentalClinic::Financial::Transaction->retrieve(1001);
    is( $test_transaction->refunded, 1, 'stored');

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# reset billing cycle
dbinit(1);
        $test->financial_setup( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# run the second billing cycle 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $test->financial_setup( 2, '', { no_payment => 1 } );
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# process the second 835
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    TODO: {
        local $TODO =  "This should fail, since a BillingPayment object should only ever process one 825";
        # TODO this is commented since if it runs at all it will break the next tests
        ok( 0, q#ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.2.txt', '2006-09-05' ) );# );
    }
    ok( eleMentalClinic::Financial::BillingPayment->new->process_remittance_advice(
            't/resource/sample_835.2.txt', '2006-09-05'
    ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    can_ok( $one, 'populate' );
    throws_ok{ $one->populate } qr/stored/, 'expected exception on populate';

    # 1001
        $one = $CLASS->retrieve( 1001 );
    # properties are undef
    is( $one->{ billing_claim_id }, undef );
    is( $one->{ billing_file_id }, undef );
    is( $one->{ billing_cycle_id }, undef );
    # populate
    ok( $one->populate );
    # populate sets properties
    is( $one->{ billing_claim_id }, 1002 );
    is( $one->{ billing_file_id }, 1002 );
    is( $one->{ billing_cycle_id }, 1001 );

    # 1002
        $one = $CLASS->retrieve( 1002 );
    # properties are undef
    is( $one->{ billing_claim_id }, undef );
    is( $one->{ billing_file_id }, undef );
    is( $one->{ billing_cycle_id }, undef );
    # populate
    ok( $one->populate );
    # populate sets properties
    is( $one->{ billing_claim_id }, 1002 );
    is( $one->{ billing_file_id }, 1002 );
    is( $one->{ billing_cycle_id }, 1001 );

    # 1011
        $one = $CLASS->retrieve( 1011 );
    # properties are undef
    is( $one->{ billing_claim_id }, undef );
    is( $one->{ billing_file_id }, undef );
    is( $one->{ billing_cycle_id }, undef );
    # populate
    ok( $one->populate );
    # populate sets properties
    is( $one->{ billing_claim_id }, 1004 );
    is( $one->{ billing_file_id }, 1003 );
    is( $one->{ billing_cycle_id }, 1002 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing claim
    can_ok( $CLASS, 'billing_claim' );
    is_deeply( $CLASS->retrieve( 1001 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1002 ));
    is_deeply( $CLASS->retrieve( 1002 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1002 ));
    is_deeply( $CLASS->retrieve( 1003 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1002 ));
    is_deeply( $CLASS->retrieve( 1004 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1002 ));
    is_deeply( $CLASS->retrieve( 1005 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1002 ));
    is_deeply( $CLASS->retrieve( 1006 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1002 ));
    is_deeply( $CLASS->retrieve( 1007 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1003 ));
    is_deeply( $CLASS->retrieve( 1008 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1003 ));
    is_deeply( $CLASS->retrieve( 1009 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1003 ));
    is_deeply( $CLASS->retrieve( 1010 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1003 ));
    is_deeply( $CLASS->retrieve( 1011 )->billing_claim, eleMentalClinic::Financial::BillingClaim->retrieve( 1004 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing service
    can_ok( $CLASS, 'billing_service' );
    is_deeply( $CLASS->retrieve( 1001 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1003 ));
    is_deeply( $CLASS->retrieve( 1002 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1004 ));
    is_deeply( $CLASS->retrieve( 1003 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1005 ));
    is_deeply( $CLASS->retrieve( 1004 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1006 ));
    is_deeply( $CLASS->retrieve( 1005 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1007 ));
    is_deeply( $CLASS->retrieve( 1006 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1008 ));
    is_deeply( $CLASS->retrieve( 1007 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1009 ));
    is_deeply( $CLASS->retrieve( 1008 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1010 ));
    is_deeply( $CLASS->retrieve( 1009 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1011 ));
    is_deeply( $CLASS->retrieve( 1010 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1012 ));
    is_deeply( $CLASS->retrieve( 1011 )->billing_service, eleMentalClinic::Financial::BillingService->retrieve( 1013 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing cycle
    can_ok( $CLASS, 'billing_cycle' );
    is_deeply( $CLASS->retrieve( 1001 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1002 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1003 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1004 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1005 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1006 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1007 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1008 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1009 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1010 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1011 )->billing_cycle, eleMentalClinic::Financial::BillingCycle->retrieve( 1002 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# deductions
    can_ok( $CLASS, 'deductions' );
    is_deeply( $CLASS->retrieve( 1001 )->deductions, [
        eleMentalClinic::Financial::TransactionDeduction->retrieve( 1001 ),
        eleMentalClinic::Financial::TransactionDeduction->retrieve( 1002 ),
    ]);
    is( $CLASS->retrieve( 1002 )->deductions, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client
    can_ok( $CLASS, 'client' );
    is_deeply( $CLASS->retrieve( 1001 )->client, $client->{ 1003 });
    is_deeply( $CLASS->retrieve( 1002 )->client, $client->{ 1003 });
    is_deeply( $CLASS->retrieve( 1003 )->client, $client->{ 1003 });
    is_deeply( $CLASS->retrieve( 1004 )->client, $client->{ 1003 });
    is_deeply( $CLASS->retrieve( 1005 )->client, $client->{ 1003 });
    is_deeply( $CLASS->retrieve( 1006 )->client, $client->{ 1003 });
    is_deeply( $CLASS->retrieve( 1007 )->client, $client->{ 1004 });
    is_deeply( $CLASS->retrieve( 1008 )->client, $client->{ 1004 });
    is_deeply( $CLASS->retrieve( 1009 )->client, $client->{ 1004 });
    is_deeply( $CLASS->retrieve( 1010 )->client, $client->{ 1004 });
    is_deeply( $CLASS->retrieve( 1011 )->client, $client->{ 1003 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing payment
    can_ok( $CLASS, 'billing_payment' );
    is_deeply( $CLASS->retrieve( 1001 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1002 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1003 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1004 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1005 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1006 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1007 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1008 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1009 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1010 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1011 )->billing_payment, eleMentalClinic::Financial::BillingPayment->retrieve( 1002 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_for_adjustment
    can_ok( $CLASS, 'get_for_adjustment' );
    throws_ok{ $CLASS->get_for_adjustment } qr/required/;
    throws_ok{ $CLASS->get_for_adjustment( 1001 ) } qr/required/;
    is_deeply( $CLASS->get_for_adjustment( 1003, 1015 ), {
        1001 => {
            payment_date => '2006-08-31',
            payment_number => '12345',
            billing_claims => {
                1002 => {
                    personnel => eleMentalClinic::Personnel->retrieve( 1002 ),
                    billed_date => '2006-07-15 18:04:25',
                    transactions => [
                        $CLASS->retrieve( 1001 ),
                        $CLASS->retrieve( 1002 ),
                        $CLASS->retrieve( 1003 ),
                        $CLASS->retrieve( 1004 ),
                        $CLASS->retrieve( 1005 ),
                        $CLASS->retrieve( 1006 ),
                    ],
                },
            },
        },
    });
    is_deeply( $CLASS->get_for_adjustment( 1004, 1015 ), {
        1001 => {
            payment_date => '2006-08-31',
            payment_number => '12345',
            billing_claims => {
                1003 => {
                    personnel => eleMentalClinic::Personnel->retrieve( 1001 ),
                    billed_date => '2006-07-15 18:04:25',
                    transactions => [
                        $CLASS->retrieve( 1007 ),
                        $CLASS->retrieve( 1008 ),
                        $CLASS->retrieve( 1009 ),
                        $CLASS->retrieve( 1010 ),
                    ],
                },
            },
        },
    });
    is_deeply( $CLASS->get_for_adjustment( 1003, 1014 ), {
        1002 => {
            payment_date => '2006-08-31',
            payment_number => '12350',
            billing_claims => {
                1004 => {
                    personnel => eleMentalClinic::Personnel->retrieve( 1002 ),
                    billed_date => '2006-08-31 18:04:25',
                    transactions => [
                        $CLASS->retrieve( 1011 ),
                    ],
                },
            },
        },
    });
    is( $CLASS->get_for_adjustment( 1004, 1014 ), undef );
    is( $CLASS->get_for_adjustment( 1003, 999 ), undef );
    is( $CLASS->get_for_adjustment( 999, 1015 ), undef );

    # test with entered_in_error and refunded transactions
    is( eleMentalClinic::Financial::Transaction->retrieve( 1007 )->entered_in_error, 0 );
        eleMentalClinic::Financial::Transaction->retrieve( 1007 )->entered_in_error( 1 )->save;
    is( eleMentalClinic::Financial::Transaction->retrieve( 1008 )->refunded, 0 );
        eleMentalClinic::Financial::Transaction->retrieve( 1008 )->refunded( 1 )->save;

    is_deeply( $CLASS->get_for_adjustment( 1004, 1015 ), {
        1001 => {
            payment_date => '2006-08-31',
            payment_number => '12345',
            billing_claims => {
                1003 => {
                    personnel => eleMentalClinic::Personnel->retrieve( 1001 ),
                    billed_date => '2006-07-15 18:04:25',
                    transactions => [
                        $CLASS->retrieve( 1009 ),
                        $CLASS->retrieve( 1010 ),
                    ],
                },
            },
        },
    });

    is( eleMentalClinic::Financial::Transaction->retrieve( 1007 )->entered_in_error, 1 );
        eleMentalClinic::Financial::Transaction->retrieve( 1007 )->entered_in_error( 0 )->save;
    is( eleMentalClinic::Financial::Transaction->retrieve( 1008 )->refunded, 1 );
        eleMentalClinic::Financial::Transaction->retrieve( 1008 )->refunded( 0 )->save;

    # TODO could use tests with multiple payments for the same payer

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
