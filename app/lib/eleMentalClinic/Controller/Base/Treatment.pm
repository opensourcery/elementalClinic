package eleMentalClinic::Controller::Base::Treatment;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Treatment

=head1 SYNOPSIS

Base Treatment Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::TreatmentPlan;
use eleMentalClinic::TreatmentGoal;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'treatment.cgi',
        javascripts  => [
            'treatment.js',
            'jquery.js',
            'date_picker.js'
        ],
        styles => [ 'layout/3366', 'treatment', 'date_picker' ],
    });

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias => [ 'Cancel', 'View Goals' ],
        },
        plan_view => {
            -alias          => 'View Plan',
        },
        plan_clone => {
            -alias          => 'Clone Plan',
        },
        plan_clone_save => {},
        plan_new => {},
        plan_save => {
            -alias          => 'Save Plan',
            start_date      => [ 'Start date', 'required', 'date::iso' ],
            end_date        => [ 'End date', 'date::iso' ],
            meets_dsm4      => [ 'Has DSM IV', 'checkbox::boolean' ],
            needs_selfcare  => [ 'Needs self-care', 'checkbox::boolean' ],
            needs_skills    => [ 'Needs social skills', 'checkbox::boolean' ],
            needs_support   => [ 'Needs psych support', 'checkbox::boolean' ],
            needs_adl       => [ 'Needs ADL', 'checkbox::boolean' ],
            needs_focus     => [ 'Needs focus', 'checkbox::boolean' ],
            assets          => [ 'Strengths' ],
            debits          => [ 'Weaknesses' ],
        },
        plan_print => {
            -alias          => 'Print Plan',
        },
        plan_edit => {
            -alias          => 'Edit Plan',
        },
        goal_new => {},
        goal_save => {
            -alias      => 'Save Goal',
            goal_name   => [ 'Goal name', 'required', 'length(1,250)', 'text' ],
            start_date      => [ 'Start date', 'required', 'date::iso' ],
            end_date        => [ 'End date', 'date::iso' ],
            problem_description => [ 'Problem' ],
            eval                => [ 'Evaluation' ],
            serv                => [ 'Services provided' ],
            goal                => [ 'Objective' ],
            comment_text        => [ 'Comments' ],
        },
        goal_edit => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $plan ) = @_;

    $self->template->process_page( 'treatment/home', {
        current => $plan,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub plan_view {
    my $self = shift;

    my $plan = $self->get_plan;
    $self->home( $plan );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub plan_clone {
    my $self = shift;

    my $plan = $self->get_plan;
    $self->template->process_page( 'treatment/plan_clone', {
        current => $plan,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub plan_print {
    my $self = shift;
    my( $plan_id ) = @_;

    my $plan = $self->get_plan;
    $self->template->vars({
        styles => [ 'treatment', 'report', 'report_print_new' ],
        print_styles => [ 'treatment', 'report_print_new' ],
    });

    $self->template->process_page( 'treatment/plan_print', {
        current => $plan,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub plan_new {
    my $self = shift;

    $self->template->vars({
        styles => [ 'layout/5050', 'treatment', 'date_picker' ],
    });

    $self->template->process_page( 'treatment/plan_edit', {
        action  => 'Create',
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub plan_save {
    my $self = shift;

    my $vars = $self->Vars;
    $vars->{ staff_id } = $self->current_user->id;
    $vars->{ active } = 1;
    $self->date_check( 'start_date', 'end_date' );
    unless( $self->errors ) {
        my $plan = eleMentalClinic::TreatmentPlan->new( $vars );
        $plan->save;
        $self->home( $plan );
    }
    else {
        $self->plan_edit( $vars );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub plan_clone_save {
    my $self = shift;

    my $plan = $self->get_plan;

    my @goals;
    for( keys %{ $self->Vars } ) {
        next unless $_ =~ /^goal_clone_(\d+)$/;
        push @goals => $1;
    }
    my $clone = $plan->clone( \@goals );
    $clone->start_date( $self->today );
    $clone->end_date( '' );
    $clone->save;
    $self->plan_edit( $clone );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub plan_edit {
    my $self = shift;
    my( $plan ) = @_;

    unless( $plan ) {
        $plan = eleMentalClinic::TreatmentPlan->new({
            rec_id => $self->param( 'plan_id' )})->retrieve;
    }

    $self->template->vars({
        styles => [ 'layout/5050', 'treatment', 'date_picker' ],
    });

    $self->template->process_page( 'treatment/plan_edit', {
        current => $plan,
        action  => 'Edit',
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub goal_new {
    my $self = shift;

    my $plan = eleMentalClinic::TreatmentPlan->new({
        rec_id => $self->param( 'plan_id' ) })->retrieve;

    $self->template->process_page( 'treatment/goal_edit', {
        plan    => $plan,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub goal_edit {
    my $self = shift;
    my( $goal ) = @_;

    $goal ||= $self->get_goal;
    my $plan = $self->get_plan;

    $self->template->process_page( 'treatment/goal_edit', {
        plan    => $plan,
        current => $goal,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub goal_save {
    my $self = shift;

    unless( $self->errors ) {
        my $vars = $self->Vars;
        $vars->{ staff_id } = $self->current_user->id;
        $vars->{ active } = 1;
        $vars->{ rec_id } = $vars->{ goal_id };

        my $goal = eleMentalClinic::TreatmentGoal->new( $vars );
        $goal->save;

        my $plan = $self->get_plan;
        $self->home( $plan );
    }
    else {
        my $vars = $self->Vars;
        $vars->{ rec_id } = $vars->{ goal_id };
        $self->goal_edit( $vars );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_plan {
    my $self = shift;
    my( $plan_id ) = @_;
    $plan_id ||= $self->param( 'plan_id' );
    eleMentalClinic::TreatmentPlan->retrieve( $plan_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_goal {
    my $self = shift;
    eleMentalClinic::TreatmentGoal->retrieve( $self->param( 'goal_id' ));
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
