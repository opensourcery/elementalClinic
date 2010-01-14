# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Role;
use strict;
use warnings;
use eleMentalClinic::Util;
use eleMentalClinic::Personnel;
use eleMentalClinic::Role::Access;
use eleMentalClinic::Role::Member;
use eleMentalClinic::Role::DirectMember;
use eleMentalClinic::Role::ActualMember;
use eleMentalClinic::Role::ClientPermission;
use eleMentalClinic::Role::DirectClientPermission;
use eleMentalClinic::Role::GroupPermission;
use eleMentalClinic::Role::DirectGroupPermission;
use Data::Dumper;

use base qw/ eleMentalClinic::DB::Object /;

=head1 NAME

eleMentalClinic::Role

=head1 DESCRIPTION

Roles are essentially groups that clinicians are associated with. There are
system roles and clinician roles. Roles can be members of other roles.

=head1 METHODS

=over 4

=cut

sub table  { 'personnel_role' }
sub fields { [ qw/ rec_id name staff_id system_role has_homepage special_name / ] }
sub primary_key { 'rec_id' }

#{{{ Special role logic

=item $role = all_clients_role()

retrieve the 'all clients' special role

=item $role = all_groups_role()

retrieve the 'all groups' special role

=item $role = admin_role()

retrieve the 'admin' special role

=cut

sub all_clients_role { shift->special_role( 'all_clients' )}
sub all_groups_role { shift->special_role( 'all_groups' )}
sub admin_role { shift->special_role( 'admin' )}
sub limited_all_access_names { qw/financial reports/ }
sub limited_all_access_roles { return [
    map { __PACKAGE__->get_one_by_( name => $_ )}
        (limited_all_access_names())
]}

=item $role = special_role( $special_name )

Retrieve a special role by name.

=cut

sub special_role {
    my $self = shift;
    my $class = ref $self || $self;
    my ( $special ) = @_;
    return $class->get_one_by_( special_name => $special );
}

#}}}

sub accessors_retrieve_many {
    {
        all_members => { role_id   => 'eleMentalClinic::Role::Member' },
        all_parents => { member_id => 'eleMentalClinic::Role::Member' },
        all_clients => { role_id   => 'eleMentalClinic::Role::ClientPermission' },
        all_groups  => { role_id   => 'eleMentalClinic::Role::GroupPermission' },
        all_access  => { role_id   => 'eleMentalClinic::Role::Access' },

        direct_members => { role_id   => 'eleMentalClinic::Role::DirectMember' },
        direct_parents => { member_id => 'eleMentalClinic::Role::DirectMember' },
        direct_clients => { role_id   => 'eleMentalClinic::Role::DirectClientPermission' },
        direct_groups  => { role_id   => 'eleMentalClinic::Role::DirectGroupPermission' },
    };
}

#{{{ Membership related methods

=item direct_members()

Returns an arrayref of eleMentalClinic::Role::Member objects where this role is the
parent role.

=item direct_parents()

Returns an arrayref of eleMentalClinic::Role::Member objects where this role is the
member role.

=item all_members()

Returns an arrayref with all the member objects that effect this role. This
includes direct members, as well as members of members.

=item all_parents()

Returns an arrayref with all the member objects that are parents of this role. This
includes direct parents, as well as parents of parents.

=item $member = add_member( $role )

Make the specified role a member of this one.

=cut

sub add_member {
    my $self = shift;
    my ( $member ) = @_;
    $member = $member->id if ref $member;

    my $membership = $self->has_direct_member( $member );
    return $membership if $membership;

    eleMentalClinic::Role::ActualMember->new({
        role_id => $self->id,
        member_id => $member,
    })->save;

    return $self->has_direct_member( $member );
}

=item $members = add_members( $role1, $role2, ... )

Add multiple roles as members.

=cut

sub add_members {
    my $self = shift;
    return [ map { $self->add_member( $_ ) } @_ ];
}

=item del_member( $role )

Remove any direct memberships where the spefied role is a member of this one.

NOTE: Will not remove an indirect membership where the specified role is a
member of another member.

=cut

sub del_member {
    my $self = shift;

    my $membership = $self->has_direct_member( @_ );
    return unless $membership and $membership->id;

    $membership->delete();
}

=item del_members( $role1, $role2, ... )

Remove multiple direct members.

NOTE: Will not remove an indirect membership where the specified role is a
member of another member.

=cut

sub del_members {
    my $self = shift;
    return [ map { $self->del_member( $_ )} @_ ];
}

=item has_direct_member( $role )

Returns the eleMentalClinic::Role::Member object if the role is a direct member
of this one. Returns undef when the specified role is not a direct member.

=cut

sub has_direct_member {
    my $self = shift;
    my ( $member ) = @_;
    unless( ref $member ){
        $member = $member =~ m/^\d+$/ ? eleMentalClinic::Role->retrieve( $member )
                                      : eleMentalClinic::Role->get_one_by_( 'name', $member );
    }

    my $membership = eleMentalClinic::Role::DirectMember->get_one_where(
        'WHERE member_id = ' . dbquote( $member->id ) . ' AND role_id = ' . dbquote( $self->id )
    );

    return unless $membership and $membership->role_id;
    return $membership;
}

=item has_direct_members( $role1, $role2, ... )

Returns true if all the specified roles are direct members of this one.

=cut

sub has_direct_members {
    my $self = shift;
    my @list = @_;
    my @yes = map { $self->has_direct_member( @_ ) } @list;
    return if grep { !$_ } @yes;
    return @list == @yes;
}

=item has_member( $role )

Returns true if the specified role is either a direct or indirect member of
this role.

=cut

sub has_member {
    my $self = shift;
    my ( $member ) = @_;
    unless( ref $member ){
        $member = $member =~ m/^\d+$/ ? eleMentalClinic::Role->retrieve( $member )
                                      : eleMentalClinic::Role->get_one_by_( 'name', $member );
    }

    my $membership = eleMentalClinic::Role::Member->get_one_where(
        'WHERE member_id = ' . dbquote( $member->id ) . ' AND role_id = ' . dbquote( $self->id )
    );

    return unless $membership and $membership->role_id;
    return $membership;
}

=item has_members( $role1, $role2, ... )

Returns true if the specified roles are all either direct or indirect members of
this role.

=cut

sub has_members {
    my $self = shift;
    my @list = @_;
    my @yes = map { $self->has_member( @_ ) } @list;
    return if grep { !$_ } @yes;
    return @list == @yes;
}

#}}}

#{{{ Personnel related methods

=item $personnel = direct_personnel()

Returns the eleMentalClinic::Personnel associated with this role. If the role
is a system role this will return undef.

=cut

# Cannot use accessors_retrieve_one for this because staff_id is undef for
# system roles. It causes an error.
sub direct_personnel {
    my $self = shift;
    return unless $self->staff_id;
    return eleMentalClinic::Personnel->retrieve( $self->staff_id );
}

=item $list = all_personnel()

Returns an arrayref of all eleMentalClinic::Personnel that are direct or
inderectly part of this role.

=cut

sub all_personnel {
    my $self = shift;
    my $members = $self->all_members;

    my @roles = ( $self, map { $_->member } @$members );
    my %personnel = map { $_->id => $_ } grep { $_ } map { $_->direct_personnel } @roles;

    return [ values %personnel ];
}

=item has_personnel( $personnel1, $personnel2, ... )

Returns true if all the personnel are directly or indirectly part of this role.

Arguments must all be eleMentalClinic::Personnel objects or their id's.

=cut

sub has_personnel {
    my $self = shift;
    my @personnel = @_;
    my $list = $self->all_personnel;
    return unless $list;
    return $self->_has_(
        $list,
        \@personnel,
        'staff_id',
    );
}

=item add_personnel( $personnel1, $personnel2_id, ... )

Add the specified personnel to this role. Arguments may be personnel objects or
id's.

=cut

sub add_personnel {
    my $self = shift;
    $self->_do_personnel( 'add_member', @_ );
}

=item del_personnel( $personnel1, $personnel2_id, ... )

Remove the specified personnel from this role. Arguments may be personnel objects or
id's.

NOTE: Only removes direct roles, not personnel roles that are members of members.

=cut

sub del_personnel {
    my $self = shift;
    $self->_do_personnel( 'del_member', @_ );
}

#}}}

#{{{ client permission related methods

=item all_client_permissions()

Returns an arrayref of all the client permissions in this role and parent
roles.

Note: Does not include service coordinator permissions

=cut

*all_client_permissions = \&all_clients;
*direct_client_permissions = \&direct_clients;

=item has_client_permission( $client )

Returns true if this role has direct or inderect permissions with the specified
client.

Argument may be eleMentalClinic::Client object or ID.

=cut

sub has_client_permission {
    my $self = shift;
    my ( $client ) = @_;
    my $client_id = ref $client ? $client->id : $client;

    my $perm = eleMentalClinic::Role::ClientPermission->get_one_where(
        'WHERE client_id = ' . dbquote( $client_id ) . ' AND role_id = ' . dbquote( $self->id )
    );

    return $perm if $perm and $perm->role_id;
}

=item has_client_permissions( $client1, $client2_id, ... )

Returns true if this role has direct or indirect permissions with all the
specified clients.

Arguments may be eleMentalClinic::Client object or ID.

=cut

sub has_client_permissions {
    my $self = shift;
    my @list = @_;
    my @yes = map { $self->has_client_permission( @_ ) } @list;
    return if grep { !$_ } @yes;
    return @list == @yes;
}

=item has_direct_client_permission( $client )

Returns true if this role has direct permissions with the specified client.

Argument may be eleMentalClinic::Client object or ID.

=cut

sub has_direct_client_permission {
    my $self = shift;
    my ( $client ) = @_;
    my $id = ref $client ? $client->id : $client;

    my $perm = eleMentalClinic::Role::DirectClientPermission->get_one_where(
        'WHERE role_id = ' . dbquote( $self->id ) . ' AND client_id = ' . dbquote( $id )
    );
    return $perm if $perm and $perm->id;
}

=item has_client_permissions( $client1, $client2_id, ... )

Returns true if this role has direct permissions with all the specified
clients.

Arguments may be eleMentalClinic::Client object or ID.

=cut

sub has_direct_client_permissions {
    my $self = shift;
    my @list = @_;
    my @yes = map { $self->has_direct_client_permission( $_ ) } @list;
    return if grep { !$_ } @yes;
    return @list == @yes;
}

=item grant_client_permission( $client )

Grant this role permissions on the specified client.

Arguemnt may be client object or id.

=cut

sub grant_client_permission {
    my $self = shift;
    my ( $client ) = @_;
    my $id = ref $client ? $client->id : $client;

    my $perm = $self->has_direct_client_permission( $client );
    return $perm if $perm and $perm->id;

    eleMentalClinic::Role::DirectClientPermission->new({
        role_id => $self->id,
        client_id => $id,
    })->save;

    return $self->has_direct_client_permission( $client );
}

=item grant_client_permissions( $client1, $client2_id )

Grant this role permissions on the specified clients.

Arguemnts may be client objects or ids.

=cut

sub grant_client_permissions {
    my $self = shift;
    return [ map { $self->grant_client_permission( $_ ) } @_ ];
}

=item revoke_client_permission( $client )

Revoke a direct client permission.

=cut

sub revoke_client_permission {
    my $self = shift;
    my ( $client ) = @_;

    my $perm = $self->has_direct_client_permission( $client );
    return unless $perm and $perm->id;
    return $perm->delete();
}

=item revoke_client_permissions( $client1, $client2_id )

Revoke the specified direct client permissions.

=cut

sub revoke_client_permissions {
    my $self = shift;
    return [ map { $self->revoke_client_permission( $_ ) } @_ ];
}

#}}}

#{{{ group permission related methods

=item all_group_permissions()

Returns an arrayref of all the group permissions in this role and parent
roles.

Note: Does not include service coordinator permissions

=cut

*all_group_permissions = \&all_groups;
*direct_group_permissions = \&direct_groups;

=item has_group_permission( $group )

Returns true if this role has direct or inderect permissions with the specified
group.

Argument may be eleMentalClinic::Group object or ID.

=cut

sub has_group_permission {
    my $self = shift;
    my ( $group ) = @_;
    my $group_id = ref $group ? $group->id : $group;

    my $perm = eleMentalClinic::Role::GroupPermission->get_one_where(
        'WHERE group_id = ' . dbquote( $group_id ) . ' AND role_id = ' . dbquote( $self->id )
    );

    return $perm if $perm and $perm->role_id;
}

=item has_group_permissions( $group1, $group2_id, ... )

Returns true if this role has direct or indirect permissions with all the
specified groups.

Arguments may be eleMentalClinic::Group object or ID.

=cut

sub has_group_permissions {
    my $self = shift;
    my @list = @_;
    my @yes = map { $self->has_group_permission( @_ ) } @list;
    return if grep { !$_ } @yes;
    return @list == @yes;
}

=item has_direct_group_permission( $group )

Returns true if this role has direct permissions with the specified group.

Argument may be eleMentalClinic::Group object or ID.

=cut

sub has_direct_group_permission {
    my $self = shift;
    my ( $group ) = @_;
    my $id = ref $group ? $group->id : $group;

    my $perm = eleMentalClinic::Role::DirectGroupPermission->get_one_where(
        'WHERE role_id = ' . dbquote( $self->id ) . ' AND group_id = ' . dbquote( $id )
    );
    return $perm if $perm and $perm->id;
}

=item has_direct_group_permissions( $group1, $group2_id, ... )

Returns true if this role has direct permissions with all the specified
groups.

Arguments may be eleMentalClinic::Group object or ID.

=cut

sub has_direct_group_permissions {
    my $self = shift;
    my @list = @_;
    my @yes = map { $self->has_direct_group_permission( @_ ) } @list;
    return if grep { !$_ } @yes;
    return @list == @yes;
}

=item grant_group_permission( $group )

Grant this role permissions on the specified group.

Arguemnt may be group object or id.

=cut

sub grant_group_permission {
    my $self = shift;
    my ( $group ) = @_;
    my $id = ref $group ? $group->id : $group;

    my $perm = $self->has_direct_group_permission( $group );
    return $perm if $perm and $perm->role_id;

    eleMentalClinic::Role::DirectGroupPermission->new({
        role_id => $self->id,
        group_id => $id,
    })->save;
    return $self->has_direct_group_permission( $group );
}

=item grant_group_permissions( $group1, $group2_id )

Grant this role permissions on the specified groups.

Arguemnts may be group objects or ids.

=cut

sub grant_group_permissions {
    my $self = shift;
    return [ map { $self->grant_group_permission( $_ ) } @_ ];
}

=item revoke_group_permission( $group )

Revoke a direct group permission.

=cut

sub revoke_group_permission {
    my $self = shift;
    my ( $group ) = @_;

    my $perm = $self->has_direct_group_permission( $group );
    return unless $perm and $perm->id;
    return $perm->delete();
}

=item revoke_group_permissions( $group1, $group2_id )

Revoke the specified direct group permissions.

=cut

sub revoke_group_permissions {
    my $self = shift;
    return [ map { $self->revoke_group_permission( $_ ) } @_ ];
}

#}}}

#{{{ Helper methods

=item _has_( $have, $want, $in_field )

$have should be an array of objects associated with this role.

$want should be an array of objects or id's we are checking for.

$in_field should be a method on the objects in $have that returns the id of the
objects we want.

Returns true if every object in $want is found in $in_field in the $have items.

This type of search is used often in eleMentalClinic::Role.

=cut

sub _has_ {
    my $self = shift;
    my ( $have, $want, $in_field ) = @_;
    #everything in @$want should be found in @$have->$in_field;

    # ID's for all the objects we 'want'.
    my @need = map { ref($_) ? $_->id : $_ } @$want;

    # Special map of field=>object for all the objects we 'have'
    my %got = map { $_->$in_field => $_ } @$have;

    # What needs do we got? :-)
    my @matches = grep { $got{ $_ }} @need;

    #If both lists are the same length we are good.
    return @matches == @need; 
}

=item _do_personnel( $method, $personnel1, $personnel2, ... )

$method should be 'add_member' or 'del_member'.

Add or remove the specified personnel to this role depending on $method.

Arguments may be personnel objects or ids.

=cut

sub _do_personnel {
    my $self = shift;
    my $method = shift;

    #Recursion - Handle several
    return [ map { $self->_do_personnel( $method, $_ )} @_ ] if @_ > 1;

    #Handle 1
    my ( $personnel ) = @_;
    return unless $personnel;

    $personnel = eleMentalClinic::Personnel->retrieve( $personnel ) unless ref $personnel;
    my $p_role = $personnel->primary_role;

    $self->$method( $p_role );
}

#}}}

'eleMental';

__END__

=back

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2009 OpenSourcery, LLC

This file is part of eleMental Clinic.

eleMental Clinic is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option) any
later version.

eleMental Clinic is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

eleMental Clinic is packaged with a copy of the GNU General Public License.
Please see docs/COPYING in this distribution.
