# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 159;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Financial::BillingClaim';
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
    is( $one->table, 'billing_claim');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id billing_file_id staff_id client_id
        client_insurance_id insurance_rank
        client_insurance_authorization_id
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diagnosis_code_f
    can_ok( $one, 'diagnosis_code_f' );

    is( $one->diagnosis_code_f, undef );

    is( $one->diagnosis_code_f( '292.89 Other/Unknown Substance Intoxication' ), '29289' );
    is( $one->diagnosis_code_f( '296.60 Bipolar I Disorder Most Recent Episode Mixed Unspecified' ), '29660' );
    is( $one->diagnosis_code_f( '292.00 Nicotine Withdrawal' ), '29200' );
    is( $one->diagnosis_code_f( '000.00 No Data Available' ), undef );
    is( $one->diagnosis_code_f( 'Bipolar disorder, mixed type in partial remission' ), undef );

    is( $one->diagnosis_code_f( '292.89 Other/Unknown Substance Intoxication', 'hcfa' ), '292 89' );
    is( $one->diagnosis_code_f( '296.60 Bipolar I Disorder Most Recent Episode Mixed Unspecified', 'hcfa' ), '296 60' );
    is( $one->diagnosis_code_f( '292.00 Nicotine Withdrawal', 'hcfa' ), '292 00' );
    is( $one->diagnosis_code_f( '000.00 No Data Available', 'hcfa' ), undef );
    is( $one->diagnosis_code_f( 'Bipolar disorder, mixed type in partial remission', 'hcfa' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_insurance_subscriber
    can_ok( $one, 'get_other_insurance_subscriber' );
    
    is( $one->get_other_insurance_subscriber, undef );

        # insured is different from the client
        my $client_insurance = eleMentalClinic::Client::Insurance->retrieve( 1003 );
    is_deeply( $one->get_other_insurance_subscriber( $client_insurance ), {
        dob             => '19131210',
        gender          => 'F',
        lname           => 'de Koenigswarter',
        fname           => 'Nica',
        mname           => undef,
        name_suffix     => undef,
        address1        => '10 Rue Flavel',
        address2        => 'Suite 6',
        city            => 'Paris',
        state           => 'NY',
        zip             => '10044',
        insurance_id    => '0141',
    });

        # insured is the client
        $client_insurance = eleMentalClinic::Client::Insurance->retrieve( 1002 );
    is_deeply( $one->get_other_insurance_subscriber( $client_insurance ), {
        dob             => '19171010',
        gender          => 'M',
        lname           => 'Monk',
        fname           => 'Thelonious',
        mname           => undef,
        name_suffix     => undef,
        address1        => '116 E 27th St',
        address2        => undef,
        city            => 'New York',
        state           => 'NY',
        zip             => '10016',
        insurance_id    => '7',
    });

        # another one since I'd already written it for somethinge else, don't really need it
        $client_insurance = eleMentalClinic::Client::Insurance->retrieve( 1004 );
    is_deeply( $one->get_other_insurance_subscriber( $client_insurance ), {
        dob             => '19240927',
        gender          => 'M',
        lname           => 'Powell',
        fname           => 'Bud',
        mname           => undef,
        name_suffix     => undef,
        address1        => '123 Downuptown St',
        address2        => undef,
        city            => 'New York',
        state           => 'NY',
        zip             => '10271',
        insurance_id    => 'white keys',
    });

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_subscriber_insurance_data
    can_ok( $CLASS, 'get_subscriber_insurance_data' );
    throws_ok{ $CLASS->get_subscriber_insurance_data } qr/required/;

        my $insurance = eleMentalClinic::Client::Insurance->retrieve( 1002 );
    is_deeply( $CLASS->get_subscriber_insurance_data( $insurance ), {
        fname       => 'Buddy',
        lname       => 'Rich',
        mname       => undef,
        name_suffix => undef,
        address1    => '123 Anystreet',
        address2    => undef,
        city        => 'San Bernadino',
        state       => 'CA',
        zip         => '95060',
        dob         => '19570227',
        gender      => 'M',
    });
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start the first billing cycle 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( my $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 ) );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# new_service
    can_ok( $one, 'new_service' );
        $one->empty;
    is( $one->new_service, undef, 'should not create new service for an empty claim' );
        $one->retrieve(1001);
    my $new_service = $one->new_service;
    isa_ok( $new_service, 'eleMentalClinic::Financial::BillingService', 'should create a billing service');
    my $test_service = eleMentalClinic::Financial::BillingService->retrieve($new_service->id);
    is_deeply( $new_service, $test_service );

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# See note for add_services in BillingClaim.pm
## add_services
#    can_ok( $one, 'add_services' );
#    is( $one->add_services, undef ); 
#    is( $one->add_services([]), undef, 'array of prognotes must contain prognotes.');
#    my $p1 = eleMentalClinic::ProgressNote->retrieve(1065);
#    my $p2 = eleMentalClinic::ProgressNote->retrieve(1066);
#        $one = $CLASS->new;
#    is( $one->add_services([$p1]), undef, 'BillingClaim must exist.');
#        $one->retrieve(1001);
#    ok( $one->add_services([$p1, $p2]) );
#    is_deeply($one->billing_services, []); 

        $one = $CLASS->new;

dbinit(1);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# re-start the first billing cycle 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 ) );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_client_insurance_data
    can_ok( $one, 'get_client_insurance_data' );
    is( $one->get_client_insurance_data, undef );

        $one->retrieve( 1002 );
    is_deeply( $one->get_client_insurance_data, {
        fname       => 'Thelonious',
        lname       => 'Monk',
        mname       => undef,
        name_suffix => undef,
        address1    => '116 E 27th St',
        address2    => undef,
        city        => 'New York',
        state       => 'NY',
        zip         => '10016',
        dob         => '19171010',
        gender      => 'M',
    });

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_subscriber_data
    can_ok( $CLASS, 'get_subscriber_data' );
    throws_ok{ $CLASS->get_subscriber_data } qr/required/;

        my @billing_claims;
        push @billing_claims => $CLASS->retrieve( 1003 );
    is_deeply( $CLASS->get_subscriber_data( \@billing_claims ), {
        fname        => 'George',
        lname        => 'Gershwin',
        mname        => undef,
        name_suffix  => undef,
        address1     => '457 151 St Uptown',
        address2     => undef,
        city         => 'New York',
        state        => 'NY',
        zip          => '10165',
        dob          => '18980926',
        gender       => 'M',
        dependents                  => [{
            fname        => 'Ella',
            lname        => 'Fitzgerald',
            mname        => undef,
            name_suffix  => undef,
            address1     => '131 W 3rd St',
            address2     => undef,
            city         => 'New York',
            state        => 'NY',
            zip          => '10012',
            dob          => '19180425',
            gender       => 'F',
            relation_to_subscriber  => '34',
            insurance_id            => undef,
            claims                  => [{
                submitter_id        => 1003,
                total_amount        => "525.76",
                facility_code       => 12,
                provider_sig_onfile => 'Y',
                patient_paid_amount => undef,
                diagnosis_codes     => [ '29289' ],
                rendering_provider  => {
                    fname                       => 'Ima',
                    lname                       => 'Therapist',
                    mname                       => undef,
                    name_suffix                 => undef,
                    taxonomy_code               => '101Y00000X',
                    medicaid_provider_number    => '111111',
                    medicare_provider_number    => 'R111111',
                    rendering_provider_id       => '0987654321',
                    id_is_employer_id           => 0,
                },
                referring_provider  => undef,
                service_lines       => [
                {
                    billing_service_id      => 1009,
                    service                 => '90806',
                    modifiers               => undef,
                    units                   => 2,
                    charge_amount           => "131.44",
                    service_date            => '20060703',
                    diagnosis_code_pointers => [ '1', ],
                    facility_code           => 12,
                },
                {
                    billing_service_id      => 1010,
                    service                 => '90806',
                    modifiers               => undef,
                    units                   => 2,
                    charge_amount           => "131.44",
                    service_date            => '20060707',
                    diagnosis_code_pointers => [ '1', ],
                    facility_code           => 12,
                },
                {
                    billing_service_id      => 1011,
                    service                 => '90806',
                    modifiers               => undef,
                    units                   => 2,
                    charge_amount           => "131.44",
                    service_date            => '20060710',
                    diagnosis_code_pointers => [ '1', ],
                    facility_code           => 12,
                },
                {
                    billing_service_id      => 1012,
                    service                 => '90806',
                    modifiers               => undef,
                    units                   => 2,
                    charge_amount           => "131.44",
                    service_date            => '20060714',
                    diagnosis_code_pointers => [ '1', ],
                    facility_code           => 12,
                }],
                other_insurances    => undef,
            }]
        }],
        plan_rank                   => 'P',
        insurance_id                => '543210000A',
        group_number                => undef,
        group_name                  => 'triangle',
        claim_filing_indicator_code => 'MB',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rendering_provider
    can_ok( $one, 'rendering_provider' );

        $one = $CLASS->new;
    throws_ok{ $one->rendering_provider } qr/requires staff_id/;

        $one->staff_id( 1001 );
    throws_ok{ $one->rendering_provider } qr/requires staff_id and billing_file/;

        $one->billing_file_id( 1001 );
    throws_ok{ $one->rendering_provider } qr/requires a claims_processor/;

        $one->billing_file_id( 1002 );
    is_deeply( $one->rendering_provider, {
        fname                       => 'Ima',
        lname                       => 'Therapist',
        mname                       => undef,
        name_suffix                 => undef,
        taxonomy_code               => '101Y00000X',
        medicaid_provider_number    => '111111',
        medicare_provider_number    => 'R111111',
        rendering_provider_id       => '0987654321',
        id_is_employer_id           => 0,
    });

        $one->staff_id( 1004 );
    dies_ok { $one->rendering_provider };
    like( $@, qr/This claims processor requires information about each clinician \(rendering provider\)\. Personnel staff_id \[1004\] has no taxonomy_code\./ );

        $one->staff_id( 1003 );
    dies_ok { $one->rendering_provider };
    like( $@, qr/This claims processor requires information about each clinician \(rendering provider\)\. Personnel staff_id \[1003\] has no national_provider_id\./ );

    # test claims_processor.send_personnel_id
    is( $one->billing_file->claims_processor->send_personnel_id, 0 );
        $one->billing_file->claims_processor->send_personnel_id( 1 )->save;
    is( $one->billing_file->claims_processor->send_personnel_id, 1 );
    is( $one->billing_file->claims_processor->requires_rendering_provider_ids, 1 );

    is_deeply( $one->rendering_provider, {
        fname                       => 'Willy',
        lname                       => 'Writer',
        mname                       => undef,
        name_suffix                 => undef,
        taxonomy_code               => '101Y00000X',
        medicaid_provider_number    => undef,
        medicare_provider_number    => undef,
        rendering_provider_id       => 1003,
        id_is_employer_id           => 1,
    });

        $one->billing_file->claims_processor->send_personnel_id( 0 )->save;
    is( $one->billing_file->claims_processor->send_personnel_id, 0 );
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# hcfa_rendering_provider
    can_ok( $one, 'hcfa_rendering_provider' );

        $one = $CLASS->new;
    throws_ok{ $one->hcfa_rendering_provider } qr/requires/;

        $one->staff_id( 1001 );
    is_deeply( $one->hcfa_rendering_provider, {
        national_provider_id => '0987654321',
    });

    # clinician's NPI undef - should return the clinic's
        $one->staff_id( 1003 );
    is_deeply( $one->hcfa_rendering_provider, {
        national_provider_id => '1234567890',
    });

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prognotes_to_service_lines
    can_ok( $one, 'prognotes_to_service_lines' );

    throws_ok{ $one->prognotes_to_service_lines } qr/Must call on stored object/;

        $one = $CLASS->new;
        $one->retrieve( 1002 );
        my( $service_lines, $claim_data ) = $one->prognotes_to_service_lines;
        my $sum_service_amounts;
        $sum_service_amounts += $_->{ charge_amount }
            for @$service_lines;

    is( $claim_data->{ total_amount }, $sum_service_amounts );
    is( $sum_service_amounts, "775.04" );

    # TODO more testing that the service lines and claim data comes out right

        $one = $CLASS->new;
        
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write 837 for the first billing cycle and process payment 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_cycle->write_837( 1002 );

        # ECS files need to be marked as submitted separately from file generation
        my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( 1002 );
        $billing_file->save_as_billed( '2006-06-29 16:04:25' );

        my $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.1.txt', '2006-09-05' ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_latest_prognote_date
        $one = $CLASS->new;
    can_ok( $one, 'get_latest_prognote_date' );
    is( $one->get_latest_prognote_date, undef );

        $one->retrieve( 1001 );
    is( $one->get_latest_prognote_date, '2006-07-12' );
        $one->retrieve( 1002 );
    is( $one->get_latest_prognote_date, '2006-07-14' );
        $one->retrieve( 1003 );
    is( $one->get_latest_prognote_date, '2006-07-14' );
        $one->retrieve( 1004 );
    is( $one->get_latest_prognote_date, undef );
            
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diagnosis_codes
    can_ok( $one, 'diagnosis_codes' );

    throws_ok{ $one->diagnosis_codes } qr/requires/;
    throws_ok{ $one->diagnosis_codes( 'hcfa' ) } qr/requires/; 
        $one->retrieve( 1001 );
    is_deeply( $one->diagnosis_codes, [ '29289' ] );
    is_deeply( $one->diagnosis_codes( 'hcfa' ), [ '292 89' ] );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# data_837
    can_ok( $one, 'data_837' );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# data_hcfa
    can_ok( $one, 'data_hcfa' );
    is( $one->data_hcfa, undef );

        $one->retrieve( 1001 );
    is_deeply( $one->data_hcfa, {
        billing_claim_id    => 1001,
        subscriber          => {
            insurance_id            => 'AA00000A',
            dob                     => '09  27  1904',
            gender                  => 'M',
            employer_or_school_name => undef,
            insurance_name          => 'Providence Health Plans',
            group_name              => 'Musical Group',
            client_relation_to_subscriber => '19',
            name                    => 'Powell I, Bud, J',
            address1                => '456 Main St',
            address2                => undef,
            city                    => 'Portland',
            state                   => 'OR',
            zip                     => '97225',
            group_number            => '4444',
            phone                   => '(111) 2223333',
            co_pay_amount           => '15.00',
        },
        client              => {
            client_id   => '1005',
            name        => 'Powell Jr, Bud, J',
            dob         => '09  27  1924',
            gender      => 'M',
            address1    => '123 Main St',
            city        => 'Portland',
            state       => 'OR',
            zip         => '97215',
            phone       => undef,
            is_married => undef,
            diagnosis_codes => [ '292 89' ],
            prior_auth_number => 'NA',
            other_insurance => undef,
            service_lines => [ {
                start_date              => '07  05  06',
                end_date                => '07  05  06',
                facility_code           => '99',
                emergency               => undef,
                service                 => '90806',
                modifiers               => undef,
                diagnosis_code_pointers => [ '1', ],
                charge_amount           => "131.44",
                paid_amount             => '0.00',
                units                   => 2,
            }, {
                start_date              => '07  12  06',
                end_date                => '07  12  06',
                facility_code           => '99',
                emergency               => undef,
                service                 => '90806',
                modifiers               => undef,
                diagnosis_code_pointers => [ '1', ],
                charge_amount           => "131.44",
                paid_amount             => '0.00',
                units                   => 2,
            }],
            service_facility => undef,
        },
        rendering_provider  => {
            national_provider_id => '0987654321',
        },
    });

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_hcfa_client_data
    can_ok( $one, 'get_hcfa_client_data' );
    is( $one->get_hcfa_client_data, undef );

        $one->retrieve( 1003 );
    is_deeply( $one->get_hcfa_client_data, {
        client_id   => '1004',
        name        => 'Fitzgerald, Ella',
        dob         => '04  25  1918',
        gender      => 'F',
        address1    => '131 W 3rd St',
        city        => 'New York',
        state       => 'NY',
        zip         => '10012',
        phone       => '(212) 4758592',
        is_married => undef,
        diagnosis_codes => [ '292 89' ],
        prior_auth_number => 'Foo Bar',
        other_insurance => undef,
        service_lines => [ {
            start_date              => '07  03  06',
            end_date                => '07  03  06',
            facility_code           => '12',
            emergency               => undef,
            service                 => '90806',
            modifiers               => undef,
            diagnosis_code_pointers => [ '1', ],
            charge_amount           => "131.44",
            paid_amount             => '0.00',
            units                   => 2,
        }, {
            start_date              => '07  07  06',
            end_date                => '07  07  06',
            facility_code           => '12',
            emergency               => undef,
            service                 => '90806',
            modifiers               => undef,
            diagnosis_code_pointers => [ '1', ],
            charge_amount           => "131.44",
            paid_amount             => '0.00',
            units                   => 2,
        }, {
            start_date              => '07  10  06',
            end_date                => '07  10  06',
            facility_code           => '12',
            emergency               => undef,
            service                 => '90806',
            modifiers               => undef,
            diagnosis_code_pointers => [ '1', ],
            charge_amount           => "131.44",
            paid_amount             => '0.00',
            units                   => 2,
        }, {
            start_date              => '07  14  06',
            end_date                => '07  14  06',
            facility_code           => '12',
            emergency               => undef,
            service                 => '90806',
            modifiers               => undef,
            diagnosis_code_pointers => [ '1', ],
            charge_amount           => "131.44",
            paid_amount             => '0.00',
            units                   => 2,
        }, ],
        service_facility => {
            name        => 'Substance abuse',
            addr        => '123 4th Street, 101A',
            citystatezip => 'Portland, OR 97215',
        },
    });

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_hcfa_auth_code
    can_ok( $one, 'get_hcfa_auth_code' );
    is( $one->get_hcfa_auth_code, undef );

        $one->retrieve( 1001 );
    is( $one->get_hcfa_auth_code, 'NA' );

        $one->retrieve( 1002 );
    is( $one->get_hcfa_auth_code, 'D123' );

        $one->retrieve( 1003 );
    is( $one->get_hcfa_auth_code, 'Foo Bar' );

        $one->retrieve( 999 );
    is( $one->get_hcfa_auth_code, undef );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_hcfa_service_facility
    can_ok( $one, 'get_hcfa_service_facility' );
    is( $one->get_hcfa_service_facility, undef );

        $one->retrieve( 1001 );
        # program is Referral, should be blank
    is( $one->get_hcfa_service_facility, undef );

        $one->retrieve( 1002 );
    is_deeply( $one->get_hcfa_service_facility, {
        name        => 'Substance abuse',
        addr        => '123 4th Street, 101A',
        citystatezip => 'Portland, OR 97215',
    });

        $one->retrieve( 1003 );
    is_deeply( $one->get_hcfa_service_facility, {
        name        => 'Substance abuse',
        addr        => '123 4th Street, 101A',
        citystatezip => 'Portland, OR 97215',
    });

        $one->retrieve( 999 );
    is( $one->get_hcfa_service_facility, undef );

    # Test with missing city/state/zips
        $one->retrieve( 1003 );
        # Temporarily remove the address info
        my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
        my $program = $valid_data->get( '_program', 1001 );
        my $city = $program->{ city };
        my $state = $program->{ state };
        my $zip = $program->{ zip };

        $program->{ city } = undef;
        $valid_data->save( '_program', $program );
    is_deeply( $one->get_hcfa_service_facility, {
        name        => 'Substance abuse',
        addr        => '123 4th Street, 101A',
        citystatezip => ' OR 97215',
    });
        $program->{ state } = undef;
        $valid_data->save( '_program', $program );
    is_deeply( $one->get_hcfa_service_facility, {
        name        => 'Substance abuse',
        addr        => '123 4th Street, 101A',
        citystatezip => ' 97215',
    });
        $program->{ zip } = undef;
        $valid_data->save( '_program', $program );
    is_deeply( $one->get_hcfa_service_facility, {
        name        => 'Substance abuse',
        addr        => '123 4th Street, 101A',
        citystatezip => undef,
    });

        # reset addresses
        $program->{ city } = $city;
        $program->{ state } = $state;
        $program->{ zip } = $zip;
        $valid_data->save( '_program', $program );
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_hcfa_other_insurance_data
    can_ok( $one, 'get_hcfa_other_insurance_data' );
    throws_ok{ $one->get_hcfa_other_insurance_data } qr/requires/;

        $one->retrieve( 1002 );
    is_deeply( $one->get_hcfa_other_insurance_data, {
        subscriber_name     => 'Powell, Bud',
        subscriber_dob      => '09  27  1924',
        subscriber_gender   => 'M',
        insurance_name      => 'WaCo OHP CAP',
        group_number        => undef,
        group_name          => 'pianists',
        employer_or_school_name => 'Blue Note',
    }); 
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_hcfa_service_lines
    can_ok( $one, 'get_hcfa_service_lines' );
    throws_ok{ $one->get_hcfa_service_lines } qr/stored object/;

        $one->retrieve( 1002 );
    is_deeply( $one->get_hcfa_service_lines, [{
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
    }, {
        start_date              => '07  05  06',
        end_date                => '07  05  06',
        facility_code           => '11',
        emergency               => undef,
        service                 => '90862',
        modifiers               => undef,
        diagnosis_code_pointers => [ '1', ],
        charge_amount           => "131.44",
        paid_amount             => '0.00',
        units                   => 2,
    }, {
        start_date              => '07  07  06',
        end_date                => '07  07  06',
        facility_code           => '11',
        emergency               => undef,
        service                 => '90806',
        modifiers               => undef,
        diagnosis_code_pointers => [ '1', ],
        charge_amount           => "131.44",
        paid_amount             => '0.00',
        units                   => 2,
    }, {
        start_date              => '07  10  06',
        end_date                => '07  10  06',
        facility_code           => '11',
        emergency               => undef,
        service                 => '90806',
        modifiers               => undef,
        diagnosis_code_pointers => [ '1', ],
        charge_amount           => "131.44",
        paid_amount             => '0.00',
        units                   => 2,
    }, {
        start_date              => '07  12  06',
        end_date                => '07  12  06',
        facility_code           => '11',
        emergency               => undef,
        service                 => '90862',
        modifiers               => undef,
        diagnosis_code_pointers => [ '1', ],
        charge_amount           => "131.44",
        paid_amount             => '0.00',
        units                   => 2,
    }, {
        start_date              => '07  14  06',
        end_date                => '07  14  06',
        facility_code           => '11',
        emergency               => undef,
        service                 => '90862',
        modifiers               => [ 'HK' ],
        diagnosis_code_pointers => [ '1', ],
        charge_amount           => "124.64",
        paid_amount             => '0.00',
        units                   => 2,
    }]);

        # TODO test when there are more than 6 service lines

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_hcfa_subscriber_data
    can_ok( $one, 'get_hcfa_subscriber_data' );
    is( $one->get_hcfa_subscriber_data, undef );
    
        $one->retrieve( 1003 );
        # change it so we can test an insurance in the client's name
        $one->client_insurance_id( 1011 );
    is_deeply( $one->get_hcfa_subscriber_data, {
        insurance_id            => 'AA00000A',
        dob                     => undef,
        gender                  => undef,
        employer_or_school_name => undef,
        insurance_name          => 'Medicare',
        group_name              => 'Musical Group',
        client_relation_to_subscriber => '00',
        co_pay_amount           => '15.00',
    });
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_deduction_groups
    can_ok( $CLASS, 'get_deduction_groups' );
    throws_ok{ $CLASS->get_deduction_groups } qr/required/;

    is_deeply( $CLASS->get_deduction_groups( 1001 ), [
        {
            group_code  => 'CO',
            deductions => [{
                rec_id          => 1001,
                transaction_id  => 1001,
                amount          => '75.00',
                units           => undef,
                group_code      => 'CO',
                reason_code     => 'A2',
            },],
        },
        {
            group_code  => 'PR',
            deductions => [{
                rec_id          => 1002,
                transaction_id  => 1001,
                amount          => '42.16',
                units           => 1,
                group_code      => 'PR',
                reason_code     => 'A2', 
            },],
        }, 
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save_as_billed
    can_ok( $one, 'save_as_billed' );
    
    throws_ok{ $one->save_as_billed } qr/stored object/;

        for( 1001, 1002 ) {
            $tmp = eleMentalClinic::Financial::BillingService->retrieve( $_ );
            is( $tmp->billed_amount, undef );
            is( $tmp->billed_units, undef );
            is( $tmp->line_number, undef );
        }

    # Test what happens when a charge code is missing minutes_per_unit.

        # To make this test more interesting, have one service be for charge code 1005
        # and the other be for charge code 1015
        $tmp = eleMentalClinic::ProgressNote->retrieve( 1066 );
        $tmp->charge_code_id( 1015 );
        $tmp->save;

        # Temporarily remove the charge code minutes_per_unit for 1005
        $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
        my $charge_code = $valid_data->get( '_charge_code', 1005 );
        my $minutes_per_unit = $charge_code->{ minutes_per_unit };
        $charge_code->{ minutes_per_unit } = 0;
        $valid_data->save( '_charge_code', $charge_code );

        # Because the charge code info is missing, we assume it wasn't billed,
        # but we don't die.
        $one->retrieve( 1001 );

    warning_like {
        ok( $one->save_as_billed );
    } qr/charge code is missing minutes_per_unit/;

        # the first service, charge code 1005, is not marked billed
        $tmp = eleMentalClinic::Financial::BillingService->retrieve( 1001 );
    is( $tmp->billed_amount, undef );
    is( $tmp->billed_units, undef );
    is( $tmp->line_number, undef );
            
        # the service line with the other charge code is still marked as billed
        $tmp = eleMentalClinic::Financial::BillingService->retrieve( 1002 );
    is( $tmp->billed_amount, 131.44 );
    is( $tmp->billed_units, 2 );
    is( $tmp->line_number, 1 );
        
        # restore
        $charge_code->{ minutes_per_unit } = $minutes_per_unit;
        $valid_data->save( '_charge_code', $charge_code );
        
        $tmp = eleMentalClinic::ProgressNote->retrieve( 1066 );
        $tmp->charge_code_id( 1005 );
        $tmp->save;
        
        # try again, all should be marked billed
    ok( $one->save_as_billed );

        my $line_number = 1;
        for( 1001, 1002 ) {
            $tmp = eleMentalClinic::Financial::BillingService->retrieve( $_ );
            is( $tmp->billed_amount, '131.44' );
            is( $tmp->billed_units, 2 );
            is( $tmp->line_number, $line_number++ );
        }

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# finish first billing cycle, start second 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
        $billing_cycle->validation_set->finish;

        $billing_cycle = $test->financial_setup_billingcycle;
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1005 ], [ 1014 ] );
 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_insurances
    can_ok( $one, 'get_other_insurances' );

        $one = $CLASS->new;
    throws_ok{ $one->get_other_insurances } qr/requires/;

        $one->retrieve( 1001 );
    is( $one->get_other_insurances, undef );
 
        $one->retrieve( 1002 );
    is_deeply( $one->get_other_insurances, [
        eleMentalClinic::Client::Insurance->retrieve( 1004 )
    ]);
        
        $one->retrieve( 1003 );
    is( $one->get_other_insurances, undef );
        
        $one->retrieve( 1004 );
    is_deeply( $one->get_other_insurances, [
        eleMentalClinic::Client::Insurance->retrieve( 1003 )    
    ]);
        
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_other_insurance_data
    can_ok( $one, 'get_other_insurance_data' );

        $one = $CLASS->new;
    throws_ok{ $one->get_other_insurance_data } qr/requires/;

        $one->retrieve( 1004 );
    is_deeply( $one->get_other_insurance_data, [  # client_insurance 1003
        {
            name                            => 'MEDICARE B OF OREGON',
            id                              => '00835',
            plan_rank                       => 'P',
            patient_relation_to_subscriber  => '23',
            patient_insurance_id            => undef,
            group_number                    => undef,
            group_name                      => 'Baroness',
            insurance_type                  => 'MB',
            claim_filing_indicator_code     => 'MB',
            paid_amount                     => '7.48',
            subscriber                      => {
                dob             => '19131210',
                gender          => 'F',
                lname           => 'de Koenigswarter',
                fname           => 'Nica',
                mname           => undef,
                name_suffix     => undef,
                address1        => '10 Rue Flavel',
                address2        => 'Suite 6',
                city            => 'Paris',
                state           => 'NY',
                zip             => '10044',
                insurance_id    => '0141',
            },
            service_lines                   => [{
                billing_service_id  => 1013,
                paid_amount         => '7.48',
                paid_service        => '90862',
                modifiers           => [ 'HK' ],
                paid_units          => 2,
                deduction_groups   => [{
                    group_code => 'CO',
                    deductions => [{
                        rec_id          => '1001',
                        transaction_id  => '1001',
                        amount          => '75.00',
                        units           => undef,
                        group_code      => 'CO',
                        reason_code     => 'A2',
                    }],
                },
                {
                    group_code => 'PR',
                    deductions => [{
                        rec_id          => '1002',
                        transaction_id  => '1001',
                        amount          => '42.16',
                        units           => 1,
                        group_code      => 'PR',
                        reason_code     => 'A2',
                    }],
                }],
                adjudication_date   => '20060902',
            }],
        },
    ]);

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rendering_provider again
        
        $one = $CLASS->new;
        $one->staff_id( 1003 );
        $one->billing_file_id( 1003 );

        # the payer for this billing_file does not require rendering providers
        # so nothing is sent here
    is( $one->billing_file->claims_processor->requires_rendering_provider_ids, 0 );
    is( $one->rendering_provider, undef );

        $one = $CLASS->new;
   
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# process payment for 2nd billing cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_cycle->write_837( 1003 );

        # ECS files need to be marked as submitted separately from file generation
        $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( 1003 );
        $billing_file->save_as_billed( '2006-06-29 16:04:25' );

        $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.2.txt', '2006-09-05' ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client_insurance
    can_ok( $CLASS, 'client_insurance' );
    is_deeply( $CLASS->retrieve( 1001 )->client_insurance, eleMentalClinic::Client::Insurance->retrieve( 1010 ));
    is_deeply( $CLASS->retrieve( 1002 )->client_insurance, eleMentalClinic::Client::Insurance->retrieve( 1003 ));
    is_deeply( $CLASS->retrieve( 1003 )->client_insurance, eleMentalClinic::Client::Insurance->retrieve( 1007 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing_file
    can_ok( $CLASS, 'billing_file' );
    is_deeply( $CLASS->retrieve( 1001 )->billing_file, eleMentalClinic::Financial::BillingFile->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1002 )->billing_file, eleMentalClinic::Financial::BillingFile->retrieve( 1002 ));
    is_deeply( $CLASS->retrieve( 1003 )->billing_file, eleMentalClinic::Financial::BillingFile->retrieve( 1002 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# personnel
    can_ok( $CLASS, 'personnel' );
    is_deeply( $CLASS->retrieve( 1001 )->personnel, eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply( $CLASS->retrieve( 1002 )->personnel, eleMentalClinic::Personnel->retrieve( 1002 ));
    is_deeply( $CLASS->retrieve( 1003 )->personnel, eleMentalClinic::Personnel->retrieve( 1001 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Run a billing cycle where a claim contains no service lines. Make sure the claim doesn't go into the 837 

        # Test normal case
        dbinit( 1 );
        $test->financial_setup( 1, undef, { no_payment => 1 });
        $one->retrieve( 1003 );
        my $subdata = $CLASS->get_subscriber_data( [ $one ] );
    is( @{ $subdata->{ dependents }->[0]{ claims } }, 1 );

        # Now run it again
        dbinit( 1 );
        # update the notes for client 1004 so that they all have a charge code that's missing dollars_per_unit
        # then what would have been billing_claim 1003 shouldn't be created
        for( 1056 .. 1059 ) {
            my $prognote = eleMentalClinic::ProgressNote->retrieve( $_ );
            $prognote->{ charge_code_id } = 2;  # No Show
            $prognote->save;
        }

    # Four charge codes missing dollars_per_unit, all should warn
    warnings_like {
        $test->financial_setup( 1, undef, { no_payment => 1 });
    } [(qr{charge code is missing .* dollars_per_unit}) x 4];

        $one->retrieve( 1003 );
    throws_ok{ $subdata = $CLASS->get_subscriber_data( [ $one ] ); } qr/No valid claims found/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Run a billing cycle where a client has no diagnosis. Make sure the claim doesn't go into the 837 

        dbinit( 1 );
        # remove the diagnoses for client 1003
        for( 1001, 1002 ){
            my $client_diagnosis = eleMentalClinic::Client::Diagnosis->retrieve( $_ );
            $client_diagnosis->{ diagnosis_1a } = '';
            $client_diagnosis->save;
        }

        $test->financial_setup( 1, undef, { no_payment => 1 });
        $one->retrieve( 1002 );
    throws_ok{ $subdata = $CLASS->get_subscriber_data( [ $one ] ); } qr/Missing diagnosis/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
