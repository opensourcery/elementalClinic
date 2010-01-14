# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 74;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Department';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->insert_data;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid_data
    can_ok( $one, 'valid_data');
        $tmp = $one->valid_data;
    isa_ok( $tmp, 'eleMentalClinic::ValidData' );
    is( $tmp->{ dept_id }, 1001 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, '' );
    is( $one->primary_key, '');
    is_deeply( $one->fields, [ ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# earliest_prognote
# more thorough tests in prognote.t
    can_ok( $one, 'earliest_prognote' );
    is_deeply( $one->earliest_prognote, $prognote->{ 1008 });
    isa_ok( $one->earliest_prognote, 'eleMentalClinic::ProgressNote' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_writers
    can_ok( $one, 'get_writers' );
    is( @{ $one->get_writers }, 5 );
    is_deeply(
        [ sort map { $_->staff_id } @{ $one->get_writers } ],
        [
            1,
            1000,
            1001,
            1002,
            1003,
        ]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_service_coordinators
    can_ok( $one, 'get_service_coordinators' );
    is( @{ $one->get_service_coordinators }, 5 );
    is_deeply(
        { %{ $one->get_service_coordinators->[ 1 ] } },
        { %{$personnel->{ 1002 }} }
    );
    is_deeply(
        { %{ $one->get_service_coordinators->[ 2 ] } },
        { %{$personnel->{ 1005 }} }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dsm4_axis1 and dsm4_axis2
    can_ok( $one, 'dsm4_axis1' );
    is( ref( $one->dsm4_axis1 ), 'ARRAY' );
    can_ok( $one, 'dsm4_axis2' );
    is( ref( $one->dsm4_axis2 ), 'ARRAY' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_supervisors
    can_ok( $one, 'get_supervisors' );

    is( @{ $one->get_supervisors }, 3 );
    isa_ok( $_, 'eleMentalClinic::Personnel' )
        for @{ $one->get_supervisors };

    is( $one->get_supervisors->[ 1 ]->{ staff_id }, 1005 );
    is( $one->get_supervisors->[ 0 ]->{ staff_id }, 1000 );
    is( $one->get_supervisors->[ 2 ]->{ staff_id }, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_financial_personnel
    can_ok( $one, 'get_financial_personnel' );

    is( @{ $one->get_financial_personnel }, 2 );
    isa_ok( $_, 'eleMentalClinic::Personnel' )
        for @{ $one->get_financial_personnel };

    is_deeply( $one->get_financial_personnel->[ 0 ]->{ staff_id }, 1005 );
    is_deeply( $one->get_financial_personnel->[ 1 ]->{ staff_id }, 1004 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# programs
    is( scalar @{ $one->list_programs }, 6 );
    is( scalar @{ $one->list_programs( 'admission' )}, 5 );
    is( scalar @{ $one->list_programs( 'referral' )}, 1 );

    # no arguments
    is_deeply( $one->list_programs->[ 0 ], {
        %{ $valid_data_program->{ 1002 }},
        full_name   => "($$valid_data_program{ 1002 }{ number }) $$valid_data_program{ 1002 }{ name }",
    });

    is_deeply( $one->list_programs->[ 1 ], {
        %{ $valid_data_program->{ 1003 }},
        full_name   => "($$valid_data_program{ 1003 }{ number }) $$valid_data_program{ 1003 }{ name }",
    });
    is( $one->list_programs->[ 3 ]->{ rec_id }, 1 );
    is( $one->list_programs->[ 3 ]->{ name }, 'Referral' );
    is( $one->list_programs->[ 3 ]->{ is_referral }, 1 );
    is_deeply( $one->list_programs->[ 2 ], {
        %{ $valid_data_program->{ 1004 }},
        full_name   => "($$valid_data_program{ 1004 }{ number }) $$valid_data_program{ 1004 }{ name }",
    });
    is_deeply( $one->list_programs->[ 4 ], {
        %{ $valid_data_program->{ 1001 }},
        full_name   => "($$valid_data_program{ 1001 }{ number }) $$valid_data_program{ 1001 }{ name }",
    });

    # referral
    is( $one->list_programs( 'referral' )->[ 0 ]->{ rec_id }, 1 );
    is( $one->list_programs( 'referral' )->[ 0 ]->{ name }, 'Referral' );
    is( $one->list_programs( 'referral' )->[ 0 ]->{ is_referral }, 1 );
    is( $one->list_programs( 'referral' )->[ 0 ]->{ full_name }, '(100) Referral' );

    # admission
    is_deeply( $one->list_programs( 'admission' )->[ 0 ], {
        %{ $valid_data_program->{ 1002 }},
        full_name   => "($$valid_data_program{ 1002 }{ number }) $$valid_data_program{ 1002 }{ name }",
    });
    is_deeply( $one->list_programs( 'admission' )->[ 1 ], {
        %{ $valid_data_program->{ 1003 }},
        full_name   => "($$valid_data_program{ 1003 }{ number }) $$valid_data_program{ 1003 }{ name }",
    });
    is_deeply( $one->list_programs( 'admission' )->[ 2 ], {
        %{ $valid_data_program->{ 1004 }},
        full_name   => "($$valid_data_program{ 1004 }{ number }) $$valid_data_program{ 1004 }{ name }",
    });
    is_deeply( $one->list_programs( 'admission' )->[ 3 ], {
        %{ $valid_data_program->{ 1001 }},
        full_name   => "($$valid_data_program{ 1001 }{ number }) $$valid_data_program{ 1001 }{ name }",
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# expired claims processor credentials
        $one->config->save({ cp_credentials_expire_warning => 10 });
    is( $one->config->cp_credentials_expire_warning, 10 );

    can_ok( $one, 'claims_processors_with_expired_credentials' );
    is_deeply( $one->claims_processors_with_expired_credentials, [
        $claims_processor->{ 1003 },
        $claims_processor->{ 1001 },
        $claims_processor->{ 1002 },
    ]);
    is( $one->claims_processors_with_expired_credentials( '2005-12-31' ), undef );

    # save config
        $one->config->save({ cp_credentials_expire_warning => 300 });
    is_deeply( $one->claims_processors_with_expired_credentials( '2005-12-31' ), [
        $claims_processor->{ 1003 },
        $claims_processor->{ 1001 },
        $claims_processor->{ 1002 },
    ]);
    is_deeply( $one->claims_processors_with_expired_credentials( '2005-07-31' ), [
        $claims_processor->{ 1003 },
        $claims_processor->{ 1001 },
    ]);

        eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1001 )->password_expires( '2100-01-01' )->save;
    is_deeply( $one->claims_processors_with_expired_credentials, [
        $claims_processor->{ 1003 },
        $claims_processor->{ 1002 },
    ]);

    is_deeply( $one->claims_processors_with_expired_credentials( '2100-02-01' ), [
        $claims_processor->{ 1003 },
        $claims_processor->{ 1002 },
        { %{ $claims_processor->{ 1001 }}, password_expires => '2100-01-01' },
    ]);
    is_deeply( $one->claims_processors_with_expired_credentials( '2099-01-01' ), [
        $claims_processor->{ 1003 },
        $claims_processor->{ 1002 },
    ]);
    is_deeply( $one->claims_processors_with_expired_credentials( '2099-06-01' ), [
        $claims_processor->{ 1003 },
        $claims_processor->{ 1002 },
        { %{ $claims_processor->{ 1001 }}, password_expires => '2100-01-01' },
    ]);

        $one->config->save({ cp_credentials_expire_warning => 10 });
        eleMentalClinic::Financial::ClaimsProcessor->retrieve( 1001 )->password_expires( '2100-01-31' )->save;
    is_deeply( $one->claims_processors_with_expired_credentials( '2100-01-20' ), [
        $claims_processor->{ 1003 },
        $claims_processor->{ 1002 },
    ]);
    is_deeply( $one->claims_processors_with_expired_credentials( '2100-01-21' ), [
        $claims_processor->{ 1003 },
        $claims_processor->{ 1002 },
        { %{ $claims_processor->{ 1001 }}, password_expires => '2100-01-31' },
    ]);

        $one->config->save({ cp_credentials_expire_warning => 10 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# deferred_log
    can_ok( $one, 'deferred_log' );

    is( $one->deferred_log, undef );
    
    ok( eleMentalClinic::Log::Log_defer( 'Save this error for a later time' ) );
    is( $one->deferred_log, 'Save this error for a later time' );

    ok( eleMentalClinic::Log::Log_defer( 'And this one' ) );
    is( $one->deferred_log, 'Save this error for a later timeAnd this one' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
