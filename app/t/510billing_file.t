# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 124;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Financial::BillingFile';
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
    ok( $one = $CLASS->empty );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'billing_file');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id billing_cycle_id group_control_number
        set_control_number purpose type is_production submission_date
        rolodex_id edi
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# init, defaults
    can_ok( $one, 'init' );
    can_ok( $one, 'defaults' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# new_claim
    my $ciauth = $client_insurance_authorization->{1001};
    my $cinsurance = $client_insurance->{$ciauth->{client_insurance_id}};
    my $claim_parameters = {
        staff_id => 1000,
        client_id => $cinsurance->{client_id},
        client_insurance_id => $cinsurance->{rec_id},
        insurance_rank => $cinsurance->{rank},
        client_insurance_authorization_id => $ciauth->{rec_id},        
    };
    can_ok( $one, 'new_claim' );
    is( $one->new_claim, undef );
    is( $one->new_claim({}), undef, 'should not execut if parameters are blank');
        $one->empty;
    is( $one->new_claim($claim_parameters), undef, 'should not try to create new claim if $self is not setup.' );
        $one->retrieve(1001)->save;
    my $claim = $one->new_claim($claim_parameters);
    isnt( $claim, undef );
    my $test_claim = eleMentalClinic::Financial::BillingClaim->retrieve($claim->id);
    is_deeply( $claim, $test_claim, 'generated and db claim match');

dbinit(1);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setup database for add_claims
    ok( my $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 ) );
#        $test->financial_setup_system_validation( $billing_cycle );
#        $test->financial_setup_payer_validation( $billing_cycle );
        $one = $CLASS->new({
            billing_cycle_id    => 1001,
            rolodex_id          => 1009,
        });
    ok( $one->save );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add_claims
    can_ok( $one, 'add_claims' );

    is( $one->add_claims, undef );
    is( $one->add_claims([]), undef, 'must send some progress notes' );
    my $p1 = eleMentalClinic::ProgressNote->retrieve(1065);
    my $p2 = eleMentalClinic::ProgressNote->retrieve(1066);
    is( $one->rolodex_id, 1009 );
    is( $one->billing_claims, undef, 'billing file currently has no claims.' );
    ok( $one->add_claims([ $p1, $p2 ]), 'can execute add_claims' ); 

    # check billing_file
    is_deeply( $one, 
        { 
            rec_id => 1001,
            billing_cycle_id => 1001,
            group_control_number => 1,
            set_control_number => 1,
            purpose => '00',
            type => 'CH',
            is_production => 0,
            submission_date => undef,
            rolodex_id => 1009,
            edi => undef,
            payer => $rolodex->{ 1009 },
        }
    );

    # check billing_claims
    is_deeply( $one->billing_claims, [
        {
            rec_id => 1001,
            billing_file_id => 1001,
            staff_id => 1001,
            client_id => 1005,
            client_insurance_id => 1010,
            client_insurance_authorization_id => 1013,
            insurance_rank => 1,
        },
    ]);

    # check billing_services
    is_deeply( $one->billing_claims->[0]->billing_services, [
        { rec_id => 1001, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1002, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
    ]);

    # check billing_prognotes
    is_deeply( $one->billing_claims->[0]->billing_services->[0]->billing_prognotes, [
        { rec_id => 1001, billing_service_id => 1001, prognote_id => 1065, },
    ]);
    is_deeply( $one->billing_claims->[0]->billing_services->[1]->billing_prognotes, [
        { rec_id => 1002, billing_service_id => 1002, prognote_id => 1066, },
    ]);

        $one = $CLASS->empty;

dbinit(1);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# do the database setup - start the first billing cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 ) );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );

        $tmp = {
            rec_id              => 1001,
            billing_cycle_id    => 1001,
            group_control_number => 1,
            set_control_number  => 1,
            purpose             => '00',
            type                => 'CH',
            is_production       => 0,
            submission_date     => undef,
            rolodex_id          => 1009,
            edi                 => undef,
            payer               => $rolodex->{ 1009 },
        };
    is_deeply( $one->new({ 
        rec_id              => 1001, 
        billing_cycle_id    => 1001,
        rolodex_id          => 1009,
    }), $tmp );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all_billed
    can_ok( $CLASS, 'get_all_billed' );
    is( $CLASS->get_all_billed, undef );
    
    # notice that get_all will fetch the files that aren't actually billed yet
    is_deeply( $CLASS->get_all, [
        eleMentalClinic::Financial::BillingFile->retrieve( 1001 ),
        eleMentalClinic::Financial::BillingFile->retrieve( 1002 ),
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rec_id_f
    can_ok( $one, 'rec_id_f' );
    is( $one->rec_id_f, undef );

        $one->rec_id( 1001 )->retrieve;
    is( $one->rec_id_f, '000001001' );
        $one->rec_id( 999 )->retrieve;
    is( $one->rec_id_f, undef );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set_control_number_f
    can_ok( $one, 'set_control_number_f' );
    is( $one->set_control_number_f, '0001' );

        $one->rec_id( 1001 )->retrieve;
    is( $one->set_control_number_f, '0001' );
        $one->rec_id( 999 )->retrieve;
    is( $one->set_control_number_f, '0001' );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# mode
    can_ok( $one, 'mode' );
    is( $one->mode, 'T' );

        $one->rec_id( 1001 )->retrieve;
    is( $one->mode, 'T' );
        $one->is_production( 1 );
    is( $one->mode, 'P' );

        # Test that if a claims_processor sends production files, the new billing file is production
        $one = $CLASS->new({
            billing_cycle_id    => 1001,
            rolodex_id          => 1015,
        });
    is( $one->mode, 'T' );
        my $claims_processor = eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1003 );
    is( $claims_processor->send_production_files, 0 );
        $claims_processor->send_production_files( 1 )->save;
        
        $one = $CLASS->new({
            billing_cycle_id    => 1001,
            rolodex_id          => 1015,
        });
    is( $one->mode, 'P' );
        $claims_processor->send_production_files( 0 )->save;

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_submitter
    can_ok( $one, 'get_submitter' );
    throws_ok { $one->get_submitter } qr/requires/;

        $one->retrieve( 1002 );
        $tmp = {
            id              => 'OR00000',
            name            => 'Our Clinic',
            contact_name    => 'Site Admin',
            contact_method  => 'TE',
            contact_number  => '5035557777',
            contact_extension => '123',
        };
    is_deeply( $one->get_submitter, $tmp );
        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_payer
    can_ok( $one, 'get_payer_data' );
    throws_ok { $one->get_payer_data } qr/requires/;

        $one->retrieve( 1002 );
        $tmp = {
            name     => 'MEDICARE B OF OREGON',
            id       => '00835',
            address  => 'PO Box 9319',
            address2 => undef,
            city     => 'Fargo', 
            state    => 'ND',
            zip      => '581066702',
            claims_processor_id => 1003,
            edi_indicator_code => 'MB',
        };
    is_deeply( $one->get_payer_data, $tmp );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_sender
    can_ok( $one, 'get_sender' );
    throws_ok { $one->get_sender } qr/requires/;

        $one->retrieve( 1002 );
    is_deeply( $one->get_sender, {
        interchange_id_qualifier => 'ZZ',
        padded_interchange_id    => 'OR00000        ',
        code                     => 'OR00000',
    });

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_receiver
    can_ok( $one, 'get_receiver' );
    throws_ok { $one->get_receiver } qr/requires/;

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_billing_provider
    can_ok( $one, 'get_billing_provider' );
    throws_ok { $one->get_billing_provider } qr/requires/;

        $one->retrieve( 1002 );
    is_deeply( $one->get_billing_provider, {
        name                     => 'Our Clinic',
        national_provider_id     => '1234567890',
        employer_id              => '123456789',
        address1                 => '123 4th Street, 101',
        address2                 => undef,
        city                     => 'Portland',
        state                    => 'OR',
        zip                      => '97215',
        medicaid_provider_number => '000000',
        medicare_provider_number => 'R000000',
    });
        $one = $CLASS->empty;
        $one->retrieve( 1001 );
    is_deeply( $one->get_billing_provider( 'hcfa' ), {
        name                     => 'Our Clinic',
        national_provider_id     => '1234567890',
        employer_id              => '123-45-6789',
        address1                 => '123 4th Street 101',
        address2                 => undef,
        city                     => 'Portland',
        state                    => 'OR',
        zip                      => '97215',
        citystatezip             => 'Portland OR 97215',
        medicaid_provider_number => '000000',
        medicare_provider_number => 'R000000',
    });

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_subscribers
    can_ok( $one, 'get_subscribers' );
    throws_ok { $one->get_subscribers } qr/Must call on stored object/;

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_837_data
    can_ok( $one, 'get_837_data' );

    throws_ok { $one->get_837_data } qr/requires/;

        $one = $CLASS->empty;
        $one->rec_id( 1002 )->retrieve;
    isnt( $one->get_837_data, undef );

    # TODO this is tested by way of the tests in 551write_837.t - more tests here too?

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_hcfa_data
    can_ok( $one, 'get_hcfa_data' );

    is( $one->get_hcfa_data, undef );

        $one->rec_id( 1001 )->retrieve;
    is_deeply( $one->get_hcfa_data, {
        payer               => {
            name     => 'Providence Health Plans',
            address  => 'P.O. Box 4327',
            address2 => undef,
            citystatezip => 'Portland, OR 97208-4327',
        },
        billing_provider    => {
            name                     => 'Our Clinic',
            national_provider_id     => '1234567890',
            employer_id              => '123-45-6789',
            address1                 => '123 4th Street 101',
            address2                 => undef,
            city                     => 'Portland',
            state                    => 'OR',
            zip                      => '97215',
            citystatezip             => 'Portland OR 97215',
            contact_number           => '(503) 5557777',
            medicaid_provider_number => '000000',
            medicare_provider_number => 'R000000',
        },
        claims              => [ {
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
                is_married  => undef,
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
                }, ],
                service_facility => undef,
            },
            rendering_provider  => {
                national_provider_id => '0987654321',
            },
        }, ],
    });

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_hcfa_payer
    can_ok( $one, 'get_hcfa_payer' );

    is( $one->get_hcfa_payer, undef );

        $one->rec_id( 1002 )->retrieve;
    is_deeply( $one->get_hcfa_payer, {
        name     => 'Medicare',
        address  => 'PO Box 9319',
        address2 => undef,
        citystatezip => 'Fargo, ND 58106-6702',
    });

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires_rendering_provider_ids
    can_ok( $one, 'requires_rendering_provider_ids' );
    is( $one->requires_rendering_provider_ids, undef );

        $one->claims_processor( eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1001 ) );
    is( $one->requires_rendering_provider_ids, 0 );

        $one->claims_processor( eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1002 ) );
    is( $one->requires_rendering_provider_ids, 0 );

        $one->claims_processor( eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1003 ) );
    is( $one->requires_rendering_provider_ids, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# date_edi_billed
    can_ok( $one, 'date_edi_billed' );
    throws_ok { $one->date_edi_billed } qr/Must call on stored object/;
        $one->rec_id( 1002 )->retrieve;
    is( $one->date_edi_billed, undef );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# finish the first billing cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        my( $file837, $edi_data ) = $billing_cycle->write_837( 1002, '2006-06-29 16:04:25' );
        $billing_cycle->write_hcfas( 1001, '2006-06-29 16:04:25' );

        # ECS files need to be marked as submitted separately from file generation
        $one->rec_id( 1002 )->retrieve;
        $one->save_as_billed( '2006-06-29 16:04:24', $edi_data );

        my $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.1.txt', '2006-09-05' ) );

        $billing_cycle->validation_set->finish;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all_billed
    is_deeply( $CLASS->get_all_billed, [
        eleMentalClinic::Financial::BillingFile->retrieve( 1001 ),
        eleMentalClinic::Financial::BillingFile->retrieve( 1002 ),
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# do the database setup for the second billing cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_cycle = $test->financial_setup_billingcycle;
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1005 ], [ 1014 ] );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_hcfa_claims
    can_ok( $one, 'get_hcfa_claims' );

    throws_ok { $one->get_hcfa_claims } qr/Must call on stored object/;

        $one->rec_id( 1003 )->retrieve;
    is_deeply( $one->get_hcfa_claims, [{
        billing_claim_id    => 1004,
        subscriber          => {
            insurance_id            => 'white keys',
            dob                     => '09  27  1924',
            gender                  => 'M',
            employer_or_school_name => 'Blue Note',
            insurance_name          => 'WaCo OHP CAP',
            group_name              => 'pianists',
            client_relation_to_subscriber => 'G8',
            name                    => 'Powell, Bud',
            address1                => '123 Downuptown St',
            address2                => undef,
            city                    => 'New York',
            state                   => 'NY',
            zip                     => '10271',
            group_number            => undef,
            phone                   => '9210472814',
            co_pay_amount           => '0.00',
        },
        client              => {
            client_id   => '1003',
            name        => 'Monk, Thelonious',
            dob         => '10  10  1917',
            gender      => 'M',
            address1    => '116 E 27th St',
            city        => 'New York',
            state       => 'NY',
            zip         => '10016',
            is_married  => undef,
            phone       => '(212) 5762232',
            diagnosis_codes => [ '296 60' ],
            prior_auth_number => 'RCA3',
            other_insurance => {
                subscriber_name     => 'de Koenigswarter, Nica',
                subscriber_dob      => '12  10  1913',
                subscriber_gender   => 'F',
                insurance_name      => 'Medicare',
                group_number        => undef,
                group_name          => 'Baroness',
                employer_or_school_name => 'none',
            },
            service_lines => [ {
                start_date              => '07  03  06',
                end_date                => '07  03  06',
                facility_code           => '11',
                emergency               => undef,
                service                 => '90862',
                modifiers               => [ 'HK' ],
                diagnosis_code_pointers => [ '1', ],
                charge_amount           => "124.64",
                paid_amount             => "7.48",
                units                   => 2,
            }, ],
            service_facility => {
                name        => 'Substance abuse',
                addr        => '123 4th Street, 101A',
                citystatezip => 'Portland, OR 97215',
            },
        },
        rendering_provider  => {
            national_provider_id => '5432154321',
        },
    }]);
    
        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# date_edi_billed again
        $one->rec_id( 1002 )->retrieve;
    is( $one->date_edi_billed, '2006-06-29 16:04:24' );

    # Test 1001 - HCFA was billed but it's not EDI
        $one->rec_id( 1001 )->retrieve;
    is( $one->date_edi_billed, undef );
    is( $one->submission_date, '2006-06-29 16:04:25' );
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_by_billing_cycle
    can_ok( $CLASS, 'list_by_billing_cycle' );
    is( $CLASS->list_by_billing_cycle, undef );

        my %exceptions = ( payer => undef, claims_processor => undef );
    is_deeply_except( \%exceptions, $CLASS->list_by_billing_cycle( 1001 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1001 ),
        eleMentalClinic::Financial::BillingFile->retrieve( 1002 ),
    ] );

    is_deeply_except( \%exceptions, $CLASS->list_by_billing_cycle( 1002 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1003 ),
    ] );
    
    is_deeply_except( \%exceptions, $CLASS->list_by_billing_cycle( 1001, 1009 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1001 ),
    ] );
    
    is_deeply_except( \%exceptions,  $CLASS->list_by_billing_cycle( 1001, 1015 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1002 ),
    ] );

    is( $CLASS->list_by_billing_cycle( 1001, 1014 ), undef );
    
    is_deeply_except( \%exceptions, $CLASS->list_by_billing_cycle( 1002, 1014 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1003 ),
    ] );
    
    is( $CLASS->list_by_billing_cycle( 1001, 999 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_by_billing_cycle
    can_ok( $CLASS, 'get_by_billing_cycle' );
    is( $CLASS->get_by_billing_cycle, undef );

    is_deeply( $CLASS->get_by_billing_cycle( 1001 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1001 ),
        eleMentalClinic::Financial::BillingFile->retrieve( 1002 ),
    ] );
    is_deeply( $CLASS->get_by_billing_cycle( 1002 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1003 ),
    ] );
    
    is_deeply( $CLASS->get_by_billing_cycle( 1001, 1009 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1001 ),
    ] );
    is_deeply( $CLASS->get_by_billing_cycle( 1001, 1015 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1002 ),
    ] );

    is( $CLASS->get_by_billing_cycle( 1001, 1014 ), undef );
    
    is_deeply( $CLASS->get_by_billing_cycle( 1002, 1014 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1003 ),
    ] );
    
    is( $CLASS->get_by_billing_cycle( 1001, 999 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# label
    can_ok( $CLASS, 'label' );
    is( $CLASS->empty->label, undef );
    is( $CLASS->empty({ rolodex_id => 1015, submission_date => '2006-01-01' })->label, 'Medicare | 2006-01-01' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all_billed - note that 1003 isn't billed yet
    is_deeply( $CLASS->get_all_billed, [
        eleMentalClinic::Financial::BillingFile->retrieve( 1001 ),
        eleMentalClinic::Financial::BillingFile->retrieve( 1002 ),
    ] );
    is_deeply( $CLASS->get_all, [
        eleMentalClinic::Financial::BillingFile->retrieve( 1001 ),
        eleMentalClinic::Financial::BillingFile->retrieve( 1002 ),
        eleMentalClinic::Financial::BillingFile->retrieve( 1003 ),
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
