#!/usr/bin/perl

# Test emc::Rolodex::ByState and the emc::Rolodex::HasByState role

use strict;
use warnings;

use Test::More;

use Test::More 'no_plan';
use eleMentalClinic::Test;

my $CLASS = 'eleMentalClinic::Rolodex::ByState';
use_ok $CLASS;

sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );


# Test a rolodex with no state information
{
    my $rolodex = eleMentalClinic::Rolodex->retrieve(1001);
    is_deeply $rolodex->all_by_state, {}, "all_by_state() empty";
    is $rolodex->by_state("OR"), undef,   "by_state() empty";

    ok !eval { $rolodex->by_state },      "by_state with no state";
}


# Add, change and remove state information
{
    # Add one
    my $rolodex = eleMentalClinic::Rolodex->retrieve(1001);
    my $or = $rolodex->add_by_state(OR => { license => "12345abc" });

    ok $or->id;
    is $or->license, "12345abc";
    is $or->rolodex_id, $rolodex->id;

    is $rolodex->by_state("OR")->id, $or->id;


    # Add another
    my $wa = $rolodex->add_by_state(WA => { license => "qzxy" });
    ok $wa->id;


    # Test all_by_state
    my $all = $rolodex->all_by_state;
    is_deeply $all, {
        OR => $or,
        WA => $wa,
    };


    # Delete one
    $or->delete;
    ok !$rolodex->by_state("OR");
    is_deeply $rolodex->all_by_state, { WA => $wa };
}
