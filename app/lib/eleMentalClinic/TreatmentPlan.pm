package eleMentalClinic::TreatmentPlan;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::TreatmentPlan

=head1 SYNOPSIS

Parent of L<eleMentalClinic::TreatmentGoal>; a treatment plan assists a client in solving problems.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::TreatmentGoal;
use eleMentalClinic::Client;
use Date::Calc qw/ Today Add_Delta_Days Parse_Date /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'tx_plan' }
    sub fields { [ qw/
        client_id chart_id 
        staff_id rec_id start_date end_date 
        period esof_id esof_date esof_name
        esof_note
        assets debits case_worker src_worker supervisor
        meets_dsm4 needs_selfcare needs_skills
        needs_support needs_adl needs_focus
        active
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my $self = shift;
    my ( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;
    my $class = ref $self;
    
    my $where = "WHERE client_id = $client_id AND active = 1";
    my $order_by = "ORDER BY start_date DESC";
    my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results if @results;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_staff_all {
    my $self = shift;
    my $args = shift;
    my $class = ref $self;
    
    my $staff_id = $args->{ staff_id };
    return unless $staff_id;
    
    my $where = "WHERE staff_id = $staff_id AND active = 1";
    $where .= "  AND end_date < ( now() - INTERVAL '1 YEAR') " if $args->{ year_old };
    my $order_by = "ORDER BY start_date DESC";
    
    my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results if @results;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub goals {
    my $self = shift;
    my ( $rec_id ) = @_;
    $rec_id ||= $self->rec_id;
    return unless $rec_id;
    my $class = ref $self;
    
    eleMentalClinic::TreatmentGoal->empty({
        plan_id => $rec_id,
    })->get_all;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    my( $staff_id ) = @_;
    return unless $self->client_id and ($staff_id or $self->staff_id);

    my $client = eleMentalClinic::Client->new({
        client_id => $self->client_id,
    })->retrieve;

    $self->staff_id( $staff_id ) unless $self->staff_id;
    unless( $self->start_date ) {
        my( $year, $month, $day ) = Today;
        $self->start_date( "$year-$month-$day" );
    }
    
    unless( $self->end_date ) {
        # add the default from config 
        my( $year, $month, $day ) = Add_Delta_Days(
            split( '-', $self->start_date), #Should be normalized by now
            (( $self->config->tx_plan_period_default) * 30 )
        );
        $self->end_date( "$year-$month-$day" );
    }
    
    $self->period( $self->start_date .' - '. $self->end_date );
    $self->SUPER::save($self);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub clone {
    my $self = shift;
    my( $clone_goals ) = @_;

    my $plan = $self->SUPER::clone;
    my $self_goals = $self->goals;
    return $plan
        unless $clone_goals and @$clone_goals
        and $self_goals and @$self_goals;

    for my $goal( @$self_goals ) {
        my $id = $goal->rec_id;
        next unless grep /$id/ => @$clone_goals;
        my $new_goal = $goal->clone;
        $new_goal->plan_id( $plan->rec_id );
        $new_goal->save;
    }

    $plan;
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
