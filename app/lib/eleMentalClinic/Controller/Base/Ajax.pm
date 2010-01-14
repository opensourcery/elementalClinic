package eleMentalClinic::Controller::Base::Ajax;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Ajax

=head1 SYNOPSIS

Base Ajax Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use CGI qw(header);
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->ajax( 1 );
    $self->error( 'login' )
        unless $self->current_user and $self->current_user->id;
    $self->override_template_path( 'gateway' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        client_selector => {
            controller  => [ 'Controller', 'text::word' ],
        },
        appointment_edit => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_selector {
    my $self = shift;

    $self->override_template_name( 'home_client_select' );
    return {
        ajax        => 1,
        controller  => $self->_get_valid_controller,
        clients     => $self->current_user->filter_clients || '',
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub appointment_edit {
    my $self = shift;

    $self->override_template_path( 'schedule/popup' );
    $self->override_template_name( 'appointment' );
    return {
        ajax => 1,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub error {
    my $self = shift;
    my( $type ) = @_;

    $_ = $type;
    return "Please login" if /^login$/;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_valid_controller {
    my $self = shift;

    # these controllers are good -- any client request should stay put
    my @good = qw/
        allergies assessment demographics diagnosis discharge 
        hospitalizations income legal letter
        placement prescription progress_notes report roi rolodex treatment
    /;
    # these aren't controllers, so should go back to the referrer
    my @refer = qw/
        dispatch ajax client_filter progress_notes_charge_codes rolodex_filter_roles
    /;
    # special cases
    my %redirect_to = (
       financial    => 'insurance',
    );
    # these controllers don't work with a client, so should be redirected
    my @redirect = qw/
        admin entitlements index menu rolodex_cleanup
        set_treaters user_prefs valid_data personnel financial
        intake groups group_notes admin_assessment_templates
    /;

    my $controller = $self->context->{ controller };
    my $referrer = $self->context->{ referrer };

    # FIXME this is an ugly one-off and should be generalized
    return 'insurance'
        if $referrer and $referrer eq 'index'
        and $self->current_user->home_page_type eq 'financial';

    return $controller
        if $controller
        and grep /^$controller$/ => @good;
    for( keys %redirect_to ) {
        return $redirect_to{ $_ }
            if ($controller || '') eq $_
            or ($referrer   || '') eq $_;
    }
    return $referrer
        if $referrer
        and grep /^$controller$/ => @refer
        and not grep /^$controller$/ => @redirect
        and not grep /^$referrer$/ => @redirect;
    return 'demographics';
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
