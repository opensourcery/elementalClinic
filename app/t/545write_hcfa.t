# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 103;
use Test::Exception;
#use Test::PDF;
use Data::Dumper;
use eleMentalClinic::Test;

use eleMentalClinic::Financial::BillingFile;

our ($CLASS, $one, $tmp);
our $BILLING_FILE_REC_ID = 1002;
our $DATE_STAMP = '20060629';
our $MMDD_STAMP = '0629';
our $TIME_STAMP = '1604';

BEGIN {
    *CLASS = \'eleMentalClinic::Financial::HCFA';
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
# run the first billing cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( my $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 ) );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );
        $test->financial_setup_bill( $billing_cycle );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setup for upcoming tests

        my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $BILLING_FILE_REC_ID );
        $one = $CLASS->new( { 
            billing_file => $billing_file,
            date_stamp => $DATE_STAMP,
            time_stamp => $TIME_STAMP,
        });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# template_path and output_root path are obtained from Base::config
# Verify that $self->output_root provides same path as config->pdf_out_root
    can_ok( $one, 'output_root' );
    ok( $one->output_root );
    ok( $one->config->pdf_out_root );
    is( $one->config->pdf_out_root, $one->output_root);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make filenames
    can_ok( $one, 'make_filename');
    
    is( $one->make_filename, undef );
    is( $one->make_filename( 1001 ), undef );
    is( $one->make_filename( 1001, 'Medicare of Oregon' ), "1001MedicareofOregonHCFA$MMDD_STAMP.pdf" );

    is( $one->make_filename( 1001, 'Some !@#$%^&*();:"<>.,\?/{}=+-_~` 12345 Payer' ), "1001Some_12345PayerHCFA$MMDD_STAMP.pdf" );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate
    can_ok( $one, 'validate' );
    is( $one->validate, undef );

        # good data: test that it is not altered
        my $good = {  # {{{
            payer => {
                address         => 'P.O. Box 4327',
                address2        => undef,
                citystatezip    => 'Portland, OR 97208-4327',
                name            => 'Test Health Plans'
            },
            billing_provider => {
                address1            => '123 4th Street 101',
                address2            => undef,
                city                => 'Portland',
                citystatezip        => 'Portland, OR 97215',
                contact_number      => '(503) 5557777',
                employer_id         => '123-45-6789',
                name                => 'Our Clinic',
                national_provider_id => '1234567890',
                state               => 'OR',
                taxonomy_code       => '101Y00000X',
                zip                 => '97215',
          },
          claims => [ {
                billing_claim_id => 1001,
                rendering_provider => {},
                client => {
                    address1        => '123 Main St',
                    city            => 'Portland',
                    client_id       => '1005',
                    diagnosis_codes => [ '292 89' ],
                    dob             => '09  27  1924',
                    gender          => 'M',
                    marital_status  => 'Single',
                    name            => 'Powell Jr, Bud, J',
                    phone           => '(503) 7778888',
                    state           => 'OR',
                    zip             => '97215',
                    other_insurance => {
                        employer_or_school_name => 'Other Subscriber Employer',
                        group_name          => 'Group Name',
                        group_number        => 'Group Number',
                        insurance_name      => 'WaCo OHP CAP',
                        subscriber_dob      => '09  27  1924',
                        subscriber_gender   => 'M',
                        subscriber_name     => 'Name, of Other Insurance Subscriber',
                    },
                    service_lines => [ {
                        charge_amount           => '131.44',
                        diagnosis_code_pointers => [ '1' ],
                        emergency               => undef,
                        end_date                => '07  03  06',
                        facility_code           => '11',
                        modifiers               => undef,
                        service                 => '90806',
                        start_date              => '07  03  06',
                        units                   => 2,
                    },
                    {
                        charge_amount           => '131.44',
                        diagnosis_code_pointers => [ '1' ],
                        emergency               => undef,
                        end_date                => '07  05  06',
                        facility_code           => '99',
                        modifiers               => undef,
                        service                 => '90806',
                        start_date              => '07  05  06',
                        units                   => 2,
                    }, ],
                },
                subscriber => {
                    address1        => '456 Main St',
                    address2        => undef,
                    city            => 'Portland',
                    client_relation_to_subscriber => '19',
                    dob             => '09  27  1904',
                    employer_or_school_name => 'Employer',
                    gender          => 'M',
                    group_name      => 'Musical Group',
                    group_number    => '4444',
                    insurance_id    => 'AA00000A',
                    insurance_name  => 'Providence Health Plans',
                    name            => 'Powell I, Bud, J',
                    phone           => '(503) 5556666',
                    state           => 'OR',
                    zip             => '97225'
                },
            } ],
        }; # }}}

    is_deeply( $one->validate( $good ), $good );

        # data with each field going over the max length by one
        # (data that is not used (and therefore not validated) is left alone)
        my $over = {  # {{{
            payer => {
                address         => '00005000050000500005000050000X',
                address2        => undef,
                citystatezip    => '00005000050000500005000050000X',
                name            => '00005000050000500005000050000X'
            },
            billing_provider => {
                address1            => '0000500005000050000500005000X',
                address2            => undef,
                city                => '00005000050000500005000X',
                citystatezip        => '00005000050000500005000050000X',
                contact_number      => '00005000050000X',
                employer_id         => '000050000500005X',
                name                => '00005000050000500005000050000X',
                national_provider_id => '0000500005X',
                state               => '000X',
                taxonomy_code       => '101Y00000X',
                zip                 => '000050000500X',
          },
          claims => [ {
                billing_claim_id => 1001,
                rendering_provider => {},
                client => {
                    address1        => '0000500005000050000500005000X',
                    city            => '00005000050000500005000X',
                    client_id       => '00005000050000X',
                    diagnosis_codes => [ '00005000X' ],
                    dob             => '000050000500X',
                    gender          => '0X',
                    marital_status  => 'Single',
                    name            => '00005000050000500005000050000X',
                    phone           => '000050000500005X',
                    state           => '000X',
                    zip             => '000050000500X',
                    other_insurance => {
                        employer_or_school_name => '0000500005000050000500005000X',
                        group_name          => 'Group Name',
                        group_number        => '0000500005000050000500005000X',
                        insurance_name      => '0000500005000050000500005000X',
                        subscriber_dob      => '000050000500X',
                        subscriber_gender   => '0X',
                        subscriber_name     => '0000500005000050000500005000X',
                    },
                    service_lines => [ {
                        charge_amount           => '000050000X',
                        diagnosis_code_pointers => [ '0000X' ],
                        emergency               => undef,
                        end_date                => '000050000500X',
                        facility_code           => '00X',
                        modifiers               => [ '00X' ],
                        service                 => '000050X',
                        start_date              => '000050000500X',
                        units                   => '000X',
                    },
                    {
                        charge_amount           => '000050000X',
                        diagnosis_code_pointers => [ '0000X' ],
                        emergency               => undef,
                        end_date                => '000050000500X',
                        facility_code           => '00X',
                        modifiers               => [ '00X' ],
                        service                 => '000050X',
                        start_date              => '000050000500X',
                        units                   => '000X',
                    }, ],
                },
                subscriber => {
                    address1        => '0000500005000050000500005000X',
                    address2        => undef,
                    city            => '00005000050000500005000X',
                    client_relation_to_subscriber => '19',
                    dob             => '000050000500X',
                    employer_or_school_name => '0000500005000050000500005000X',
                    gender          => '0X',
                    group_name      => 'Musical Group',
                    group_number    => '0000500005000050000500005000X',
                    insurance_id    => '00005000050000500005000050000X',
                    insurance_name  => '0000500005000050000500005000X',
                    name            => '00005000050000500005000050000X',
                    phone           => '000050000500005X',
                    state           => '000X',
                    zip             => '000050000500X',
                },
            } ],
        }; # }}}

        my $truncated = {  # {{{
            payer => {
                address         => '00005000050000500005000050000',
                address2        => undef,
                citystatezip    => '00005000050000500005000050000',
                name            => '00005000050000500005000050000'
            },
            billing_provider => {
                address1            => '0000500005000050000500005000',
                address2            => undef,
                city                => '00005000050000500005000',
                citystatezip        => '00005000050000500005000050000',
                contact_number      => '00005000050000',
                employer_id         => '000050000500005',
                name                => '00005000050000500005000050000',
                national_provider_id => '0000500005',
                state               => '000',
                taxonomy_code       => '101Y00000X',
                zip                 => '000050000500',
          },
          claims => [ {
                billing_claim_id => 1001,
                rendering_provider => {},
                client => {
                    address1        => '0000500005000050000500005000',
                    city            => '00005000050000500005000',
                    client_id       => '00005000050000',
                    diagnosis_codes => [ '00005000' ],
                    dob             => '000050000500',
                    gender          => '0',
                    marital_status  => 'Single',
                    name            => '00005000050000500005000050000',
                    phone           => '000050000500005',
                    state           => '000',
                    zip             => '000050000500',
                    other_insurance => {
                        employer_or_school_name => '0000500005000050000500005000',
                        group_name          => 'Group Name',
                        group_number        => '0000500005000050000500005000',
                        insurance_name      => '0000500005000050000500005000',
                        subscriber_dob      => '000050000500',
                        subscriber_gender   => '0',
                        subscriber_name     => '0000500005000050000500005000',
                    },
                    service_lines => [ {
                        charge_amount           => '000050000',
                        diagnosis_code_pointers => [ '0000' ],
                        emergency               => undef,
                        end_date                => '000050000500',
                        facility_code           => '00',
                        modifiers               => [ '00' ],
                        service                 => '000050',
                        start_date              => '000050000500',
                        units                   => '000',
                    },
                    {
                        charge_amount           => '000050000',
                        diagnosis_code_pointers => [ '0000' ],
                        emergency               => undef,
                        end_date                => '000050000500',
                        facility_code           => '00',
                        modifiers               => [ '00' ],
                        service                 => '000050',
                        start_date              => '000050000500',
                        units                   => '000',
                    }, ],
                },
                subscriber => {
                    address1        => '0000500005000050000500005000',
                    address2        => undef,
                    city            => '00005000050000500005000',
                    client_relation_to_subscriber => '19',
                    dob             => '000050000500',
                    employer_or_school_name => '0000500005000050000500005000',
                    gender          => '0',
                    group_name      => 'Musical Group',
                    group_number    => '0000500005000050000500005000',
                    insurance_id    => '00005000050000500005000050000',
                    insurance_name  => '0000500005000050000500005000',
                    name            => '00005000050000500005000050000',
                    phone           => '000050000500005',
                    state           => '000',
                    zip             => '000050000500',
                }
            } ],
        }; # }}}

    is_deeply( $one->validate( $over ), $truncated );
        
        # data with each field under the min by one, for those fields that require 2 or more chars
        my $under = {  # {{{
            payer => {
                address         => 'P.O. Box 4327',
                address2        => undef,
                citystatezip    => '0',
                name            => 'Test Health Plans'
            },
            billing_provider => {
                address1            => '123 4th Street 101',
                address2            => undef,
                city                => '0',
                citystatezip        => '0',
                contact_number      => '(503) 5557777',
                employer_id         => '123-45-6789',
                name                => 'Our Clinic',
                national_provider_id => '0',
                state               => '0',
                taxonomy_code       => '101Y00000X',
                zip                 => '00',
          },
          claims => [ {
                billing_claim_id => 1001,
                rendering_provider => {},
                client => {
                    address1        => '123 Main St',
                    city            => '0',
                    client_id       => '1005',
                    diagnosis_codes => [ '292 89' ],
                    dob             => '09  27  1924',
                    gender          => 'M',
                    marital_status  => 'Single',
                    name            => 'Powell Jr, Bud, J',
                    phone           => '(503) 7778888',
                    state           => '0',
                    zip             => '00',
                    other_insurance => {
                        employer_or_school_name => 'Other Subscriber Employer',
                        group_name          => 'Group Name',
                        group_number        => 'Group Number',
                        insurance_name      => 'WaCo OHP CAP',
                        subscriber_dob      => '09  27  1924',
                        subscriber_gender   => 'M',
                        subscriber_name     => 'Name, of Other Insurance Subscriber',
                    },
                    service_lines => [ {
                        charge_amount           => '131.44',
                        diagnosis_code_pointers => [ '1' ],
                        emergency               => undef,
                        end_date                => '07  03  06',
                        facility_code           => '11',
                        modifiers               => [ '0' ],
                        service                 => '90806',
                        start_date              => '07  03  06',
                        units                   => 2,
                    },
                    {
                        charge_amount           => '131.44',
                        diagnosis_code_pointers => [ '1' ],
                        emergency               => undef,
                        end_date                => '07  05  06',
                        facility_code           => '99',
                        modifiers               => undef,
                        service                 => '90806',
                        start_date              => '07  05  06',
                        units                   => 2,
                    }, ],
                },
                subscriber => {
                    address1        => '456 Main St',
                    address2        => undef,
                    city            => '0',
                    client_relation_to_subscriber => '19',
                    dob             => '09  27  1904',
                    employer_or_school_name => 'Employer',
                    gender          => 'M',
                    group_name      => 'Musical Group',
                    group_number    => '4444',
                    insurance_id    => '0',
                    insurance_name  => 'Providence Health Plans',
                    name            => 'Powell I, Bud, J',
                    phone           => '(503) 5556666',
                    state           => '0',
                    zip             => '00',
                }
            } ],
        }; # }}}

    is_deeply( $one->validate( $under ), $under );
        
        # good data with one field that's under its minimum
        $good->{ payer }{ citystatezip } = '0';
        $eleMentalClinic::Base::TESTMODE = 0;
    throws_ok { $one->validate( $good ) } qr/citystatezip length must be at least 2 characters long./;
        $eleMentalClinic::Base::TESTMODE = 1;

    # TODO test required fields

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write file
    can_ok( $one, 'write' );
    is( $one->write, undef );

    #test real case
        $one = $CLASS->new( {
            billing_file => $billing_file,
            date_stamp => $DATE_STAMP,
            time_stamp => $TIME_STAMP,
        });

    ok( -d $one->output_root, $one->output_root.' directory exists' );
        
        my $test_file_path = $one->output_root . "/" . $one->make_filename( $billing_file->rec_id, 'Medicare' );
        unlink $test_file_path;
    is( $one->write, $test_file_path );
    is_pdf_file($test_file_path);
    #cmp_pdf( $test_file_path, 'templates/default/hcfa_billing/hcfa1500.pdf' );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# generate_hcfa
    can_ok( $one, 'generate_hcfa' );
    is( $one->generate_hcfa, undef );

        my $payer = {
            name     => 'Test Health Plans',
            address  => 'P.O. Box 4327',
            address2 => undef,
            citystatezip => 'Portland, OR 97208-4327',
        };
        my $billing_provider = {
            name                     => 'Our Clinic',
            national_provider_id     => '1234567890',
            employer_id              => '123-45-6789',
            address1                 => '123 4th Street 101',
            address2                 => undef,
            city                     => 'Portland',
            state                    => 'OR',
            zip                      => '97215',
            taxonomy_code            => '101Y00000X',
            citystatezip             => 'Portland OR 97215',
            contact_number           => '(503) 5557777',
        };
        my $claim_data = {
            billing_claim_id    => 1001,
            subscriber          => {
                insurance_id            => 'AA00000A',
                dob                     => '09  27  1904',
                gender                  => 'M',
                employer_or_school_name => 'Employer',
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
                phone                   => '(503) 5556666',
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
                phone       => '(503) 7778888',
                marital_status  => 'Single',
                diagnosis_codes => [ '292 89' ],
                prior_auth_number => 'Insurance Auth Code',
                other_insurance => {
                    subscriber_name     => 'Name, of Other Insurance Subscriber',
                    subscriber_dob      => '09  27  1924',
                    subscriber_gender   => 'M',
                    insurance_name      => 'WaCo OHP CAP',
                    group_number        => 'Group Number',
                    group_name          => 'Group Name',
                    employer_or_school_name => 'Other Subscriber Employer',
                },
                service_lines => [ {
                    start_date              => '07  05  06',
                    end_date                => '07  05  06',
                    facility_code           => '99',
                    emergency               => undef,
                    service                 => '90806',
                    modifiers               => [ 'HK', ],
                    diagnosis_code_pointers => [ '1', ],
                    charge_amount           => "131.44",
                    paid_amount             => 0,
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
                    paid_amount             => 0,
                    units                   => 2,
                }, ],
            },
            rendering_provider  => {
                national_provider_id => '0987654321',
            },
        };
    is( $one->generate_hcfa( $payer ), undef );
    is( $one->generate_hcfa( $payer, $billing_provider ), undef );
        
        $one->date_stamp( $DATE_STAMP );
        $test_file_path = $one->output_root . "/" . $one->make_filename( 1001, 'Test Health Plans' );
        unlink $test_file_path;
        $one->pdf( eleMentalClinic::PDF->new );
        $one->pdf->start_pdf( $test_file_path );
    ok( $one->generate_hcfa( $payer, $billing_provider, $claim_data ) );
    is_pdf_file($test_file_path);
    #cmp_pdf( $test_file_path, 'templates/default/hcfa_billing/hcfa1500.pdf' );

        $one->pdf->finish_pdf;
        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# generate_hcfas 
    can_ok( $one, 'generate_hcfas' );
    is( $one->generate_hcfas, undef );

        # 7 service lines should produce 2 files
        $tmp = [ {
            start_date              => '07  03  06',
            end_date                => '07  03  06',
            facility_code           => '11',
            emergency               => undef,
            service                 => '90806',
            modifiers               => undef,
            diagnosis_code_pointers => [ '1', ],
            charge_amount           => "131.44",
            paid_amount             => 0,
            units                   => 2,
        }, {
            start_date              => '07  05  06',
            end_date                => '07  05  06',
            facility_code           => '99',
            emergency               => undef,
            service                 => '90806',
            modifiers               => undef,
            diagnosis_code_pointers => [ '1', ],
            charge_amount           => "131.44",
            paid_amount             => 0,
            units                   => 2,
        }, {
            start_date              => '07  07  06',
            end_date                => '07  07  06',
            facility_code           => '99',
            emergency               => undef,
            service                 => '90806',
            modifiers               => undef,
            diagnosis_code_pointers => [ '1', ],
            charge_amount           => "131.44",
            paid_amount             => 0,
            units                   => 2,
        }, {
            start_date              => '07  10  06',
            end_date                => '07  10  06',
            facility_code           => '99',
            emergency               => undef,
            service                 => '90806',
            modifiers               => undef,
            diagnosis_code_pointers => [ '1', ],
            charge_amount           => "131.44",
            paid_amount             => 0,
            units                   => 2,
        }, {
            start_date              => '07  11  06',
            end_date                => '07  11  06',
            facility_code           => '99',
            emergency               => undef,
            service                 => '90806',
            modifiers               => undef,
            diagnosis_code_pointers => [ '1', ],
            charge_amount           => "131.44",
            paid_amount             => 0,
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
            paid_amount             => 0,
            units                   => 2,
        }, {
            start_date              => '07  14  06',
            end_date                => '07  14  06',
            facility_code           => '99',
            emergency               => undef,
            service                 => '90806',
            modifiers               => undef,
            diagnosis_code_pointers => [ '1', ],
            charge_amount           => "131.44",
            paid_amount             => 0,
            units                   => 2,
        }, ];

        $claim_data->{ client }{ service_lines } = $tmp;

        my $hcfa_data = {
            payer   => $payer,
            claims  => [ $claim_data ],
            billing_provider => $billing_provider,
        };

        $one->date_stamp( $DATE_STAMP );
        $test_file_path = $one->output_root . "/" . $one->make_filename( 1001, 'Test Health Plans' );
        unlink $test_file_path;

        $one->billing_file( eleMentalClinic::Financial::BillingFile->retrieve( 1001 ) );
    is( $one->generate_hcfas( $hcfa_data ), $test_file_path );
    
    is_pdf_file($test_file_path);
#    cmp_pdf( $test_file_path,  'sample.pdf' );

        # Add on 7 more services lines (total of 14), make sure we get 3 files
        # TODO this can't be tested (except by looking at the file) now that we append them all into one file-- until we do pdf file comparisons
        $one = $CLASS->empty;
        $one->date_stamp( $DATE_STAMP );

        @{ $claim_data->{ client }{ service_lines } } = ( @$tmp, @$tmp );
        $test_file_path = $one->output_root . "/" . $one->make_filename( 1001, 'Test Health Plans', 1005 );
        unlink $test_file_path;
        $one->billing_file( eleMentalClinic::Financial::BillingFile->retrieve( 1001 ) );
    is( $one->generate_hcfas( $hcfa_data ), $test_file_path );
    
    is_pdf_file($test_file_path);
#    cmp_pdf( $test_file_path,  'sample.pdf' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Finish the first billing cycle, process first payment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_cycle->write_hcfas( 1002, '2006-06-29 16:04:25' );

        my $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.1.txt', '2006-09-05' ) );
        
        $billing_cycle->validation_set->finish;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Second billing cycle, secondary payers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $billing_cycle = $test->financial_setup_billingcycle;
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1005 ], [ 1014 ] );
        $test->financial_setup_bill( $billing_cycle, [ 1003 ], [], '2006-08-31 18:04:25' );

        $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( 1003 );
        $one = $CLASS->new( {
            billing_file => $billing_file,
            date_stamp => $DATE_STAMP,
            time_stamp => $TIME_STAMP,
            template   => 'hcfa1500.pdf', 
        });
        
        $test_file_path = $one->output_root . "/" . $one->make_filename( $billing_file->rec_id, 'WaCo OHP CAP' );
        unlink $test_file_path;

        $one->write;

    is_pdf_file($test_file_path);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# format_dollars
    can_ok( $CLASS, 'format_dollars' );
    is( $CLASS->format_dollars, undef );

    is( $CLASS->format_dollars( '62.4' ), '62 40' );
    is( $CLASS->format_dollars( '9' ), '9 00' );
    is( $CLASS->format_dollars( '12.56' ), '12 56' );
    is( $CLASS->format_dollars( '19.00' ), '19 00' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_date_f
    can_ok( $CLASS, 'get_date_f' );
    is( $CLASS->get_date_f, undef );

    is( $CLASS->get_date_f( '2006-08-28' ), '08  28  2006' );
    is( $CLASS->get_date_f( '2006-8-28' ), '08  28  2006' );
    is( $CLASS->get_date_f( '2006-08' ), undef );
    is( $CLASS->get_date_f( '06-08-28' ), undef );
    is( $CLASS->get_date_f( '20060828' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_shortdate_f
    can_ok( $CLASS, 'get_shortdate_f' );
    is( $CLASS->get_shortdate_f, undef );

    is( $CLASS->get_shortdate_f( '2006-08-28' ), '08  28  06' );
    is( $CLASS->get_shortdate_f( '2006-8-28' ), '08  28  06' );
    is( $CLASS->get_shortdate_f( '2006-08' ), undef );
    is( $CLASS->get_shortdate_f( '06-08-28' ), undef );
    is( $CLASS->get_shortdate_f( '20060828' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_sigdate_f
    can_ok( $CLASS, 'get_sigdate_f' );
    is( $CLASS->get_sigdate_f, undef );

    is( $CLASS->get_sigdate_f( '2006-08-28' ), undef );
    is( $CLASS->get_sigdate_f( '2006-8-28' ), undef );
    is( $CLASS->get_sigdate_f( '2006828' ), undef );
    is( $CLASS->get_sigdate_f( '2006-08' ), undef );
    is( $CLASS->get_sigdate_f( '06-08-28' ), undef );
    is( $CLASS->get_sigdate_f( '20060828' ), '08/28/06' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_name_f
    can_ok( $CLASS, 'get_name_f' );
    is( $CLASS->get_name_f, undef );

        $tmp = {
            lname       => 'Jones',
            name_suffix => 'Jr.',
            fname       => 'Mary',
            mname       => 'Pat.',
        };
    is( $CLASS->get_name_f( $tmp ), 'Jones Jr, Mary, P' );
        $tmp->{ mname } = 'P';
    is( $CLASS->get_name_f( $tmp ), 'Jones Jr, Mary, P' );
        $tmp->{ name_suffix } = undef;
    is( $CLASS->get_name_f( $tmp ), 'Jones, Mary, P' );
        $tmp->{ mname } = undef;
    is( $CLASS->get_name_f( $tmp ), 'Jones, Mary' );
        $tmp->{ fname } = undef;
    is( $CLASS->get_name_f( $tmp ), 'Jones' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_addr_f
    can_ok( $CLASS, 'get_addr_f' );
    is( $CLASS->get_addr_f, undef );

    is( $CLASS->get_addr_f( '123 N. Main St., #101' ), '123 N Main St 101' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_phone_f
    can_ok( $CLASS, 'get_phone_f' );
    is( $CLASS->get_phone_f, undef );

    is( $CLASS->get_phone_f( '(503) 555-6677' ), '(503) 5556677' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client_is_self
    can_ok( $CLASS, 'client_is_self' );
    
    ok( $CLASS->client_is_self );
    ok( $CLASS->client_is_self( '00' ) );
    is( $CLASS->client_is_self( '01' ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client_is_spouse
    can_ok( $CLASS, 'client_is_spouse' );
    is( $CLASS->client_is_spouse, undef );

    ok( $CLASS->client_is_spouse( '01' ) );
    is( $CLASS->client_is_spouse( '99' ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client_is_child
    can_ok( $CLASS, 'client_is_child' );
    is( $CLASS->client_is_child, undef );

    is( $CLASS->client_is_child( '01' ), 0 );
    ok( $CLASS->client_is_child( '19' ) );
    ok( $CLASS->client_is_child( '09' ) );
    ok( $CLASS->client_is_child( '10' ) );
    ok( $CLASS->client_is_child( '17' ) );
 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_married
    can_ok( $CLASS, 'is_married' );
    is( $CLASS->is_married, undef );

    is( $CLASS->is_married( 'Single' ), 0 );
    is( $CLASS->is_married( 'Married' ), 1 );
    # this one has the is_married flag left undefined in the test data, to test this
    is( $CLASS->is_married( 'Living - As - Married' ), undef );
    is( $CLASS->is_married( 'unrelated' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
