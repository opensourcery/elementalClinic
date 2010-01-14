# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use warnings;
use strict;

use Test::More tests => 21;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Venus::Rolodex';
    use_ok( $CLASS );
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
# runmodes
    can_ok( $CLASS, 'ops' );
    ok( my %ops = $CLASS->ops );
    is_deeply( [ sort keys %ops ], [ sort qw/
        home rolodex_new rolodex_edit rolodex_save
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home rolodex_new rolodex_edit rolodex_save
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# *NOTE* This controller test was written well after the controller, a majority
# of these tests therfor are written from looking at the controller and what I
# *think* it is supposed to do. This testing is to find bugs, and define
# expected behavior to prevent future breakage.

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Home

    my $user = eleMentalClinic::Personnel->retrieve( 1001 );
    my $rolodex = eleMentalClinic::Rolodex->new;
    $one->current_user( $user );
    is_deeply(
        $one->home,
        {
            rolodex         => $rolodex,
            address         => $rolodex->addresses->[0],
            phone           => $rolodex->phones->[0],
            rolodex_entries => $one->list_rolodex_entries, #This function is tested elseware
            op              => 'home',
            current_role    => $rolodex->roles( $user->pref->rolodex_filter ),
            all_role_names  => [ map { $_->{ name }} @{ $rolodex->roles }],
        },
        "Home returns the correct variables"
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex_new

    is_deeply(
        $one->rolodex_new,
        $one->rolodex_edit,
        "new is essentially an alias to edit."
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex_edit

    $rolodex = eleMentalClinic::Rolodex->retrieve( 1001 );
    $one = $CLASS->new_with_cgi_params(
        rolodex_id => 1001,
        op => 'rolodex_edit',
    );
    is_deeply(
        $one->rolodex_edit,
        {
            rolodex          => $rolodex,
            address          => $rolodex->addresses->[0],
            phone            => $rolodex->phones->[0],
            rolodex_roles    => eleMentalClinic::Rolodex->new->roles,
            rolodex_entries  => $one->list_rolodex_entries, #Tested elseware
            op               => 'rolodex_edit',
            in_roles         => undef,
            dupsok           => 0,
            schedule_type_id => $rolodex->schedule->get_schedule_type( 1001 ),
        },
        "rolodex_edit runmode",
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex_save

    $rolodex = eleMentalClinic::Rolodex->new;
    $one = $CLASS->new_with_cgi_params(
        op => 'rolodex_save',

        fname           => 'Bob',
        lname           => 'Marley',
        name            => 'Organization Name',
        credentials     => 'The credentials',
        comment_text    => 'Some comment',

        address1        => '999 Xxx St.',
        address2        => 'Unit 99',
        city            => 'Funkytown',
        state           => 'NY',
        post_code       => 99999,
        phone           => '555-555-5555',
        phone_2         => '565-656-5656',

        #These were/are hidden fields in the template.
        role_treaters   => 1,
        treaters        => 1,
    );
    $one->current_user( $user );
    # Save the ouput to check, we cannot obtain the rolodex until it is
    # finished, so an is deeply needs to come after
    ok( my $output = $one->rolodex_save );
    $rolodex = eleMentalClinic::Rolodex->get_one_by_( 'lname', 'Marley' );
    is_deeply(
        $output,
        # Saving a doctor should go back to the edit page,
        # we should test edit's return elsware.
        {
            %{ $one->rolodex_edit( $rolodex ) },
            phone_1 => '555-555-5555', #Added to make it possible to 'remember' value on error.
        },
        "Saved a doctor.",
    );

    $rolodex = eleMentalClinic::Rolodex->get_one_by_( 'lname', 'Marley' );
    is( $rolodex->phones->[0]->phone_number, '555-555-5555', "Primary phone number" );
    is( $rolodex->phones->[1]->phone_number, '565-656-5656', "Secondary phone number" );
    is( $rolodex->phones->[2], undef, 'Only 2 phone numbers.' );

    is_deeply(
        $rolodex->addresses,
        [{
            rec_id          => $rolodex->addresses->[0]->id, #no brainer.
            client_id       => undef,
            rolodex_id      => $rolodex->id,
            address1        => '999 Xxx St.',
            address2        => 'Unit 99',
            city            => 'Funkytown',
            state           => 'NY',
            post_code       => 99999,
            county          => undef,
            active          => 1,
            primary_entry   => 1,
        }],
        "Address is saved."
    );
#CLEANUP

    $one->db->do_sql( "DELETE FROM rolodex_treaters WHERE rolodex_id = ?", 1, $rolodex->id );
    $rolodex->delete;


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# roles_exist
    $one = $CLASS->new_with_cgi_params(
        op => 'rolodex_save',

        referral    => 1,
        treaters    => 1,
        contacts    => 1,
        employment  => 1,
        dental_insurance  => 0,
        medical_insurance => 0,
        mental_health_insurance => 0,
    );
    is( $one->roles_exist, 4 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_rolodex

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_rolodex_entries

##########################################################
# The following are probably old and unused, ticket #293 #
##########################################################

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# relationship_save

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# relationship_edit

#    is_deeply(
#        $one->relationship_new,
#        $one->relationship_edit,
#        "new is essentially an alias to edit."
#    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# relationship_new

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_relationship


dbinit( );
