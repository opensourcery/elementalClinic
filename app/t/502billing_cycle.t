# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 670;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Financial::BillingCycle';
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
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'billing_cycle');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id creation_date staff_id step status
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# new_file
    can_ok( $CLASS, 'new_file' );
        # valid BillingCycle, saved
        $one->staff_id(1);
        $one->save;
    is( $one->new_file, undef );
    throws_ok{
      $test->db->transaction_do(sub { $one->new_file(-1) })
    } qr/Catchable Exception/, 'cannot violate rolodex foreign key constraint';
    my $new_file = $one->new_file(1009);
    my $check_file = eleMentalClinic::Financial::BillingFile->retrieve($new_file->id);  
    is_deeply( $new_file, $check_file );

        $one->empty;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bill_manual_combined_notes
    can_ok( $CLASS, 'bill_manual_combined_notes' );
    throws_ok{ $CLASS->bill_manual_combined_notes } qr/required/;
    throws_ok{ $CLASS->bill_manual_combined_notes( [] )} qr/required/;
    throws_ok{ $CLASS->bill_manual_combined_notes( [], 1 )} qr/required/;
    throws_ok{ $CLASS->bill_manual_combined_notes( [], 1, 1 )} qr/required/, 'note_ids must hold ids';
    throws_ok {$CLASS->bill_manual_combined_notes([1], 1, 1)} qr/eleMentalClinic::Client::Insurance/, 'client_insurance_id must link to a valid client_insurance record';
    throws_ok {$CLASS->bill_manual_combined_notes([1], 1, 1003)} qr/eleMentalClinic::ProgressNote/, 'note_ids must be valid prognotes';    
    $test->db->transaction_do(sub { 
        local $SIG{__WARN__} = sub {}; # shut up, we know it fails
        is( $CLASS->bill_manual_combined_notes([1044], -1, 1003), undef, 'BillingCycle.staff_id must link to an existing personnel row.' );
    });

        my $insurance = eleMentalClinic::Client::Insurance->retrieve( 1003 );
        my $pnote = eleMentalClinic::ProgressNote->retrieve(1044);
TODO: {
    local $TODO = 'should add tests checking that we have transactions prior to bill_manual_combined_notes and that they are refunded';
    # financial_setup(1) would add transactions but this test code probably needs some tweaking for that
    ok( @{$pnote->valid_transactions} > 0, 'prognote should have some transactions to be refunded.' );
}

        my $cycle = $CLASS->bill_manual_combined_notes([1044], 1, 1003);
    isa_ok( $cycle, 'eleMentalClinic::Financial::BillingCycle' );
    is( $cycle->staff_id, 1);
        my $files = $cycle->get_billing_files;
    is( scalar(@$files), 1, 'Only 1 billing file associated with the cycle.' );
        my $manual_file = $files->[0];
    is( $manual_file->rolodex_id, $insurance->rolodex_id );

#    print Dumper $cycle;
#    print Dumper $manual_file;

    is_deeply( $manual_file->billing_claims, [
          bless( {
                   'billing_file_id' => '1003',
                   'client_id' => '1003',
                   'client_insurance_authorization_id' => '1004',
                   'client_insurance_id' => '1003',
                   'insurance_rank' => '1',
                   'rec_id' => '1001',
                   'staff_id' => '1002'
                 }, 'eleMentalClinic::Financial::BillingClaim' )
    ]);

        my $claim = $manual_file->billing_claims->[0];
#    print Dumper $claim->billing_services;
        my $service = $claim->billing_services->[0];
    is_deeply( $service, 
          bless( {
                   'billed_amount' => '131.44',
                   'billed_units' => '2',
                   'billing_claim_id' => '1001',
                   'line_number' => '1',
                   'rec_id' => '1001'
                 }, 'eleMentalClinic::Financial::BillingService' )
    );
#    print Dumper $service->billing_prognotes;
    is( $service->billing_prognotes->[0]->prognote->billing_status, 'BilledManually' );

dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# XXX copied from validation_rule tests
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
# XXX copied from validation_rule tests
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
# clients
    can_ok( $one, 'clients' );
    is( $one->clients, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create validation set and billing cycle, set up test data
    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date       => '2006-07-01',
        to_date         => '2006-07-15',
    })->billing_cycle );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get active
    can_ok( $CLASS, 'get_active' );
    is_deeply( $CLASS->get_active, [ $one ]);
    isa_ok( $_, $CLASS )
        for @{ $CLASS->get_active };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clients
    is_deeply( $one->clients, {
        1003    => $client->{ 1003 },
        1004    => $client->{ 1004 },
        1005    => $client->{ 1005 },
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid notes
    can_ok( $one, 'valid_notes' );
    is( $one->valid_notes, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validation set
        $one = $CLASS->new;
    can_ok( $one, 'validation_set' );
    is( $one->validation_set, undef );

        $one = $CLASS->get_active->[ 0 ];
    isa_ok( $one->validation_set, 'eleMentalClinic::Financial::ValidationSet' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# personnel
        $one = $CLASS->new;
    can_ok( $one, 'personnel' );
    is( $one->personnel, undef );

        $one = $CLASS->get_active->[ 0 ];
    isa_ok( $one->personnel, 'eleMentalClinic::Personnel' );
    is_deeply( $one->personnel->staff_id, 1005 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step & status
        $one = $CLASS->new;
    is( $one->step, undef );
    is( $one->status, undef );

        $one = $CLASS->get_active->[ 0 ];
    is( $one->step, 1 );
    is( $one->status, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# checking prognotes
        $one = $CLASS->new;
    is( $one->prognotes, undef );

        $one = $CLASS->get_active->[ 0 ];
    is( scalar @{ $one->prognotes }, 18 );
    is_deeply( ids( $one->prognotes ), [ qw/
        1144 1043 1056 1143 1145 1044 1065 1159 1045 1057 1157 1158 1046 1058 1047 1066 1048 1059
    /]);
    for my $prognote_id( @{ ids $one->prognotes }) {
        is( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
    }
    is_deeply( $one->prognotes, $one->validation_set->prognotes );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prognotes by payer
    is( $one->prognotes( 666 ), undef );
    is( $one->prognotes( 1009 ), undef );
    is( $one->prognotes( 1015 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prognote count by payer
    is( $one->prognote_count, 18 );
    is( $one->prognote_count( 666 ), 0 );
    is( $one->prognote_count( 1009 ), 0 );
    is( $one->prognote_count( 1015 ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# result count by payer

    is( $one->result_count, 0 );
    is( $one->result_count( undef, 666 ), 0 );
    is( $one->result_count( undef, 1009 ), 0 );
    is( $one->result_count( undef, 1015 ), 0 );

    is( $one->result_count( '', 666 ), 0 );
    is( $one->result_count( '', 1009 ), 0 );
    is( $one->result_count( '', 1015 ), 0 );

    is( $one->result_count( 1 ), 0 );
    is( $one->result_count( 1, 666 ), 0 );
    is( $one->result_count( 1, 1009 ), 0 );
    is( $one->result_count( 1, 1015 ), 0 );

    is( $one->result_count( 0 ), 0 );
    is( $one->result_count( 0, 666 ), 0 );
    is( $one->result_count( 0, 1009 ), 0 );
    is( $one->result_count( 0, 1015 ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setup for next tests
    ok( $one->validation_set->system_validation([ qw/ 1001 1003 1004 1010 /]));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rules used
    is_deeply( $one->system_rules_used, [
        $validation_rule->{ 1001 },
        $validation_rule->{ 1003 },
        $validation_rule->{ 1004 },
        $validation_rule->{ 1010 },
    ]);
    is( $one->payer_rules_used( 1009 ), undef );
    is( $one->payer_rules_used( 1015 ), undef );
    is_deeply( $one->system_rules_used, $one->validation_set->system_rules_used );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is payer validated?
    eval { $one->payer_is_validated };
    ok( my $error = $@ );
    like( $error, qr/Payer id is required/ );
    is( $one->payer_is_validated( 1009 ), 0 );
    is( $one->payer_is_validated( 1015 ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is payer validated?
        $one = $CLASS->new;
    throws_ok{ $one->payer_has_billable_notes } qr/Must/;

        $one = $CLASS->get_active->[ 0 ];
    throws_ok{ $one->payer_has_billable_notes } qr/Payer id is required/;
    is( $one->payer_has_billable_notes( 666 ), 0 );
    is( $one->payer_has_billable_notes( 1009 ), 0 );
    is( $one->payer_has_billable_notes( 1015 ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# results
    is( scalar @{ $one->results }, 18 );
    is( scalar @{ $one->results( 1 )}, 12 );
    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);

    is_deeply( $one->results( 1 ), [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
    ]);

    is_deeply( $one->results( 0 ), [
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);                                                                                         

    is_deeply( $one->results, $one->validation_set->results );
    is_deeply( $one->results( 1 ), $one->validation_set->results( 1 ));
    is_deeply( $one->results( 0 ), $one->validation_set->results( 0 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validation prognotes by insurer
        $one = $CLASS->new;
    can_ok( $one, 'validation_prognotes_by_insurer' );
    is( $one->validation_prognotes_by_insurer, undef );

        $one = $CLASS->get_active->[ 0 ];
    is( scalar keys %{ $one->validation_prognotes_by_insurer }, 2 );
    is( scalar @{ $one->validation_prognotes_by_insurer->{ 1009 }}, 2 );
    is( scalar @{ $one->validation_prognotes_by_insurer->{ 1015 }}, 10 );

    is_deeply( $one->validation_prognotes_by_insurer, {
        1009 => [ qw/
            1065 1066 
        /],
        1015 => [ qw/
            1043 1044 1045 1046 1047 1048 1056 1057 1058 1059
        /],
    });
    is_deeply( $one->validation_prognotes_by_insurer, $one->validation_set->validation_prognotes_by_insurer );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validation prognote force valid
    can_ok( $CLASS, 'validation_prognote_force_valid' );
    throws_ok{ $CLASS->validation_prognote_force_valid } qr/Validation prognote id is required/;

    ok( $CLASS->validation_prognote_force_valid( 1001, 1 ));
    ok( $CLASS->validation_prognote_force_valid( 1002, 'true' ));
    ok( $CLASS->validation_prognote_force_valid( 1003, 0 ));
    ok( $CLASS->validation_prognote_force_valid( 1004, 0 ));
    ok( $CLASS->validation_prognote_force_valid( 1005, undef ));
    ok( $CLASS->validation_prognote_force_valid( 1006 ));
    ok( $CLASS->validation_prognote_force_valid( 1013, 1 ));
    ok( $CLASS->validation_prognote_force_valid( 1014, 1 ));
    ok( $CLASS->validation_prognote_force_valid( 1015, 0 ));
    ok( $CLASS->validation_prognote_force_valid( 1016, 0 ));

    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => 1,     pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => 1,     pass => 1, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => 0,     pass => 0, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => 0,     pass => 0, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => 1,     pass => 1, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => 1,     pass => 1, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => 0,     pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => 0,     pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);

    is_deeply( $one->results( 1 ), [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => 1,     pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => 1,     pass => 1, },
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => 1,     pass => 1, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => 1,     pass => 1, },
    ]);                                                                                         
    is_deeply( $one->results( 0 ), [
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => 0,     pass => 0, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => 0,     pass => 0, }, 
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => 0,     pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => 0,     pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);                                                                                         

    is_deeply( $one->results, $one->validation_set->results );
    is_deeply( $one->results( 1 ), $one->validation_set->results( 1 ));
    is_deeply( $one->results( 0 ), $one->validation_set->results( 0 ));

    is_deeply( $one->validation_prognotes_by_insurer, {
        1009 => [ qw/
            1065 1066 
        /],
        1015 => [ qw/
            1043 1044 1047 1048 1056 1057 1058 1059 1143 1144
        /],
    });

    ok( $CLASS->validation_prognote_force_valid( 1001 ));
    ok( $CLASS->validation_prognote_force_valid( 1002 ));
    ok( $CLASS->validation_prognote_force_valid( 1003 ));
    ok( $CLASS->validation_prognote_force_valid( 1004 ));
    ok( $CLASS->validation_prognote_force_valid( 1005 ));
    ok( $CLASS->validation_prognote_force_valid( 1006 ));
    ok( $CLASS->validation_prognote_force_valid( 1013 ));
    ok( $CLASS->validation_prognote_force_valid( 1014 ));
    ok( $CLASS->validation_prognote_force_valid( 1015 ));
    ok( $CLASS->validation_prognote_force_valid( 1016 ));

    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);                                                                                         

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# insurers
    can_ok( $one, 'insurers' );
    is( $one->insurers, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# group notes by insurer
        $one = $CLASS->new;
    can_ok( $one, 'group_prognotes_by_insurer' );
    is( $one->group_prognotes_by_insurer, undef );

        $one->id( 1001 )->retrieve;
    ok( $one->group_prognotes_by_insurer );
    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009,  force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009,  force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);

    is_deeply( $one->results( 1 ), [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015, force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015, force_valid => undef, pass => 1, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015, force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015, force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015, force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015, force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009, force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009, force_valid => undef, pass => 1, }, 
    ]);
    is_deeply( $one->results( 0 ), [
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);

    is_deeply( $one->results, $one->validation_set->results );
    is_deeply( $one->results( 1 ), $one->validation_set->results( 1 ));
    is_deeply( $one->results( 0 ), $one->validation_set->results( 0 ));

    is_deeply( $one->insurers, [
        $rolodex->{ 1009 },
        $rolodex->{ 1015 },
    ]);
    isa_ok( $_, 'eleMentalClinic::Rolodex' )
        for @{ $one->insurers };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# result counts
    is( $one->result_count, 18 );
    is( $one->result_count( undef, 666 ), 0 );
    is( $one->result_count( undef, 1009 ), 2 );
    is( $one->result_count( undef, 1015 ), 10 );

    is( $one->result_count( '', 666 ), 0 );
    is( $one->result_count( '', 1009 ), 2 );
    is( $one->result_count( '', 1015 ), 10 );

    is( $one->result_count( 1 ), 12 );
    is( $one->result_count( 1, 666 ), 0 );
    is( $one->result_count( 1, 1009 ), 2 );
    is( $one->result_count( 1, 1015 ), 10 );

    is( $one->result_count( 0 ), 6 );
    is( $one->result_count( 0, 666 ), 0 );
    is( $one->result_count( 0, 1009 ), 0 );
    is( $one->result_count( 0, 1015 ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prognotes by insurer
    is_deeply( ids( $one->prognotes ), [ qw/
        1144 1043 1056 1143 1145 1044 1065 1159 1045 1057 1157 1158 1046 1058 1047 1066 1048 1059
    /]);
    for my $prognote_id( @{ ids $one->prognotes }) {
        is( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
    }

    is( $one->prognote_count( 666 ), 0 );
    is( $one->prognotes( 666 ), undef );

    is( $one->prognote_count( 1009 ), 2 );
    is_deeply( ids( $one->prognotes( 1009 )), [ qw/
        1065 1066
    /]);
    for my $prognote_id( @{ ids $one->prognotes( 1009 )}) {
        is( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
    }

    is( $one->prognote_count( 1015 ), 10 );
    is_deeply( ids( $one->prognotes( 1015 )), [ qw/
        1043 1056 1044 1045 1057 1046 1058 1047 1048 1059
    /]);
    for my $prognote_id( @{ ids $one->prognotes( 1015 )}) {
        is( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rule 1005, payer must accept charge code
# also, more generic test for validation
        $one = $CLASS->new;
    can_ok( $one, 'test_validate_sql' );
    is( $one->test_validate_sql, undef );

        $one->id( 1001 )->retrieve;
    is( $one->test_validate_sql, undef );
    is_deeply( $one->test_validate_sql( { %{ $validation_rule->{ 1005 }}, selects_pass => 1, }, 1015 ),
        [ qw/ 1044 1047 /]
    );

    is_deeply( $one->test_validate_sql({ %{ $validation_rule->{ 1005 }}, selects_pass => 0, }, 1015 ),
        [ qw/ 1043 1056 1045 1057 1046 1058 1048 1059 /]
    );
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1005 }, 1015 ),
        [ qw/ 1043 1056 1045 1057 1046 1058 1048 1059 /]
    );

    # 1009
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1005 }, 1009 ),
        [ qw/ 1065 1066 /]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# payer-specific rules should only ever return notes for payers,
# regardless of rule
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1006 }, 1009 ),
        [ qw/ 1065 1066 /]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate for real
    ok( $one->live_validate_sql( $validation_rule->{ 1005 }, 1009 ));

        # used rules
        is_deeply( $one->system_rules_used, [
            $validation_rule->{ 1001 },
            $validation_rule->{ 1003 },
            $validation_rule->{ 1004 },
            $validation_rule->{ 1010 },
        ]);
        is_deeply( $one->payer_rules_used( 1009 ), [
            $validation_rule->{ 1005 },
        ]);
        is( $one->payer_rules_used( 1015 ), undef );
        is( $one->payer_is_validated( 1009 ), 0 );
        is( $one->payer_is_validated( 1015 ), 0 );

        is( $one->payer_has_billable_notes( 1009 ), 0 );
        is( $one->payer_has_billable_notes( 1015 ), 0 );

    ok( $one->live_validate_sql( $validation_rule->{ 1005 }, 1015 ));

        # used rules
        is_deeply( $one->system_rules_used, [
            $validation_rule->{ 1001 },
            $validation_rule->{ 1003 },
            $validation_rule->{ 1004 },
            $validation_rule->{ 1010 },
        ]);
        is_deeply( $one->payer_rules_used( 1009 ), [
            $validation_rule->{ 1005 },
        ]);
        is_deeply( $one->payer_rules_used( 1015 ), [
            $validation_rule->{ 1005 },
        ]);

    # not using payer_id
    is_deeply( $one->rule_ids, [ qw/ 1001 1003 1004 1005 1010 /]);
    is_deeply( $one->rule_ids( undef, 'system' ), [ qw/ 1001 1003 1004 1010 /]);
    is_deeply( $one->rule_ids( undef, 'payer' ), [ qw/ 1005 /]);
    is_deeply( $one->rules, [
        $validation_rule->{ 1001 },
        $validation_rule->{ 1003 },
        $validation_rule->{ 1004 },
        $validation_rule->{ 1005 },
        $validation_rule->{ 1010 },
    ]);

    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 0, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 0, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },  
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },  
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },  
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009,  force_valid => undef, pass => 1, }, 
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009,  force_valid => undef, pass => 1, },  
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
    ]); 
 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
# set notes which fail rule 
    can_ok( $one, 'set_notes_which_fail_rule' ); 
    throws_ok{ $one->set_notes_which_fail_rule } qr/rule_id and status are required/; 
    throws_ok{ $one->set_notes_which_fail_rule( 1001 )} qr/rule_id and status are required/; 
 
    # FIXME don't care if the rule exists or not, for now ... hmph, pry we should ... 
    ok( $one->set_notes_which_fail_rule( 666, 'Unbillable', 666 )); 
 
    ok( $one->set_notes_which_fail_rule( 1004, 'Unbillable', 1009 )); 
    ok( $one->set_notes_which_fail_rule( 1005, 'Unbillable', 1009 )); 
    # no results should have changed, since all notes passed 
    is_deeply( $one->results, [ 
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 0, }, 
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },  
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 0, },  
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },  
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },  
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },  
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009,  force_valid => undef, pass => 1, }, 
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009,  force_valid => undef, pass => 1, },  
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, }, 
    ]); 
 
    #however, rule 1005 does fail for payer 1015 
    ok( $one->set_notes_which_fail_rule( 1005, 'Unbillable', 1015 )); 
    is_deeply( $one->results, [ 
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1044 ), billing_status => 'Unbillable', validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 0, }, 
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },  
        { pn_result( 1047 ), billing_status => 'Unbillable', validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 0, },  
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009,  force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009,  force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => 'Prebilling', validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => 'Prebilling', validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => 'Prebilling', validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => 'Prebilling', validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => 'Prebilling', validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => 'Prebilling', validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1005 => 0, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);

    # using payer_id
    is( $one->results( undef, 1009 ), undef );
    is( $one->results( undef, 1015 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# finish set
# prognote billing_status flags:  reset?
#  - Billing : NO
#  - Partial : NO
#  - Paid : NO
#  - Unbillable : NO
#  - Prebilling : YES

    is( scalar @{ $CLASS->get_active }, 1 );
    can_ok( $one, 'finish' );

    ok( eleMentalClinic::ProgressNote->retrieve( 1043 )->update({ billing_status => 'Billing' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1044 )->update({ billing_status => 'Billing' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1045 )->update({ billing_status => 'Billing' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1046 )->update({ billing_status => 'Billing' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1047 )->update({ billing_status => 'Partial' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1048 )->update({ billing_status => 'Partial' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1056 )->update({ billing_status => 'Partial' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1057 )->update({ billing_status => 'Partial' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1058 )->update({ billing_status => 'Paid' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1059 )->update({ billing_status => 'Paid' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1065 )->update({ billing_status => 'Paid' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1066 )->update({ billing_status => 'Paid' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1143 )->update({ billing_status => 'Unbillable' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1144 )->update({ billing_status => 'Unbillable' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1145 )->update({ billing_status => 'Unbillable' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1157 )->update({ billing_status => 'Prebilling' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1158 )->update({ billing_status => 'Prebilling' }));
    ok( eleMentalClinic::ProgressNote->retrieve( 1159 )->update({ billing_status => 'Prebilling' }));

    ok( $one->finish );
    is( $one->step, 0 );
    is( $one->status, 'Closed' );

    is( eleMentalClinic::ProgressNote->retrieve( 1043 )->billing_status, 'Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1044 )->billing_status, 'Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1045 )->billing_status, 'Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1046 )->billing_status, 'Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1047 )->billing_status, 'Partial' );
    is( eleMentalClinic::ProgressNote->retrieve( 1048 )->billing_status, 'Partial' );
    is( eleMentalClinic::ProgressNote->retrieve( 1056 )->billing_status, 'Partial' );
    is( eleMentalClinic::ProgressNote->retrieve( 1057 )->billing_status, 'Partial' );
    is( eleMentalClinic::ProgressNote->retrieve( 1058 )->billing_status, 'Paid' );
    is( eleMentalClinic::ProgressNote->retrieve( 1059 )->billing_status, 'Paid' );
    is( eleMentalClinic::ProgressNote->retrieve( 1065 )->billing_status, 'Paid' );
    is( eleMentalClinic::ProgressNote->retrieve( 1066 )->billing_status, 'Paid' );
    is( eleMentalClinic::ProgressNote->retrieve( 1143 )->billing_status, 'Unbillable' );
    is( eleMentalClinic::ProgressNote->retrieve( 1144 )->billing_status, 'Unbillable' );
    is( eleMentalClinic::ProgressNote->retrieve( 1145 )->billing_status, 'Unbillable' );
    is( eleMentalClinic::ProgressNote->retrieve( 1157 )->billing_status, undef );
    is( eleMentalClinic::ProgressNote->retrieve( 1158 )->billing_status, undef );
    is( eleMentalClinic::ProgressNote->retrieve( 1159 )->billing_status, undef );

    is( $CLASS->get_active, undef );

    eleMentalClinic::ProgressNote->retrieve( $_ )->update({ billing_status => undef })
        for qw/ 1043 1044 1045 1046 1047 1048 1056 1057 1058 1059 1065 1066 1143 1144 1145 1157 1158 1159 /;
    is( eleMentalClinic::ProgressNote->retrieve( $_ )->billing_status, undef )
        for qw/ 1043 1044 1045 1046 1047 1048 1056 1057 1058 1059 1065 1066 1143 1144 1145 1157 1158 1159 /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start over so we can test validate()
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# payer_validation_complete
        $one = $CLASS->new;
    can_ok( $one, 'payer_validation_complete' );
    throws_ok{ $one->payer_validation_complete } qr/stored/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate
        $one = $CLASS->new;
    can_ok( $one, 'system_validation' );
    can_ok( $one, 'payer_validation' );

    # failures; no validation prognotes
    is( $one->system_validation, undef );
    is( $one->payer_validation, undef );
    is( $one->system_validation([ qw/ 1009 /]), undef );
    is( $one->payer_validation([ qw/ 1009 /], 1005 ), undef );

    # create validation set and billing cycle
    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date        => '2006-07-01',
        to_date          => '2006-07-15',
    })->billing_cycle );

    # no validation results 'cause no system validation yet
    is( $one->results, undef );
    is( $one->results( undef, 1009 ), undef );
    is( $one->results( undef, 1015 ), undef );

    # payer validation not complete
    is( $one->payer_validation_complete, undef );

    # system rule: remove dups
    ok( $one->validation_set->system_validation([ qw/ 1010/]));
    ok( $one->group_prognotes_by_insurer );

    # does nothing
    is( $one->system_validation, undef );
    is( $one->system_validation([ qw/ 666 /]), undef );

    # no payer validation run yet
    is_deeply( $one->rule_ids, [ qw/ 1010 /]);
    is_deeply( $one->rule_ids( 1009 ), [ qw/ 1010 /]);
    is_deeply( $one->rule_ids( 1015 ), [ qw/ 1010 /]);

    is( scalar @{ $one->rules }, 1 );
    is( scalar @{ $one->rules( 1009 )}, 1 );
    is( scalar @{ $one->rules( 1015 )}, 1 );

    is( $one->rules->[ 0 ]->rec_id, $validation_rule->{ 1010 }{ rec_id });
    is( $one->rules( 1009 )->[ 0 ]->rec_id, $validation_rule->{ 1010 }{ rec_id });
    is( $one->rules( 1015 )->[ 0 ]->rec_id, $validation_rule->{ 1010 }{ rec_id });

    # only rules for 1009
    ok( $one->payer_validation([ qw/ 1005 /], 1009 )); # payer, accepted charge codes
    is_deeply( $one->rule_ids, [ qw/ 1005 1010 /]);
    is( $one->rule_ids( 666 ), undef );
    is_deeply( $one->rule_ids( 1009 ), [ qw/ 1005 1010 /]);
    is_deeply( $one->rule_ids( 1015 ), [ qw/ 1010 /]);

    is( $one->payer_is_validated( 1009 ), 1 );
    is( $one->payer_is_validated( 1015 ), 0 );
    is( $one->payer_validation_complete, undef );

    is( $one->payer_has_billable_notes( 1009 ), 1 );
    is( $one->payer_has_billable_notes( 1015 ), 0 );

    is( scalar @{ $one->rules }, 2 );
    is( scalar @{ $one->rules( 1009 )}, 2 );
    is( scalar @{ $one->rules( 1015 )}, 1 );

    is( $one->rules->[ 0 ]->rec_id, $validation_rule->{ 1005 }{ rec_id });
    is( $one->rules->[ 1 ]->rec_id, $validation_rule->{ 1010 }{ rec_id });
    is( $one->rules( 1009 )->[ 0 ]->rec_id, $validation_rule->{ 1005 }{ rec_id });
    is( $one->rules( 1009 )->[ 1 ]->rec_id, $validation_rule->{ 1010 }{ rec_id });
    is( $one->rules( 1015 )->[ 0 ]->rec_id, $validation_rule->{ 1010 }{ rec_id });

    # results after running rules for 1009
    is( scalar @{ $one->results( undef, 1009 ) || []}, 2 );
    is_deeply( $one->results( undef, 1009 ), [
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1009, force_valid => undef, pass => 1 },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1009, force_valid => undef, pass => 1 },
    ]);
    # no results because payer 1015 hasn't been validated for that yet
    is( $one->results( undef, 1015 ), undef );

    # only rules for 1015
    ok( $one->payer_validation([ qw/ 1005 /], 1015 )); # payer, accepted charge codes
    is_deeply( $one->rule_ids, [ qw/ 1005 1010 /]);
    is( $one->rule_ids( 666 ), undef );
    is_deeply( $one->rule_ids( 1009 ), [ qw/ 1005 1010 /]);
    is_deeply( $one->rule_ids( 1015 ), [ qw/ 1005 1010 /]);

    is_deeply( $one->insurers, [
        $rolodex->{ 1009 },
        $rolodex->{ 1015 },
    ]);
    is( $one->payer_is_validated( 1009 ), 1 );
    is( $one->payer_is_validated( 1015 ), 1 );
    is( $one->payer_validation_complete, 1 );

    is( $one->payer_has_billable_notes( 1009 ), 1 );
    is( $one->payer_has_billable_notes( 1015 ), 1 );

    is( scalar @{ $one->rules }, 2 );
    is( scalar @{ $one->rules( 1009 )}, 2 );
    is( scalar @{ $one->rules( 1015 )}, 2 );

    is( $one->rules->[ 0 ]->rec_id, $validation_rule->{ 1005 }{ rec_id });
    is( $one->rules->[ 1 ]->rec_id, $validation_rule->{ 1010 }{ rec_id });
    is( $one->rules( 1009 )->[ 0 ]->rec_id, $validation_rule->{ 1005 }{ rec_id });
    is( $one->rules( 1009 )->[ 1 ]->rec_id, $validation_rule->{ 1010 }{ rec_id });
    is( $one->rules( 1015 )->[ 0 ]->rec_id, $validation_rule->{ 1005 }{ rec_id });
    is( $one->rules( 1015 )->[ 1 ]->rec_id, $validation_rule->{ 1010 }{ rec_id });

    # 1015 results
    is( scalar @{ $one->results( undef, 1009 ) || []}, 2 );
    is_deeply( $one->results( undef, 1009 ), [
        { pn_result( 1065 ), billing_status => 'Prebilling', validation_prognote_id => 1011, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1009, force_valid => undef, pass => 1 },
        { pn_result( 1066 ), billing_status => 'Prebilling', validation_prognote_id => 1012, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1009, force_valid => undef, pass => 1 },
    ]);
    is( scalar @{ $one->results( undef, 1015 ) || []}, 10 );
    is_deeply( $one->results( undef, 1015 ), [
        { pn_result( 1043 ), billing_status => 'Prebilling', validation_prognote_id => 1001, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1015, force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => 'Prebilling', validation_prognote_id => 1002, rule_1005 => 0, rule_1010 => 1, payer_validation => 1, rolodex_id => 1015, force_valid => undef, pass => 0, },
        { pn_result( 1045 ), billing_status => 'Prebilling', validation_prognote_id => 1003, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1015, force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => 'Prebilling', validation_prognote_id => 1004, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1015, force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => 'Prebilling', validation_prognote_id => 1005, rule_1005 => 0, rule_1010 => 1, payer_validation => 1, rolodex_id => 1015, force_valid => undef, pass => 0, }, 
        { pn_result( 1048 ), billing_status => 'Prebilling', validation_prognote_id => 1006, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1015, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => 'Prebilling', validation_prognote_id => 1007, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1015, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => 'Prebilling', validation_prognote_id => 1008, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1015, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => 'Prebilling', validation_prognote_id => 1009, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1015, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => 'Prebilling', validation_prognote_id => 1010, rule_1005 => 1, rule_1010 => 1, payer_validation => 1, rolodex_id => 1015, force_valid => undef, pass => 1, }, 
    ]);

    ok( $one->payer_validation([ qw/ 1005 /], 1014 ));
    ok( $one->payer_validation([ qw/ 1007 /], 1014 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid notes
    is_deeply( $one->valid_notes( 1015 ), [
            eleMentalClinic::ProgressNote->retrieve( 1043 ),
            eleMentalClinic::ProgressNote->retrieve( 1045 ),
            eleMentalClinic::ProgressNote->retrieve( 1046 ),
            eleMentalClinic::ProgressNote->retrieve( 1048 ),
            eleMentalClinic::ProgressNote->retrieve( 1056 ),
            eleMentalClinic::ProgressNote->retrieve( 1057 ),
            eleMentalClinic::ProgressNote->retrieve( 1058 ),
            eleMentalClinic::ProgressNote->retrieve( 1059 ),
    ]);

    ok( $one->payer_validation([ qw/ 1009 /], 1015 ));

    is_deeply( $one->valid_notes( 1015 ), [
            eleMentalClinic::ProgressNote->retrieve( 1043 ),
            eleMentalClinic::ProgressNote->retrieve( 1046 ),
            eleMentalClinic::ProgressNote->retrieve( 1048 ),
            eleMentalClinic::ProgressNote->retrieve( 1056 ),
            eleMentalClinic::ProgressNote->retrieve( 1058 ),
            eleMentalClinic::ProgressNote->retrieve( 1059 ),
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# fail all notes for one payer, see _has_billable fail
    ok( $one->payer_validation([ qw/ 1007 /], 1015 )); # payer, all fail

    is( $one->payer_is_validated( 1009 ), 1 );
    is( $one->payer_is_validated( 1015 ), 1 );
    is( $one->payer_has_billable_notes( 1009 ), 1 );
    is( $one->payer_has_billable_notes( 1015 ), 0 );

# TODO test a full billing cycle where all notes fail
# $one->validation_set->system_validation([ qw/ 1001 1002 1003 1004 /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start again so the rest of the tests pass
# they were written assuming all notes pass
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( $one = $test->financial_setup_billingcycle( reset_sequences => 1 ) );
    is( $one->rec_id, 1001 );
    ok( $one->id( 1001 )->retrieve );
        $test->financial_setup_system_validation( $one );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test validation_prognotes_by_insurer again
        
    is( scalar keys %{ $one->validation_prognotes_by_insurer }, 2 );
    is( scalar @{ $one->validation_prognotes_by_insurer->{ 1009 }}, 2 );
    is( scalar @{ $one->validation_prognotes_by_insurer->{ 1015 }}, 10 );

    is_deeply( $one->validation_prognotes_by_insurer, {
        1009 => [ qw/
            1065 1066 
        /],
        1015 => [ qw/
            1043 1044 1045 1046 1047 1048 1056 1057 1058 1059
        /],
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# continue with the validation process - trivial payer validation: all pass
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( $one->payer_validation([ qw/ 1006 1008 /], 1009 ));
    ok( $one->payer_validation([ qw/ 1006 1008 /], 1015 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# move_notes_to_billing
    can_ok( $one, 'move_notes_to_billing' );
    is( $one->move_notes_to_billing, undef );

    ok( $one->move_notes_to_billing( 1009 ));

    # check billing_file
    is_deeply( eleMentalClinic::Financial::BillingFile->get_all, [
        { 
            rec_id => 1001,
            billing_cycle_id => 1001,
            group_control_number => 1,
            set_control_number => 1,
            purpose => '00',
            type => 'CH',
            is_production => 0,
            submission_date => undef,
            rolodex_id => 1009,
            edi => undef,
            payer => $rolodex->{ 1009 },
        },
    ]);

    # check billing_claims
    is_deeply( eleMentalClinic::Financial::BillingFile->retrieve( 1001 )->billing_claims, [
        {
            rec_id => 1001,
            billing_file_id => 1001,
            staff_id => 1001,
            client_id => 1005,
            client_insurance_id => 1010,
            client_insurance_authorization_id => 1013,
            insurance_rank => 1,
        },
    ]);

    # check billing_services
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1001 )->billing_services, [
        { rec_id => 1001, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1002, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
    ]);

    # check billing_prognotes
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->billing_prognotes, [
        { rec_id => 1001, billing_service_id => 1001, prognote_id => 1065, },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->billing_prognotes, [
        { rec_id => 1002, billing_service_id => 1002, prognote_id => 1066, },
    ]);

    # check prognotes
    is( eleMentalClinic::ProgressNote->retrieve( 1065 )->billing_status, 'Billing' );
    is( eleMentalClinic::ProgressNote->retrieve( 1066 )->billing_status, 'Billing' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# move the next set to billing

    ok( $one->move_notes_to_billing( 1015 ) );

    # check billing_file
    is_deeply( eleMentalClinic::Financial::BillingFile->get_all, [
        {
            rec_id => 1001,
            billing_cycle_id => 1001,
            group_control_number => 1,
            set_control_number => 1,
            purpose => '00',
            type => 'CH',
            is_production => 0,
            submission_date => undef,
            rolodex_id => 1009,
            edi => undef,
            payer => $rolodex->{ 1009 },
        },
        {
            rec_id => 1002,
            billing_cycle_id => 1001,
            group_control_number => 1,
            set_control_number => 1,
            purpose => '00',
            type => 'CH',
            is_production => 0,
            submission_date => undef,
            rolodex_id => 1015,
            edi => undef,
            payer => $rolodex->{ 1015 },
            claims_processor => $claims_processor->{ 1003 },
        },
    ]);

    # check billing_claims
    is_deeply( eleMentalClinic::Financial::BillingFile->retrieve( 1001 )->billing_claims, [
        { rec_id => 1001, billing_file_id => 1001, staff_id => 1001, client_id => 1005, client_insurance_id => 1010, insurance_rank => 1, client_insurance_authorization_id => 1013 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingFile->retrieve( 1002 )->billing_claims, [
        { rec_id => 1002, billing_file_id => 1002, staff_id => 1002, client_id => 1003, client_insurance_id => 1003, insurance_rank => 1, client_insurance_authorization_id => 1004 },
        { rec_id => 1003, billing_file_id => 1002, staff_id => 1001, client_id => 1004, client_insurance_id => 1007, insurance_rank => 1, client_insurance_authorization_id => 1009 },
    ]);

    # check billing_services
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1001 )->billing_services, [
        { rec_id => 1001, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1002, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1002 )->billing_services, [
        { rec_id => 1003, billing_claim_id => 1002, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1004, billing_claim_id => 1002, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1005, billing_claim_id => 1002, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1006, billing_claim_id => 1002, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1007, billing_claim_id => 1002, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1008, billing_claim_id => 1002, billed_amount => undef, billed_units => undef, line_number => undef },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1003 )->billing_services, [
        { rec_id => 1009, billing_claim_id => 1003, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1010, billing_claim_id => 1003, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1011, billing_claim_id => 1003, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1012, billing_claim_id => 1003, billed_amount => undef, billed_units => undef, line_number => undef },
    ]);
    
    # check billing_prognotes
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->billing_prognotes, [
        { rec_id => 1001, billing_service_id => 1001, prognote_id => 1065 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->billing_prognotes, [
        { rec_id => 1002, billing_service_id => 1002, prognote_id => 1066 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1003 )->billing_prognotes, [
        { rec_id => 1003, billing_service_id => 1003, prognote_id => 1043 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->billing_prognotes, [
        { rec_id => 1004, billing_service_id => 1004, prognote_id => 1044 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1005 )->billing_prognotes, [
        { rec_id => 1005, billing_service_id => 1005, prognote_id => 1045 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1006 )->billing_prognotes, [
        { rec_id => 1006, billing_service_id => 1006, prognote_id => 1046 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1007 )->billing_prognotes, [
        { rec_id => 1007, billing_service_id => 1007, prognote_id => 1047 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1008 )->billing_prognotes, [
        { rec_id => 1008, billing_service_id => 1008, prognote_id => 1048 },
    ]);

    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1009 )->billing_prognotes, [
        { rec_id => 1009, billing_service_id => 1009, prognote_id => 1056 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1010 )->billing_prognotes, [
        { rec_id => 1010, billing_service_id => 1010, prognote_id => 1057 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1011 )->billing_prognotes, [
        { rec_id => 1011, billing_service_id => 1011, prognote_id => 1058 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1012 )->billing_prognotes, [
        { rec_id => 1012, billing_service_id => 1012, prognote_id => 1059 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write_837
    can_ok( $one, 'write_837' );
    throws_ok{ $one->write_837 } qr/required/;

        my $output_root = $one->config->edi_out_root;
    ok( -d $output_root, $output_root.' directory exists' );

        my $test_file_path = $output_root . '/1002t837P0629.txt';
        unlink $test_file_path;
        
        my( $file, $edi_data ) = $one->write_837( 1002, '2006-06-29 16:04:25' );
    is( $file, $test_file_path );
    like( $edi_data, qr/ISA\*00\*          \*00\*          \*ZZ\*OR00000        \*ZZ\*00824          \*060629\*1604\*U\*00401\*000001002\*0\*T\*:\~/ );

    ok( -f $test_file_path, "test file $test_file_path exists after write()." );
    ok(`file $test_file_path` =~ /ASCII text/,  "$test_file_path is an ASCII text file");

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# process the first billing cycle: process 835, create transactions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        # ECS files need to be marked as submitted separately from file generation
        my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( 1002 );
        $billing_file->save_as_billed( '2006-06-29 16:04:25', $edi_data );

        my $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.1.txt', '2006-09-05' ) );
    # finish the billing cycle
        $one->validation_set->finish;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write_file
    can_ok( $one, 'write_file' );
    throws_ok{ $one->write_file } qr/required/;
    throws_ok{ $one->write_file( 1002 ) } qr/required/;
    throws_ok{ $one->write_file( 1002, 'frog' ) } qr/837 or hcfa/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# do the database setup for the second billing cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $one = $test->financial_setup_billingcycle;
    is( $one->rec_id, 1002 );

        $test->financial_setup_system_validation( $one );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test validation_prognotes_by_insurer again, after the first billing cycle
        
    is( scalar keys %{ $one->validation_prognotes_by_insurer }, 2 );
    is( scalar @{ $one->validation_prognotes_by_insurer->{ 1009 }}, 2 );
    is( scalar @{ $one->validation_prognotes_by_insurer->{ 1014 }}, 1 );

    is_deeply( $one->validation_prognotes_by_insurer, {
        1009 => [ qw/
            1065 1066
        /],
        1014 => [ qw/
            1043
        /],
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# continue the set up for the second billing cycle,
# test move_notes_to_billing again
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        $test->financial_setup_payer_validation( $one, [ 1005 ], [ 1014 ] );

    # check billing_file
    is_deeply( eleMentalClinic::Financial::BillingFile->get_all, [
        {
            rec_id => 1001,
            billing_cycle_id => 1001,
            group_control_number => 1,
            set_control_number => 1,
            purpose => '00',
            type => 'CH',
            is_production => 0,
            submission_date => undef,
            rolodex_id => 1009,
            edi => undef,
            payer => $rolodex->{ 1009 },
        },
        {
            rec_id => 1002,
            billing_cycle_id => 1001,
            group_control_number => 1,
            set_control_number => 1,
            purpose => '00',
            type => 'CH',
            is_production => 0,
            submission_date => '2006-06-29 16:04:25',
            rolodex_id => 1015,
            edi => $edi_data,
            payer => $rolodex->{ 1015 },
            claims_processor => $claims_processor->{ 1003 },
        },
        {
            rec_id => 1003,
            billing_cycle_id => 1002,
            group_control_number => 1,
            set_control_number => 1,
            purpose => '00',
            type => 'CH',
            is_production => 0,
            submission_date => undef,
            rolodex_id => 1014,
            edi => undef,
            payer => $rolodex->{ 1014 },
            claims_processor => $claims_processor->{ 1002 },
        },
    ]);

    # check billing_claims
    is_deeply( eleMentalClinic::Financial::BillingFile->retrieve( 1001 )->billing_claims, [
        { rec_id => 1001, billing_file_id => 1001, staff_id => 1001, client_id => 1005, client_insurance_id => 1010, insurance_rank => 1, client_insurance_authorization_id => 1013 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingFile->retrieve( 1002 )->billing_claims, [
        { rec_id => 1002, billing_file_id => 1002, staff_id => 1002, client_id => 1003, client_insurance_id => 1003, insurance_rank => 1, client_insurance_authorization_id => 1004 },
        { rec_id => 1003, billing_file_id => 1002, staff_id => 1001, client_id => 1004, client_insurance_id => 1007, insurance_rank => 1, client_insurance_authorization_id => 1009 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingFile->retrieve( 1003 )->billing_claims, [
        { rec_id => 1004, billing_file_id => 1003, staff_id => 1002, client_id => 1003, client_insurance_id => 1004, insurance_rank => 2, client_insurance_authorization_id => 1007 },
    ]);

    # check billing_services
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1001 )->billing_services, [
        { rec_id => 1001, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1002, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1002 )->billing_services, [
        { rec_id => 1003, billing_claim_id => 1002, billed_amount => '124.64', billed_units => 2, line_number => 1 },
        { rec_id => 1004, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 2 },
        { rec_id => 1005, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 3 },
        { rec_id => 1006, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 4 },
        { rec_id => 1007, billing_claim_id => 1002, billed_amount => '131.44', billed_units => 2, line_number => 5 },
        { rec_id => 1008, billing_claim_id => 1002, billed_amount => '124.64', billed_units => 2, line_number => 6 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1003 )->billing_services, [
        { rec_id => 1009, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 1 },
        { rec_id => 1010, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 2 },
        { rec_id => 1011, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 3 },
        { rec_id => 1012, billing_claim_id => 1003, billed_amount => '131.44', billed_units => 2, line_number => 4 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1004 )->billing_services, [
        { rec_id => 1013, billing_claim_id => 1004, billed_amount => undef, billed_units => undef, line_number => undef },
    ]);

    # check billing_prognotes
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->billing_prognotes, [
        { rec_id => 1001, billing_service_id => 1001, prognote_id => 1065 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->billing_prognotes, [
        { rec_id => 1002, billing_service_id => 1002, prognote_id => 1066 },
    ]);

    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1003 )->billing_prognotes, [
        { rec_id => 1003, billing_service_id => 1003, prognote_id => 1043 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1004 )->billing_prognotes, [
        { rec_id => 1004, billing_service_id => 1004, prognote_id => 1044 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1005 )->billing_prognotes, [
        { rec_id => 1005, billing_service_id => 1005, prognote_id => 1045 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1006 )->billing_prognotes, [
        { rec_id => 1006, billing_service_id => 1006, prognote_id => 1046 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1007 )->billing_prognotes, [
        { rec_id => 1007, billing_service_id => 1007, prognote_id => 1047 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1008 )->billing_prognotes, [
        { rec_id => 1008, billing_service_id => 1008, prognote_id => 1048 },
    ]);

    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1009 )->billing_prognotes, [
        { rec_id => 1009, billing_service_id => 1009, prognote_id => 1056 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1010 )->billing_prognotes, [
        { rec_id => 1010, billing_service_id => 1010, prognote_id => 1057 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1011 )->billing_prognotes, [
        { rec_id => 1011, billing_service_id => 1011, prognote_id => 1058 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1012 )->billing_prognotes, [
        { rec_id => 1012, billing_service_id => 1012, prognote_id => 1059 },
    ]);

    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1013 )->billing_prognotes, [
        { rec_id => 1013, billing_service_id => 1013, prognote_id => 1043 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write_hcfas
    can_ok( $one, 'write_hcfas' );
    throws_ok{ $one->write_hcfas } qr/required/;

        $output_root = $one->config->pdf_out_root;
    ok( -d $output_root, $output_root.' directory exists' );

    # check billing_services
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1001 )->billing_services, [
        { rec_id => 1001, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
        { rec_id => 1002, billing_claim_id => 1001, billed_amount => undef, billed_units => undef, line_number => undef },
    ]);
    # check billing_prognotes
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1001 )->billing_prognotes, [
        { rec_id => 1001, billing_service_id => 1001, prognote_id => 1065 },
    ]);
    is_deeply( eleMentalClinic::Financial::BillingService->retrieve( 1002 )->billing_prognotes, [
        { rec_id => 1002, billing_service_id => 1002, prognote_id => 1066 },
    ]);

        $test_file_path = $output_root . '/1001ProvidenceHealthPlansHCFA0629.pdf';
        unlink $test_file_path;

        $one->id( 1002 )->retrieve;
    is( $one->write_hcfas( 1001, '2006-06-29 16:04:25' ), $test_file_path );

    is_pdf_file($test_file_path);

    #cmp_pdf( $test_file_path, 'templates/default/hcfa_billing/hcfa1500.pdf' );

    # check billing_services
    is_deeply( eleMentalClinic::Financial::BillingClaim->retrieve( 1001 )->billing_services, [
        { rec_id => 1001, billing_claim_id => 1001, billed_amount => '131.44', billed_units => 2, line_number => 1 },
        { rec_id => 1002, billing_claim_id => 1001, billed_amount => '131.44', billed_units => 2, line_number => 2 },
    ]);

    # check submission date
    is( eleMentalClinic::Financial::BillingFile->retrieve( 1002 )->submission_date, '2006-06-29 16:04:25' );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_billing_files
    can_ok( $one, 'get_billing_files' );
    is( $one->get_billing_files, undef );

        $one->id( 1001 )->retrieve;
    is_deeply( $one->get_billing_files, [
        eleMentalClinic::Financial::BillingFile->retrieve( 1001 ),
        eleMentalClinic::Financial::BillingFile->retrieve( 1002 ),
    ] );
    is_deeply( $one->get_billing_files( 1009 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1001 ),
    ] );
    is_deeply( $one->get_billing_files( 1015 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1002 ),
    ] );
    is( $one->get_billing_files( 999 ), undef );

        $one->id( 1002 )->retrieve;
    is_deeply( $one->get_billing_files, [
        eleMentalClinic::Financial::BillingFile->retrieve( 1003 ),
    ] );
    is_deeply( $one->get_billing_files( 1014 ), [
        eleMentalClinic::Financial::BillingFile->retrieve( 1003 ),
    ] );
    is( $one->get_billing_files( 999 ), undef );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check that EDI is only allowed to be billed once, HCFAs unlimited
        
        $one->id( 1002 )->retrieve;

    throws_ok{ $one->write_837( 1002, '2006-06-29 16:04:25' ) } qr/This file has already been sent/;
    is( $one->write_hcfas( 1001, '2006-06-29 18:18:18' ), $test_file_path );

    # submission date should be updated
    is( eleMentalClinic::Financial::BillingFile->retrieve( 1001 )->submission_date, '2006-06-29 18:18:18' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test validation_prognotes_by_insurer again, after the second billing cycle
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        $one->write_837( 1003 );
        eleMentalClinic::Financial::BillingFile->retrieve( 1003 )->save_as_billed( '2006-06-29 16:04:25' );
        $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    ok( $billing_payment->process_remittance_advice( 't/resource/sample_835.2.txt', '2006-09-05' ) );

    # If there is a third insurance, test that it's not billed for prognote 1043.
    # (need to create another authorization before the third insurance will be used)
    eleMentalClinic::Client::Insurance::Authorization->new({ 
        client_insurance_id => 1005,
        allowed_amount      => 1000,
        code                => 'RCA3',
        start_date          => '2006-01-01',
        end_date            => '2006-12-31',
    })->save; 

    # there are no prognotes left to separate by insurer because they've all been paid or are awaiting payment
    is( scalar keys %{ $one->validation_prognotes_by_insurer }, 0 );
    is_deeply( $one->validation_prognotes_by_insurer, { } );

        # delete that auth
        $test->db->delete_one( 'client_insurance_authorization', 'client_insurance_id = 1005' );

        $one->validation_set->finish;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start over so we can test prognote_count 
# with more than one validation set open 
# -- make sure it only counts notes in its own set
# also ensure that we're properly restoring the billing status when we finish a
# set.
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date       => '2006-07-01',
        to_date         => '2006-07-15',
    }));

    my @ids = map { $_->{id} } @{$one->prognotes};

    $one->finish;

    #
    # Since we'd just be restoring nulls here, we set it to our real-world use
    # case: Setting the status to "Partial" on all the notes we're about to
    # start a cycle with and then revert.
    #

    foreach my $id (@ids) {
        $one = eleMentalClinic::ProgressNote->retrieve($id);
        $one->billing_status("Partial");
        $one->save;
    }

    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date       => '2006-07-01',
        to_date         => '2006-07-15',
    }));

    # 
    # The ->prognotes call returns a hash, so we just pull out the minimum here
    # and store it in a hash for comparison later.
    #
    # The check following it ensures they are all "partial".
    # 

    my %prognote_previous_billing_status = map { ($_->{id} => $_->{previous_billing_status}) } @{$one->prognotes};

    map { is($_, "Partial") } values %prognote_previous_billing_status;

    is( $one->prognote_count, 18 );

    ok( my $validation_set = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'validation',
        from_date       => '2006-07-16',
        to_date         => '2006-07-31',
    }));

    is( $one->prognote_count, 18 );
    is( $one->prognote_count( 999 ), 0 );
    is( $one->prognote_count( 1015 ), 0 );

    is( $validation_set->prognote_count, 16 );

        $one->system_validation( [ qw/ 1001 1003 1004 1010 /] );
        $one->billing_cycle->group_prognotes_by_insurer;
    is( $one->prognote_count( 1015 ), 10 );

    #
    # similar to above, but gathering the billing statuses
    #
    
    my %prognote_billing_status = map { ($_->{id} => $_->{billing_status}) } @{$one->prognotes};

        $one->finish;
        $validation_set->finish;

    #
    # Check the billing status after finishing to ensure the previous status is
    # undef, and the (now restored) status is "partial"
    #

    foreach my $key (keys %prognote_previous_billing_status) {
        $one = eleMentalClinic::ProgressNote->retrieve($key);
        is($one->billing_status, "Partial");
        is($one->previous_billing_status, undef); 
    }

    #
    # Do it all again to ensure we're not screwing something up in the transition.
    #

    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date       => '2006-07-01',
        to_date         => '2006-07-15',
    }));

    %prognote_previous_billing_status = map { ($_->{id} => $_->{previous_billing_status}) } @{$one->prognotes};

    map { is($_, "Partial") } values %prognote_previous_billing_status;

    is( $one->prognote_count, 18 );
    is( $one->prognote_count( 999 ), 0 );
    is( $one->prognote_count( 1015 ), 0 );

        $one->system_validation( [ qw/ 1001 1003 1004 1010 /] );
        $one->billing_cycle->group_prognotes_by_insurer;
    is( $one->prognote_count( 1015 ), 10 );

    #
    # Here we ensure that we're set to "Prebilling" in the billing status and
    # "Partial" in the previous status.
    #

    foreach my $key (keys %prognote_previous_billing_status) {
        local $one = eleMentalClinic::ProgressNote->retrieve($key);
        is($one->billing_status, "Prebilling");
        is($one->previous_billing_status, "Partial");
    }

        $one->finish;

    #
    # And here we make sure it's restored.
    #

    foreach my $key (keys %prognote_previous_billing_status) {
        $one = eleMentalClinic::ProgressNote->retrieve($key);
        is($one->billing_status, "Partial");
        is($one->previous_billing_status, undef); 
    }
   
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# start over so we can test delete_validation_prognotes
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# delete_validation_prognotes
    can_ok( $one, 'delete_validation_prognotes' );
    is( $one->delete_validation_prognotes, undef );

    is( $test->select_count( 'validation_prognote' ), 0 );

        # create a fake validation_set and some validation_prognote records so we can delete them
    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date       => '2006-07-01',
        to_date         => '2006-07-03',
    })->billing_cycle );

    is( $test->select_count( 'validation_prognote' ), 5 );

    ok( $one->delete_validation_prognotes( [ 1043, 1056, 1143, 1144 ] ) );
    is( $test->select_count( 'validation_prognote' ), 1 );

    ok( $one->delete_validation_prognotes( [ 1145 ] ) );
    is( $test->select_count( 'validation_prognote' ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
