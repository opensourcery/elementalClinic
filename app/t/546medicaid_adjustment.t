# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 26;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Financial::MedicaidAdjustment';
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
# field info
    is_deeply( $CLASS->fields, [qw/
        form transactions billing_claim_id billing_payment_id client_id
        date_requested underpayment internal_control_number ra_date
        recipient_name recipient_id provider_name provider_number
        provider_npi provider_taxonomy place charge_code modifier
        units diagnosis performing_provider billed_amount
        medicare_payment other_payment coinsurance other remarks
    /]);
    is_deeply( $CLASS->fields_required, [ qw/ transaction_ids /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->empty );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));
    is( $one->form, 'medicaidadjustment' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# run the first billing cycle 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $test->financial_setup( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# filename
    can_ok( $one, 'filename' );

        $one = $CLASS->empty; 
    throws_ok { $one->filename } qr/required/;
        $one = $CLASS->new({
            date_requested  => '2006-11-21',
            billing_claim_id  => 1001,
        });
    is( $one->filename, "MedicaidAdjustment1001.112106.pdf" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# populate
    can_ok( $one, 'populate' );
    can_ok( $one, 'populate_transactions' );

        $one = $CLASS->empty; 
    ok( $one->populate );
    like( $one->date_requested, qr/\d\d\d\d-\d\d-\d\d/ );
    is( $one->form, 'medicaidadjustment' );

        $one = $CLASS->empty( { date_requested => '2006-11-21' } );
    ok( $one->populate({
        date_requested      => '2006-11-21',
        transaction_ids     => [ 1001, 1002, 1003 ],
        place_1001          => 1,
        place_wrong         => 12,
        place_right_1001    => 11,
        place_right_1002    => 11,
        place_right_1003    => 11,
        charge_code_1001    => 1,
        charge_code_wrong   => 'H0036',
        charge_code_right_1001  => '90862',
        charge_code_right_1002  => 'XXXXX',
        charge_code_right_1003  => 'ZZZZZ',
        modifier_1002       => 1,
        modifier_wrong      => 'HK',
        modifier_right_1001 => '',
        modifier_right_1002 => '',
        modifier_right_1003 => '',
        units_1001          => 1,
        units_1002          => 1,
        units_wrong         => 99,
        units_right_1001    => 2,
        units_right_1002    => 4,
        units_right_1003    => 8,
        diagnosis_1001      => 1,
        diagnosis_wrong     => '295.30',
        diagnosis_right_1001 => '',
        diagnosis_right_1002 => '250.00',
        diagnosis_right_1003 => '555.55',
        performing_provider_1001 => 1,
        performing_provider_wrong => 'Performing Provider',
        performing_provider_right_1001 => 'Betty Clinician',
        performing_provider_right_1002 => 'Betty NonClinician',
        performing_provider_right_1003 => 'Betty Chemist',
        billed_amount_1002  => 1,
        billed_amount_wrong => '45.00',
        billed_amount_right_1001 => '99.99',
        billed_amount_right_1002 => '131.44',
        billed_amount_right_1003 => '88.88',
        medicare_payment_1002 => 1,
        medicare_payment_wrong => '46.00',
        medicare_payment_right_1001 => '55.00',
        medicare_payment_right_1002 => '',
        medicare_payment_right_1003 => '77.00',
        other_payment_1001  => 1,
        other_payment_wrong => '47.00',
        other_payment_right_1001 => '',
        other_payment_right_1002 => '',
        other_payment_right_1003 => '55.00',
        coinsurance_wrong   => '48.00',
        coinsurance_right_1001   => '1.0',
        coinsurance_right_1002   => '2.0',
        coinsurance_right_1003   => '3.0',
        other_1001          => 1,
        other_wrong         => 'NoneOther',
        other_right         => 'Other',
    }) );
    is_deeply( $one, {
        form            => 'medicaidadjustment',
        date_requested      => '2006-11-21',
        billing_payment_id => 1001,
        client_id       => 1003,
        billing_claim_id => 1002,
        internal_control_number => '1999999444444',
        ra_date         => '8/31/2006',
        recipient_name  => 'Monk, Thelonious',
        recipient_id    => '0141',
        provider_name   => 'Our Clinic',
        provider_number => '000000',
        provider_npi    => '1234567890',
        provider_taxonomy => '101Y00000X',
        underpayment    => undef,
        remarks         => undef,
        place           => { line_numbers => [ 1 ], service_date => '7/3/2006', right => 11, wrong => 12, },
        charge_code     => { line_numbers => [ 1 ], service_date => '7/3/2006', right => '90862', wrong => 'H0036', },
        modifier        => { line_numbers => [ 2 ], service_date => '7/5/2006', right => '', wrong => 'HK', },
        units           => { line_numbers => [ 1, 2 ], service_date => '7/3/2006', right => 2, wrong => 99, },
        diagnosis       => { line_numbers => [ 1 ], service_date => '7/3/2006', right => '', wrong => '295.30', },
        performing_provider => { line_numbers => [ 1 ], service_date => '7/3/2006', right => 'Betty Clinician', wrong => 'Performing Provider', },
        billed_amount   => { line_numbers => [ 2 ], service_date => '7/5/2006', right => '131.44', wrong => '45.00', },
        medicare_payment => { line_numbers => [ 2 ], service_date => '7/5/2006', right => '', wrong => '46.00', },
        other_payment   => { line_numbers => [ 1 ], service_date => '7/3/2006', right => '', wrong => '47.00', },
        coinsurance     => undef,
        other           => { line_numbers => [ 1 ], service_date => '7/3/2006', right => 'Other', wrong => 'NoneOther', },
        transactions    => [ {
            billing_payment_id     => '1001',
            billing_service_id     => '1003',
            entered_in_error       => 0,
            refunded               => 0,
            paid_amount            => '7.48',
            paid_charge_code       => '90862HK',
            paid_units             => '2',
            claim_status_code      => '1',
            patient_responsibility_amount  => '42.16',
            payer_claim_control_number  => '1999999444444',
            rec_id                 => '1001',
            remarks                => 'M137:M1',
            submitted_charge_code_if_applicable => undef,
        },
        {
            billing_payment_id      => '1001',
            billing_service_id      => '1004',
            entered_in_error        => 0,
            refunded                => 0,
            paid_amount             => '131.44',
            paid_charge_code        => '90862',
            paid_units              => '2',
            claim_status_code       => '1',
            patient_responsibility_amount => '42.16',
            payer_claim_control_number => '1999999444444',
            rec_id                  => '1002',
            remarks                 => undef,
            submitted_charge_code_if_applicable => undef
        },
        {
            billing_payment_id      => '1001',
            billing_service_id      => '1005',
            entered_in_error        => 0,
            refunded                => 0,
            paid_amount             => '131.44',
            paid_charge_code        => '90806',
            paid_units              => '2',
            claim_status_code       => '1',
            patient_responsibility_amount => '42.16',
            payer_claim_control_number => '1999999444444',
            rec_id                  => '1003',
            remarks                 => undef,
            submitted_charge_code_if_applicable => undef
        }, ],
    });
    
        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write
    can_ok( $one, 'write' );

        $one = $CLASS->empty({
            date_requested  => '2006-11-29',
            underpayment    => 0,
            internal_control_number => '1004163315070',
            ra_date         => '07-16-2006',
            recipient_name  => 'Ella Fitzgerald',
            recipient_id    => 'AK97940A',
            provider_name   => 'Our Clinic',
            provider_number => '503641',
            provider_npi    => '1234567890',
            provider_taxonomy => '101Y00000X',
            remarks         => 'overpayment $216.63',
            billing_claim_id => 1002,
            place   => { 
                line_numbers => [ 2, 5 ],
                service_date => '05/20/06',
                wrong        => '11',
                right        => 'Place',
            },
            charge_code   => { 
                line_numbers => [ 3 ],
                service_date => '04/20/06',
                wrong        => 'H0036',
                right        => 'Charge Code',
            },
            modifier   => { 
                line_numbers => [ 3 ],
                service_date => '04/20/06',
                wrong        => 'HK',
                right        => 'Modifier',
            },
            units   => { 
                line_numbers => [ 3 ],
                service_date => '04/20/06',
                wrong        => '2',
                right        => 'Units',
            },
            diagnosis   => { 
                line_numbers => [ 3 ],
                service_date => '04/20/06',
                wrong        => '295.30',
                right        => 'Diagnosis',
            },
            performing_provider   => { 
                line_numbers => [ 3 ],
                service_date => '04/20/06',
                wrong        => 'Ima Therapist',
                right        => 'Performing Provider',
            },
            billed_amount   => { 
                line_numbers => [ 3 ],
                service_date => '04/20/06',
                wrong        => '45',
                right        => 'Bill Amount',
            },
            medicare_payment   => { 
                line_numbers => [ 3 ],
                service_date => '04/20/06',
                wrong        => '20.00',
                right        => 'Medicare Payment',
            },
            other_payment   => { 
                line_numbers => [ 3 ],
                service_date => '04/20/06',
                wrong        => '10.00',
                right        => 'Other Payment',
            },
            coinsurance   => { 
                line_numbers => [ 3 ],
                service_date => '04/20/06',
                wrong        => 'XXX',
                right        => 'Coinsurance',
            },
            other   => { 
                line_numbers => [ 3 ],
                service_date => '04/20/06',
                wrong        => 'something else',
                right        => 'Other',
            },
        });
        # temporarily remove form
        $one->form( '' );
    throws_ok{ $one->write } qr/required/;

        $one->form( 'medicaidadjustment' );

    ok( $tmp = $one->write );
    like( $tmp, qr/MedicaidAdjustment1002.112906.pdf/ );
    ok( -f $tmp, "test file $tmp exists after write()." );
    ok( `file $tmp` =~ /PDF/,  "$tmp is a pdf file" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# string_to_boxes

    is( eleMentalClinic::Financial::MedicaidAdjustment::string_to_boxes, undef );
    is_deeply( [ eleMentalClinic::Financial::MedicaidAdjustment::string_to_boxes( 'frog' ) ], [
        { x =>  0, y => 0, value => 'f' },
        { x => 18, y => 0, value => 'r' },
        { x => 36, y => 0, value => 'o' },
        { x => 54, y => 0, value => 'g' },
    ]);
    is_deeply( [ eleMentalClinic::Financial::MedicaidAdjustment::string_to_boxes( 'toad', 250, 300 ) ], [
        { x => 250, y => 300, value => 't' },
        { x => 268, y => 300, value => 'o' },
        { x => 286, y => 300, value => 'a' },
        { x => 304, y => 300, value => 'd' },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
