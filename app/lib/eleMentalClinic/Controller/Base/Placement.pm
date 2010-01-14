package eleMentalClinic::Controller::Base::Placement;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Placement

=head1 SYNOPSIS

Base Placement Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Rolodex;
use eleMentalClinic::Client::Discharge;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'placement.cgi',
        styles => [ 'placement', 'layout/00', 'gateway', 'date_picker' ],
        javascripts => [ 'jquery.js', 'date_picker.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        referral_edit => {
            -alias  => 'Edit Referral',
        },
        referral_save => {
            -alias  => 'Save Referral',
            referral_date  => [ 'Referral date', 'date::iso' ],
            rolodex_id => [ 'Source', 'required' ],
        },
        admit_from_referral => {
            event_date  => [ 'Date', 'required', 'date::iso' ],
            program_id  => [ 'Program', 'required' ],
        },
        change => {
            program_id  => [ 'Program', 'required' ],
            event_date  => [ 'Date', 'required', 'date::iso' ],
        },
        discharge => {},
        discharge_view => {},
        discharge_save_for_later => {
            -alias => 'Save for later editing',
            client_contests_termination => [ 'Contests termination', 'checkbox::boolean' ],
            criminal_justice => [ 'Criminal justice', 'checkbox::boolean' ],
            last_contact_date => [ 'Last contact date', 'date::iso' ],
            termination_notice_sent_date => [ 'Termination notice sent date', 'date::iso' ],
            income => [ 'Household monthly income', 'number' ],
        },
        discharge_commit => {
            -alias => 'Commit Discharge',
            client_contests_termination => [ 'Contests termination', 'checkbox::boolean' ],
            criminal_justice => [ 'Criminal justice', 'checkbox::boolean' ],
            last_contact_date => [ 'Last contact date', 'date::iso' ],
            termination_notice_sent_date => [ 'Termination notice sent date', 'date::iso' ],
            income => [ 'Household monthly income', 'number' ],
            discharge_note => [ 'Discharge Summary', 'text::liberal' ],
            after_care => [ 'After care', 'text::liberal' ],
            sent_to => [ 'Discharged to', 'text::liberal' ],
        },
        readmit => {},
        readmit_confirm => {
            staff_id         => [ 'Staff Member',  'number::integer' ],
            level_of_care_id => [ 'Level of Care', 'number::integer' ],
        },
        event_edit => {},
        event_save => {
            event_id => [ 'Event', 'number::integer', 'required' ],
            event_date => [ 'Event date', 'date::iso', 'required' ],
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $client, $vars ) = @_;

    $client ||= $self->client;

    $vars ||= {};
    $vars->{ referrals_list } = eleMentalClinic::Rolodex->new->get_byrole( 'referral' );
    $self->override_template_name( 'home' );
    return $vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub referral_edit {
    my $self = shift;
    my( $event_id ) = @_;

    $event_id ||=  $self->param( 'event_id' );
    return $self->home
        unless $event_id;
    $self->home( undef, {
        referral_edit => 1,
        current_event => $self->_get_event( $event_id ),
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub referral_save {
    my $self = shift;
    my $client = $self->client;

    if( $self->errors ) {
        $self->home( $client, { referral => $self->Vars });
    }
    else {
        my $rolodex_referral_id = eleMentalClinic::Rolodex->new({ rec_id => $self->param( 'rolodex_id' )})->in_referral;
        my $referral_id = $self->param( 'referral_id' );

        my %vars = (
            $self->Vars,
            active  => 1,
            rolodex_referral_id => $rolodex_referral_id,
        );
        $vars{ rec_id } = $referral_id
            if $referral_id;
        my $referral = eleMentalClinic::Client::Referral->new( \%vars )->save;
        $self->home( $client );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub admit_from_referral {
    my $self = shift;

    my $client = $self->client;
    return $self->home( $client )
        if $self->errors;

    return $self->change( 
        intake_id => undef,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub readmit {
    my $self = shift;

    my $client = $self->client;
    return $self->home( $client, { readmit_confirm => 1 });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub readmit_confirm {
    my $self = shift;

    my $vars = $self->Vars;
    my $date = $self->_check_future_date( 'event_date', 'Date', $vars->{ event_date });
    # no intake prior to last discharge
    $self->add_error( 'event_date', 'event_date', '<strong>Date</strong> must be after most recent discharge.' )
        if $self->client->placement->last_discharge
        and $date le $self->client->placement->last_discharge->placement_event->event_date;
    if( $self->errors ) {
        delete $vars->{ event_date };
        return $self->home( undef, {
            current         => $vars,
            readmit_confirm => 1,
            intake_type     => $vars->{ intake_type },
        })
    }
    my %change;
    for ( grep { $vars->{$_} } qw(level_of_care_id staff_id) ) {
        $change{$_} = $vars->{$_};
    }
    $self->client->readmit(
        %change,
        program_id => $self->_program_id,
    );
    return $self->referral_edit( $self->client->placement->rec_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub change {
    my $self = shift;
    my( %vars ) = @_;

    $vars{ event_date } ||= $self->param( 'event_date' );
    my $date = $self->_check_future_date( 'event_date', 'Date', $vars{ event_date });

    # disallow changes prior to last intake
    $self->add_error( 'event_date', 'event_date', '<strong>Date</strong> must be after most recent intake.' )
        if $date le $self->client->placement->intake_date;

    $self->_check_duplicate;
    return $self->home if $self->errors;

    %vars = (
        input_by_staff_id   => $self->current_user->staff_id,
        dept_id             => $self->current_user->dept_id,
        intake_id           => undef,
        %vars,
    );
    $vars{ $_ } ||= $self->param( $_ )
        for qw/ program_id level_of_care_id staff_id event_date /;
    $vars{ program_id } ||= $self->_program_id;

    # deal with locked level of care
    # if locked, preserve current value, unless admin or financial user
    if( $self->client->placement->level_of_care_locked
        and not( $self->current_user->financial or $self->current_user->admin ))
    {
        $vars{ level_of_care_id } = $self->client->placement->level_of_care_id;
        $vars{ level_of_care_locked } = 1;
    }

    my $event = $self->client->placement->change( %vars );
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub event_edit {
    my $self = shift;
    my( $event ) = @_;

    $event ||= $self->_get_event;
    $self->template->process_page( 'placement/event_edit', {
        event_to_edit   => $event,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub event_save {
    my $self = shift;

    my $event = $self->_get_event;
    $self->add_error( 'event_id', 'event_id', "<strong>Event</strong> is required" )
        unless $event;

    my $new_date = $self->_check_future_date( 'event_date', 'Date', $self->param( 'event_date' ));
    my $previous = $event->previous_date_limit;
    my $next = $event->next_date_limit;

    $self->add_error( 'event_date', 'event_date',
        qq#<strong>Event date</strong> must be after $previous.# )
        if $previous and $new_date le $previous;
    $self->add_error( 'event_date', 'event_date',
        qq#<strong>Event date</strong> must be before $next.# )
        if $next and $new_date ge $next;

    return $self->event_edit( $event ) if $self->errors;
    for( qw/ event_date program_id level_of_care_id staff_id /) {
        $event->$_( $self->param( $_ ));
    }
    $event->save;
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub discharge {
    my $self = shift;
    
    my $client = $self->client;
    return $self->home( $client, { discharge_confirm => 1 })
        unless $self->param( 'discharge_confirm' );

    my $date = $self->_check_future_date( 'discharge_date', 'Discharge date', $self->param( 'discharge_date' ));
    # no discharge prior to last change
    $self->add_error( 'discharge_date', 'discharge_date', '<strong>Discharge date</strong> must be after most recent event.' )
        if $date le $self->client->placement->event_date;
    return $self->home( $client, { discharge_confirm => 1 })
        if $self->errors;

    my $personnel = $client->placement->personnel;

    # create placement event
    my %vars = (
        event_date          => $self->param( 'discharge_date' ) || $self->today,
        input_by_staff_id   => $self->current_user->staff_id,
        intake_id           => undef,
    );
    $vars{ $_ } = undef
        for qw/ dept_id program_id level_of_care_id staff_id /;
    my $event = $client->placement->change( %vars );

    # create new client_discharge entry
    my %discharge = (
        client_id           => $self->client->id,
        staff_name          => $personnel
                ? $personnel->fname .' '. $personnel->lname
                : '',
        committed           => 0,
        client_placement_event_id   =>  $event->rec_id,
        legal_history       =>  $self->client->legal_past_issues
                ? 1
                : 0,
    );

    my $discharge = $self->_save_discharge( \%discharge );
    return $self->_discharge_display( $discharge );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub discharge_view {
    my $self = shift;
    my( $discharge ) = @_;

    return $self->_discharge_display( $discharge );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub discharge_save_for_later {
    my $self = shift;

    my $discharge = $self->errors
        ? $self->_get_discharge
        : $self->_save_discharge;
    return $self->_discharge_display( $discharge );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub discharge_commit {
    my $self = shift;

    my $discharge;
    unless( $self->errors ) {
        $discharge = $self->_save_discharge( undef, 'commit' );
    }
    $self->_discharge_display( $discharge || $self->_get_discharge );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _discharge_display {
    my $self = shift;
    my( $discharge ) = @_;

    my %vars;
    my $placement = $self->_placement;
    if( ! $discharge and $placement and $placement->discharge ) {
        $discharge = $placement->discharge;
    }

    if( $self->op eq 'save_for_later' and $self->errors ) {
        $vars{ err_note } = qq/ Discharge has been saved. Please correct these errors before finalizing: /;
    }

    $self->template->vars({
        styles => [ 'layout/5050', 'discharge', 'date_picker' ],
    });
    $self->override_template_name( 'discharge' );
    return {
        placement   => $placement,
        discharge   => $discharge,
        last_contact_date_guess => $self->_last_contact_date,
        %vars,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _last_contact_date {
    my $self = shift;

    ( my $date = $self->client->progress_notes->[ 0 ]->{ start_date }) =~ s/ \d\d:\d\d:\d\d//g
        if $self->client->progress_notes;
    $date;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _save_discharge {
    my $self = shift;
    my( $discharge, $commit ) = @_;

    $discharge = $self->_get_discharge( $discharge, $commit );
    $discharge->save;
    return $discharge;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_discharge {
    my $self = shift;
    my( $discharge, $commit ) = @_;

    $discharge ||= $self->Vars;
    $discharge->{ rec_id } = $self->param( 'discharge_id' );
    $discharge->{ committed } = 1 if $commit;
    for( keys %$discharge ) {
        next unless $discharge->{ $_ ."_manual" };
        $discharge->{ $_ } = $discharge->{ $_ ."_manual" };
    }
    return eleMentalClinic::Client::Discharge->new( $discharge );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _placement {
    my $self = shift;

    return $self->{ placement }
        if $self->{ placement };
    my $date = $self->param( 'event_date' ) || $self->param( 'discharge_date' );
    my $placement = $self->client->placement( $date );
    return unless $placement->event;

    $self->{ placement } = $placement;
    return $self->{ placement }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _program_id {
    my $self = shift;

    return $self->param( 'admission_program_id' )
        if $self->param( 'intake_type' ) eq 'Admission';
    return $self->param( 'referral_program_id' )
        if $self->param( 'intake_type' ) eq 'Referral';
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# adds an error if all main placement items we're asked to change
# are the the current values -- you can't "change" without changing something
sub _check_duplicate {
    my $self = shift;

    {
        no warnings qw/ uninitialized /;
        for my $field( qw/ program_id staff_id level_of_care_id /) {
            return unless $self->param( $field ) eq $self->client->placement->$field;
        }
        # special case for readmit
        # FIXME
        return unless $self->_program_id eq $self->client->placement->program_id;
    }
    $self->add_error( 'client_id', 'client_id',
        'Cannot create a duplicate placement event; you must change at least one of: Program, Staff, Level of care.' )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_event {
    my $self = shift;
    my( $event_id ) = @_;

    $event_id ||= $self->param( 'event_id' );
    return unless $event_id;
    my $event = eleMentalClinic::Client::Placement::Event->new({
        rec_id => $event_id,
    })->retrieve;
    return $event;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _check_future_date {
    my $self = shift;
    my( $field, $label, $date ) = @_;

    # zero-pad, if needed
    $date =~ s/-(\d)-/-0$1-/g;
    $date =~ s/-(\d)$/-0$1/g;
    $self->add_error( $field, $field, "<strong>$label</strong> cannot be in the future" )
        unless $date le $self->today;
    return $date;
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

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
