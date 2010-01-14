# vim: ts=4 sts=4 sw=4
# Copyright (C) 2004-2009 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 113;
use eleMentalClinic::Test;
use Data::Dumper;

our ($CLASS, $one, $tmp);

BEGIN {
    *CLASS = \'eleMentalClinic::Role';
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
    is( $one->table, 'personnel_role');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/ rec_id name staff_id system_role has_homepage special_name /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

    can_ok( $CLASS, @{ $CLASS->fields }, qw/direct_members direct_client_permissions direct_group_permissions/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    $one = $CLASS->retrieve( 4 );
    is_deeply(
        [ sort { $a->id <=> $b->id } @{ $one->direct_members }],
        [ map { eleMentalClinic::Role::DirectMember->retrieve( $_ ) } qw/8 100010 100013 100017 100020 100025 100028/],
        "Got direct members of " . $one->name
    );

    eleMentalClinic::Role::DirectClientPermission->new({ role_id => $one->id, client_id => $_ })->save for 1001 .. 1003;

    is_deeply(
        [ map { $_->client_id } @{ $one->direct_client_permissions }],
        [ 1001 .. 1003 ],
        "Got direct client permissions for " . $one->name
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get some stuff setup to work with

    my $all_clients = $CLASS->retrieve( 2 );

    my %users = map {
        my $n = $_;
        my $u = eleMentalClinic::Personnel->new({
            unit_id => 1001,
            dept_id => 1001,
            map { $_ => $n } qw/fname lname mname login/
        });
        $u->save;
        # Refresh after save.
        $n => eleMentalClinic::Personnel->retrieve( $u->id );
    } 'a' .. 'k';

    my %roles = map {
        my $r = $CLASS->new({ name => $_, system_role => 1, has_homepage => 0});
        $r->save;
        $_ => $r;
    } qw/parent child subchild/;

    $roles{ parent }->add_member( $roles{ child });
    $roles{ child }->add_member( $roles{ subchild });

    $roles{ parent }->add_personnel( @users{'a' .. 'c'} );
    $roles{ child }->add_personnel( @users{'d' .. 'f'} );
    $roles{ subchild }->add_personnel( @users{'g' .. 'i'} );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    is_deeply(
        [ sort { $a->id <=> $b->id } map { $_->member } @{ $roles{ subchild }->direct_members }],
        [ sort { $a->id <=> $b->id } map { $_->primary_role } @users{'g' .. 'i'}],
        "Correct direct members"
    );

    is_deeply(
        [ sort { $a->id <=> $b->id } map { $_->member } @{ $roles{ subchild }->all_members }],
        [ sort { $a->id <=> $b->id } map { $_->primary_role } @users{'g' .. 'i'}],
        "Correct all members"
    );

    is_deeply(
        [
            sort { $a->id <=> $b->id }
                map { $_->member } @{ $roles{ child }->all_members }
        ],
        [
            sort { $a->id <=> $b->id }
            (map { $_->primary_role } @users{'d' .. 'i'}),
            $roles{ subchild }
        ],
        "correct direct members"
    );

    is_deeply(
        [
            sort { $a->id <=> $b->id }
            map { $_->member } @{ $roles{ child }->direct_members }
        ],
        [
            sort { $a->id <=> $b->id }
            (map { $_->primary_role } @users{'d' .. 'f'}),
            $roles{ subchild }
        ],
        "correct all members"
    );

    is_deeply(
        [
            sort { $a->name cmp $b->name } map { $_->member }
                @{ $roles{ parent }->direct_members }
        ],
        [
            sort { $a->name cmp $b->name }
            (map { $_->primary_role } @users{'a' .. 'c'}),
            $roles{ child },
        ],
        "correct direct members"
    );

    is_deeply(
        [
            sort { $a->name cmp $b->name } map { $_->member }
                @{ $roles{ parent }->all_members }
        ],
        [
            sort { $a->name cmp $b->name }
            (map { $_->primary_role } @users{'a' .. 'i'}),
            $roles{ child },
            $roles{ subchild },
        ],
        "correct all members"
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    is( $roles{ parent }->direct_parents, undef, "correct direct parents" );
    is( $roles{ parent }->all_parents, undef, "correct all parents" );

    is_deeply(
        [
            map { $_->role }
            @{ $roles{ child }->direct_parents }
        ],
        [ $roles{ parent } ],
        "correct direct parents"
    );
    is_deeply(
        [
            map { $_->role }
            @{ $roles{ child }->all_parents }
        ],
        [ $roles{ parent } ],
        "correct all parents"
    );

    is_deeply(
        [
            map { $_->role }
            @{ $roles{ subchild }->direct_parents }
        ],
        [ $roles{ child } ],
        "correct direct parents"
    );
    is_deeply(
        [
            sort { $a->name cmp $b->name }
            map { $_->role }
            @{ $roles{ subchild }->all_parents },
        ],
        [
            sort { $a->name cmp $b->name }
            $roles{ parent },
            $roles{ child },
        ],
        "correct all parents"
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    is( $roles{ parent }->direct_personnel, undef, "No personnel for system group" );
    is_deeply(
        [
            sort { $a->id <=> $b->id }
            @{ $roles{ parent }->all_personnel}
        ],
        [ sort { $a->id <=> $b->id } @users{'a' .. 'i'} ],
        "all personnel found"
    );
    is_deeply( $users{ 'a' }->primary_role->direct_personnel, $users{ 'a' }, "Personnel specific role has personnel" );

    ok( $roles{ parent }->has_personnel( @users{ 'a' .. 'c' }), "Role has all its direct members" );
    ok( $roles{ parent }->has_personnel( @users{ 'a' .. 'i' }), "Role has all its descended members" );
    ok( ! $roles{ parent }->has_personnel( $users{ 'j' }), "Role does not have j" );
    ok( ! $roles{ parent }->has_personnel( @users{ 'a' .. 'j' }), "Role does not have j" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    my $result = $roles{ parent }->add_members( map { $_->primary_role } @users{qw/j k/});
    is( @$result, 2, "2 memberships" );
    ok( $roles{ parent }->has_members( map { $_->primary_role } @users{qw/j k/} ), "Memberships added" );

    ok( $roles{ parent }->del_member( map { $_->primary_role } $users{j}), "deleted member");
    ok( ! $roles{ parent }->has_members( map { $_->primary_role } @users{qw/j k/} ), "Memberships deleted" );
    ok( $roles{ parent }->has_members( map { $_->primary_role } @users{qw/k/} ), "Membership still here" );

    $roles{ parent }->add_members( map { $_->primary_role } @users{qw/j k/});
    ok( $roles{ parent }->del_members( map { $_->primary_role } @users{qw/j k/}), "deleted members");
    ok( ! $roles{ parent }->has_members( map { $_->primary_role } @users{qw/j k/} ), "Memberships j and k deleted" );
    ok( ! $roles{ parent }->has_members( map { $_->primary_role } @users{qw/j/} ), "Membership j gone" );
    ok( ! $roles{ parent }->has_members( map { $_->primary_role } @users{qw/k/} ), "Membership k gone" );

    ok( $roles{ parent }->has_direct_member( $users{a}->primary_role ), "Direct member found" );
    ok(
        $roles{ parent }->has_direct_members(
            map { $_->primary_role } @users{qw/a b c/}
        ),
        "Direct members found"
    );

    ok(
        ! $roles{ parent }->has_direct_member( $users{d}->primary_role ),
        "not a direct member",
    );
    ok(
        $roles{ parent }->has_member( $users{d}->primary_role ),
        "is an indirect member",
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( ! $roles{ parent }->has_personnel( $users{k} ), "personnel not found" );
    ok( $roles{ parent }->add_personnel( $users{k} ), "Added personnel" );
    ok( $roles{ parent }->add_personnel( $users{k} ), "Adding personnel again has no error" );
    ok( $roles{ parent }->has_personnel( $users{k} ), "personnel found now" );
    ok( $roles{ parent }->del_personnel( $users{k} ), "del personnel" );
    ok( ! $roles{ parent }->has_personnel( $users{k} ), "personnel not found" );

    ok( $roles{ parent }->has_personnel( $users{f} ), "personnel found from descended" );
    ok( ! $roles{ parent }->del_personnel( $users{f} ), "personnel is not a direct member" );
    ok( ! $roles{ parent }->has_personnel( $users{k} ), "personnel still found (descended)" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    my %clients = map {
        my $c = eleMentalClinic::Client->new({
            fname => $_,
            lname => $_,
            mname => $_,
        });
        $c->save;
        $_ => $c
    } 'a' .. 'k';

    ok( ! $roles{ child }->has_client_permission( $clients{a} ), "Currently no client permissions" );
    ok( my $perm = $roles{ child }->grant_client_permission( $clients{a} ), "Granted client permission" );
    ok( $roles{ child }->has_direct_client_permission( $clients{a} ), "Found client permission" );
    ok( $roles{ child }->has_client_permission( $clients{a} ), "Found client permission" );

    ok( ! $roles{ subchild }->has_direct_client_permission( $clients{a} ), "subchild has no direct" );
    ok( $roles{ subchild }->has_client_permission( $clients{a} ), "subchild does inherit" );

    ok( ! $roles{ parent }->has_direct_client_permission( $clients{a} ), "parent has no direct" );
    ok( ! $roles{ parent }->has_client_permission( $clients{a} ), "parent does not inherit" );

    delete $perm->{ rec_id };
    is_deeply(
        $roles{ child }->all_client_permissions,
        [ $perm ],
        "Found the permission"
    );

    is_deeply(
        $roles{ subchild }->all_client_permissions,
        [ { %$perm, role_id => $roles{ subchild }->id }],
        "Found the permission"
    );

    is_deeply(
        $roles{ parent }->all_client_permissions || undef,
        undef,
        "Found no permission"
    );

    ok( my $perms = $roles{ child }->grant_client_permissions( @clients{'b' .. 'd'} ), "Grant multiple permissions" );
    is( @$perms, 3, "granted 3 permissions" );

    ok( $roles{ child }->has_direct_client_permissions( @clients{'a' .. 'd'} ), "Found client permission" );
    ok( $roles{ child }->has_client_permissions( @clients{'a' .. 'd'} ), "Found client permission" );

    ok( ! $roles{ subchild }->has_direct_client_permissions( @clients{'a' .. 'd'} ), "subchild has no direct" );
    ok( $roles{ subchild }->has_client_permissions( @clients{'a' .. 'd'} ), "subchild does inherit" );

    ok( ! $roles{ parent }->has_direct_client_permissions( @clients{'b' .. 'd'} ), "parent has no direct" );
    ok( ! $roles{ parent }->has_client_permissions( @clients{'b' .. 'd'} ), "parent does not inherit" );

    ok( ! $roles{ subchild }->revoke_client_permission( $clients{a} ), "Cannot remove indirect permission" );
    ok( $roles{ child }->has_client_permission( $clients{a} ), "Found client permission" );
    ok( $roles{ subchild }->has_client_permission( $clients{a} ), "Found client permission" );

    ok( $roles{ child }->revoke_client_permission( $clients{a} ), "Can remove direct permission" );
    ok( ! $roles{ child }->has_client_permission( $clients{a} ), "removed client permission" );
    ok( ! $roles{ subchild }->has_client_permission( $clients{a} ), "removed client permission" );

    ok( $roles{ child }->revoke_client_permissions( @clients{'b' .. 'c'} ), "Can remove direct permissions" );
    ok( ! $roles{ child }->has_direct_client_permissions( @clients{'a' .. 'c'} ), "client permission revoked" );
    ok( ! $roles{ child }->has_client_permissions( @clients{'a' .. 'c'} ), "client permission revoked" );
    ok( ! $roles{ subchild }->has_direct_client_permissions( @clients{'a' .. 'c'} ), "subchild has no direct" );
    ok( ! $roles{ subchild }->has_client_permissions( @clients{'a' .. 'c'} ), "perms revoked" );
    ok( $roles{ child }->has_client_permission( $clients{d} ), "Found client permission" );
    ok( $roles{ subchild }->has_client_permission( $clients{d} ), "Found client permission" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Unique client-staff associations
    my $events = {( map { $_->client_id => $_ }
        @{ eleMentalClinic::Client::Placement::Event->get_by_( staff_id => 1001 )})};
    $events = [ values %$events ];

    is( $_->staff_id, 1001, "Correct staff_id" ) for @$events;
    is( @$events, 4, "Correct event count" );

    my $role = $CLASS->get_one_by_( staff_id => 1001 );

    $all_clients->del_member( $role );
    $CLASS->admin_role->del_member( $role );
    $role->revoke_client_permissions( $_->client_id )
        for @$events;
    ok( !$role->has_direct_client_permissions( $_->client_id ), "no direct on client")
        for @$events;
    ok( $role->has_client_permission( $_->client_id ), "can access the client")
        for @$events;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    my $q = sub { $CLASS->get_one_by_( staff_id => shift( @_ ))};

    #{{{ Added to fix bug where tests passes on its own, bu not in suite.
    my $remove = {
        1000 => [ 1001, 1002, 1004, 1005 ],
        1001 => [ 1003 ],
        1002 => [ 1001, 1002, 1004, 1005 ],
        1003 => [ 1001, 1002, 1003, 1004, 1005 ],
    };

    while( my ( $staff, $clients ) = each %$remove ) {
        for my $client ( @$clients ) {
            eleMentalClinic::DB->new->do_sql(
                'DELETE FROM client_placement_event WHERE staff_id = ? and client_id = ?',
                1,
                $staff, $client
            );
        }
    }
    #}}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->new({ name => 'test', system_role => 1 });
    $one->save;

    ok( $tmp = $one->grant_group_permission( 1001 ), "Grant group rights");
    isa_ok( $tmp, 'eleMentalClinic::Role::DirectGroupPermission' );

    my $pre = $one->all_group_permissions;
    ok( $tmp = $one->grant_group_permissions( 1001, 1002 ), "Grant group rights");
    isa_ok( $tmp->[0], 'eleMentalClinic::Role::DirectGroupPermission' );
    isa_ok( $tmp->[1], 'eleMentalClinic::Role::DirectGroupPermission' );

    is_deeply(
        [
            map { delete $_->{ rec_id }; delete $_->{ cause } unless $_->{ cause }; $_ }
                sort { $a->group_id <=> $b->group_id }
                    @{ $one->all_group_permissions }
        ],
        [ map { delete $_->{ rec_id }; $_ } sort { $a->group_id <=> $b->group_id } @$tmp ],
        "Correct group permissions"
    );

    $CLASS->admin_role->add_member( $one );
    $perm = $CLASS->admin_role->grant_group_permission( 1003 );

    ok( $one->has_group_permission( 1001 ), "Permissions directly" );
    ok( $one->has_group_permission( 1003 ), "Permissions indirectly" );
    ok( $one->has_group_permissions( 1001 .. 1003 ), "Permissions" );

    ok( $one->has_direct_group_permission( 1001 ), "Permissions directly" );
    ok( !$one->has_direct_group_permission( 1003 ), "No permissions directly" );
    ok( $one->has_direct_group_permissions( 1001, 1002 ), "Permissions directly" );

    $CLASS->admin_role->del_member( $one );
    $perm = $CLASS->admin_role->revoke_group_permission( 1003 );
    $one->revoke_group_permission( 1002 );
    ok( !$one->has_group_permission( 1002 ), "Permission revoked" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    #Client 1001 is part of group 1001
    ok( $one->has_client_permission( 1001 ), "Client permission by group" );
    ok( $one->has_client_permissions( 1001 ), "Client permission by group" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one->revoke_group_permission( 1001 );
    ok( !$one->has_client_permission( 1001 ), "No more client permission by group" );

    my $reports = $CLASS->get_one_by_( name => 'reports' );
    $reports->add_member( $one );

    my $admin = $CLASS->admin_role;
    $admin->add_member( $one );
    $reports->add_member( $admin );

dbinit( 0 );
