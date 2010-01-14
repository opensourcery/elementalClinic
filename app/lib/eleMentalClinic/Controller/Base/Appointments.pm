package eleMentalClinic::Controller::Base::Appointments;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Venus::Appointments

=head1 SYNOPSIS

Base Appointments Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use Data::Dumper;
use eleMentalClinic::Schedule::Appointments;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/5050', 'gateway', 'date_picker' ],
        script => 'appointments.cgi',
		javascripts  => [ 'client_filter.js', 'jquery.js', 'date_picker.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        save => {},
        edit => {},
        remove => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $current ) = @_;

    $self->template->process_page( 'schedule/home', {
        current => $current,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    my $current = $self->Vars;

	
    if( $self->errors ) {
        $self->home( $current );
    }
    else {
		my $hour = int($current->{ appt_time });
		my $mins = ($current->{ appt_time } - $hour) * 60;
		
		my $time = "$hour:$mins";

		$current->{ appt_time } = $time;
		$current->{ personnel_id } = $self->current_user->staff_id;
		
        eleMentalClinic::Schedule::Appointments->new( $current )->save;
        $self->home;
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;

    my $current = eleMentalClinic::Schedule::Appointments->new({
        rec_id   => $self->param( 'rec_id' )})->retrieve;
    $self->home( $current );
}

sub remove {
    my $self = shift;
    
    my $current = eleMentalClinic::Schedule::Appointments->new({
        rec_id   => $self->param( 'rec_id' )})->retrieve;
    
    $current->db->delete_one('schedule_appointments','rec_id = '.$current->{ rec_id });
    $self->home;
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
