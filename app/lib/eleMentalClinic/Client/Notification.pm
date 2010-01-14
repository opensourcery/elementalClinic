package eleMentalClinic::Client::Notification;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Notification

=head1 SYNOPSIS

Client Notifications.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::Mail;
use eleMentalClinic::Client;
use eleMentalClinic::Mail::Template;
use eleMentalClinic::Client::Notification::Appointment;
use eleMentalClinic::Client::Notification::Renewal;
use eleMentalClinic::Schedule::Appointments;

our $NOTIFICATION_CLASS = "eleMentalClinic::Client::Notification";
our $TEMPLATE_CLASS = "eleMentalClinic::Mail::Template";
our $NOTIFICATION_TYPES = [ qw/ Appointment Renewal / ];

sub methods {[ qw/ email_id client_id days / ]}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 sent()

Object method.

returns true if this notification has been sent.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub sent {
    my $self = shift;
    return $self->email_id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 subject_addon()

Object method.

Returns a string of text to be added to the subject line of an e-mail notification.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub subject_addon { '' }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 message_addon()

Object method.

Returns a string of text to be added to the body of an e-mail notification.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub message_addon { '' }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 template_id()

Object method.

Get the template_id for this notification

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub template_id {
    my $self = shift;
    my $template_id = $self->config->default_mail_template;
    die( "No default mail template has been specified!\n" ) unless $template_id;
    return $template_id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 template()

Object method.

Get the template for this notification

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub template {
    my $self = shift;
    my $template = eleMentalClinic::Mail::Template->retrieve( $self->template_id );
    die( "Default template does not exist!" ) unless $template->id;
    return $template;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 client()

Object method.

Get the client associated with this notification

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client {
    my $self = shift;
    return unless $self->client_id;
    return eleMentalClinic::Client->retrieve( $self->client_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 mail()

Object method.

Returns the mail object associated with this notification.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub mail {
    my $self = shift;
    return unless $self->email_id;
    return eleMentalClinic::Mail->retrieve( $self->email_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head1 sendable()

Object method.

True if this notification should be / can be sent
False if it cannot (client has opted out, or client has no e-mail address)
 
=cut
sub sendable {
    my $self = shift;
    return unless $self->client 
              and $self->client->email
              and $self->client->send_notifications ;
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 send()

Object method.

Send the notification.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub send {
    my $self = shift;
    return unless $self->sendable;
    my $mail = $self->template->mail({
        subject => $self->subject_addon,
        message => $self->message_addon,
    });
    $mail->sender_id(1); # XXX FIXME: This should be the emc admin
    return unless $mail->send( $self->client_id );
    $self->email_id( $mail->id );
    return $mail->id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 send_notifications()

Object or Class method.

This will generate and send notifications for all upcomming events.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub send_notifications {
    my ( $sec,$min,$hour,$mday,$mon,$year ) = localtime();
    my $date = ( $year + 1900 ) . "-" . ( $mon + 1 ) . "-$mday";
    my $out = { date_used => $date };

    for my $type ( @$NOTIFICATION_TYPES ) {
        $out->{ $type } = [];
        my $days_function = lc( $type ) . "_notification_days";
        my $all_days = eleMentalClinic::Config->new->$days_function;
        for my $days ( split(/\s*,\s*/, $all_days )) {
            next unless $days =~ m/(\d+)/;
            $days = $1; #Normalize to be just the digits.
            my $class = "eleMentalClinic::Client::Notification::$type";
            $class->notify( $date, $days );
            push( @{ $out->{ $type }}, [ $date, $days ]);
        }
    }
    return $out;
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

