# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Schedule;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Schedule

=head1 SYNOPSIS

Parent schedule object.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Schedule::Availability;
use eleMentalClinic::Schedule::Appointments;
use Date::Calc qw/ Add_Delta_DHMS Delta_DHMS /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub fields { [ qw/ month year location_id rolodex_id /] }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub schedule_availability {
    my $self = shift;
    my( $date ) = @_;

    return eleMentalClinic::Schedule::Availability->get_one(
        year    => $self->year,
        month   => $self->month,
        date    => $date,
        location_id => $self->location_id,
        rolodex_id  => $self->rolodex_id,
    );
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub days {
    my $self = shift;

    return unless
        my $days = eleMentalClinic::Schedule::Availability->list_formonth(
            month   => $self->month,
            year    => $self->year,
            location_id    => $self->location_id,
            rolodex_id    => $self->rolodex_id,
        );
    my %days;
    for( @$days ) {
        $days{ $1 * 1 }++
            if $_->{ date } =~ /^\d{4}-\d{2}-(\d{2})$/;
    }
    return \%days;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub appointments {
    my $self = shift;
    my( $date ) = @_;

    return unless $date and $self->month and $self->year;
    return unless
        my $appointments = eleMentalClinic::Schedule::Appointments->get_byday(
            date        => $self->year .'-'. $self->month .'-'. $date,
            location_id => $self->location_id,
            rolodex_id  => $self->rolodex_id,
        );
    #warn Dumper $appointments;
    return $appointments;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 appointment_slots()

I'm altering appointment slots not to use the valid_data_schedule_types
schedule_multiplier so that we can work with a simple scheduling that
allows them to add as many appointments per slot as they require
Hence, appointment_slots currently just returns a list of times from
start to end, based on a fixed schedule_interval of 15 minutes.

=cut

sub appointment_slots {
    my $self = shift;
    my( $rolodex_id ) = @_;

    return unless $rolodex_id;

    # get the data
    my $type = $self->db->select_one(
        [ 'schedule_type_id' ],
        'schedule_type_associations',
        "rolodex_id = $rolodex_id",
    );
    my $schedule = eleMentalClinic::Department->new->valid_data->get( '_schedule_types', $type->{ schedule_type_id });
    return unless $schedule;

    return $self->build_appointment_slots( $schedule->{schedule_interval} );
}

sub _time { sprintf "%d:%02d", @_[0, 1] }

sub build_appointment_slots {
    my $self = shift;
    my ( $interval, $start, $end ) = @_;

    # each are (HH, MM)
    my @start   = split /:/,
        $start || $self->config->clinic_first_appointment || '8:00';
    my @end     = split /:/, 
        $end   || $self->config->clinic_last_appointment || '16:45';
    my @current = @start;

    my @times;
    push @times => _time(@start);

    my @delta = ( 0, 0, 0 );
    while( $delta[ 1 ] >= 0 and $delta[ 2 ] >= 0 ) {
        ( @current ) = ( Add_Delta_DHMS( 1971,7,4,
            @current, 0,
            0, 0, $interval, 0 ))[ 3, 4 ];
        push @times => _time(@current);
        @delta = Delta_DHMS(
            1971, 7, 4, @current, 0,
            1971, 7, 4, @end, 0,
        );
    }
    return \@times;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 appointment_slots_filled()

This adds entries for filled appointments into the list of appointment_slots().
User is always able to add a new appointment.  So, if I have a schedule
from 8:00 to 10:00 in half hour intervals, and there is already an appointment
set for 9:30, the list will look like:

8:00 - available
8:30 - available
9:00 - available
9:30 - appointment
9:30 - available
10:00 - available

Returns an array of all the available times interspersed with actual
appointments, in time order ascending.

=cut

sub appointment_slots_filled {
    my $self = shift;
    my( $date, $slots ) = @_;

    return unless
        $slots ||= $self->appointment_slots( $self->rolodex_id );
    my $appointments = $self->appointments( $date ) || [];
    # see #1191 -- make sure that these are sorted by appt_time, as we (later)
    # expect, rather than by location_id and date, as is the default
    @$appointments = sort {
        sprintf("%05s", $a->appt_time)
        cmp
        sprintf("%05s", $b->appt_time)
    } @$appointments;
    my @filled;
    for( @$slots ) {
        
        # push in all the appointments for the current time.
        while( $appointments and $appointments->[ 0 ] and $_ eq $appointments->[ 0 ]->appt_time ) {
            push @filled => shift @$appointments;
        }
#        else {

# push in the time, regardless, so a new appointment can always be added for
# this slot...
            push @filled => $_;

#        }
    }
    return \@filled;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 appointment_slots_tallied()

Provides a list of appointments with a count of how many appointments
have already been schedule for that time slot.

Returns an array of arrays, where each time slot array is the time, # of appointments:

[
    [ 8:00, 0 ],
    [ 8:15, 1 ],
    [ 8:30, 0 ],
    [ 9:00, 3 ],
...
]

=cut

sub appointment_slots_tallied {
    my $self = shift;
    my( $date ) = @_;

    return unless
        my $slots = $self->appointment_slots( $self->rolodex_id );
    my $appointments = $self->appointments( $date );
    my @tallied;
    for( @$slots ) {
        
        my $tally = 0;
 
        # tally all the appointments for the current time.
        while( $appointments and $appointments->[ 0 ] and $_ eq $appointments->[ 0 ]->appt_time ) {
            $tally++;
            shift @$appointments;
        }

        push @tallied => { appt_time => $_, count => $tally };

    }
    return \@tallied;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_schedule_type {
    my $self = shift;
    my ($schedule_type_id) = @_;
    
    return unless $schedule_type_id;
    
    #warn Dumper $self;
    my $where = "rolodex_id = ".$self->rolodex_id;
    my @ucolumns = qw/schedule_type_id/;
    my @icolumns = qw/rolodex_id schedule_type_id/;
    
    
    my $already_set = $self->db->select_one(\@ucolumns,'schedule_type_associations',$where);
    #warn Dumper $already_set;
    if( $already_set ) {
        my @values = ($schedule_type_id);
        $self->db->update_one('schedule_type_associations',\@ucolumns,\@values,$where);
    } else {
        my @values = ($self->rolodex_id,$schedule_type_id);
        $self->db->insert_one('schedule_type_associations',\@icolumns,\@values);
    }
    
    return;
}

sub get_schedule_type {
    my $self = shift;
    my ( $rolodex_id ) = @_;
    return unless $rolodex_id;
    
    my @columns = qw/schedule_type_id/;
    my $where = "rolodex_id = $rolodex_id";
    
    my $result = $self->db->select_one( \@columns,'schedule_type_associations',$where );
    #warn Dumper $schedule_type_id;
    
    return $result->{ schedule_type_id };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head available_schedules()

This class method is an optimization over Schedule::Availability->get_all() to provide
all of the data needed for the list of "Date : Doctor : Location : Appointment Count"
that is used in the main scheduling drop down.

=cut

sub available_schedules {
    my $class = shift;

    my $available_schedules = $class->new->db->do_sql(qq/
       select
           sa.rec_id as schedule_availability_id,
           sa.date,
           l.name as location,
           r.lname as doctor,
           count(appt.rec_id) as appointment_count
       from
           schedule_availability as sa inner join valid_data_prognote_location as l
           on sa.location_id = l.rec_id
           inner join rolodex as r
           on sa.rolodex_id = r.rec_id
           left outer join schedule_appointments as appt
           on sa.rec_id = appt.schedule_availability_id
       group by
           sa.rec_id,
           sa.date,
           l.rec_id,
           l.name,
           r.rec_id,
           r.lname
       order by
           sa.date DESC,
           l.rec_id,
           r.rec_id
    /);
    
    return $available_schedules;
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
