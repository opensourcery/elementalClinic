package eleMentalClinic::Client::Placement::Event;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Placement::Event

=head1 SYNOPSIS

One record in client's placement history within the clinic.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Client::Referral;
use eleMentalClinic::Client::Discharge;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_placement_event' }
    sub fields { [ qw/
        rec_id client_id dept_id program_id level_of_care_id
        staff_id event_date input_date
        level_of_care_locked intake_id discharge_id
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_intake {
    my $self = shift;
    $self->intake_id ? 1 : 0
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_by_client {
    my $class = shift;
    my( $client_id, $date ) = @_;

    return unless $client_id;
    my $date_filter = $date
        ? 'AND event_date <= '. $class->db->dbh->quote( $date )
        : '';
    my $events = $class->new->db->select_many(
        $class->fields,
        $class->table,
        "WHERE client_id = $client_id $date_filter",
        # rec_id DESC is really only for helping the tests, which will all end
        # up with the same event_date/input_date
        'ORDER BY event_date DESC, input_date DESC, rec_id DESC'
    );
    return unless $events;
    return $class->new( $events->[ 0 ]);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub program {
    my $self = shift;

    return unless $self->client_id and $self->program_id;
    return eleMentalClinic::ValidData->new({ dept_id => $self->dept_id })->get( '_program', $self->program_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub level_of_care {
    my $self = shift;

    return unless $self->client_id and $self->level_of_care_id;
    return eleMentalClinic::ValidData->new({ dept_id => $self->dept_id })->get( '_level_of_care', $self->level_of_care_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    my @fields = @{ $self->fields };
    my $class = ref $self;

    {
        # rewrite the 'fields' method on the fly
        # we do this to remove "input_date" from the fields list
        # so that the database can use its default value instead
        no strict qw/ refs /;
        no warnings qw/ redefine /;
        *{ "${ class }::fields" } = sub {[ grep !/^input_date$/ => @fields ]};
    }
    my $return = $self->SUPER::save;
    {
        # reset 'fields' to what it was before
        no strict qw/ refs /;
        no warnings qw/ redefine /;
        *{ "${ class }::fields" } = sub {[ @fields ]};
    }
    return $return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub referral {
    my $self = shift;

    return eleMentalClinic::Client::Referral->get_by_placement_event_id( $self->rec_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub discharge {
    my $self = shift;

    return eleMentalClinic::Client::Discharge->get_by_placement_event_id( $self->rec_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get the earliest date that this event can be moved to
sub previous_date_limit {
    my $self = shift;
    
    my $tables = "client_placement_event cpe";
    my $where;
    
    # event is intake, find the
    # previous discharge
    if( $self->is_intake ){
        $tables .= ", client_discharge";
        $where = "     cpe.client_id = " . $self->client_id .
                 " AND cpe.event_date < " . $self->db->dbh->quote( $self->event_date ) . 
                 " AND cpe.rec_id = client_discharge.client_placement_event_id ";
    }
    # event is disharge, find the
    # previous event
    elsif( $self->discharge ) {
        $where = "     cpe.client_id = " . $self->client_id .
                 " AND cpe.event_date < " . $self->db->dbh->quote( $self->event_date );
    }
    # event is just a change event, find the
    # previous intake
    else {
        $where = "     cpe.client_id = " . $self->client_id .
                 " AND cpe.event_date <  " . $self->db->dbh->quote( $self->event_date ) .
                 " AND cpe.intake_id is not null ";
    }
    
    my $date = $self->db->select_one(
        ['MAX(cpe.event_date)'],
        $tables,
        $where
    );
    return $date->{ max };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get the latest date that this event can be moved to
sub next_date_limit {
    my $self = shift;

    my $tables = "client_placement_event cpe";
    my $where;
    
    # event is intake, find the
    # next event
    if( $self->is_intake ){
        $where = "     cpe.client_id = " . $self->client_id .
                 " AND cpe.event_date > " . $self->db->dbh->quote( $self->event_date );
    }
    # event is disharge, find the
    # next intake event
    elsif( $self->discharge ) {
        $where = "     cpe.client_id = " . $self->client_id .
                 " AND cpe.event_date > " . $self->db->dbh->quote( $self->event_date ) .
                 " AND cpe.intake_id is not null";
    }
    # event is just a change event, find the
    # next discharge
    else {
        $tables .= ", client_discharge";
        $where = "     cpe.client_id = " . $self->client_id .
                 " AND cpe.event_date > " . $self->db->dbh->quote( $self->event_date ) .
                 " AND cpe.rec_id = client_discharge.client_placement_event_id ";
    }

    my $date = $self->db->select_one(
        ['MIN(cpe.event_date)'],
        $tables,
        $where
    );
    return $date->{ min };
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
