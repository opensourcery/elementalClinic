package eleMentalClinic::Group;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Group

=head1 SYNOPSIS

Group of clients who meet and share a common progress note.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::Group::Member;
use eleMentalClinic::Group::Note;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'groups' }
    sub fields { [ qw/
        rec_id name description active default_note
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_all {
    my $self = shift;

    $self->db->select_many(
        $self->fields,
        $self->table,
        '',
        "ORDER BY name"
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my $self = shift;
    return unless my $results = $self->list_all( @_ );

    my $class = ref $self;
    my @results;
    push @results => $class->new( $_ ) for @$results;
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_members()

Object method.

Returns a list of clients who are members of this group ordered by name.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_members {
    my $self = shift;
    return unless $self->id;
    eleMentalClinic::Group::Member->get_bygroup( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub add_member {
    my $self = shift;
    return unless my $group_id = $self->rec_id;
    my( $client_id ) = @_;

    $client_id = $client_id->id if ref $client_id eq 'eleMentalClinic::Client';
    return unless $client_id;

    return if eleMentalClinic::Group::Member->get_byclient_group( $client_id, $group_id );

    #TODO test the first half of the unless
    if( $self->get_notes
        and not $self->get_notes->[0]->note_committed ){
        eleMentalClinic::Group::Attendee->new({
            client_id     => $client_id,
            group_note_id => $self->get_notes->[0]->id,
            action        => 'group_note',
        })->save;
    }
    eleMentalClinic::Group::Member->new({
        client_id => $client_id,
        group_id  => $group_id,
        active    => 1,          #FIXME this is stupid
    })->save;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub remove_member {
    my $self = shift;
    return unless my $group_id = $self->rec_id;
    my( $client_id ) = @_;

    $client_id = $client_id->id if ref $client_id eq 'eleMentalClinic::Client';
    return unless $client_id;

    return unless my $member = eleMentalClinic::Group::Member->get_byclient_group( $client_id, $group_id );

    $member->remove;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_notes {
    my $self = shift;
    return unless my $group_id = $self->rec_id;

    eleMentalClinic::Group::Note->get_bygroup( $group_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    return if not $self->id and $self->name_exists;

    $self->active( 1 )
        unless defined $self->active;
    $self->SUPER::save;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns true if incoming name already exists in database
# FIXME should be better about case, spaces, etc
sub name_exists {
    my $self = shift;
    my( $name ) = @_;

    $name ||= $self->name;
    $self->db->select_one( # name already exists
        [ qw/ rec_id /],
        'groups',
        'name = '. $self->db->dbh->quote( $name ),
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_bygroupnote {
    my $class = shift;
    my( $group_note_id ) = @_;
    return unless $group_note_id;

    my $table = $class->table;
    return unless my $group = $class->db->select_one(
        [ "$table.*" ],
        "$table, group_notes",
        qq/
            $table.rec_id = group_notes.group_id
            AND group_notes.rec_id = $group_note_id
        /
    );
    return $class->new( $group );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# group_status should be 0 for inactive, 1 for active, without group status it
# should give all groups
# TODO
# chain should be:
#   group->get_history( client_id )
#       group_note->get_history
#           attendee->get_history
# or something like this
sub get_byclient {
    my $class = shift;
    my( $client_id, $group_status ) = @_;
    return unless $client_id;
    
    my $query = qq/ 
        SELECT groups.*
        FROM   groups
        WHERE   rec_id IN (
            SELECT  group_id
            FROM    group_attendance, group_notes
            WHERE   group_attendance.group_note_id = group_notes.rec_id
                AND client_id = $client_id
            UNION ALL
            SELECT  group_id
            FROM    GROUP_MEMBERS
            WHERE   CLIENT_ID = $client_id
        )/;

        $query .= "AND active = " . $class->db->dbh->quote( $group_status ) 
        if defined $group_status;
        

    return unless my $groups = $class->db->do_sql( $query );

    my @groups;
    push @groups, $class->new( $_ ) for @$groups;
    return unless $groups[0];
    return \@groups;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This function takes the group_filter param string and converts it
# to the correct value to pass to the get_groups_byclient function
sub show_from_str {
    my $self = shift;
    my ( $str ) = @_;

    if ( $str ) {
        return undef if $str eq 'all'; #undef means show all
        return '0' if $str eq 'inactive'; #0 is inactive
    }

    return 1; #Default is to return active (1)
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

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
