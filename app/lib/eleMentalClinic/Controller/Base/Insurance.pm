package eleMentalClinic::Controller::Base::Insurance;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Insurance

=head1 SYNOPSIS

Base Insurance Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Client::Insurance;
use eleMentalClinic::Rolodex;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'insurance.cgi',
        styles => [ 'layout/3366', 'rolodex_filter', 'insurance', 'date_picker' ],
        javascripts  => [
            'rolodex_filter.js',
            'jquery.js',
            'date_picker.js',
        ],
    });
    
    $self->session->param( client_insurance_filter => $self->param( 'client_insurance_filter' ) || 'active' );
    $self->session->param( client_insurance_rolodex_filter => $self->param( 'client_insurance_rolodex_filter' ) || 'mental_health_insurance' )
        unless $self->session->param( 'client_insurance_rolodex_filter' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            client_insurance_filter => [ 'Filter', 'text::word', 'length(0,9)' ],
        },

        inactive => {},
        show_authorizations => {},

        insurance_view => {},
        insurance_new => {},
        insurance_save => {
            -alias  => 'Save Insurance',
            start_date   => [ 'Start date', 'required', 'date::iso' ],
            end_date   => [ 'End date', 'date::iso' ],
            carrier_type   => [ 'Insurance carrier type', 'required' ],
            rank   => [ 'Insurance rank', 'required' ],
            insurance_id   => [ 'Subscriber Insurance ID', 'required', 'text', 'length(2,80)' ],
            insurance_type_id   => [ 'Insurance type', 'required' ],
            insured_group_id => [ 'Group id', 'text', 'length(2,30)' ],
            insured_group => [ 'Group name', 'text', 'length(2,60)' ],
            insured_addr => [ 'Address', 'text', 'length(2,50)' ],
            insured_addr2 => [ 'Address 2', 'text', 'length(2,50)' ],
            insured_city => [ 'City', 'text', 'length(2,30)' ],
            insured_state => [ 'State', 'text', 'length(2,2)' ],
            insured_postcode => [ 'Zip', 'text', 'length(3,15)' ],
            patient_insurance_id   => [ 'Client Insurance ID', 'text', 'length(2,80)' ],
        },
        relationship_new => {},

        authorization_view => {},
        authorization_new => {},
        authorization_save => {
            -on_error => 'authorization_new',
            -alias  => 'Save Authorization',
            start_date   => [ 'Start date', 'required', 'date::iso' ],
            end_date   => [ 'End date', 'required', 'date::iso' ],
            allowed_amount  => [ 'Allowed amount', 'number::integer', 'required' ],
            type => [ 'Type', 'required' ],
            code => [ 'Authorization ref. #', 'required' ],

        },

        level_of_care_lock => {
            -alias  => 'Lock',
        },
        level_of_care_unlock => {
            -alias  => 'Unlock',
        }
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( %vars ) = @_;

    my %insurers = $self->_get_insurers;
    my $action = ( $self->current_user->insurance or $self->current_user->admin )
        ? 'edit'
        : 'display';
    %vars = (
        action          => $action,
        rolodex         => $self->_get_rolodex,
        rolodex_entries => $self->_get_rolodex_entries,
        %insurers,
        %vars,
    );
    $self->template->process_page( 'insurance/home', \%vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub inactive {
    my $self = shift;
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub insurance_view {
    my $self = shift;
    return $self->home(
        op => 'insurance_view',
        current_insurance => $self->_get_insurance,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub insurance_new {
    my $self = shift;
    my( $vars ) = @_;

    $self->template->vars({
        styles => [ 'layout/6633', 'rolodex_filter', 'insurance', 'date_picker' ],
        javascripts  => [
            'jquery.js',
            'date_picker.js',
        ],
    });
    return $self->home(
        op => 'insurance_new',
        role_name   => $self->param( 'role_name' ),
        current_insurance   => $vars,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub relationship_new {
    my $self = shift;
    return $self->insurance_new;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub insurance_save {
    my $self = shift;

    my $vars = $self->Vars;
    my $insurance = $self->_get_insurance;

    # if we have errors creating a new insurance, we should use that runmode
    # if we have $insurance, it means we're editing an existing one
    if( $self->errors ) {
        $insurance
            ? return $self->home( current_insurance => $insurance )
            : return $self->insurance_new( $vars );
    }

    my $rel_id = $self->param( 'client_insurance_id' ) ||
        $self->client->rolodex_associate(
            $self->param( 'role_name' ),
            $self->param( 'rolodex_id' ),
        );
    my $relationship = $self->client->relationship_getone({
        role    => $self->param( 'role_name' ),
        relationship_id => $rel_id,
    });
    $relationship->update({ %$vars, rolodex_insurance_id => $relationship->rolodex_insurance_id });
    $insurance = $relationship;

    # set session so we know where we're going
    $insurance->is_active
        ? $self->session->param( client_insurance_filter => 'active' )
        : $self->session->param( client_insurance_filter => 'inactive' );
    return $self->home( current_insurance => $insurance );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub authorization_view {
    my $self = shift;

    my $current_authorization = $self->_get_authorization;
    # if we change the auth view preference from 'all' to 'current',
    # we may be viewing an inactive auth.  in that case, we bounce to
    # view the default (first) insurance
    return $self->insurance_view
        if not $self->session->param( 'client_insurance_authorizations_show_all' )
        and not $current_authorization->is_active;
    return $self->home(
        op => 'authorization_view',
        current_authorization => $self->_get_authorization,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub authorization_new {
    my $self = shift;

    return $self->home(
        op => 'authorization_new',
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub authorization_save {
    my $self = shift;

    my $vars = $self->Vars;
    my $authorization = $self->_get_authorization;
    return $self->home( current_authorization => $authorization || $vars )
        if $self->errors;

    if( $authorization ) {
        $authorization->update( $vars );
    }
    else {
        $authorization = eleMentalClinic::Client::Insurance::Authorization->new( $vars )->save;
        die 'a grisly death' unless $authorization;
    }
    return $self->home( current_authorization => $authorization );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub show_authorizations {
    my $self = shift;

    $self->param( 'show' )
        ? $self->session->param( 'client_insurance_authorizations_show_all' => 1 )
        : $self->session->param( 'client_insurance_authorizations_show_all' => 0 );
    my $op = $self->param( 'return_op' ) || 'home';
    $self->$op;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub level_of_care_lock {
    my $self = shift;

    $self->client->placement->level_of_care_locked( 1 );
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub level_of_care_unlock {
    my $self = shift;

    $self->client->placement->level_of_care_locked( 0 );
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO need to account for active/inactive insurance status
# when setting "rank" flags and updating all other insurers
# MAYBE: don't update rank at all; let HS do it
sub _get_insurers {
    my $self = shift;

    my %return_vars;
    # first, get the current insurer, if we're asked for it
    $return_vars{ current_insurance } = $self->_get_insurance;
    my $active = $self->session->param( 'client_insurance_filter' ) eq 'inactive'
        ? 0
        : 1;
    my %insurers;
    for( 'mental health', 'medical', 'dental' ) {
        next unless
            my $insurers = $self->client->insurance_bytype( $_, $active );
        ( my $key = $_ ) =~ s/ /_/g;
        $insurers{ $key } = $insurers;
        # if we don't have a current insurer yes, pick the first one we can
        $return_vars{ current_insurance } ||= $insurers-> [ 0 ];
    }
    $return_vars{ client_insurers } = \%insurers
        if %insurers;
    %return_vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_insurance {
    my $self = shift;

    return unless $self->param( 'client_insurance_id' );
    return eleMentalClinic::Client::Insurance->retrieve( $self->param( 'client_insurance_id' ));
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_authorization {
    my $self = shift;

    return unless $self->param( 'authorization_id' );
    return eleMentalClinic::Client::Insurance::Authorization->retrieve( $self->param( 'authorization_id' ));
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_rolodex {
    my $self = shift;
    eleMentalClinic::Rolodex->retrieve( $self->param( 'rolodex_id' ) || 0 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_rolodex_entries {
    my $self = shift;

    my $rolodex_filter = $self->session->param( 'client_insurance_rolodex_filter' );
    return eleMentalClinic::Rolodex->new->get_byrole( $rolodex_filter, $self->client->id ),
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

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
