package eleMentalClinic::Schedule::Availability;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Schedule::Availability

=head1 SYNOPSIS

Join between schedule location and rolodex, with availability by date.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Rolodex;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'schedule_availability' }
    sub fields { [ qw/ rec_id rolodex_id location_id date /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_one {
    my $class = shift;
    my( %vars ) = @_;
    # passing in year/month/date is ok, in which case date = day
    # passing in just date is ok too
    # but passing in the first 3 means they're all required
    if ( $vars{month} or $vars{year} ) {
        return unless $vars{month} and $vars{year};
    }
    if ( $vars{month} and $vars{year} and $vars{date} ) {
        $vars{date} = join('-',
            delete $vars{year},
            delete $vars{month},
            $vars{date},
        );
    }
    return unless $vars{date};
    return unless $vars{rolodex_id} and $vars{location_id};

    die "invalid date: $vars{date} [@_]"
        unless $vars{date} =~ /^(\d+)-(\d+)-(\d+)$/;
    $vars{date} = sprintf "%04d-%02d-%02d", $1, $2, $3;
    
    return unless my $vars = $class->new->db->select_one(
        $class->fields,
        $class->table,
        [
            'date = ? AND location_id = ? AND rolodex_id = ?',
            @vars{qw(date location_id rolodex_id)}
        ]
    );
    return $class->new( $vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_bylocation {
    my $class = shift;
    my( $location_id  ) = @_;
    return unless $location_id;

    return $class->new->db->select_many(
        $class->fields,
        $class->table,
        "WHERE location_id = $location_id",
        'ORDER BY date'
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_bydoctor {
    my $class = shift;
    my( $doctor_id ) = @_;
    return unless $doctor_id;

    return $class->new->db->select_many(
        $class->fields,
        $class->table,
        "WHERE rolodex_id = $doctor_id",
        'ORDER BY date'
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_bydate {
    my $class = shift;
    my ( $date ) = @_;
    return unless $date;
    
    #warn Dumper $date;
    return $class->new->db->select_many(
        $class->fields,
        $class->table,
        "WHERE date = '$date'",
        'ORDER BY date'
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_formonth {
    my $class = shift;
    my( %vars ) = @_;
    return unless $vars{ month } and $vars{ year };
    
    my $where = "WHERE extract(month from date) = $vars{ month }"
        ." AND extract(year from date) = $vars{ year }";
    $where .= " AND location_id = $vars{ location_id }"
        if $vars{ location_id };
    $where .= " AND rolodex_id = $vars{ rolodex_id }"
        if $vars{ rolodex_id };
    return $class->new->db->select_many(
        $class->fields,
        $class->table,
        $where,
        'ORDER BY date'
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex {
    my $self = shift;
    return unless
        my $rolodex_id = $self->rolodex_id;

    eleMentalClinic::Rolodex->new({ rec_id => $rolodex_id })->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 location()

The location that is available for scheduling.  Looked up from valid_data_prognote_location.

=cut

sub location {
    my $self = shift;
   
    return unless
        my $location_id = $self->location_id;

    return eleMentalClinic::ValidData->new({ dept_id => 1001 })->get_name('_prognote_location', $location_id);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 get_all()

Class method, returns all schedule_availability rows as Schedule::Availability objects, optionally (and typically) with a given sql LIMIT set.

Overrides Base.pm get_all, because we are ordering by date, location, doctor and supplying the limit.

=cut

sub get_all {
    my $class = shift;
    my( $limit ) = @_;

    # ensures we don't fall victim to '1;DELETE FROM foo'
    $limit =~ s/^.*(\d+).*$/$1/ if $limit;
    my $limit_clause = '';
    $limit_clause = "LIMIT $limit" if $limit;

    return unless my $hashrefs = $class->new->db->select_many(
        $class->fields,
        $class->table,
        '',
        "ORDER BY date DESC, location_id, rolodex_id $limit_clause"
    );
    my @results;
    foreach my $row ( @$hashrefs ) {
        push @results, $class->new($row);
    }

    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 detail()

Human readable detail for this Schedule::Availability object.

"Date : Location : Doctor"

The first argument is the separator string (' : ').

=cut

sub detail {
    my $self = shift;
    my( $separator ) = @_;

    $separator ||= ' : ';
    my $date = $self->date;
    my $location = $self->location;
    my $doctor = $self->rolodex->lname if $self->rolodex;
    return undef unless $date || $location || $doctor;
    
    return join $separator, ($date,$location,$doctor);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head Schedule()

Returns an eleMentalClinic::Schedule object set to the current 
Schedule::Availability's location_id, rolodex_id, year and month.

Returns undef if location_id or rolodex_id or date are not defined
yet (essentially if instance is not valid).

=cut

sub Schedule {
    my $self = shift;
    
    return unless $self->location_id && $self->rolodex_id && $self->date;
    my( $year, $month ) = $self->date =~ qr/(\d{4})-(\d{1,2})/;

    return eleMentalClinic::Schedule->new( {
        location_id => $self->location_id,
        rolodex_id => $self->rolodex_id,
        year => $year,
        month => $month,
    });

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head get_appointment_slots_tallied()

Convenience method to obtain Schedule.appoinment_slots_tallied
for the data relevant to this Schedule::Availability's key of
location/rolodex/date info.

=cut

sub get_appointment_slots_tallied {
    my $self = shift;

    return unless my $schedule = $self->Schedule;
    my( $date ) = $self->date =~ qr/^\d{4}-\d{1,2}-(\d{1,2})$/;
    return $schedule->appointment_slots_tallied($date);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head appointment_count

This looks up the count of schedule_appointment rows for this
schedule_availability record.

=cut

sub appointment_count {
    my $self = shift;

    return unless $self->rec_id;
    $self->db->do_sql(qq/
        SELECT count(*)
        FROM 
        schedule_appointments 
        WHERE schedule_availability_id = /.$self->rec_id)->[ 0 ]->{ count };
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
