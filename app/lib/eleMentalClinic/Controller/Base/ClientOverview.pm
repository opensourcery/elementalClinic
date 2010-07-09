# Copyright (C) 2004-2006 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.

=pod

ClientOverview is a high level view into patient information for the Venus theme.  It provides the ability to quickly edit the most important client fields, view a list of appointment history and add/review notes entered for a client.

=head1 AUTHORS

=over 4

=item Josh Partlow L<jpartlow@opensourcery.com>

=back

=cut

package eleMentalClinic::Controller::Base::ClientOverview;
use strict;
use warnings;

use base qw/ eleMentalClinic::CGI::Rolodex /;
use eleMentalClinic::Client;
use eleMentalClinic::Schedule::Appointments;
use eleMentalClinic::Theme;
use eleMentalClinic::Mail::Recipient;
use Data::Dumper;

my $schedule_controller_class =
    eleMentalClinic::Theme->new->controller_can('Schedule');

our $cgi_name = 'clientoverview.cgi';

sub note_header_options { [
    { id => 0, label => 'Called: Left Message' },
    { id => 1, label => 'Called: Disconnected' },
    { id => 2, label => 'Called: Wrong Number' },
    { id => 3, label => 'Called: No Answer' },
    { id => 4, label => 'Called: Other Dr. Rnwd' },
    { id => 5, label => 'Called: Will Call Us' },
    { id => 6, label => 'Called: Getting Docs' },
    { id => 7, label => 'Verification Sent' },
    { id => 8, label => 'Chart on File' },
    { id => 9, label => 'File Note' },
    { id => 10, label => 'New Fax Document' },
    { id => 11, label => 'Volunteer' },
    { id => 12, label => 'Other' },
] }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/3366', 'appointment', 'clientoverview', 'gateway', 'date_picker' ],
        script => $cgi_name,
        javascripts  => [ 'jquery.js', 'client_filter.js', 'clientoverview.js', 'schedule.js', 'date_picker.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias => 'Cancel',
        },
        save => {
            -alias => 'Save Patient',
            lname   => [ 'Last name', 'text::words', 'required', 'length(0,30)'],
            fname   => [ 'First name', 'text::words', 'required', 'length(0,30)'],
            mname   => [ 'Middle name', 'text::words', 'length(0,30)'],
            ssn     => [ 'Social Security number', 'demographics::us_ssn(integer)' ],
            dob     => [ 'Birthdate', 'date::general' ],
            phone   => [ 'Phone', 'text::hippie', 'length(0,25)' ],
            phone_2 => [ '2nd Phone', 'text::hippie', 'length(0,25)' ],
            email   => [ 'Email', 'email', 'length(0,64)' ],
            renewal_date  => [ 'Renewal Date', 'date::general' ],
            aka     => [ 'Alias', 'length(0,25)' ],
            state_specific_id => [ 'CPMS', 'number' ],
            comment_text => [ 'Comment', 'text::hippie' ],
            send_notifications => [ 'Send email notifications', 'checkbox::boolean' ],
        },
        save_note => {
            -alias => 'Add Note',
            start_date  => [ 'Date', 'date::general', 'required' ],
            note_header => [ 'Type', 'number::integer', 'required' ],
            note_body   => [ 'Note', 'text::hippie' ],
        },
        appointment_save => {
            noshow  => [ 'No show', 'checkbox::boolean' ],
            fax     => [ 'FAX', 'checkbox::boolean' ],
            chart   => [ 'Chart', 'checkbox::boolean' ],
			appointment_date => [ 'Date', 'date::general' ],
            notes => [ 'Note', 'text::hippie' ],
        },
        appointment_edit => {},
        appointment_remove => {},
        request_times => {},
    )
}

sub mix_in_email {
    my $self = shift;
    my ( $notes ) = @_;
    my $out = [];
    for my $note ( @$notes ) {
        push(
            @$out,
            {
                date   => $note->note_date,
                type   => $note->note_header,
                body   => $note->note_body,
                writer => $note->personnel->login,
            }
        );
    }

    my $client_id = $self->client->id;
    return $out unless $client_id;
    my $events = eleMentalClinic::Mail::Recipient->get_by_( 'client_id', $client_id );

    for my $event ( @$events ) {
        my $mail = $event->mail;
        my ( $date ) = split( ' ', $mail->send_date );
        push(
            @$out,
            {
                date    => $date,
                type    => 'Email Notification',
                subject => $mail->subject,
                writer  => 'System',
                content => $mail->htmlbody,
                mail_id => $mail->rec_id,
            }
        );
    }
    return sort_mail_in( $out );
}

sub sort_mail_in {
    my $list = shift;

    sub normalize {
        my $datestring = shift;
        $datestring =~ s/-//g;
        return $datestring;
    }

    my $sort = sub {
        my ( $a, $b ) = @_;
        # Only sorting the mail, not the notes.
        return 0 unless ( $a->{ mail_id } or $b->{ mail_id } );
        return normalize($b->{ date }) <=> normalize($a->{ date });
    };

    return [ sort { $sort->( $a, $b ) } @$list ];
}

sub home {
    my $self = shift;
    my( $current_client, $primary_treater_rolodex, $current_note ) = @_;

    my $client = $self->client;
#    $current_client ||= $client;
    $primary_treater_rolodex ||= $client->get_primary_treater;
    $current_note ||= eleMentalClinic::ProgressNote->new;
    $current_note->start_date ||
        $current_note->start_date( $self->today ); # default for new notes

    # Lookups needed for options and appointments sub-table
    my $progress_notes = $client->get_all_progress_notes;
    my $display_items = $self->mix_in_email( $progress_notes );
    my $appointments =
        eleMentalClinic::Schedule::Appointments->get_byclient($client->id);

    # store the client_id in the session so we don't lose
    # it when changing focus
    $self->session->param( 'client_id', $client->id )
        if $client->id;

#    print STDERR "Now process_page ClientOverview->home\n";

    $self->template->process_page( 'clientoverview/home', {
        current_client             => $current_client,
        current_note               => $current_note,
        display_items              => $display_items,
        primary_treater_rolodex    => $primary_treater_rolodex,
        rolodex_treaters           => eleMentalClinic::Rolodex->new->get_byrole('treaters') || 0,
        appointments               => $appointments,
        note_header_options        => $self->note_header_options,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    my $client = $self->client;

    my $primary_treater_rolodex_id = $self->param('primary_treater_rolodex_id');

    if( $self->errors ) {
        my $current_client = $client->new({ $self->Vars });
        my $primary_treater_rolodex =
            eleMentalClinic::Rolodex->new({
                rec_id => $primary_treater_rolodex_id
            });

        return $self->home( $current_client, $primary_treater_rolodex );
    }

    $client->save_primary_treater( { primary_treater_rolodex_id => $primary_treater_rolodex_id } );
    # staff id required by client update so that it can set a renewal progress note if
    # required by an update to renewal_date
    $client->update({ $self->Vars, staff_id => $self->current_user->staff_id });
    my $vars = $self->Vars;
    $self->save_phones(
        $client,
        $vars,
        [ qw(phone phone_2) ],
    );
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_note {
    my $self = shift;

    my $current_note = eleMentalClinic::ProgressNote->new( {
        $self->Vars
    });

    if ( $self->errors ) {
        return $self->home(undef, undef, $current_note);
    }

    # Need to translate note_header to text (it is currently
    # holding the id of the note_header_options selection).
    print STDERR "clientoverview controller: note_header = " . $self->Vars->{note_header} . " : " . $self->note_header_options->[$self->Vars->{note_header}]->{label};
    my @note_parts = split qr/:/,
        $self->note_header_options->[$self->Vars->{note_header}]->{label};
    # We only want to record the prefix
    $current_note->note_header( $note_parts[0] );
    $current_note->staff_id( $self->current_user->staff_id );
    $current_note->goal_id( 0 );
    $current_note->save;
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub appointment_save {
    my $self = shift;

    my $current = $self->Vars;

    print STDERR "ClientOverview->appointment_save\n";

    return $self->home( $current )
        if $self->errors;

    $schedule_controller_class->new->_appointment_save($current);

#    print STDERR "Back from Schedule->_appointment_save\n";

    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub appointment_edit {
    my $self = shift;

    print STDERR "ClientOverview->appointment_edit\n";

    $self->ajax( 1 );
    $schedule_controller_class->new->_appointment_edit( $cgi_name );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub appointment_remove {
    my $self = shift;

    print STDERR "ClientOverview->remove\n";

    $schedule_controller_class->new->_appointment_remove;
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub request_times {
    my $self = shift;

    print STDERR "ClientOverview->request_times\n";

    $self->ajax( 1 );
    $schedule_controller_class->new->_request_times( $cgi_name );
}

1;
