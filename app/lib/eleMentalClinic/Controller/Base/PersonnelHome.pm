package eleMentalClinic::Controller::Base::PersonnelHome;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::PersonnelHome

=head1 SYNOPSIS

Base PersonnelHome Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'index.cgi',
        styles => [ 'layout/3366', 'gateway' ],
        javascripts  => [ 'client_filter.js', 'calendar.js' ],
    });
    $self->override_template_path( 'gateway' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        save_home_page_type => {
            home_page_type  => [ 'Home page type', 'required', 'text::word' ],
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Abstract out redirects so that subclassing themes that do not have them can
# simply override this instead of home()

sub home_redirects {
    my $self = shift;
    if( $self->current_user->home_page_type eq 'financial' ) {
        return 'financial';
    }
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;

    if( my $redirect = $self->home_redirects ) {
        return $self->redirect_to( $redirect );
    }

    my %vars = (
        search      => $self->param( 'search' ) || '',
        clients     => $self->current_user->filter_clients || '',
    );

    $vars{ reminders } = $self->get_reminders
        if $self->current_user->pref->user_home_show_visit_frequency_reminders;
    $self->override_template_name( 'home' );
    return \%vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_home_page_type {
    my $self = shift;

    if( $self->current_user->admin ) {
        $self->current_user->home_page_type( $self->param( 'home_page_type' ));
        $self->current_user->save;
    }
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_reminders {
    my $self = shift;

    my( @treatment_plans, @assessments, @overdue_clients );

    my $treatmentplans = $self->current_user->get_treatmentplans({ year_old => 1 });
    foreach my $plan ( @$treatmentplans ){
        my $client = eleMentalClinic::Client->new({ client_id => $plan->{ client_id } })->retrieve;
        next unless $client->placement->active; 
        push @treatment_plans => {
            client  => $client,
            plan    => $plan,
        };
    }

    my $assessments = $self->current_user->get_assessments({ year_old => 1 });
    foreach my $one ( @$assessments ){
        my $client = eleMentalClinic::Client->new({ client_id => $one->client_id })->retrieve;
        next unless $client->placement->active; 
        push @assessments => {
            client      => $client,
            assessment  => $one,
        };
    }
    
    my $overdue_clients = $self->current_user->get_overdue_clients;
    foreach my $one ( @$overdue_clients ) {
        my $client = eleMentalClinic::Client->new({ client_id => $one->{ client_id } })->retrieve;
        next unless $client->placement->active; 
        push @overdue_clients => {
            client  => $client,
            overdue => $one,
        };
    }

    return {
        treatment_plans => \@treatment_plans,
        assessments     => \@assessments,
        overdue_clients => \@overdue_clients,
    };
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

=item Ryan Whitehurst L<ryan@opensourcery.com>

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
