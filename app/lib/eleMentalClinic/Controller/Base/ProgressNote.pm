# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
package eleMentalClinic::Controller::Base::ProgressNote;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::ProgressNote

=head1 SYNOPSIS

Base ProgressNote Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::ProgressNote;
use eleMentalClinic::ValidData;
use eleMentalClinic::Lookup::ChargeCodes;
use Date::Calc;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my ( $args ) = @_;

    $self->SUPER::init( $args );
    $self->override_template_path( 'progress_notes' );
    return $self;
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        save => {
            -alias          => 'Save for later editing',
            client_id       => [ 'Client', 'required' ],
            outcome_rating  => [ 'Rating', 'number::integer' ],
            goal_id         => [ 'Goal' ],
            note_date       => [ 'Date', 'required', 'date::iso(past,present)' ],
            start_time      => [ 'Start time' ],
            end_time        => [ 'End time' ],
            charge_code_id  => [ 'Charge code' ],
            note_location_id=> [ 'Location' ],
            note_body       => [ 'Note body' ],
            unbillable_per_writer    => [ 'Unbillable', 'checkbox::boolean' ],
        },
        commit => {
            -alias          => 'Digitally sign and commit',
            outcome_rating  => [ 'Rating', 'number::integer' ],
            client_id       => [ 'Client', 'required' ],
            goal_id         => [ 'Goal' ],
            note_date       => [ 'Date', 'required', 'date::iso(past,present)' ],
            start_time      => [ 'Start time', 'required' ],
            end_time        => [ 'End time', 'required' ],
            charge_code_id  => [ 'Charge code', 'required' ],
            note_location_id=> [ 'Location' ],
            note_body       => [ 'Note body' ],
            unbillable_per_writer    => [ 'Unbillable', 'checkbox::boolean' ],
        },
        bounce_back => {
            -alias          => 'Bounce Back',
            outcome_rating  => [ 'Rating', 'number::integer' ],
            goal_id         => [ 'Goal' ],
            note_date       => [ 'Date', 'required', 'date::iso(past,present)' ],
            start_time      => [ 'Start time', 'required' ],
            end_time        => [ 'End time', 'required' ],
            charge_code_id  => [ 'Charge code', 'required' ],
            note_location_id=> [ 'Location' ],
            note_body       => [ 'Note body' ],
            unbillable_per_writer    => [ 'Unbillable', 'checkbox::boolean' ],
            response_message => [ 'Response message', 'required', 'text::liberal' ],
        },
        print_psych => {},
        print_single => {},
        edit => {
            rec_id  => [ 'rec_id', 'required' ],
        },
        view => {
            rec_id  => [ 'rec_id', 'required' ],
        },
        charge_codes => {
            -alias          => 'Get valid charge codes',
            writer_id       => [ 'Writer', 'required' ],
            notes_from      => [ 'Notes from' ],
            notes_to        => [ 'Notes to' ],
            writer_filter   => [ 'Writer filter' ],
        },
        charge_codes_only => {
            writer_id       => [ 'Writer', 'required' ],
        },
        bounce_respond => {},
    )
}

sub writer_id {
    my $self = shift;
    return $self->current_user->id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub charge_codes {
    my $self = shift;

    my $client = $self->client;
    my $prognote = $self->get_note;

    my $progress_notes = $prognote->get_recent( $client->id, $self->current_user->pref->recent_prognotes );
    $self->init_template_vars;

    my %vars;
    $vars{ notes_from } = $self->param( 'notes_from' ) if $self->param( 'notes_from' );
    $vars{ notes_to } = $self->param( 'notes_to' ) if $self->param( 'notes_to' );
    $vars{ writer_filter } = $self->param( 'writer_filter' ) if $self->param( 'writer_filter' );
    $vars{ valid_charge_codes } = $self->get_charge_codes( $prognote );

    $self->override_template_name( 'home' );
    return {
        progress_notes  => $progress_notes,
        current         => $prognote,
        start_times     => &start_times,
        end_times       => &end_times,
        %vars,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub charge_codes_only {
    my $self = shift;

    my $prognote = $self->get_note;
    my $valid_charge_codes = $self->get_charge_codes( $prognote );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $prognote ) = @_;

    my $client = $self->client;
    if( !$prognote or $prognote->note_committed ) {
        $prognote = eleMentalClinic::ProgressNote->new;
    }

    my $progress_notes;

    $self->date_check( 'notes_from','notes_to' );
    unless( $self->errors ){
        $progress_notes = $prognote->get_all(
            $client->id,
            $self->param( 'notes_from' ),
            $self->param( 'notes_to' ),
            $self->param( 'writer_filter' ),
        );
        if (defined $progress_notes and (not $self->param('notes_from') and not $self->param('notes_to')) ) {
            if( $self->current_user->pref->recent_prognotes < @$progress_notes ){
                splice @$progress_notes, $self->current_user->pref->recent_prognotes, @$progress_notes;
            }
        }
    }
    else {
        $progress_notes = $prognote->get_recent( $client->id, $self->current_user->pref->recent_prognotes );
    }

    # if the first note returned is uncommitted, we edit that note
    # instead of allowing creation of a new one
    unless( $progress_notes->[ 0 ]->{ note_committed }) {
        my $note = shift @$progress_notes;
        $prognote = eleMentalClinic::ProgressNote->new({
            rec_id => $note->{ rec_id },
        })->retrieve;
    }

    $self->init_template_vars;

    my %vars;
    $vars{ notes_from } = $self->param( 'notes_from' ) if $self->param( 'notes_from' );
    $vars{ notes_to } = $self->param( 'notes_to' ) if $self->param( 'notes_to' );
    $vars{ writer_filter } = $self->param( 'writer_filter' ) if $self->param( 'writer_filter' );
    $vars{ valid_charge_codes } = $self->get_charge_codes( $prognote );

    $self->override_template_name( 'home' );
    return {
        progress_notes  => $progress_notes,
        current         => $prognote,
        start_times     => &start_times,
        end_times       => &end_times,
        %vars,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    #my $prognote = $self->get_note
        #unless $self->errors;
    my $prognote = $self->errors
        ? eleMentalClinic::ProgressNote->new({ $self->Vars })
        : $self->get_note;
    $prognote->goal_id( 0 )
        unless defined $prognote->goal_id;
    $prognote->save
        unless $self->errors;
    $self->home( $prognote );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub commit {
    my $self = shift;

    my $prognote = $self->get_note;
    $self->validate_note( $prognote );
    if ( $self->errors ) {
        return $self->save;
    }

    $prognote->sign_and_commit( $self->current_user );
    $prognote->save;
    return $self->redirect_to( 'progress_notes.cgi', $self->client->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print_one {
    my $self = shift;
    my( $template ) = @_;

    my $prognote = eleMentalClinic::ProgressNote->new({ $self->Vars })->retrieve;

    $self->init_template_vars;

    $self->template->vars({
        styles => [ 'report' ],
        print_styles => [ 'report', 'report_print_new', 'progress_note_print' ],
    });

    # Fetch the writer using staff_id instead of relying on the writer field - will drop that field one day
    my $writer = eleMentalClinic::Personnel->new({ staff_id => $prognote->staff_id })->retrieve;

    $template =~ m{progress_notes/(.*)};
    my $template_name = $1;

    $self->override_template_name( $template_name );
    return{
        current         => $prognote,
        writer          => $writer,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print_psych {
    my $self = shift;
    $self->print_one( 'progress_notes/print_psych' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print_single {
    my $self = shift;
    $self->print_one( 'progress_notes/print_single' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;

    return $self->home
        unless $self->config->edit_prognote;
    return $self->_note_action( 'edit' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub view {
    my $self = shift;
    return $self->_note_action( 'view' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub bounce_respond {
    my $self = shift;
    my( $prognote ) = @_;

    return $self->_note_action( 'bounce_respond', $prognote );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# XXX much like 'commit' above
sub bounce_back {
    my $self = shift;

    my $prognote = $self->get_note;
    $self->validate_note( $prognote );

    if( $self->errors ) {
        $self->bounce_respond( $prognote );
    }
    else {
        my $bounced = $prognote->bounced;
        $bounced->response_message( $self->param( 'response_message' ));
        $bounced->response_date( $self->today );
        $bounced->save;

        $prognote->note_committed( 1 );
        $prognote->save;

        $ENV{ REQUEST_URI } =~ m#(.*)/gateway/.*#; # get the first part of the URI
        return( undef, "$1/gateway/" ); # redirect
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _note_action {
    my $self = shift;
    my( $action, $prognote ) = @_;

    $prognote ||= eleMentalClinic::ProgressNote->retrieve( $self->param( 'rec_id' ));
    $self->init_template_vars;
    my %vars;
    $vars{ notes_from } = $self->param( 'notes_from' ) if $self->param( 'notes_from' );
    $vars{ notes_to } = $self->param( 'notes_to' ) if $self->param( 'notes_to' );
    $vars{ valid_charge_codes } = $self->get_charge_codes( $prognote );

    $self->override_template_name( $action );
    return {
        current         => $prognote,
        start_times     => &start_times,
        end_times       => &end_times,
        %vars,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_note {
    my $self = shift;

    for( $self->param( 'rec_id' )) {
        next unless $_;
        next unless
            my $note = eleMentalClinic::ProgressNote->retrieve( $_ );
        next unless
            $note->locked;
        $self->add_error(
            'billing_status',
            'billing_status',
            "Progress note is <strong>locked</strong> by the billing process and cannot be edited."
        )
    }

    my $prognote = eleMentalClinic::ProgressNote->new({ $self->Vars });
    my $writer = eleMentalClinic::Personnel->new({
        staff_id => $self->writer_id,
    })->retrieve;
    $prognote->data_entry_id( $self->current_user->id );
    $prognote->staff_id( $writer->id );
    $prognote->writer( $writer->fname .' '. $writer->lname );
    return $prognote;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_charge_codes {
    my $self = shift;
    my( $prognote ) = @_;

    return unless $prognote;

    my $cc = eleMentalClinic::Lookup::ChargeCodes->new;
    $cc->client_id( $self->client->id );
    $cc->staff_id( $prognote->staff_id || $self->current_user->staff_id );
    $cc->note_date( $prognote->note_date || $self->today );
    $cc->prognote_location_id( $prognote->note_location_id );
    $cc->valid_charge_codes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME : duplicated in group_notes.cgi
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
sub validate_note {
    my $self = shift;
    my( $prognote ) = @_;

    my $max_time = sprintf '%.1f' => $self->config->prognote_max_duration_minutes / 60;
    my $lax_codes = eleMentalClinic::Lookup::Group->new->get_codes_by_group_name_and_parent(
        'No validation required',
        'valid_data_charge_code',
    );
    my $code = $prognote->charge_code_id;
    # lax checking
    # look for the charge code in the list of rec_ids generated from the lax_codes hashref
    if( $code and $lax_codes and grep /^$code$/ => ( map { $_->{ rec_id }} @$lax_codes )) {
        # goal_id is required by the database
        $prognote->goal_id( 0 ) unless defined $self->param( 'goal_id' );

        # Note duration may not be negative
        # Note duration must be no greater than max time configured in eleMentalClinic_Config.pm
        $self->add_error( 'start_time', 'start_time', "<strong>Note time</strong> must be between 0 minutes and $max_time hours" )
            unless $prognote->note_duration_ok;
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
        $self->add_error( 'goal_id', 'goal_id', "${msg1}Goal$msg2" )
            unless defined $self->param( 'goal_id' );

        # Note duration must be greater than zero
        # Note duration may not be negative
        # Note duration must be no greater than max time configured in eleMentalClinic_Config.pm
        $self->add_error( 'start_time', 'start_time', "<strong>Note time</strong> must be between 1 minute and $max_time hours" )
            unless $prognote->note_duration_ok;
        # Progress note cannot be in the future.

        $self->add_error( 'note_date', 'note_date', "Progress note cannot be in the future." ) 
            if ( $prognote->note_date gt $self->today ); 
    }

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init_template_vars {
    my $self = shift;

    $self->template->vars({
        styles => [ 'layout/5050', 'progress_note', 'date_picker' ],
        script => 'progress_notes.cgi',
        javascripts  => [
            'prognote_charge_codes.js',
            'date_picker.js',
        ],
    });
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

=item Ryan Whitehurst L<ryan@opensourcery.com>

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
