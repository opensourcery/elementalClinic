package eleMentalClinic::Client::Placement;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Placement

=head1 SYNOPSIS

Parent for client placement objects.  Consolidates these objects into a better API:

=over 4

=item eleMentalClinic::Client::Placement::Event

=item eleMentalClinic::Client::Placement::Episode

=back

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Carp;
use Data::Dumper;
use eleMentalClinic::Client::Placement::Event;
use eleMentalClinic::Client::Placement::Episode;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub fields { [ qw/ client_id date /] }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub event_methods {
    (
        @{ eleMentalClinic::Client::Placement::Event->fields },
        qw/
            program personnel level_of_care
        /
    );
}

sub episode_methods {
    (
        @{ eleMentalClinic::Client::Placement::Episode->fields },
        qw/
            intake_date referral discharge
            initial_diagnosis final_diagnosis
            admit_date referral_date
        /
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# creates, when requested, ::Placement methods to pass through to the
# current Placement::Event object.  caches those methods so they're
# only created once
sub AUTOLOAD {
    no strict;
    $AUTOLOAD =~ /.*::(\w+)$/;
    my $method = $1;
    
    die "Invalid method"
        unless $method;

    my $class;
    $class = ( grep /^$method$/ => event_methods()   ) ? 'event'
           : ( grep /^$method$/ => episode_methods() ) ? 'episode'
           :                                         croak "Invalid ::Event or ::Episode method: '$method'";
        
    *{ $method } = sub {
        my $self = shift;
        return unless $self->$class;
        return $self->$class->$method;
    };
    &$method( @_ );
}
sub DESTROY {}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_intake { 
    my $self = shift;

    $self->event->intake_id ? 1 : 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub event {
    my $self = shift;
    my( $args ) = @_;
    
    my $date;
    # if we want the current event, make sure we don't return the cached
    # event, and make sure we use the current date
    unless( $args and $args eq 'current' ) {
        return $self->{ event }
            if $self->{ event };
        $date = $self->date;
    }
    $self->{ event } = eleMentalClinic::Client::Placement::Event->get_by_client( $self->client_id, $date );
    return $self->{ event };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub episode {
    my $self = shift;
    
    return $self->{ episode }
        if $self->{ episode };
    $self->{ episode } = eleMentalClinic::Client::Placement::Episode->get_by_client( $self->client_id, $self->date );
    return $self->{ episode };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub active {
    my $self = shift;

    return unless $self->client_id;
    return 1 if $self->program_id;
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_admitted {
    my $self = shift;

    return unless $self->client_id;
    return 1 if $self->program_id and not $self->program->{ is_referral };
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_referral {
    my $self = shift;

    return unless $self->client_id;
    return 1 if $self->program_id and $self->program->{ is_referral };
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub was_referral {
    my $self = shift;

    return unless $self->client_id;
    return 1 if $self->db->select_one(
        [ 'client_id' ],
        'client_referral',
        'client_id = '. $self->client_id
    );
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME ? much meddling inside the object here.  hard to avoid
sub change {
    my $self = shift;
    my( %changes ) = @_;

    return unless $self->client_id and %changes;
    my @ok_fields = qw/
        dept_id program_id level_of_care_id staff_id
        event_date 
        level_of_care_locked active intake_id
        input_by_staff_id
    /;
    for my $field( keys %changes ) {
        die "Changes only allowed to the following fields ('$field'): ". join ', ' => @ok_fields
            unless grep /^$field$/ => @ok_fields;
    }

    # a previous note said "not sure of the repercussions of this"
    #$changes{intake_id} = undef unless exists $changes{intake_id};

    # preserve date
    my $date = $self->date;
    undef $self->{ date };

    my $event = $self->event;
    undef $event->{ rec_id };
  
    my $new = eleMentalClinic::Client::Placement::Event->new({ %$event, %changes, client_id => $self->client_id });
    $new->save;

    # reset date
    $self->{ date } = $date;

    $self->{ event } = $new;
    return $self->{ event };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# XXX we're not using this
sub edit {
    my $self = shift;
    my( %changes ) = @_;

    return unless $self->client_id and %changes;

    my $event = $self->event;
    my @ok_fields = qw/ program_id level_of_care_id staff_id event_date /;
    for my $field( keys %changes ) {
        die "Changes only allowed to the following fields ('$field'): ". join ', ' => @ok_fields
            unless grep /^$field$/ => @ok_fields;
        $event->$field( $changes{ $field });
    }
    $event->save;
    $self->{ event } = $event;
    return $self->{ event };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME: There is a more efficient way to do this, but this works for now.
sub episodes {
    my $self = shift;

    return unless $self->client_id;

    my $intake_dates = $self->db->select_many(
        ['event_date'],
        'client_placement_event',
        'WHERE intake_id is not null AND client_id = ' . $self->client_id,
        'ORDER BY event_date DESC, rec_id DESC'
    );

    return unless $intake_dates;

    my @episodes;
    for( @$intake_dates ){

        $self->{ date } = $_->{ event_date };
        $self->{ episode } = undef;
        push @episodes => $self->episode;
    }

    return \@episodes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub last_discharge {
    my $self = shift;
    
    my $episodes = $self->episodes;
    return unless $episodes;
    # if this episode doesn't have a discharge, the previous one either
    # does not exist or will
    return $episodes->[ 0 ]->discharge
        if $episodes->[ 0 ]->discharge;
    return $episodes->[ 1 ]->discharge
        if $episodes->[ 1 ] and $episodes->[ 1 ]->discharge;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub level_of_care_locked {
    my $self = shift;
    my( $locked ) = @_;
 
    return $self->event->level_of_care_locked
        unless defined $locked;

    $self->event->level_of_care_locked( $locked );
    $self->event->save;
    return $self->event->level_of_care_locked;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# necessary to fix a bug in which the local "staff_id" isn't propagated
# correctly before "personnel" is called
sub personnel {
    my $self = shift;
    return unless $self->staff_id;
    return eleMentalClinic::Personnel->retrieve( $self->staff_id );
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
