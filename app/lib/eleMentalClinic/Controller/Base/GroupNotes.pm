package eleMentalClinic::Controller::Base::GroupNotes;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::GroupNotes

=head1 SYNOPSIS

Base Group Notes Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI::GroupCGI /;
use Data::Dumper;
use eleMentalClinic::Group;
use eleMentalClinic::Group::Note;
use eleMentalClinic::ProgressNote;
use eleMentalClinic::Group::Attendee;
use eleMentalClinic::Lookup::ChargeCodes;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/3366', 'group_notes', 'active_groups', 'date_picker' ],
        script => 'group_notes.cgi',
        javascripts  => [
            'prognote_charge_codes.js',
            'jquery.js',
            'date_picker.js'
        ],
    });
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias  => 'New Group Note',
        },
        save_group_note => {
            -alias => 'Save for later editing',
            outcome_rating  => [ 'Outcome rating', 'length(0,20)' ],
            note_body       => [ 'Note body' ],
            note_date       => [ 'Note date', 'date::iso(past,present)' ],
        },
        commit_group_note => {
            -alias => 'Commit group note',
            outcome_rating  => [ 'Outcome rating', 'length(0,20)' ],
            note_body       => [ 'Note body' ],
            charge_code_id  => [ 'Charge code', 'required' ],
            note_date       => [ 'Note date', 'date::iso(past,present)' ],
        },
        save_prognote => {
            -alias => 'Save progress note for later editing',
            outcome_rating  => [ 'Outcome rating', 'length(0,20)' ],
            note_body       => [ 'Note body' ],
        },
        commit_prognote => {
            -alias => 'Digitally sign and commit',
            outcome_rating  => [ 'Outcome rating', 'length(0,20)' ],
            note_body       => [ 'Note body' ],
            charge_code_id  => [ 'Charge code', 'required' ],
        },
        prognote_detail => {},
        group_note_detail => {},
        client_prognote_detail => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $group_note ) = @_;

    $group_note ||= $self->get_group_note;
    my $group;
    if( $group_note ) {
        return $self->group_note_detail
            if $group_note->note_committed;
        $group = $self->get_group( $group_note->group_id );
    }
    else {
        $group = $self->get_group;
    }
    my %vars;
    $vars{ valid_charge_codes } = $self->get_charge_codes( $group_note );
    $self->template->process_page( 'group_notes/home', {
        group           => $group,
        start_times     => &start_times,
        end_times       => &end_times,
        group_note      => $group_note,
        %vars,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_group_note {
    my $self = shift;

    my $note = $self->_save_group_note;
    $self->home( $note );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub commit_group_note {
    my $self = shift;

    my $group_note = $self->_save_group_note;
    $group_note->commit
        unless $self->errors;
    $self->group_note_detail( $group_note );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_note_detail {
    my $self = shift;
    my( $group_note ) = @_;

    $group_note ||= $self->get_group_note( $self->param( 'group_note_id' ));
    return $self->home( $group_note )
        unless $group_note->note_committed;
    my $group = $self->get_group( $group_note->group_id );
    my %vars;
    $vars{ valid_charge_codes } = $self->get_charge_codes( $group_note );
    $self->template->process_page( 'group_notes/notes', {
        group           => $group,
        group_note      => $group_note,
        %vars,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_prognote {
    my $self = shift;

    my $prognote = $self->get_prognote;
    $prognote->save
        unless $self->errors;
    $self->prognote_detail( $prognote );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub commit_prognote {
    my $self = shift;

    my $prognote = $self->get_prognote;
    $self->validate_note( $prognote );
    unless( $self->errors ) {
        $prognote->sign_and_commit( $self->current_user );
        $prognote->save;
    }
    $self->prognote_detail( $prognote );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognote_detail {
    my $self = shift;
    my( $prognote ) = @_;

    my $attendee = $self->get_attendee;
    $prognote ||= $attendee->get_prognote;

    my $group_note = $self->get_group_note( $attendee->group_note_id );
    my $group = $self->get_group( $group_note->group_id );
    my %vars;
    $vars{ valid_charge_codes } = $self->get_charge_codes( $group_note );
    $self->template->process_page( 'group_notes/notes', {
        attendee        => $attendee,
        group_note      => $group_note,
        group           => $group,
        prognote        => $prognote,
        %vars,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_prognote_detail {
    my $self = shift;
    my( $prognote ) = @_;

    my $attendee = $self->get_attendee;
    return $self->home
        if $self->errors;
    $prognote ||= $attendee->get_prognote;

    my $group_note = $self->get_group_note( $attendee->group_note_id );
    my $group = $self->get_group( $group_note->group_id );

    my $groups = $group->get_byclient(
        $self->param( 'client_id' ),
        $group->show_from_str( $self->group_filter ),
    );

    $self->template->process_page( 'groups/client_notes', {
        attendee        => $attendee,
        group_note      => $group_note,
        group           => $group,
        prognote        => $prognote,
        groups          => $groups,
        group_filter     => $self->group_filter,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _save_group_note {
    my $self = shift;

    my %actions;
    for( keys %{ $self->Vars } ) {
        next unless $_ =~ /^action_(\d+)/;
        $actions{ $1 } = $self->param( $_ );
    }

    my $note = eleMentalClinic::Group::Note->new({ $self->Vars });
    $note->rec_id( $self->param( 'group_note_id' ));
    $note->data_entry_id( $self->current_user->id );
    $note->staff_id( $self->current_user->id );

    $note->save( \%actions );

    if( $self->op eq 'commit_group_note' ) {
        $self->validate_note( $note ); 
    
        # make sure we have at least one attendee
        $self->add_error( 'group_id', 'group_id',
            'You must enter attendance information.' )
            unless grep /group_note|no_show/ => values %actions;
    }
    $note;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Note: this could be validating a group note or a progress note
# FIXME refactor to put this into a Note object that both group notes and 
# progress notes inherit from - KJC
sub validate_note {
    my $self = shift;
    my( $note ) = shift;
    
    my $max_time = sprintf '%.1f' => $self->config->prognote_max_duration_minutes / 60;
    my $lax_codes = eleMentalClinic::Lookup::Group->new->get_codes_by_group_name_and_parent(
        'No validation required',
        'valid_data_charge_code',
    );
    my $code = $note->charge_code_id;
    # lax checking
    # look for the charge code in the list of rec_ids generated from the lax_codes hashref
    if( $code and $lax_codes and grep /^$code$/ => ( map { $_->{ rec_id }} @$lax_codes )) {

        # Note duration may not be negative
        # Note duration must be no greater than max time configured in eleMentalClinic_Config.pm
        $self->add_error( 'start_time', 'start_time', "<strong>Note time</strong> must be between 0 minutes and $max_time hours" )
            unless $note->note_duration_ok;
    }
    # strict checking
    # FIXME ew, hard-coded HTML
    else {
        my $msg1 = "<strong>";
        my $code_names = join ', ' => ( map { $_->{ name }} @$lax_codes );
        my $msg2 = "</strong> is required unless you select a charge code in: $code_names";
        $self->add_error( 'note_body', 'note_body', "${msg1}Note Body$msg2" )
            unless $self->param( 'note_body' );
#        $self->add_error( 'writer_id', 'writer_id', "${msg1}Writer$msg2" )
#            unless $self->param( 'writer_id' );
        $self->add_error( 'note_location_id', 'note_location_id', "${msg1}Location$msg2" )
            unless $self->param( 'note_location_id' );

        # Note duration must be greater than zero
        # Note duration may not be negative
        # Note duration must be no greater than max time configured in eleMentalClinic_Config.pm
        $self->add_error( 'start_time', 'start_time', "<strong>Note time</strong> must be between 1 minute and $max_time hours" )
            unless $note->note_duration_ok;
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_attendee {
    my $self = shift;

    my $attendee = eleMentalClinic::Group::Attendee->new({
        rec_id => $self->param( 'attendee_id' )})->retrieve;
    $self->add_error( 'attendee_id', 'attendee_id',
        'Invalid attendee id; this should never happen under normal use; please contact developer.')
        unless $attendee->id;
    return $attendee;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_group_note {
    my $self = shift;
    my( $id ) = @_;

    $id ||= $self->param( 'group_note_id' );
    return unless $id;
    eleMentalClinic::Group::Note->new({ rec_id => $id })->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_prognote {
    my $self = shift;

    my $prognote = eleMentalClinic::ProgressNote->new({ $self->Vars });
    my $writer = eleMentalClinic::Personnel->new({
        staff_id => $self->current_user->id,
    })->retrieve;
    $prognote->rec_id( $self->param( 'prognote_id' ));
    $prognote->data_entry_id( $self->current_user->id );
    $prognote->staff_id( $writer->id );
    $prognote->writer( $writer->fname .' '. $writer->lname );
    $prognote;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME : duplicated from progress_notes.cgi
sub start_times {
    my( @times, $time, $time24, $m, $h, $h24, $des );
    for( my $i = 0; $i < 96; $i++ ) {
        $m = sprintf( "%02d", ( $i % 4 ) * 15 );
        $h24 = sprintf( "%1d", ( $i / 4 ));
        $des = $h24 < 12 ? 'AM' : 'PM';
        $h = $h24 < 13 ? $h24 : $h24 - 12;

        push @times => {
            key => "$h24:$m",
            val => "$h:$m $des",
        };
    }
    return \@times;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub end_times {
    &start_times;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_charge_codes {
    my $self = shift;
    my( $note ) = @_;

    my $cc = eleMentalClinic::Lookup::ChargeCodes->new;
    if( $note ) {
        $cc->client_id( $self->client->id );
        $cc->staff_id( $note->staff_id || $self->current_user->staff_id );
        $cc->note_date( $note->note_date || $self->today );
        $cc->prognote_location_id( $note->note_location_id );
    }
    else {
        $cc->staff_id( $self->current_user->staff_id );
        $cc->note_date( $self->today );
    }
    $cc->valid_charge_codes;
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
