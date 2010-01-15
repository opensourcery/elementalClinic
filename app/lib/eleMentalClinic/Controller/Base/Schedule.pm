# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Controller::Base::Schedule;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Venus::Schedule

=head1 SYNOPSIS

Base Schedule Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Schedule;
use eleMentalClinic::Schedule::Appointments;
use HTML::Calendar::Template;
use Scalar::Util ();

use Data::Dumper;

our @calendar_controls = ( 'date', 'location_id', 'rolodex_id' );

# this controller is complicated, and passing a hashref around to each method
# is dumb; ideally, this would be first-class object state instead of its own
# hashref.
sub current {
    my $self = shift;
    $self->{current} ||= $self->Vars;
}

sub quick { shift->config->quick_schedule_availability }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    # XXX hardcoding, but this is too trivial to want to subclass for
    my $layout = $self->config->theme eq 'Venus'
        ? 'layout/7525' : 'layout/5050';
    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ $layout, 'gateway', 'appointment', 'schedule' ],
        script => 'schedule.cgi',
        javascripts => [ 'schedule.js','client_filter.js' ],
        use_new_date_picker => 1,
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    my $self = shift;
    my %availability = (
        rolodex_id  => [ 'Doctor',   'required', 'number::integer'],
        location_id => [ 'Location', 'required', 'number::integer'],
        date        => [ 'Date',     'required', 'date::general'],
    );
    my %home = (
        date        => [ 'date', 'date::iso' ],
        location_id => [ 'location_id', 'number::integer' ],
        rolodex_id  => [ 'rolodex_id', 'number::integer' ],
        schedule_availability_id => [ 'schedule_availability_id', 'number::integer' ],
    );
    (
        home     => \%home,
        by_client => {
            client_id => [ 'Client', 'required', 'number::integer' ],
        },
        calendar => {
            calendar => [ 'calendar date', 'date::iso' ],
            %home,
        },
        save => {
            %availability,
        },
        delete_day => {
			schedule_availability_id => [ 'schedule_availability_id', 'required', 'number::integer'],
        },
#        patient => {},
#        doctor => {},
        appointment_new  => {},
        appointment_save => {
            noshow  => [ 'No show', 'checkbox::boolean' ],
            fax     => [ 'FAX', 'checkbox::boolean' ],
            chart   => [ 'Chart', 'checkbox::boolean' ],
            notes => [ 'Note', 'text::hippie' ],
            $self->quick
            ? %availability
            : (),
        },
        appointment_edit => {},
        appointment_remove => {},
        request_times => {},
    )
}

sub current_date {
    my $self = shift;
    $self->{date} ||= do {
        my $date;
        if ( $self->current->{date} ) {
            my ( $year, $month, $day ) = split /-/, $self->current->{date};
            $date = {
                year  => $year,
                month => $month,
                day   => $day,
            };
        } else {
            $date = {
                year  => (localtime)[5] + 1900,
                month => (localtime)[4] + 1,
                day   => (localtime)[3],
            };
        }
        $date;
    };
}

sub format_date {
    my $self = shift;
    my ( $date ) = @_;
    # for the calendar, day is undefined
    my $fmt = $date->{day} ? "%04d-%02d-%02d" : "%04d-%02d";
    sprintf $fmt, @{ $date }{qw( year month day )};
}

sub availability_date {
    my $self = shift;
    $self->{schedule_date} ||= do {
        my $avail = $self->_get_availability_by_id;
        if ( $avail ) {
            my %date;
            @date{qw(year month day)} = split /-/, $avail->date;
            \%date;
        } else {
            $self->current_date;
        }
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO This could stand to be cleaned up.
sub home {
    my $self = shift;

    my $current = $self->current;
    $current->{withclient} ||= 'yes' if $current->{client_id};
    $self->_update_from_session( @calendar_controls, 'schedule_availability_id', 'withclient' );

    # If we are not a treater, and do not have the scheduler role then we have
    # no schedule to show, except when viewing a client schedule.
    return $self->no_schedule
        if !$self->current_user->has_schedule
           && (!$current->{withclient} || $current->{withclient} eq 'no');

    # For viewing the schedule without an associated client
    $self->template->vars({ client => eleMentalClinic::Client->new })
        if $current->{withclient} && $current->{withclient} eq 'no';

    unless ( $self->quick ) {
        if ( $self->_changed( 'schedule_availability_id' ) ) {
            # schedule_availability_id has changed since last call
            # so reset calendar controls to match
            $self->_set_calendar_controls;
        } elsif ( $self->_changed( @calendar_controls ) ) {
            # otherwise, if calendar controls have changed since 
            # last call, then reset the schedule_availability_id
            $self->_set_schedule_availability_control;
        }
    }

    my $schedule_date = $self->quick ? $self->current_date : $self->availability_date;
    # this schedule is only used for building appointments
    my $Schedule = eleMentalClinic::Schedule->new({
        year        => $schedule_date->{year},
        month       => $schedule_date->{month},
        rolodex_id  => $self->quick ? 0 : $current->{rolodex_id}  || 0,
        location_id => $self->quick ? 0 : $current->{location_id} || 0,
    });

    my $scheduled_days = $Schedule->days;

    # XXX guessing that 15 minute schedules will always be OK; this should
    # probably be configurable somehow, but we don't yet know how.
    my $default_quick_slots = $Schedule->build_appointment_slots( 15 );

    # Only generate an appointments list if this day is available for scheduling
    my $appointments = $Schedule->appointment_slots_filled(
        $schedule_date->{day},
        $self->quick && $default_quick_slots,
    ) if $scheduled_days->{ $schedule_date->{day} * 1 };

    $appointments ||= $default_quick_slots if $self->quick;

    # Save control data to session
    $self->_save_to_session(
        @calendar_controls,
        'schedule_availability_id',
        'withclient',
    );

    $self->filter_appointments( $appointments, $current );


    $self->template->process_page( 'schedule/home', {
        %$current,        
        rolodex         => $self->_get_rolodex || 0,
        treaters        => $self->treaters,
        available_schedules => eleMentalClinic::Schedule->available_schedules() || 0,
        appointments    => $appointments || 0,
        schedule_availability   => $Schedule->schedule_availability( $schedule_date->{day} ) || 0,
        # date is the date of the current availability OR the
        # currently selected calendar date, whichever is appropriate given
        # $self->quick; it's the date to schedule a new appointment for
        date            => $self->format_date( $schedule_date ),
        # current_date is ALWAYS the currently selected calendar date, regardless of
        # whether or not there is quick scheduling enabled/an availability
        # selected
        current_date    => $self->format_date( $self->current_date ),
        navpage => 'calendar',
        current_user => $self->current_user,
    });
}

sub treaters {
    my $self = shift;
    return $self->current_user->scheduler ? eleMentalClinic::Rolodex->new->get_byrole( 'treaters' )
                                          : $self->current_user->treater ? $self->current_user->treater->rolodex
                                                                         : [];
}

# XXX: Ideally the appointments would be gathered and sorted in an SQL query,
# however thus far it has been sorted and filtered in several places. I will
# refactor this if it proves a performance issue.
sub filter_appointments {
    my $self = shift;
    my ( $appointments, $current ) = @_;
    # Venus theme doesn't observe the scheduler role
    return if $self->config->Theme->open_schedule;

    #remove the appointments that don't belong to the current user.

    if ( $current->{ withclient } and $current->{ withclient } eq 'yes' ) {
        $self->filter_client_appointments( @_ );
    }
    else {
        $self->filter_user_appointments( @_ );
    }
}

sub filter_client_appointments {
    my $self = shift;
    my ( $appointments, $current ) = @_;
    @$appointments = grep { !ref( $_ ) || $_->client_id == $self->param( 'client_id' ) } @$appointments;
}

sub filter_user_appointments {
    my $self = shift;
    my ( $appointments, $current ) = @_;
    return if $self->current_user->scheduler;
    # Get the treater_rolodex_id for the current user
    # Filter appointments w/o that id.
    my $treater = $self->current_user->treater;
    return unless $treater and $treater->id;
    my $id = $treater->rolodex_id;
    @$appointments = grep {
        (!ref( $_ )) || ($_->schedule_availability->rolodex_id == $id) ? 1 : 0;
    } @$appointments;
}

sub no_schedule {
    my $self = shift;
    $self->override_template_name( 'no_schedule' );
    return { }
}

sub by_client {
    my $self = shift;
    my $appointments = eleMentalClinic::Schedule::Appointments->get_byclient(
        $self->param( 'client_id' )
    );

    push @{ $self->template->vars->{styles} }, 'clientoverview';

    return {
        appointments => $appointments,
        navpage => 'overview',
    };
}

sub calendar {
    my $self = shift;
    $self->ajax(1);
    return $self->_build_calendar->calendar;
}

sub _build_calendar {
    my $self = shift;
    my $current = $self->current;

    my $calendar = do {
        my %vars = (Controller => $self);
        Scalar::Util::weaken( $vars{Controller} );

        my $date = $self->current->{calendar} 
            ? do {
                my ($year, $month) = split /-/, $self->current->{calendar};
                { year => $year, month => $month }
            }
            : $self->current_date;
        my $calendar = HTML::Calendar::Template->new(
            orthodox            => 1,
            template_path       => [
                map { "$_/schedule/calendar" }
                    $self->config->template_path,
                    $self->config->default_template_path
            ],
            template_extension  => 'html',
            year  => $date->{year},
            month => $date->{month},
            date  => $date->{day},
        );
        $calendar->vars( \%vars );
        $calendar;
    };

    my $schedule = eleMentalClinic::Schedule->new({
        month => $calendar->month,
        year  => $calendar->year,
        # leaving these at 0 means "show everything", which is what we want if
        # we aren't setting up schedules ahead of time
        $self->quick
        ? (
            location_id => 0,
            rolodex_id  => 0,
        )
        : (
            location_id => $current->{location_id} || 0,
            rolodex_id  => $current->{rolodex_id}  || 0,
        )
    });

    my $date = $self->current_date;

    my $scheduled_days = $schedule->days;
    for( 1 .. $calendar->days_in_month ) {
        my @class;
        if ( $self->quick || $scheduled_days->{ $_ }) {
            push @class, 'doc_scheduled';
            push @class, 'appointments' if $schedule->appointments( $_ );
        }
        else {
            push @class, 'unavailable'
        }
        push @class, 'current'   if $date and (
            $date->{year}  == $calendar->year and
            $date->{month} == $calendar->month and
            $date->{day}   and
            $date->{day}   == $_
        );
        $calendar->class( $_, "@class" ) if @class;
        my $uri = $self->uri->clone;
        my $param = $uri->query_form_hash;
        $uri->query_form({
            date => join('-', $calendar->year, $calendar->month, $_), 
            map { $_, $param->{$_} }
            grep { exists $param->{$_} }
                # location_id, rolodex_id, and schedule_availability_id would
                # be here if they weren't stored in the session.
                qw(client_id)
        });
        $calendar->link( $_, $uri );
    }
    return $calendar;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Save a new Schedule::Availability entry (admin only)
sub save {
    my $self = shift;
    my $current = $self->current;

    return $self->home unless $self->current_user->admin;

    unless ( $self->errors ) {
        if ( $self->_get_availability ) {
            $self->add_error(
                'rolodex_id',
                'schedule_availability_business_key',
                'The chosen doctor is already scheduled for that date and location.',
            );
        } else {
            $self->_save_availability;
        }
    }

    return $self->home;
}

sub _get_availability_by_id {
    my $self = shift;
    return unless my $id = $self->current->{schedule_availability_id};
    return eleMentalClinic::Schedule::Availability->retrieve( $id );
}

sub _get_availability {
    my $self = shift;

    return eleMentalClinic::Schedule::Availability->get_one(
        date        => $self->format_date( $self->current_date ),
        rolodex_id  => $self->current->{rolodex_id},
        location_id => $self->current->{location_id},
    );
}

sub _save_availability {
    my $self = shift;

    return eleMentalClinic::Schedule::Availability->new({
        date        => $self->format_date( $self->current_date ),
        rolodex_id  => $self->current->{rolodex_id},
        location_id => $self->current->{location_id},
    })->save;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Delete an existing Schedule::Availability entry (admin only)
sub delete_day {
    my $self = shift;
    my $current = $self->current;
   
    return $self->home
        unless $self->current_user->admin;

    my $day = $self->_get_availability_by_id;

    return $self->home unless $day->rolodex_id;
    
    if ($day->appointment_count > 0) {
        $self->add_error("schedule_availability_id", "schedule_availability_id", $day->rolodex . " scheduled at " . $day->location . " on " . $day->date . " still has " . $day->appointment_count . " appointments scheduled.  The appointments must be cancelled before the scheduled day can be removed.");
        return $self->home; 
    }
    $self->db->delete_one(
        'schedule_availability',
        'rec_id = ' . $day->rec_id,
    );
    return $self->home;    
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 _changed()

Returns true if entries in the passed hash have changed from the entries in the session.  An undefined hash entry is not considered to have changed.

The second parameter must be an arrayref of keys to check.

=cut

sub _changed {
    my $self = shift;
    my ( @keys ) = @_;

    foreach my $key (@keys) {
        my $current_value = $self->current->{$key};
        my $session_value = $self->session->param($key) || '';
        return 1 
            if $current_value &&
               $current_value ne $session_value;
    }   
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 _update_from_session()

Updates the entries in the passed hash to the values stored in the session.  Entries in the hash are only updated if they are not already defined.

The second parameter must be an arrayref of the keys for the entries to be updated.

=cut

sub _update_from_session {
    my $self = shift;
    my ( @keys ) = @_;

    foreach my $key (@keys) {
        $self->current->{$key} ||= $self->session->param($key);
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 _set_calendar_controls()

Reset all the calendar controls to match the values from the Schedule::Availability object associated with the schedule_availability_id.  This keeps the calendar in synch with the selection from the schedule drop down.

=cut

sub _set_calendar_controls {
    my $self = shift;
    my $current = $self->current;

    my $schedule_availability = $self->_get_availability_by_id or return;

    $current->{date} = $schedule_availability->date;
    $current->{rolodex_id} = $schedule_availability->rolodex_id;
    $current->{location_id} = $schedule_availability->location_id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 set_schedule_availability_control()

Reset the schedule_availablity_id to an id matching the calendar control values (if the current calendar control values point to a valid schedule_availability_id).  This keeps the schedule drop down in synch with the calendar.

=cut

sub _set_schedule_availability_control {
    my $self = shift;
    my $current = $self->current;

    my $schedule_availability = 
        eleMentalClinic::Schedule::Availability->get_one(
            date        => $current->{date},
            location_id => $current->{location_id},
            rolodex_id  => $current->{rolodex_id},
        );
    return unless $schedule_availability && $schedule_availability->id;

    $current->{schedule_availability_id} = $schedule_availability->id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 _save_to_session()

Stores a set of entries from the passed hash into the session.

=cut

sub _save_to_session {
    my $self = shift;
    my ( @keys ) = @_;
    
    foreach my $key (@keys) {
        $self->session->param( $key, $self->current->{$key} );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub appointment_save {
    my $self = shift;

    return $self->home if $self->errors;
    $self->_appointment_save;
    return $self->home;
}

sub _appointment_save {
    my $self = shift;
    my $current = $self->current;

#    print STDERR Dumper "_appointment_save";

    $current->{staff_id} = $self->current_user->staff_id;
    $current->{rec_id}   = $self->param( 'appointment_id' ) || $self->param( 'rec_id' );
   
#    print STDERR Dumper ["Current:", $current];
    if ( $self->quick ) {
        die "got schedule_availability_id "
            . $current->{schedule_availability_id}
            . ", but quick_schedule_availability is enabled"
            if $current->{schedule_availability_id};
        $current->{schedule_availability_id} = (
            $self->_get_availability( $current ) ||
            $self->_save_availability( $current )
        )->rec_id;
    }
 
    $self->db->transaction_do_eval(sub {
        eleMentalClinic::Schedule::Appointments->new( { %$current })->save
    });
    if ($@) {
        print STDERR Dumper ['$@:', "$@"];
        if ($@ =~ /DBD::Pg::st execute failed: ERROR:  duplicate key violates unique constraint "schedule_appointments_business_key"/) {
            $self->add_error('appt_time', 'Duplicate Appointment Time', "Sorry, but you can't set two appointments for the same person at the same time.") 
        }
        else {
            die "eleMentalClinic::Controller::Venus::Schedule failed to save appointment: $@";
        }
    }
   
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Retrieve the available appointment times data if user changes the
# schedule_availability record for an appointment
sub request_times {
    my $self = shift;

    print STDERR Dumper "Schedule->request_times";
    $self->_request_times;
}

sub _request_times {
    my $self  = shift;
    my( $return_script ) = @_;
    
    print STDERR Dumper "_request_times";

    $self->ajax( 1 );

#    print STDERR Dumper ["schedule_availability_id", $self->param( 'schedule_availability_id' )];

    my $schedule_availability = eleMentalClinic::Schedule::Availability->new( {rec_id => $self->param( 'schedule_availability_id' ) } )->retrieve;
    return 'Schedule::Availability not found.'
        unless $schedule_availability;

    my $appointment_times = $schedule_availability->get_appointment_slots_tallied;
    return 'Appointment times not found.'
        unless $appointment_times;

    $self->template->process_page( 'schedule/popup/appointment_times', {
        appointment_times   => $appointment_times,
        return_script       => $return_script,
        ajax                => 1,
        prefix              => "edit_",
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub appointment_edit {
    my $self = shift;

    $self->_appointment_edit;
}

sub _appointment_edit {
    my $self = shift;
    my( $return_script ) = @_;
    
    $self->ajax( 1 );
    return 'Appointment not found'
        unless my $appointment = $self->_get_appointment;

    my $schedule_availability = $appointment->schedule_availability;

    $self->template->process_page( 'schedule/popup/appointment', {
        available_schedules => eleMentalClinic::Schedule->available_schedules() || 0,
        appointment_times   => $schedule_availability->get_appointment_slots_tallied || 0,
        $return_script ? ( return_script => $return_script ) : (),
        ajax        => 1,
        appointment => $appointment,
        prefix      => "edit_",
        treaters    => $self->treaters,
        # default to 'no' because it will have been set to 'yes' by loading the
        # schedule page, just previously, if there was a client selected
        withclient  => $self->session->param('withclient') || 'no',
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub appointment_remove {
    my $self = shift;

    $self->_appointment_remove; 
    $self->home;
}

sub _appointment_remove {
    my $self = shift;

    return $self->home
        unless my $appt = $self->_get_appointment;
    return $self->home
        unless $self->current_user->primary_role->has_client_permission( $appt->client_id );

    $self->db->delete_one(
        'schedule_appointments',
        'rec_id = '. $appt->id,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_rolodex {
    my $self = shift;
    my $current = $self->current;

    return unless $current->{'rolodex_id'};
    return eleMentalClinic::Rolodex->new({
        rec_id   => $current->{'rolodex_id'}
    })->retrieve;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_appointment {
    my $self = shift;

    my $appointment = eleMentalClinic::Schedule::Appointments->new({
        rec_id => ( $self->param( 'appointment_id' ) || $self->param( 'rec_id' )),
    })->retrieve;
    return unless $appointment->id;
    return $appointment;
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
