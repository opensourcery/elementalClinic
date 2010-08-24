# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Controller::Venus::Rolodex;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Venus::Rolodex

=head1 SYNOPSIS

Rolodex Controller for Venus theme.

=head1 METHODS

=cut

use Moose;
extends 'eleMentalClinic::Controller::Base::Rolodex';

my @ROLES = ( qw/ contacts dental_insurance employment medical_insurance mental_health_insurance referral treaters /);

sub common_styles { 'layout/00', 'rolodex', 'gateway' }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias => 'Cancel',
        },
        rolodex_new => {
            -alias => 'New Doctor',
        },
        rolodex_edit => {
            -alias => 'Edit Doctor',
        },
        rolodex_save => {
            -alias => ['Save Doctor', 'Save Doctor, ignoring duplicates'],
            lname   => [ 'Last name', 'required', 'text::liberal', 'length(0,30)' ],
            fname   => [ 'First name', 'required', 'text::words', 'length(0,30)' ],
            state   => [ 'State', 'demographics::us_state2' ],
            post_code   => [ 'Zip code', 'number::integer', 'length(0,10)' ],
            address1 => [ 'Address', 'text::hippie', 'length(0,255)' ],
            address2 => [ 'Address 2', 'text::hippie', 'length(0,255)' ],
            city => [ 'City', 'length(0,255)' ],
            phone => [ 'Phone', 'length(0,25)' ],
            phone_2 => [ 'Second Phone', 'length(0,25)' ],
            name => [ 'Organization', 'length(0,80)' ],
            credentials => [ 'Credentials', 'length(0,80)' ],
            license_wa  => [ 'WA License', 'length(0,80)' ],
            license_or  => [ 'OR License', 'length(0,80)' ],
            license_ca  => [ 'CA License', 'length(0,80)' ],
        },
    )
}

sub home_javascripts { $_[0]->SUPER::home_javascripts, 'date_picker.js' }

sub home_styles { 'date_picker' }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex_edit {
    my $self = shift;
    my( $rolodex, $dupsok ) = @_;

    $dupsok ||= 0;

    $rolodex ||= $self->get_rolodex;
    my $in_roles;
    if( $self->errors and $self->roles_exist ) { # and ! $rolodex->{ rec_id } ) {
        for( @ROLES ) {
            $in_roles->{ $_ } = $self->param( $_ );
        }
    }

    my $schedule_type_id = $rolodex->schedule()->get_schedule_type($self->param( 'rolodex_id' )) if $rolodex->{ rec_id };

    $self->override_template_name( 'home' );

    return {
        $self->expand_rolodex( $rolodex ),
        rolodex_roles   => eleMentalClinic::Rolodex->new->roles,
        rolodex_entries => $self->list_rolodex_entries,
        op              => $self->op,
        in_roles        => $in_roles,
        dupsok          => $dupsok,
        schedule_type_id => $schedule_type_id,
    };

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex_save {
    my $self = shift;

    my $cleanvars = $self->Vars;
    delete $cleanvars->{ client_id };

    # Prepare $vars to be a prototype for our new rolodex
    my $vars = $cleanvars;
    $vars->{ rec_id } = $vars->{ rolodex_id };

    # Look for duplicates
    my $rolodex = eleMentalClinic::Rolodex->new( $vars );
    $rolodex->dept_id( $self->current_user->dept_id );

    unless ( $self->errors ) {
        my $rv = $self->_check_duplicates( $rolodex );
        return $rv if $rv;

        $rolodex->save;

        $self->save_phones(
            $rolodex,
            $vars,
            [ qw(phone phone_2) ],
        );

        $self->save_licenses(
            $rolodex,
            $vars
        );

        # don't use $vars, it's been fiddled with e.g. adding rec_id
        # But it also removes client_id, which is critical, now we have
        # $cleanvars for this.
        $self->save_address( $rolodex, $cleanvars );

        my $schedule = $rolodex->schedule;
        $schedule->set_schedule_type( $vars->{ schedule_type } );

        $self->_add_and_remove_roles( $rolodex, $vars );
        $rolodex = eleMentalClinic::Rolodex->retrieve( $rolodex->id );
    }

    $self->override_template_name( 'home' );
    return {
        %{ $self->rolodex_edit( $rolodex )},
        $self->expand_rolodex( $rolodex ),
        phone_1 => $self->param( 'phone' ),
    };
}


# Save each license_state entry as a ByState object
sub save_licenses {
    my $self = shift;
    my($rolodex, $vars) = @_;

    my $all = $rolodex->all_by_state;

    for my $key (grep /^license_/, keys %$vars) {
        my $val = $vars->{$key};
        my($state) = uc( (split /_/, $key)[-1] );

        my $by_state = $all->{$state};

        if( $val ) {
            if( $by_state and $val ne $by_state->license ) {
                $by_state->license($val);
                $by_state->save;
            }
            else {
                $rolodex->add_by_state($state, { license => $val });
            }
        }
        else {
            next unless $by_state;

            $by_state->license('');
            $by_state->save;
        }
    }
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub relationship_new {
    my $self = shift;
    $self->relationship_edit( undef, $self->get_rolodex );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_rolodex {
    my $self = shift;
    my $rolodex_id = $self->param( 'rolodex_id' );
    return eleMentalClinic::Rolodex->retrieve( $rolodex_id ) if $rolodex_id;
    return eleMentalClinic::Rolodex->new;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_rolodex_entries {
    my $self = shift;

    return eleMentalClinic::Rolodex->new->get_byrole( 'treaters' );
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

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
