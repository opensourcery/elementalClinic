package eleMentalClinic::Client::Placement::Episode;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Placement::Episode

=head1 SYNOPSIS

A group of Client::Placement::Event records, from intake to discharge.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use Date::Calc qw/ Date_to_Days /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub fields { [ qw/ client_id date valid_episode /] }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get the current episode, 
# or get the one associated with the passed-in date
sub get_by_client {
    my $class = shift;
    my( $client_id, $date ) = @_;

    return unless $client_id;

    my $episode = $class->new( { client_id => $client_id, date => $date } );

    # if no intake_date is found, we're not in an episode
    return 
        unless $episode->intake_date;
    
    if( $episode->discharge_date ) {
    
        # if no date was passed in, and we found a discharge_date, we're not in an episode anymore
        return
            if !$date;
    
        # if discharge_date < date, the episode has finished and we're not currently in one
        $date =~ m/(\d+)-(\d+)-(\d+)/;
        my( $year, $month, $day ) = ($1, $2, $3); 
        $episode->discharge_date =~ m/(\d+)-(\d+)-(\d+)/;
        my( $dis_year, $dis_month, $dis_day ) = ($1, $2, $3); 
    
        return 
            if Date_to_Days( $dis_year, $dis_month, $dis_day )  <
               Date_to_Days( $year, $month, $day );
    }
   
    $episode->valid_episode( 1 );
    return $episode;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get all the events in the episode
sub events {
    my $self = shift;
    
    return unless $self->valid_episode;
   
    return $self->{ events }
        if $self->{ events };

    my $where  = " WHERE client_id = " . $self->client_id .
                 "   AND event_date >= " . $self->db->dbh->quote( $self->intake_date );
    
    # if there's no discharge date, we're in the middle of an un-ended episode
    $where .= " AND event_date <= " . $self->db->dbh->quote( $self->discharge_date )
        if $self->discharge_date;

    my $events = $self->db->select_many(
        ["*"],
        'client_placement_event',
        $where,
        'ORDER BY event_date DESC, rec_id DESC'
    );
     
    my @events;
    push @events => eleMentalClinic::Client::Placement::Event->new( $_ ) for @$events;

    $self->{ events } = \@events;
    return $self->{ events };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get the current episode intake_date, 
# or get the one associated with the passed-in date
#
# NOTE --- this is not a known valid intake_date until the 
# discharge_date has been checked against $self->date too
# --- and this is currently only done in get_by_client
sub intake_date {
    my $self = shift;

    return unless $self->client_id;

    return $self->{ intake_date }
        if $self->{ intake_date };
        
    my $date_filter = $self->date
        ? 'AND event_date <= ' . $self->db->dbh->quote( $self->date )
        : ''; # if no date passed in, get the most recent intake date
  
    my $where = 'client_id = ' . $self->client_id . " $date_filter AND intake_id is not null";
        
    my $intake_date = $self->db->select_one(
        [ 'MAX( event_date )' ],
        'client_placement_event',
        $where
    );

    $self->{ intake_date } = $intake_date->{ max };
    return $self->{ intake_date };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Find the discharge_date associated with the intake_date
sub discharge_date {
    my $self = shift;

    return unless $self->client_id and $self->intake_date;
   
    # TBD: if we've already looked before and there is none, we'll do the calc again.
    return $self->{ discharge_date }
        if $self->{ discharge_date };
    
    my $date_filter = 'AND event_date >= ' . $self->db->dbh->quote( $self->intake_date );
       
    my $where = qq/ client_id =  / . $self->client_id .
                qq/ $date_filter
                   AND (dept_id IS NULL AND
                     program_id IS NULL AND 
               level_of_care_id IS NULL AND
                       staff_id IS NULL) 
                 /;
        
    my $discharge_date = $self->db->select_one(
        [ 'MIN( event_date )' ],
        'client_placement_event',
        $where
    );

    $self->{ discharge_date } = $discharge_date->{ min };
    return $self->{ discharge_date };
}
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub referral {
    my $self = shift;
    
    return unless $self->valid_episode;
    
    return $self->{ referral }
        if $self->{ referral };

    # get the intake event first, which is the LAST event in the events array
    my $intake_event = $self->events->[ -1 ];
    $self->{ referral } = eleMentalClinic::Client::Referral->get_by_placement_event_id( $intake_event->{ rec_id } );
    return $self->{ referral };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub discharge {
    my $self = shift;

    return unless $self->valid_episode;

    return $self->{ discharge }
        if $self->{ discharge };
    # get the discharge event first, which is the FIRST event in the events array
    # assuming, of course, we have a discharge_date (checked above)
    my $discharge_event = $self->events->[ 0 ];
    $self->{ discharge } = eleMentalClinic::Client::Discharge->get_by_placement_event_id( $discharge_event->{ rec_id } );
    return $self->{ discharge };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub initial_diagnosis {
    my $self = shift;

    return unless
        my $diagnoses = $self->diagnoses;
    return eleMentalClinic::Client::Diagnosis->new( $diagnoses->[ 0 ]);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub final_diagnosis {
    my $self = shift;

    return unless
        my $diagnoses = $self->diagnoses;
    return unless @$diagnoses > 1; # means we only have initial
    return eleMentalClinic::Client::Diagnosis->new( $diagnoses->[ -1 ]);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub diagnoses {
    my $self = shift;

    return unless $self->valid_episode;
    my $where = "WHERE client_id = " . $self->client_id .
                "  AND diagnosis_date >= " . $self->db->dbh->quote( $self->intake_date );
    $where .=   "  AND diagnosis_date <= " . $self->db->dbh->quote( $self->discharge_date )
        if $self->discharge_date;

    my $diagnoses = $self->db->select_many(
        ["*"],
        'client_diagnosis',
        $where,
        'ORDER BY diagnosis_date, rec_id'
    );

    return unless $diagnoses; 
    return $diagnoses;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get the earliest event in an episode where program_id != 1
sub admit_date {
    my $self = shift;
   
    foreach my $event ( reverse @{$self->events} ) {
        
        if( $event->program_id > 1 ) {
            return $event->event_date;
        }
    }

    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get the earliest event in an episode where program_id = 1
sub referral_date {
    my $self = shift;
   
    foreach my $event ( reverse @{$self->events} ) {
        
        if( $event->program_id and $event->program_id == 1 ) {
            return $event->event_date;
        }
    }

    return;
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
