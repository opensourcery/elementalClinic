package eleMentalClinic::Controller::Base::Inpatient;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Inpatient

=head1 SYNOPSIS

Base Inpatient Controller.

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
        styles => [ 'layout/6633', 'hospitalizations', 'date_picker' ],
        javascripts => [ 'jquery.js', 'date_picker.js' ],
        script => 'hospitalizations.cgi',
    });
    $self->override_template_path( 'hospitalizations' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        save => {
            client_id       => [ 'Client', 'required' ],
            comment_text    => [ '', 'text::liberal' ],
            reason          => [ '', 'text::liberal' ],
            voluntary       => [ '', 'checkbox::boolean' ],
            state_hosp      => [ '', 'checkbox::boolean' ],
            start_date      => [ 'Start date', 'date::iso' ],
            end_date        => [ 'End date', 'date::iso' ],
        },
        edit => {
            rec_id          => [ 'Record ID', 'required' ],
        },
        view => {
            rec_id          => [ 'Record ID', 'required' ],
        },
        create => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $current ) = @_;

    $self->override_template_name( 'home' );
    return {
        current => $current,
        op      => $self->op,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub view {
    my $self = shift;

    my $current = eleMentalClinic::Client::Inpatient->new({
        rec_id   => $self->param( 'rec_id' )})->retrieve;
    $self->home( $current );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
    my $self = shift;
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    $self->date_check( 'start_date','end_date' );
    my $current = $self->Vars;
    unless( $self->errors ){
        $current = eleMentalClinic::Client::Inpatient->new( $current );
        $current->save;
    }
    $self->home( $current );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;

    my $current = eleMentalClinic::Client::Inpatient->new({
        rec_id   => $self->param( 'rec_id' )})->retrieve;
    $self->home( $current );
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
