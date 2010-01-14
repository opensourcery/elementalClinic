# vim: ts=4 sts=4 sw=4
# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
package eleMentalClinic::Controller::Base::Rolodex;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Rolodex

=head1 SYNOPSIS

Base Rolodex Controller.

=head1 METHODS

=cut

use Moose;
extends qw/ eleMentalClinic::CGI::Rolodex /;
use eleMentalClinic::Contact::Phone;
use eleMentalClinic::Contact::Address;

my @ROLES = ( qw/ contacts dental_insurance employment medical_insurance mental_health_insurance referral treaters /);

sub common_styles { 'layout/00', 'rolodex_filter', 'rolodex', 'date_picker' }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'rolodex.cgi',
        styles => [ $self->common_styles ],
        javascripts => [ 'jquery.js', 'date_picker.js' ]
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias => 'Cancel',
        },
        rolodex_new => {
            -alias => 'New Rolodex',
        },
        rolodex_edit => {
            -alias => 'Edit Rolodex',
            private => [ 'Private', 'checkbox::boolean' ],
        },
        rolodex_save => {
            -alias => ['Save Rolodex', 'Save Rolodex, ignoring duplicates'],
            state => [ 'State', 'demographics::us_state2' ],
            generic => [ 'Is generic', 'checkbox::boolean' ],
            address1 => [ 'Address', 'text::liberal', 'length(0,75)' ],
            contacts => [ 'Contacts role', 'checkbox::boolean' ],
            dental_insurance => [ 'Dental insurance role', 'checkbox::boolean' ],
            employment => [ 'Employer role', 'checkbox::boolean' ],
            medical_insurance => [ 'Medical insurance role', 'checkbox::boolean' ],
            mental_health_insurance => [ 'Mental health insurance role', 'checkbox::boolean' ],
            referral => [ 'Referral source', 'checkbox::boolean' ],
            treaters => [ 'Treater role', 'checkbox::boolean' ],
        },
        relationship_edit => {
            -alias => 'Edit Relationship',
        },
        relationship_save => {
            -alias => 'Save Relationship',
            co_pay_amount       => [ 'Co-pay', 'number::decimal' ],
            deductible_amount   => [ 'Deductible', 'number::decimal' ],
            start_date   => [ 'Start date', 'date::iso' ],
            end_date   => [ 'End date', 'date::iso' ],
            auth_start_date   => [ 'Authorization start date', 'date::iso' ],
            auth_end_date   => [ 'Authorization end date', 'date::iso' ],
            insured_dob   => [ 'Insured birthdate', 'date::iso' ],
            last_visit   => [ 'Last visit', 'date::iso' ],
            active => [ 'Active', 'checkbox::boolean' ],
        },
        relationship_new => {},
    )
}

#         $self->current_user->pref->rolodex_filter( $self->param( 'rolodex_filter' ));
#         $self->current_user->pref->save;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $op ) = @_;

    my $client = $self->client;
    my $rolodex = $self->get_rolodex;

    my $rolodex_filter = $self->current_user->pref->rolodex_filter || 'contacts';
    my $current_role = $rolodex->roles( $rolodex_filter );

    $self->template->vars({
        javascripts  => [ $self->home_javascripts ],
        styles       => [ $self->common_styles, $self->home_styles ],
    });

    $self->override_template_name( 'home' );
    return {
        $self->expand_rolodex( $rolodex ),
        rolodex_entries => $self->list_rolodex_entries,
        op              => $op ||= $self->op,
        current_role    => $current_role,
        all_role_names  => [ map { $_->{ name }} @{ eleMentalClinic::Rolodex->new->roles }],
    };
}

sub home_javascripts { qw(rolodex_filter.js jquery.js date_picker.js) }

sub home_styles { () }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex_new {
    my $self = shift;
    $self->rolodex_edit;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex_edit {
    my $self = shift;
    my( $rolodex, $dupsok ) = @_;

    $dupsok ||= 0;
    
    $rolodex ||= $self->get_rolodex;
    $rolodex->{ rec_id } = $self->param( 'rolodex_id' );
    my $in_roles;
    if( $self->errors and $self->roles_exist ) { # and ! $rolodex->{ rec_id } ) {
        for( @ROLES ) {
            $in_roles->{ $_ } = $self->param( $_ );
        }
    }

    $self->override_template_name( 'home' );

    return {
        rolodex         => $rolodex,
        rolodex_roles   => eleMentalClinic::Rolodex->new->roles,
        op              => $self->op,
        in_roles        => $in_roles,
        dupsok          => $dupsok,
        claims_processors => eleMentalClinic::Financial::ClaimsProcessor->get_all,
    };

}

sub _check_duplicates {
    my ( $self, $rolodex ) = @_;

    my $duplicates = $rolodex->dup_check;

    if( $duplicates->{ name } ) {
        my $error = "There is already a rolodex entry with the name <strong>$rolodex->{ name }</strong>. ";
        $error .= "To ignore duplicates, click 'Save Rolodex, ignoring duplicates'.";
        $self->add_error( 'name', 'name', $error );
        return $self->rolodex_edit({ $self->Vars }, 'dupsok');
    }
    elsif( $duplicates->{ fname_lname_cred } and ! $self->param( 'dupsok' )) {
        my $error = "There is already a rolodex entry with the name <strong>$rolodex->{ fname } $rolodex->{ lname } $rolodex->{ credentials }</strong>. ";
        $error .= "To ignore duplicates, click 'Save Rolodex, ignoring duplicates'.";
        $self->add_error( 'fname', 'fname_lname_cred',  $error );
        return $self->rolodex_edit({ $self->Vars }, 'dupsok');
    }
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex_save {
    my $self = shift;

    $self->add_error( 'contacts', 'contacts', 'You must select at least one role.' )
        unless $self->roles_exist;

    $self->add_error( 'name', 'name', 'You must enter an organization, or a first name and a last name.' )
        unless $self->param( 'name' ) or ($self->param( 'fname' ) and $self->param( 'lname' ));

    if( $self->errors ) {
        my $vars = { $self->Vars };

        # Address is now a property of a rolodex, and each line is a sub
        # property fo that, this mapping is required to preserve data on form
        # error.
        $vars->{ address } = {};
        for my $addrline (qw/ address1 address2 post_code city state /) {
            $vars->{ address }->{ $addrline } = $vars->{ $addrline };
        }
        $vars->{ phone } = { phone_number => $vars->{ phone_number }};

        return $self->rolodex_edit($vars);
    }
    else {
        my $vars = $self->Vars;

        $vars->{ rec_id } = $vars->{ rolodex_id };
        delete $vars->{ client_id };

        my $rolodex = eleMentalClinic::Rolodex->new( $vars );
        my $edit = $self->_check_duplicates( $rolodex );
        return $edit if $edit;

        $rolodex->dept_id( $self->current_user->dept_id );
        $rolodex->save;
        #$rolodex->retrieve;
        $self->_add_and_remove_roles( $rolodex, $vars );
#             $rolodex->remove_role( 'mental_health_insurance' );

        $vars->{ rec_id } = $rolodex->id unless $vars->{ rolodex_id };
        $self->save_phone( $rolodex, $vars->{phone_number} );
        $self->save_address( $rolodex, $vars );

        $self->override_template_name( 'home' );

        return $self->home;
    }
}

sub _add_and_remove_roles {
    my ( $self, $rolodex, $vars ) = @_;
    for( @ROLES ) {
        $vars->{ $_ }
            ? $rolodex->add_role( $_ )
            : $rolodex->remove_role( $_ );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub relationship_new {
    my $self = shift;
    $self->override_template_name( 'relationship_edit' );
    $self->relationship_edit( undef, $self->get_rolodex );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub relationship_edit {
    my $self = shift;
    my( $relationship, $rolodex ) = @_;

    $relationship ||= $self->get_relationship( $self->param( 'relationship_id' ));
    $rolodex ||= $relationship->rolodex;
    my $rolodex_filter = $self->current_user->pref->rolodex_filter || 'contacts';
    my $current_role = $rolodex->roles( $self->param( 'role_name' ));

    return {
        current_role    => $current_role,
        relationship    => $relationship,
        $self->expand_rolodex( $rolodex ),
        op              => $self->op,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub relationship_save {
    my $self = shift;

    $self->date_check( 'auth_start_date', 'auth_end_date' );
    $self->date_check( 'start_date', 'end_date' );
    
    my $rolodex = $self->get_rolodex;
    if( $self->param( 'private' ) ){
        unless( $rolodex->make_private( $self->param( 'client_id' ))){
            $self->add_error( 'private', 'private', 'This rolodex entry has a relationship with other clients, and cannot be made private to this one.' );
        }
    }
    else {
        $rolodex->client_id( '' )->save;
    }

    my $vars = $self->Vars;
    if( $self->errors ) {
        $self->relationship_edit( $vars, $self->get_rolodex );
    }
    else {
        my $client = $self->client;

        my $rel_id = $self->param( 'relationship_id' ) ||
            $client->rolodex_associate(
                $self->param( 'role_name' ),
                $self->param( 'rolodex_id' ),
            );

        my $relationship = $client->relationship_getone({
            role    => $self->param( 'role_name' ),
            relationship_id => $rel_id,
        });

        # XXX this is a bit of a hack
        # it gets around #728, but a better solution would be to change how update() works
        while( my( $property, $value ) = each %$vars ) {
            delete $vars->{ $property } unless defined $value;
        }
        # end hack
        $relationship->update( $vars );
        $self->home;
    }
}

## utility
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub roles_exist {
    my $self = shift;

    my $vars = $self->Vars;
    my $role_count;
    for( @ROLES ) {
        $role_count++ if $vars->{ $_ };
    }
    $role_count;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_rolodex {
    my $self = shift;
    eleMentalClinic::Rolodex->retrieve( $self->param( 'rolodex_id' ) || 0 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_relationship {
    my $self = shift;
    my( $relationship_id ) = @_;

    $relationship_id ||= $self->param( 'relationship_id' );
    return unless my $rel = $self->client->relationship_getone({
        role            => $self->param( 'role_name' ),
        relationship_id => $relationship_id,
    });
    $rel;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_rolodex_entries {
    my $self = shift;

    my $rolodex_filter = $self->current_user->pref->rolodex_filter;
    if( $rolodex_filter ) {
        return eleMentalClinic::Rolodex->new->get_byrole( $rolodex_filter, $self->client->id ),
    }
    else {
        return eleMentalClinic::Rolodex->new->get_all;
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub expand_rolodex {
    my $self = shift;
    my ( $rolodex ) = @_;

    return (
        rolodex => $rolodex,
        address => $rolodex->addresses->[0],
        phone   => $rolodex->phones->[0],
    );
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
