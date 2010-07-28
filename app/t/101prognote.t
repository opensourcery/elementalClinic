# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use warnings;
use strict;

use Test::More tests => 656;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use POSIX qw(strftime);

our ($CLASS, $CLASSDATA, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::ProgressNote';
    use_ok( $CLASS );
    $CLASSDATA = $prognote;
}

# Turn off the warnings coming from validation during financial_setup.
$eleMentalClinic::Base::TESTMODE = 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    #$test->financial_delete_data;
    $test->db_refresh;
    shift and $test->insert_data;
}

dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'prognote');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id billing_status staff_id goal_id start_date end_date
        note_header note_body audit_trail charge_code_id outcome_rating writer
        note_committed note_location_id data_entry_id group_id created modified
        unbillable_per_writer bill_manually previous_billing_status
        digital_signature digital_signer
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

    # refactored out; want to make sure they stay dead
    ok( ! $one->can( $_ ))
        for qw/
            acct_id acronym active charge_date charge_staff charge_submit
            charge_time chart_id medicaid note_link timer
        /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_client_name

    $one = $CLASS->retrieve( 1001 );
    is( $one->get_client_name, 'Mingus, Charles' );
    $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_billed_by_client
    can_ok( $CLASS, 'get_billed_by_client' );
    throws_ok{ $CLASS->get_billed_by_client } qr/Client id is required/;

    is( $CLASS->get_billed_by_client( 1003 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billings
    can_ok( $CLASS, 'billings' );
    throws_ok{ $one->billings } qr/Must call on stored object/;

        $one = $CLASS->retrieve( 1043 );
    is_deeply( $one->billings, [] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# refund
        $test->financial_setup( 1 );
        $one = $CLASS->new;
    can_ok( $one, 'refund' );
    is( $one->refund, undef, 'nothing to do if no transactions');
        $one = eleMentalClinic::ProgressNote->retrieve(1043);
    ok( @{$one->valid_transactions} > 0, 'we must have at least one transaction' );
    ok( $one->refund, 'should return with no problems' );
    is_deeply( $one->valid_transactions, [], 'should no longer have valid transactions' );
        $one = $CLASS->new;

dbinit(1);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# calculate_units

        $one = eleMentalClinic::ProgressNote->retrieve(1001);
        is($one->units, 1.5);

        $one = eleMentalClinic::ProgressNote->retrieve(1002);
        is($one->units, 1);

        # 1003 has no insurance?
        $one = eleMentalClinic::ProgressNote->retrieve(1003);
        is($one->units, 0);

        # Round to 2 decimal places
        $one = eleMentalClinic::ProgressNote->retrieve(1042);
        is($one->units, 1.33);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# with payment data
        $test->financial_setup( 1 );
    is( scalar @{ $CLASS->get_billed_by_client( 1003 )}, 6 );
    is_deeply( ids( $CLASS->get_billed_by_client( 1003 )), [
        qw/ 1048 1047 1046 1045 1044 1043 /
    ]);

    is( $CLASS->get_billed_by_client( 1003, '1900-01-01', '1910-01-01' ), undef );
    is_deeply( ids( $CLASS->get_billed_by_client( 1003, '2006-07-01', '2006-07-10' )), [
        qw/ 1046 1045 1044 1043 /
    ]);

    is( scalar @{ $CLASS->retrieve( 1043 )->billings }, 1 );
    is_deeply( $CLASS->retrieve( 1043 )->billings, [
        {
            billed_date         =>  '2006-07-15',
            billed_amount       =>  124.64,
            prognote_id         =>  1043,
            billing_service_id  => 1003,
            insurance_rank      =>  1,
            paid_date           => '2006-08-31',
            paid_amount         => 7.48,
            refunded            => 0,
        },
    ]);

        $test->financial_setup( 2 );
    is( scalar @{ $CLASS->retrieve( 1043 )->billings }, 2 );
    is_deeply( $CLASS->retrieve( 1043 )->billings->[ 1 ], {
        billed_date         => '2006-08-31',
        billed_amount       => 124.64,
        prognote_id         => 1043,
        billing_service_id  => 1013,
        insurance_rank      =>  2,
        paid_date           => '2006-08-31',
        paid_amount         => 117.16,
        refunded            => 0,
    });

        $test->financial_setup( 3 );
    is( scalar @{ $CLASS->retrieve( 1051 )->billings }, 1 );
    is_deeply( $CLASS->retrieve( 1051 )->billings, [
        {
            billed_date         =>  '2006-08-15',
            billed_amount       =>  131.44,
            prognote_id         =>  1051,
            billing_service_id  => 1017,
            insurance_rank      =>  1,
            paid_date           => '2006-09-05',
            paid_amount         => '10.00',
            refunded            => 0,
        },
    ]);

        $test->financial_setup( 4 );
    is( scalar @{ $CLASS->retrieve( 1051 )->billings }, 2 );
    is_deeply( $CLASS->retrieve( 1051 )->billings->[ 1 ], {
        billed_date         =>  '2006-09-06',
        billed_amount       => 262.88,
        prognote_id         => 1051,
        billing_service_id  => 1028,
        insurance_rank      =>  2,
        paid_date           => '2006-09-15',
        paid_amount         => 152.88,
        refunded            => 0,
        combined            => 1,
    });
    is_deeply( $CLASS->retrieve( 1351 )->billings->[ 1 ], {
        billed_date         =>  '2006-09-06',
        billed_amount       => 262.88,
        prognote_id         => 1351,
        billing_service_id  => 1028,
        insurance_rank      =>  2,
        paid_date           => '2006-09-15',
        paid_amount         => 152.88,
        refunded            => 0,
        combined            => 1,
    });

        # make sure we still pick up the billings even when there's no payment
        dbinit( 1 );
        $test->financial_setup( 1, undef, { no_payment => 1 });
    is( scalar @{ $CLASS->retrieve( 1043 )->billings }, 1 );
    is_deeply( $CLASS->retrieve( 1043 )->billings, [
        {
            billed_date         =>  '2006-07-15',
            billed_amount       =>  124.64,
            prognote_id         =>  1043,
            billing_service_id  => 1003,
            insurance_rank      =>  1,
            paid_date           => undef,
            paid_amount         => undef,
            refunded            => undef,  # FIXME refunded usually returns 0
        },
    ]);

        # make sure billings that aren't billed yet are not picked up
        dbinit( 1 );
        my $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );
    is_deeply( $CLASS->retrieve( 1043 )->billings, [] );
    is( $CLASS->get_billed_by_client( 1003 ), undef );

        # test with refunded and entered_in_error transactions
        dbinit( 1 );
        $test->financial_setup( 1 );
        $test->financial_setup( 2 );
        eleMentalClinic::Financial::Transaction->retrieve( 1001 )->entered_in_error( 1 )->save;
        eleMentalClinic::Financial::Transaction->retrieve( 1011 )->refunded( 1 )->save;
    is( scalar @{ $CLASS->retrieve( 1043 )->billings }, 2 );
    is_deeply( $CLASS->retrieve( 1043 )->billings, [
        {
            billed_date         =>  '2006-07-15',
            billed_amount       =>  124.64,
            prognote_id         =>  1043,
            billing_service_id  => 1003,
            insurance_rank      =>  1,
            paid_date           => undef,
            paid_amount         => undef,
            refunded            => undef,
        },
        {
            billed_date         => '2006-08-31',
            billed_amount       =>  124.64,
            prognote_id         =>  1043,
            billing_service_id  => 1013,
            insurance_rank      =>  2,
            paid_date           => '2006-08-31',
            paid_amount         => 117.16,
            refunded            => 1,
        },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validation rules failed
# XXX this is tested more thoroughly in t/501validation_set, so we 
# don't have to create a full validation set here
    can_ok( $one, 'validation_rules_failed' );
    throws_ok{ $one->validation_rules_failed } qr/Validation set id is required/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bounce
        $one = $CLASS->new;
    can_ok( $one, 'bounce' );
    throws_ok{ $one->bounce } qr/Must call on existing progress note object/;

        $one = $CLASS->retrieve( 1043 );
    throws_ok{ $one->bounce } qr/Staff and message are required/;

        $one = $CLASS->new({ %{ $CLASSDATA->{ 1043 }}, rec_id => undef })->save;
    for( qw/ Billed Billing Paid Unbillable BilledManually /) {
        $one->billing_status( $_ )->save;
        throws_ok{ $one->bounce( eleMentalClinic::Personnel->retrieve( 1004 ), 'foo' )} qr/$_ notes cannot be bounced/;
    }
        $one->delete;

        $one = $CLASS->retrieve( 1043 );
    ok( $one->bounce( eleMentalClinic::Personnel->retrieve( 1004 ), 'Rules, rules, rules.' ));

#     throws_ok{ $one->bounce } qr/Note has an existing and active bounce record./;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bounced
        $one = $CLASS->new;
    can_ok( $one, 'bounced' );
    is( $one->bounced, undef );

        $one = $CLASS->retrieve( 1043 );
    ok( $one->bounced );
    isa_ok( $one->bounced, 'eleMentalClinic::ProgressNote::Bounced' );
    is( $one->bounced->prognote_id, 1043 );
    is( $one->bounced->bounced_by_staff_id, 1004 );
    is( $one->bounced->bounce_message, 'Rules, rules, rules.' );

        $one->bounced->delete;

    is( $CLASS->retrieve( 1243 )->bounced, undef );
    is( $CLASS->retrieve( 1244 )->bounced, undef );
    is_deeply( $CLASS->retrieve( 1245 )->bounced, $prognote_bounced->{ 1003 });
    is_deeply( $CLASS->retrieve( 1257 )->bounced, $prognote_bounced->{ 1004 } );
    is( $CLASS->retrieve( 1258 )->bounced, undef );
    is_deeply( $CLASS->retrieve( 1259 )->bounced, $prognote_bounced->{ 1006 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# note duration & pretty
        $one = $CLASS->new;
    can_ok( $one, 'note_duration' );
    is_deeply( $one->note_duration, [ 0,0,0 ]);
    is( $one->note_duration_pretty, '0:00' );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 7:00' );
    is_deeply( $one->note_duration, [ 0, -1, 0 ]);
    is( $one->note_duration_pretty, '0:00' );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 7:59' );
    is_deeply( $one->note_duration, [ 0, 0, -1 ]);
    is( $one->note_duration_pretty, '0:00' );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 8:00' );
    is_deeply( $one->note_duration, [ 0, 0, 0 ]);
    is( $one->note_duration_pretty, '0:00' );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 9:00' );
    is_deeply( $one->note_duration, [ 0, 1, 0 ]);
    is( $one->note_duration_pretty, '1:00' );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 8:59' );
    is_deeply( $one->note_duration, [ 0, 0, 59 ]);
    is( $one->note_duration_pretty, '0:59' );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-7 16:00' );
    is_deeply( $one->note_duration, [ 1, 8, 0 ]);
    is( $one->note_duration_pretty, '1d 8:00' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# note_duration_ok
    is( $one->config->prognote_min_duration_minutes, 1 );
    is( $one->config->prognote_max_duration_minutes, 480 );
    can_ok( $one, 'note_duration_ok' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# note_duration_ok
# methods with no parameters are using the config variables
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 1 ), undef );
    is( $one->note_duration_ok( undef, 1 ), undef );
    is( $one->note_duration_ok( 0, -1 ), undef );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 7:00' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 30 ), 0 );
    is( $one->note_duration_ok( 0, 60 ), 0 );
    is( $one->note_duration_ok( 0, 120 ), 0 );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 7:59' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 30 ), 0 );
    is( $one->note_duration_ok( 0, 60 ), 0 );
    is( $one->note_duration_ok( 0, 120 ), 0 );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-5 9:00' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 30 ), 0 );
    is( $one->note_duration_ok( 0, 60 ), 0 );
    is( $one->note_duration_ok( 0, 120 ), 0 );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 8:00' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 1 );
    is( $one->note_duration_ok( 0, 30 ), 1 );
    is( $one->note_duration_ok( 0, 60 ), 1 );
    is( $one->note_duration_ok( 0, 120 ), 1 );

        $one->start_date( '2005-5-6 8:00' );
        $one->end_date( '2005-5-6 8:30' );
    is( $one->note_duration_ok, 1 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 30 ), 1 );
    is( $one->note_duration_ok( 0, 60 ), 1 );
    is( $one->note_duration_ok( 0, 120 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-6 9:00' );
    is( $one->note_duration_ok, 1 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 30 ), 0 );
    is( $one->note_duration_ok( 0, 60 ), 1 );
    is( $one->note_duration_ok( 0, 120 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-6 12:00' );
    is( $one->note_duration_ok, 1 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 239 ), 0 );
    is( $one->note_duration_ok( 0, 240 ), 1 );
    is( $one->note_duration_ok( 0, 300 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-6 15:59' );
    is( $one->note_duration_ok, 1 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 420 ), 0 );
    is( $one->note_duration_ok( 0, 480 ), 1 );
    is( $one->note_duration_ok( 0, 540 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-6 16:00' );
    is( $one->note_duration_ok, 1 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 420 ), 0 );
    is( $one->note_duration_ok( 0, 480 ), 1 );
    is( $one->note_duration_ok( 0, 540 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-6 16:01' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 420 ), 0 );
    is( $one->note_duration_ok( 0, 480 ), 0 );
    is( $one->note_duration_ok( 0, 540 ), 1 );

        $one->start_date( '2000-5-6 8:00' );
        $one->end_date( '2000-5-7 8:00' );
    is( $one->note_duration_ok, 0 );
    is( $one->note_duration_ok( 0, 0 ), 0 );
    is( $one->note_duration_ok( 0, 1439 ), 0 );
    is( $one->note_duration_ok( 0, 1440 ), 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# init
    can_ok( $one, 'init' );
    is_deeply( $one->init, $one );

    is_deeply( $one->init({ note_date => '2005-05-05' }), $one );
    is_deeply( $one->init({ start_time => '8:00' }), $one );
    is_deeply( $one->init({ end_time => '9:00' }), $one ); 

    is_deeply( $one->init({
        start_time => '8:00',
        end_time => '9:00',
    }), $one ); 

    # TODO fix the warning that this incurrs
    is_deeply( $one->init({
        note_date => '2005-05-05',
        end_time => '9:00',
    }), $one ); 

    is_deeply( $one->init({
        note_date => '2005-05-05',
        start_time => '8:00',
    }), $one ); 

    is_deeply( $one->init({
        note_date => '2005-05-05',
        start_time => '8:00',
        end_time => '9:00',
    }), $one ); 
    is( $one->start_date, '2005-05-05 8:00' );
    is( $one->end_date, '2005-05-05 9:00' );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_all
    # TODO test no results are uncommitted group notes
    can_ok( $one, 'list_all' );
    is( @{ $one->list_all }, 91 );

    is_deeply( $one->list_all, [
        $prognote->{ 1646 },
        $prognote->{ 1647 },
        $prognote->{ 1648 },
        $prognote->{ 1649 },
        $prognote->{ 1650 },
        $prognote->{ 1651 },
        $prognote->{ 1260 },
        $prognote->{ 1445 },
        $prognote->{ 1258 },
        $prognote->{ 1257 },
        $prognote->{ 1259 },
        $prognote->{ 1444 },
        $prognote->{ 1245 },
        $prognote->{ 1243 },
        $prognote->{ 1244 },
        $prognote->{ 1055 },
        $prognote->{ 1064 },
        $prognote->{ 1054 },
        $prognote->{ 1063 },
        $prognote->{ 1053 },
        $prognote->{ 1068 },
        $prognote->{ 1052 },
        $prognote->{ 1062 },
        $prognote->{ 1351 },
        $prognote->{ 1051 },
        $prognote->{ 1061 },
        $prognote->{ 1350 },
        $prognote->{ 1050 },
        $prognote->{ 1067 },
        $prognote->{ 1049 },
        $prognote->{ 1060 },
        $prognote->{ 1048 },
        $prognote->{ 1059 },
        $prognote->{ 1047 },
        $prognote->{ 1066 },
        $prognote->{ 1046 },
        $prognote->{ 1058 },
        $prognote->{ 1158 },
        $prognote->{ 1045 },
        $prognote->{ 1057 },
        $prognote->{ 1157 },
        $prognote->{ 1159 },
        $prognote->{ 1044 },
        $prognote->{ 1065 },
        $prognote->{ 1145 },
        $prognote->{ 1043 },
        $prognote->{ 1056 },
        $prognote->{ 1143 },
        $prognote->{ 1144 },
        $prognote->{ 1042 },
        $prognote->{ 1041 },
        $prognote->{ 1040 },
        $prognote->{ 1039 },
        $prognote->{ 1038 },
        $prognote->{ 1037 },
        $prognote->{ 1036 },
        $prognote->{ 1035 },
        $prognote->{ 1034 },
        $prognote->{ 1033 },
        $prognote->{ 1032 },
        $prognote->{ 1031 },
        $prognote->{ 1030 },
        $prognote->{ 1029 },
        $prognote->{ 1028 },
        $prognote->{ 1027 },
        $prognote->{ 1026 },
        $prognote->{ 1025 },
        $prognote->{ 1024 },
        $prognote->{ 1001 },
        $prognote->{ 1023 },
        $prognote->{ 1022 },
        $prognote->{ 1021 },
        $prognote->{ 1019 },
        $prognote->{ 1018 },
        $prognote->{ 1002 },
        $prognote->{ 1020 },
        $prognote->{ 1017 },
        $prognote->{ 1004 },
        $prognote->{ 1016 },
        $prognote->{ 1003 },
        $prognote->{ 1015 },
        $prognote->{ 1014 },
        $prognote->{ 1010 },
        $prognote->{ 1005 },
        $prognote->{ 1012 },
        $prognote->{ 1011 },
        $prognote->{ 1013 },
        $prognote->{ 1009 },
        $prognote->{ 1007 },
        $prognote->{ 1006 },
        $prognote->{ 1008 },
    ]);

    is( $one->list_all( 6666 ), undef );

    is_deeply( $one->list_all( 1004 ), [
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
        $prognote->{ 1012 },
        $prognote->{ 1011 },
        $prognote->{ 1013 },
    ]);

        $one->client_id( 1004 );
    is_deeply( $one->list_all( 1004 ), $one->list_all );

    is( $one->list_all( 1004, '2001-01-01' ), undef );
    is_deeply( $one->list_all( 1004, '2000-01-02' ), [
        $prognote->{ 1012 },
    ]);

    is( $one->list_all( 1004, undef, '2001-01-01' ), undef );
    is_deeply( $one->list_all( 1004, undef, '1999-07-05' ), [
        $prognote->{ 1011 },
    ]);

    is_deeply( $one->list_all( 1004, '1999-01-01', '1999-12-31' ), [
        $prognote->{ 1011 },
        $prognote->{ 1013 },
    ]);

    isa_ok( $_, 'HASH' ) for @{$one->list_all( 1004 )};

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_all, filter by writer
    is_deeply( $one->list_all( 1003, '1971-01-01', '2005-12-31' ), [
        $prognote->{ 1010 }, # 1003
        $prognote->{ 1009 }, # 1002
        $prognote->{ 1007 }, # 1002
        $prognote->{ 1006 }, # 1002
        $prognote->{ 1008 }, # 1002
    ]);

    is_deeply( $one->list_all( 1003, '1971-01-01', '2005-12-31', 1002 ), [
        $prognote->{ 1009 },
        $prognote->{ 1007 },
        $prognote->{ 1006 },
        $prognote->{ 1008 },
    ]);

    is_deeply( $one->list_all( 1003, '1975-01-01', '2005-12-31', 1002 ), [
        $prognote->{ 1009 },
        $prognote->{ 1007 },
        $prognote->{ 1006 },
    ]);

    is_deeply( $one->list_all( 1003, undef, undef, 1002 ), [
        $prognote->{ 1444 },
        $prognote->{ 1245 },
        $prognote->{ 1243 },
        $prognote->{ 1244 },
        $prognote->{ 1055 },
        $prognote->{ 1054 },
        $prognote->{ 1053 },
        $prognote->{ 1052 },
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
        $prognote->{ 1009 },
        $prognote->{ 1007 },
        $prognote->{ 1006 },
        $prognote->{ 1008 },
    ]);
    is_deeply( $one->list_all( 1003, '1971-01-01', '2005-12-31', 1003 ), [
        $prognote->{ 1010 },
    ]);

    is_deeply( $one->list_all( 1003, '1971-01-01', '2000-12-31', 1003 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
    can_ok( $one, 'get_all' );
    is( @{ $one->get_all }, 91 );

    isa_ok( $_, $CLASS ) for @{ $one->get_all };
    isa_ok( $_, $CLASS ) for @{ $one->get_all( 1004 )};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_recent
    can_ok( $CLASS, 'list_recent' );
    is( $CLASS->list_recent, undef );
    is( $CLASS->list_recent( 1001 ), undef );

    #select * order by start_date desc limit 3
    # fix?
    is_deeply( $CLASS->list_recent( undef, 3 ), [
        $prognote->{ 1651 },
        $prognote->{ 1650 },
        $prognote->{ 1649 },
    ] );
    is_deeply( $CLASS->list_recent( 1002, 4 ), [
        $prognote->{ 1001 },
        $prognote->{ 1002 },
        $prognote->{ 1004 },
        $prognote->{ 1003 },
    ] );

    is_deeply( $CLASS->list_recent( 1002, 5 ), [
        $prognote->{ 1001 },
        $prognote->{ 1002 },
        $prognote->{ 1004 },
        $prognote->{ 1003 },
        $prognote->{ 1005 },
    ] );

    is_deeply( $CLASS->list_recent( 1002, 100 ), [
        $prognote->{ 1001 },
        $prognote->{ 1002 },
        $prognote->{ 1004 },
        $prognote->{ 1003 },
        $prognote->{ 1005 },
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_recent_byheader
    can_ok( $CLASS, 'list_recent_byheader');

    is($one->list_recent_byheader, undef);
    is($one->list_recent_byheader( 1002 ), undef);
    is($one->list_recent_byheader( 1002, 1), undef);
    is_deeply($one->list_recent_byheader(1002, 1, 'CALLED'), [
        $prognote->{ 1001 }
    ]); 
    is_deeply($one->list_recent_byheader(1002, 2, 'CALLED'), [
        $prognote->{ 1001 },
        $prognote->{ 1002 },
    ]); 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_recent
    can_ok( $CLASS, 'get_recent' );

    is_deeply( $CLASS->get_recent( 1002, 5 ), [
        $prognote->{ 1001 },
        $prognote->{ 1002 },
        $prognote->{ 1004 },
        $prognote->{ 1003 },
        $prognote->{ 1005 },
    ] );
    isa_ok( $_, $CLASS ) for @{ $CLASS->get_recent( 1002, 5 ) };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# commit
    can_ok( $one, 'commit' );

    ok( $one->commit );
    is( $one->note_committed, 1 );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_billed
# TODO untested
    can_ok( $one, 'is_billed' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# location
        $one = $CLASS->new;
    can_ok( $one, 'location' );
    is( $one->location, undef );

    is_deeply( $CLASS->retrieve( 1002 )->location,
        $valid_data_prognote_location->{ $prognote->{ 1002 }->{ note_location_id }}
    );
    is_deeply( $CLASS->retrieve( 1042 )->location,
        $valid_data_prognote_location->{ $prognote->{ 1042 }->{ note_location_id }}
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# charge_codes
# wrapper
    can_ok( $one, 'charge_codes' );
    is( $one->charge_codes, undef );

    isa_ok( $one->charge_codes( 1001 ), 'ARRAY' );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# charge_code, takes current insurer into account
        $one = $CLASS->new;
    can_ok( $one, 'charge_code' );
    throws_ok{ $one->charge_code } qr/Must/;

    # - for each client:
    #   - notes in different authorizations
    #   - find insurer and charge code
    #   - see if custom and test
    #   - first, remove duplicate auths

    is( $CLASS->retrieve( 1010 )->charge_code->{ charge_code_id },    1, "id: 1010" );
    is( $CLASS->retrieve( 1042 )->charge_code->{ charge_code_id }, 1005, "id: 1042" );
    is( $CLASS->retrieve( 1043 )->charge_code->{ charge_code_id }, 1016, "id: 1043" );
    is( $CLASS->retrieve( 1044 )->charge_code->{ charge_code_id }, 1015, "id: 1044" );
    is( $CLASS->retrieve( 1045 )->charge_code->{ charge_code_id }, 1005, "id: 1045" );
    is( $CLASS->retrieve( 1046 )->charge_code->{ charge_code_id }, 1005, "id: 1046" );
    is( $CLASS->retrieve( 1047 )->charge_code->{ charge_code_id }, 1015, "id: 1047" );
    is( $CLASS->retrieve( 1048 )->charge_code->{ charge_code_id }, 1016, "id: 1048" );
    is( $CLASS->retrieve( 1049 )->charge_code->{ charge_code_id }, 1005, "id: 1049" );
    is( $CLASS->retrieve( 1050 )->charge_code->{ charge_code_id }, 1016, "id: 1050" );
    is( $CLASS->retrieve( 1051 )->charge_code->{ charge_code_id }, 1005, "id: 1051" );
    is( $CLASS->retrieve( 1052 )->charge_code->{ charge_code_id }, 1005, "id: 1052" );
    is( $CLASS->retrieve( 1053 )->charge_code->{ charge_code_id }, 1015, "id: 1053" );
    is( $CLASS->retrieve( 1054 )->charge_code->{ charge_code_id }, 1005, "id: 1054" );
    is( $CLASS->retrieve( 1055 )->charge_code->{ charge_code_id }, 1005, "id: 1055" );
    is( $CLASS->retrieve( 1056 )->charge_code->{ charge_code_id }, 1005, "id: 1056" );
    is( $CLASS->retrieve( 1057 )->charge_code->{ charge_code_id }, 1005, "id: 1057" );
    is( $CLASS->retrieve( 1058 )->charge_code->{ charge_code_id }, 1005, "id: 1058" );
    is( $CLASS->retrieve( 1059 )->charge_code->{ charge_code_id }, 1005, "id: 1059" );
    is( $CLASS->retrieve( 1060 )->charge_code->{ charge_code_id }, 1005, "id: 1060" );
    is( $CLASS->retrieve( 1061 )->charge_code->{ charge_code_id }, 1005, "id: 1061" );
    is( $CLASS->retrieve( 1062 )->charge_code->{ charge_code_id }, 1005, "id: 1062" );
    is( $CLASS->retrieve( 1063 )->charge_code->{ charge_code_id }, 1005, "id: 1063" );
    is( $CLASS->retrieve( 1064 )->charge_code->{ charge_code_id }, 1005, "id: 1064" );
    is( $CLASS->retrieve( 1065 )->charge_code->{ charge_code_id }, 1005, "id: 1065" );
    is( $CLASS->retrieve( 1066 )->charge_code->{ charge_code_id }, 1005, "id: 1066" );
    is( $CLASS->retrieve( 1067 )->charge_code->{ charge_code_id }, 1005, "id: 1067" );
    is( $CLASS->retrieve( 1068 )->charge_code->{ charge_code_id }, 1005, "id: 1068" );
    is( $CLASS->retrieve( 1143 )->charge_code->{ charge_code_id },    2, "id: 1143" );
    is( $CLASS->retrieve( 1144 )->charge_code->{ charge_code_id },    2, "id: 1144" );
    is( $CLASS->retrieve( 1145 )->charge_code->{ charge_code_id },    2, "id: 1145" );
    is( $CLASS->retrieve( 1157 )->charge_code->{ charge_code_id }, 1005, "id: 1157" );
    is( $CLASS->retrieve( 1158 )->charge_code->{ charge_code_id }, 1005, "id: 1158" );
    is( $CLASS->retrieve( 1159 )->charge_code->{ charge_code_id }, 1005, "id: 1159" );
    is( $CLASS->retrieve( 1243 )->charge_code->{ charge_code_id },    2, "id: 1243" );
    is( $CLASS->retrieve( 1244 )->charge_code->{ charge_code_id },    2, "id: 1244" );
    is( $CLASS->retrieve( 1245 )->charge_code->{ charge_code_id },    2, "id: 1245" );
    is( $CLASS->retrieve( 1257 )->charge_code->{ charge_code_id }, 1005, "id: 1257" );
    is( $CLASS->retrieve( 1258 )->charge_code->{ charge_code_id }, 1005, "id: 1258" );
    is( $CLASS->retrieve( 1259 )->charge_code->{ charge_code_id }, 1005, "id: 1259" );
    is( $CLASS->retrieve( 1260 )->charge_code->{ charge_code_id }, 1005, "id: 1260" );

    # specific insurer
    is( $CLASS->retrieve( 1042 )->charge_code( 1015 )->{ charge_code_id }, 1005, "id: 1042" );
    is( $CLASS->retrieve( 1042 )->charge_code( 1015 )->{ acceptable }, 1, "id: 1042" );
    is( $CLASS->retrieve( 1043 )->charge_code( 1015 )->{ charge_code_id }, 1016, "id: 1043" );
    is( $CLASS->retrieve( 1043 )->charge_code( 1015 )->{ acceptable }, 1, "id: 1043" );
    is( $CLASS->retrieve( 1044 )->charge_code( 1015 )->{ charge_code_id }, 1015, "id: 1044" );
    is( $CLASS->retrieve( 1044 )->charge_code( 1015 )->{ acceptable }, 0, "id: 1044" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# editable
        $one = $CLASS->new;
    can_ok( $one, 'editable' );
    is( $one->editable, undef );

        $one = $CLASS->new({
            client_id => 1001,
        });
    is( $one->editable, undef );

        $one = $CLASS->new({
            rec_id => 1,
        });
    is( $one->editable, undef );

        $one = $CLASS->new({
            staff_id => 1001,
        });
    is( $one->editable, undef );

        $one = $CLASS->new({
            rec_id => 1,
            client_id => 1001,
            staff_id => 1001,
            note_committed => 1,
        });
    is( $one->editable, 0 );

        $one = $CLASS->new({
            rec_id => 1,
            client_id => 1001,
            staff_id => 1001,
        });
    is( $one->editable, 1 );

        $one = $CLASS->new({
            rec_id => 1,
            client_id => 6666,
            staff_id => 1001,
        });
    is( $one->editable, 0 );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# note_date
    can_ok( $one, 'note_date' );
    is( $one->note_date, undef );

        $one->start_date( 0 );
    is( $one->note_date, undef );

        $one->start_date( '2005-05-09 12:30:00' );
    is( $one->note_date, '2005-05-09' );

        $one->start_date( 'foo bar' );
    is( $one->note_date, 'foo' );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start_time
    can_ok( $one, 'start_time' );
    is( $one->start_time, undef );

    $one->start_date( 0 );
    is( $one->start_time, undef );

    $one->start_date( '2005-05-09 12:30:00' );
    is( $one->start_time, '12:30' );

    $one->start_date( '2005-05-09 02:00:00' );
    is( $one->start_time, '2:00' );

    $one->start_date( '2005-05-09 00:15:00' );
    is( $one->start_time, '0:15' );

    $one->start_date( 'there is a time in here 00:15:00 somewhere' );
    is( $one->start_time, '0:15' );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# end_time
    can_ok( $one, 'end_time' );
    is( $one->end_time, undef );

        $one->end_date( 0 );
    is( $one->end_time, undef );

        $one->end_date( '2005-05-09 12:30:00' );
    is( $one->end_time, '12:30' );

        $one->end_date( '2005-05-09 02:00:00' );
    is( $one->end_time, '2:00' );

        $one->end_date( '2005-05-09 00:15:00' );
    is( $one->end_time, '0:15' );

        $one->end_date( 'there is a time in here 00:15:00 somewhere' );
    is( $one->end_time, '0:15' );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    can_ok( $one, 'save' );
    $test->db->transaction_do_eval(sub { is( $one->save, undef ) });
    ok( eleMentalClinic::Log::ExceptionReport->message_is_catchable( $@ ), "Throws catchable exception" );

        $one = $CLASS->new({
            client_id => 1001,
            staff_id  => 1001,
            goal_id   => 1,
        });
    ok( $one->save );

# FIXME - this was changed for simple, but will this break trunk?
#    is( $one->note_header, 'Core Services' );

    ok( $one->rec_id );

        $tmp = $one;
    is_deeply( $one->retrieve, $tmp );

        $one = $CLASS->new({
            client_id => 1001,
            staff_id  => 1001,
            goal_id   => 0,
        });
    ok( $one->save );

# FIXME - removed for simple, but will this break trunk?
#    is( $one->note_header, 'Case Note' );

    ok( $one->rec_id );

        $tmp = $one;
    is_deeply( $one->retrieve, $tmp );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# goal
# wrapper
    can_ok( $one, 'goal' );
    is( $one->goal, undef );

        $one->goal_id( 6666 );
    is( $one->goal, undef );

        $one->goal_id( 1001 );
    is_deeply( $one->goal, $tx_goals->{ 1001 } );
        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_group
# wrapper
    can_ok( $one, 'get_group' );

    is( $one->get_group, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_attendee
# wrapper
    can_ok( $one, 'get_attendee' );

    is( $one->get_attendee, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_group_uncommitted
# wrapper
    can_ok( $one, 'get_group_uncommitted' );

    is( $one->get_group_uncommitted, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# total_duration
    can_ok( $one, 'total_duration' );
    
    is_deeply( $one->total_duration({ staff_id => 1000, current_date => '11-07-05' }), {
        week  => 0,
        month => 0,
        year  => 3.5,
    });
    is_deeply( $one->total_duration({ staff_id => 1001, current_date => '11-07-05' }), {
        week  => 1,
        month => 3,
        year  => 24.25,
    });
    is_deeply( $one->total_duration({ staff_id => 1002, current_date => '11-07-05' }), {
        week  => 0,
        month => 0,
        year  => 5.5,
    });
    is_deeply( $one->total_duration({ staff_id => 1003, current_date => '11-07-05' }), {
        week  => 0,
        month => 0,
        year  => 2,
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# duplicate checking
        $one = $CLASS->new;
    can_ok( $one, 'is_duplicate' );
    is( $one->is_duplicate, undef );

        $one->id( 1001 )->retrieve;
    is( $one->is_duplicate, undef );

        $one->id( 1043 )->retrieve;
    is_deeply( $one->is_duplicate, [ qw/
        1145
        1143
        1144
    /]);

        $one->id( 1057 )->retrieve;
    is_deeply( $one->is_duplicate, [ qw/
        1158
        1157
        1159
    /]);

TODO: {
    todo_skip 'not yet implemented', 3 if 1;
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # do_not_bill notes
            $one = $CLASS->new;
        can_ok( $CLASS, 'list_do_not_bill' );
        is_deeply( $CLASS->list_do_not_bill, [
            $prognote->{ 1066 },
        ]);
        isa_ok( $_, $CLASS )
            for @{ $CLASS->get_do_not_bill };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# locked
#         Billed
#         Billing
#         Paid
#         Prebilling
#         Unbillable
# XXX near the end since it modifies data
        $one = $CLASS->new;
    can_ok( $one, 'locked' );
    is( $one->locked, 0 );
    is( $CLASS->retrieve( 1001 )->locked, 'Paid' );
    is( $CLASS->retrieve( 1002 )->locked, 'Paid' );
    is( $CLASS->retrieve( 1143 )->locked, 0 );
    is( $CLASS->retrieve( 1144 )->locked, 0 );
    is( $CLASS->retrieve( 1145 )->locked, 0 );
    is( $CLASS->retrieve( 1157 )->locked, 0 );
    is( $CLASS->retrieve( 1158 )->locked, 0 );

    ok( $CLASS->retrieve( 1143 )->billing_status( 'Billed' )->save );
    ok( $CLASS->retrieve( 1144 )->billing_status( 'Billing' )->save );
    ok( $CLASS->retrieve( 1145 )->billing_status( 'Prebilling' )->save );
    ok( $CLASS->retrieve( 1157 )->billing_status( 'Unbillable' )->save );
    ok( $CLASS->retrieve( 1158 )->billing_status( 'BilledManually' )->save );

    is( $CLASS->retrieve( 1143 )->locked, 'Billed' );
    is( $CLASS->retrieve( 1144 )->locked, 'Billing' );
    is( $CLASS->retrieve( 1145 )->locked, 'Prebilling' );
    is( $CLASS->retrieve( 1157 )->locked, 'Unbillable' );
    is( $CLASS->retrieve( 1158 )->locked, 'BilledManually' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_earliest
# XXX near the end since it modifies data
    can_ok( $CLASS, 'get_earliest' );
    is_deeply( $CLASS->get_earliest, $CLASSDATA->{ 1008 });
    isa_ok( $CLASS->get_earliest, $CLASS );

    # change that note and make sure we get the next in line
        $tmp = $CLASSDATA->{ 1008 }{ start_date };
        $CLASS->retrieve( 1008 )->start_date( '2006-01-01' )->save;
    is_deeply( $CLASS->get_earliest, $CLASSDATA->{ 1006 });
    isa_ok( $CLASS->get_earliest, $CLASS );

    # reset values
        $CLASS->retrieve( 1008 )->start_date( $tmp )->save;
    is( $CLASS->get_earliest->id, 1008 );
    is( $CLASS->get_earliest->start_date, $tmp );
    isa_ok( $CLASS->get_earliest, $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# uncommitted by writer
    can_ok( $CLASS, 'get_uncommitted_by_writer' );
    throws_ok{ $CLASS->get_uncommitted_by_writer } qr/Writer id is required/;

    is( $CLASS->get_uncommitted_by_writer( 1001 ), undef );
    is( $CLASS->get_uncommitted_by_writer( 1002 ), undef );
    is( $CLASS->get_uncommitted_by_writer( 1003 ), undef );
        
        $CLASS->retrieve( 1003 )->note_committed( 0 )->save;
        $CLASS->retrieve( 1004 )->note_committed( 0 )->save;
        $CLASS->retrieve( 1005 )->note_committed( 0 )->save;

    is_deeply_except({ modified => undef },
        $CLASS->get_uncommitted_by_writer( 1001 ),
        [
            { %{ $prognote->{ 1005 }}, note_committed => 0 },
        ]
    );
    is_deeply_except({ modified => undef },
        $CLASS->get_uncommitted_by_writer( 1002 ),
        [
            { %{ $prognote->{ 1004 }}, note_committed => 0 },
            { %{ $prognote->{ 1003 }}, note_committed => 0 },
        ]
    );
    is( $CLASS->get_uncommitted_by_writer( 1003 ), undef );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing prognotes
    can_ok( $one, 'billing_prognotes' );
        dbinit( 1 );
    is( $CLASS->retrieve( 1001 )->billing_prognotes, undef );
    is( $CLASS->retrieve( 1043 )->billing_prognotes, undef );

        $test->financial_setup( 1 );
    is( $CLASS->retrieve( 1001 )->billing_prognotes, undef );
    is_deeply( $CLASS->retrieve( 1043 )->billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1003 ),
    ]);
    is_deeply( $CLASS->retrieve( 1044 )->billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1004 ),
    ]);

        $test->financial_setup( 2 );
    is_deeply( $CLASS->retrieve( 1043 )->billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1003 ),
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1013 ),
    ]);
    is_deeply( $CLASS->retrieve( 1044 )->billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1004 ),
    ]);

    # now start the billing cycle, but don't go as far as billing - unbilled records are included
        dbinit( 1 );

        $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );
    is( $CLASS->retrieve( 1001 )->billing_prognotes, undef );
    is_deeply( $CLASS->retrieve( 1043 )->billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1003 ),
    ]);
    is_deeply( $CLASS->retrieve( 1044 )->billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1004 ),
    ]);


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billed_billing prognotes
    can_ok( $one, 'billed_billing_prognotes' );
        dbinit( 1 );
    is( $CLASS->retrieve( 1001 )->billed_billing_prognotes, undef );
    is( $CLASS->retrieve( 1043 )->billed_billing_prognotes, undef );

        $test->financial_setup( 1 );
    is( $CLASS->retrieve( 1001 )->billed_billing_prognotes, undef );
    is_deeply( $CLASS->retrieve( 1043 )->billed_billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1003 ),
    ]);
    is_deeply( $CLASS->retrieve( 1044 )->billed_billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1004 ),
    ]);

        $test->financial_setup( 2 );
    is_deeply( $CLASS->retrieve( 1043 )->billed_billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1003 ),
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1013 ),
    ]);
    is_deeply( $CLASS->retrieve( 1044 )->billed_billing_prognotes, [
        eleMentalClinic::Financial::BillingPrognote->retrieve( 1004 ),
    ]);

    # now start the billing cycle, but don't go as far as billing - unbilled records are NOT included
        dbinit( 1 );

        $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );
    is( $CLASS->retrieve( 1001 )->billed_billing_prognotes, undef );
    is( $CLASS->retrieve( 1043 )->billed_billing_prognotes, undef );
    is( $CLASS->retrieve( 1044 )->billed_billing_prognotes, undef );

    # run a billing cycle where some notes are billed and some aren't. Ones that aren't shouldn't be included in billed_billing_prognotes
    dbinit( 1 );

        # create a progress note in the date range, with a charge code that's missing dollars_per_unit
        $tmp = $CLASS->new({
            client_id   => 1003,
            staff_id    => 1002,
            goal_id     => 0,
            start_date  => '2006-07-03 14:00:00',
            end_date    => '2006-07-03 12:00:00',
            note_body   => 'This is a test note with an invalid charge code',
            writer      => 'Betty Clinician',
            data_entry_id => 1002,
            charge_code_id => 2,
            note_location_id => 1,
        })->save;
        $test->financial_setup( 1, undef, { no_payment => 1 });

    is( $CLASS->retrieve( $tmp->{ rec_id } )->billed_billing_prognotes, undef, 'unbilled notes in a billed file should not show up' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# charge_code, takes current insurer into account
# make sure we don't fail with date out of range
    is( $CLASS->retrieve( 1042 )->start_date( '1900-01-01' )->charge_code->{ charge_code_id }, 1005, "id: 1042" );
    is( $CLASS->retrieve( 1043 )->start_date( '1900-01-01' )->charge_code->{ charge_code_id }, 1016, "id: 1043" );
    is( $CLASS->retrieve( 1044 )->start_date( '1900-01-01' )->charge_code->{ charge_code_id }, 1015, "id: 1044" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# split_charge_code
    can_ok( $one, 'split_charge_code' );

        $one = $CLASS->new;
    eval { $one->split_charge_code };
    like $@, qr/stored object/, 'split_charge_code';
    # for some reason, this causes a "Modification of read-only value" in
    # Carp::Heavy.  no, I have no idea.
    #throws_ok{ $one->split_charge_code } qr/stored object/;
    is_deeply( $one->retrieve( 1001 )->split_charge_code, { charge_code => '90801', modifiers => undef } );
    is_deeply( $one->retrieve( 1002 )->split_charge_code, { charge_code => '90801', modifiers => 'HK' } );
    throws_ok{ $one->retrieve( 1003 )->split_charge_code } qr/code is required and must include at least 5 characters/; # N/A
    is_deeply( $one->retrieve( 1042 )->split_charge_code, { charge_code => '90806', modifiers => undef } );
    is_deeply( $one->retrieve( 1050 )->split_charge_code, { charge_code => '90862', modifiers => 'HK' } );
    is_deeply( $one->retrieve( 1053 )->split_charge_code, { charge_code => '90862', modifiers => undef } );
    throws_ok{ $one->retrieve( 1243 )->split_charge_code } qr/code is required and must include at least 5 characters/; # No Show

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_client_insurance
    can_ok( $one, 'get_client_insurance' );

        $one = $CLASS->new;
    throws_ok{ $one->get_client_insurance } qr/stored object/;
    throws_ok{ $one->retrieve( 1043 )->get_client_insurance } qr/required/;

    is_deeply( $one->retrieve( 1043 )->get_client_insurance( 1015 ), $client_insurance->{ 1003 } );
    is_deeply( $one->retrieve( 1043 )->get_client_insurance( 1014 ), $client_insurance->{ 1004 } );
    # client insurance exists but auth does not
    is( $one->retrieve( 1043 )->get_client_insurance( 1013 ), undef );
    
    # Progress note for the same client, same time period
    is_deeply( $one->retrieve( 1044 )->get_client_insurance( 1015 ), $client_insurance->{ 1003 } );
    is_deeply( $one->retrieve( 1044 )->get_client_insurance( 1014 ), $client_insurance->{ 1004 } );
    is( $one->retrieve( 1044 )->get_client_insurance( 1013 ), undef );

    is_deeply( $one->retrieve( 1056 )->get_client_insurance( 1015 ), $client_insurance->{ 1007 } );
    # client insurance exists but auth does not
    is( $one->retrieve( 1056 )->get_client_insurance( 1016 ), undef );
    # client insurance does not exist
    is( $one->retrieve( 1056 )->get_client_insurance( 1014 ), undef );

    is_deeply( $one->retrieve( 1065 )->get_client_insurance( 1009 ), $client_insurance->{ 1010 } );
    # client insurance exists but auth does not for time period
    is( $one->retrieve( 1065 )->get_client_insurance( 1015 ), undef );

    is_deeply( $one->retrieve( 1067 )->get_client_insurance( 1015 ), $client_insurance->{ 1011 } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# combine_identical
    can_ok( $one, 'combine_identical' );

        $one = $CLASS->new;
    is( $one->combine_identical, undef );
    
    # incorrect args
    is( $one->combine_identical( 1043, 1044, 1045 ), undef );
    is_deeply( $one->combine_identical(
        eleMentalClinic::ProgressNote->retrieve( 1043 ),
        eleMentalClinic::ProgressNote->retrieve( 1044 ),
        eleMentalClinic::ProgressNote->retrieve( 1045 ),
    ), undef );

    is_deeply( $one->combine_identical( [
        eleMentalClinic::ProgressNote->retrieve( 1043 ),
        eleMentalClinic::ProgressNote->retrieve( 1044 ),
        eleMentalClinic::ProgressNote->retrieve( 1045 ),
    ] ), 
    { 
        1002 => { 
            '2006-07-03|1016|1' => [ eleMentalClinic::ProgressNote->retrieve( 1043 ), ],
            '2006-07-05|1015|1' => [ eleMentalClinic::ProgressNote->retrieve( 1044 ), ],
            '2006-07-07|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1045 ), ], 
        },
    } );

    is_deeply( $one->combine_identical( [
        eleMentalClinic::ProgressNote->retrieve( 1043 ),
        eleMentalClinic::ProgressNote->retrieve( 1044 ),
        eleMentalClinic::ProgressNote->retrieve( 1045 ),
    ],
    'ignore staff' ), # should have no effect
    { 
        1002 => { 
            '2006-07-03|1016|1' => [ eleMentalClinic::ProgressNote->retrieve( 1043 ), ],
            '2006-07-05|1015|1' => [ eleMentalClinic::ProgressNote->retrieve( 1044 ), ],
            '2006-07-07|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1045 ), ], 
        },
    } );

    is_deeply( $one->combine_identical( [
        eleMentalClinic::ProgressNote->retrieve( 1065 ),
        eleMentalClinic::ProgressNote->retrieve( 1066 ),
    ] ), 
    { 
        1001 => { 
            '2006-07-05|1005|1002' => [ eleMentalClinic::ProgressNote->retrieve( 1065 ), ],
            '2006-07-12|1005|1002' => [ eleMentalClinic::ProgressNote->retrieve( 1066 ), ], 
        },
    } );

    is_deeply( $one->combine_identical( [
        eleMentalClinic::ProgressNote->retrieve( 1065 ),
        eleMentalClinic::ProgressNote->retrieve( 1066 ),
    ],
    'ignore staff' ),  # should have no effect
    { 
        1001 => { 
            '2006-07-05|1005|1002' => [ eleMentalClinic::ProgressNote->retrieve( 1065 ), ],
            '2006-07-12|1005|1002' => [ eleMentalClinic::ProgressNote->retrieve( 1066 ), ], 
        },
    } );

    # actually combining here
    is_deeply( $one->combine_identical( [
        eleMentalClinic::ProgressNote->retrieve( 1050 ),
        eleMentalClinic::ProgressNote->retrieve( 1350 ),
    ] ), 
    { 
        1002 => { 
            '2006-07-19|1016|1' => [ 
                eleMentalClinic::ProgressNote->retrieve( 1050 ), 
                eleMentalClinic::ProgressNote->retrieve( 1350 ), 
            ],},
    } );

    is_deeply( $one->combine_identical( [
        eleMentalClinic::ProgressNote->retrieve( 1050 ),
        eleMentalClinic::ProgressNote->retrieve( 1350 ),
    ],
    'ignore staff' ), # should have no effect (already combining)
    { 
        1002 => { 
            '2006-07-19|1016|1' => [ 
                eleMentalClinic::ProgressNote->retrieve( 1050 ), 
                eleMentalClinic::ProgressNote->retrieve( 1350 ), 
            ],},
    } );

    # ignore staff and these will combine
    is_deeply( $one->combine_identical( [
        eleMentalClinic::ProgressNote->retrieve( 1051 ),
        eleMentalClinic::ProgressNote->retrieve( 1351 ),
    ],
    'ignore staff' ), 
    { 
        1002 => { 
            '2006-07-21|1005|1' => [ 
                eleMentalClinic::ProgressNote->retrieve( 1051 ), 
                eleMentalClinic::ProgressNote->retrieve( 1351 ), 
            ],},
    } );

    # use staff_ids, therefore don't combine
    is_deeply( $one->combine_identical( [
        eleMentalClinic::ProgressNote->retrieve( 1051 ),
        eleMentalClinic::ProgressNote->retrieve( 1351 ),
    ] ), 
    { 
        1002 => { 
            '2006-07-21|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1051 ), ],
        },
        1001 => {
            '2006-07-21|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1351 ), ],
        },
    } );

    # test with a bigger group of notes
        my $notes = eleMentalClinic::ProgressNote->list_all( 1003, '07-01-2006', '07-31-2006' );
        $notes = [ map{ $CLASS->new( $_ )} @$notes ];

    is_deeply( $one->combine_identical( $notes, 'ignore_staff' ),
    {
        1002 => { 
            '2006-07-03|1016|1' => [ eleMentalClinic::ProgressNote->retrieve( 1043 ), ],
            '2006-07-05|1015|1' => [ eleMentalClinic::ProgressNote->retrieve( 1044 ), ],
            '2006-07-07|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1045 ), ],
            '2006-07-10|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1046 ), ],
            '2006-07-12|1015|1' => [ eleMentalClinic::ProgressNote->retrieve( 1047 ), ],
            '2006-07-14|1016|1' => [ eleMentalClinic::ProgressNote->retrieve( 1048 ), ],
            '2006-07-17|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1049 ), ],
            '2006-07-19|1016|1' => [ 
                eleMentalClinic::ProgressNote->retrieve( 1050 ), 
                eleMentalClinic::ProgressNote->retrieve( 1350 ), 
            ],
            '2006-07-21|1005|1' => [ 
                eleMentalClinic::ProgressNote->retrieve( 1051 ), 
                eleMentalClinic::ProgressNote->retrieve( 1351 ), 
            ],
            '2006-07-24|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1052 ), ],
            '2006-07-26|1015|1' => [ eleMentalClinic::ProgressNote->retrieve( 1053 ), ],
            '2006-07-28|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1054 ), ],
            '2006-07-31|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1055 ), ],
            '2006-07-03|2|1003' => [
                eleMentalClinic::ProgressNote->retrieve( 1143 ),
                eleMentalClinic::ProgressNote->retrieve( 1144 ),
                eleMentalClinic::ProgressNote->retrieve( 1145 ),
            ],
        },
    } );

    # not ignoring staff
    is_deeply( $one->combine_identical( $notes ),
    {
        1001 => {
            '2006-07-21|1005|1' => [
                eleMentalClinic::ProgressNote->retrieve( 1351 ),
            ],
        },
        1002 => { 
            '2006-07-03|1016|1' => [ eleMentalClinic::ProgressNote->retrieve( 1043 ), ],
            '2006-07-05|1015|1' => [ eleMentalClinic::ProgressNote->retrieve( 1044 ), ],
            '2006-07-07|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1045 ), ],
            '2006-07-10|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1046 ), ],
            '2006-07-12|1015|1' => [ eleMentalClinic::ProgressNote->retrieve( 1047 ), ],
            '2006-07-14|1016|1' => [ eleMentalClinic::ProgressNote->retrieve( 1048 ), ],
            '2006-07-17|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1049 ), ],
            '2006-07-19|1016|1' => [ 
                eleMentalClinic::ProgressNote->retrieve( 1050 ), 
                eleMentalClinic::ProgressNote->retrieve( 1350 ), 
            ],
            '2006-07-21|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1051 ), ],
            '2006-07-24|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1052 ), ],
            '2006-07-26|1015|1' => [ eleMentalClinic::ProgressNote->retrieve( 1053 ), ],
            '2006-07-28|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1054 ), ],
            '2006-07-31|1005|1' => [ eleMentalClinic::ProgressNote->retrieve( 1055 ), ],
            '2006-07-03|2|1003' => [
                eleMentalClinic::ProgressNote->retrieve( 1143 ),
                eleMentalClinic::ProgressNote->retrieve( 1144 ),
                eleMentalClinic::ProgressNote->retrieve( 1145 ),
            ],
        },
    } );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_mental_health_insurers
    can_ok( $one, 'get_mental_health_insurers' );

    throws_ok{ $CLASS->retrieve( 999 )->get_mental_health_insurers } qr/required/;

    is( $CLASS->retrieve( 1014 )->get_mental_health_insurers, undef );
    is( $CLASS->retrieve( 1001 )->get_mental_health_insurers, undef );

    is_deeply( $CLASS->retrieve( 1043 )->get_mental_health_insurers, [
        $client_insurance->{ 1003 },
        $client_insurance->{ 1004 },
    ] );

    is_deeply( $CLASS->retrieve( 1056 )->get_mental_health_insurers, [
        $client_insurance->{ 1007 },
    ] );

    is_deeply( $CLASS->retrieve( 1065 )->get_mental_health_insurers, [
        $client_insurance->{ 1010 },
    ] );
    is_deeply( $CLASS->retrieve( 1067 )->get_mental_health_insurers, [
        $client_insurance->{ 1010 },
        $client_insurance->{ 1011 },
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing_services
    can_ok( $one, 'billing_services' );

    throws_ok{ $one->billing_services } qr/stored object/;

        dbinit( 1 );
    is_deeply( $CLASS->retrieve( 1003 )->billing_services, [] );
    throws_ok{ $CLASS->retrieve( 1003 )->billing_services( 1014 ) } qr/must be an array/;

    # -----------------------------
        $test->financial_setup( 1 );
    is_deeply( $CLASS->retrieve( 1003 )->billing_services, [] );
    
    is_deeply( $CLASS->retrieve( 1043 )->billing_services, [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1003 ),
    ]);
    is_deeply( $CLASS->retrieve( 1043 )->billing_services([ 1014 ]), [] );
    is_deeply( $CLASS->retrieve( 1043 )->billing_services([ 1015 ]), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1003 ),
    ]);

    is_deeply( $CLASS->retrieve( 1056 )->billing_services([ 1014, 1015, 1016 ]), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1009 ),
    ]);

    # -----------------------------
        $test->financial_setup( 2 );
    is_deeply( $CLASS->retrieve( 1003 )->billing_services, [] );
    
    is_deeply( $CLASS->retrieve( 1043 )->billing_services, [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1003 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1013 ),
    ]);
    is_deeply( $CLASS->retrieve( 1043 )->billing_services([ 1014 ]), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1013 ),
    ]);
    is_deeply( $CLASS->retrieve( 1043 )->billing_services([ 1015 ]), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1003 ),
    ]);
    is_deeply( $CLASS->retrieve( 1043 )->billing_services([ 1014, 1015 ]), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1003 ),
        eleMentalClinic::Financial::BillingService->retrieve( 1013 ),
    ]);
    
    is_deeply( $CLASS->retrieve( 1056 )->billing_services([ 1014, 1015, 1016 ]), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1009 ),
    ]);

    # -----------------------------
        $test->financial_setup( 3 );
    is_deeply( $CLASS->retrieve( 1050 )->billing_services([ 1015 ]),  
               $CLASS->retrieve( 1350 )->billing_services([ 1015 ])
    );

    # -----------------------------
        $test->financial_setup( 4 );
    is_deeply( $CLASS->retrieve( 1050 )->billing_services([ 1014 ]),
               $CLASS->retrieve( 1350 )->billing_services([ 1014 ])
    );
    is_deeply( $CLASS->retrieve( 1051 )->billing_services([ 1014 ]),
               $CLASS->retrieve( 1351 )->billing_services([ 1014 ])
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing_services_by_auth
    can_ok( $one, 'billing_services_by_auth' );

    throws_ok{ $one->billing_services_by_auth } qr/stored object/;

        dbinit( 1 );
    throws_ok{ $CLASS->retrieve( 1003 )->billing_services_by_auth } qr/required/;

    # -----------------------------
        $test->financial_setup( 1 );
    is_deeply( $CLASS->retrieve( 1003 )->billing_services_by_auth( 1004 ), [] );
    
    is_deeply( $CLASS->retrieve( 1043 )->billing_services_by_auth( 1004 ), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1003 ),
    ]);
    is_deeply( $CLASS->retrieve( 1043 )->billing_services_by_auth( 1007 ), [] );
    is_deeply( $CLASS->retrieve( 1043 )->billing_services_by_auth( 1009 ), [] );

    is_deeply( $CLASS->retrieve( 1057 )->billing_services_by_auth( 1009 ), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1010 ),
    ]);

    # -----------------------------
        $test->financial_setup( 2 );
    is_deeply( $CLASS->retrieve( 1003 )->billing_services_by_auth( 1004 ), [] );
    
    is_deeply( $CLASS->retrieve( 1043 )->billing_services_by_auth( 1004 ), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1003 ),
    ]);
    is_deeply( $CLASS->retrieve( 1043 )->billing_services_by_auth( 1007 ), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1013 ),
    ]);
    is_deeply( $CLASS->retrieve( 1043 )->billing_services_by_auth( 1009 ), [] );
    
    is_deeply( $CLASS->retrieve( 1057 )->billing_services_by_auth( 1009 ), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1010 ),
    ]);

    # -----------------------------
        $test->financial_setup( 3 );
    is_deeply( $CLASS->retrieve( 1050 )->billing_services_by_auth( 1004 ),  
               $CLASS->retrieve( 1350 )->billing_services_by_auth( 1004 )
    );
    is_deeply( $CLASS->retrieve( 1051 )->billing_services_by_auth( 1004 ), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1017 ),
    ]);
    is_deeply( $CLASS->retrieve( 1351 )->billing_services_by_auth( 1004 ), [ 
        eleMentalClinic::Financial::BillingService->retrieve( 1014 ),
    ]);

    # -----------------------------
        $test->financial_setup( 4 );
    is_deeply( $CLASS->retrieve( 1050 )->billing_services_by_auth( 1007 ),
               $CLASS->retrieve( 1350 )->billing_services_by_auth( 1007 )
    );
    is_deeply( $CLASS->retrieve( 1051 )->billing_services_by_auth( 1007 ),
               $CLASS->retrieve( 1351 )->billing_services_by_auth( 1007 )
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_manual_to_bill
    can_ok( $CLASS, 'get_manual_to_bill' );

        dbinit( 1 );
        $test->financial_setup( 1 );
    is_deeply( $CLASS->get_manual_to_bill, {} );

        # move a note into the billing cycle date range, mark manual billing
        my $prognote = eleMentalClinic::ProgressNote->retrieve( 1444 );
        $prognote->start_date( '2006-07-05 14:00:00' );
        $prognote->end_date( '2006-07-05 15:00:00' );

        $prognote->bill_manually( 1 )->save;
   
    # should pick it up, plus its identical note
    is_deeply( $CLASS->get_manual_to_bill, {
        1003 => { 
            '2006-07-05' => {
                deferred => 0,
                deferred_ids => [],
                notes => [
                   eleMentalClinic::ProgressNote->retrieve( 1044 ),
                    $prognote,
                ],
            }
        },
    } );
        
        # when the bill_manual note is already billed manually, shouldn't get picked up
        $prognote->billing_status( 'BilledManually' )->save;
    is_deeply( $CLASS->get_manual_to_bill, {} );

        # move another note into the billing cycle and mark manual billing
        # (this note has a different staff_id, should not make a difference)
        my $prognote2 = eleMentalClinic::ProgressNote->retrieve( 1445 );
        $prognote2->start_date( '2006-07-07 14:00:00' );
        $prognote2->end_date( '2006-07-07 15:00:00' );
        $prognote2->bill_manually( 1 )->save;

    is_deeply( $CLASS->get_manual_to_bill, {
        1003 => {
            '2006-07-07' => {
                deferred => 0,
                deferred_ids => [],
                notes => [
                    eleMentalClinic::ProgressNote->retrieve( 1045 ),
                    $prognote2,
                ],
            },
        },
    } );

        # unmark that first note as billed, now all 4 should show up
        $prognote->{ billing_status } = undef;
        $prognote->save;

    is_deeply( $CLASS->get_manual_to_bill, {
        1003 => {
            '2006-07-05' => {
                deferred => 0,
                deferred_ids => [],
                notes => [
                    eleMentalClinic::ProgressNote->retrieve( 1044 ),
                    $prognote,
                ],
            },
            '2006-07-07' => {
                deferred => 0,
                deferred_ids => [],
                notes => [
                    eleMentalClinic::ProgressNote->retrieve( 1045 ),
                    $prognote2,
                ],
            },
        },
    } );

        # mark manual billing for one of the identical notes
        # to test that duplicates are filtered out when both identical notes are marked bill_manually 
        my $identical = eleMentalClinic::ProgressNote->retrieve( 1044 );
        $identical->bill_manually( 1 )->save;
    
    is_deeply( $CLASS->get_manual_to_bill, {
        1003 => {
            '2006-07-05' => {
                deferred => 0,
                deferred_ids => [],
                notes => [
                    eleMentalClinic::ProgressNote->retrieve( 1044 ),
                    $prognote,
                ],
            },
            '2006-07-07' => {
                deferred => 0,
                deferred_ids => [],
                notes => [
                    eleMentalClinic::ProgressNote->retrieve( 1045 ),
                    $prognote2,
                ],
            },
        },
    } );

        # mark a transaction for one of the identical notes as entered_in_error
        # to test that the notes now get marked as "defer_until_payment" 
        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->entered_in_error( 1 )->save;
    
    is_deeply( $CLASS->get_manual_to_bill, {
        1003 => {
            '2006-07-05' => {
                deferred => 1,
                deferred_ids => [1044],
                notes => [
                    eleMentalClinic::ProgressNote->retrieve( 1044 ),
                    $prognote,
                ],
            },
            '2006-07-07' => {
                deferred => 0,
                deferred_ids => [],
                notes => [
                    eleMentalClinic::ProgressNote->retrieve( 1045 ),
                    $prognote2,
                ],
            },
        },
    } );

    # XXX - Could add a test case to show that things still work when two groups are on the same date (different charge code or location)
    # Need to add two more notes in this date range,
    # one billed, the other not. It'd be better if the one billed is not billed in the usual first billing cycle
    # used by our tests all over, otherwise the tests will break all over.

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid_transactions
    can_ok( $one, 'valid_transactions' );
    
    throws_ok{ $CLASS->new->valid_transactions } qr/stored object/;

        dbinit( 1 );
    is_deeply( $CLASS->retrieve( 1043 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1049 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1050 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1350 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1051 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1351 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1056 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1060 )->valid_transactions, [] );

    # -----------------------------
        $test->financial_setup( 1 );
    is_deeply( $CLASS->retrieve( 1043 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1001 ),
    ]);
    is_deeply( $CLASS->retrieve( 1049 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1050 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1350 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1051 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1351 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1056 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1007 ),
    ]);
    is_deeply( $CLASS->retrieve( 1060 )->valid_transactions, [] );

    # -----------------------------
        $test->financial_setup( 2 );
    is_deeply( $CLASS->retrieve( 1043 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1001 ),
        eleMentalClinic::Financial::Transaction->retrieve( 1011 ),
    ]);
    is_deeply( $CLASS->retrieve( 1049 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1050 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1350 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1051 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1351 )->valid_transactions, [] );
    is_deeply( $CLASS->retrieve( 1056 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1007 ),
    ]);
    is_deeply( $CLASS->retrieve( 1060 )->valid_transactions, [] );

    # -----------------------------
        $test->financial_setup( 3 );
    is_deeply( $CLASS->retrieve( 1043 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1001 ),
        eleMentalClinic::Financial::Transaction->retrieve( 1011 ),
    ]);
    is_deeply( $CLASS->retrieve( 1049 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1013 ),
    ]);
    is_deeply( $CLASS->retrieve( 1050 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1014 ),
    ]);
    is_deeply( $CLASS->retrieve( 1350 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1014 ),
    ]);
    is_deeply( $CLASS->retrieve( 1051 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1015 ),
    ]);
    is_deeply( $CLASS->retrieve( 1351 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1012 ),
    ]);
    is_deeply( $CLASS->retrieve( 1052 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1016 ),
    ]);
    is_deeply( $CLASS->retrieve( 1056 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1007 ),
    ]);
    is_deeply( $CLASS->retrieve( 1060 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1020 ),
    ]);

    # -----------------------------
        $test->financial_setup( 4 );
    is_deeply( $CLASS->retrieve( 1043 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1001 ),
        eleMentalClinic::Financial::Transaction->retrieve( 1011 ),
    ]);
    is_deeply( $CLASS->retrieve( 1049 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1013 ),
    ]);
    is_deeply( $CLASS->retrieve( 1050 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1014 ),
        eleMentalClinic::Financial::Transaction->retrieve( 1025 ),
    ]);
    is_deeply( $CLASS->retrieve( 1350 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1014 ),
        eleMentalClinic::Financial::Transaction->retrieve( 1025 ),
    ]);
    is_deeply( $CLASS->retrieve( 1051 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1015 ),
        eleMentalClinic::Financial::Transaction->retrieve( 1026 ),
    ]);
    is_deeply( $CLASS->retrieve( 1351 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1012 ),
        eleMentalClinic::Financial::Transaction->retrieve( 1026 ),
    ]);
    is_deeply( $CLASS->retrieve( 1052 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1016 ),
        eleMentalClinic::Financial::Transaction->retrieve( 1027 ),
    ]);
    is_deeply( $CLASS->retrieve( 1056 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1007 ),
    ]);
    is_deeply( $CLASS->retrieve( 1060 )->valid_transactions, [
        eleMentalClinic::Financial::Transaction->retrieve( 1020 ),
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test for fix to ticket #213 (jamuna)
# Notes were not being created with a time stamp, and the sort did not 
# take timestamp into account. This caused notes created on the same day
# to be sorted improperly.

    # we have to specify created manually because the db time will be wrong;
    # it's frozen at transaction start time
    my $ID1 = $CLASS->new({
        client_id   => 1003,
        staff_id    => 1002,
        goal_id     => 0,
        start_date  => '2020-03-10 14:00:00',
        end_date    => '2020-03-10 18:00:00',
        note_body   => 'Alphabetically first',
        writer      => 'Betty Clinician',
        data_entry_id => 1002,
        charge_code_id => 1005,
        note_location_id => 1,
    })->save->rec_id;

    my $ID2 = $CLASS->new({
        client_id   => 1003,
        staff_id    => 1002,
        goal_id     => 0,
        start_date  => '2020-03-10 14:00:00',
        end_date    => '2020-03-10 18:00:00',
        note_body   => 'But this one should be on top.',
        writer      => 'Betty Clinician',
        data_entry_id => 1002,
        charge_code_id => 1005,
        note_location_id => 1,
        created     => strftime('%Y-%m-%d %H:%M:%S', localtime),
    })->save->rec_id;

    #Both should have a creation timestamp now, before the fix they did not.
    ok( $CLASS->retrieve( $ID1 )->created );
    ok( $CLASS->retrieve( $ID2 )->created );

    # the second one should have been created sooner
    cmp_ok(
        $CLASS->retrieve( $ID1 )->created, 'lt',
        $CLASS->retrieve( $ID2 )->created,
        'different timestamps',
    );

    #Check to make sure the 2 new ones are the top 2, newest first rather than 
    #alphabetical on the same day.
    is( $CLASS->list_all->[0]->{ rec_id }, $ID2, 'list_all, newest first' );
    is( $CLASS->list_all->[1]->{ rec_id }, $ID1, 'list_all, second newest' );

    #clean up the mess
    $CLASS->retrieve( $ID1 )->delete;
    $CLASS->retrieve( $ID2 )->delete;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# deprecated
    throws_ok{ $CLASS->locations } qr/DEPRECATED/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
