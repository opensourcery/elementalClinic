# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 39;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

use eleMentalClinic::Financial::BillingFile;

our ($CLASS, $one, $tmp);
our $BILLING_FILE_REC_ID = 1002;
our $DATE_STAMP = '20060629';
our $MMDD_STAMP = '0629';
our $TIME_STAMP = '1604';

BEGIN {
    *CLASS = \'eleMentalClinic::ECS::Write837';
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
# start the first billing cycle 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( my $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 ) );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setup for upcoming tests

        my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $BILLING_FILE_REC_ID );
        $one = $CLASS->new( { 
            billing_file => $billing_file,
            date_stamp => $DATE_STAMP,
            time_stamp => $TIME_STAMP,
        });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# template_path and edi_out_root path are obtained from
# Base::config
# Verify that $self->output_root provides same path as config->edi_out_root
    can_ok( $one, 'output_root' );
    ok( $one->output_root );
    ok( $one->config->edi_out_root );
    is( $one->config->edi_out_root, $one->output_root);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make filenames
    can_ok( $one, 'make_filename');
    
    is( $one->make_filename, "${BILLING_FILE_REC_ID}t837P$MMDD_STAMP.txt" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate
    can_ok( $one, 'validate' );
    is( $one->validate, undef );

        # good data: test that it is not altered
        my $good = {  # {{{
            'date' => '060629',
            'date_long' => '20060629',
            'time' => '1604',
            'billing_file' => {
                'billing_cycle_id' => '1002',
                'edi' => undef,
                'group_control_number' => '1',
                'is_production' => '0',
                'purpose' => '00',
                'rec_id' => '1003',
                'rolodex_id' => '1014',
                'set_control_number' => '1',
                'submission_date' => undef,
                'type' => 'CH',
                'payer' => {
                    'address' => 'P.O. Box 5490',
                    'address2' => undef,
                    'city' => 'Salem',
                    'claims_processor_id' => '1002',
                    'edi_indicator_code' => 'MC',
                    'id' => '181632',
                    'name' => 'WCHHS',
                    'state' => 'OR',
                    'zip' => '97304'
                },
                'claims_processor' => {
                    'clinic_trading_partner_id' => '999999999',
                    'code' => '931211733',
                    'dialup_number' => undef,
                    'interchange_id' => '931211733',
                    'interchange_id_qualifier' => 'ZZ',
                    'name' => 'PHTECH',
                    'password' => undef,
                    'password_active_days' => undef,
                    'password_expires' => '2006-06-30',
                    'password_min_char' => undef,
                    'primary_id' => '931211733',
                    'rec_id' => '1002',
                    'sftp_host' => 'sftp.phtech.com',
                    'get_directory' => undef,
                    'put_directory' => undef,
                    'sftp_port' => '22',
                    'template_837' => 'write_837',
                    'username' => 'username'
                },
            },
            'billing_provider' => {
                'address1' => '123 4th Street',
                'address2' => undef,
                'city' => 'Portland',
                'employer_id' => '123456789',
                'medicaid_provider_number' => undef,
                'medicare_provider_number' => undef,
                'name' => 'Our Clinic',
                'national_provider_id' => '1234567890',
                'state' => 'OR',
                'taxonomy_code' => '101Y00000X',
                'zip' => '97215'
            },
            'payer' => $tmp->{'billing_file'}{'payer'},
            'receiver' => {
                'code' => '931211733',
                'padded_interchange_id' => '931211733      ',
                'interchange_id_qualifier' => 'ZZ',
                'name' => 'PHTECH',
                'primary_id' => '931211733'
            },
            'sender' => {
                'code' => '999999999',
                'padded_interchange_id' => '999999999      ',
                'interchange_id_qualifier' => 'ZZ'
            },
            'submitter' => {
                'contact_extension' => '123',
                'contact_method' => 'TE',
                'contact_name' => 'Site Admin',
                'contact_number' => '5035557777',
                'name' => 'Our Clinic'
            },
            'subscribers' => [ {
                'dob' => '19240927',
                'fname' => 'Bud',
                'gender' => 'M',
                'group_name' => 'pianists',
                'group_number' => undef,
                'insurance_id' => 'white keys',
                'lname' => 'Powell',
                'mname' => undef,
                'name_suffix' => undef,
                'plan_rank' => 'S',
                'state' => 'NY',
                'zip' => '10271',
                'address1' => '123 Downuptown St',
                'address2' => undef,
                'city' => 'New York',
                'claim_filing_indicator_code' => 'MC',
                'dependents' => [ {
                    'dob' => '19171010',
                    'fname' => 'Thelonious',
                    'gender' => 'M',
                    'insurance_id' => undef,
                    'lname' => 'Monk',
                    'mname' => undef,
                    'name_suffix' => undef,
                    'relation_to_subscriber' => 'G8',
                    'state' => 'NY',
                    'zip' => '10016',
                    'address1' => '116 E 27th St',
                    'address2' => undef,
                    'city' => 'New York',
                    'claims' => [ {
                        'submitter_id' => '1004',
                        'total_amount' => '124.64',
                        'diagnosis_codes' => [ '29660' ],
                        'facility_code' => '11',
                        'other_insurances' => [ {
                            'claim_filing_indicator_code' => 'MB',
                            'group_name' => 'Baroness',
                            'group_number' => undef,
                            'id' => '00835',
                            'insurance_type' => 'MB',
                            'name' => 'MEDICARE B OF OREGON',
                            'patient_insurance_id' => undef,
                            'patient_relation_to_subscriber' => '23',
                            'plan_rank' => 'P',
                            'service_lines' => [ {
                                'modifiers' => [ 'HK' ],
                                'paid_amount' => '7.48',
                                'paid_service' => '90862',
                                'paid_units' => '2',
                                'prognote_id' => '1043',
                                'adjudication_date' => '20060902',
                                'deduction_groups' => [ {
                                    'group_code' => 'CO',
                                    'deductions' => [ {
                                        'amount' => '75.00',
                                        'group_code' => 'CO',
                                        'reason_code' => 'A2',
                                        'rec_id' => '1001',
                                        'transaction_id' => '1001',
                                        'units' => undef
                                    }, ],
                                },
                                {
                                    'group_code' => 'PR',
                                    'deductions' => [ {
                                        'amount' => '42.16',
                                        'group_code' => 'PR',
                                        'reason_code' => 'A2',
                                        'rec_id' => '1002',
                                        'transaction_id' => '1001',
                                        'units' => '1'
                                    }, ],
                                } ],
                            } ],
                            'subscriber' => {
                                'address1' => '10 Rue Flavel',
                                'address2' => 'Suite 6',
                                'city' => 'Paris',
                                'dob' => '19131210',
                                'fname' => 'Nica',
                                'gender' => 'F',
                                'insurance_id' => '0141',
                                'lname' => 'de Koenigswarter',
                                'mname' => undef,
                                'name_suffix' => undef,
                                'state' => 'NY',
                                'zip' => '10044'
                            }
                        } ],
                        'patient_paid_amount' => undef,
                        'provider_sig_onfile' => 'Y',
                        'referring_provider' => undef,
                        'rendering_provider' => {
                            'fname' => 'Betty',
                            'lname' => 'Clinician',
                            'medicaid_provider_number' => undef,
                            'medicare_provider_number' => undef,
                            'mname' => undef,
                            'name_suffix' => undef,
                            'national_provider_id' => undef,
                            'taxonomy_code' => undef
                        },
                        'service_lines' => [ {
                            'charge_amount' => '124.64',
                            'service_date' => '20060703',
                            'diagnosis_code_pointers' => [ '1' ],
                            'facility_code' => '11',
                            'modifiers' => [ 'HK' ],
                            'prognote_id' => '1043',
                            'service' => '90862',
                            'units' => '2'
                        } ],
                    } ],
                } ],
            } ],
        }; # }}}

    is_deeply( $one->validate( $good ), $good );

        # data with each field going over the max length by one
        # (data that is not used (and therefore not validated) is left alone)
        my $over = {  # {{{
            'date' => '000050X',
            'date_long' => '00005000X',
            'time' => '0000X',
            'billing_file' => {
                'billing_cycle_id' => '1002',
                'edi' => undef,
                'group_control_number' => '000050000X',
                'is_production' => '0',
                'purpose' => '00X',
                'rec_id' => '1003',
                'rolodex_id' => '1014',
                'set_control_number' => '1',
                'submission_date' => undef,
                'type' => '00X',
                'payer' => {
                    'address' => '0000500005000050000500005000050000500005000050000500005X',
                    'address2' => '0000500005000050000500005000050000500005000050000500005X',
                    'city' => '000050000500005000050000500005X',
                    'claims_processor_id' => '1002',
                    'edi_indicator_code' => 'MC',
                    'id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X',
                    'name' => '00005000050000500005000050000500005X',
                    'state' => '00X',
                    'zip' => '000050000500005X'
                },
                'claims_processor' => {
                    'clinic_trading_partner_id' => '999999999',
                    'code' => '931211733',
                    'dialup_number' => undef,
                    'interchange_id' => '931211733',
                    'interchange_id_qualifier' => 'ZZ',
                    'name' => 'PHTECH',
                    'password' => undef,
                    'password_active_days' => undef,
                    'password_expires' => '2006-06-30',
                    'password_min_char' => undef,
                    'primary_id' => '931211733',
                    'rec_id' => '1002',
                    'sftp_host' => 'sftp.phtech.com',
                    'sftp_port' => '22',
                    'get_directory' => undef,
                    'put_directory' => undef,
                    'template_837' => 'write_837',
                    'username' => 'username'
                },
            },
            'billing_provider' => {
                'address1' => '0000500005000050000500005000050000500005000050000500005X',
                'address2' => '0000500005000050000500005000050000500005000050000500005X',
                'city' => '000050000500005000050000500005X',
                'employer_id' => '000050000500005000050000500005X',
                'medicaid_provider_number' => '000050000500005000050000500005X',
                'medicare_provider_number' => '000050000500005000050000500005X',
                'name' => '00005000050000500005000050000500005X',
                'national_provider_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X',
                'state' => '00X',
                'taxonomy_code' => '000050000500005000050000500005X',
                'zip' => '000050000500005X'
            },
            'payer' => $tmp->{'billing_file'}{'payer'},
            'receiver' => {
                'code' => '000050000500005X',
                'padded_interchange_id' => '000050000500005X',
                'interchange_id_qualifier' => '00X',
                'name' => '00005000050000500005000050000500005X',
                'primary_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X'
            },
            'sender' => {
                'code' => '000050000500005X',
                'padded_interchange_id' => '000050000500005X',
                'interchange_id_qualifier' => '00X'
            },
            'submitter' => {
                'contact_extension' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X',
                'contact_method' => '00X',
                'contact_name' => '000050000500005000050000500005000050000500005000050000500005X',
                'contact_number' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X',
                'name' => '00005000050000500005000050000500005X'
            },
            'subscribers' => [ {
                'dob' => '00005000050000500005000050000500005X',
                'fname' => '0000500005000050000500005X',
                'gender' => '0X',
                'group_name' => '000050000500005000050000500005000050000500005000050000500005X',
                'group_number' => '000050000500005000050000500005X',
                'insurance_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X',
                'lname' => '00005000050000500005000050000500005X',
                'mname' => '0000500005000050000500005X',
                'name_suffix' => '0000500005X',
                'plan_rank' => '0X',
                'state' => '00X',
                'zip' => '000050000500005X',
                'address1' => '0000500005000050000500005000050000500005000050000500005X',
                'address2' => '0000500005000050000500005000050000500005000050000500005X',
                'city' => '000050000500005000050000500005X',
                'claim_filing_indicator_code' => '00X',
                'dependents' => [ {
                    'dob' => '00005000050000500005000050000500005X',
                    'fname' => '0000500005000050000500005X',
                    'gender' => '0X',
                    'insurance_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X',
                    'lname' => '00005000050000500005000050000500005X',
                    'mname' => '0000500005000050000500005X',
                    'name_suffix' => '0000500005X',
                    'relation_to_subscriber' => '00X',
                    'state' => '00X',
                    'zip' => '000050000500005X',
                    'address1' => '0000500005000050000500005000050000500005000050000500005X',
                    'address2' => '0000500005000050000500005000050000500005000050000500005X',
                    'city' => '000050000500005000050000500005X',
                    'claims' => [ {
                        'submitter_id' => '00005000050000500005000050000500005000X',
                        'total_amount' => '000050000500005000X',
                        'diagnosis_codes' => [ '000050000500005000050000500005X' ],
                        'facility_code' => '00X',
                        'other_insurances' => [ {
                            'claim_filing_indicator_code' => '00X',
                            'group_name' => '000050000500005000050000500005000050000500005000050000500005X',
                            'group_number' => '000050000500005000050000500005X',
                            'id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X',
                            'insurance_type' => '000X',
                            'name' => '00005000050000500005000050000500005X',
                            'patient_insurance_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X',
                            'patient_relation_to_subscriber' => '00X',
                            'plan_rank' => '0X',
                            'service_lines' => [ {
                                'modifiers' => [ '00X' ],
                                'paid_amount' => '000050000500005000X',
                                'paid_service' => '000050000500005000050000500005000050000500005000X',
                                'paid_units' => '000050000500005X',
                                'prognote_id' => '1043',
                                'adjudication_date' => '00005000050000500005000050000500005X',
                                'deduction_groups' => [ {
                                    'group_code' => '00X',
                                    'deductions' => [ {
                                        'amount' => '000050000500005000X',
                                        'group_code' => 'CO',
                                        'reason_code' => '00005X',
                                        'rec_id' => '1001',
                                        'transaction_id' => '1001',
                                        'units' => '000050000500005X'
                                    }, ],
                                },
                                {
                                    'group_code' => '00X',
                                    'deductions' => [ {
                                        'amount' => '000050000500005000X',
                                        'group_code' => 'PR',
                                        'reason_code' => '00005X',
                                        'rec_id' => '1002',
                                        'transaction_id' => '1001',
                                        'units' => '000050000500005X'
                                    }, ],
                                } ],
                            } ],
                            'subscriber' => {
                                'address1' => '0000500005000050000500005000050000500005000050000500005X',
                                'address2' => '0000500005000050000500005000050000500005000050000500005X',
                                'city' => '000050000500005000050000500005X',
                                'dob' => '00005000050000500005000050000500005X',
                                'fname' => '0000500005000050000500005X',
                                'gender' => '0X',
                                'insurance_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X',
                                'lname' => '00005000050000500005000050000500005X',
                                'mname' => '0000500005000050000500005X',
                                'name_suffix' => '0000500005X',
                                'state' => '00X',
                                'zip' => '000050000500005X'
                            }
                        } ],
                        'patient_paid_amount' => '000050000500005000X',
                        'provider_sig_onfile' => '0X',
                        'referring_provider' => {
                            'fname' => '0000500005000050000500005X',
                            'lname' => '00005000050000500005000050000500005X',
                            'medicaid_provider_number' => '000050000500005000050000500005X',
                            'medicare_provider_number' => '000050000500005000050000500005X',
                            'mname' => '0000500005000050000500005X',
                            'name_suffix' => '0000500005X',
                            'ssn' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X'
                        },
                        'rendering_provider' => {
                            'fname' => '0000500005000050000500005X',
                            'lname' => '00005000050000500005000050000500005X',
                            'medicaid_provider_number' => '000050000500005000050000500005X',
                            'medicare_provider_number' => '000050000500005000050000500005X',
                            'mname' => '0000500005000050000500005X',
                            'name_suffix' => '0000500005X',
                            'national_provider_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005X',
                            'taxonomy_code' => '000050000500005000050000500005X'
                        },
                        'service_lines' => [ {
                            'charge_amount' => '000050000500005000X',
                            'service_date' => '00005000050000500005000050000500005X',
                            'diagnosis_code_pointers' => [ '00X' ],
                            'facility_code' => '00X',
                            'modifiers' => [ '00X' ],
                            'prognote_id' => '000050000500005000050000500005X',
                            'service' => '000050000500005000050000500005000050000500005000X',
                            'units' => '000050000500005X'
                        } ],
                    } ],
                } ],
            } ],
        }; # }}}

        my $truncated = {  # {{{
            'date' => '000050',
            'date_long' => '00005000',
            'time' => '0000',
            'billing_file' => {
                'billing_cycle_id' => '1002',
                'edi' => undef,
                'group_control_number' => '000050000',
                'is_production' => '0',
                'purpose' => '00',
                'rec_id' => '1003',
                'rolodex_id' => '1014',
                'set_control_number' => '1',
                'submission_date' => undef,
                'type' => '00',
                'payer' => {
                    'address' => '0000500005000050000500005000050000500005000050000500005',
                    'address2' => '0000500005000050000500005000050000500005000050000500005',
                    'city' => '000050000500005000050000500005',
                    'claims_processor_id' => '1002',
                    'edi_indicator_code' => 'MC',
                    'id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005',
                    'name' => '00005000050000500005000050000500005',
                    'state' => '00',
                    'zip' => '000050000500005'
                },
                'claims_processor' => {
                    'clinic_trading_partner_id' => '999999999',
                    'code' => '931211733',
                    'dialup_number' => undef,
                    'interchange_id' => '931211733',
                    'interchange_id_qualifier' => 'ZZ',
                    'name' => 'PHTECH',
                    'password' => undef,
                    'password_active_days' => undef,
                    'password_expires' => '2006-06-30',
                    'password_min_char' => undef,
                    'primary_id' => '931211733',
                    'rec_id' => '1002',
                    'sftp_host' => 'sftp.phtech.com',
                    'sftp_port' => '22',
                    'get_directory' => undef,
                    'put_directory' => undef,
                    'template_837' => 'write_837',
                    'username' => 'username'
                },
            },
            'billing_provider' => {
                'address1' => '0000500005000050000500005000050000500005000050000500005',
                'address2' => '0000500005000050000500005000050000500005000050000500005',
                'city' => '000050000500005000050000500005',
                'employer_id' => '000050000500005000050000500005',
                'medicaid_provider_number' => '000050000500005000050000500005',
                'medicare_provider_number' => '000050000500005000050000500005',
                'name' => '00005000050000500005000050000500005',
                'national_provider_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005',
                'state' => '00',
                'taxonomy_code' => '000050000500005000050000500005',
                'zip' => '000050000500005'
            },
            'payer' => $tmp->{'billing_file'}{'payer'},
            'receiver' => {
                'code' => '000050000500005',
                'padded_interchange_id' => '000050000500005',
                'interchange_id_qualifier' => '00',
                'name' => '00005000050000500005000050000500005',
                'primary_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005'
            },
            'sender' => {
                'code' => '000050000500005',
                'padded_interchange_id' => '000050000500005',
                'interchange_id_qualifier' => '00'
            },
            'submitter' => {
                'contact_extension' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005',
                'contact_method' => '00',
                'contact_name' => '000050000500005000050000500005000050000500005000050000500005',
                'contact_number' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005',
                'name' => '00005000050000500005000050000500005'
            },
            'subscribers' => [ {
                'dob' => '00005000050000500005000050000500005',
                'fname' => '0000500005000050000500005',
                'gender' => '0',
                'group_name' => '000050000500005000050000500005000050000500005000050000500005',
                'group_number' => '000050000500005000050000500005',
                'insurance_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005',
                'lname' => '00005000050000500005000050000500005',
                'mname' => '0000500005000050000500005',
                'name_suffix' => '0000500005',
                'plan_rank' => '0',
                'state' => '00',
                'zip' => '000050000500005',
                'address1' => '0000500005000050000500005000050000500005000050000500005',
                'address2' => '0000500005000050000500005000050000500005000050000500005',
                'city' => '000050000500005000050000500005',
                'claim_filing_indicator_code' => '00',
                'dependents' => [ {
                    'dob' => '00005000050000500005000050000500005',
                    'fname' => '0000500005000050000500005',
                    'gender' => '0',
                    'insurance_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005',
                    'lname' => '00005000050000500005000050000500005',
                    'mname' => '0000500005000050000500005',
                    'name_suffix' => '0000500005',
                    'relation_to_subscriber' => '00',
                    'state' => '00',
                    'zip' => '000050000500005',
                    'address1' => '0000500005000050000500005000050000500005000050000500005',
                    'address2' => '0000500005000050000500005000050000500005000050000500005',
                    'city' => '000050000500005000050000500005',
                    'claims' => [ {
                        'submitter_id' => '00005000050000500005000050000500005000',
                        'total_amount' => '000050000500005000',
                        'diagnosis_codes' => [ '000050000500005000050000500005' ],
                        'facility_code' => '00',
                        'other_insurances' => [ {
                            'claim_filing_indicator_code' => '00',
                            'group_name' => '000050000500005000050000500005000050000500005000050000500005',
                            'group_number' => '000050000500005000050000500005',
                            'id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005',
                            'insurance_type' => '000',
                            'name' => '00005000050000500005000050000500005',
                            'patient_insurance_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005',
                            'patient_relation_to_subscriber' => '00',
                            'plan_rank' => '0',
                            'service_lines' => [ {
                                'modifiers' => [ '00' ],
                                'paid_amount' => '000050000500005000',
                                'paid_service' => '000050000500005000050000500005000050000500005000',
                                'paid_units' => '000050000500005',
                                'prognote_id' => '1043',
                                'adjudication_date' => '00005000050000500005000050000500005',
                                'deduction_groups' => [ {
                                    'group_code' => '00',
                                    'deductions' => [ {
                                        'amount' => '000050000500005000',
                                        'group_code' => 'CO',
                                        'reason_code' => '00005',
                                        'rec_id' => '1001',
                                        'transaction_id' => '1001',
                                        'units' => '000050000500005'
                                    }, ],
                                },
                                {
                                    'group_code' => '00',
                                    'deductions' => [ {
                                        'amount' => '000050000500005000',
                                        'group_code' => 'PR',
                                        'reason_code' => '00005',
                                        'rec_id' => '1002',
                                        'transaction_id' => '1001',
                                        'units' => '000050000500005'
                                    }, ],
                                } ],
                            } ],
                            'subscriber' => {
                                'address1' => '0000500005000050000500005000050000500005000050000500005',
                                'address2' => '0000500005000050000500005000050000500005000050000500005',
                                'city' => '000050000500005000050000500005',
                                'dob' => '00005000050000500005000050000500005',
                                'fname' => '0000500005000050000500005',
                                'gender' => '0',
                                'insurance_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005',
                                'lname' => '00005000050000500005000050000500005',
                                'mname' => '0000500005000050000500005',
                                'name_suffix' => '0000500005',
                                'state' => '00',
                                'zip' => '000050000500005'
                            }
                        } ],
                        'patient_paid_amount' => '000050000500005000',
                        'provider_sig_onfile' => '0',
                        'referring_provider' => {
                            'fname' => '0000500005000050000500005',
                            'lname' => '00005000050000500005000050000500005',
                            'medicaid_provider_number' => '000050000500005000050000500005',
                            'medicare_provider_number' => '000050000500005000050000500005',
                            'mname' => '0000500005000050000500005',
                            'name_suffix' => '0000500005',
                            'ssn' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005'
                        },
                        'rendering_provider' => {
                            'fname' => '0000500005000050000500005',
                            'lname' => '00005000050000500005000050000500005',
                            'medicaid_provider_number' => '000050000500005000050000500005',
                            'medicare_provider_number' => '000050000500005000050000500005',
                            'mname' => '0000500005000050000500005',
                            'name_suffix' => '0000500005',
                            'national_provider_id' => '00005000050000500005000050000500005000050000500005000050000500005000050000500005',
                            'taxonomy_code' => '000050000500005000050000500005'
                        },
                        'service_lines' => [ {
                            'charge_amount' => '000050000500005000',
                            'service_date' => '00005000050000500005000050000500005',
                            'diagnosis_code_pointers' => [ '00' ],
                            'facility_code' => '00',
                            'modifiers' => [ '00' ],
                            'prognote_id' => '000050000500005000050000500005',
                            'service' => '000050000500005000050000500005000050000500005000',
                            'units' => '000050000500005'
                        } ],
                    } ],
                } ],
            } ],
        }; # }}}

    is_deeply( $one->validate( $over ), $truncated );
        # XXX Add test against the deferred log

        # data with each field under the min by one, for those fields that require 2 or more chars
        my $under = { # {{{
            'date' => '00005',
            'date_long' => '0000500',
            'time' => '000',
            'billing_file' => {
                'billing_cycle_id' => '1002',
                'edi' => undef,
                'group_control_number' => '1',
                'is_production' => '0',
                'purpose' => '0',
                'rec_id' => '1003',
                'rolodex_id' => '1014',
                'set_control_number' => '1',
                'submission_date' => undef,
                'type' => '0',
                'payer' => {
                    'address' => 'P.O. Box 5490',
                    'address2' => undef,
                    'city' => '0',
                    'claims_processor_id' => '1002',
                    'edi_indicator_code' => 'MC',
                    'id' => '0',
                    'name' => 'WCHHS',
                    'state' => '0',
                    'zip' => '00'
                },
                'claims_processor' => {
                    'clinic_trading_partner_id' => '999999999',
                    'code' => '931211733',
                    'dialup_number' => undef,
                    'interchange_id' => '931211733',
                    'interchange_id_qualifier' => 'ZZ',
                    'name' => 'PHTECH',
                    'password' => undef,
                    'password_active_days' => undef,
                    'password_expires' => '2006-06-30',
                    'password_min_char' => undef,
                    'primary_id' => '931211733',
                    'rec_id' => '1002',
                    'sftp_host' => 'sftp.phtech.com',
                    'sftp_port' => '22',
                    'get_directory' => undef,
                    'put_directory' => undef,
                    'template_837' => 'write_837',
                    'username' => 'username'
                },
            },
            'billing_provider' => {
                'address1' => '123 4th Street',
                'address2' => undef,
                'city' => '0',
                'employer_id' => '123456789',
                'medicaid_provider_number' => undef,
                'medicare_provider_number' => undef,
                'name' => 'Our Clinic',
                'national_provider_id' => '0',
                'state' => '0',
                'taxonomy_code' => '101Y00000X',
                'zip' => '00'
            },
            'payer' => $tmp->{'billing_file'}{'payer'},
            'receiver' => {
                'code' => '0',
                'padded_interchange_id' => '00005000050000',
                'interchange_id_qualifier' => '0',
                'name' => 'PHTECH',
                'primary_id' => '0'
            },
            'sender' => {
                'code' => '0',
                'padded_interchange_id' => '00005000050000',
                'interchange_id_qualifier' => '0'
            },
            'submitter' => {
                'contact_extension' => '123',
                'contact_method' => '0',
                'contact_name' => 'Site Admin',
                'contact_number' => '5035557777',
                'name' => 'Our Clinic'
            },
            'subscribers' => [ {
                'dob' => '19240927',
                'fname' => 'Bud',
                'gender' => 'M',
                'group_name' => 'pianists',
                'group_number' => undef,
                'insurance_id' => '0',
                'lname' => 'Powell',
                'mname' => undef,
                'name_suffix' => undef,
                'plan_rank' => 'S',
                'state' => '0',
                'zip' => '001',
                'address1' => '123 Downuptown St',
                'address2' => undef,
                'city' => '0',
                'claim_filing_indicator_code' => 'MC',
                'dependents' => [ {
                    'dob' => '19171010',
                    'fname' => 'Thelonious',
                    'gender' => 'M',
                    'insurance_id' => '0',
                    'lname' => 'Monk',
                    'mname' => undef,
                    'name_suffix' => undef,
                    'relation_to_subscriber' => '0',
                    'state' => '0',
                    'zip' => '00',
                    'address1' => '116 E 27th St',
                    'address2' => undef,
                    'city' => '0',
                    'claims' => [ {
                        'submitter_id' => '1004',
                        'total_amount' => '124.64',
                        'diagnosis_codes' => [ '29660' ],
                        'facility_code' => '11',
                        'other_insurances' => [ {
                            'claim_filing_indicator_code' => 'MB',
                            'group_name' => 'Baroness',
                            'group_number' => undef,
                            'id' => '0',
                            'insurance_type' => 'MB',
                            'name' => 'MEDICARE B OF OREGON',
                            'patient_insurance_id' => '0',
                            'patient_relation_to_subscriber' => '0',
                            'plan_rank' => 'P',
                            'service_lines' => [ {
                                'modifiers' => [ '0' ],
                                'paid_amount' => '7.48',
                                'paid_service' => '90862',
                                'paid_units' => '2',
                                'prognote_id' => '1043',
                                'adjudication_date' => '20060902',
                                'deduction_groups' => [ {
                                    'group_code' => 'CO',
                                    'deductions' => [ {
                                        'amount' => '75.00',
                                        'group_code' => 'CO',
                                        'reason_code' => 'A2',
                                        'rec_id' => '1001',
                                        'transaction_id' => '1001',
                                        'units' => undef
                                    }, ],
                                },
                                {
                                    'group_code' => 'PR',
                                    'deductions' => [ {
                                        'amount' => '42.16',
                                        'group_code' => 'PR',
                                        'reason_code' => 'A2',
                                        'rec_id' => '1002',
                                        'transaction_id' => '1001',
                                        'units' => '1'
                                    }, ],
                                } ],
                            } ],
                            'subscriber' => {
                                'address1' => '10 Rue Flavel',
                                'address2' => 'Suite 6',
                                'city' => '0',
                                'dob' => '19131210',
                                'fname' => 'Nica',
                                'gender' => 'F',
                                'insurance_id' => '0',
                                'lname' => 'de Koenigswarter',
                                'mname' => undef,
                                'name_suffix' => undef,
                                'state' => '0',
                                'zip' => '00'
                            }
                        } ],
                        'patient_paid_amount' => undef,
                        'provider_sig_onfile' => 'Y',
                        'referring_provider' => {
                            'fname' => 'Test',
                            'lname' => 'Provider',
                            'medicaid_provider_number' => undef,
                            'medicare_provider_number' => undef,
                            'mname' => 'Referring',
                            'name_suffix' => undef,
                            'ssn' => '0'
                        },
                        'rendering_provider' => {
                            'fname' => 'Betty',
                            'lname' => 'Clinician',
                            'medicaid_provider_number' => undef,
                            'medicare_provider_number' => undef,
                            'mname' => undef,
                            'name_suffix' => undef,
                            'national_provider_id' => '0',
                            'taxonomy_code' => undef
                        },
                        'service_lines' => [ {
                            'charge_amount' => '124.64',
                            'service_date' => '20060703',
                            'diagnosis_code_pointers' => [ '1' ],
                            'facility_code' => '11',
                            'modifiers' => [ '0' ],
                            'prognote_id' => '1043',
                            'service' => '90862',
                            'units' => '2'
                        } ],
                    } ],
                } ],
            } ],
        }; # }}}

    is_deeply( $one->validate( $under ), $under );
        
        # good data with one field that's under its minimum
        $good->{ time } = '000';
        $eleMentalClinic::Base::TESTMODE = 0;
    throws_ok { $one->validate( $good ) } qr/time length must be at least 4 characters long./;
        $eleMentalClinic::Base::TESTMODE = 1;

    # TODO test required fields

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# generate edi data

        $one = $CLASS->new( {
            billing_file => $billing_file,
            date_stamp => $DATE_STAMP,
            time_stamp => $TIME_STAMP,
        });
    can_ok( $one, 'generate' );
        my $edi_data = $one->generate;   
        my @lines = split( /~/ => $edi_data );

    # compare with golden data
    ok( my( $samplelines, undef ) = $test->split_file( 't/resource/sample_837.1.txt' ) );
    is_deeply( \@lines, $samplelines );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test setting the BillingFile.is_production flag

        $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $BILLING_FILE_REC_ID );
    is( $billing_file->is_production, 0 );
        $billing_file->is_production( 1 )->save;
    is( $billing_file->is_production, 1 );

        $one = $CLASS->new( {
            billing_file => $billing_file,
            date_stamp => $DATE_STAMP,
            time_stamp => $TIME_STAMP,
        });
        $edi_data = $one->generate;   
        @lines = split( /~/ => $edi_data );

        # The Production flag should show up instead of Test
        $samplelines->[0] =~ s/\*T\*:/\*P\*:/;
    is_deeply( \@lines, $samplelines );
       
        # Reset everything
        $billing_file->is_production( 0 )->save;
        $one = $CLASS->new( {
            billing_file => $billing_file,
            date_stamp => $DATE_STAMP,
            time_stamp => $TIME_STAMP,
        });
        $edi_data = $one->generate;   
        @lines = split( /~/ => $edi_data );
        $samplelines->[0] =~ s/\*P\*:/\*T\*:/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write file

    ok( -d $one->output_root, $one->output_root.' directory exists' );

        my $test_file_path = $one->output_root."/".$one->make_filename;
#    print Dumper $test_file_path;
        unlink $test_file_path;

        $one->write;
    ok( -f $test_file_path, 'Test file exists after write().' );

        my ( undef, $test_file_edi_data ) = $test->split_file( $test_file_path );
    is( $edi_data, $test_file_edi_data );    

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Finish the first billing cycle, process first payment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_cycle->write_837( 1002 );
        $billing_file->save_as_billed( '2006-06-29 16:04:25' );

        my $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.1.txt', '2006-09-05' ) );
        
        $billing_cycle->validation_set->finish;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Second billing cycle, secondary payers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $test->financial_setup( 2 );

        my $second_test_file_edi_data;
        ( $samplelines, $second_test_file_edi_data ) = $test->split_file( 't/resource/sample_837.2.txt' );

        $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( 1003 );
        $one = $CLASS->new( {
            billing_file => $billing_file,
            date_stamp => $DATE_STAMP,
            time_stamp => $TIME_STAMP,
        });
        
        my $second_edi_data = $one->generate;   
        @lines = split( /~/ => $second_edi_data );

    is_deeply( \@lines, $samplelines );

    $second_test_file_edi_data =~ s/\n/~/g;
    is( $second_edi_data, $second_test_file_edi_data );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test an 837 with a payer that has send_personnel_id turned on 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit(1);

    is( eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1002 )->send_personnel_id, 0 );
        eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1002 )->send_personnel_id( 1 )->save;
    is( eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1002 )->send_personnel_id, 1 );
    is( eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1002 )->requires_rendering_provider_ids, 0 );
        eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1002 )->requires_rendering_provider_ids( 1 )->save;
    is( eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1002 )->requires_rendering_provider_ids, 1 );

        $test->financial_setup( 1 );
        $test->financial_setup( 2 );

        ( $samplelines, $second_test_file_edi_data ) = $test->split_file( 't/resource/sample_837.2.personnel.txt' );

        $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( 1003 );
        $one = $CLASS->new( {
            billing_file => $billing_file,
            date_stamp => $DATE_STAMP,
            time_stamp => $TIME_STAMP,
        });
        $second_edi_data = $one->generate;   
        @lines = split( /~/ => $second_edi_data );

    is_deeply( \@lines, $samplelines );

    $second_test_file_edi_data =~ s/\n/~/g;
    is( $second_edi_data, $second_test_file_edi_data );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_date_f
    can_ok( $one, 'get_date_f' );
    is( $CLASS->get_date_f, undef );

    is( $CLASS->get_date_f( '2006-08-28' ), '20060828' );
    is( $CLASS->get_date_f( '2006-8-28' ), '20060828' );
    is( $CLASS->get_date_f( '2006-08' ), undef );
    is( $CLASS->get_date_f( '06-08-28' ), undef );
    is( $CLASS->get_date_f( '20060828' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
