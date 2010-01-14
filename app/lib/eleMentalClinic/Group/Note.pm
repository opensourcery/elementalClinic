package eleMentalClinic::Group::Note;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Group::Note

=head1 SYNOPSIS

Progress note for a group.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base::Note /;
use eleMentalClinic::ProgressNote;
use eleMentalClinic::Group::Attendee;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'group_notes' }
    sub fields { [ qw/
        rec_id group_id staff_id start_date end_date note_body
        data_entry_id charge_code_id note_location_id
        note_committed outcome_rating
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    #this is a dirty hack
    # we should split the date munging crap out of prognote's
    # init and just call that method here
    eleMentalClinic::ProgressNote::init( $self, @_ );
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub get_uncommitted_by_writer {
    my $class = shift;

    my $list = $class->list_uncommitted_by_writer( @_ );
    return unless $list;

    my @gnotes = map { $class->retrieve( $_->{rec_id} ) } @$list;
    return unless @gnotes;

    my @notes = map { @{ $_->notes_for_attendees || [] }} @gnotes;
    return \@notes if @notes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    my( $actions ) = @_;
    return unless $actions;
    $self->note_committed( 0 );

    $self->SUPER::save;

    my $attendees = eleMentalClinic::Group::Attendee->get_bygroupnote( $self->id );
    # loop over attendees
    #   if client_id exists in hash
    #     if actions are different
    #       set action to action in hash and save
    #   else
    #     delete attendee
    #   delete hash entry
    #
    #   create new attendees for remaining hash entries
    my %temp_actions = %$actions;
    for( @$attendees ){
        my $action = $temp_actions{ $_->client_id };

        if( $action ){
            if( $action ne $_->action ){
                $_->action( $action );
                $_->save;
            }
        }
        else {
            $_->remove;
        }
        delete $temp_actions{ $_->client_id }
    }

    for( keys %temp_actions ){
        my $action = $temp_actions{ $_ };
        eleMentalClinic::Group::Attendee->new({
            client_id     => $_,
            action        => $action,
            group_note_id => $self->id,
        })->save;
    }
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub notes_for_attendees {
    my $self = shift;
    return unless $self->id and $self->group_id and $self->staff_id;

    my $writer = eleMentalClinic::Personnel->new({ staff_id => $self->staff_id })->retrieve->name;
    my $attendees = eleMentalClinic::Group::Attendee->get_bygroupnote( $self->id );

    my @prognotes;
    for( @$attendees ){
        unless( $_->action =~ m/none/ ){
            my $goal_id = 0;
            my $commit = 0;
            my $note_body = $self->note_body;
            my $charge_code_id = $self->charge_code_id;

            if( $_->action =~ m/no_show/ ){
                $commit = 1;
                $note_body = 'No show.';
                $charge_code_id = eleMentalClinic::ValidData->new({
                    dept_id => 1001
                })->get_byname( '_charge_code', 'No Show' )->{ rec_id };
            }
            my $prognote = eleMentalClinic::ProgressNote->new({
                client_id        => $_->client_id,
                staff_id         => $self->staff_id,
                goal_id          => $goal_id,
                start_date       => $self->start_date,
                end_date         => $self->end_date,
                note_body        => $note_body,
                writer           => $writer,
                data_entry_id    => $self->data_entry_id,
                charge_code_id   => $charge_code_id,
                note_location_id => $self->note_location_id,
                note_committed   => $commit,
                group_id         => $self->group_id,
                outcome_rating   => $self->outcome_rating,
            });
            push @prognotes, $prognote;
        }
    }
    return \@prognotes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub commit {
    my $self = shift;
    return unless $self->id and $self->group_id and
        $self->staff_id and $self->start_date and $self->end_date;

    my $attendees = eleMentalClinic::Group::Attendee->get_bygroupnote( $self->id );
    my $prognotes = $self->notes_for_attendees || [];

    for my $attendee ( @$attendees ) {
        my @attendee_notes = grep { $_->client_id == $attendee->client_id } @$prognotes;
        for my $note ( @attendee_notes ) {
            next unless $note;
            $note->save;
            $attendee->prognote_id( $note->id )->save;
        }
    }

    $self->note_committed( 1 )->SUPER::save;
    return $prognotes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_bygroup {
    my $class = shift;
    my( $group_id ) = @_;
    return unless $group_id;

    return unless my $notes = $class->db->select_many(
        $class->fields,
        $class->table,
        "WHERE group_id = $group_id",
        'ORDER BY start_date DESC, note_committed'
    );

    my @notes;
    push @notes, $class->new( $_ ) for @$notes;
    return \@notes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_attendees {
    my $self = shift;
    my( $action, $committed ) = @_;
    return unless $self->id;

    eleMentalClinic::Group::Attendee->get_bygroupnote( $self->id, $action, $committed );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# accepts minutes
# returns 1 on success, 0 on failure, undef on error
sub note_duration_ok {
    my $self = shift;
    my( $min, $max ) = @_;
    
    my $prognote = eleMentalClinic::ProgressNote->new({
        start_date       => $self->start_date,
        end_date         => $self->end_date,
    });

    $prognote->note_duration_ok( $min, $max );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub note_date {
    my $self = shift;
    return unless $self->start_date;
    eleMentalClinic::ProgressNote::note_date( $self );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub start_time {
    my $self = shift;
    return unless $self->start_date;
    eleMentalClinic::ProgressNote::start_time( $self );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub end_time {
    my $self = shift;
    return unless $self->end_date;
    eleMentalClinic::ProgressNote::end_time( $self );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub all_committed {
    my $self = shift;
    return unless $self->id;
    return 0 unless $self->note_committed;

    return 1 unless my $attendees = $self->get_attendees( undef, 0 );
    return 0;

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_group {
    my $self = shift;
    return unless $self->group_id;
    my $group = eleMentalClinic::Group->new({
        rec_id => $self->group_id,
    })->retrieve;
    return unless $group->id;
    return $group;
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
