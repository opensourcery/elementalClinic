package eleMentalClinic::Client::Notification::Appointment;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Notification::Appointment

=head1 SYNOPSIS

Client Appointment Notification class.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Client::Notification /;
use Data::Dumper;
use eleMentalClinic::Mail;
use eleMentalClinic::Client;
use eleMentalClinic::Schedule::Appointments;

our $NOTIFICATION_CLASS = "eleMentalClinic::Client::Notification::Appointment";
our $APPOINTMENT_CLASS = "eleMentalClinic::Schedule::Appointments";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub table  { 'notification_appointment' }
sub fields { [ qw/ rec_id client_id appointment_id email_id days / ] }
sub primary_key { 'rec_id' }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 subject_addon()

Object method.

Returns a string of text to be added to the subject line of an e-mail notification.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub subject_addon {
    my $self = shift;
    return "Appointment reminder: " 
        .$self->appointment->schedule_availability->date
        ." " 
        .$self->appointment->appt_time;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 message_addon()

Object method.

Returns a string of text to be added to the body of an e-mail notification.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub message_addon {
    my $self = shift;
    my $date = $self->appointment->schedule_availability->date;
    my $time = $self->appointment->appt_time;

return <<EOT
=======================================================
Appointment Information
Date: $date
Time: $time
=======================================================
EOT
;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 template_id()

Object method.

Get the template_id for this notification

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub template_id {
    my $self = shift;
    return $self->config->appointment_template;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 appointment()

Object method.

Returns the appointment associated with this notification.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub appointment {
    my $self = shift;
    return $APPOINTMENT_CLASS->retrieve( $self->appointment_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 notify()

Object or Class method.

This will generate and send notifications for all upcomming events.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub notify {
    my $self = shift;
    my ( $date, $days ) = @_;

    # This is getting a list of hashes, not objects.
    my $list = $APPOINTMENT_CLASS->list_upcoming( 
        date => $date, 
        days => $days, 
        fields => [ qw/ a.rec_id / ],
    );
    return unless $list;

    my $appointments = [ map { $APPOINTMENT_CLASS->retrieve( $_->{ rec_id })} @$list ]; 

    for my $appointment ( @$appointments ) {
        my $notification;
        my $notifications = $NOTIFICATION_CLASS->get_by_( 'appointment_id', $appointment->{ rec_id } );
        # See if there is one for the correct interval
        for my $item ( @$notifications ) {
            $notification = $item if ( $item->days == $days );
        }
        $notification ||= $NOTIFICATION_CLASS->new({
            client_id       => $appointment->client_id,
            appointment_id  => $appointment->rec_id,
            days => $days,
        });
        $notification->send unless $notification->sent;
        $notification->save;
    }
}

'eleMental';


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

Copyright (C) 2004-2008 OpenSourcery, LLC

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

=cut

