package eleMentalClinic::Group::Attendee;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Group::Attendee

=head1 SYNOPSIS

Join between client and group.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::Client;
use eleMentalClinic::Group::Note;
use eleMentalClinic::Group;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'group_attendance' }
    sub fields { [ qw/
        rec_id group_note_id client_id action prognote_id
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client {
    my $self = shift;
    return unless $self->client_id;

    my $client = eleMentalClinic::Client->new({ client_id => $self->client_id })->retrieve;
    return unless $client->id;
    return $client;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_bygroupnote {
    my $class = shift;
    my( $group_note_id, $action, $committed ) = @_;
    return unless $group_note_id;

    my $table = $class->table;
    my $where = qq/
            WHERE $table.group_note_id = $group_note_id
            AND $table.client_id = client.client_id
    /;
    $where .= "AND $table.action = '$action'" if $action;

    return unless my $attendees = $class->db->select_many(
        [ "$table.*" ],
        "$table, client",
        $where,
        'ORDER BY client.lname, client.fname'
    );

    my @attendees;
    if( defined $committed ){
        for( @$attendees ){
            my $attendee = $class->new( $_ );
            next unless my $prognote = $attendee->get_prognote;
            next unless $prognote->note_committed =~ m/$committed/;
            push @attendees, $attendee;
        }
    }
    else {
        push @attendees, $class->new( $_ ) for @$attendees;
    }
    return unless $attendees[0];
    return \@attendees;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_bygroup {
    my $class = shift;
    my( $group_id ) = @_;
    return unless $group_id;

    return unless my $notes = eleMentalClinic::Group::Note->get_bygroup( $group_id );
    return unless my $group_note_id = $notes->[0]->id;

    $class->get_bygroupnote( $group_note_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub remove {
    my $self = shift;
    return unless my $id = $self->id;
    my $return = $self->db->delete_one(
        $self->table,
        "rec_id = $id"
    );
    $return = undef if $return eq '0E0';
    return $return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_prognote {
    my $self = shift;
    return unless $self->prognote_id;

    my $prognote = eleMentalClinic::ProgressNote->new({ rec_id => $self->prognote_id })->retrieve;
    return unless $prognote->id;
    return $prognote;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_byprognote {
    my $class = shift;
    my( $prognote_id ) = @_;
    return unless $prognote_id;

    return unless my $attendee = $class->db->select_one(
        $class->fields,
        $class->table,
        "prognote_id = $prognote_id"
    );
    return $class->new( $attendee );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_byclient_group {
    my $class = shift;
    my( $client_id, $group_id ) = @_;
    return unless $client_id and $group_id;

    my $table = $class->table;
    return unless my $attendees = $class->db->select_many(
        [ "$table.*" ],
        "$table, group_notes",
        qq/
            WHERE client_id = $client_id
              AND $table.group_note_id = group_notes.rec_id
              AND group_notes.group_id = $group_id
              AND $table.action != 'none'
        /,
        'ORDER BY start_date DESC'
    );
    my @attendees;
    push @attendees, $class->new( $_ ) for( @$attendees );
    return \@attendees;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_group_note {
    my $self = shift;
    return unless $self->group_note_id;
    my $group_note = eleMentalClinic::Group::Note->new({
        rec_id => $self->group_note_id,
    })->retrieve;
    return unless $group_note->id;
    return $group_note;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_group {
    my $self = shift;
    return unless $self->group_note_id;
    return unless my $group_note = $self->get_group_note;
    $group_note->get_group;
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
