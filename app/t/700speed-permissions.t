#!/usr/bin/perl
use strict;
use warnings;

use Test::More skip_all => 'This test breaks most of the tests that follow it.';
use eleMentalClinic::Test;
use Data::Dumper;

sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 0 );

use_ok 'eleMentalClinic::Client';
use_ok 'eleMentalClinic::Personnel';
use_ok 'eleMentalClinic::Role';
use_ok 'eleMentalClinic::Role::Cache';
use_ok 'eleMentalClinic::Role::ClientPermission';
use_ok 'eleMentalClinic::Role::GroupPermission';
use_ok 'eleMentalClinic::Role::Member';

eleMentalClinic::DB->new->transaction_begin;
eval {
    #Create 5 roles, A-E
    #Create users a-k for each role (Aa Ab .. Ek)
    #role A is in admin
    #role E is in all_users
    #User a in any role is admin
    #User e in any role is all_users
    #Create 3 clients per personnel (x-z)
    #Clients 'x' are granted to role B
    #Clients 'y' are granted to role C
    #Clients 'z' are granted to role D

    my %ROLES;
    my %USERS;
    my %CLIENTS;
    my $SSN = 1111;
    for my $i ( 'A' .. 'E' ) {
        my $role = eleMentalClinic::Role->new({
            name => $i,
            system_role => 1,
            has_homepage => 0,
        });
        $role->save;
        $ROLES{ $i } = $role;

        for my $j ( 'a' .. 'k' ) {
            my $user = eleMentalClinic::Personnel->new({
                fname => $i,
                lname => $j,
                unit_id => 1,
                dept_id => 1,
            });
            $user->save;
            $USERS{ "$i$j" } = $user;

            $role->add_member( $user->primary_role );

            eleMentalClinic::Role->admin_role->add_member( $user->primary_role ) if $j eq 'a';
            eleMentalClinic::Role->all_clients_role->add_member( $user->primary_role ) if $j eq 'e';
            eleMentalClinic::Role->get_one_by_( 'name', 'active' )->add_member( $user->primary_role );

            for my $k ( 'x' .. 'z' ) {
                my $client = eleMentalClinic::Client->new({
                    ssn     => '111-11-' . $SSN++,
                    mname   => $i,
                    fname   => $j,
                    lname   => $k,
                });
                $client->save;
                $CLIENTS{ "$i$j$k" } = $client;
                $user->primary_role->grant_client_permission( $client );

                $role->grant_client_permission( $client ) if (
                    ( $i eq 'B' && $k eq 'x' ) ||
                    ( $i eq 'C' && $k eq 'y' ) ||
                    ( $i eq 'D' && $k eq 'z' )
                );
            }
        }

        eleMentalClinic::Role->admin_role->add_member( $role ) if $i eq 'A';
        eleMentalClinic::Role->all_clients_role->add_member( $role ) if $i eq 'E';
    }

    my $start = time;
    diag "Start:";
    for my $client ( values %CLIENTS ) {
        my $start = time;
        my $access = $client->access;
        ok( time - $start < 5, "Reasonable speed" );
        for my $name ( keys %$access ) {
            ok( @{ $access->{ $name }}, "Access list for staff: $name" );
            for my $item ( @{ $access->{ $name }}) {
                is( $item->staff->lname . ', ' . $item->staff->fname, $name, "Correct name for item" )
            }
        }
    }
    diag "Final Time: " . (time() - $start);
};
ok( !$@, "Tests ran" ) || diag( $@ );
eleMentalClinic::DB->new->transaction_rollback;

dbinit( 0 );
