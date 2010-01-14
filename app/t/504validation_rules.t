# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 148;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Financial::ValidationSet';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
    financial_reset_sequences();
}
dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# all pass this rule
    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date       => '2006-07-01',
        to_date         => '2006-07-15',
    }));

    is_deeply( $one->test_validate_sql( $validation_rule->{ 1001 }),
        [ qw/ 1043 1044 1045 1046 1047 1048 1056 1057 1058 1059 1065 1066 1143 1144 1145 1157 1158 1159 /]
    );
    ok( $one->live_validate_sql( $validation_rule->{ 1001 }));
    is( $one->status, 'Validating' );
    is_deeply( $one->rule_ids, [ qw/ 1001 /]);
    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rules_failed_by_prognote_id
    can_ok( $one, 'rules_failed_by_prognote_id' );
    throws_ok{ $one->rules_failed_by_prognote_id } qr/Progress note id is required/;

    is( $one->rules_failed_by_prognote_id( 1043 ), undef );
    is( $one->rules_failed_by_prognote_id( 1044 ), undef );
    is( $one->rules_failed_by_prognote_id( 1045 ), undef );
    is( $one->rules_failed_by_prognote_id( 1046 ), undef );
    is( $one->rules_failed_by_prognote_id( 1047 ), undef );
    is( $one->rules_failed_by_prognote_id( 1048 ), undef );
    is( $one->rules_failed_by_prognote_id( 1056 ), undef );
    is( $one->rules_failed_by_prognote_id( 1057 ), undef );
    is( $one->rules_failed_by_prognote_id( 1058 ), undef );
    is( $one->rules_failed_by_prognote_id( 1059 ), undef );
    is( $one->rules_failed_by_prognote_id( 1065 ), undef );
    is( $one->rules_failed_by_prognote_id( 1066 ), undef );
    is( $one->rules_failed_by_prognote_id( 1143 ), undef );
    is( $one->rules_failed_by_prognote_id( 1144 ), undef );
    is( $one->rules_failed_by_prognote_id( 1145 ), undef );
    is( $one->rules_failed_by_prognote_id( 1157 ), undef );
    is( $one->rules_failed_by_prognote_id( 1158 ), undef );
    is( $one->rules_failed_by_prognote_id( 1159 ), undef );
        $test->delete_( 'validation_result', '*' );

    is_deeply_except( { billing_status => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1001 )->results( '2006-07-01', '2006-07-15' ),
        [
            { %{ $prognote->{ 1144 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1159 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1157 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1057 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1045 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1158 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1058 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1059 }}, rule_1001 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }}, rule_1001 => 1, pass => 1 },
        ],
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# all fail this rule
    is( $one->test_validate_sql( $validation_rule->{ 1002 }), undef );
    ok( $one->live_validate_sql( $validation_rule->{ 1002 }));
    is( $one->status, 'Validating' );
    is_deeply( $one->rule_ids, [ qw/ 1002 /]);
    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1002 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);
        $test->delete_( 'validation_result', '*' );

    is_deeply_except( { billing_status => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1002 )->results( '2006-07-01', '2006-07-15' ),
        [
            { %{ $prognote->{ 1144 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1143 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1056 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1043 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1145 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1065 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1044 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1159 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1157 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1057 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1045 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1158 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1058 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1046 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1066 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1047 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1059 }}, rule_1002 => 0, pass => 0 },
            { %{ $prognote->{ 1048 }}, rule_1002 => 0, pass => 0 },
        ],
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# arbitrary rule, excludes july 7, 2006
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1009 }),
        [ qw/ 1043 1044 1046 1047 1048 1056 1058 1059 1065 1066 1143 1144 1145 /]
    );
    is_deeply_except( { billing_status => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1009 )->results( '2006-07-01', '2006-07-15' ),
        [
            { %{ $prognote->{ 1144 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1159 }}, rule_1009 => 0, pass => 0 },
            { %{ $prognote->{ 1157 }}, rule_1009 => 0, pass => 0 },
            { %{ $prognote->{ 1057 }}, rule_1009 => 0, pass => 0 },
            { %{ $prognote->{ 1045 }}, rule_1009 => 0, pass => 0 },
            { %{ $prognote->{ 1158 }}, rule_1009 => 0, pass => 0 },
            { %{ $prognote->{ 1058 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1059 }}, rule_1009 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }}, rule_1009 => 1, pass => 1 },
        ],
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# duplicate check rule
# FIXME passes, but only because we're excluding notes by id
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1010 }),
        [ qw/ 1043 1044 1045 1046 1047 1048 1056 1057 1058 1059 1065 1066 /]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rule 1004: charge code must exist and be active
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1004 }),
        [ qw/ 1043 1044 1045 1046 1047 1048 1056 1057 1058 1059 1065 1066 1143 1144 1145 1157 1158 1159 /]
    );
    is_deeply_except( { billing_status => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1004 )->results( '2006-07-01', '2006-07-15' ),
        [
            { %{ $prognote->{ 1144 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1159 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1157 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1057 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1045 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1158 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1058 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1059 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }}, rule_1004 => 1, pass => 1 },
        ],
    );

        # deactivate charge code 1015
        eleMentalClinic::ValidData->new({ dept_id => 1001 })->save( '_charge_code',
            { %{ $valid_data_charge_code->{ 1015 }}, active => 0 }
        );
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1004 }),
        [ qw/ 1043 1045 1046 1048 1056 1057 1058 1059 1065 1066 1143 1144 1145 1157 1158 1159 /]
    );
    is_deeply_except( { billing_status => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1004 )->results( '2006-07-01', '2006-07-15' ),
        [
            { %{ $prognote->{ 1144 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1159 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1157 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1057 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1045 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1158 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1058 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1059 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }}, rule_1004 => 1, pass => 1 },
        ],
    );

        # deactivate charge code 1005
        eleMentalClinic::ValidData->new({ dept_id => 1001 })->save( '_charge_code',
            { %{ $valid_data_charge_code->{ 1005 }}, active => 0 }
        );
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1004 }),
        [ qw/ 1043 1048 1143 1144 1145 /]
    );
    is_deeply_except( { billing_status => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1004 )->results( '2006-07-01', '2006-07-15' ),
        [
            { %{ $prognote->{ 1144 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1043 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1004 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1044 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1159 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1157 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1057 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1045 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1158 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1058 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1046 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1066 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1047 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1059 }}, rule_1004 => 0, pass => 0 },
            { %{ $prognote->{ 1048 }}, rule_1004 => 1, pass => 1 },
        ],
    );

        # cleanup
        eleMentalClinic::ValidData->new({ dept_id => 1001 })->save( '_charge_code',
            { %{ $valid_data_charge_code->{ 1015 }}, active => 1 }
        );
        eleMentalClinic::ValidData->new({ dept_id => 1001 })->save( '_charge_code',
            { %{ $valid_data_charge_code->{ 1005 }}, active => 1 }
        );
        $test->delete_( 'validation_result', '*' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rule to find 'identical' prognotes for a client, when one has been previously billed, and this one hasn't

    # all pass before anything is billed
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1013 } ),
        [ qw/ 1144 1043 1056 1143 1145 1044 1065 1159 1045 1057 1157 1158 1046 1058 1047 1066 1048 1059 /]
    );

    is_deeply_except( { billing_status => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1013 )->results( '2006-07-01', '2006-07-15' ),
        [
            { %{ $prognote->{ 1144 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1159 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1157 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1057 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1045 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1158 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1058 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1059 }}, rule_1013 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }}, rule_1013 => 1, pass => 1 },
        ],
    );

    # See further tests after billing, in 518combined_notes.t

        $test->delete_( 'validation_result', '*' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rule 1005: charge code must be accepted by payer
    # 1015, only one fails
    is_deeply_except( { billing_status => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1005 )->results( '2006-07-01', '2006-07-15', 1015 ),
        [
            { %{ $prognote->{ 1144 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }}, rule_1005 => 0, pass => 0 },
            { %{ $prognote->{ 1159 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1157 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1057 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1045 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1158 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1058 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }}, rule_1005 => 0, pass => 0 },
            { %{ $prognote->{ 1059 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }}, rule_1005 => 1, pass => 1 },
        ],
    );

    # 1013, none fail
    is_deeply_except( { billing_status => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1005 )->results( '2006-07-01', '2006-07-15', 1013 ),
        [
            { %{ $prognote->{ 1144 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1065 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1159 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1157 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1057 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1045 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1158 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1058 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1059 }}, rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }}, rule_1005 => 1, pass => 1 },
        ],
    );

    # change some data and try again
        eleMentalClinic::ProgressNote->retrieve( 1143 )->charge_code_id( 1018 )->save; # pass
        eleMentalClinic::ProgressNote->retrieve( 1144 )->charge_code_id( 1020 )->save; # pass
        eleMentalClinic::ProgressNote->retrieve( 1145 )->charge_code_id( 1023 )->save; # fail
        eleMentalClinic::ProgressNote->retrieve( 1157 )->charge_code_id( 1024 )->save; # fail
        eleMentalClinic::ProgressNote->retrieve( 1158 )->charge_code_id( 1034 )->save; # fail
        eleMentalClinic::ProgressNote->retrieve( 1159 )->charge_code_id( 1035 )->save; # fail

    # 1013, many fail
    is_deeply_except( { billing_status => undef, modified => undef },
         eleMentalClinic::Financial::ValidationRule->retrieve( 1005 )->results( '2006-07-01', '2006-07-15', 1013 ),
        [
            { %{ $prognote->{ 1144 }}, charge_code_id => 1020 , rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1143 }}, charge_code_id => 1018 , rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1056 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1043 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1145 }}, charge_code_id => 1023 , rule_1005 => 0, pass => 0 },
            { %{ $prognote->{ 1065 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1044 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1159 }}, charge_code_id => 1035 , rule_1005 => 0, pass => 0 },
            { %{ $prognote->{ 1157 }}, charge_code_id => 1024 , rule_1005 => 0, pass => 0 },
            { %{ $prognote->{ 1057 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1045 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1158 }}, charge_code_id => 1034 , rule_1005 => 0, pass => 0 },
            { %{ $prognote->{ 1058 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1046 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1066 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1047 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1059 }},                          rule_1005 => 1, pass => 1 },
            { %{ $prognote->{ 1048 }},                          rule_1005 => 1, pass => 1 },
        ],
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# running all four rules
    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date       => '2006-07-01',
        to_date         => '2006-07-15',
    }));

    ok( $one->live_validate_sql( $validation_rule->{ 1001 }), 'rule 1001' );
    ok( $one->live_validate_sql( $validation_rule->{ 1002 }), 'rule 1002' );
    ok( $one->live_validate_sql( $validation_rule->{ 1003 }), 'rule 1003' );
    ok( $one->live_validate_sql( $validation_rule->{ 1004 }), 'rule 1004' );
    is( $one->status, 'Validating' );
    is_deeply( $one->rule_ids, [ qw/ 1001 1002 1003 1004 /]);
    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rules_failed_by_prognote_id
    can_ok( $one, 'rules_failed_by_prognote_id' );
    throws_ok{ $one->rules_failed_by_prognote_id } qr/Progress note id is required/;
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1043 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1044 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1045 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1046 )), [ 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1047 )), [ 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1048 )), [ 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1056 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1057 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1058 )), [ 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1059 )), [ 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1065 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1066 )), [ 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1143 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1144 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1145 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1157 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1158 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1159 )), [ 1002 ]);
        $test->delete_( 'validation_result', '*' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate method
        # munge data to make some more notes fail
        eleMentalClinic::Client->retrieve( 1003 )->address->address1( '' )->save;
        eleMentalClinic::ValidData->new({ dept_id => 1001 })->save( '_charge_code',
            { %{ $valid_data_charge_code->{ 1015 }}, active => 0 }
        );

    ok( $one->system_validation([ qw/ 1001 1002 1003 1004 /]));
    is( $one->status, 'Validated' );
    is_deeply( $one->rule_ids, [ qw/ 1001 1002 1003 1004 /]);
    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1002 => 0, rule_1003 => 0, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1002 => 0, rule_1003 => 0, rule_1004 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1002 => 0, rule_1003 => 0, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1002 => 0, rule_1003 => 0, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1002 => 0, rule_1003 => 0, rule_1004 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1002 => 0, rule_1003 => 0, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1002 => 0, rule_1003 => 0, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1002 => 0, rule_1003 => 0, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1002 => 0, rule_1003 => 0, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1002 => 0, rule_1003 => 1, rule_1004 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);

    is_deeply( ids( $one->rules_failed_by_prognote_id( 1043 )), [ 1003, 1002, ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1044 )), [ 1004, 1003, 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1045 )), [ 1003, 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1046 )), [ 1003, 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1047 )), [ 1004, 1003, 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1048 )), [ 1003, 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1056 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1057 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1058 )), [ 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1059 )), [ 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1065 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1066 )), [ 1002 ]); 
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1143 )), [ 1003, 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1144 )), [ 1003, 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1145 )), [ 1003, 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1157 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1158 )), [ 1002 ]);
    is_deeply( ids( $one->rules_failed_by_prognote_id( 1159 )), [ 1002 ]);

    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1043 )->validation_rules_failed( $one->id )), [ 1003, 1002, ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1044 )->validation_rules_failed( $one->id )), [ 1004, 1003, 1002 ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1045 )->validation_rules_failed( $one->id )), [ 1003, 1002 ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1046 )->validation_rules_failed( $one->id )), [ 1003, 1002 ]); 
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1047 )->validation_rules_failed( $one->id )), [ 1004, 1003, 1002 ]); 
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1048 )->validation_rules_failed( $one->id )), [ 1003, 1002 ]); 
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1056 )->validation_rules_failed( $one->id )), [ 1002 ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1057 )->validation_rules_failed( $one->id )), [ 1002 ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1058 )->validation_rules_failed( $one->id )), [ 1002 ]); 
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1059 )->validation_rules_failed( $one->id )), [ 1002 ]); 
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1065 )->validation_rules_failed( $one->id )), [ 1002 ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1066 )->validation_rules_failed( $one->id )), [ 1002 ]); 
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1143 )->validation_rules_failed( $one->id )), [ 1003, 1002 ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1144 )->validation_rules_failed( $one->id )), [ 1003, 1002 ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1145 )->validation_rules_failed( $one->id )), [ 1003, 1002 ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1157 )->validation_rules_failed( $one->id )), [ 1002 ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1158 )->validation_rules_failed( $one->id )), [ 1002 ]);
    is_deeply( ids( eleMentalClinic::ProgressNote->retrieve( 1159 )->validation_rules_failed( $one->id )), [ 1002 ]);

        $test->delete_( 'validation_result', '*' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# testing the "exclude paid" rule on every note in the database
        dbinit( 1 );

    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date       => '1970-01-01',
        to_date         => '2006-07-15',
    }));
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1011 }),
        [ qw/ 1043 1044 1045 1046 1047 1048 1056 1057 1058 1059 1065 1066 1143 1144 1145 1157 1158 1159 /]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bug-fix:  rule 1011 appears to give different results for billing cycle and validation set
    dbinit( 1 );

    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date       => '2006-07-01',
        to_date         => '2006-07-15',
    }));

    ok( $one->live_validate_sql( $validation_rule->{ 1011 }), 'rule 1011' );
    is_deeply( $one->rule_ids, [ qw/ 1011 /]);
    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
    ]);

    # now for validation set
    dbinit( 1 );

    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'validation',
        from_date       => '2006-07-01',
        to_date         => '2006-07-15',
    }));

    ok( $one->live_validate_sql( $validation_rule->{ 1011 }), 'rule 1011' );
    is_deeply( $one->rule_ids, [ qw/ 1011 /]);
    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => undef, validation_prognote_id => 1001, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => undef, validation_prognote_id => 1002, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1045 ), billing_status => undef, validation_prognote_id => 1003, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => undef, validation_prognote_id => 1004, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => undef, validation_prognote_id => 1005, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => undef, validation_prognote_id => 1006, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => undef, validation_prognote_id => 1007, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => undef, validation_prognote_id => 1008, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => undef, validation_prognote_id => 1009, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => undef, validation_prognote_id => 1010, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => undef, validation_prognote_id => 1011, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => undef, validation_prognote_id => 1012, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => undef, validation_prognote_id => 1013, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1144 ), billing_status => undef, validation_prognote_id => 1014, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1145 ), billing_status => undef, validation_prognote_id => 1015, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1157 ), billing_status => undef, validation_prognote_id => 1016, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1158 ), billing_status => undef, validation_prognote_id => 1017, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1159 ), billing_status => undef, validation_prognote_id => 1018, rule_1011 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    for my $method (qw( system_default_rules payer_default_rules )) {
        is_deeply(
            [ map { $_->rule_where } 
                @{ eleMentalClinic::Financial::ValidationRule->$method }
            ],
            [ 
                undef,
            ],
            "$method: the only default rule has an empty where",
        );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
