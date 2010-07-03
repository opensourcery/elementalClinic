# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 57;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Insurance::Authorization::Request';
    use_ok( $CLASS );
    $CLASSDATA = $client_insurance_authorization_request;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->empty );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'client_insurance_authorization_request');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [ qw/
        rec_id client_id client_insurance_authorization_id start_date end_date
        form provider_agency location diagnosis_primary diagnosis_secondary ohp
        medicare general_fund ohp_id medicare_id general_fund_id date_requested
    /]);
    is_deeply( $one->fields_required, [ qw/
        client_id start_date
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client_insurance_authorization
        $one = $CLASS->empty;
    can_ok( $one, 'client_insurance_authorization' );
    throws_ok{ $one->write } qr/required/;

        $one = $CLASS->new({
            client_id   => 1004,
            start_date  => '2006-11-21',
        });
        $one->client_insurance_authorization_id( 1009 );
    is_deeply( $one->client_insurance_authorization,
        $client_insurance_authorization->{ 1009 }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write
        $one = $CLASS->new({
            client_id   => 1004,
            start_date  => '2006-11-21',
            date_requested => '2006-11-29',
        });
    can_ok( $one, 'write' );
    throws_ok{ $one->write } qr/required/;

        $one->form( 'wacoauth' );
    throws_ok{ $one->write } qr/required/;

        $one->end_date( '2006-05-21' );
    ok( $one->populate );
    ok( $tmp = $one->write );
    like( $tmp, qr/Client1004Auth112106-052106.pdf/ );
    is_pdf_file($tmp);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save and write again
        $tmp = $one->save;
        $one = $CLASS->retrieve( $tmp->id );
    ok( $tmp = $one->write );
    like( $tmp, qr/Client1004Auth112106-052106.pdf/ );
    is_pdf_file($tmp);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# date_requested
    is( $one->date_requested, '2006-11-29' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# format_date
    can_ok( $one, 'format_date' );

        $one = $CLASS->empty;
    is( $one->format_date, undef );
    is( $one->format_date( '2006-11-21' ), 'November 21st, 2006' );
    is( $one->format_date( '2007-9-10' ), 'September 10th, 2007' );
    is( $one->format_date( '07-9-10' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# filename
        $one = $CLASS->new({
            client_id   => 1004,
            start_date  => '2006-11-21',
        });
    can_ok( $one, 'filename' );
    throws_ok{ $one->filename } qr/required/;

        $one->end_date( '2006-05-21' );
    is( $one->filename, "Client1004Auth112106-052106.pdf" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# populate
    can_ok( $one, 'populate' );

        $one = $CLASS->empty;
    is( $one->populate, undef );
    is( $one->location, undef );

        $one = $CLASS->new({
            client_id   => 1004,
            start_date  => '2006-11-21',
        });
    ok( $one->populate );

    is( $one->diagnosis_primary, '292.89' );
    is( $one->diagnosis_secondary, '300.30' );
    is( $one->location, 'Substance abuse' );
    
    # no relationship
    is( $one->ohp, undef ); 
    is( $one->ohp_id, undef );
    
    # relationship not active
    is( $one->general_fund, undef );
    is( $one->general_fund_id, undef );

    is( $one->medicare, 1 );
    is( $one->medicare_id, '543210000A' );

        $one = $CLASS->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diagnoses
        $one = $CLASS->new({
            client_id   => 1004,
            start_date  => '2006-11-21',
        });
        $one->populate;
    is( $one->diagnosis_primary, '292.89' );
    is( $one->diagnosis_secondary, '300.30' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_diagnoses
        $one = $CLASS->empty;
    can_ok( $one, 'get_diagnoses' );
    throws_ok{ $one->get_diagnoses } qr/required/;

        $one = $CLASS->new({
            client_id   => 1004,
            start_date  => '2006-11-21',
        });
    is_deeply( $one->get_diagnoses, [ '292.89', '300.30' ]);

        # fix the data so that there is only one diagnosis,
        # testing that it returns just one
        $tmp = eleMentalClinic::Client::Diagnosis->retrieve( 1008 );
        $tmp->{ diagnosis_1b } = undef;
        $tmp->save;

    is_deeply( $one->get_diagnoses, [ '292.89', undef ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_location
        $one = $CLASS->empty;
    can_ok( $one, 'get_location' );
    throws_ok{ $one->get_location } qr/required/;

        $one = $CLASS->new({
            client_id   => 1004,
            start_date  => '2006-11-21',
        });
    is( $one->get_location, 'Substance abuse' );

        $one->{ client_id } = 1002;
    is( $one->get_location, undef );

        $one->{ client_id } = 1006;
    is( $one->get_location, 'Inpatient' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
