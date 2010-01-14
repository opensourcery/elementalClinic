# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 55;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
our $BILLING_FILE_REC_ID = 1002;
our $DATE_STAMP = '20060629';
our $MMDD_STAMP = '0629';
our $TIME_STAMP = '1604';

BEGIN {
    *CLASS = \'eleMentalClinic::Financial::WriteClaim';
    use_ok( $CLASS );
}

# Turn off the warnings coming from validation during financial setup.
$eleMentalClinic::Base::TESTMODE = 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test BillingFile object initialization
        my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $BILLING_FILE_REC_ID );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    throws_ok { $one = $CLASS->new } qr/Missing required field/;
    throws_ok { $one = $CLASS->new( { billing_file => 'foo' } ) }
        qr/billing_file parameter is not an eleMentalClinic::Financial::BillingFile\./;
    ok( $one = $CLASS->new( { billing_file => $billing_file } ) );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# date_stamp and time_stamp
#   have defaults
    ok( $one->date_stamp );
    ok( $one->time_stamp );
#   and can be set in the constructor
        $one = $CLASS->new( { 
            billing_file => $billing_file,
            date_stamp => $DATE_STAMP,
            time_stamp => $TIME_STAMP,
        });
    is( $one->date_stamp, $DATE_STAMP );
    is( $one->time_stamp, $TIME_STAMP );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    throws_ok { $one->make_filename } qr/must override/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    throws_ok { $one->write } qr/must override/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_gender_f
    can_ok( $one, 'get_gender_f' );
    is( $CLASS->get_gender_f, undef );

    is( $CLASS->get_gender_f( 'Female' ), 'F' );
    is( $CLASS->get_gender_f( 'Male' ), 'M' );
    is( $CLASS->get_gender_f( 'Trans' ), 'U' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_insurance_rank_f
    can_ok( $one, 'get_insurance_rank_f' );
    is( $CLASS->get_insurance_rank_f, undef );

    is( $CLASS->get_insurance_rank_f( 1 ), 'P' );
    is( $CLASS->get_insurance_rank_f( 2 ), 'S' );
    is( $CLASS->get_insurance_rank_f( 3 ), 'T' );
    is( $CLASS->get_insurance_rank_f( 4 ), 'T' );

    is( $CLASS->get_insurance_rank_f( 12 ), undef );
    is( $CLASS->get_insurance_rank_f( 'P' ), undef );
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# split_charge_code
    can_ok( $CLASS, 'split_charge_code' );
    throws_ok { $CLASS->split_charge_code } qr/code is required and must include at least 5 characters/;
        
    is_deeply([ $CLASS->split_charge_code( '90806' )],      [ '90806', undef ]);
    is_deeply([ $CLASS->split_charge_code( '90847HK' )],    [ '90847', [ 'HK', ] ]);
    is_deeply([ $CLASS->split_charge_code( 'T1016 HN' )],   [ 'T1016', [ 'HN', ] ]);
    is_deeply([ $CLASS->split_charge_code( 'T1013' )],      [ 'T1013', undef ]);
    throws_ok{ $CLASS->split_charge_code( 'N/A' ) } qr/code is required and must include at least 5 characters/;
    throws_ok{ $CLASS->split_charge_code( 'No Show' ) } qr/code is required and must include at least 5 characters/;

    # XXX This isn't a real charge code, but I've seen it in the live database
    # There's no good way to tell that it's not real, unless we hard code it in - do we need to?
    is_deeply([ $CLASS->split_charge_code( 'TransHous' )], [ 'Trans', [ 'Ho', 'us', ]]);

    # if this goes into an infinite loop, you may assume the test has failed
    is_deeply([ $CLASS->split_charge_code( 'AbcdeFgh' )], [ 'Abcde', [ 'Fg' ]]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate
    can_ok( $one, 'validate' );
    is( $one->validate, undef );

        # set up the length rules
        $one->valid_lengths( {
            charge_amount => '3, 5',
            service_date  => '1, 5',
            diagnosis_code_pointers => '1, 2',
            modifiers       => '1, 2',
            prognote_id     => '1, 5',
            service         => '1, 5',
            units           => '1, 5',
        });

        # good data: test that it is not altered
        my $good = {
            charge_amount   => '00005',
            service_date    => '00005',
            diagnosis_code_pointers => [ '00', '11', '22', '1', '4' ],
            facility_code   => '00',
            modifiers       => [ '00' ],
            prognote_id     => '0004',
            service         => '00005',
            units           => '00005'
        };

    is_deeply( $one->validate( $good ), $good );

        # data with each field going over the max length by one
        # (data that is not used (and therefore not validated) is left alone)
        my $over = {
            charge_amount   => '000050000500005000X',
            service_date    => '00005000050000500005000050000500005X',
            diagnosis_code_pointers => [ '00X', '11', '22XX', '', '4' ],
            facility_code   => '00X',
            modifiers       => [ '00X' ],
            prognote_id     => '000050000500005000050000500005X',
            service         => '000050000500005000050000500005000050000500005000X',
            units           => '000050000500005X'
        };

        my $truncated = {
            charge_amount   => '00005',
            service_date    => '00005',
            diagnosis_code_pointers => [ '00', '11', '22', '', '4' ],
            facility_code   => '00X',
            modifiers       => [ '00' ],
            prognote_id     => '00005',
            service         => '00005',
            units           => '00005'
        };

    is_deeply( $one->validate( $over ), $truncated );
        
        # good data with one field that's under its minimum
        $good->{ charge_amount } = '12';
    $eleMentalClinic::Base::TESTMODE = 0;
    throws_ok { $one->validate( $good ) } qr/charge_amount length must be at least 3 characters long./;
    $eleMentalClinic::Base::TESTMODE = 1;

    # TODO test required fields

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate_hash
    can_ok( $one, 'validate_hash' );
    is( $one->validate_hash, undef );

        # test with a different valid_lengths hash
        $one->valid_lengths( {
            charge_amount => '3, 5',
            service_date  => '1, 5',
            diagnosis_code_pointers => '1, 2',
            modifiers       => '1, 2',
            prognote_id     => '1, 5',
            service         => '1, 5',
            units           => '1, 5',
        });

        $tmp = {
            charge_amount   => '000050000500005000X',
            service_date    => '00005000050000500005000050000500005X',
            diagnosis_code_pointers => [ '00X', '11', '22XX', '', '4' ],
            facility_code   => '00X',
            modifiers       => [ '00X' ],
            prognote_id     => '000050000500005000050000500005X',
            service         => '000050000500005000050000500005000050000500005000X',
            units           => '000050000500005X'
        };

    is_deeply( $one->validate_hash( $tmp ), {
        charge_amount   => '00005',
        service_date    => '00005',
        diagnosis_code_pointers => [ '00', '11', '22', '', '4' ],
        facility_code   => '00X',
        modifiers       => [ '00' ],
        prognote_id     => '00005',
        service         => '00005',
        units           => '00005'
    });

        $tmp->{ charge_amount } = '12'; 
    $eleMentalClinic::Base::TESTMODE = 0;
    throws_ok { $one->validate( $tmp ) } qr/charge_amount length must be at least 3 characters long./;
    $eleMentalClinic::Base::TESTMODE = 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check_length
    can_ok( $one, 'check_length' );
    is( $one->check_length, undef );

    is( $one->check_length( 'charge_amount' ), undef ); 
    is( $one->check_length( 'charge_amount', '' ), '' ); 
    is( $one->check_length( 'charge_amount', '1234567890123456.89' ), '1234567890123456.89' );
    is( $one->check_length( 'charge_amount', '1234567890123456.89', 18 ), '1234567890123456.89' );
    is( $one->check_length( 'charge_amount', '1234567890123456.89', 0, 18 ), '1234567890123456.89' );
    is( $one->check_length( 'charge_amount', '', 1, 18 ), '' );
    is( $one->check_length( 'charge_amount', '133.65', 2, 18 ), '133.65' );
    is( $one->check_length( 'charge_amount', '1234567890123456.89', 2, 18 ), '1234567890123456.8' );

    $eleMentalClinic::Base::TESTMODE = 0;
    throws_ok { $one->check_length( 'charge_amount', 'X', 2, 18 ) } qr/charge_amount length must be at least 2 characters long./;
    $eleMentalClinic::Base::TESTMODE = 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
