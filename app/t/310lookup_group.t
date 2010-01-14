# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 328;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Lookup::Group';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->delete_( 'lookup_group_entries', '*' );
        $test->delete_( 'lookup_associations', '*' );
#         $test->delete_( 'lookup_groups', '*' );
        $test->insert_data;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# methods
    can_ok( $one, qw/ rec_id parent_id name description active system / );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_by_table failures
    dies_ok{ $one->get_by_table };
    throws_ok{ $one->get_by_table } qr/Table id required/;
    throws_ok{ $one->get_by_table( 1, 'foo' )} qr/Options must be a hashref/;


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_by_table successes
    is( $one->get_by_table( 1 ), undef );
    is_deeply( $one->get_by_table( 3 ), [
        $lookup_groups->{ 1004 },
        $lookup_groups->{ 1006 },
        $lookup_groups_default->{ 1 },
        $lookup_groups->{ 1003 },
        $lookup_groups->{ 1001 },
        $lookup_groups->{ 1002 },
        $lookup_groups_default->{ 2 },
        $lookup_groups->{ 1005 },
    ]);

    is_deeply( $one->get_by_table( 3, { active => 1 }), [
        $lookup_groups->{ 1004 },
        $lookup_groups_default->{ 1 },
        $lookup_groups->{ 1003 },
        $lookup_groups->{ 1001 },
        $lookup_groups->{ 1002 },
        $lookup_groups_default->{ 2 },
        $lookup_groups->{ 1005 },
    ]);

    is_deeply( $one->get_by_table( 3, { name => 'Global' }), [
        $lookup_groups_default->{ 1 },
    ]);

    is_deeply( $one->get_by_table( 3, { name => 'No validation required' }), [
        $lookup_groups_default->{ 2 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# members
    can_ok( $one, qw/ members / );
        undef $one->{ rec_id };
    is_deeply( $one->members, []);

        $one->rec_id( 1001 );
    is_deeply( $one->members, [ qw/
        1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
    /]);

        $one->rec_id( 1002 );
    is_deeply( $one->members, [ qw/
        1001 1002 1003 1004 1015 1016 1029 1030 1031 1032
    /]);

        $one->rec_id( 1003 );
    is_deeply( $one->members, [ qw/
        1007 1008 1009 1010 1011 1012 1013 1014 1022 1023 1033 1034
    /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# members_lookup
    can_ok( $one, qw/ members_lookup / );
        undef $one->{ rec_id };
    is_deeply( $one->members_lookup, {});

        $one->rec_id( 1001 );
    is_deeply( $one->members_lookup, {
        1001 => 1,
        1002 => 1,
        1003 => 1,
        1004 => 1,
        1005 => 1,
        1006 => 1,
        1015 => 1,
        1016 => 1,
        1022 => 1,
        1025 => 1,
        1026 => 1,
        1027 => 1,
        1028 => 1,
        1029 => 1,
        1030 => 1,
        1033 => 1,
        1034 => 1,
    });

        $one->rec_id( 1002 );
    is_deeply( $one->members_lookup, {
        1001 => 1,
        1002 => 1,
        1003 => 1,
        1004 => 1,
        1015 => 1,
        1016 => 1,
        1029 => 1,
        1030 => 1,
        1031 => 1,
        1032 => 1,
    });

        $one->rec_id( 1003 );
    is_deeply( $one->members_lookup, {
        1007 => 1,
        1008 => 1,
        1009 => 1,
        1010 => 1,
        1011 => 1,
        1012 => 1,
        1013 => 1,
        1014 => 1,
        1022 => 1,
        1023 => 1,
        1033 => 1,
        1034 => 1,
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_member
        undef $one->{ rec_id };
    dies_ok{ $one->is_member };
    throws_ok{ $one->is_member } qr/Item id is required./;
    throws_ok{ $one->is_member( 1 )} qr/No group id: cannot check membership of an undefined group./;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_member
        $one->rec_id( 1001 );
    is( $one->is_member( $_ ), 1 ) for qw/
        1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
        /;

    is( $one->is_member( $_ ), undef ) for qw/
        1007 1008 1009 1010 1011 1012 1013 1014 1017 1018 1019 1020 1021 1023 1024 1031 1032 1035 1036
        /;

        $one->rec_id( 1002 );
    is( $one->is_member( $_ ), 1 ) for qw/
        1001 1002 1003 1004 1015 1016 1029 1030 1031 1032
        /;
    is( $one->is_member( $_ ), undef ) for qw/
        1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1017 1018 1019 1020 1021 1022 1023 1024 1025 1026 1027 1028 1033 1034 1035 1036
        /;

        $one->rec_id( 1003 );
    is( $one->is_member( $_ ), 1 ) for qw/
        1007 1008 1009 1010 1011 1012 1013 1014 1022 1023 1033 1034
        /;
    is( $one->is_member( $_ ), undef ) for qw/
        1001 1002 1003 1004 1005 1006 1015 1016 1017 1018 1019 1020 1021 1024 1025 1026 1027 1028 1029 1030 1031 1032 1035 1036
        /;

        $one->rec_id( 1004 );
    is( $one->is_member( $_ ), 1 ) for qw/
        1001 1002 1021 1022 1027 1028
        /;
    is( $one->is_member( $_ ), undef ) for qw/
        1003 1004 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1017 1018 1019 1020 1023 1024 1025 1026 1029 1030 1031 1032 1033 1034 1035 1036
        /;

        $one->rec_id( 1005 );
    is( $one->is_member( $_ ), 1 ) for qw/
        1023 1024 1029 1030 1031 1032 1033 1034
        /;
    is( $one->is_member( $_ ), undef ) for qw/
        1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1017 1018 1019 1020 1021 1022 1025 1026 1027 1028 1035 1036
        /;

        $one->rec_id( 1006 );
    is( $one->is_member( $_ ), 1 ) for qw/
        1017 1018 1019 1020
        /;
    is( $one->is_member( $_ ), undef ) for qw/
        1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034 1035 1036
        /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set_members
    can_ok( $one, qw/ set_members / );
    throws_ok{ $one->set_members( 1, 2, 3 )} qr/Member ids must be an arrayref./;

    ok( ! $one->set_members );
        $one->rec_id( 1004 );

    ok( $one->set_members([ qw/ 1001 /]));
    is_deeply( $one->members, [ qw/ 1001 /]);

    ok( $one->set_members([ qw/ 1002 /]));
    is_deeply( $one->members, [ qw/ 1002 /]);

    ok( $one->set_members([ qw/ 1003 1003 1003 /]));
    is_deeply( $one->members, [ qw/ 1003 /]);

    ok( $one->set_members([ qw/ 1001 1002 1003 /]));
    is_deeply( $one->members, [ qw/ 1001 1002 1003 /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# name exists should return true if:
# - name matches
# - parent_id matches
# - rec_id does not match
    can_ok( $one, qw/ name_is_dup / );

        undef $one->{ rec_id };
        undef $one->{ name };
        undef $one->{ parent_id };
    throws_ok{ $one->name_is_dup } qr/Name and parent_id are required./;

        $one->name( 'Test group' );
    throws_ok{ $one->name_is_dup } qr/Name and parent_id are required./;

        $one->parent_id( 28 );
    ok( $one->name_is_dup );

        $one->parent_id( 3 );
    ok( ! $one->name_is_dup );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_by_personnel_association
    can_ok( $one, qw/ get_by_personnel_association / );
    throws_ok{ $one->get_by_personnel_association }
        qr/Table id and staff id are required by Lookup::Groups::get_by_personnel_association./;

    is_deeply( $one->get_by_personnel_association( 3, 1001 ), [
        { %{ $lookup_groups->{ 1001 }}, sticky => 1 },
        { %{ $lookup_groups->{ 1002 }}, sticky => 0 },
    ]);

    is_deeply( $one->get_by_personnel_association( 3, 1002 ), [
        { %{ $lookup_groups->{ 1003 }}, sticky => 0 },
        { %{ $lookup_groups->{ 1001 }}, sticky => 1 },
    ]);

    is_deeply( $one->get_by_personnel_association( 3, 1003 ), [
        { %{ $lookup_groups->{ 1001 }}, sticky => 1 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $one->rec_id( 1001 );
    can_ok( $one, qw/ lookup_associations / );
    throws_ok{ $one->lookup_associations }
        qr/Table id is required by Lookup::Groups::lookup_associations./;

        undef $one->{ rec_id };
    throws_ok{ $one->lookup_associations }
        qr/Group id is required by Lookup::Groups::lookup_associations./;

        $one->rec_id( 1001 );
    is_deeply( $one->lookup_associations( 12 ), [ qw/ 1003 /]);
    is_deeply( $one->lookup_associations( 28 ), [ qw/ 1002 1004 1 /]);

# subroutine 'cause we're repeating this several times verbatim
sub test_groups_1002_plus {
    my( $one ) = @_;

        $one->rec_id( 1002 );
    is( $one->lookup_associations( 12 ), undef );
    is_deeply( $one->lookup_associations( 28 ), [ qw/ 1003 1004 /]);

        $one->rec_id( 1003 );
    is_deeply( $one->lookup_associations( 12 ), [ qw/ 1002 /]);
    is_deeply( $one->lookup_associations( 28 ), [ qw/ 1003 1004 /]);

        $one->rec_id( 1004 );
    is_deeply( $one->lookup_associations( 12 ), [ qw/ 1003 1004 /]);
    is_deeply( $one->lookup_associations( 28 ), [ qw/ 1002 1003 1004 1 /]);

        $one->rec_id( 1005 );
    is_deeply( $one->lookup_associations( 12 ), [ qw/ 1002 1003 /]);
    is_deeply( $one->lookup_associations( 28 ), [ qw/ 1002 1003 1004 /]);

        $one->rec_id( 1006 );
    is_deeply( $one->lookup_associations( 12 ), [ qw/ 1004 /]);
    is_deeply( $one->lookup_associations( 28 ), [ qw/ 1003 1 /]);
}
    test_groups_1002_plus( $one );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set lookup associations
    can_ok( $one, qw/ set_lookup_associations / );
    throws_ok{ $one->set_lookup_associations }
        qr/Table id is required by Lookup::Groups::set_lookup_associations./;
    is( $one->set_lookup_associations( 1 ), undef );
    throws_ok{ $one->set_lookup_associations( 1, 2 ) }
        qr/Lookup ids must be an arrayref at Lookup::Groups::set_lookup_associations./;

        $one->rec_id( 1001 );
    ok( $one->set_lookup_associations( 12, [] ));
    is( $one->lookup_associations( 12 ), undef );

    ok( $one->set_lookup_associations( 28, [] ));
    is( $one->lookup_associations( 28 ), undef );

    # make sure we haven't delete anything else
    test_groups_1002_plus( $one );

        $one->rec_id( 1001 );
    ok( $one->set_lookup_associations( 12, [ qw/ 1001 /]));
    is_deeply( $one->lookup_associations( 12 ), [ qw/ 1001 /]);

    ok( $one->set_lookup_associations( 12, [ qw/ 1001 1001 1001 /]));
    is_deeply( $one->lookup_associations( 12 ), [ qw/ 1001 /]);

    ok( $one->set_lookup_associations( 12, [ qw/ 1001 1002 1003 1004 /]));
    is_deeply( $one->lookup_associations( 12 ), [ qw/ 1001 1002 1003 1004 /]);

    ok( $one->set_lookup_associations( 28, [ qw/ 1001 /]));
    is_deeply( $one->lookup_associations( 28 ), [ qw/ 1001 /]);

    ok( $one->set_lookup_associations( 28, [ qw/ 1001 1001 1001 /]));
    is_deeply( $one->lookup_associations( 28 ), [ qw/ 1001 /]);

    ok( $one->set_lookup_associations( 28, [ qw/ 1001 1002 1003 1004 /]));
    is_deeply( $one->lookup_associations( 28 ), [ qw/ 1001 1002 1003 1004 /]);

    # make sure no other groups were affected
    test_groups_1002_plus( $one );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_codes_by_group_name_and_parent
    can_ok( $one, qw/ get_codes_by_group_name_and_parent / );
    throws_ok{ $one->get_codes_by_group_name_and_parent }
        qr/Group and parent name are required by ::Lookup::Group::get_codes_by_group_name_and_parent./;

    is_deeply( $one->get_codes_by_group_name_and_parent(
            'Global',
            'valid_data_charge_code',
        ), [
            {
                dept_id     => 1001,
                active      => 1,
                name        => 'N/A',
                rec_id      => 1,
                description => undef,
                min_allowable_time               => undef,
                max_allowable_time               => undef,
                minutes_per_unit                 => undef,
                dollars_per_unit                 => undef,
                max_units_allowed_per_encounter  => undef,
                max_units_allowed_per_day        => undef,
                cost_calculation_method          => undef,
            },
            {
                dept_id     => 1001,
                active      => 1,
                name        => 'No Show',
                rec_id      => 2,
                description => undef,
                min_allowable_time               => undef,
                max_allowable_time               => undef,
                minutes_per_unit                 => undef,
                dollars_per_unit                 => undef,
                max_units_allowed_per_encounter  => undef,
                max_units_allowed_per_day        => undef,
                cost_calculation_method          => undef,
            }
        ]
    );

    is_deeply( $one->get_codes_by_group_name_and_parent(
            'Medication-related',
            'valid_data_charge_code',
        ), [
            $valid_data_charge_code->{ 1001 },
            $valid_data_charge_code->{ 1002 },
            $valid_data_charge_code->{ 1003 },
            $valid_data_charge_code->{ 1004 },
            $valid_data_charge_code->{ 1015 },
            $valid_data_charge_code->{ 1016 },
            $valid_data_charge_code->{ 1029 },
            $valid_data_charge_code->{ 1030 },
            $valid_data_charge_code->{ 1031 },
            $valid_data_charge_code->{ 1032 },
        ]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_ids_by_group_name_and_parent
    can_ok( $one, qw/ get_ids_by_group_name_and_parent / );
    throws_ok{ $one->get_ids_by_group_name_and_parent }
        qr/Group and parent name are required by ::Lookup::Group::get_codes_by_group_name_and_parent./;

    # should be a TODO, but the error kills it
#     TODO: {
#         local $TODO = 'Should check to see if table name is valid';
#         is( $one->get_ids_by_group_name_and_parent( 'one', 'two' ), undef );
#     }

        $one->rec_id( 1 );
    is_deeply( $one->get_ids_by_group_name_and_parent(
        'Global',
        'valid_data_charge_code',
    ), $one->members );

        $one->rec_id( 1001 );
    is_deeply( $one->get_ids_by_group_name_and_parent(
        'Individual therapy',
        'valid_data_charge_code',
    ), $one->members );

        $one->rec_id( 1002 );
    is_deeply( $one->get_ids_by_group_name_and_parent(
        'Medication-related',
        'valid_data_charge_code',
    ), $one->members );

        $one->rec_id( 1005 );
    is_deeply( $one->get_ids_by_group_name_and_parent(
        'Training and education',
        'valid_data_charge_code',
    ), $one->members );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->delete_( 'lookup_group_entries', '*' );
        $test->delete_( 'lookup_associations', '*' );
#         $test->delete_( 'lookup_groups', '*' );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
