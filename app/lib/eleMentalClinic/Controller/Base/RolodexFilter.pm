=head1 eleMentalClinic::DispatchConfig

Rolodex Filter controller

=cut

package eleMentalClinic::Controller::Base::RolodexFilter;

use strict;
use warnings;

use base qw/ eleMentalClinic::CGI /;
use Data::Dumper;
use eleMentalClinic::Rolodex;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    if( $self->param( 'role_name' ) and $self->param( 'role_name' ) =~ /insurance/ ) {
        $self->session->param( client_insurance_rolodex_filter => $self->param( 'role_name' ));
        $self->template->vars({ script => 'insurance.cgi' });
    }
    else {
        $self->template->vars({ script => 'rolodex.cgi' });
    }
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;

    $self->ajax(1);

    my $role_name = $self->param( 'role_name' ) || 'contacts';
    my $current_role = eleMentalClinic::Rolodex->new->roles( $role_name );

    $self->current_user->pref->rolodex_filter( $current_role->{ name } );
    $self->current_user->pref->save;

    $self->template->process_page( 'rolodex/rolodex_entries', {
            current_role    => $current_role,
            rolodex_entries => $self->get_rolodex_entries,
        });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_rolodex_entries {
    my $self = shift;

    eleMentalClinic::Rolodex->new->get_byrole(
        $self->param( 'role_name' ),
        $self->param( 'client_id' ),
    );
}

1;

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Erik Hollensbe L<erikh@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see
L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for
known bugs.

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

=cut
