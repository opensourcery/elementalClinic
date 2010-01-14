package eleMentalClinic::Client::Insurance::Authorization;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Insurance::Authorization

=head1 SYNOPSIS

Client's insurance authorization records and history.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::ValidData;
use eleMentalClinic::Rolodex;
use eleMentalClinic::Client;
use eleMentalClinic::Client::Insurance;
use eleMentalClinic::Util;
use eleMentalClinic::ProgressNote;
use Date::Calc qw/ check_date Add_Delta_Days Days_in_Month Date_to_Days Delta_Days Today /;
use Data::Dumper;
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_insurance_authorization' }
    sub fields { [ qw/ 
        rec_id client_insurance_id allowed_amount
        code type start_date end_date
        capitation_amount capitation_last_date
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_insurance {
    my $self = shift;

    die 'Must call on stored object'
        unless $self->id;
    return eleMentalClinic::Client::Insurance->retrieve( $self->client_insurance_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# by default returns only one authorization
# insurance_id is required
# $date defaults to today
sub get_by_client_insurance {
    my $class = shift;
    my( $client_insurance_id, $date ) = @_;

    return unless $client_insurance_id;
    my $where = qq/ client_insurance_id = $client_insurance_id /;
    $where .= $date
        ? qq/ AND date( '$date' ) BETWEEN start_date and end_date /
        : qq/ AND date( NOW() ) BETWEEN start_date and end_date /;

    return unless
        my $auth = $class->db->select_one(
            $class->fields,
            $class->table,
            $where,
            'ORDER BY start_date DESC'
        );
    return $class->new( $auth );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# return all authorizations for client insurance in reverse order
# insurance_id is required
sub get_all_by_client_insurance {
    my $class = shift;
    my( $client_insurance_id ) = @_;

    return unless $client_insurance_id;
    my $where = qq/ WHERE client_insurance_id = $client_insurance_id /;

    return unless
        my $auths = $class->db->select_many(
            $class->fields,
            $class->table,
            $where,
            'ORDER BY start_date DESC'
        );
    return [ map{ $class->new( $_ )} @$auths ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 is_active()

Object method.

Returns C<1> is object is active on the current date.  Returns C<0> if object
is inactive.

Returns C<undef> if end_date is not defined.  This will still evaluate to
false, but gives us a little granularity.

FIXME This code is copied from C<Client::Insurance>, and we should fix that.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub is_active {
    my $self = shift;
    my( $date ) = @_;

    $date ||= $self->today;
    return 1 unless defined $self->end_date;

    my $days = Date_to_Days( split /-/ => $date );
    my $start_days = Date_to_Days( split /-/ => $self->start_date );
    my $end_days = Date_to_Days( split /-/ => $self->end_date );

    return 0
        if $start_days gt $days
        or $end_days   lt $days;
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 renewals_due_in_month( $date, [ $rolodex_id ])

Class method.

Returns a list of objects whose C<end_date> indicates they need a new renewal
in the given month.  Does some funny stuff with dates, in effect, shifting the
month window it examins backwards one day.

For example, given June 2006, renewals will be returned between these dates:
2006-05-30, 2006-06-29.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub renewals_due_in_month {
    my $class = shift;
    my( $date, $rolodex_id ) = @_;

    die 'Date is required'
        unless $date;
    my( $year, $month ) = split '-' => $date;
    die 'Invalid date'
        unless check_date( $year, $month, 1 );

    my $from = join '-' => Add_Delta_Days( $year, $month, 1, -1 );
    my $to   = join '-' => ( $year, $month, Days_in_Month( $year, $month ) -1 );
    dbquoteme( \$from, \$to, \$rolodex_id );

    my $fields = $class->fields_qualified;
    my( $rolodex_where, $rolodex_from ) = ( '', '' );
    if( $rolodex_id ) {
         $rolodex_where = qq/
            AND rolodex_mental_health_insurance.rolodex_id = $rolodex_id
        /;
    }
    my $query = qq/
        SELECT $fields
        FROM client_insurance_authorization, client_insurance, rolodex_mental_health_insurance, rolodex
        WHERE
            client_insurance_authorization.client_insurance_id = client_insurance.rec_id
            AND client_insurance.rolodex_insurance_id = rolodex_mental_health_insurance.rec_id
            AND rolodex_mental_health_insurance.rolodex_id = rolodex.rec_id
            AND DATE( client_insurance_authorization.end_date ) BETWEEN DATE( $from ) AND DATE( $to ) 
            $rolodex_where
        ORDER BY rolodex.name, client_insurance_authorization.end_date
    /;
    my $auths = $class->db->do_sql( $query );
    return unless $auths and @$auths;
    return[ map{ $class->new( $_ )} @$auths ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client {
    my $self = shift;

    return $self->client_insurance->client;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 authorization_request()

Object method.

Returns the L<eleMentalClinic::Client::Insurance::Authorization::Request>
object associated with this object, if one exists.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub authorization_request {
    my $self = shift;

    croak 'Must call on stored object'
        unless $self->id;
    return eleMentalClinic::Client::Insurance::Authorization::Request->get_one_by_(
        'client_insurance_authorization_id',
        $self->id
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 client_id()

Object method.

Returns object's C<client_id> so L<eleMentalClinic::Base>'s C<client()> method
works.

FIXME: this could be optimized by using a query instead of using the
C<client_insurance> method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub client_id {
    my $self = shift;

    croak 'Must call on stored object'
        unless $self->id;
    return $self->client_insurance->client_id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 prognotes()

Object method.

Returns all L<eleMentalClinic::ProgressNote> objects associated with this
authorization's client, and taking place during this authorization's time
period.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub prognotes {
    my $self = shift;
    return eleMentalClinic::ProgressNote->get_all(
        $self->client_id,
        $self->start_date,
        $self->end_date,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 billing_services()

Object method. Retrieves all L<eleMentalClinic::Financial::BillingService>
objects for this authorization's prognotes. See prognotes method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub billing_services {
    my $self = shift;

    return undef
        unless my $notes = $self->prognotes;

    # this will get us duplicates if there are combined notes,
    # so use a hash to filter them out
    my %billing_services;
    for my $note ( @$notes ){

        $billing_services{ $_->rec_id } = $_
            for @{ $note->billing_services_by_auth( $self->id ) };
    }
    return undef
        unless %billing_services;

    my @billing_services = sort { $a->rec_id <=> $b->rec_id } values %billing_services;
    return \@billing_services;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 transaction_amount()

Object method.

To find the total paid amount for a client insurance authorization, first find all the notes
for the auth, then find all billing services for that auth and those notes.
Then all payments to those billing services are added up.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub transaction_amount {
    my $self = shift;
    return 0
        unless my $billing_services = $self->billing_services;
    my $sum = 0;

    $sum += $_->transaction_amount
        for @$billing_services;

    return $sum;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 update_capitation()

Object method.

Updates the capitation fields in this object with current information.  Per
business rule, does nothing if the object's C<allowed_amount> property is 0.

Always returns success unless it borks.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub update_capitation {
    my $self = shift;

    return 1 unless $self->allowed_amount;
    return 1 unless
        my $amount = $self->transaction_amount;

    # XXX this is the slowest possible way for the code to do this, but the
    # fastest way for me.  plus, we're only going to run this code from a cron
    # job.
    # we exploit the fact that the notes are returned in descending date order,
    # and find the date of the most recent one with any transactions
    my $note_date;
    PROGNOTE:    
    for( @{ $self->prognotes }) {
        $note_date = $_->note_date;
        my $billing_services = $_->billing_services_by_auth( $self->id );

        for( @$billing_services ){
            last PROGNOTE if $_->transaction_amount;
        }
    }

    $self->update({
        capitation_amount       => $amount,
        capitation_last_date    => $note_date,
    });
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 capitation_amount_percent()

Object method.

Returns the percent of the authorization's C<allowed_amount> that has been
used, as an integer.  Returns C<undef> with no C<allowed_amount>, 0 if no
C<capitation_amount>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub capitation_amount_percent {
    my $self = shift;

    return unless $self->allowed_amount;
    return 0 unless $self->capitation_amount;
    return sprintf( "%.0f" => $self->capitation_amount / ( $self->allowed_amount / 100 ));
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 capitation_time_percent([ $today ])

Object method.

Accepts C<$today> to facilitate testing.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub capitation_time_percent {
    my $self = shift;
    my( $today ) = @_;

    $today ||= $self->today;
    my $days_total = Delta_Days(( split /-/ => $self->end_date ), ( split /-/ => $self->start_date ));
    my $days_todate = Delta_Days(( split /-/ => $today ), ( split /-/ => $self->start_date ));
    return sprintf( "%.0f" => $days_todate / ( $days_total / 100 ));
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

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
