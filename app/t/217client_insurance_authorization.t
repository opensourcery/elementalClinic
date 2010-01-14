# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 102;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Department;

our ($CLASS, $CLASSDATA, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Insurance::Authorization';
    use_ok( $CLASS );
    $CLASSDATA = $fixtures->{'client_insurance_authorization'};
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'client_insurance_authorization');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_insurance_id allowed_amount
        code type start_date end_date
        capitation_amount capitation_last_date
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client
    can_ok( $one, 'client_id' );
    is_deeply( $CLASS->retrieve( 1001 )->client_id, 1003 );
    is_deeply( $CLASS->retrieve( 1002 )->client_id, 1003 );
    is_deeply( $CLASS->retrieve( 1003 )->client_id, 1003 );
    is_deeply( $CLASS->retrieve( 1004 )->client_id, 1003 );
    is_deeply( $CLASS->retrieve( 1005 )->client_id, 1003 );
    is_deeply( $CLASS->retrieve( 1006 )->client_id, 1003 );
    is_deeply( $CLASS->retrieve( 1007 )->client_id, 1003 );
    is_deeply( $CLASS->retrieve( 1008 )->client_id, 1004 );
    is_deeply( $CLASS->retrieve( 1009 )->client_id, 1004 );
    is_deeply( $CLASS->retrieve( 1010 )->client_id, 1004 );
    is_deeply( $CLASS->retrieve( 1011 )->client_id, 1005 );
    is_deeply( $CLASS->retrieve( 1012 )->client_id, 1005 );
    is_deeply( $CLASS->retrieve( 1013 )->client_id, 1005 );
    is_deeply( $CLASS->retrieve( 1014 )->client_id, 1005 );
    is_deeply( $CLASS->retrieve( 1015 )->client_id, 1004 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prognotes
    can_ok( $one, 'prognotes' );
    is_deeply( $CLASS->retrieve( 1001 )->prognotes, [
        $prognote->{ 1010 },
    ]);
    is( $CLASS->retrieve( 1002 )->prognotes, undef );
    is( $CLASS->retrieve( 1003 )->prognotes, undef );
    is_deeply( $CLASS->retrieve( 1004 )->prognotes, [
        $prognote->{ 1445 },
        $prognote->{ 1444 },
        $prognote->{ 1245 },
        $prognote->{ 1243 },
        $prognote->{ 1244 },
        $prognote->{ 1055 },
        $prognote->{ 1054 },
        $prognote->{ 1053 },
        $prognote->{ 1052 },
        $prognote->{ 1351 },
        $prognote->{ 1051 },
        $prognote->{ 1350 },
        $prognote->{ 1050 },
        $prognote->{ 1049 },
        $prognote->{ 1048 },
        $prognote->{ 1047 },
        $prognote->{ 1046 },
        $prognote->{ 1045 },
        $prognote->{ 1044 },
        $prognote->{ 1145 },
        $prognote->{ 1043 },
        $prognote->{ 1143 },
        $prognote->{ 1144 },
    ]);
    is( $CLASS->retrieve( 1005 )->prognotes, undef );
    is( $CLASS->retrieve( 1006 )->prognotes, undef );
    is_deeply( $CLASS->retrieve( 1007 )->prognotes, [
        $prognote->{ 1445 },
        $prognote->{ 1444 },
        $prognote->{ 1245 },
        $prognote->{ 1243 },
        $prognote->{ 1244 },
        $prognote->{ 1055 },
        $prognote->{ 1054 },
        $prognote->{ 1053 },
        $prognote->{ 1052 },
        $prognote->{ 1351 },
        $prognote->{ 1051 },
        $prognote->{ 1350 },
        $prognote->{ 1050 },
        $prognote->{ 1049 },
        $prognote->{ 1048 },
        $prognote->{ 1047 },
        $prognote->{ 1046 },
        $prognote->{ 1045 },
        $prognote->{ 1044 },
        $prognote->{ 1145 },
        $prognote->{ 1043 },
        $prognote->{ 1143 },
        $prognote->{ 1144 },
    ]);
    is( $CLASS->retrieve( 1008 )->prognotes, undef );
    is_deeply( $CLASS->retrieve( 1009 )->prognotes, [
        $prognote->{ 1260 },
        $prognote->{ 1258 },
        $prognote->{ 1257 },
        $prognote->{ 1259 },
        $prognote->{ 1064 },
        $prognote->{ 1063 },
        $prognote->{ 1062 },
        $prognote->{ 1061 },
        $prognote->{ 1060 },
        $prognote->{ 1059 },
        $prognote->{ 1058 },
        $prognote->{ 1158 },
        $prognote->{ 1057 },
        $prognote->{ 1157 },
        $prognote->{ 1159 },
        $prognote->{ 1056 },
    ]);
    is( $CLASS->retrieve( 1010 )->prognotes, undef );
    is( $CLASS->retrieve( 1011 )->prognotes, undef );
    is( $CLASS->retrieve( 1012 )->prognotes, undef );
    is_deeply( $CLASS->retrieve( 1013 )->prognotes, [
        $prognote->{ 1068 },
        $prognote->{ 1067 },
        $prognote->{ 1066 },
        $prognote->{ 1065 },
        $prognote->{ 1042 },
    ]);
    is_deeply( $CLASS->retrieve( 1014 )->prognotes, [
        $prognote->{ 1068 },
        $prognote->{ 1067 },
    ]);
    is( $CLASS->retrieve( 1015 )->prognotes, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# authorization request
        $one = $CLASS->new;
    can_ok( $one, 'authorization_request' );
    throws_ok{ $one->authorization_request } qr/Must/;

        $one = $CLASS->retrieve( 1004 );
    is( $one->authorization_request, undef );

        eleMentalClinic::Client::Insurance::Authorization::Request->new({
            client_id   => 1003,
            start_date  => '2006-12-15',
            client_insurance_authorization_id   => 1004, 
        })->save;
    ok( $one->authorization_request );
    isa_ok( $one->authorization_request, 'eleMentalClinic::Client::Insurance::Authorization::Request' );
    is( $one->authorization_request->client_insurance_authorization_id, 1004 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client insurance
        $one = $CLASS->new;
    can_ok( $one, 'client_insurance' );
    throws_ok{ $one->client_insurance } qr/stored/;

    is_deeply( $CLASS->retrieve( 1001 )->client_insurance, $client_insurance->{ 1003 });
    is_deeply( $CLASS->retrieve( 1005 )->client_insurance, $client_insurance->{ 1004 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get by client insurance
# XXX: these tests are date-dependent. Expect to modify them in the
#      new year.
        $one = $CLASS->new;
    can_ok( $CLASS, 'get_by_client_insurance' );
    is( $CLASS->get_by_client_insurance, undef );

    is( $CLASS->get_by_client_insurance, undef );

    is_deeply( $CLASS->get_by_client_insurance( 1003, '2007-01-01' ), 
        $CLASSDATA->{ 1004 },
    );
    is_deeply( $CLASS->get_by_client_insurance( 1003, '2006-07-01' ), 
        $CLASSDATA->{ 1004 },
    );
    is_deeply( $CLASS->get_by_client_insurance( 1003, '2005-07-01' ), 
        $CLASSDATA->{ 1003 },
    );
    is( $CLASS->get_by_client_insurance( 1003, '2000-07-01' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get all by client insurance
        $one = $CLASS->new;
    can_ok( $CLASS, 'get_all_by_client_insurance' );
    is( $CLASS->get_all_by_client_insurance, undef );

    is_deeply( $CLASS->get_all_by_client_insurance( 1003 ), [
        $CLASSDATA->{ 1017 },
        $CLASSDATA->{ 1004 },
        $CLASSDATA->{ 1003 },
        $CLASSDATA->{ 1002 },
        $CLASSDATA->{ 1001 },
    ]);
    # legacy: date should be ignored
    is_deeply( $CLASS->get_all_by_client_insurance( 1003, '2000-01-01' ), [
        $CLASSDATA->{ 1017 },
        $CLASSDATA->{ 1004 },
        $CLASSDATA->{ 1003 },
        $CLASSDATA->{ 1002 },
        $CLASSDATA->{ 1001 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_active
# XXX: these tests are date-dependent. expect to modify them
#      in the new year.
    can_ok( $one, 'is_active' );
    is( $CLASS->retrieve( 1001 )->is_active, 0 );
    is( $CLASS->retrieve( 1002 )->is_active, 0 );
    is( $CLASS->retrieve( 1003 )->is_active, 0 );
    is( $CLASS->retrieve( 1004 )->is_active, 0 );
    is( $CLASS->retrieve( 1005 )->is_active, 0 );
    is( $CLASS->retrieve( 1006 )->is_active, 0 );
    is( $CLASS->retrieve( 1007 )->is_active, 0 );
    is( $CLASS->retrieve( 1008 )->is_active, 0 );
    is( $CLASS->retrieve( 1009 )->is_active, 0 );
    is( $CLASS->retrieve( 1010 )->is_active, 0 );
    is( $CLASS->retrieve( 1011 )->is_active, 0 );
    is( $CLASS->retrieve( 1012 )->is_active, 0 );
    is( $CLASS->retrieve( 1013 )->is_active, 0 );
    is( $CLASS->retrieve( 1014 )->is_active, 0 );
    is( $CLASS->retrieve( 1015 )->is_active, 0 );
    is( $CLASS->retrieve( 1016 )->is_active, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# expire in month
# XXX should remain last, since it alters data

    can_ok( $CLASS, 'renewals_due_in_month' );
    throws_ok{ $CLASS->renewals_due_in_month } qr/required/;

    is( $CLASS->renewals_due_in_month( '2000-01-01' ), undef );
    is_deeply( $CLASS->renewals_due_in_month( '2006-01-01' ), [
        $CLASSDATA->{ 1003 },
        $CLASSDATA->{ 1012 },
    ]);

    # alter data for tests below
    $CLASS->retrieve( 1001 )->end_date( '2006-05-30' )->save; # DO NOT pick up for June
    $CLASS->retrieve( 1004 )->end_date( '2006-05-31' )->save; # pick up for June
    $CLASS->retrieve( 1007 )->end_date( '2006-06-01' )->save; # pick up for June
    $CLASS->retrieve( 1009 )->end_date( '2006-06-15' )->save; # pick up for June
    $CLASS->retrieve( 1013 )->end_date( '2006-06-30' )->save; # DO NOT pick up for June
    $CLASS->retrieve( 1014 )->end_date( '2006-07-01' )->save; # DO NOT pick up for June
    is_deeply( ids( $CLASS->renewals_due_in_month( '2006-06-01' )),
        [ 1004, 1009, 1007, ]
    );

    # for specific insurers
    is( $CLASS->renewals_due_in_month( '2006-01-01', 666 ), undef );
    is_deeply( $CLASS->renewals_due_in_month( '2006-01-01', 1009 ), [
        $CLASSDATA->{ 1012 },
    ]);
    is_deeply( $CLASS->renewals_due_in_month( '2006-01-01', 1015 ), [
        $CLASSDATA->{ 1003 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing_services
        $one = $CLASS->new;
    can_ok( $one, 'billing_services' );

dbinit( 1 );
        $test->financial_setup( 1 );
        $test->financial_setup( 2 );
        $test->financial_setup( 3 );
        $test->financial_setup( 4 );

    is( $CLASS->retrieve( 1001 )->billing_services, undef );
    is( $CLASS->retrieve( 1002 )->billing_services, undef );
    is( $CLASS->retrieve( 1003 )->billing_services, undef );
    is_deeply( $CLASS->retrieve( 1004 )->billing_services, [
        eleMentalClinic::Financial::BillingService->retrieve( 1003 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1004 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1005 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1006 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1007 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1008 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1014 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1015 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1016 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1017 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1018 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1019 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1020 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1021 ),
    ]);
    is( $CLASS->retrieve( 1005 )->billing_services, undef );
    is( $CLASS->retrieve( 1006 )->billing_services, undef );
    is_deeply( $CLASS->retrieve( 1007 )->billing_services, [
        eleMentalClinic::Financial::BillingService->retrieve( 1013 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1027 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1028 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1029 ),
    ]);
    is( $CLASS->retrieve( 1008 )->billing_services, undef );
    is_deeply( $CLASS->retrieve( 1009 )->billing_services, [
        eleMentalClinic::Financial::BillingService->retrieve( 1009 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1010 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1011 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1012 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1022 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1023 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1024 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1025 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1026 ),
    ]);
    is( $CLASS->retrieve( 1010 )->billing_services, undef );
    is( $CLASS->retrieve( 1011 )->billing_services, undef );
    is( $CLASS->retrieve( 1012 )->billing_services, undef );
    is_deeply( $CLASS->retrieve( 1013 )->billing_services, [
        eleMentalClinic::Financial::BillingService->retrieve( 1001 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1002 ),
    ]);
    is( $CLASS->retrieve( 1014 )->billing_services, undef );
    is( $CLASS->retrieve( 1015 )->billing_services, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
