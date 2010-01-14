# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 138;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

use eleMentalClinic::ECS::ReadTA1;

our ($CLASS, $one, $tmp, $valid_data);
BEGIN {
    *CLASS = \'eleMentalClinic::ECS::ReadTA1';
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
    like( $one->config_file, qr/ta1.cf/ );
    like( $one->yaml_file, qr/read_ta1.yaml/ );

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
        get_orig_interchange_control_number
        get_orig_interchange_date
        get_orig_interchange_time
        get_interchange_ack_code
        get_interchange_note_code
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
        get_orig_functional_group_identifier_code
        get_orig_functional_group_control_number
        get_functional_group_response
    /) {
        can_ok( $one, $_ );
        is( $one->$_, undef );
    };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid_file
    can_ok( $one, 'valid_file' );

    throws_ok{ $one->valid_file } qr/required/;

    # these all pass because the test is very basic and only checks if it's a valid EDI file
    ok( $one->valid_file( 't/resource/sample_835.1.txt' ) );
    ok( $one->valid_file( 't/resource/sample_835.2.txt' ) );
    ok( $one->valid_file( 't/resource/sample_837.1.txt' ) );
    ok( $one->valid_file( 't/resource/sample_837.2.txt' ) );
    ok( $one->valid_file( 't/resource/sample_997.1.txt' ) );

    ok( $one->valid_file( 't/resource/sample_ta1.1.txt' ) );
    ok( $one->valid_file( 't/resource/sample_ta1.2.txt' ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# parse
    can_ok( $one, 'parse' );

    is( $one->parse, undef );

        $one->file( 't/resource/sample_ta1.1.txt' );
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

        $one->file( 't/resource/sample_ta1.1.txt' );
    ok( $one->get_raw_edi );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_edi_data
    can_ok( $one, 'get_edi_data' );
    
    is( $one->get_edi_data, undef );

        $one->file( 't/resource/sample_ta1.1.txt' );
        $one->parse;
        $one->get_edi_data;
    ok( $one->edi_data );
        
        #warn "\n";
        #warn Dumper $one->edi_data;
        $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });

    is( $one->get_sender_interchange_id, '00824' );
    is( $one->get_receiver_interchange_id, 'OR00000' );
    is( $one->get_interchange_date, '2006-06-29' );
    is( $one->get_interchange_time, '17:25' );
    is( $one->get_interchange_control_number, '000040072' );
    is( $one->get_orig_interchange_control_number, '000001002' );
    is( $one->get_orig_interchange_date, '2006-06-29' );
    is( $one->get_orig_interchange_time, '16:04' );
    is( $one->get_interchange_ack_code, 'A' );
    is( $one->get_interchange_note_code, '000' );
    is( $one->get_functional_group_count, 1 );
    is( $one->is_ack_requested, 0 );
    is( $one->is_production, 0 );
    is( $one->get_functional_identifier_code, 'FA' );
    is( $one->get_sender_code, '0012' );
    is( $one->get_receiver_code, 'OR00000' );
    is( $one->get_functional_group_date, '2006-06-29' );
    is( $one->get_functional_group_time, '17:25' );
    is( $one->get_group_control_number, '40071' );
    is( $one->get_transaction_set_count, 1 );
    is( $one->get_x12_version, '004010X098A1' );
    is( $one->composite_delimiter, '>' );
    is( $one->get_orig_functional_group_identifier_code, 'HC' );
    is( $one->get_orig_functional_group_control_number, '3001' );
    is_deeply( $one->get_functional_group_response, {
        ack_code    => 'R',
        number_transaction_sets_included => 1,
        number_transaction_sets_received => 1,
        number_transaction_sets_accepted => 0,
        syntax_error_codes      => [ 2, undef, undef, undef, undef ],
    } );

    is( $valid_data->get_byname( '_interchange_ack_codes', $one->get_interchange_ack_code )->{ description },
        'The Transmitted Interchange Control Structure Header and Trailer Have Been Received and Have No Errors.' );
    is( $valid_data->get_byname( '_interchange_note_codes', $one->get_interchange_note_code )->{ description },
        'No error' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test that we have valid_data for the codes we are sent
# and show how the data is used


        # test the functional group errors
    is( $valid_data->get_byname( '_functional_group_ack_codes', $one->get_functional_group_response->{ ack_code } )->{ description },
        'Rejected' );

        my @errors = (
            'Functional Group Version Not Supported',
        );
        my $codes = $one->get_functional_group_response->{ syntax_error_codes };
    is( $valid_data->get_byname( '_functional_group_errors', $codes->[0] )->{ description }, $errors[0] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_edi_data again, with a different sample
        $one = $CLASS->new;

    is( $one->get_edi_data, undef );

        $one->file( 't/resource/sample_ta1.2.txt' );
        $one->parse;
        $one->get_edi_data;
    ok( $one->edi_data );
        
    is( $one->get_sender_interchange_id, '00824' );

    is( $one->get_receiver_interchange_id, 'OR00000' );
    is( $one->get_interchange_date, '2006-06-29' );
    is( $one->get_interchange_time, '17:16' );
    is( $one->get_interchange_control_number, '000040029' );
    is( $one->get_orig_interchange_control_number, '000001002' );
    is( $one->get_orig_interchange_date, '2006-06-29' );
    is( $one->get_orig_interchange_time, '16:04' );
    is( $one->get_interchange_ack_code, 'R' );
    is( $one->get_interchange_note_code, '020' );
    is( $one->get_functional_group_count, 0 );
    is( $one->is_ack_requested, 0 );
    is( $one->is_production, 0 );
    is( $one->get_functional_identifier_code, undef );
    is( $one->get_sender_code, undef );
    is( $one->get_receiver_code, undef );
    is( $one->get_functional_group_date, undef );
    is( $one->get_functional_group_time, undef );
    is( $one->get_group_control_number, undef );
    is( $one->get_transaction_set_count, undef );
    is( $one->get_x12_version, undef );
    is( $one->composite_delimiter, '>' );
    is( $one->get_orig_functional_group_identifier_code, undef );
    is( $one->get_orig_functional_group_control_number, undef );
    is( $one->get_functional_group_response, undef );

    is( $valid_data->get_byname( '_interchange_ack_codes', $one->get_interchange_ack_code )->{ description }, 
        'The Transmitted Interchange Control Structure Header and Trailer are Rejected Because of Errors.'
    );

    is( $valid_data->get_byname( '_interchange_note_codes', $one->get_interchange_note_code )->{ description }, 
        'Invalid Test Indicator Value' 
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

