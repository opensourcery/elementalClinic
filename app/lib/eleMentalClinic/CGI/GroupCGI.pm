package eleMentalClinic::CGI::GroupCGI;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::CGI::GroupCGI

=head1 DESCRIPTION

Functions required by both controllers used for active or inactive groups
There are 2 controllers (Groups and GroupNotes) that need these functions
this is where they inherit them from.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 group_filter()

Object method.

This is called when the controller needs to know which type of groups
it should show, active, inactive, or all.

The function will return the current setting from the user preferences.

If the group_filter CGI param is set then it will be set in the user 
preferences first. This ensures a users preference will be saved both
in the current session, and across sessions.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub group_filter {
    my $self = shift;
    my ( $filter ) = @_;
    $filter ||= $self->param( 'group_filter' );

    #If there is no filter change then we can skip this logic and go right
    #to the return.
    if ( $filter ) {
        #make sure the filter provided is valid, otherwise use default.
        $filter = $self->validate_group_filter( $filter ); 
        $self->current_user->pref->group_filter( $filter );
        $self->current_user->pref->save;
    }

    return $self->current_user->pref->group_filter || 'active';
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This function was implimented in both the groups and groupnotes controllers
# Each was slightly different but did exactly the same thing, moved it here.
sub get_group {
    my $self = shift;
    my( $group_id ) = @_;

    $group_id ||= $self->param( 'group_id' );
    return unless $group_id and $self->in_group_filter( $group_id );

    eleMentalClinic::Group->new({ rec_id => $group_id })->retrieve;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 subroutine()

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub validate_group_filter {
    my $self = shift;
    my ( $filter ) = @_;
    return $filter if ( $filter and $filter =~ /^(in)?active$/ ); #active and inactive are both ok
    return 'all'; #Return all as default.
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 in_group_filter()

Object method.

This method will check if the group ID specified is in the current active/inactive filter
If the ID is filtered out this method will return false;
If the ID is not filtered out this method will return true by returning the group ID

Example usage:
    $group = 1001;
    $group = in_group_filter( $group );
If the ID in $group is in the filter then it will be saved, otherwise it will be cleared.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub in_group_filter {
    my $self = shift;
    my ( $group_id ) = @_;

    return unless ( $group_id );

    #If the filter is 'All' then all groups should pass.
    return $group_id if ( $self->showing_all_groups );

    #IF the group is active status should be 1, if false status should be numerical 0
    #this makes for an easy comparison against showing_active_groups which returns a 0 or 1
    my $status = eleMentalClinic::Group->new->retrieve( $group_id )->active;

    #Simple numerical comparison
    return $group_id if ( $status == $self->showing_active_groups );

    return;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 showing_active_groups()

Object method.

Returns 1 (true) if the current filter shows active groups
Returns 0 (false) if the current filter does not show active groups

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub showing_active_groups {
    my $self = shift;
    
    return 1 if ( $self->group_filter eq 'all' );
    return 1 if ( $self->group_filter eq 'active' );
    return 0;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 showing_inactive_groups()

Object method.

Returns 1 (true) if the current filter shows inactive groups
Returns 0 (false) if the current filter does not show inactive groups

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub showing_inactive_groups {
    my $self = shift;
    
    return 1 if ( $self->group_filter eq 'all' );
    return 1 if ( $self->group_filter eq 'inactive' );
    return 0;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 showing_all_groups()

Object method.

Returns 1 (true) if the current filter shows all groups
Returns 0 (false) if the current filter does not show all groups

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub showing_all_groups {
    my $self = shift;
    
    return 1 if ( $self->group_filter eq 'all' );
    return 0;
}


'eleMental';

__END__

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
