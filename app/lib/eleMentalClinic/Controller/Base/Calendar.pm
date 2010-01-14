package eleMentalClinic::Controller::Base::Calendar;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Calendar

=head1 SYNOPSIS

Base Calendar Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'calendar' ],
        javascripts  => [
            'calendar.js',
        ],
    });
    $self->override_template_path( 'global' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        popup => {
            cid             => [ 'Calendar', 'required' ],
            current_date    => [ 'Current date', 'required' ],
            date_format     => [ 'Date format', 'required' ],
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub popup {
    my $self = shift;

    $self->override_template_name( 'calendar_popup' );
    return {
        cid             => $self->param( 'cid' ),
        current_date    => $self->param( 'current_date' ),
        date_format     => $self->param( 'date_format' ),
    };
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

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
