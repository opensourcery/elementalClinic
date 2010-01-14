package eleMentalClinic::Client::Notification::Renewal;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Notification::Renewal

=head1 SYNOPSIS

Client Renewal Notification class.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Client::Notification /;
use Data::Dumper;
use eleMentalClinic::Mail;
use eleMentalClinic::Client;

our $NOTIFICATION_CLASS = "eleMentalClinic::Client::Notification::Renewal";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub table  { 'notification_renewal' }
sub fields { [ qw/ rec_id client_id renewal_date email_id days / ] }
sub primary_key { 'rec_id' }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 subject_addon()

Object method.

Returns a string of text to be added to the subject line of an e-mail notification.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub subject_addon {
    my $self = shift;
    return "Your card expires on " . $self->client->renewal_date;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 message_addon()

Object method.

Returns a string of text to be added to the body of an e-mail notification.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub message_addon {
    my $self = shift;
    my $date = $self->client->renewal_date;

return <<EOT
=======================================================
Card Expiration
Your card is going to expire on $date.
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
    return $self->config->renewal_template;
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

    my $renewals = $self->get_renewals( $date, $days );

    for my $client ( @$renewals ) {
        my $notification = $NOTIFICATION_CLASS->get_existing( $client, $days );
        $notification ||= $NOTIFICATION_CLASS->new({
            client_id => $client->client_id,
            renewal_date => $client->renewal_date,
            days => $days,
        });
        $notification->send unless $notification->sent;
        $notification->save;
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_existing()

class method.

get and existing renewal for the provided client.
Will only returns existing renewal that has the same renewal date.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_existing {
    my $class = shift;
    my ( $client, $days ) = @_;
   
    my $client_id = $client->id;
    my $renewal_date = $client->renewal_date;
    my $where = "client_id = $client_id AND renewal_date = '$renewal_date' AND days = $days";
    my $id = $class->db->select_one(
        [ 'rec_id' ],
        $class->table,
        $where
    );
    return unless $id;
    return $class->retrieve( $id->{ rec_id });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head1 get_renewals()

Class method

returns a list of clients who have upcomming renewals

takes an anonymous hash as a parameter:
date => date to start looking for renewals
days => number of days to search after date.

=cut
sub get_renewals {
    my $class = shift;
    my ( $date, $days ) = @_;

    my $where = "WHERE renewal_date >= '$date'"
        ." AND renewal_date <= date '$date' + INTERVAL '$days days'";

    my $list = $class->db->select_many(
        [ 'client_id' ],
        eleMentalClinic::Client->table,
        $where,
    );

    return unless $list;

    return [ map { eleMentalClinic::Client->retrieve( $_->{ client_id })} @$list ]; 
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

