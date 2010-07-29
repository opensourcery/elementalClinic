# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 426;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Description of testdata that will apply in the billing
# cycles being tested by this file is available here:
# https://prefect.opensourcery.com:444/projects/elementalclinic/wiki/EcsBilling/TestDataJazz
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

BEGIN {
    *CLASS = \'eleMentalClinic::Financial::BillingService';
    use_ok( $CLASS );
}

# Turn off the warnings coming from validation during financial setup.
$eleMentalClinic::Base::TESTMODE = 1;

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
    is( $one->table, 'billing_service');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id billing_claim_id billed_amount billed_units line_number
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_prognotes
    can_ok( $one, 'get_prognotes' );

    throws_ok{ $one->get_prognotes } qr/stored object/, 'get_prognotes throws exception when called without a stored object';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_unpaid
    can_ok( $CLASS, 'get_unpaid' );
    is( $CLASS->get_unpaid, undef, 'get_unpaid returns undef with no params' );
    is( $CLASS->get_unpaid( 1015 ), undef, 'get_unpaid returns undef when no billing_services exist yet' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_by_insurance
    can_ok( $CLASS, 'get_by_insurance' );
    is( $CLASS->get_by_insurance, undef, 'get_by_insurance returns undef with no params' );

    is( $CLASS->get_by_insurance( 1043, 1003 ), undef, 'get_by_insurance returns undef when no billing_services exist yet' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# concat_charge_code
    can_ok( $one, 'concat_charge_code' );

    is( $one->concat_charge_code, undef, 'concat_charge_code called with no params returns undef' );

        $tmp = {
            code_qualifier => 'HC',
            code          => '90801',
            modifiers     => [ 'HK', '12', '34', 'AB' ],
        };
    is( $one->concat_charge_code( $tmp ), '90801HK1234AB' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# concat_remarks
    can_ok( $one, 'concat_remarks' );

    is( $one->concat_remarks, undef );

        $tmp = [ 
            { code => 'M137', }, 
            { code => 'M1', }, 
        ]; 
    is( $one->concat_remarks( $tmp ), 'M137:M1' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# update_billing_status
    can_ok( $one, 'update_billing_status' );
        $one = $CLASS->new;
    throws_ok { $one->update_billing_status } qr/stored object/, 'Must call update_billing_status from a stored object';
    
    # check first before we do anything
    is( eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status, undef, 'billing_status for prognote 1043 is undef' );
    is( eleMentalClinic::ProgressNote->retrieve( 1044 )->billing_status, undef, 'billing_status for prognote 1044 is undef' );
    is( eleMentalClinic::ProgressNote->retrieve( 1056 )->billing_status, undef, 'billing_status for prognote 1056 is undef' );
    
    is( eleMentalClinic::Financial::BillingPrognote->retrieve( 1001 )->rec_id, undef, 'no billing prognotes exist yet' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_fully_paid
    can_ok( $one, 'is_fully_paid' );

        $one = $CLASS->new;
    throws_ok{ $one->is_fully_paid } qr/stored object/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_total_paid_previous
    can_ok( $one, 'get_total_paid_previous' );
 
        $one = $CLASS->new;
    throws_ok{ $one->get_total_paid_previous } qr/stored object/, 'Must call get_total_paid_previous with a stored object';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_billing_services
    can_ok( $one, 'get_other_billing_services' );

        $one = $CLASS->new;
    throws_ok{ $one->get_other_billing_services } qr/stored object/;
        
        $one = $CLASS->retrieve( 1003 );
    throws_ok{ $one->get_other_billing_services } qr/stored object/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_insurance_patient_liability
    can_ok( $one, 'get_other_insurance_patient_liability' );

        $one = $CLASS->new;
    throws_ok{ $one->get_other_insurance_patient_liability } qr/required/, 
        'Calling get_other_insurance_patient_liability with no params dies';
    throws_ok{ $one->get_other_insurance_patient_liability( 1001 ) } qr/Must call on stored object/, 
        'Calling get_other_insurance_patient_liability with no object dies';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# contains_subset_prognotes
    can_ok( $one, 'contains_subset_prognotes' );

    throws_ok{ $one->contains_subset_prognotes( $CLASS->new ) } qr/stored object/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Beginning First Billing Cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        my $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# new_billing_prognote
    can_ok( $one, 'new_billing_prognote' );
    is( $one->new_billing_prognote, undef );
        $one->empty;
    is( $one->new_billing_prognote(1001), undef, 'BillingService must exist.');
        $one->retrieve(1001);
    my $billing_prognote = $one->new_billing_prognote(1001);
    isa_ok( $billing_prognote, 'eleMentalClinic::Financial::BillingPrognote');
    my $test_billing_prognote = eleMentalClinic::Financial::BillingPrognote->retrieve($billing_prognote->id);
    is_deeply( $billing_prognote, $test_billing_prognote, 'created and db prognote match.'); 

        $one = $CLASS->new;
dbinit(1);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Reset First Billing Cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_fully_paid again
    
    is( $one->retrieve( 1001 )->is_fully_paid, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# charge_code
    can_ok( $one, 'charge_code' );

        $one = $CLASS->new;
    throws_ok{ $one->charge_code } qr/Must call on stored object/, 'charge_code throws exception if not called on stored object';
   
    is( $CLASS->retrieve( 1001 )->charge_code->{ name }, '90806' );
    is( $CLASS->retrieve( 1002 )->charge_code->{ name }, '90806' );
    is( $CLASS->retrieve( 1003 )->charge_code->{ name }, '90862HK' );
    is( $CLASS->retrieve( 1004 )->charge_code->{ name }, '90862' );
    is( $CLASS->retrieve( 1009 )->charge_code->{ name }, '90806' );
    is( $CLASS->retrieve( 1010 )->charge_code->{ name }, '90806' );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# amount_to_bill
    can_ok( $one, 'amount_to_bill' );

        $one = $CLASS->new;
    throws_ok{ $one->amount_to_bill } qr/Must call on stored object/;
 
    is_deeply( [ $CLASS->retrieve( 1001 )->amount_to_bill ], [ 131.44, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1002 )->amount_to_bill ], [ 131.44, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1003 )->amount_to_bill ], [ 124.64, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1004 )->amount_to_bill ], [ 131.44, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1005 )->amount_to_bill ], [ 131.44, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1006 )->amount_to_bill ], [ 131.44, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1007 )->amount_to_bill ], [ 131.44, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1008 )->amount_to_bill ], [ 124.64, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1009 )->amount_to_bill ], [ 131.44, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1010 )->amount_to_bill ], [ 131.44, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1011 )->amount_to_bill ], [ 131.44, 2 ] );
    is_deeply( [ $CLASS->retrieve( 1012 )->amount_to_bill ], [ 131.44, 2 ] );

        # Try it with the minutes_per_unit removed
        my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
        my $charge_code = $valid_data->get( '_charge_code', 1005 );
    is( $charge_code->{ minutes_per_unit }, 45 );
        $charge_code->{ minutes_per_unit } = 0;
        $valid_data->save( '_charge_code', $charge_code );
    is( $valid_data->get( '_charge_code', 1005 )->{ minutes_per_unit }, 0 );

    throws_ok{ $CLASS->retrieve( 1001 )->amount_to_bill } qr/Error calculating amount_to_bill for billing_service/;

        $charge_code->{ minutes_per_unit } = 45;
        $valid_data->save( '_charge_code', $charge_code );

        # Try it with the start_date removed
        my $prognote = eleMentalClinic::ProgressNote->retrieve( 1043 );
        my $start_date = $prognote->start_date;
        $prognote->start_date( '' );
        $prognote->save;
    throws_ok{ $CLASS->retrieve( 1003 )->amount_to_bill } qr/note is missing a start_date and\/or end_date/;
        $prognote->start_date( $start_date );
        $prognote->save;

        # Test with a prognote lasting a full day
        $prognote->start_date( '2006-07-02 12:00:00' ); # duration changed to 1 day
        $prognote->save;
    is_deeply( [ $CLASS->retrieve( 1003 )->amount_to_bill ], [ '2991.36', 48 ] );
        $prognote->start_date( $start_date );
        $prognote->save;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# calculate_amount_to_bill
    can_ok( $one, 'calculate_amount_to_bill' );

    throws_ok{ $one->calculate_amount_to_bill } qr/required/;
    throws_ok{ $one->calculate_amount_to_bill( $charge_code ) } qr/required/;

        # duration 210 min
        # minutes_per_unit 30 dollars_per_unit 65.72
        $charge_code = $valid_data->get( '_charge_code', 1003 );
        
        $charge_code->{ cost_calculation_method } = 'Per Session';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 210 ) ], [ '65.72', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Pro Rated Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 210 ) ], [ '460.04', 7 ] );
        $charge_code->{ cost_calculation_method } = 'Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 210 ) ], [ '460.04', 7 ] );

        # duration 60 min
        # minutes_per_unit 60 dollars_per_unit 131.44
        $charge_code = $valid_data->get( '_charge_code', 1001 );

        $charge_code->{ cost_calculation_method } = 'Per Session';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '131.44', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Pro Rated Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '131.44', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '131.44', 1 ] );

        # minutes_per_unit 45 dollars_per_unit 98.58
        $charge_code = $valid_data->get( '_charge_code', 1005 );

        $charge_code->{ cost_calculation_method } = 'Per Session';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '98.58', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Pro Rated Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '131.44', 2 ] );
        $charge_code->{ cost_calculation_method } = 'Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '197.16', 2 ] );

        $charge_code->{ minutes_per_unit } = 45;
        $charge_code->{ dollars_per_unit } = 60;

        $charge_code->{ cost_calculation_method } = 'Per Session';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '60.00', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Pro Rated Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '80.00', 2 ] );
        $charge_code->{ cost_calculation_method } = 'Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '120.00', 2 ] );
    
        # duration 15 min
        $charge_code->{ cost_calculation_method } = 'Per Session';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 15 ) ], [ '60.00', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Pro Rated Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 15 ) ], [ '20.00', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 15 ) ], [ '60.00', 1 ] );

        $charge_code->{ minutes_per_unit } = 15;

        $charge_code->{ cost_calculation_method } = 'Per Session';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 15 ) ], [ '60.00', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Pro Rated Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 15 ) ], [ '60.00', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 15 ) ], [ '60.00', 1 ] );

        # duration 60 min
        $charge_code->{ cost_calculation_method } = 'Per Session';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '60.00', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Pro Rated Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '240.00', 4 ] );
        $charge_code->{ cost_calculation_method } = 'Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '240.00', 4 ] );

        $charge_code->{ minutes_per_unit } = 30;
        $charge_code->{ dollars_per_unit } = 60;
       
        # duration 45 min
        $charge_code->{ cost_calculation_method } = 'Per Session';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 45 ) ], [ '60.00', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Pro Rated Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 45 ) ], [ '90.00', 2 ] );
        $charge_code->{ cost_calculation_method } = 'Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 45 ) ], [ '120.00', 2 ] );

        # duration 15 min
        $charge_code->{ cost_calculation_method } = 'Per Session';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 15 ) ], [ '60.00', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Pro Rated Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 15 ) ], [ '30.00', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 15 ) ], [ '60.00', 1 ] );

        # duration 60 min
        $charge_code->{ cost_calculation_method } = 'Per Session';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '60.00', 1 ] );
        $charge_code->{ cost_calculation_method } = 'Pro Rated Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '120.00', 2 ] );
        $charge_code->{ cost_calculation_method } = 'Dollars per Unit';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '120.00', 2 ] );

        # Try with unknown cost_calculation_method -- should default to Per Session 
        $charge_code->{ minutes_per_unit } = 45;
        $charge_code->{ dollars_per_unit } = 98.58;
        $charge_code->{ cost_calculation_method } = 'Some unknown value';
    is_deeply( [ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) ], [ '98.58', 1 ] );

        # Try it with the minutes_per_unit removed
        $charge_code->{ minutes_per_unit } = 0;
    throws_ok{ $CLASS->calculate_amount_to_bill( $charge_code, 60 ) } qr/charge code is missing minutes_per_unit and\/or dollars_per_unit/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_prognotes, continue tests

        $one = $CLASS->retrieve( 1001 );
    is_deeply( $one->get_prognotes, [ eleMentalClinic::ProgressNote->retrieve( 1065 ), ], 
        'get_prognotes gets associated prognotes for billing_service 1001' );

        $one = $CLASS->retrieve( 1003 );
    is_deeply( $one->get_prognotes, [ eleMentalClinic::ProgressNote->retrieve( 1043 ), ], 
        'get_prognotes gets associated prognotes for billing_service 1003' );

        $one = $CLASS->retrieve( 1004 );
    is_deeply( $one->get_prognotes, [ eleMentalClinic::ProgressNote->retrieve( 1044 ), ], 
        'get_prognotes gets associated prognotes for billing_service 1004' );

        $one = $CLASS->retrieve( 1009 );
    is_deeply( $one->get_prognotes, [ eleMentalClinic::ProgressNote->retrieve( 1056 ), ], 
        'get_prognotes gets associated prognotes for billing_service 1009' );

        $one = $CLASS->new;
      
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# service_dates
    can_ok( $one, 'service_dates' );
    throws_ok{ $one->service_dates } qr/stored object/;

    is_deeply( [ $one->retrieve( 1001 )->service_dates ], [ '2006-07-05', '2006-07-05' ] );
    is_deeply( [ $one->retrieve( 1002 )->service_dates ], [ '2006-07-12', '2006-07-12' ] );
    is_deeply( [ $one->retrieve( 1003 )->service_dates ], [ '2006-07-03', '2006-07-03' ] );
    is_deeply( [ $one->retrieve( 1004 )->service_dates ], [ '2006-07-05', '2006-07-05' ] );
    is_deeply( [ $one->retrieve( 1005 )->service_dates ], [ '2006-07-07', '2006-07-07' ] );
    is_deeply( [ $one->retrieve( 1006 )->service_dates ], [ '2006-07-10', '2006-07-10' ] );
    is_deeply( [ $one->retrieve( 1007 )->service_dates ], [ '2006-07-12', '2006-07-12' ] );
    is_deeply( [ $one->retrieve( 1008 )->service_dates ], [ '2006-07-14', '2006-07-14' ] );
    is_deeply( [ $one->retrieve( 1009 )->service_dates ], [ '2006-07-03', '2006-07-03' ] );
    is_deeply( [ $one->retrieve( 1010 )->service_dates ], [ '2006-07-07', '2006-07-07' ] );
    is_deeply( [ $one->retrieve( 1011 )->service_dates ], [ '2006-07-10', '2006-07-10' ] );
    is_deeply( [ $one->retrieve( 1012 )->service_dates ], [ '2006-07-14', '2006-07-14' ] );
 
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# facility_code
    can_ok( $one, 'facility_code' );
    throws_ok{ $one->facility_code } qr/stored object/;

    is( $one->retrieve( 1001 )->facility_code, '99' );
    is( $one->retrieve( 1002 )->facility_code, '99' );
    is( $one->retrieve( 1003 )->facility_code, '11' );
    is( $one->retrieve( 1004 )->facility_code, '11' );
    is( $one->retrieve( 1005 )->facility_code, '11' );
    is( $one->retrieve( 1006 )->facility_code, '11' );
    is( $one->retrieve( 1007 )->facility_code, '11' );
    is( $one->retrieve( 1008 )->facility_code, '11' );
    is( $one->retrieve( 1009 )->facility_code, '12' );
    is( $one->retrieve( 1010 )->facility_code, '12' );
    is( $one->retrieve( 1011 )->facility_code, '12' );
    is( $one->retrieve( 1012 )->facility_code, '12' );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# service_line
    can_ok( $one, 'service_line' );
    throws_ok{ $one->service_line } qr/stored object/;

        $one->retrieve( 1002 );
    is_deeply( $one->service_line, {
        billing_service_id      => 1002,
        service                 => '90806',
        modifiers               => undef,
        units                   => 2,
        charge_amount           => "131.44",
        service_date            => '20060712',
        diagnosis_code_pointers => [ '1' ],
        facility_code           => 99,
    });

    # Test a service_line with a prognote having 
    # undefined values for the charge codes' dollars_per_unit, minutes_per_unit
        $tmp = $valid_data->get( '_charge_code', 1005 );
    is( $tmp->{ minutes_per_unit }, 45 );
        $tmp->{ minutes_per_unit } = 0;
        $valid_data->save( '_charge_code', $tmp );
    is( $valid_data->get( '_charge_code', 1005 )->{ minutes_per_unit }, 0 );

    throws_ok{ $one->service_line } qr/Error calculating amount_to_bill for billing_service/;
    throws_ok{ $one->service_line } qr/charge code is missing minutes_per_unit and\/or dollars_per_unit/;
    
        # restore
        $tmp->{ minutes_per_unit } = 45;
        $valid_data->save( '_charge_code', $tmp );
        
        # do the same with dollars_per_unit
    is( $valid_data->get( '_charge_code', 1005 )->{ dollars_per_unit }, 98.58 );
        $tmp->{ dollars_per_unit } = 0;
        $valid_data->save( '_charge_code', $tmp );
    is( $valid_data->get( '_charge_code', 1005 )->{ dollars_per_unit }, '0.00' );

    throws_ok{ $one->service_line } qr/charge code is missing minutes_per_unit and\/or dollars_per_unit/;
        
        # restore
        $tmp->{ dollars_per_unit } = 98.58;
        $valid_data->save( '_charge_code', $tmp );

        # should work again
    ok( $one->service_line );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# service_line for hcfa
    throws_ok{ $one->service_line( 'is hcfa' ) } qr/stored object/;
    
        $one->retrieve( 1003 );
        # TODO don't need anymore?
        # set client_insurance_id because get_hcfa_service_line needs it 
#        $one->client_insurance_id( 1012 );
    is_deeply( $one->service_line( 'is hcfa' ), {
        start_date              => '07  03  06',
        end_date                => '07  03  06',
        facility_code           => '11',
        emergency               => undef,
        service                 => '90862',
        modifiers               => [ 'HK' ],
        diagnosis_code_pointers => [ '1', ],
        charge_amount           => "124.64",
        paid_amount             => '0.00',
        units                   => 2,
    });

        # TODO test with a different client_insurance 
#        $one->billing_claim->client_insurance_id( 1004 );
# where this charge code is in insurance_charge_code_association and this client's insurance overrides the valid_data_charge_code table for this code.
# so that the charge_amount is no longer 131.44
  
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# update_billing_status, continue the tests
    
    is( eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status, 'Billing', 'billing_status for prognote 1043 should be Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1044 )->billing_status, 'Billing', 'billing_status for prognote 1044 should be Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1056 )->billing_status, 'Billing', 'billing_status for prognote 1056 should be Billing' );
  
    # test that we can force a note to be marked 'Paid' regardless of what the transactions say
        $one = $CLASS->retrieve( 1003 );
        $one->update_billing_status( 'Paid' );
    is( eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status, 'Paid', 'billing_status for prognote 1043 should be Paid' );

    # reset the progress note back again
        eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status( 'Billing' )->save;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list by billing_claim, continue tests

    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1001 )->billing_services, [
        $CLASS->retrieve( 1001 ),
        $CLASS->retrieve( 1002 ),
    ], 'list billing services for billing_claim 1001' );
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1002 )->billing_services, [
        $CLASS->retrieve( 1003 ),
        $CLASS->retrieve( 1004 ),
        $CLASS->retrieve( 1005 ),
        $CLASS->retrieve( 1006 ),
        $CLASS->retrieve( 1007 ),
        $CLASS->retrieve( 1008 ),
    ], 'list billing services for billing_claim 1002' );
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1003 )->billing_services, [
        $CLASS->retrieve( 1009 ),
        $CLASS->retrieve( 1010 ),
        $CLASS->retrieve( 1011 ),
        $CLASS->retrieve( 1012 ),
    ], 'list billing services for billing_claim 1003' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_by_insurance, continue tests

    is( $CLASS->get_by_insurance( 1043 ), undef, 'get_by_insurance returns undef with no params' );
    is( $CLASS->get_by_insurance( 1043, 999 ), undef );
    is( $CLASS->get_by_insurance( 1001, 1003 ), undef );
    is_deeply( $CLASS->get_by_insurance( 1043, 1003 ), $CLASS->new->retrieve( 1003 ) );
    is( $CLASS->get_by_insurance( 1043, 1004 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    is( $CLASS->get_unpaid( 1015 ), undef, 'get_unpaid should still be undef' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_billing_services
        
        $one = $CLASS->retrieve( 1003 );
    is_deeply( $one->get_other_billing_services , [] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_insurance_patient_liability

        $one = $CLASS->retrieve( 1003 );
    throws_ok{ $one->get_other_insurance_patient_liability } qr/required/;
    
    is( $one->get_other_insurance_patient_liability( 1013 ), '59.00' ); # $59 copay
    is( $one->get_other_insurance_patient_liability( 1014 ), '59.00' );
    is( $one->get_other_insurance_patient_liability( 1015 ), '59.00' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write the 837 and hcfa for billing cycle 1 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        $billing_cycle->write_837( 1002 );
        $billing_cycle->write_hcfas( 1001 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save_as_billed
    can_ok( $one, 'save_as_billed' );
    
    throws_ok{ $one->save_as_billed } qr/required/;

        $one = $CLASS->retrieve( 1003 );
    # before billing
    is_deeply( $CLASS->retrieve( 1003 ), {
        rec_id              => 1003,
        billing_claim_id    => 1002,
        billed_amount       => undef,
        billed_units        => undef,
        line_number         => undef,
    });
    is( eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status, 'Billing' );

    ok( $one->save_as_billed( 1 ), '1003 is save_as_billed' );
    # after saving as billed
    is_deeply( $CLASS->retrieve( 1003 ), {
        rec_id              => 1003,
        billing_claim_id    => 1002,
        billed_amount       => '124.64',
        billed_units        => 2,
        line_number         => 1
    } );
    is( eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status, 'Billed' );

    ok( $one->save_as_billed( 1, 1 ), '1003 saved_as_billed manually' );
    is_deeply( $CLASS->retrieve( 1003 ), {
        rec_id              => 1003,
        billing_claim_id    => 1002,
        billed_amount       => '124.64',
        billed_units        => 2,
        line_number         => 1
    } );
    is( eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status, 'BilledManually' );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test billing_status for prognotes 
    
    is( eleMentalClinic::ProgressNote->retrieve( 1044 )->billing_status, 'Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1056 )->billing_status, 'Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1065 )->billing_status, 'Billed' );
  
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ECS files need to be marked as submitted separately from file generation

    ok( eleMentalClinic::Financial::BillingFile->retrieve( 1002 )->save_as_billed( '2006-06-29 16:04:25' ) );

    is( eleMentalClinic::ProgressNote->retrieve( 1044 )->billing_status, 'Billed' );
    is( eleMentalClinic::ProgressNote->retrieve( 1056 )->billing_status, 'Billed' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_unpaid
    
    is_deeply( $CLASS->get_unpaid( 1009 ), {
        1005 => {
            client_name => 'Powell Jr., Bud J',
            billing_services => [
                $CLASS->get_byid( 1001 ),
                $CLASS->get_byid( 1002 ),
            ],
        },
    });
    is( $CLASS->get_unpaid( 1014 ), undef );
    is_deeply( $CLASS->get_unpaid( 1015 ), {
        1003 => {
            client_name => 'Monk, Thelonious',
            billing_services => [ 
                $CLASS->get_byid( 1003 ),
                $CLASS->get_byid( 1004 ),
                $CLASS->get_byid( 1005 ),
                $CLASS->get_byid( 1006 ),
                $CLASS->get_byid( 1007 ),
                $CLASS->get_byid( 1008 ),
            ],
        },
        1004 => {
            client_name => 'Fitzgerald, Ella',
            billing_services => [
                $CLASS->get_byid( 1009 ),
                $CLASS->get_byid( 1010 ),
                $CLASS->get_byid( 1011 ),
                $CLASS->get_byid( 1012 ),
            ],
        },
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_total_paid_previous
   
    is( $CLASS->new->retrieve( 1001 )->get_total_paid_previous([ 1015 ]), '0.00', 'zero paid on billing_service 1001' );
    is( $CLASS->new->retrieve( 1003 )->get_total_paid_previous([ 1015 ]), '0.00', 'zero paid on billing_service 1003' );
    is( $CLASS->new->retrieve( 1004 )->get_total_paid_previous([ 1015 ]), '0.00', 'zero paid on billing_service 1004' );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_billing_services
        
        $one = $CLASS->retrieve( 1003 );
    is_deeply( $one->get_other_billing_services( 1013 ), [] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_insurances_paid_amount before first payment
    can_ok( $one, 'get_other_insurances_paid_amount' );

        $one = $CLASS->new;
    throws_ok{ $one->get_other_insurances_paid_amount } qr/stored object/;

        $one->retrieve( 1003 );
    is( $one->get_other_insurances_paid_amount, '0.00' );
        $one->retrieve( 1004 );
    is( $one->get_other_insurances_paid_amount, '0.00' );
        $one->retrieve( 1009 );
    is( $one->get_other_insurances_paid_amount, '0.00' );
        $one->retrieve( 1001 );
    is( $one->get_other_insurances_paid_amount, '0.00' );
        $one->retrieve( 999 );
    throws_ok{ $one->get_other_insurances_paid_amount } qr/stored object/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# transaction_amount
    can_ok( $one, 'transaction_amount' );

        $one = $CLASS->new;
    throws_ok{ $one->transaction_amount } qr/stored object/;

    is( $one->retrieve( 1001 )->transaction_amount, 0 );
    is( $one->retrieve( 1003 )->transaction_amount, 0 );
    throws_ok{ $one->retrieve( 1013 )->transaction_amount } qr/stored object/;
    throws_ok{ $one->retrieve( 1014 )->transaction_amount } qr/stored object/;
    throws_ok{ $one->retrieve( 1028 )->transaction_amount } qr/stored object/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# process a payment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        my $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.1.txt', '2006-09-05' ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_fully_paid again
   
    # not processed or paid
    is( $one->retrieve( 1001 )->is_fully_paid, 0 );
    is( $one->retrieve( 1002 )->is_fully_paid, 0 );
    # partially paid
    is( $one->retrieve( 1003 )->is_fully_paid, 0 );
    # fully paid
    is( $one->retrieve( 1004 )->is_fully_paid, 1 );
    is( $one->retrieve( 1005 )->is_fully_paid, 1 );
    is( $one->retrieve( 1006 )->is_fully_paid, 1 );
    is( $one->retrieve( 1007 )->is_fully_paid, 1 );
    is( $one->retrieve( 1008 )->is_fully_paid, 1 );
    # processed, but not paid
    is( $one->retrieve( 1009 )->is_fully_paid, 0 );
    is( $one->retrieve( 1010 )->is_fully_paid, 0 );
    is( $one->retrieve( 1011 )->is_fully_paid, 0 );
    # partially paid
    is( $one->retrieve( 1012 )->is_fully_paid, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_insurances_paid_amount after first payment
# -- they are all still zero because we're looking for any payment by any OTHER insurance, not the current one

        $one->retrieve( 1003 );
    is( $one->get_other_insurances_paid_amount, '0.00' );
        $one->retrieve( 1004 );
    is( $one->get_other_insurances_paid_amount, '0.00' );
        $one->retrieve( 1009 );
    is( $one->get_other_insurances_paid_amount, '0.00' );
        $one->retrieve( 1001 );
    is( $one->get_other_insurances_paid_amount, '0.00' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save_payment
    can_ok( $one, 'save_payment' );
    is( $one->save_payment, undef );

        # just checking beforehand...
        my $transaction = eleMentalClinic::Financial::Transaction->retrieve( 1011 );
    is( $transaction->rec_id, undef );

        # now do the payment
        $one = $CLASS->new;
        $one->retrieve( 1003 );
    is( $one->save_payment, undef );
    is( $one->save_payment( 1001 ), undef );

    # partial payment
        my $claim = { #{{{
            id                          => 1002,
            claim_header_id             => 961211,
            status_code                 => 1,
            total_charge_amount         => '775.04',
            payment_amount              => '658.00',
            patient_responsibility_amount => '42.16',
            claim_filing_indicator_code => 'MC',
            payer_claim_control_number  => 1999999444444,
            facility_code               => 11,
            claim_statement_period_start => '2006-07-03',
            claim_statement_period_end  => '2006-07-14',
            claim_contact               => undef,
            covered_actual              => 8,
            deductions                  => [],
            patient                     => {
                lname   => 'MONK',
                fname   => 'THELONIOUS',
                mname   => undef,
                name_suffix => undef,
                medicaid_recipient_id_number => '0141',
            },
            subscriber                  => {
                lname       => 'DE KOENIGSWARTER',
                fname       => 'NICA',
                mname       => undef,
                name_suffix => undef,
            },
            corrected_patient           => undef,
            corrected_payer             => undef,
            claim_contact               => undef,
            service_lines               => [ {
                payment_info        => {
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90862',
                        modifiers     => [ 'HK', ],
                    },
                    line_item_charge_amount         => 124.64,
                    line_item_provider_payment_amount => 7.48,
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    original_units_of_service_count => undef,
                },
                service_date                                => '2006-07-03',
                deductions                                  => [ {
                    group_code          => 'CO',
                    reason_code         => 'A2',
                    reason_text         => "Contractual adjustment. Note: Inactive for version 004060. Use Code 45 with Group Code 'CO' or use another appropriate specific adjustment code.",
                    deduction_amount    => '75.00',
                    deduction_quantity  => undef,
                },
                {
                    group_code          => 'PR',
                    reason_code         => 'A2',
                    reason_text         => "Contractual adjustment. Note: Inactive for version 004060. Use Code 45 with Group Code 'CO' or use another appropriate specific adjustment code.",
                    deduction_amount    => 42.16,
                    deduction_quantity  => '1',
                }  ],
                line_item_control_number                    => '1043',
                remarks                                     => [ {
                    code => 'M137',
                    text => 'Part B coinsurance under a demonstration project.',
                }, 
                {
                    code => 'M1',
                    text => 'X-ray not taken within the past 12 months or near enough to the start of treatment.',
                }, ],
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90862',
                        modifiers     => [],
                    },
                    line_item_charge_amount         => '131.44',
                    line_item_provider_payment_amount => '131.44',
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => undef,
                    original_units_of_service_count => undef,
                }, # }}}
                service_date                                => '2006-07-05',
                deductions                                  => [],
                line_item_control_number                    => '1044',
                remarks                                     => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90806',
                        modifiers     => [],
                    },
                    line_item_charge_amount         => 131.44,
                    line_item_provider_payment_amount => 131.44,
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => undef,
                    original_units_of_service_count => undef,
                }, # }}}
                service_date                                => '2006-07-07',
                deductions                                  => [],
                line_item_control_number                    => '1045',
                remarks                                     => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90806',
                        modifiers     => [],
                    },
                    line_item_charge_amount         => 131.44,
                    line_item_provider_payment_amount => 131.44,
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    original_units_of_service_count => undef,
                }, # }}}
                service_date                                => '2006-07-10',
                deductions                                  => [],
                line_item_control_number                    => '1046',
                remarks                                     => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90862',
                        modifiers     => [],
                    },
                    line_item_charge_amount         => '131.44',
                    line_item_provider_payment_amount => '131.44',
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    original_units_of_service_count => undef,
                }, # }}}
                service_date                                => '2006-07-12',
                deductions                                  => [],
                line_item_control_number                    => '1047',
                remarks                                     => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90862',
                        modifiers     => [ 'HK', ],
                    },
                    line_item_charge_amount         => 124.64,
                    line_item_provider_payment_amount => 124.64,
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    original_units_of_service_count => undef,
                }, # }}}
                service_date                                => '2006-07-14',
                deductions                                  => [],
                line_item_control_number                    => '1048',
                remarks                                     => [], 
            } ],
            inpatient_adjudication_info => { # {{{
                PPS_operating_outlier_amount                => undef,
                lifetime_psychiatric_days_count             => undef,
                claim_DRG_amount                            => '75.00',
                remarks                                     => [ {
                    code => 'M2',
                    text => 'Not paid separately when the patient is an inpatient.',
                },
                {
                    code => 'MA26',
                    text => 'Our records indicate that you were previously informed of this rule.',
                }, ],
                claim_disproportionate_share_amount         => undef,
                claim_MSP_pass_through_amount               => undef,
                claim_PPS_capital_amount                    => undef,
                PPS_capital_FSP_DRG_amount                  => undef,
                PPS_capital_HSP_DRG_amount                  => undef,
                PPS_capital_DSH_DRG_amount                  => undef,
                old_capital_amount                          => undef,
                PPS_capital_IME_amount                      => undef,
                PPS_operating_hospital_specific_DRG_amount  => undef,
                cost_report_day_count                       => undef,
                PPS_operating_federal_specific_DRG_amount   => undef,
                claim_PPS_capital_outlier_amount            => undef,
                claim_indirect_teaching_amount              => undef,
                nonpayable_professional_component_amount    => undef,
                PPS_capital_exception_amount                => undef,
            }, # }}}
            outpatient_adjudication_info                 => {
                reimbursement_rate              => undef,
                claim_HCPCS_payable_amount      => undef,
                claim_ESRD_payment_amount       => undef,
                nonpayable_professional_component_amount => undef,
                remarks                         => [],
            },
        }; # }}}
        my $service_line = { # {{{
                payment_info        => {
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90862',
                        modifiers     => [ 'HK', ],
                    },
                    line_item_charge_amount         => 124.64,
                    line_item_provider_payment_amount => 7.48,
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    original_units_of_service_count => undef,
                },
                service_date                                => '2006-07-03',
                deductions                                  => [ {
                    group_code          => 'CO',
                    reason_code         => 'A2',
                    reason_text         => "Contractual adjustment. Note: Inactive for version 004060. Use Code 45 with Group Code 'CO' or use another appropriate specific adjustment code.",
                    deduction_amount    => '75.00',
                    deduction_quantity  => undef,
                },
                {
                    group_code          => 'PR',
                    reason_code         => 'A2',
                    reason_text         => "Contractual adjustment. Note: Inactive for version 004060. Use Code 45 with Group Code 'CO' or use another appropriate specific adjustment code.",
                    deduction_amount    => 42.16,
                    deduction_quantity  => '1',
                }  ],
                line_item_control_number                    => '1043',
                remarks                                     => [ {
                    code => 'M137',
                    text => 'Part B coinsurance under a demonstration project.',
                }, 
                {
                    code => 'M1',
                    text => 'X-ray not taken within the past 12 months or near enough to the start of treatment.',
                }, ],
            }; # }}}

    ok( $one->save_payment( 1001, $claim, $service_line ) );

    # test that the transaction record got created
        $transaction->retrieve( 1011 );
    is_deeply( $transaction, {
        rec_id                              => 1011,
        billing_service_id                  => 1003,
        billing_payment_id                  => 1001,
        paid_amount                         => '7.48',
        paid_units                          => 2,
        claim_status_code                   => 1,
        patient_responsibility_amount       => '42.16',
        payer_claim_control_number          => '1999999444444',
        paid_charge_code                    => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                             => "M137:M1",
        entered_in_error                    => 0,
        refunded                            => 0,
    });

        $service_line = { # {{{
                payment_info        => {
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90862',
                        modifiers     => [],
                    },
                    line_item_charge_amount         => '131.44',
                    line_item_provider_payment_amount => '131.44',
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    original_units_of_service_count => undef,
                },
                service_date                                => '2006-07-05',
                deductions                                  => [],
                line_item_control_number                    => '1044',
                remarks                                     => [], 
            }; # }}}

    # full payment with a service_line
        $one->retrieve( 1004 );
    ok( $one->save_payment( 1001, $claim, $service_line ) );

        $transaction->retrieve( 1012 );
    is_deeply( $transaction, {
        rec_id                              => 1012,
        billing_service_id                  => 1004,
        billing_payment_id                  => 1001,
        paid_amount                         => '131.44',
        paid_units                          => 2,
        claim_status_code                   => 1,
        patient_responsibility_amount       => '42.16',
        payer_claim_control_number          => '1999999444444',
        paid_charge_code                    => '90862',
        submitted_charge_code_if_applicable => undef,
        remarks                             => undef,
        entered_in_error                    => 0,
        refunded                            => 0,
    });
    
    # full payment without a service_line
    ok( $one->save_payment( 1001, $claim ) );

        $transaction->retrieve( 1013 );
    is_deeply( $transaction, {
        rec_id                              => 1013,
        billing_service_id                  => 1004,
        billing_payment_id                  => 1001,
        paid_amount                         => '131.44',
        paid_units                          => 2,
        claim_status_code                   => 1,
        patient_responsibility_amount       => '42.16',
        payer_claim_control_number          => '1999999444444',
        paid_charge_code                    => undef,
        submitted_charge_code_if_applicable => undef,
        remarks                             => undef,
        entered_in_error                    => 0,
        refunded                            => 0,
    });

    # delete those unnecessary transaction records we just created
        $test->delete_( 'transaction_deduction', [ 1007, 1008 ], 'rec_id' );
        $test->delete_( 'transaction', [ 1011, 1012, 1013 ], 'rec_id' );
        $test->db->do_sql(qq/ SELECT setval( 'transaction_rec_id_seq', 1011, false ) /);

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_total_paid_previous
   
    throws_ok { $CLASS->new->retrieve( 999 )->get_total_paid_previous } qr/Must call on stored object/, 
        'get_total_paid_previous on non-existing billing_service throws exception'; 

    # get_total_paid_previous gets what was paid for OTHER billing_cycles, not this one
    is( $CLASS->new->retrieve( 1003 )->get_total_paid_previous([ 1015 ]), '0.00', 'zero paid on billing_service 1003' );
    is( $CLASS->new->retrieve( 1004 )->get_total_paid_previous([ 1015 ]), '0.00', 'zero paid on billing_service 1004' );

    # we can check this billing cycle's payments this way
    is( $one->retrieve( 1003 )->valid_transaction->paid_amount, 7.48 );
    is( $one->retrieve( 1004 )->valid_transaction->paid_amount, 131.44 );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_unpaid

    is_deeply( $CLASS->get_unpaid( 1009 ), {
        1005 => {
            client_name => 'Powell Jr., Bud J',
            billing_services => [
                $CLASS->get_byid( 1001 ),
                $CLASS->get_byid( 1002 ),
            ],
        },
    });
    is( $CLASS->get_unpaid( 1015 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_insurance_patient_liability

        $one = $CLASS->retrieve( 1003 );
    throws_ok{ $one->get_other_insurance_patient_liability } qr/required/;
    
    is( $one->get_other_insurance_patient_liability( 1013 ), '59.00' ); # $59 copay
    is( $one->get_other_insurance_patient_liability( 1014 ), '59.00' );
    is( $one->get_other_insurance_patient_liability( 1015 ), '59.00' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# update_billing_status, continue the tests after payment is made
    
    is( eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status, 'Partial' );
    is( eleMentalClinic::ProgressNote->retrieve( 1044 )->billing_status, 'Paid' );
    is( eleMentalClinic::ProgressNote->retrieve( 1143 )->billing_status, 'Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1065 )->billing_status, 'Billed' );

    # set the billing_status for 1043 and 1044 to 'Prebilling'
        eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status( 'Prebilling' )->save;
        eleMentalClinic::ProgressNote->retrieve( 1044 )->billing_status( 'Prebilling' )->save;

    # test that update_billing_status works when checking the transactions
        $one = $CLASS->retrieve( 1003 );
        $one->update_billing_status;
    is( eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status, 'Partial' );

        $one = $CLASS->retrieve( 1004 );
        $one->update_billing_status;
    is( eleMentalClinic::ProgressNote->retrieve( 1044 )->billing_status, 'Paid' );
 
        $one = $CLASS->retrieve( 1001 );
        $one->update_billing_status;
    is( eleMentalClinic::ProgressNote->retrieve( 1065 )->billing_status, 'Billed' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save service deductions 
# TODO : must test
    can_ok( $one, 'save_service_deductions' );
    is( $one->save_service_deductions, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid_transaction 
    can_ok( $one, 'valid_transaction' );

        $one = $CLASS->new;
    throws_ok{ $one->valid_transaction } qr/stored object/;

    is( $one->retrieve( 1001 )->valid_transaction, undef );

    is_deeply( $one->retrieve( 1003 )->valid_transaction, {
        rec_id                          => 1001,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => 'M137:M1',
        entered_in_error                => 0,
        refunded                        => 0,
    } );
            
    # create a duplicate transaction
        $tmp = eleMentalClinic::Financial::Transaction->new( {
            billing_service_id              => 1003,
            billing_payment_id              => 1001,
            paid_amount                     => "7.48",
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
        $tmp->save;

    # should pick up the lowest rec_id still
    is_deeply( $one->retrieve( 1003 )->valid_transaction, {
        rec_id                          => 1001,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
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

    # mark the first transaction as "entered_in_error"
        $tmp = eleMentalClinic::Financial::Transaction->retrieve( 1001 );
        $tmp->entered_in_error( 1 )->save;

    # should pick up the clean one, not the error one
    is_deeply( $one->retrieve( 1003 )->valid_transaction, {
        rec_id                          => 1011,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
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

    # restore the first transaction
        $tmp->entered_in_error( 0 )->save;

    # mark the first transaction as "refunded"
        $tmp->refunded( 1 )->save;

    # should pick up the clean one, not the refunded one
    is_deeply( $one->retrieve( 1003 )->valid_transaction, {
        rec_id                          => 1011,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
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

    # delete that unnecessary transaction record we just created
        $test->delete_( 'transaction', [ 1011 ], 'rec_id' );
    # and reset the sequence
        $test->db->do_sql(qq/ SELECT setval( 'transaction_rec_id_seq', 1011, false ) /);
    # and restore the first transaction
        $tmp->refunded( 0 )->save;

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# all_transactions 
    can_ok( $one, 'all_transactions' );

        $one = $CLASS->new;
    throws_ok{ $one->all_transactions } qr/stored object/;

    is( $one->retrieve( 1001 )->all_transactions, undef );

    is_deeply( $one->retrieve( 1003 )->all_transactions, [{
        rec_id                          => 1001,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => 'M137:M1',
        entered_in_error                => 0,
        refunded                        => 0,
    }] );

    # create a duplicate transaction
        $tmp = eleMentalClinic::Financial::Transaction->new( {
            billing_service_id              => 1003,
            billing_payment_id              => 1001,
            paid_amount                     => "7.48",
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
        $tmp->save;

    # should pick up both 
    is_deeply( $one->retrieve( 1003 )->all_transactions, [{
        rec_id                          => 1001,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => 'M137:M1',
        entered_in_error                => 0,
        refunded                        => 0,
    },
    {
        rec_id                          => 1011,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => 'M137:M1',
        entered_in_error                => 0,
        refunded                        => 0,
    }]);

    # mark the first transaction as "entered_in_error"
        $tmp = eleMentalClinic::Financial::Transaction->retrieve( 1001 );
        $tmp->entered_in_error( 1 );
        $tmp->save;

    # should still pick up all 
    is_deeply( $one->retrieve( 1003 )->all_transactions, [{
        rec_id                          => 1001,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => 'M137:M1',
        entered_in_error                => 1,
        refunded                        => 0,
    },
    {
        rec_id                          => 1011,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => 'M137:M1',
        entered_in_error                => 0,
        refunded                        => 0,
    }]);

    # mark the second transaction as "refunded"
        my $tmp2 = eleMentalClinic::Financial::Transaction->retrieve( 1011 );
        $tmp2->refunded( 1 )->save;

    # should still pick up all 
    is_deeply( $one->retrieve( 1003 )->all_transactions, [{
        rec_id                          => 1001,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => 'M137:M1',
        entered_in_error                => 1,
        refunded                        => 0,
    },
    {
        rec_id                          => 1011,
        billing_service_id              => 1003,
        billing_payment_id              => 1001,
        paid_amount                     => "7.48",
        paid_units                      => 2,
        claim_status_code               => 1,
        patient_responsibility_amount   => '42.16',
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => 'M137:M1',
        entered_in_error                => 0,
        refunded                        => 1,
    }]);

    # delete that unnecessary transaction record we just created
        $test->delete_( 'transaction', [ 1011 ], 'rec_id' );
    # and reset the sequence
        $test->db->do_sql(qq/ SELECT setval( 'transaction_rec_id_seq', 1011, false ) /);
    # and restore the transactions
        $tmp->entered_in_error( 0 )->save;
        $tmp2->refunded( 0 )->save;

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# finish the billing cycle

        $billing_cycle->validation_set->finish;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Beginning Second Billing Cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_cycle = $test->financial_setup_billingcycle;
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1006 ], [ 1014 ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_by_insurance, continue tests

    is_deeply( $CLASS->get_by_insurance( 1043, 1004 ), $CLASS->new->retrieve( 1013 ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write the 837 for the 2nd billing cycle 
       
        $test->financial_setup_bill( $billing_cycle, [ 1003 ], [], '2006-06-29 16:04:25' ); 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_fully_paid again
   
    # partially paid, billed again, but not processed by 2nd insurer yet
    is( $one->retrieve( 1003 )->is_fully_paid, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test a service line

    is_deeply( $CLASS->retrieve( 1013 ), {
        rec_id              => 1013,
        billing_claim_id    => 1004,
        billed_amount       => '124.64',
        billed_units        => 2,
        line_number         => 1
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_unpaid
    is( $CLASS->get_unpaid( 999 ), undef );
    is_deeply( $CLASS->get_unpaid( 1009 ), {
        1005 => {
            client_name => 'Powell Jr., Bud J',
            billing_services => [
                $CLASS->get_byid( 1001 ),
                $CLASS->get_byid( 1002 ),
            ],
        },
    });
    is_deeply( $CLASS->get_unpaid( 1014 ), {
        1003 => {
            client_name => 'Monk, Thelonious',
            billing_services => [ 
                $CLASS->get_byid( 1013 ),
            ],
        },
    });
    is( $CLASS->get_unpaid( 1015 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# transaction_amount

    is( $one->retrieve( 1001 )->transaction_amount, 0 );
    is( $one->retrieve( 1003 )->transaction_amount, 7.48 );
    is( $one->retrieve( 1013 )->transaction_amount, 0 );
    throws_ok{ $one->retrieve( 1014 )->transaction_amount } qr/stored object/;
    throws_ok{ $one->retrieve( 1028 )->transaction_amount } qr/stored object/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# process next payment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.2.txt', '2006-09-05' ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_fully_paid after second payment
   
    ok( $one->retrieve( 1003 )->is_fully_paid, "is_fully_paid after 2nd payment" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_insurances_paid_amount after second payment

    # first billing shows payment for second billing
    is( $one->retrieve( 1003 )->get_other_insurances_paid_amount, 117.16 );
    # second billing shows payment for first billing
    is( $one->retrieve( 1013 )->get_other_insurances_paid_amount, 7.48 );
   
    # only a single billing, so nothing is paid by other insurances
    is( $one->retrieve( 1004 )->get_other_insurances_paid_amount, '0.00' );
    is( $one->retrieve( 1009 )->get_other_insurances_paid_amount, '0.00' );
    is( $one->retrieve( 1001 )->get_other_insurances_paid_amount, '0.00' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_unpaid
    is_deeply( $CLASS->get_unpaid( 1009 ), {
        1005 => { 
            client_name => 'Powell Jr., Bud J',
            billing_services => [ 
                $CLASS->get_byid( 1001 ),
                $CLASS->get_byid( 1002 ),
            ],
        },
    });
    is( $CLASS->get_unpaid( 1014 ), undef );
    is( $CLASS->get_unpaid( 1015 ), undef );

    # mark a transaction as "entered_in_error"
        $tmp = $one->retrieve( 1013 )->valid_transaction;
        $tmp->entered_in_error( 1 )->save;

    # it should show up as unpaid again
    is_deeply( $CLASS->get_unpaid( 1014 ), {
        1003 => {
            client_name => 'Monk, Thelonious',
            billing_services => [ 
                $CLASS->get_byid( 1013 ),
            ],
        },
    });

    # reset entered_in_error
        $tmp->entered_in_error( 0 )->save;
    is( $CLASS->get_unpaid( 1014 ), undef );

    # mark a transaction as "refunded"
        $tmp = $one->retrieve( 1013 )->valid_transaction;
        $tmp->refunded( 1 )->save;

    # transaction still counts as 'paid', even though it's refunded (paid really means processed)
    is( $CLASS->get_unpaid( 1014 ), undef );

    # reset refunded
        $tmp->refunded( 0 )->save;
    is( $CLASS->get_unpaid( 1014 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_billing_services
        
        $one = $CLASS->retrieve( 1003 );
    is_deeply( $one->get_other_billing_services( 1013 ), [] );
    is_deeply( $one->get_other_billing_services( 1014 ), [
        $CLASS->retrieve( 1013 ) 
    ] );

    is_deeply( $one->get_other_billing_services( 1015 ), [] );

        $one = $CLASS->retrieve( 1013 );
    is_deeply( $one->get_other_billing_services( 1013 ), [] );
    is_deeply( $one->get_other_billing_services( 1014 ), [] );
    is_deeply( $one->get_other_billing_services( 1015 ), [
        $CLASS->retrieve( 1003 ) 
    ] );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_total_paid_previous
 
    # get_total_paid_previous gets what was paid for OTHER billing_cycles, not this one
    is( $CLASS->new->retrieve( 1003 )->get_total_paid_previous([ 1014 ]), 117.16, 'get_total_paid_previous again, after 2nd billing and payment' );
    is( $CLASS->new->retrieve( 1003 )->get_total_paid_previous([ 1015 ]), '0.00' );
    is( $CLASS->new->retrieve( 1003 )->get_total_paid_previous, '117.16', 'test get_total_paid_previous with no args' );


    is( $CLASS->new->retrieve( 1013 )->get_total_paid_previous([ 1014 ]), '0.00' );
    is( $CLASS->new->retrieve( 1013 )->get_total_paid_previous([ 1015 ]), 7.48 );
    is( $CLASS->new->retrieve( 1013 )->get_total_paid_previous, '7.48', 'test get_total_paid_previous with no args' );

    # TODO test get_total_paid_previous with entered_in_error, refunded transactions

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_insurance_patient_liability

        $one = $CLASS->retrieve( 1003 );
   
        # get the total paid by all but 1015 and the selected id
    is( $one->get_other_insurance_patient_liability( 1013 ), '176.16' ); # $59 copay + $117.16
    is( $one->get_other_insurance_patient_liability( 1014 ), '59.00' );
    is( $one->get_other_insurance_patient_liability( 1015 ), '176.16' ); # $59 copay + $117.16

        $one = $CLASS->retrieve( 1013 ); 
        # 2nd billing_prognote means same prognote, but different client_insurance 
        # so get total paid by all but 1014 and selected id
    is( $one->get_other_insurance_patient_liability( 1013 ), '7.48' ); # 0 copay
    is( $one->get_other_insurance_patient_liability( 1014 ), '7.48' );
    is( $one->get_other_insurance_patient_liability( 1015 ), '0.00' );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# finish the billing cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_cycle->validation_set->finish;
    
    is( eleMentalClinic::ProgressNote->retrieve( 1350 )->billing_status, undef );
    is( eleMentalClinic::ProgressNote->retrieve( 1351 )->billing_status, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Beginning Third Billing Cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
# Test a billing_service that has multiple prognotes (combined notes)

        $billing_cycle = $test->financial_setup_billingcycle( creation_date => '2006-07-31', from_date => '2006-07-16', to_date => '2006-07-31' );

    is( eleMentalClinic::ProgressNote->retrieve( 1350 )->billing_status, 'Prebilling' );
    is( eleMentalClinic::ProgressNote->retrieve( 1351 )->billing_status, 'Prebilling' );

        $test->financial_setup_system_validation( $billing_cycle, [ qw/ 1001 1003 1004 / ] );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1006 ], [ 1015 ] );
    
    is( eleMentalClinic::ProgressNote->retrieve( 1350 )->billing_status, 'Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1351 )->billing_status, 'Billing' );

    # FIXME we're skipping a billing to Providence, which would change the sequence of some ids
        $billing_cycle->validation_set->billing_cycle->write_837( 1004 );

    is_deeply( $CLASS->retrieve( 1016 ), {
        rec_id              => 1016,
        billing_claim_id    => 1006,
        billed_amount       => undef,
        billed_units        => undef,
        line_number         => undef,
    });

        eleMentalClinic::Financial::BillingFile->retrieve( 1004 )->save_as_billed( '2006-08-15 18:04:25' );
        $billing_cycle->validation_set->finish;

    is_deeply( $CLASS->retrieve( 1016 ), {
        rec_id              => 1016,
        billing_claim_id    => 1006,
        billed_amount       => '249.28',
        billed_units        => 4,
        line_number         => 2,
    });

    is( eleMentalClinic::ProgressNote->retrieve( 1350 )->billing_status, 'Billed' );
    is( eleMentalClinic::ProgressNote->retrieve( 1351 )->billing_status, 'Billed' );

    is_deeply( $CLASS->get_unpaid( 1015 ), {
        1003 => {
            client_name => 'Monk, Thelonious',
            billing_services => [ 
                $CLASS->get_byid( 1014 ),
                $CLASS->get_byid( 1015 ),
                $CLASS->get_byid( 1016 ),
                $CLASS->get_byid( 1017 ),
                $CLASS->get_byid( 1018 ),
                $CLASS->get_byid( 1019 ),
                $CLASS->get_byid( 1020 ),
                $CLASS->get_byid( 1021 ),
            ],
        },
        1004 => {
            client_name => 'Fitzgerald, Ella',
            billing_services => [
                $CLASS->get_byid( 1022 ),
                $CLASS->get_byid( 1023 ),
                $CLASS->get_byid( 1024 ),
                $CLASS->get_byid( 1025 ),
                $CLASS->get_byid( 1026 ),
            ],
        },
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test these methods with the multiple notes per service line 

        $one = $CLASS->retrieve( 1016 );
    is_deeply( $one->billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1016 ),
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1017 ),
    ]);

    is( $one->is_fully_paid, 0 );
    is( $one->charge_code->{ name }, '90862HK' );

    is_deeply( [ $one->amount_to_bill ], [ 249.28, 4 ] );

    is_deeply( $one->get_prognotes, [ 
        eleMentalClinic::ProgressNote->retrieve( 1050 ), 
        eleMentalClinic::ProgressNote->retrieve( 1350 ), 
    ], );

    is_deeply( [ $one->service_dates ], [ '2006-07-19', '2006-07-19' ] );
    is( $one->facility_code, '11' );

    is_deeply( $one->service_line, {
        billing_service_id      => 1016,
        service                 => '90862',
        modifiers               => [ 'HK' ],
        units                   => 4,
        charge_amount           => "249.28",
        service_date            => '20060719',
        diagnosis_code_pointers => [ '1' ],
        facility_code           => 11,
    });

    # test that we can force a note to be marked 'Paid' regardless of what the transactions say
        $one->update_billing_status( 'Paid' );
    is( eleMentalClinic::ProgressNote->retrieve( 1050 )->billing_status, 'Paid', 'billing_status for prognote 1050 should be Paid' );
    is( eleMentalClinic::ProgressNote->retrieve( 1350 )->billing_status, 'Paid', 'billing_status for prognote 1350 should be Paid' );
    # reset the progress notes back again
        eleMentalClinic::ProgressNote->retrieve( 1050 )->billing_status( 'Billed' )->save;
        eleMentalClinic::ProgressNote->retrieve( 1350 )->billing_status( 'Billed' )->save;

    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1006 )->billing_services, [
        $CLASS->retrieve( 1015 ),
        $CLASS->retrieve( 1016 ),
        $CLASS->retrieve( 1017 ),
        $CLASS->retrieve( 1018 ),
        $CLASS->retrieve( 1019 ),
        $CLASS->retrieve( 1020 ),
        $CLASS->retrieve( 1021 ),
    ], 'list billing services for billing_claim 1006' );

    is_deeply( $CLASS->get_by_insurance( 1050, 1003 ), $one );
    is_deeply( $CLASS->get_by_insurance( 1350, 1003 ), $one );

        # 1051 and 1351 should NOT be combined because they have different staff_ids and payer requires NPI for staff
    is( eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1003 )->requires_rendering_provider_ids, 1 );
        $one = $CLASS->retrieve( 1017 );
    is_deeply( $one->get_prognotes, [ 
        eleMentalClinic::ProgressNote->retrieve( 1051 ), 
    ], );
        $one = $CLASS->retrieve( 1014 );
    is_deeply( $one->get_prognotes, [ 
        eleMentalClinic::ProgressNote->retrieve( 1351 ), 
    ], );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# transaction_amount

    is( $one->retrieve( 1001 )->transaction_amount, 0 );
    is( $one->retrieve( 1003 )->transaction_amount, 7.48 );
    is( $one->retrieve( 1013 )->transaction_amount, 117.16 );
    is( $one->retrieve( 1014 )->transaction_amount, 0 );
    throws_ok{ $one->retrieve( 1028 )->transaction_amount } qr/stored object/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# process payment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.3.txt', '2006-09-05' ) );

        $one = $CLASS->retrieve( 1016 );
    is( $one->is_fully_paid, 0 );

        # adjust the payment to test full payment
        $tmp = eleMentalClinic::Financial::Transaction->retrieve( 1014 );
        $tmp->paid_amount( 249.28 );
        $tmp->save;
    is( $one->is_fully_paid, 1 );
    
        # revert back
        $tmp->paid_amount( 100.47 );
        $tmp->save;

        # test transaction methods
    is_deeply( $one->valid_transaction, {
        rec_id                          => 1014,
        billing_service_id              => 1016,
        billing_payment_id              => 1003,
        paid_amount                     => 100.47,
        paid_units                      => 4,
        claim_status_code               => 1,
        patient_responsibility_amount   => undef,
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    } );
            
    is_deeply( $one->all_transactions, [{
        rec_id                          => 1014,
        billing_service_id              => 1016,
        billing_payment_id              => 1003,
        paid_amount                     => 100.47,
        paid_units                      => 4,
        claim_status_code               => 1,
        patient_responsibility_amount   => undef,
        payer_claim_control_number      => 1999999444444,
        paid_charge_code                => '90862HK',
        submitted_charge_code_if_applicable => undef,
        remarks                         => undef,
        entered_in_error                => 0,
        refunded                        => 0,
    }] );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Beginning Fourth Billing Cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $test->financial_setup( 4, '', { no_payment => 1 } );

    # Check that 1050 and 1350 are still combined 
    is_deeply( $CLASS->retrieve( 1027 )->billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1028 ),
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1029 ),
    ]);
    is_deeply( $CLASS->retrieve( 1027 )->get_prognotes, [ 
        eleMentalClinic::ProgressNote->retrieve( 1050 ), 
        eleMentalClinic::ProgressNote->retrieve( 1350 ), 
    ], );
  
    # Test prognotes 1051 and 1351 again: diff personnel are ignored, so notes should be combined this time
        $one = $CLASS->retrieve( 1028 );
    is_deeply( $one->billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1030 ),    
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1031 ),    
    ]);

    # the only other prognote is not combined
    is_deeply( $CLASS->retrieve( 1029 )->billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1032 ),
    ]);
    is_deeply( $CLASS->retrieve( 1029 )->get_prognotes, [ 
        eleMentalClinic::ProgressNote->retrieve( 1052 ), 
    ], );

    is( $one->is_fully_paid, 0 );
    is( $one->charge_code->{ name }, '90806' );

    ok( @{$one->get_prognotes} > 1 );
    is_deeply( [ $one->amount_to_bill ], [ 262.88, 3 ] );

    is_deeply( $one->get_prognotes, [ 
        eleMentalClinic::ProgressNote->retrieve( 1051 ), 
        eleMentalClinic::ProgressNote->retrieve( 1351 ), 
    ], );

    is_deeply( [ $one->service_dates ], [ '2006-07-21', '2006-07-21' ] );
    is( $one->facility_code, '11' );

    is_deeply( $one->service_line( 'is hcfa' ), {
        start_date              => '07  21  06',
        end_date                => '07  21  06',
        facility_code           => '11',
        emergency               => undef,
        service                 => '90806',
        modifiers               => undef,
        diagnosis_code_pointers => [ '1', ],
        charge_amount           => "262.88",
        paid_amount             => '110.00',
        units                   => 3,
    });

    # test that we can force a note to be marked 'Paid' regardless of what the transactions say
        $one->update_billing_status( 'Paid' );
    is( eleMentalClinic::ProgressNote->retrieve( 1051 )->billing_status, 'Paid', 'billing_status for prognote 1051 should be Paid' );
    is( eleMentalClinic::ProgressNote->retrieve( 1351 )->billing_status, 'Paid', 'billing_status for prognote 1351 should be Paid' );
    # reset the progress notes back again
        eleMentalClinic::ProgressNote->retrieve( 1051 )->billing_status( 'Billed' )->save;
        eleMentalClinic::ProgressNote->retrieve( 1351 )->billing_status( 'Billed' )->save;

    # note now two sets of notes are combined
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1008 )->billing_services, [
        $CLASS->retrieve( 1027 ),
        $CLASS->retrieve( 1028 ),
        $CLASS->retrieve( 1029 ),
    ], 'list billing services for billing_claim 1008' );

    is_deeply( $CLASS->get_by_insurance( 1051, 1004 ), $one );
    is_deeply( $CLASS->get_by_insurance( 1351, 1004 ), $one );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_billing_services
       
    # 1050 and 1350
        $one = $CLASS->retrieve( 1016 );
    is_deeply( $one->get_other_billing_services( 1013 ), [] );
    is_deeply( $one->get_other_billing_services( 1014 ), [
        $CLASS->retrieve( 1027 )
    ] );
    is_deeply( $one->get_other_billing_services( 1015 ), [] );

        $one = $CLASS->retrieve( 1027 );
    is_deeply( $one->get_other_billing_services( 1013 ), [] );
    is_deeply( $one->get_other_billing_services( 1014 ), [] );
    is_deeply( $one->get_other_billing_services( 1015 ), [
        $CLASS->retrieve( 1016 ) 
    ] );

    # 1051 and 1351
        $one = $CLASS->retrieve( 1017 );
    is_deeply( $one->get_other_billing_services( 1013 ), [] );
    # will NOT pick up 1028 because this case is not handled by the system
    throws_ok { $one->get_other_billing_services( 1014 ) } qr/Notes previously sent combined are now sent individually; not supported/;
    is_deeply( $one->get_other_billing_services( 1015 ), [] );

        $one = $CLASS->retrieve( 1014 );
    is_deeply( $one->get_other_billing_services( 1013 ), [] );
    # will NOT pick up 1028 because this case is not handled by the system
    throws_ok { $one->get_other_billing_services( 1014 ) } qr/Notes previously sent combined are now sent individually; not supported/;
    is_deeply( $one->get_other_billing_services( 1015 ), [] );

        $one = $CLASS->retrieve( 1028 );
    is_deeply( $one->get_other_billing_services( 1013 ), [] );
    is_deeply( $one->get_other_billing_services( 1014 ), [] );
    is_deeply( $one->get_other_billing_services( 1015 ), [
        $CLASS->retrieve( 1014 ),
        $CLASS->retrieve( 1017 ) 
    ] );

        # try adding a billing_prognote to the wrong billing_service
        $tmp = eleMentalClinic::Financial::BillingPrognote->retrieve( 1032 );
    is( $tmp->billing_service_id, 1029 );
        $tmp->billing_service_id( 1027 );
        $tmp->save;

        $one = $CLASS->retrieve( 1016 );
    throws_ok { $one->get_other_billing_services( 1014 ) } qr/Notes previously sent as one combined group are not all getting sent combined now; not supported/;
        $one = $CLASS->retrieve( 1027 );
    is_deeply( $one->get_other_billing_services( 1015 ), [
        $CLASS->retrieve( 1016 ),
        $CLASS->retrieve( 1018 ),
    ] );

        # revert back
        $tmp->billing_service_id( 1029 );
        $tmp->save;

        # if notes previously sent individually are now combined, test what happens if we don't find all individual notes 
        $tmp = eleMentalClinic::Financial::BillingPrognote->retrieve( 1014 );
    is( $tmp->prognote_id, 1351 );
        $tmp->prognote_id( 1001 );
        $tmp->save;

        # - should be OK because this is possible with manual billing
        $one = $CLASS->retrieve( 1028 );
    is_deeply( $one->get_other_billing_services( 1015 ), [
        $CLASS->retrieve( 1017 ),
    ] );

            # revert back
            $tmp->prognote_id( 1351 );
            $tmp->save;

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# transaction_amount

    is( $one->retrieve( 1001 )->transaction_amount, 0 );
    is( $one->retrieve( 1003 )->transaction_amount, '7.48' );
    is( $one->retrieve( 1013 )->transaction_amount, '117.16' );
    is( $one->retrieve( 1014 )->transaction_amount, '100.00' );
    is( $one->retrieve( 1028 )->transaction_amount, 0 );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# contains_subset_prognotes

        $one = $CLASS->retrieve( 1016 );
    throws_ok{ $one->contains_subset_prognotes } qr/other service is required/;

    is( $one->contains_subset_prognotes( $CLASS->retrieve( 1027 ) ), 1 );
    is( $one->contains_subset_prognotes( $CLASS->retrieve( 1028 ) ), 0 );

        $one = $CLASS->retrieve( 1027 );
    is( $one->contains_subset_prognotes( $CLASS->retrieve( 1016 ) ), 1 );
    is( $one->contains_subset_prognotes( $CLASS->retrieve( 1021 ) ), 0 );

        $one = $CLASS->retrieve( 1028 );
    is( $one->contains_subset_prognotes( $CLASS->retrieve( 1014 ) ), 1 );
    is( $one->contains_subset_prognotes( $CLASS->retrieve( 1017 ) ), 1 );
    is( $one->contains_subset_prognotes( $CLASS->retrieve( 1027 ) ), 0 );

        $one = $CLASS->retrieve( 1029 );
    is( $one->contains_subset_prognotes( $CLASS->retrieve( 1018 ) ), 1 );
    is( $one->contains_subset_prognotes( $CLASS->retrieve( 1027 ) ), 0 );

        $one = $CLASS->retrieve( 1014 );
    is( $one->contains_subset_prognotes( $CLASS->retrieve( 1028 ) ), 0 );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save_manual_payment
    can_ok( $one, 'save_manual_payment' );
    throws_ok{ $one->save_manual_payment } qr/stored object/;

dbinit(1);
        $test->financial_setup( 1, '', { no_payment => 1 } );

        # check that the transaction doesn't exist yet 
        $transaction = eleMentalClinic::Financial::Transaction->retrieve( 1001 );
    is( $transaction->rec_id, undef );

        # check that the transaction deduction doesn't exist yet 
        my $transaction_deduction = eleMentalClinic::Financial::TransactionDeduction->retrieve( 1001 );
    is( $transaction_deduction->rec_id, undef );

        # need to create a billing_payment first
    is( eleMentalClinic::Financial::BillingPayment->retrieve( 1001 )->rec_id, undef );
    ok( eleMentalClinic::Financial::BillingPayment->new( {
        payment_amount          => 1000,
        payment_date            => '2006-08-31',
        payment_number          => '12345',
        date_received           => '2006-09-01',
        rolodex_id              => 1015,
        entered_by_staff_id     => 1001,
    })->save );
    is( eleMentalClinic::Financial::BillingPayment->retrieve( 1001 )->rec_id, 1001 );

        $one->retrieve( 1003 );
    throws_ok{ $one->save_manual_payment } qr/Missing parameters/;

        # test data to start with
        my $vars = { 
            paid_charge_code    => '90806',
            paid_amount         => 4.64,
            submitted_charge_code_if_applicable => '90862HK',
            paid_units          => 2,
            deduction_1         => 100,
            reason_1            => '',
            payer_claim_control_number => 'ABCD123',
            patient_responsibility_amount => '',
            remarks             => "M137:M1",
            billing_service_id  => 1003,
            billing_payment_id  => 1001,
            claim_status_code   => 1,
        };

    is( $one->save_manual_payment( $vars ),
        'Amount paid + deductions must add up to billed amount. Unaccounted for: $20.00',
        'deductions must add up' 
    );
        # fix paid_amount
        $vars->{ paid_amount } = 24.64;

    is( $one->save_manual_payment( $vars ),
        'Deductions must have both an amount and a reason.',
        'Deductions must have both an amount and a reason.'
    );
        # fix reason
        $vars->{ reason_1 } = 1;

    # works
    is( $one->save_manual_payment( $vars ), undef );

    # test that the transaction record got created
    is_deeply( $transaction->retrieve( 1001 ), {
        rec_id                              => 1001,
        billing_service_id                  => 1003,
        billing_payment_id                  => 1001,
        paid_amount                         => 24.64,
        paid_units                          => 2,
        claim_status_code                   => 1,
        patient_responsibility_amount       => undef,
        payer_claim_control_number          => 'ABCD123',
        paid_charge_code                    => '90806',
        submitted_charge_code_if_applicable => '90862HK',
        remarks                             => "M137:M1",
        entered_in_error                    => 0,
        refunded                            => 0,
    });

    # and that the transaction_deduction got created
    is_deeply( $transaction_deduction->retrieve( 1001 ), {
        rec_id          => 1001,
        transaction_id  => 1001,
        amount          => '100.00',
        units           => undef,
        group_code      => undef,
        reason_code     => 1,
    } );

        # test other variations on the input parameters
        # no deductions
        $vars->{ paid_amount } = 124.64;
        $vars->{ deduction_1 } = undef;
        $vars->{ reason_1 } = undef;
    is( $one->save_manual_payment( $vars ), undef );
    is( $transaction->retrieve( 1002 )->paid_amount, 124.64 );

        # all deductions
        $vars->{ paid_amount } = 24.64;
        $vars->{ deduction_1 } = 10;
        $vars->{ reason_1 } = 1;
        $vars->{ deduction_2 } = 20;
        $vars->{ reason_2 } = 2;
        $vars->{ deduction_3 } = 30;
        $vars->{ reason_3 } = 3;
        $vars->{ deduction_4 } = 40;
        $vars->{ reason_4 } = 4;
    is( $one->save_manual_payment( $vars ), undef );
    is( $transaction->retrieve( 1003 )->paid_amount, 24.64 );
    is( $transaction_deduction->retrieve( 1002 )->amount, '10.00' );
    is( $transaction_deduction->retrieve( 1003 )->amount, '20.00' );
    is( $transaction_deduction->retrieve( 1004 )->amount, '30.00' );
    is( $transaction_deduction->retrieve( 1005 )->amount, '40.00' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

