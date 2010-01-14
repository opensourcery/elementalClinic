# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
package eleMentalClinic::Controller::Base::Groups;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Groups

=head1 SYNOPSIS

Base Groups Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI::GroupCGI /;
use Data::Dumper;
use eleMentalClinic::Group;
use eleMentalClinic::Group::Attendee;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/3366', 'gateway', 'groups', 'active_groups', 'group_members' ],
        script => 'groups.cgi',
        javascripts  => [ 'client_filter.js' ],
    });
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias => 'View',
        },
        group_edit => {
            -alias => 'Edit Group',
        },
        group_save => {
            -alias => 'Save Group',
            name => [ 'Group name', 'required', 'text', 'length(0,255)' ],
            description     => [ 'Group description' ],
            default_note    => [ 'Default note' ],
        },
        group_create => {
            -alias => 'New Group',
        },
        grant_access => {
            -alias => 'Grant Access',
        },
        revoke_access => {
        },
        members_edit => {
            -alias => [ 'Edit Membership' ],
        },
        member_add => {
            -alias => [ 'Add Members' ],
            new_member_id => [ 'Client', 'required', 'number::integer' ],
        },
        member_remove => {
            -alias => [ 'Remove Members' ],
            member_id => [ 'Member', 'required', 'number::integer' ],
        },
        group_status => {
            -alias => [ 'Apply Status Changes' ],
            group_active => [ 'Group active toggle', 'checkbox::boolean' ],
        },
        caseload_pref => {},
        client_history => {
            -alias => 'client_group_detail',
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my ( $group, $op ) = @_;

    $group ||= $self->get_group;
    $op ||= 'display';

    $self->override_template_name( 'home' );

    return {
        op => $op,
        groups  => $self->get_groups,
        current => $group,
        group_filter => $self->group_filter,
        personnel => $self->personnel( $group ),
        unassociated => $self->unassociated( $group ),
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub grant_access {
    my $self = shift;
    my $group = $self->get_group;
    my $staff_id = $self->param( 'staff_id' );
    if ( $group and $staff_id ) {
        my $personnel = eleMentalClinic::Personnel->retrieve( $staff_id );
        $personnel->primary_role->grant_group_permission( $group );
    }
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub revoke_access {
    my $self = shift;
    my $group = $self->get_group;
    my $staff_id = $self->param( 'staff_id' );
    print STDERR Dumper( $staff_id, $group->id );
    if ( $group and $staff_id ) {
        my $personnel = eleMentalClinic::Personnel->retrieve( $staff_id );
        $personnel->primary_role->revoke_group_permission( $group );
    }
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub personnel {
    my $self = shift;
    my ( $group ) = @_;
    return [] unless $group and $group->id;
    my $set = eleMentalClinic::Role::GroupPermission->get_by_( group_id => $group->id, 'cause', 'DESC' );
    return unless $set and @$set;
    my $out = {};
    for my $item ( @$set ) {
        next unless $item->role->staff_id;
        next if $item->cause && $item->get_cause->direct_cause; #Don't want this depth.
        push @{ $out->{ $item->role->staff_id }}, $item;
    }
    return $out;
}

sub unassociated {
    my $self = shift;
    my ( $group ) = @_;
    return [] unless $group and $group->id;
    return [
        grep { !$_->primary_role->has_direct_group_permission( $group )}
            @{ eleMentalClinic::Personnel->get_all }
    ]
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_edit {
    my $self = shift;
    return $self->home( undef, 'group_edit' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_create {
    my $self = shift;
    return $self->home( undef, 'group_create' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_save {
    my $self = shift;

    my $group = eleMentalClinic::Group->new({ $self->Vars });
    $group->rec_id( $self->param( 'group_id' ));
    $self->add_error( 'name', 'name',
        'The name <strong>'. $self->param( 'name' ) .'</strong>'
        .' already exists; please name your group something else.' )
        if not $group->id and $group->name_exists;

    unless ( $self->errors ) {
        $group->save;
        $self->current_user->primary_role->grant_group_permission( $group );
    }

    return $self->home( $group, 'group_save' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub members_edit {
    my $self = shift;
    my( $group ) = @_;

    $group ||= $self->get_group;
    return $self->home
        unless $group;
    $self->template->process_page( 'groups/members', {
        current => $group,
        clients => $self->current_user->filter_clients,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub member_add {
    my $self = shift;

    my $group = $self->get_group;
    unless( $self->errors ) {
        my @new_members = ref $self->param( 'new_member_id' )
            ? @{ $self->param( 'new_member_id' )}
            : $self->param( 'new_member_id' );
        $group->add_member( $_ )
            for @new_members;
    }
    $self->members_edit( $group );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub member_remove {
    my $self = shift;

    my $group = $self->get_group;
    unless( $self->errors ) {
        my @members = ref $self->param( 'member_id' )
            ? @{ $self->param( 'member_id' )}
            : $self->param( 'member_id' );
        $group->remove_member( $_ )
            for @members;
    }
    $self->members_edit( $group );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub caseload_pref {
    my $self = shift;

    $self->current_user->pref->client_list_filter( $self->param( 'client_list_filter' ));
    $self->current_user->pref->save;
    $self->members_edit;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_history {
    my $self = shift;

    my $group = eleMentalClinic::Group->new;
    my $groups = $group->get_byclient(
        $self->param( 'client_id' ),
        $group->show_from_str( $self->group_filter ),
    );

    $self->template->vars({ styles => [ 'layout/3366', 'active_groups' ] });
    $self->template->process_page( 'groups/client_notes', {
        group_filter => $self->group_filter,
        groups      => $groups, 
        group       => $self->get_group || 0, #the || 0 fixes the 'odd number of elements' message.
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_groups {
    my $self = shift;
    my ( $group_filter ) = @_;
    $group_filter ||= $self->group_filter;
    my $out;

    if ( $self->showing_all_groups ) {
        $out = eleMentalClinic::Group->new->get_all;
    }
    else {
        $out = eleMentalClinic::Group->new->get_by_( 
            'active',  
            $self->showing_active_groups, #will be 0 if false, 1 if true, thusly filter is applied. 
            'name',
            'ASC',
        );
    }

    $out = [ grep { $self->current_user->primary_role->has_group_permission( $_ )} @$out ]
        if $out and @$out;

    # {} is legacy....
    return $out || {};
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_status {
    my $self = shift;

    return unless my $id = $self->param( 'group_id' );
    
    my $group = eleMentalClinic::Group->new({ rec_id => $id })->retrieve;
    $group->active( $self->param( 'group_active' ) );
    $group->save;

    #Unless we are already viewing all groups, we want the filter to follow the current group
    #that way it remains on our visible list, and selected. ticket #708
    unless ( $self->showing_all_groups ) {
        $self->param( 'group_active' )
            ? $self->group_filter( 'active' ) 
            : $self->group_filter( 'inactive' );
    }
    return $self->home;
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2007 OpenSourcery, LLC

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
