# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 1376;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, %count);
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
# constructor
    ok( $one = $CLASS->empty );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'validation_set' );
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [ qw/
        rec_id creation_date from_date to_date staff_id billing_cycle_id step status
    /]);
    is_deeply( $CLASS->fields_required, [ qw/ creation_date from_date to_date staff_id /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# XXX need to munge data for these
# notes not selected
        $one = $CLASS->empty;
    can_ok( $one, 'prognotes_not_selected' );
    is( $one->prognotes_not_selected, undef );

        # all these notes are marked "paid", so we mark one "unpaid" so the craetion succeeds
        eleMentalClinic::ProgressNote->retrieve( $_ )->billing_status( '*NULL' )->save
            for qw/ 1010 /;

    ok( $one = $CLASS->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'validation',
        from_date       => '1999-01-01',
        to_date         => '2005-04-01',
    }));
    is( scalar@{ $one->prognotes }, 1 );
    is( $one->prognotes_not_selected, undef );

        eleMentalClinic::ProgressNote->retrieve( $_ )->billing_status( 'Unbillable' )->save
            for qw/ 1010 1011 1012 1013 1014 1015 1016 /;

    is( scalar @{ $one->prognotes_not_selected }, 6 );
    is_deeply( ids( $one->prognotes_not_selected ), [ qw/
        1013 1011 1012 1014 1015 1016 
    /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# results_to_notes was a mistake, it was a bad fix, make sure it is no 
# longer present.

    ok( ! $one->can( 'results_to_notes' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clients
    can_ok( $one, 'clients' );
    is( $one->clients, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prognote_count
    can_ok( $one, 'prognote_count' );
    is( $one->prognote_count, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# result_count
    can_ok( $one, 'result_count' );
    is( $one->result_count, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setup ...
    ok( $one = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'validation',
        from_date       => '2006-07-01',
        to_date         => '2006-07-15',
    }));
    ok( $one->system_validation([ qw/ 1001 1003 1004 1010 /]));
    is( $one->prognote_count, 18 );
    is( $one->result_count, 18 );
    is( $one->result_count( '' ), 18 );
    is( $one->result_count( 'foo' ), 18 );
    is( $one->result_count( -1 ), 18 );
    is( $one->result_count( undef ), 18 );
    is( $one->result_count( 1 ), 12 );
    is( $one->result_count( 0 ), 6 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clients
    is_deeply( $one->clients, {
        1003    => $client->{ 1003 },
        1004    => $client->{ 1004 },
        1005    => $client->{ 1005 },
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check before grouping by insurer

    is( scalar @{ $one->results }, 18 );
    is( scalar @{ $one->results( 1 )}, 12 );

    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => undef, validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => undef, validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1045 ), billing_status => undef, validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => undef, validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => undef, validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => undef, validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => undef, validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => undef, validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => undef, validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => undef, validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => undef, validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => undef, validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => undef, validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => undef, validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => undef, validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => undef, validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => undef, validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => undef, validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validation prognotes by insurer
    can_ok( $one, 'validation_prognotes_by_insurer' );
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
# group notes by insurer
    can_ok( $one, 'group_prognotes_by_insurer' );
    ok( $one->group_prognotes_by_insurer );
    is_deeply( $one->results, [
        { pn_result( 1043 ), billing_status => undef, validation_prognote_id => 1001, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1044 ), billing_status => undef, validation_prognote_id => 1002, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1045 ), billing_status => undef, validation_prognote_id => 1003, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1046 ), billing_status => undef, validation_prognote_id => 1004, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1047 ), billing_status => undef, validation_prognote_id => 1005, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1048 ), billing_status => undef, validation_prognote_id => 1006, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1056 ), billing_status => undef, validation_prognote_id => 1007, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1057 ), billing_status => undef, validation_prognote_id => 1008, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, },
        { pn_result( 1058 ), billing_status => undef, validation_prognote_id => 1009, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1059 ), billing_status => undef, validation_prognote_id => 1010, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1015,  force_valid => undef, pass => 1, }, 
        { pn_result( 1065 ), billing_status => undef, validation_prognote_id => 1011, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009,  force_valid => undef, pass => 1, },
        { pn_result( 1066 ), billing_status => undef, validation_prognote_id => 1012, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 1, payer_validation => 0, rolodex_id => 1009,  force_valid => undef, pass => 1, }, 
        { pn_result( 1143 ), billing_status => undef, validation_prognote_id => 1013, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1144 ), billing_status => undef, validation_prognote_id => 1014, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1145 ), billing_status => undef, validation_prognote_id => 1015, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1157 ), billing_status => undef, validation_prognote_id => 1016, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1158 ), billing_status => undef, validation_prognote_id => 1017, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
        { pn_result( 1159 ), billing_status => undef, validation_prognote_id => 1018, rule_1001 => 1, rule_1003 => 1, rule_1004 => 1, rule_1010 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0, },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing_cycle
    can_ok( $one, 'billing_cycle' );
    is( $one->billing_cycle, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create_billing_cycle
    can_ok( $one, 'create_billing_cycle' );
    ok( $one->create_billing_cycle({
        creation_date   => '2006-01-01',
        staff_id        => 1001,
    }));
    isa_ok( $one->billing_cycle, 'eleMentalClinic::Financial::BillingCycle' );
        $test->delete_( 'billing_cycle', '*' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create validation prognotes
        $one = $CLASS->empty;
    can_ok( $one, 'create_validation_prognotes' );
    throws_ok{ $one->create_validation_prognotes } qr/Must call on stored object/;

    # creating progress notes in this date range that we should skip

        # this is a bit of a hack; really, necessary for testing
        # usually, new validation sets are created with 'create'
        $one = $CLASS->new({
            creation_date   => '2006-08-01',
            staff_id        => 1005,
            from_date       => '2006-07-01',
            to_date         => '2006-07-10',
        });
        $one->save;
    is( ++$count{ $CLASS->table }, $test->select_count( $CLASS->table ));
    is( scalar @{ $CLASS->get_active }, 1 );
    isa_ok( $_, $CLASS )
        for @{ $CLASS->get_active };
    is( $one->prognotes, undef );

#     is( $one->create_validation_prognotes({ type => 'billing' }), 14 );
    is( $one->create_validation_prognotes, 14 );
    is( @{ $one->prognotes }, 14 );
    is( $one->billing_cycle, undef );

    # making sure that the billing status is updated correctly, so the note is locked
    is_deeply( ids( $one->prognotes ), [ qw/
        1144 1043 1056 1143 1145 1044 1065 1159 1045 1057 1157 1158 1046 1058
    /]);
    for my $prognote_id( @{ ids( eleMentalClinic::ProgressNote->new->get_all )}) {
        isnt( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get active
    can_ok( $CLASS, 'get_active' );
    is_deeply( $CLASS->get_active, [ $one ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create validation prognotes, skipping notes in bounce workflow
        $one = $CLASS->empty;

        # this is a bit of a hack; really, necessary for testing
        # usually, new validation sets are created with 'create'
        $one = $CLASS->new({
            creation_date   => '2006-09-01',
            staff_id        => 1005,
            from_date       => '2006-08-01',
            to_date         => '2006-08-10',
        });
        $one->save;
    is( ++$count{ $CLASS->table }, $test->select_count( $CLASS->table ));
    is( scalar @{ $CLASS->get_active }, 2 );

    is( $one->create_validation_prognotes, 5 );
    is( @{ $one->prognotes }, 5 );
    is( $one->billing_cycle, undef );
    is_deeply( ids( $one->prognotes ), [
        qw/ 1244 1243 1444 1258 1445 /
    ]);
        $one->delete;
    is( scalar @{ $CLASS->get_active }, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create new validation set: failure
        $count{ $CLASS->table } = $test->select_count( $CLASS->table );
    can_ok( $CLASS, 'create' );
    throws_ok{ $CLASS->create } qr/Missing required argument/;
    throws_ok{ $CLASS->create({
        creation_date      => '2006-07-15',
        staff_id        => 1005,
        type            => 'validation',
        from_date            => '1900-01-01',
        })
    } qr/Missing required argument/;
    ok( $count{ $CLASS->table } == $test->select_count( $CLASS->table ));

    # bad dates -- no notes
    is( $CLASS->create({
        creation_date      => '2006-07-15',
        staff_id        => 1005,
        type            => 'validation',
        from_date            => '1900-01-01',
        to_date              => '1901-01-01',
    }), undef );
    ok( $count{ $CLASS->table } == $test->select_count( $CLASS->table ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create new validation set: good dates, should get notes
    ok( $one = $CLASS->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'validation',
        from_date       => '2006-07-15',
        to_date         => '2006-07-31',
    }));
    ok( ++$count{ $CLASS->table } == $test->select_count( $CLASS->table ));

    isa_ok( $one, $CLASS );
    is( $one->status, 'Initialized' );
    is( @{ $one->prognotes }, 16 );
    is( $one->billing_cycle, undef );
    is_deeply( ids( $one->prognotes ), [ qw/
        1049 1060 1050 1067 1350 1051 1061 1351 1052 1062 1053 1068 1054 1063 1055 1064
    /]);

##         $one->finish;
##     for my $prognote_id( @{ ids( eleMentalClinic::ProgressNote->new->get_all )}) {
##         isnt( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
##     }
## __END__
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# retrieve set and make sure it's still good
        $tmp = $one;
    ok( $one = $CLASS->empty({ rec_id => $tmp->id }));
    isa_ok( $one, $CLASS );
    is( $one->billing_cycle, undef );
    is( @{ $one->prognotes }, 16 );
    is_deeply( ids( $one->prognotes ), [ qw/
        1049 1060 1050 1067 1350 1051 1061 1351 1052 1062 1053 1068 1054 1063 1055 1064
    /]);
    $one->retrieve;
    is( $one->id, $tmp->id );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get active
    can_ok( $CLASS, 'get_active' );
    is( scalar @{ $CLASS->get_active }, 2 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# personnel
        $tmp = $one;
        $one = $CLASS->empty;
    can_ok( $one, 'personnel' );
    is( $one->personnel, undef );

        $one = $tmp;
    is( $one->staff_id, 1005 );
    isa_ok( $one->personnel, 'eleMentalClinic::Personnel' );
    is( $one->personnel->staff_id, 1005 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rule ids
    can_ok( $one, 'rule_ids' );
    is( $one->rule_ids, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rules
    can_ok( $one, 'rules' );
    is( $one->rules, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# delete set
    ok( $one->delete );
    ok( --$count{ $CLASS->table } == $test->select_count( $CLASS->table ));
    ok( $one = $CLASS->empty({ rec_id => $tmp->id }));

    # we still have an id here, so the retrieve accessors will work,
    # even if the object is gone from the main table
    ok( $one->id );
    is( $one->billing_cycle, undef );
    is( $one->prognotes, undef );

        $one->retrieve;
    is( $one->id, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# finish set
    can_ok( $one, 'finish' );
    is( scalar @{ $CLASS->get_active }, 1 );
    throws_ok{ $one->finish } qr/Can only call on stored object/;

        $one = $CLASS->get_active->[ 0 ];
    ok( $one->finish );
    is( $CLASS->get_active, undef );
    is( --$count{ $CLASS->table }, $test->select_count( $CLASS->table ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tell it we're in a billing cycle ...
        $one = $CLASS->new({
            status       => 1,
            creation_date  => '2006-08-01',
            staff_id     => 1005,
            from_date    => '2006-07-01',
            to_date      => '2006-07-10',
        });
        $one->save;
    is( ++$count{ $CLASS->table }, $test->select_count( $CLASS->table ));
    is( $one->create_validation_prognotes({
            status  => 1,
            type    => 'billing',
        }),
        14
    );
    is( @{ $one->prognotes }, 14 );
    is( $one->billing_cycle, undef );
    is_deeply( ids( $one->prognotes ), [ qw/
        1144 1043 1056 1143 1145 1044 1065 1159 1045 1057 1157 1158 1046 1058
    /]);
    for my $prognote_id( @{ ids $one->prognotes }) {
        is( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
    }

    $one->finish;
    # finish won't reset billing_status here because we don't have
    # an actual billing cycle object
    ok( eleMentalClinic::ProgressNote->retrieve( $_ )->update({ billing_status => undef }))
        for qw/ 1144 1043 1056 1143 1145 1044 1065 1159 1045 1057 1157 1158 1046 1058 /;
    is( eleMentalClinic::ProgressNote->new->id( $_ )->retrieve->billing_status, undef )
        for qw/ 1144 1043 1056 1143 1145 1044 1065 1159 1045 1057 1157 1158 1046 1058 /;
    is( --$count{ $CLASS->table }, $test->select_count( $CLASS->table ));

# XXX nuke set here
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create new billing validation set
        $count{ 'billing_cycle' } = $test->select_count( 'billing_cycle' );
    is( $CLASS->create({
        creation_date      => '2006-07-15',
        staff_id        => 1005,
        type            => 'validation',
        from_date            => '1900-01-01',
        to_date              => '1901-01-01',
    }), undef );
    is( $count{ $CLASS->table }, $test->select_count( $CLASS->table ));
    is( $count{ 'billing_cycle' }, $test->select_count( 'billing_cycle' ));

    ok( $one = $CLASS->create({
        creation_date      => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date            => '2006-07-15',
        to_date              => '2006-07-31',
    }));
    is( ++$count{ $CLASS->table }, $test->select_count( $CLASS->table ));
    is( ++$count{ 'billing_cycle' }, $test->select_count( 'billing_cycle' ));

    isa_ok( $one, $CLASS );
    is( $one->status, 'Initialized' ); # default
    is( @{ $one->prognotes }, 16 );
    is_deeply( ids( $one->prognotes ), [ qw/
        1049 1060 1050 1067 1350 1051 1061 1351 1052 1062 1053 1068 1054 1063 1055 1064
    /]);
    for my $prognote_id( @{ ids $one->prognotes }) {
        is( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
    }

    $tmp = ids( $one->prognotes );
    for my $prognote_id( @{ ids( eleMentalClinic::ProgressNote->new->get_all )}) {
        ( grep/^$prognote_id$/ => @$tmp )
            ? is( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
            : isnt( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# associated billing cycle
        $tmp = $one->billing_cycle_id;
    ok( $one->billing_cycle_id );
    isa_ok( $one->billing_cycle, 'eleMentalClinic::Financial::BillingCycle' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get by billing cycle
    can_ok( $CLASS, 'get_by_billing_cycle' );
    is( $CLASS->get_by_billing_cycle, undef );
    is( $CLASS->get_by_billing_cycle( 666 ), undef );

    isa_ok( $CLASS->get_by_billing_cycle( $tmp ), $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# finish billing cycle
        $tmp = $one->billing_cycle;
    ok( $one->finish );

    # make sure we've reset the billing status, since we didn't do anything with this cycle
    is( eleMentalClinic::ProgressNote->new->id( $_ )->retrieve->billing_status, undef )
        for qw/ 1049 1060 1050 1067 1051 1061 1052 1062 1053 1068 1054 1063 1055 1064 /;

    ok( $tmp->retrieve );
    is( $tmp->step, 0 );
    is( $tmp->status, 'Closed' );

    is( $CLASS->get_active, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bug-test and potential fix
# billing status was set incorrectly under these circumstances:
#   - there are bounced notes in this date range
#   - there are bounced notes outside this date range
#   - at least one bounced note outside this date range has been responded to
# this used to set the bounced notes we *do not* select to 'Prebilling'
    ok( $one = $CLASS->create({
        creation_date   => '2006-07-15',
        staff_id        => 1005,
        type            => 'billing',
        from_date       => '2006-08-01',
        to_date         => '2006-08-31',
    }));

    isa_ok( $one, $CLASS );
    is( $one->status, 'Initialized' ); # default
    is( @{ $one->prognotes }, 5 );
    is_deeply( ids( $one->prognotes ), [ qw/
        1244 1243 1444 1258 1445
    /]);
    for my $prognote_id( @{ ids $one->prognotes }) {
        is( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling' )
    }

    $tmp = ids( $one->prognotes );
    for my $prognote_id( @{ ids( eleMentalClinic::ProgressNote->new->get_all )}) {
        ( grep/^$prognote_id$/ => @$tmp )
            ? is( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling', "prognote: $prognote_id" )
            : isnt( eleMentalClinic::ProgressNote->retrieve( $prognote_id )->billing_status, 'Prebilling', "prognote: $prognote_id" )
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validation query
       $one = $CLASS->empty;
    can_ok( $one, 'validation_query' );
    is( $one->validation_query, undef );

    is( $one->validation_query( 'foo' ), undef );
    is( $one->validation_query( 'prognote' ), undef );

        ok( $one = $CLASS->create({
            creation_date      => '2006-07-15',
            staff_id        => 1005,
            type            => 'billing',
            from_date            => '2006-07-01',
            to_date              => '2006-07-10',
        }));

        $tmp = $one->id;
    is( $one->validation_query( 'foo' ), undef );
    is( $one->validation_query( 'prognote' ), qq/ SELECT prognote.rec_id
 FROM validation_prognote, prognote
 WHERE validation_prognote.prognote_id = prognote.rec_id
 AND validation_prognote.validation_set_id =$tmp
 ORDER BY prognote.rec_id/
    );

    is( $one->validation_query( 'validation_prognotes' ), qq/ SELECT validation_prognote.rec_id
 FROM validation_prognote, prognote
 WHERE validation_prognote.prognote_id = prognote.rec_id
 AND validation_prognote.validation_set_id =$tmp
 ORDER BY validation_prognote.rec_id/
    );

    # bugfix: we weren't getting a space before the "AND 1 = 0"
    is( $one->validation_query( 'prognote', $validation_rule->{ 1002 }), qq/ SELECT prognote.rec_id
 FROM validation_prognote, prognote
 WHERE validation_prognote.prognote_id = prognote.rec_id
 AND validation_prognote.validation_set_id =$tmp AND 1 = 0
 ORDER BY prognote.rec_id/
    );
    is( $one->validation_query( 'validation_prognotes', $validation_rule->{ 1002 } ), qq/ SELECT validation_prognote.rec_id
 FROM validation_prognote, prognote
 WHERE validation_prognote.prognote_id = prognote.rec_id
 AND validation_prognote.validation_set_id =$tmp AND 1 = 0
 ORDER BY validation_prognote.rec_id/
    );

    # payer_id should always be used in query
    is( $one->validation_query( 'prognote', undef, 1009 ), qq/ SELECT prognote.rec_id
 FROM validation_prognote, prognote
 WHERE validation_prognote.prognote_id = prognote.rec_id
 AND validation_prognote.validation_set_id =$tmp
 AND validation_prognote.rolodex_id = 1009
 ORDER BY prognote.rec_id/
    );

    is( $one->validation_query( 'validation_prognotes', undef, 1009 ), qq/ SELECT validation_prognote.rec_id
 FROM validation_prognote, prognote
 WHERE validation_prognote.prognote_id = prognote.rec_id
 AND validation_prognote.validation_set_id =$tmp
 AND validation_prognote.rolodex_id = 1009
 ORDER BY validation_prognote.rec_id/
    );

    # payer_id should always be used in query, and subbed in for all placeholders
    is( $one->validation_query( 'prognote', $validation_rule->{ 1005 }, 1009 ), qq/ SELECT prognote.rec_id
 FROM validation_prognote, prognote
LEFT OUTER JOIN 
    insurance_charge_code_association
    ON prognote.charge_code_id = insurance_charge_code_association.valid_data_charge_code_id
 WHERE validation_prognote.prognote_id = prognote.rec_id
 AND validation_prognote.validation_set_id =$tmp 
AND insurance_charge_code_association.rolodex_id = 1009
AND insurance_charge_code_association.acceptable = FALSE
 AND validation_prognote.rolodex_id = 1009
 ORDER BY prognote.rec_id/
    );

    is( $one->validation_query( 'validation_prognotes', $validation_rule->{ 1005 }, 1009 ), qq/ SELECT validation_prognote.rec_id
 FROM validation_prognote, prognote
LEFT OUTER JOIN 
    insurance_charge_code_association
    ON prognote.charge_code_id = insurance_charge_code_association.valid_data_charge_code_id
 WHERE validation_prognote.prognote_id = prognote.rec_id
 AND validation_prognote.validation_set_id =$tmp 
AND insurance_charge_code_association.rolodex_id = 1009
AND insurance_charge_code_association.acceptable = FALSE
 AND validation_prognote.rolodex_id = 1009
 ORDER BY validation_prognote.rec_id/
    );
        $one->finish;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test validation with SQL rule (only display results)
#    - provider must exist
#    - location must exist
#    - start and end time must exist
#    - note must exist
#    - client has a med ID for his insurance
#    - check notes with lengthy time duration

       $one = $CLASS->empty; 
    can_ok( $one, 'test_validate_sql' );
    is( $one->test_validate_sql, undef );

        ok( $one = $CLASS->create({
            creation_date      => '2006-07-15',
            staff_id        => 1005,
            type            => 'billing',
            from_date            => '2006-07-01',
            to_date              => '2006-07-15',
        }));
    # these tests include all the dups
    is( @{ $one->prognotes }, 18 );
    is_deeply( $one->test_validate_sql,
        [ qw/ 1043 1044 1045 1046 1047 1048 1056 1057 1058 1059 1065 1066 1143 1144 1145 1157 1158 1159 /]
    );

    # blank rules incoming, no effect
    is_deeply( $one->test_validate_sql({
            rule_select  => '',
            rule_from    => '',
            rule_where   => '',
            rule_order   => '',
        }),
        [ qw/ 1043 1044 1045 1046 1047 1048 1056 1057 1058 1059 1065 1066 1143 1144 1145 1157 1158 1159 /]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client has address: addr city post_code state
    # no effect since all clients comply
    is_deeply( $one->test_validate_sql({
            rule_from    => ', client, address',
            rule_where   => q/
                AND prognote.client_id = client.client_id
                AND client.client_id = address.client_id
                AND address.primary_entry = true
                AND address.address1  IS NOT NULL AND address.address1    != ''
                AND address.city      IS NOT NULL AND address.city        != ''
                AND address.post_code IS NOT NULL AND address.post_code   != ''
                AND address.state     IS NOT NULL AND address.state       != ''
            /,
        }),
        [ qw/ 1043 1044 1045 1046 1047 1048 1056 1057 1058 1059 1065 1066 1143 1144 1145 1157 1158 1159 /]
    );
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1003 }),
        [ qw/ 1043 1044 1045 1046 1047 1048 1056 1057 1058 1059 1065 1066 1143 1144 1145 1157 1158 1159 /]
    );

    ok( $one->live_validate_sql( $validation_rule->{ 1003 }));
    is_deeply( $one->rule_ids, [ qw/ 1003 /]);
    ok( $one->billing_cycle );
    is_deeply_except(
        { validation_prognote_id => qr/^\d+$/, modified => undef, },
        $one->results,
        [
            { pn_result( 1043 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1044 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1045 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1046 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1047 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1048 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1056 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1057 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1058 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1059 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1065 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1066 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1143 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1144 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1145 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1157 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1158 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1159 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
        ],
    );
    

    is_deeply_except(
        { validation_prognote_id => qr/^\d+$/, modified => undef, },
        $one->results( 1 ),
        [
            { pn_result( 1043 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1044 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1045 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1046 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1047 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1048 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1056 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1057 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1058 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1059 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1065 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1066 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1143 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1144 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1145 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1157 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1158 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
            { pn_result( 1159 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 },
        ]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
# set notes which fail rule 
    can_ok( $one, 'set_notes_which_fail_rule' ); 
    throws_ok{ $one->set_notes_which_fail_rule } qr/rule_id and status are required/;
    throws_ok{ $one->set_notes_which_fail_rule( 1001 )} qr/rule_id and status are required/;
    
    # FIXME don't care if the rule exists or not, for now ... hmph, pry we should ... 
    ok( $one->set_notes_which_fail_rule( 666, 'Unbillable' ));

    ok( $one->set_notes_which_fail_rule( 1003, 'Unbillable' ));
    # no results should have changed, since all notes passed 
    is_deeply_except( 
        { validation_prognote_id => qr/^\d+$/, modified => undef, }, 
        $one->results, 
        [ 
            { pn_result( 1043 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1044 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1045 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1046 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1047 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1048 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1056 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1057 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1058 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1059 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1065 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1066 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1143 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1144 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1145 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1157 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1158 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1159 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
        ], 
    ); 
    
    # now we fail some notes, in preparation for marking them as a group 
    ok( $one->db->do_sql( qq| 
        UPDATE validation_result 
        SET pass = FALSE 
        WHERE validation_result.validation_prognote_id IN ( 
        SELECT 
            validation_prognote.rec_id 
        FROM validation_prognote 
            LEFT JOIN prognote ON prognote.rec_id = validation_prognote.prognote_id 
        WHERE 
            prognote.rec_id IN ( 1043, 1044, 1056, 1057, 1143, 1144, 1157 ) 
        ) 
    |, 'RETURN' )); 
    
    # only "pass" should have changed here 
    is_deeply_except( 
        { validation_prognote_id => qr/^\d+$/, modified => undef, }, 
        $one->results, 
        [ 
            { pn_result( 1043 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1044 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1045 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1046 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1047 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1048 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1056 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1057 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1058 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1059 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1065 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1066 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1143 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1144 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1145 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1157 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1158 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1159 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
        ], 
    ); 
    # now we actually mark the notes 
    is( $one->set_notes_which_fail_rule( 1003, 'Unbillable' ), 7 ); 
    # and see the billing_status change reflected 
    is( scalar @{ $one->results( 0 )}, 7 ); 
    is_deeply_except( 
        { validation_prognote_id => qr/^\d+$/, modified => undef, }, 
        $one->results, 
        [ 
            { pn_result( 1043 ), billing_status => 'Unbillable', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1044 ), billing_status => 'Unbillable', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1045 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1046 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1047 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1048 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1056 ), billing_status => 'Unbillable', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1057 ), billing_status => 'Unbillable', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1058 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1059 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1065 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1066 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1143 ), billing_status => 'Unbillable', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1144 ), billing_status => 'Unbillable', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1145 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1157 ), billing_status => 'Unbillable', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1158 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1159 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
        ], 
    ); 
    
    # trying something whacky, to prove we can do it 
    is( $one->set_notes_which_fail_rule( 1003, 'WHACKY' ), 7 ); 
    # and see the billing_status change reflected 
    is( scalar @{ $one->results( 0 )}, 7 ); 
    is_deeply_except( 
        { validation_prognote_id => qr/^\d+$/, modified => undef, }, 
        $one->results, 
        [ 
            { pn_result( 1043 ), billing_status => 'WHACKY', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1044 ), billing_status => 'WHACKY', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1045 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1046 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1047 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1048 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1056 ), billing_status => 'WHACKY', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1057 ), billing_status => 'WHACKY', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1058 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1059 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1065 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1066 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1143 ), billing_status => 'WHACKY', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1144 ), billing_status => 'WHACKY', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1145 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1157 ), billing_status => 'WHACKY', rule_1003 => 0, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 0 }, 
            { pn_result( 1158 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
            { pn_result( 1159 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, rolodex_id => undef, force_valid => undef, pass => 1 }, 
        ], 
    ); 
    
    # clean up ... 
    $one->set_notes_which_fail_rule( 1003, 'Prebilling' ); 
    $test->delete_( 'validation_result', '*' );
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# new set
        eleMentalClinic::Client->new->id( 1003 )->retrieve->address->address1( '' )->save;
    is_deeply( $one->test_validate_sql({
            rule_from    => ', client, address',
            rule_where   => q/
                AND prognote.client_id = client.client_id
                AND client.client_id = address.client_id
                AND address.primary_entry = true
                AND address.address1  IS NOT NULL AND address.address1    != ''
                AND address.city      IS NOT NULL AND address.city        != ''
                AND address.post_code IS NOT NULL AND address.post_code   != ''
                AND address.state     IS NOT NULL AND address.state       != ''
            /,
        }),
        [ qw/ 1056 1057 1058 1059 1065 1066 1157 1158 1159 /]
    );
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1003 }),
        [ qw/ 1056 1057 1058 1059 1065 1066 1157 1158 1159 /]
    );

    ok( $one->live_validate_sql( $validation_rule->{ 1003 }));
    is_deeply( $one->rule_ids, [ qw/ 1003 /]);
    is( $one->rules->[ 0 ]->rec_id, $validation_rule->{ 1003 }{ rec_id } );
    $tmp = $one->results;
    is_deeply_except(
        { validation_prognote_id => qr/^\d+$/, modified => undef, },
        $tmp,
        [
            { pn_result( 1043 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1044 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1045 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1046 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1047 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1048 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1056 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1057 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1058 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1059 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1065 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1066 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1143 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1144 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1145 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1157 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1158 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1159 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
        ]
    );

    # Make sure all the fields required for the template are present.
    $tmp = $tmp->[0];
    ok( defined $tmp->{ id } );
    ok( defined $tmp->{ client_id } );
    ok( defined $tmp->{ start_date } );
    ok( defined $tmp->{ note_duration } );
    ok( defined $tmp->{ charge_code_name } );
    ok( defined $tmp->{ location_name } );
    ok( defined $tmp->{ note_units } );
    ok( defined $tmp->{ pass } );
    ok( defined $tmp->{ bill_manually } );
    ok( defined $tmp->{ billing_status } );

    is_deeply_except(
        { validation_prognote_id => qr/^\d+$/, modified => undef, },
        $one->results( 1 ),
        [
            { pn_result( 1056 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1057 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1058 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1059 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1065 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1066 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1157 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1158 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1159 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
        ]
    );
    is_deeply_except(
        { validation_prognote_id => qr/^\d+$/, modified => undef, },
        $one->results( 0 ),
        [
            { pn_result( 1043 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1044 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1045 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1046 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1047 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1048 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1143 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1144 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1145 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
        ]
    );
        $test->delete_( 'validation_result', '*' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# now make client 1004 invalid
#     print STDERR Dumper[ map{ $_->{ rec_id }} @{ $one->results(  )}];
#     print STDERR Dumper[ map{ $_->{ rec_id }} @{ $one->results( 1 )}];
#     print STDERR Dumper[ map{ $_->{ rec_id }} @{ $one->results( 0 )}];
        eleMentalClinic::Client->new->id( 1004 )->retrieve->address->post_code( '' )->save;
    is_deeply( $one->test_validate_sql({
            rule_from    => ', client, address',
            rule_where   => q/
                AND prognote.client_id = client.client_id
                AND client.client_id = address.client_id
                AND address.primary_entry = true
                AND address.address1  IS NOT NULL AND address.address1    != ''
                AND address.city      IS NOT NULL AND address.city        != ''
                AND address.post_code IS NOT NULL AND address.post_code   != ''
                AND address.state     IS NOT NULL AND address.state       != ''
            /,
        }),
        [ qw/ 1065 1066 /]
    );
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1003 }),
        [ qw/ 1065 1066 /]
    );

    ok( $one->live_validate_sql( $validation_rule->{ 1003 }));
    is_deeply( $one->rule_ids, [ qw/ 1003 /]);
    is( $one->rules->[ 0 ]->rec_id, $validation_rule->{ 1003 }{ rec_id } );

    is_deeply_except(
        { validation_prognote_id => qr/^\d+$/, modified => undef, },
        $one->results,
        [
            { pn_result( 1043 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1044 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1045 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1046 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1047 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1048 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1056 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1057 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1058 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1059 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1065 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1066 ), billing_status => 'Prebilling', rule_1003 => 1, payer_validation => 0, pass => 1, rolodex_id => undef, force_valid => undef },
            { pn_result( 1143 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1144 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1145 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1157 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1158 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
            { pn_result( 1159 ), billing_status => 'Prebilling', rule_1003 => 0, payer_validation => 0, pass => 0, rolodex_id => undef, force_valid => undef },
    ]);
        $test->delete_( 'validation_result', '*' );

        eleMentalClinic::Client->new->id( 1004 )->retrieve->address->post_code( '12345' )->save;
        eleMentalClinic::Client->new->id( 1004 )->retrieve->address->state( '' )->save;
    is_deeply( $one->test_validate_sql({
            rule_from    => ', client, address',
            rule_where   => q/
                AND prognote.client_id = client.client_id
                AND client.client_id = address.client_id
                AND address.primary_entry = true
                AND address.address1  IS NOT NULL AND address.address1    != ''
                AND address.city      IS NOT NULL AND address.city        != ''
                AND address.post_code IS NOT NULL AND address.post_code   != ''
                AND address.state     IS NOT NULL AND address.state       != ''
            /,
        }),
        [ qw/ 1065 1066 /]
    );
    is_deeply( $one->test_validate_sql( $validation_rule->{ 1003 }),
        [ qw/ 1065 1066 /]
    );

        eleMentalClinic::Client->new->id( 1005 )->retrieve->address->city( '' )->save;
    is( $one->test_validate_sql({
            rule_from    => ', client, address',
            rule_where   => q/
                AND prognote.client_id = client.client_id
                AND client.client_id = address.client_id
                AND address.primary_entry = true
                AND address.address1  IS NOT NULL AND address.address1    != ''
                AND address.city      IS NOT NULL AND address.city        != ''
                AND address.post_code IS NOT NULL AND address.post_code   != ''
                AND address.state     IS NOT NULL AND address.state       != ''
            /,
        }),
        undef
    );
    is( $one->test_validate_sql( $validation_rule->{ 1003 }), undef );

        # cleanup
        eleMentalClinic::Client->new( $client->{ 1003 })->save;
        eleMentalClinic::Client->new( $client->{ 1004 })->save;
        eleMentalClinic::Client->new( $client->{ 1005 })->save;
    $one->finish;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create validation prognotes, not selecting useless notes
        $one = $CLASS->new({
            status      => 1,
            creation_date  => '2006-08-01',
            staff_id    => 1005,
            from_date    => '2006-07-01',
            to_date      => '2006-07-31',
        });
        $one->save;

    # first, change some notes so they don't qualify
    # not committed
    eleMentalClinic::ProgressNote->new( $prognote->{ 1043 })->note_committed( 0 )->save;
    eleMentalClinic::ProgressNote->new( $prognote->{ 1056 })->note_committed( 0 )->save;
    # Paid
    eleMentalClinic::ProgressNote->new( $prognote->{ 1044 })->billing_status( 'Paid' )->save;
    eleMentalClinic::ProgressNote->new( $prognote->{ 1057 })->billing_status( 'Paid' )->save;
    # Prebilling
    eleMentalClinic::ProgressNote->new( $prognote->{ 1045 })->billing_status( 'Prebilling' )->save;
    eleMentalClinic::ProgressNote->new( $prognote->{ 1058 })->billing_status( 'Prebilling' )->save;
    # Unbillable
    eleMentalClinic::ProgressNote->new( $prognote->{ 1047 })->billing_status( 'Unbillable' )->save;
    eleMentalClinic::ProgressNote->new( $prognote->{ 1060 })->billing_status( 'Unbillable' )->save;
    # Billed
    eleMentalClinic::ProgressNote->new( $prognote->{ 1048 })->billing_status( 'Billed' )->save;
    eleMentalClinic::ProgressNote->new( $prognote->{ 1061 })->billing_status( 'Billed' )->save;

    is( $one->create_validation_prognotes, 24 );

    is( @{ $one->prognotes }, 24 );
    is( $one->billing_cycle, undef );
    is_deeply( ids( $one->prognotes ), [ qw/
        1144 1143 1145 1065 1159 1157 1158 1046 1066 1059 1049 1050 1067 1350 1051 1351 1052 1062 1053 1068 1054 1063 1055 1064
    /]);
    is( scalar @{ $CLASS->get_active }, 1 );
    ok( $one->finish );
    is( $CLASS->get_active, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set prognote billing status
    can_ok( $one, 'set_note_billing_status' );
    ok( $one = $CLASS->create({
        status          => 1,
        creation_date   => '2006-08-01',
        staff_id        => 1005,
        from_date       => '2006-07-01',
        to_date         => '2006-07-31',
        type            => 'billing',
    }));

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        sub change_and_verify_note_billing_status {
            my( $object, $status, $verify_only, $ids ) = @_;

            # because so many other notes are marked "Paid" already
            if( $status and $status eq 'Paid' ) {
                die 'This test will fail if status is "Paid."';
                return; # Test::Exception catches the "die"
            }
            # ids in the validation set
            my @ids = qw/
                1144 1043 1056 1143 1145 1044 1065 1159 1045 1057
                1157 1158 1046 1058 1047 1066 1048 1059 1049 1060 1050 1067 1051
                1061 1052 1062 1053 1068 1054 1063 1055 1064
                1350 1351
            /;

            if( $ids and ref $ids eq 'ARRAY' and @$ids ) {
                @ids = @$ids;
            }
            else {
                $ids = [];
            }

            ok( $object->set_note_billing_status( $status, $ids ))
                unless $verify_only;
            for my $prognote( @{ eleMentalClinic::ProgressNote->new->get_all }) {
                my $id = $prognote->id;
                if( grep /^$id$/ => @ids ) { # if the note is in this set
                    my $message = $status
                        ? "Note $id, changed to '$status'"
                        : "Note $id, changed to NULL";
                    is( $prognote->billing_status, $status, $message );
                }
                else {
                    # we want to make sure that notes not in the set have not been changed
                    # UNLESS we're verifying setting the set notes to 'undef', in which
                    # case we skip this, because the non-set notes may have been undef already
                    isnt( $prognote->billing_status, $status, "Note $id, should NOT be changed" )
                        unless not defined $status;
                }
            }
        }
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    throws_ok{ change_and_verify_note_billing_status( $one, 'Paid', 1 )}
        qr/This test will fail if status is "Paid."/;
    change_and_verify_note_billing_status( $one, 'Prebilling', 1 ); # checking, not changing
    change_and_verify_note_billing_status( $one, 'Unbillable' );
    change_and_verify_note_billing_status( $one->billing_cycle, 'Gollum' );
    change_and_verify_note_billing_status( $one, 'Your mom' );
    change_and_verify_note_billing_status( $one, 'Your mom, dude', undef, [ qw/ 1043 1044 1045 /]);
    # should set to undef
    change_and_verify_note_billing_status( $one );

    # should also work for billing cycle
    # FIXME : should move these to 502billing_cycle.t
    # which would mean duplicating the subroutine somehow
    change_and_verify_note_billing_status( $one->billing_cycle, 'Finished' );
    # should set to undef
    change_and_verify_note_billing_status( $one->billing_cycle );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
