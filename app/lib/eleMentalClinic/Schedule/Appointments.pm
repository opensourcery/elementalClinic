package eleMentalClinic::Schedule::Appointments;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Schedule::Appointments

=head1 SYNOPSIS

Appointments.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Rolodex;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'schedule_appointments' }
    sub fields { [ qw/
        rec_id schedule_availability_id client_id  confirm_code_id noshow
        fax chart payment_code_id auth_number notes appt_time staff_id
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_byday {
    my $class = shift;
    my( %vars ) = @_;

    return unless
        $vars{ date } and $class->valid_date( $vars{ date });

    my @fields;
    for( @{ $class->fields }) {
        push @fields => "p.$_";
    }
    my $where = "WHERE p.schedule_availability_id = v.rec_id"
        ." AND v.date = '$vars{ date }'";
    $where .= " AND location_id = $vars{ location_id }"
        if $vars{ location_id };
    $where .= " AND rolodex_id = $vars{ rolodex_id }"
        if $vars{ rolodex_id };

    return unless 
        my $appointments = $class->new->db->select_many(
            \@fields,
            'schedule_appointments AS p, schedule_availability AS v',
            $where,
            'ORDER BY v.location_id, v.date ASC, p.appt_time ASC, v.rec_id ASC'
        );
    for( @$appointments ) {
        $_->{ appt_time } =~ m/^0?([1-9]?\d:\d\d)/;
        $_->{ appt_time } = $1;
    }
    return $appointments;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_byday {
    my $class = shift;

    return unless my $appointments = $class->list_byday( @_ );
    return [ map{ $class->new( $_ )} @$appointments ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head1 list_upcomming()
Will pull a list of appointments in a range from specified date 
to specified number of days later.

Parameters:
    date:   Date to start from (yyyy-mm-dd)
    days:   Number of days from 'date' to search into
    fields: List of fields to retrieve (defaults to class fields)
            Must be an array reference.

Returns a list of database hash refs of appointments within date range.

=cut
sub list_upcoming {
    my $class = shift;
    my ( %vars ) = @_;
    my @fields;

    return unless
        $vars{ date } and $class->valid_date( $vars{ date })
                      and $vars{ days };

    $vars{ fields } ? @fields = @{ $vars{ fields }}
                    : push( @fields, "a.$_" ) for( @{ $class->fields } );

    my $where = "WHERE v.date >= '$vars{ date }'"
        ." AND v.date <= date '$vars{ date }' + interval '$vars{ days } days'";
    $where .= " AND location_id = $vars{ location_id }"
        if $vars{ location_id };
    $where .= " AND rolodex_id = $vars{ rolodex_id }"
        if $vars{ rolodex_id };

    return unless 
        my $appointments = $class->new->db->select_many(
            \@fields,
            'schedule_availability as v inner join schedule_appointments as a on (v.rec_id = a.schedule_availability_id)',
            $where,
            'ORDER BY a.rec_id ASC'
        );
    for( @$appointments ) {
        next unless ( $_->{ appt_time } );
        $_->{ appt_time } =~ m/^0?([1-9]?\d:\d\d)/;
        $_->{ appt_time } = $1;
    }
    return $appointments;

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head1 list_byclient()

Class method, returns an array of rows, one very each appointment associated with
the passed client_id.

Returns undef if client_id not passed or if no rows retrieved.

=cut

sub list_byclient {
    my $class = shift;
    my( $client_id ) = @_;

    return unless $client_id;

    return unless 
        my $appointments = $class->new->db->select_many(
            $class->fields,
            $class->table,
            "WHERE client_id = $client_id",
            'ORDER BY schedule_availability_id'
        );
    for( @$appointments ) {
        $_->{ appt_time } =~ m/^0?([1-9]?\d:\d\d)/;
        $_->{ appt_time } = $1;
    }
    return $appointments;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 get_byclient()

Returns all appointments for a passed client_id as Schedule::Appointment objects.

Returns undef if no client_id or no rows obtained.

=cut

sub get_byclient {
    my $class = shift;

    return unless my $appointments = $class->list_byclient( @_ );
    return [ map{ $class->new( $_ )} @$appointments ]
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub schedule_availability {
    my $self = shift;
    return unless
        my $availability_id = $self->schedule_availability_id;

    eleMentalClinic::Schedule::Availability->new({ rec_id => $availability_id })->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex {
    my $self = shift;
    return unless
        $self->schedule_availability;

    return $self->schedule_availability->rolodex;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 confirm_code()

Confirmation code name looked up from valid_data.

=cut

sub confirm_code {
    my $self = shift;

    return unless my $confirm_code_id = $self->confirm_code_id;
    return eleMentalClinic::ValidData->new({ dept_id => 1001 })->get_name('_confirmation_codes', $confirm_code_id);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 payment_code()

Payment code name looked up from valid_data.

=cut

sub payment_code {
    my $self = shift;

    return unless my $payment_code_id = $self->payment_code_id;
    return eleMentalClinic::ValidData->new({ dept_id => 1001 })->get_name('_payment_codes', $payment_code_id);
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
