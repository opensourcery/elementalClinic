package eleMentalClinic::Controller::Venus::Personnel;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Venus::Personnel

=head1 SYNOPSIS

Personnel Controller for Venus theme.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Controller::Base::Personnel /;

my @SECURITY_ONLY = qw/ login password security /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_security {
    my $self = shift;

    $self->add_error( 'password1', 'password1', '<strong>Password</strong> and <strong>verify password</strong> must match.' )
        if(
            ( $self->param( 'password1' ) or $self->param( 'password2' )) 
            and( $self->param( 'password1' ) ne $self->param( 'password2' ))
        );
    if( $self->errors ) {
        $self->override_template_name( 'home' );
        return {
            op => 'save_security',
            current => $self->get_personnel,
        };
    }

    my $person = $self->get_personnel;
    $person->login( $self->param( 'login' ));

    if( $self->param( 'password1' )) {
        $person->update_password( $person->crypt_password(
            $person->login,
            $self->param( 'password1' ),
        ));
    }

    $person->password_expired( $self->param( 'password_expired' ));

    for my $role (@{ $person->security_roles }) {
        # We don't want to change this
        next if $role->name eq 'financial' or $role->name eq 'supervisor';
        my $value = $self->param( 'role_' . $role->id );

        my $action = $value ? 'add_member' : 'del_member';

        $role->$action( $person->primary_role );
    }

    $person->save;

    $self->home( $person );
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
