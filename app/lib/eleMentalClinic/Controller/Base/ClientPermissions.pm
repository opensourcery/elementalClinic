package eleMentalClinic::Controller::Base::ClientPermissions;
use strict;
use warnings;

use eleMentalClinic::Role::ClientPermission;
use eleMentalClinic::Personnel;

=head1 NAME

eleMentalClinic::Controller::Default::ClientPermissions

=head1 SYNOPSIS

Add and remove client->staff associations

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/6633', 'clientpermissions', 'gateway' ],
        script => 'clientpermissions.cgi',
        javascripts => [ 'jquery.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        remove => {
            staff_id => [ 'Personnel', 'number::integer' ],
        },
        add => {
            -alias => 'Grant',
            staff_id => [ 'Personnel', 'number::integer' ],
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub home {
    my $self = shift;

    return {
        permissions => $self->client->access,
        unassociated => $self->unassociated,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub add {
    my $self = shift;

    return unless $self->current_user->admin;

    my $personnel = $self->personnel;
    $personnel->primary_role->grant_client_permission( $self->client->id );

    $self->override_template_name( 'home' );
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub remove {
    my $self = shift;

    return unless $self->current_user->admin;

    my $personnel = $self->personnel;
    $personnel->primary_role->revoke_client_permission( $self->client->id );

    $self->override_template_name( 'home' );
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub personnel {
    my $self = shift;
    my $staff_id = $self->param( 'staff_id' );
    return unless $staff_id;
    return eleMentalClinic::Personnel->retrieve( $staff_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub unassociated {
    my $self = shift;
    return [
        map {{
            staff_id => $_->staff_id,
            name => $_->lname . ", " . $_->fname,
        }} grep { ! $_->primary_role->has_direct_client_permission( $self->client->id ) }
            @{ eleMentalClinic::Personnel->get_all }
    ];
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2009 OpenSourcery, LLC

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
