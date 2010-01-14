# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 125;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

use eleMentalClinic::ECS::Read997;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::ECS::Read997';
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
    like( $one->config_file, qr/997.cf/ );
    like( $one->yaml_file, qr/read_997.yaml/ );

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
        get_orig_functional_group_identifier_code
        get_orig_functional_group_control_number
        get_orig_transaction_set_identifier_code
        get_orig_transaction_set_control_number
        get_data_segment_notes
        get_transaction_response
        get_functional_group_response
    /) {
        can_ok( $one, $_ );
        is( $one->$_, undef );
    };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid_file
    can_ok( $one, 'valid_file' );

    throws_ok{ $one->valid_file } qr/required/;

    is( $one->valid_file( 't/resource/sample_835.1.txt' ), undef );
    is( $one->valid_file( 't/resource/sample_835.2.txt' ), undef );
    is( $one->valid_file( 't/resource/sample_837.1.txt' ), undef );
    is( $one->valid_file( 't/resource/sample_837.2.txt' ), undef );
    ok( $one->valid_file( 't/resource/sample_997.1.txt' ) );
    is( $one->valid_file( 't/resource/sample_ta1.1.txt' ), undef );
    is( $one->valid_file( 't/resource/sample_ta1.2.txt' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# parse
    can_ok( $one, 'parse' );

    is( $one->parse, undef );

        $one->file( 't/resource/sample_997.1.txt' );
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

        $one->file( 't/resource/sample_997.1.txt' );
    ok( $one->get_raw_edi );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_edi_data
    can_ok( $one, 'get_edi_data' );
    
    is( $one->get_edi_data, undef );

        $one->file( 't/resource/sample_997.1.txt' );
        $one->parse;
        $one->get_edi_data;
    ok( $one->edi_data );
        
        #warn "\n";
        #warn Dumper $one->edi_data;

    is( $one->get_sender_interchange_id, '00824' );
    is( $one->get_receiver_interchange_id, 'OR00000' );
    is( $one->get_interchange_date, '2006-06-29' );
    is( $one->get_interchange_time, '17:25' );
    is( $one->get_interchange_control_number, '000040072' );
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
    is( $one->get_transaction_set_identifier_code, '997' );
    is( $one->get_transaction_set_control_number, '0001' );
    is( $one->get_segment_count, 13 );
    is( $one->composite_delimiter, ':' );
    is( $one->get_orig_functional_group_identifier_code, 'HC' );
    is( $one->get_orig_functional_group_control_number, 1 );
    is( $one->get_orig_transaction_set_identifier_code, '837' );
    is( $one->get_orig_transaction_set_control_number, '0001' );
    is_deeply( $one->get_data_segment_notes, [ {
        identifier_code             => 'N4',
        position_in_transaction_set => 11,
        loop_identifier_code        => '2010AA',
        syntax_error_code           => 8,
        element_notes               => [ {
            element_position            => 2,
            component_position          => undef,
            reference_number            => 156,
            syntax_error_code           => 5,
            copy_of_bad_data_element    => 'OR',
        }, {
            element_position            => 3,
            component_position          => undef,
            reference_number            => 116,
            syntax_error_code           => 4,
            copy_of_bad_data_element    => 97215,
        }, ],
    }, {
        identifier_code             => 'REF',
        position_in_transaction_set => 12,
        loop_identifier_code        => '2010AA',
        syntax_error_code           => 1,
    }, {
        identifier_code             => 'NM1',
        position_in_transaction_set => 16,
        loop_identifier_code        => '2010BA',
        syntax_error_code           => 8,
        element_notes               => [ {
            element_position            => 4,
            component_position          => undef,
            reference_number            => 1036,
            syntax_error_code           => 4,
            copy_of_bad_data_element    => 'NICA',
        }, ],
    }, {
        identifier_code             => 'HI',
        position_in_transaction_set => 30,
        loop_identifier_code        => '2300',
        syntax_error_code           => 8,
        element_notes               => [ {
            element_position            => 1,
            component_position          => 2,
            reference_number            => 1271,
            syntax_error_code           => 7,
            copy_of_bad_data_element    => '29660',
        }, ],
    }, ] );

    is_deeply( $one->get_transaction_response, {
        ack_code    => 'R',
        syntax_error_codes      => [ 1, 3, 5, 6, 23 ],
    } );
        
    is_deeply( $one->get_functional_group_response, {
        ack_code    => 'R',
        number_transaction_sets_included => 1,
        number_transaction_sets_received => 1,
        number_transaction_sets_accepted => 0,
        syntax_error_codes      => [ 1, 2, 3, 5, 6 ],
    } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test that we have valid_data for the codes we are sent
# and show how the data is used

    ok( my $notes = $one->get_data_segment_notes );
        my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });

        # test the particular segment and element errors
        my $message;

        for my $note ( @$notes ) { 
            my $error = $valid_data->get_byname( '_segment_errors', $note->{ syntax_error_code } )->{ description };
            my $code  = $note->{ identifier_code };
            my $loop  = $note->{ loop_identifier_code };
            my $line  = $note->{ position_in_transaction_set } + 2;
            
            $message .= qq/
            ---------------------
            Segment error: $error
            In the [$code] segment, loop $loop, line $line./;

            for my $element ( @{ $note->{ element_notes } } ) {
                
                my $element_error = $valid_data->get_byname( '_element_errors', $element->{ syntax_error_code } )->{ description };
                my $element_pos   = $element->{ element_position };
                $element_pos     .= " (composite item number $element->{ component_position })" if $element->{ component_position };
                my $ref           = $element->{ reference_number };
                my $data          = $element->{ copy_of_bad_data_element };

                $message .= qq/
                -- Error in element $element_pos: $element_error
                Element reference number: $ref.
                Copy of the data sent: [$data]/;
            }
        }

    is( $message, qq/
            ---------------------
            Segment error: Segment Has Data Element Errors
            In the [N4] segment, loop 2010AA, line 13.
                -- Error in element 2: Data element too long.
                Element reference number: 156.
                Copy of the data sent: [OR]
                -- Error in element 3: Data element too short.
                Element reference number: 116.
                Copy of the data sent: [97215]
            ---------------------
            Segment error: Unrecognized segment ID
            In the [REF] segment, loop 2010AA, line 14.
            ---------------------
            Segment error: Segment Has Data Element Errors
            In the [NM1] segment, loop 2010BA, line 18.
                -- Error in element 4: Data element too short.
                Element reference number: 1036.
                Copy of the data sent: [NICA]
            ---------------------
            Segment error: Segment Has Data Element Errors
            In the [HI] segment, loop 2300, line 32.
                -- Error in element 1 (composite item number 2): Invalid code value.
                Element reference number: 1271.
                Copy of the data sent: [29660]/ );

        # test the transaction set errors
    is( $valid_data->get_byname( '_transaction_set_ack_codes', $one->get_transaction_response->{ ack_code } )->{ description },
        'Rejected' );

        my @errors = (
            'Transaction Set Not Supported',
            'Transaction Set Control Number in Header and Trailer Do Not Match',
            'One or More Segments in Error',
            'Missing or Invalid Transaction Set Identifier',
            'Transaction Set Control Number Not Unique within the Functional Group',
        );
        my $codes = $one->get_transaction_response->{ syntax_error_codes };
    is( $valid_data->get_byname( '_transaction_set_errors', $codes->[$_] )->{ description }, $errors[$_] )
        for 0 .. 4;

        # test the functional group errors
    is( $valid_data->get_byname( '_functional_group_ack_codes', $one->get_functional_group_response->{ ack_code } )->{ description },
        'Rejected' );

        @errors = (
            'Functional Group Not Supported',
            'Functional Group Version Not Supported',
            'Functional Group Trailer Missing',
            'Number of Included Transaction Sets Does Not Match Actual Count',
            'Group Control Number Violates Syntax',
        );
        $codes = $one->get_functional_group_response->{ syntax_error_codes };
    is( $valid_data->get_byname( '_functional_group_errors', $codes->[$_] )->{ description }, $errors[$_] )
        for 0 .. 4;


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

