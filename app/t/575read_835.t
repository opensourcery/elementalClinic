# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 161;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
#use Test::Warn;

use eleMentalClinic::ECS::Read835;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::ECS::Read835';
    use_ok( $CLASS );
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
        
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

    isa_ok( $one->parser, 'X12::Parser' ); 
    like( $one->config_file, qr/835_004010X091.cf/ );
    like( $one->yaml_file, qr/read_835.yaml/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# format_ccyymmdd
    can_ok( $one, 'format_ccyymmdd' );

    is( $one->format_ccyymmdd, undef );
    is( $one->format_ccyymmdd( '060503' ), undef );
    is( $one->format_ccyymmdd( '20060503' ), '2006-05-03' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# data extraction methods, return undef with no edi data
    for( qw/
        composite_delimiter
        get_sender_interchange_id
        get_receiver_interchange_id
        get_interchange_date
        get_interchange_time
        get_interchange_control_number
        get_functional_group_count
        is_ack_requested
        is_production
        get_functional_identifier_code
        get_sender_code
        get_receiver_code
        get_functional_group_date
        get_functional_group_time
        get_group_control_number
        get_transaction_set_count
        get_x12_version
        get_transaction_set_identifier_code
        get_transaction_set_control_number
        get_segment_count
        get_transaction_monetary_amount
        get_credit_debit_flag_code
        get_payment_format_code
        get_payment_date
        get_payment_trace_type
        get_check_number
        get_originating_company_id
        get_originating_company_supplemental_code
        get_receiver_id
        get_system_version
        get_production_cycle_end_date
        get_payer_name
        get_payer_address
        get_payer_contact
        get_provider_name
        get_provider_NPI
        get_provider_address
        get_provider_tax_id
    /) {
        can_ok( $one, $_ );
        is( $one->$_, undef );
    };

    # non-standard
    can_ok( $one, 'is_paidby_check' );
    is( $one->is_paidby_check, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid_file
    can_ok( $one, 'valid_file' );

    throws_ok{ $one->valid_file } qr/required/;

    ok( $one->valid_file( 't/resource/sample_835.1.txt' ) );
    ok( $one->valid_file( 't/resource/sample_835.2.txt' ) );
    is( $one->valid_file( 't/resource/sample_837.1.txt' ), undef );
    is( $one->valid_file( 't/resource/sample_837.2.txt' ), undef );
    is( $one->valid_file( 't/resource/sample_997.1.txt' ), undef );
    is( $one->valid_file( 't/resource/sample_ta1.1.txt' ), undef );
    is( $one->valid_file( 't/resource/sample_ta1.2.txt' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# parse
    can_ok( $one, 'parse' );

    throws_ok{ $one->parse } qr/required/;

        $one->file( 't/resource/sample_835.1.txt' );
    ok( $one->parse );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# _load_yaml
    can_ok( $one, '_load_yaml' );

        my $some = $one->_load_yaml;

        # TODO tests

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_raw_edi
    can_ok( $one, 'get_raw_edi' );

    is( $one->get_raw_edi, undef );

        $one->file( 't/resource/sample_835.1.txt' );
    ok( $one->get_raw_edi );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_edi_data
    can_ok( $one, 'get_edi_data' );
    
    throws_ok{ $one->get_edi_data } qr/required/;

        $one->file( 't/resource/sample_835.1provideradjust.txt' );
        $one->parse;
        $one->get_edi_data;
    ok( $one->edi_data );
        
        #warn "\n";
        #warn Dumper $one->edi_data;

    is( $one->get_sender_interchange_id, '00824' );
    is( $one->get_receiver_interchange_id, 'OR00000' );
    is( $one->get_interchange_date, '2006-09-02' );
    is( $one->get_interchange_time, '13:43' );
    is( $one->get_interchange_control_number, '000000066' );
    is( $one->get_functional_group_count, 1 );
    is( $one->is_ack_requested, 0 );
    is( $one->is_production, 0 );
    is( $one->get_functional_identifier_code, 'HP' );
    is( $one->get_sender_code, '00824' );
    is( $one->get_receiver_code, 'OR00000' );
    is( $one->get_functional_group_date, '2006-09-02' );
    is( $one->get_functional_group_time, '15:03' );
    is( $one->get_group_control_number, '000001' );
    is( $one->get_transaction_set_count, 1 );
    is( $one->get_x12_version, '004010X091' );
    is( $one->get_transaction_set_identifier_code, '835' );
    is( $one->get_transaction_set_control_number, '1234' );
    is( $one->get_segment_count, 74 );
    is( $one->composite_delimiter, ':' );
    is( $one->get_transaction_monetary_amount, '684.91' );
    is( $one->get_credit_debit_flag_code, 'C' );
    is( $one->get_payment_method, 'CHK' );
    is( $one->is_paidby_check, 1 );
    is( $one->get_payment_format_code, undef );
    is( $one->get_payment_date, '2006-08-31' );
    is( $one->get_payment_trace_type, '1' );
    is( $one->get_check_number, '12345' );
    is( $one->get_originating_company_id, '1930555555' );
    is( $one->get_originating_company_supplemental_code, undef );
    is( $one->get_receiver_id, undef );
    is( $one->get_system_version, 'FS3.21' );
    is( $one->get_production_cycle_end_date, '2006-08-31' );
    is( $one->get_payer_name, 'MEDICARE B OF OREGON' );
    is_deeply( $one->get_payer_address, {
        addr_1 => 'PO BOX 9319',
        addr_2 => undef,
        city   => 'FARGO',
        state  => 'ND',
        zip    => '581066702',
    });

    is_deeply( $one->get_payer_contact, {
        name => 'HOWLIN WOLF',
        phone => '5035551212',
    });
    is( $one->get_provider_name, 'OUR CLINIC' );
    is( $one->get_provider_NPI, '1234567890' );
    is_deeply( $one->get_provider_address, {
        addr_1 => '123 4TH STREET',
        addr_2 => undef,
        city   => 'PORTLAND',
        state  => 'OR',
        zip    => '97200',
    });
    is( $one->get_provider_tax_id, '123456789' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_transaction_handling_code
    can_ok( $one, 'get_transaction_handling_code' );

    is( $one->get_transaction_handling_code, 'I' );

        my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
    is( $valid_data->get_byname( '_transaction_handling' ), undef );
    is( $valid_data->get_byname( '_transaction_handling', $one->get_transaction_handling_code )->{ description }, 
        'Remittance Information Only: payment is separate' );
    is( $valid_data->get_byname( '_transaction_handling', 'C' )->{ description }, 
        'Payment Accompanies Remittance Advice' );
    is( $valid_data->get_byname( '_transaction_handling', 'N' )->{ description }, 
        'Notification Only (Usually used to pass predetermination of benefits info from payer to provider)' );
    is( $valid_data->get_byname( '_transaction_handling', 'ABC' ), undef ); 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_claim_headers
    can_ok( $one, 'get_claim_headers' );

    is_deeply( $one->get_claim_headers, [ 
        {
            header_number                   => 961211,
            provider_id                     => 1234567890,
            facility_code                   => 11,
            fiscal_period_date              => '2006-12-31',
            total_claim_count               => 1,
            total_claim_charge_amount       => '775.04',
            total_covered_charge_amount     => '657.88',
            total_noncovered_charge_amount  => '25.00',
            total_denied_charge_amount      => '50.00',
            total_provider_payment_amount   => undef,
            total_interest_amount           => undef, 
            total_contractual_adjustment_amount => undef,
            claim_ids                       => [ 1002 ], 
        },
        {
            header_number                   => 961212,
            provider_id                     => 1234567890,
            facility_code                   => 12,
            fiscal_period_date              => '2006-12-31',
            total_claim_count               => 1,
            total_claim_charge_amount       => '525.76',
            total_covered_charge_amount     => '25.76',
            total_noncovered_charge_amount  => undef,
            total_denied_charge_amount      => '500.00',
            total_provider_payment_amount   => undef,
            total_interest_amount           => undef, 
            total_contractual_adjustment_amount => undef,
            claim_ids                       => [ 1003 ], 
        },
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_claims
    can_ok( $one, 'get_claims' );

    is_deeply( $one->get_claims, [
        {
            id                          => 1002,
            claim_header_id             => 961211,
            status_code                 => 1,
            total_charge_amount         => '775.04',
            payment_amount              => '657.88',
            patient_responsibility_amount => '42.16',
            claim_filing_indicator_code => 'MB',
            payer_claim_control_number  => 1999999444444,
            facility_code               => 11,
            #date_received               => undef,
            claim_statement_period_start => '2006-07-03',
            claim_statement_period_end  => '2006-07-14',
            claim_contact               => undef,
            covered_actual              => 8,
            #coinsured_actual            => undef,
            #patient_paid_amount         => undef,
            #interest                    => undef,
            deductions                   => [],
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
            service_lines               => [ {
                payment_info        => {
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90862',
                        modifiers     => [ 'HK', ],
                        #description   => undef,  # under most circumstances, this component is not sent
                    },
                    line_item_charge_amount         => 124.64,
                    line_item_provider_payment_amount => 7.48,
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    #submitted_medical_procedure => {
                    #    code_qualifier  => undef,
                    #    code            => undef,
                    #    modifiers       => [],
                    #    description     => undef,
                    #},
                    original_units_of_service_count => undef,
                },
                #service_period_start                        => undef,
                #service_period_end                          => undef,
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
                line_item_control_number                    => '1003',
                #location_number                             => undef,
                #rendering_provider_medicare_provider_number => undef,
                #rendering_provider_medicaid_provider_number => undef,
                #rendering_provider_provider_UPIN_number     => undef,
                #rendering_provider_CHAMPUS_number           => undef,
                #rendering_provider_national_provider_id     => undef,
                #allowed_actual                              => undef,
                #deduction_amount                            => undef,
                #non_covered_estimated                       => undef,
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
                        #description   => undef,  # under most circumstances, this component is not sent
                    },
                    line_item_charge_amount         => '131.44',
                    line_item_provider_payment_amount => '131.44',
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    #submitted_medical_procedure => {
                    #    code_qualifier  => undef,
                    #    code            => undef,
                    #    modifiers       => [],
                    #    description     => undef,
                    #},
                    original_units_of_service_count => undef,
                }, # }}}
                #service_period_start                        => undef,
                #service_period_end                          => undef,
                service_date                                => '2006-07-05',
                deductions                                  => [],
                line_item_control_number                    => '1004',
                #location_number                             => undef,
                #rendering_provider_medicare_provider_number => undef,
                #rendering_provider_medicaid_provider_number => undef,
                #rendering_provider_provider_UPIN_number     => undef,
                #rendering_provider_CHAMPUS_number           => undef,
                #rendering_provider_national_provider_id     => undef,
                #allowed_actual                              => undef,
                #deduction_amount                            => undef,
                #non_covered_estimated                       => undef,
                remarks                                      => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90806',
                        modifiers     => [],
                        #description   => undef,  # under most circumstances, this component is not sent
                    },
                    line_item_charge_amount         => 131.44,
                    line_item_provider_payment_amount => 131.44,
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    #submitted_medical_procedure => {
                    #    code_qualifier  => undef,
                    #    code            => undef,
                    #    modifiers       => [],
                    #    description     => undef,
                    #},
                    original_units_of_service_count => undef,
                }, # }}}
                #service_period_start                        => undef,
                #service_period_end                          => undef,
                service_date                                => '2006-07-07',
                deductions                                  => [],
                line_item_control_number                    => '1005',
                #location_number                             => undef,
                #rendering_provider_medicare_provider_number => undef,
                #rendering_provider_medicaid_provider_number => undef,
                #rendering_provider_provider_UPIN_number     => undef,
                #rendering_provider_CHAMPUS_number           => undef,
                #rendering_provider_national_provider_id     => undef,
                #allowed_actual                              => undef,
                #deduction_amount                            => undef,
                #non_covered_estimated                       => undef,
                remarks                                     => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90806',
                        modifiers     => [],
                        #description   => undef,  # under most circumstances, this component is not sent
                    },
                    line_item_charge_amount         => 131.44,
                    line_item_provider_payment_amount => 131.44,
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    #submitted_medical_procedure => {
                    #    code_qualifier  => undef,
                    #    code            => undef,
                    #    modifiers       => [],
                    #    description     => undef,
                    #},
                    original_units_of_service_count => undef,
                }, # }}}
                #service_period_start                        => undef,
                #service_period_end                          => undef,
                service_date                                => '2006-07-10',
                deductions                                  => [],
                line_item_control_number                    => '1006',
                #location_number                             => undef,
                #rendering_provider_medicare_provider_number => undef,
                #rendering_provider_medicaid_provider_number => undef,
                #rendering_provider_provider_UPIN_number     => undef,
                #rendering_provider_CHAMPUS_number           => undef,
                #rendering_provider_national_provider_id     => undef,
                #allowed_actual                              => undef,
                #deduction_amount                            => undef,
                #non_covered_estimated                       => undef,
                remarks                                     => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90862',
                        modifiers     => [],
                        #description   => undef,  # under most circumstances, this component is not sent
                    },
                    line_item_charge_amount         => '131.44',
                    line_item_provider_payment_amount => '131.44',
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    #submitted_medical_procedure => {
                    #    code_qualifier  => undef,
                    #    code            => undef,
                    #    modifiers       => [],
                    #    description     => undef,
                    #},
                    original_units_of_service_count => undef,
                }, # }}}
                #service_period_start                        => undef,
                #service_period_end                          => undef,
                service_date                                => '2006-07-12',
                deductions                                  => [],
                line_item_control_number                    => '1007',
                #location_number                             => undef,
                #rendering_provider_medicare_provider_number => undef,
                #rendering_provider_medicaid_provider_number => undef,
                #rendering_provider_provider_UPIN_number     => undef,
                #rendering_provider_CHAMPUS_number           => undef,
                #rendering_provider_national_provider_id     => undef,
                #allowed_actual                              => undef,
                #deduction_amount                            => undef,
                #non_covered_estimated                       => undef,
                remarks                                     => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90862',
                        modifiers     => [ 'HK', ],
                        #description   => undef,  # under most circumstances, this component is not sent
                    },
                    line_item_charge_amount         => 124.64,
                    line_item_provider_payment_amount => 124.64,
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    #submitted_medical_procedure => {
                    #    code_qualifier  => undef,
                    #    code            => undef,
                    #    modifiers       => [],
                    #    description     => undef,
                    #},
                    original_units_of_service_count => undef,
                }, # }}}
                #service_period_start                        => undef,
                #service_period_end                          => undef,
                service_date                                => '2006-07-14',
                deductions                                  => [],
                line_item_control_number                    => '1008',
                #location_number                             => undef,
                #rendering_provider_medicare_provider_number => undef,
                #rendering_provider_medicaid_provider_number => undef,
                #rendering_provider_provider_UPIN_number     => undef,
                #rendering_provider_CHAMPUS_number           => undef,
                #rendering_provider_national_provider_id     => undef,
                #allowed_actual                              => undef,
                #deduction_amount                            => undef,
                #non_covered_estimated                       => undef,
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
            #original_reference_number                    => undef,
            #prior_authorization_number                   => undef,
            #rendering_provider_medicaid_provider_number  => undef,
            #rendering_provider_UPIN_number               => undef,
            #rendering_provider_CHAMPUS_id_number         => undef,
        },
        {
            id                          => 1003,
            claim_header_id             => 961212,
            status_code                 => 1,
            total_charge_amount         => '525.76',
            payment_amount              => '25.76',
            patient_responsibility_amount => undef,
            claim_filing_indicator_code => 'MB',
            payer_claim_control_number  => 1999999444444,
            facility_code               => 12,
            #date_received               => undef,
            claim_statement_period_start => '2006-07-03',
            claim_statement_period_end  => '2006-07-14',
            claim_contact               => undef,
            covered_actual              => 8,
            #coinsured_actual            => undef,
            #patient_paid_amount         => undef,
            #interest                    => undef,
            deductions                  => [],
            patient                     => {
                lname   => 'FITZGERALD',
                fname   => 'ELLA',
                mname   => undef,
                name_suffix => undef,
                health_insurance_claim_number => '666666777A',
            },
            subscriber                  => {
                lname       => 'GERSHWIN',
                fname       => 'GEORGE',
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
                        code          => '90806',
                        modifiers     => [ ],
                        #description   => undef,  # under most circumstances, this component is not sent
                    },
                    line_item_charge_amount         => 131.44,
                    line_item_provider_payment_amount => '0.00',
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    #submitted_medical_procedure => {
                    #    code_qualifier  => undef,
                    #    code            => undef,
                    #    modifiers       => [],
                    #    description     => undef,
                    #},
                    original_units_of_service_count => undef,
                },
                #service_period_start                        => undef,
                #service_period_end                          => undef,
                service_date                                => '2006-07-03',
                deductions                                  => [ {
                    group_code          => 'CO',
                    reason_code         => 'A2',
                    reason_text         => "Contractual adjustment. Note: Inactive for version 004060. Use Code 45 with Group Code 'CO' or use another appropriate specific adjustment code.",
                    deduction_amount    => '131.44',
                    deduction_quantity  => undef,
                }  ],
                line_item_control_number                    => '1009',
                #location_number                             => undef,
                #rendering_provider_medicare_provider_number => undef,
                #rendering_provider_medicaid_provider_number => undef,
                #rendering_provider_provider_UPIN_number     => undef,
                #rendering_provider_CHAMPUS_number           => undef,
                #rendering_provider_national_provider_id     => undef,
                #allowed_actual                              => undef,
                #deduction_amount                            => undef,
                #non_covered_estimated                       => undef,
                remarks                                      => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90806',
                        modifiers     => [],
                        #description   => undef,  # under most circumstances, this component is not sent
                    },
                    line_item_charge_amount         => '131.44',
                    line_item_provider_payment_amount => '0.00',
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    #submitted_medical_procedure => {
                    #    code_qualifier  => undef,
                    #    code            => undef,
                    #    modifiers       => [],
                    #    description     => undef,
                    #},
                    original_units_of_service_count => undef,
                }, # }}}
                #service_period_start                        => undef,
                #service_period_end                          => undef,
                service_date                                => '2006-07-07',
                deductions                                  => [ {
                    group_code          => 'CO',
                    reason_code         => 'A2',
                    reason_text         => "Contractual adjustment. Note: Inactive for version 004060. Use Code 45 with Group Code 'CO' or use another appropriate specific adjustment code.",
                    deduction_amount    => '131.44',
                    deduction_quantity  => undef,
                }  ],
                line_item_control_number                    => '1010',
                #location_number                             => undef,
                #rendering_provider_medicare_provider_number => undef,
                #rendering_provider_medicaid_provider_number => undef,
                #rendering_provider_provider_UPIN_number     => undef,
                #rendering_provider_CHAMPUS_number           => undef,
                #rendering_provider_national_provider_id     => undef,
                #allowed_actual                              => undef,
                #deduction_amount                            => undef,
                #non_covered_estimated                       => undef,
                remarks                                     => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90806',
                        modifiers     => [],
                        #description   => undef,  # under most circumstances, this component is not sent
                    },
                    line_item_charge_amount         => 131.44,
                    line_item_provider_payment_amount => '0.00',
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    #submitted_medical_procedure => {
                    #    code_qualifier  => undef,
                    #    code            => undef,
                    #    modifiers       => [],
                    #    description     => undef,
                    #},
                    original_units_of_service_count => undef,
                }, # }}}
                #service_period_start                        => undef,
                #service_period_end                          => undef,
                service_date                                => '2006-07-10',
                deductions                                  => [ {
                    group_code          => 'CO',
                    reason_code         => 'A2',
                    reason_text         => "Contractual adjustment. Note: Inactive for version 004060. Use Code 45 with Group Code 'CO' or use another appropriate specific adjustment code.",
                    deduction_amount    => '131.44',
                    deduction_quantity  => undef,
                }  ],
                line_item_control_number                    => '1011',
                #location_number                             => undef,
                #rendering_provider_medicare_provider_number => undef,
                #rendering_provider_medicaid_provider_number => undef,
                #rendering_provider_provider_UPIN_number     => undef,
                #rendering_provider_CHAMPUS_number           => undef,
                #rendering_provider_national_provider_id     => undef,
                #allowed_actual                              => undef,
                #deduction_amount                            => undef,
                #non_covered_estimated                       => undef,
                remarks                                     => [], 
            },
            {
                payment_info        => { # {{{
                    medical_procedure => {
                        code_qualifier => 'HC',
                        code          => '90806',
                        modifiers     => [],
                        #description   => undef,  # under most circumstances, this component is not sent
                    },
                    line_item_charge_amount         => 131.44,
                    line_item_provider_payment_amount => 25.76,
                    national_uniform_billing_committee_revenue_code => undef,
                    units_of_service_paid_count     => 2,
                    #submitted_medical_procedure => {
                    #    code_qualifier  => undef,
                    #    code            => undef,
                    #    modifiers       => [],
                    #    description     => undef,
                    #},
                    original_units_of_service_count => undef,
                }, # }}}
                #service_period_start                        => undef,
                #service_period_end                          => undef,
                service_date                                => '2006-07-14',
                deductions                                 => [ {
                    group_code          => 'CO',
                    reason_code         => 'A2',
                    reason_text         => "Contractual adjustment. Note: Inactive for version 004060. Use Code 45 with Group Code 'CO' or use another appropriate specific adjustment code.",
                    deduction_amount    => '105.68',
                    deduction_quantity  => undef,
                }  ],
                line_item_control_number                    => '1012',
                #location_number                             => undef,
                #rendering_provider_medicare_provider_number => undef,
                #rendering_provider_medicaid_provider_number => undef,
                #rendering_provider_provider_UPIN_number     => undef,
                #rendering_provider_CHAMPUS_number           => undef,
                #rendering_provider_national_provider_id     => undef,
                #allowed_actual                              => undef,
                #deduction_amount                            => undef,
                #non_covered_estimated                       => undef,
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
            #original_reference_number                    => undef,
            #prior_authorization_number                   => undef,
            #rendering_provider_medicaid_provider_number  => undef,
            #rendering_provider_UPIN_number               => undef,
            #rendering_provider_CHAMPUS_id_number         => undef,
        },
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_provider_deductions
    can_ok( $one, 'get_provider_deductions' );

        $tmp = [ {
            reason_code         => 'CV',
            id                  => 'CP',
            amount              => '-1.27',
            provider_id         => '1234567890',
            fiscal_period_date  => '2006-12-31',
        }, ];

    is_deeply( $one->get_provider_deductions, $tmp );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test that get_edi_data sends the right warning when 
# attempting to parse an 837
        $one->file( 't/resource/sample_837.1.txt' );
        $one->parse;
#    warning_is { $one->get_edi_data } "The file [t/resource/sample_837.1.txt] is not a valid 835 file", 'Invalid 835 warning';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
