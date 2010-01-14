package eleMentalClinic::TreatmentGoal;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::TreatmentGoal

=head1 SYNOPSIS

Child of L<eleMentalClinic::reatmentPlan>; a treatment plan is implemented by a series of goals.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use Date::Calc qw/ Today Add_Delta_Days /;
use eleMentalClinic::Personnel;
use eleMentalClinic::Util;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'tx_goals' }
    sub fields { [ qw/
        client_id staff_id problem_description
        plan_id rec_id medicaid start_date end_date 
        goal goal_stat goal_header eval comment_text
        goal_code rstat serv audit_trail goal_name active
    /] }
    sub fields_required { [ qw/ client_id staff_id plan_id /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my ( $self, $plan_id ) = @_;
    $plan_id ||= $self->plan_id;
    return unless $plan_id;
    my $class = ref $self;
    
    my $where = "WHERE plan_id = $plan_id AND active = 1";
    my $order_by = "ORDER BY start_date DESC";
    return unless my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    return unless $self->client_id
        and $self->staff_id 
        and $self->plan_id;

    $self->start_date( $self->today )
        unless $self->start_date;
    
    unless( $self->end_date ) {
        my $delta = $self->config->tx_plan_period_default || 0;
        $self->end_date( $self->today, "+${ delta }d" )
    }

    my $login = eleMentalClinic::Personnel->new({
        staff_id => $self->staff_id,
    })->retrieve->login;

    $self->rstat(0);

    $self->SUPER::save($self);
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
