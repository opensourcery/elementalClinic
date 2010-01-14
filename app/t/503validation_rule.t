# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 293;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Financial::ValidationRule';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
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
    is( $one->table, 'validation_rule' );
    is( $one->primary_key, 'rec_id' );
    is_deeply( $one->fields, [ qw/
        rec_id name rule_select rule_from rule_where rule_order
        selects_pass error_message scope
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# system_rules
    can_ok( $CLASS, 'system_rules' );
    is_deeply( $CLASS->system_rules, [
        { %{ $validation_rule->{ 1001 }}, last_used => undef },
        { %{ $validation_rule->{ 1002 }}, last_used => undef },
        { %{ $validation_rule->{ 1003 }}, last_used => 1 },
        { %{ $validation_rule->{ 1004 }}, last_used => 1 },
        { %{ $validation_rule->{ 1009 }}, last_used => undef },
        { %{ $validation_rule->{ 1010 }}, last_used => undef },
        { %{ $validation_rule->{ 1011 }}, last_used => undef },
        { %{ $validation_rule->{ 1012 }}, last_used => undef },
        { %{ $validation_rule->{ 1013 }}, last_used => undef },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# payer_rules
    can_ok( $CLASS, 'payer_rules' );
    is_deeply( $CLASS->payer_rules, [
        $validation_rule->{ 1005 },
        $validation_rule->{ 1006 },
        $validation_rule->{ 1007 },
        $validation_rule->{ 1008 },
    ]);

    is_deeply( $CLASS->payer_rules( 666 ), [
        { %{ $validation_rule->{ 1005 }}, last_used => undef },
        { %{ $validation_rule->{ 1006 }}, last_used => undef },
        { %{ $validation_rule->{ 1007 }}, last_used => undef },
        { %{ $validation_rule->{ 1008 }}, last_used => undef },
    ]);
    is_deeply( $CLASS->payer_rules( 1009 ), [
        { %{ $validation_rule->{ 1005 }}, last_used => 1 },
        { %{ $validation_rule->{ 1006 }}, last_used => 1 },
        { %{ $validation_rule->{ 1007 }}, last_used => 1 },
        { %{ $validation_rule->{ 1008 }}, last_used => undef },
    ]);
    is_deeply( $CLASS->payer_rules( 1015 ), [
        { %{ $validation_rule->{ 1005 }}, last_used => 1 },
        { %{ $validation_rule->{ 1006 }}, last_used => 1 },
        { %{ $validation_rule->{ 1007 }}, last_used => undef },
        { %{ $validation_rule->{ 1008 }}, last_used => 1 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save rules, no payer
    can_ok( $CLASS, 'save_rules' );
    throws_ok{ $CLASS->save_rules } qr/At least one rule id, or a payer id, is required/;

    ok( $CLASS->save_rules([]));
    is_deeply( $CLASS->system_rules, [
        { %{ $validation_rule->{ 1001 }}, last_used => undef },
        { %{ $validation_rule->{ 1002 }}, last_used => undef },
        { %{ $validation_rule->{ 1003 }}, last_used => undef },
        { %{ $validation_rule->{ 1004 }}, last_used => undef },
        { %{ $validation_rule->{ 1009 }}, last_used => undef },
        { %{ $validation_rule->{ 1010 }}, last_used => undef },
        { %{ $validation_rule->{ 1011 }}, last_used => undef },
        { %{ $validation_rule->{ 1012 }}, last_used => undef },
        { %{ $validation_rule->{ 1013 }}, last_used => undef },
    ]);

        # this is very verbose, but we're doing it again to make sure other
        # rules aren't affected
        is_deeply( $CLASS->payer_rules( 666 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => undef },
            { %{ $validation_rule->{ 1006 }}, last_used => undef },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => undef },
        ]);
        is_deeply( $CLASS->payer_rules( 1009 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => 1 },
            { %{ $validation_rule->{ 1006 }}, last_used => 1 },
            { %{ $validation_rule->{ 1007 }}, last_used => 1 },
            { %{ $validation_rule->{ 1008 }}, last_used => undef },
        ]);
        is_deeply( $CLASS->payer_rules( 1015 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => 1 },
            { %{ $validation_rule->{ 1006 }}, last_used => 1 },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => 1 },
        ]);
        # end verbosity

    ok( $CLASS->save_rules([ qw/ 1001 /]));
    is_deeply( $CLASS->system_rules, [
        { %{ $validation_rule->{ 1001 }}, last_used => 1 },
        { %{ $validation_rule->{ 1002 }}, last_used => undef },
        { %{ $validation_rule->{ 1003 }}, last_used => undef },
        { %{ $validation_rule->{ 1004 }}, last_used => undef },
        { %{ $validation_rule->{ 1009 }}, last_used => undef },
        { %{ $validation_rule->{ 1010 }}, last_used => undef },
        { %{ $validation_rule->{ 1011 }}, last_used => undef },
        { %{ $validation_rule->{ 1012 }}, last_used => undef },
        { %{ $validation_rule->{ 1013 }}, last_used => undef },
    ]);

        # this is very verbose, but we're doing it again to make sure other
        # rules aren't affected
        is_deeply( $CLASS->payer_rules( 666 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => undef },
            { %{ $validation_rule->{ 1006 }}, last_used => undef },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => undef },
        ]);
        is_deeply( $CLASS->payer_rules( 1009 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => 1 },
            { %{ $validation_rule->{ 1006 }}, last_used => 1 },
            { %{ $validation_rule->{ 1007 }}, last_used => 1 },
            { %{ $validation_rule->{ 1008 }}, last_used => undef },
        ]);
        is_deeply( $CLASS->payer_rules( 1015 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => 1 },
            { %{ $validation_rule->{ 1006 }}, last_used => 1 },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => 1 },
        ]);
        # end verbosity

    ok( $CLASS->save_rules([ qw/ 1001 1002 1003 1004 /]));
    is_deeply( $CLASS->system_rules, [
        { %{ $validation_rule->{ 1001 }}, last_used => 1 },
        { %{ $validation_rule->{ 1002 }}, last_used => 1 },
        { %{ $validation_rule->{ 1003 }}, last_used => 1 },
        { %{ $validation_rule->{ 1004 }}, last_used => 1 },
        { %{ $validation_rule->{ 1009 }}, last_used => undef },
        { %{ $validation_rule->{ 1010 }}, last_used => undef },
        { %{ $validation_rule->{ 1011 }}, last_used => undef },
        { %{ $validation_rule->{ 1012 }}, last_used => undef },
        { %{ $validation_rule->{ 1013 }}, last_used => undef },
    ]);

        # this is very verbose, but we're doing it again to make sure other
        # rules aren't affected
        is_deeply( $CLASS->payer_rules( 666 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => undef },
            { %{ $validation_rule->{ 1006 }}, last_used => undef },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => undef },
        ]);
        is_deeply( $CLASS->payer_rules( 1009 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => 1 },
            { %{ $validation_rule->{ 1006 }}, last_used => 1 },
            { %{ $validation_rule->{ 1007 }}, last_used => 1 },
            { %{ $validation_rule->{ 1008 }}, last_used => undef },
        ]);
        is_deeply( $CLASS->payer_rules( 1015 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => 1 },
            { %{ $validation_rule->{ 1006 }}, last_used => 1 },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => 1 },
        ]);
        # end verbosity

    # reset to test values
    ok( $CLASS->save_rules([ qw/ 1003 1004 /]));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save rules with payer_id
    throws_ok{ $CLASS->save_rules([ qw/ 1003 1004 /], 666 )} qr/Payer id '666' does not exist./;

    ok( $CLASS->save_rules([], 1009 ));
    is_deeply( $CLASS->payer_rules( 1009 ), [
        { %{ $validation_rule->{ 1005 }}, last_used => undef },
        { %{ $validation_rule->{ 1006 }}, last_used => undef },
        { %{ $validation_rule->{ 1007 }}, last_used => undef },
        { %{ $validation_rule->{ 1008 }}, last_used => undef },
    ]);
        # this is very verbose, but we're doing it again to make sure other
        # rules aren't affected
        is_deeply( $CLASS->payer_rules( 666 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => undef },
            { %{ $validation_rule->{ 1006 }}, last_used => undef },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => undef },
        ]);
        is_deeply( $CLASS->payer_rules( 1015 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => 1 },
            { %{ $validation_rule->{ 1006 }}, last_used => 1 },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => 1 },
        ]);
        is_deeply( $CLASS->system_rules, [
            { %{ $validation_rule->{ 1001 }}, last_used => undef },
            { %{ $validation_rule->{ 1002 }}, last_used => undef },
            { %{ $validation_rule->{ 1003 }}, last_used => 1 },
            { %{ $validation_rule->{ 1004 }}, last_used => 1 },
            { %{ $validation_rule->{ 1009 }}, last_used => undef },
            { %{ $validation_rule->{ 1010 }}, last_used => undef },
            { %{ $validation_rule->{ 1011 }}, last_used => undef },
            { %{ $validation_rule->{ 1012 }}, last_used => undef },
            { %{ $validation_rule->{ 1013 }}, last_used => undef },
        ]);
        # end verbosity

    ok( $CLASS->save_rules([ qw/ 1005 1006 1007 1008 /], 1009 ));
    is_deeply( $CLASS->payer_rules( 1009 ), [
        { %{ $validation_rule->{ 1005 }}, last_used => 1 },
        { %{ $validation_rule->{ 1006 }}, last_used => 1 },
        { %{ $validation_rule->{ 1007 }}, last_used => 1 },
        { %{ $validation_rule->{ 1008 }}, last_used => 1 },
    ]);
        # this is very verbose, but we're doing it again to make sure other
        # rules aren't affected
        is_deeply( $CLASS->payer_rules( 666 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => undef },
            { %{ $validation_rule->{ 1006 }}, last_used => undef },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => undef },
        ]);
        is_deeply( $CLASS->payer_rules( 1015 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => 1 },
            { %{ $validation_rule->{ 1006 }}, last_used => 1 },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => 1 },
        ]);
        is_deeply( $CLASS->system_rules, [
            { %{ $validation_rule->{ 1001 }}, last_used => undef },
            { %{ $validation_rule->{ 1002 }}, last_used => undef },
            { %{ $validation_rule->{ 1003 }}, last_used => 1 },
            { %{ $validation_rule->{ 1004 }}, last_used => 1 },
            { %{ $validation_rule->{ 1009 }}, last_used => undef },
            { %{ $validation_rule->{ 1010 }}, last_used => undef },
            { %{ $validation_rule->{ 1011 }}, last_used => undef },
            { %{ $validation_rule->{ 1012 }}, last_used => undef },
            { %{ $validation_rule->{ 1013 }}, last_used => undef },
        ]);
        # end verbosity

    ok( $CLASS->save_rules([ qw/ 1007 /], 1015 ));
    is_deeply( $CLASS->payer_rules( 1015 ), [
        { %{ $validation_rule->{ 1005 }}, last_used => undef },
        { %{ $validation_rule->{ 1006 }}, last_used => undef },
        { %{ $validation_rule->{ 1007 }}, last_used => 1 },
        { %{ $validation_rule->{ 1008 }}, last_used => undef },
    ]);

        # this is very verbose, but we're doing it again to make sure other
        # rules aren't affected
        is_deeply( $CLASS->payer_rules( 666 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => undef },
            { %{ $validation_rule->{ 1006 }}, last_used => undef },
            { %{ $validation_rule->{ 1007 }}, last_used => undef },
            { %{ $validation_rule->{ 1008 }}, last_used => undef },
        ]);
        is_deeply( $CLASS->payer_rules( 1009 ), [
            { %{ $validation_rule->{ 1005 }}, last_used => 1 },
            { %{ $validation_rule->{ 1006 }}, last_used => 1 },
            { %{ $validation_rule->{ 1007 }}, last_used => 1 },
            { %{ $validation_rule->{ 1008 }}, last_used => 1 },
        ]);
        is_deeply( $CLASS->system_rules, [
            { %{ $validation_rule->{ 1001 }}, last_used => undef },
            { %{ $validation_rule->{ 1002 }}, last_used => undef },
            { %{ $validation_rule->{ 1003 }}, last_used => 1 },
            { %{ $validation_rule->{ 1004 }}, last_used => 1 },
            { %{ $validation_rule->{ 1009 }}, last_used => undef },
            { %{ $validation_rule->{ 1010 }}, last_used => undef },
            { %{ $validation_rule->{ 1011 }}, last_used => undef },
            { %{ $validation_rule->{ 1012 }}, last_used => undef },
            { %{ $validation_rule->{ 1013 }}, last_used => undef },
        ]);
        # end verbosity

    # reset to test values
    ok( $CLASS->save_rules([ qw/ 1005 1006 1007 /], 1009 ));
    ok( $CLASS->save_rules([ qw/ 1005 1006 1008 /], 1015 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# sanitize
    can_ok( $CLASS, 'sanitize' );
    is( $CLASS->sanitize, undef );

    # fails, since we're not specifying which type
    is( $CLASS->sanitize( '' ), undef );

    # false but defined, since nothing bad's being tried
    for( qw/ select from where order / ) {
        is( $CLASS->sanitize( $_ ), 0, "$_" );
    }

    for( qw/ select from order / ) {
        is( $CLASS->sanitize( $_, 'select' ), undef, $_ );
        is( $CLASS->sanitize( $_, 'sElEcT' ), undef, $_ );
        is( $CLASS->sanitize( $_, 'SELECT' ), undef, $_ );
    }

    # failures due to disallowed, for all types
    for( qw/ select from where order / ) {
        is( $CLASS->sanitize( $_, 'foo bar DROP baz' ), undef );
        is( $CLASS->sanitize( $_, 'DROP' ), undef );
        is( $CLASS->sanitize( $_, 'fee fi DELETE fo fum' ), undef );
        is( $CLASS->sanitize( $_, 'DELETE' ), undef );
        is( $CLASS->sanitize( $_, 'UPDATE' ), undef );
        is( $CLASS->sanitize( $_, 'INTO' ), undef );
        is( $CLASS->sanitize( $_, ';' ), undef );
        is( $CLASS->sanitize( $_, '--' ), undef );
        is( $CLASS->sanitize( $_, '; DROP TABLE sessions' ), undef );

        # bug-fix
        ok( $CLASS->sanitize( $_, "   lookup_groups.name like 'Non-HK'" ));
        ok( $CLASS->sanitize( $_, '-' ));
    }
    is( $CLASS->sanitize( 'where', 'SELECT' ), 'SELECT' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validation_query
        $one = $CLASS->new;
    can_ok( $one, 'validation_query' );

        $one = $CLASS->retrieve( 1001 );
    throws_ok{ $one->validation_query } qr/required/;

    is( $one->validation_query( '2006-01-01', '2006-02-01' ), <<EOT );
SELECT prognote.rec_id
FROM prognote
WHERE DATE( prognote.start_date ) BETWEEN DATE( '2006-01-01' ) AND DATE( '2006-02-01' )
ORDER BY prognote.rec_id
EOT

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# results, API
        $one = $CLASS->new;
    can_ok( $one, 'results' );
    throws_ok{ $one->results } qr/Must be called on a ValidationRule object./;

        $one = $CLASS->retrieve( 1001 );
    throws_ok{ $one->results } qr/Start date and end date are required./;
    throws_ok{ $one->results( '2006-07-01' )} qr/Start date and end date are required./;

        $one = $CLASS->retrieve( 1005 );
    throws_ok{ $one->results( '2006-07-01', '2006-07-02' )} qr/Payer id is required for payer rules./;
    throws_ok{ $one->results( '2006-07-01', '2006-07-02', 666 )} qr/Nonexistent payer id./;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# results, individual rules
    # all pass, system
    is_deeply( $CLASS->retrieve( 1001 )->results( '2006-07-01', '2006-07-10' ), [
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
    ]);

    # all fail, system
    is_deeply( $CLASS->retrieve( 1002 )->results( '2006-07-01', '2006-07-10' ), [
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
    ]);

    # all pass, payer
    is_deeply( $CLASS->retrieve( 1006 )->results( '2006-07-01', '2006-07-10', 1001 ), [
        { %{ $prognote->{ 1144 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1143 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1056 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1043 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1145 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1065 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1044 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1159 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1157 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1057 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1045 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1158 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1058 }}, rule_1006 => 1, pass => 1 },
        { %{ $prognote->{ 1046 }}, rule_1006 => 1, pass => 1 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# results_preview

    # Make sure all the template fields are present.
    for my $note ( @{ $CLASS->retrieve( 1001 )->results_preview( '2006-07-01', '2006-07-10' )}) {
        for my $key ( 
            qw/ 
                client_id start_date pass bill_manually id note_duration 
                charge_code_name location_name note_units client_name 
                note_body writer
            /
        ) {
            ok(
                defined $note->{ $key },
                "Note: " . $note->{ id } . '->{ ' . $key . ' }: ' . $note->{ $key } #Something useful
            );
        }
    }

    #The wrapper should return the same number of results as the original.
    is( 
        @{ $CLASS->retrieve( 1001 )->results_preview( '2006-07-01', '2006-07-10' )},
        @{ $CLASS->retrieve( 1001 )->results( '2006-07-01', '2006-07-10' )}
    );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
