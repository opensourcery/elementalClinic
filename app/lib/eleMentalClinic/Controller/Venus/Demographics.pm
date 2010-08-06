# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Controller::Venus::Demographics;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Venus::Demographics

=head1 SYNOPSIS

Demographics Controller for Venus theme.

=head1 METHODS

=cut

use Moose;
extends qw/ eleMentalClinic::Controller::Base::Demographics /;
use eleMentalClinic::Client;
use eleMentalClinic::Client::Referral;
use eleMentalClinic::Rolodex;
use Data::Dumper;
use Date::Calc;

has client => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_client {
    $_[0]->SUPER::client
}

has emergency_contact => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_emergency_contact {
    my $contact = $_[0]->client->get_emergency_contact;
    return $contact && $contact->rolodex;
}

has primary_treater => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_primary_treater {
    $_[0]->client->get_primary_treater
}

has treaters => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_treaters {
    eleMentalClinic::Rolodex->new->get_byrole('treaters') || 0
}

has emergency_contact_params => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_emergency_contact_params {
    $_[0]->Vars_byprefix('emergency_contact_rolodex_')
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/5050', 'demographics', 'gateway', 'date_picker' ],
        script => 'demographics.cgi',
        javascripts  => [ 'client_filter.js', 'jquery.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias => 'Cancel',
        },
        edit => {
            -alias => 'Edit',
        },
        save => {
            -alias => 'Save Patient',
            -on_error => 'edit',
            lname   => [ 'Last name', 'text::words', 'required', 'length(0,30)'],
            fname   => [ 'First name', 'text::words', 'required', 'length(0,30)'],
            mname   => [ 'Middle name', 'text::words', 'length(0,30)'],
            state   => [ 'State', 'demographics::us_state2' ],
            post_code   => [ 'Zip code', 'number::integer' ],
            ssn     => [ 'Social Security number', 'demographics::us_ssn(integer)' ],
            dob     => [ 'Birthdate', 'date::general' ],
            renewal_date  => [ 'Renewal Date', 'date::general' ],
            aka     => [ 'Alias', 'length(0,25)' ],
            state_specific_id => [ 'CPMS', 'number' ],
            comment_text => [ 'Comment', 'text::hippie' ],
            address1 => [ 'Address', 'text::hippie', 'length(0,255)' ],
            address2 => [ 'Address 2', 'text::hippie', 'length(0,255)' ],
            city => [ 'City', 'length(0,255)' ],
            post_code => [ 'Zip', 'length(0,10)' ],
            phone => [ 'Phone', 'length(0,25)' ],
            phone_2 => [ 'Second Phone', 'length(0,25)' ],
            email => ['Email Address', 'length(0,64)' ],
            emergency_contact_rolodex_fname => [ 'Emergency contact first name', 'length(0,50)' ],
            emergency_contact_rolodex_lname => [ 'Emergency contact last name', 'length(0,50)' ],
            emergency_contact_rolodex_comment_text => [ 'Emergency contact Relationship' ],
            emergency_contact_rolodex_phone_number => [ 'Emergency contact phone', 'length(0,25)' ],
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;

    return {
        emergency_contact_rolodex  => $self->emergency_contact,
        rolodex_treaters           => $self->treaters,
        primary_treater_rolodex    => $self->primary_treater,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;

    $self->override_template_name( 'home' );
    return {
        current                    => $self->client,
        emergency_contact_rolodex  => $self->emergency_contact,
        primary_treater_rolodex    => $self->primary_treater,
        rolodex_treaters           => $self->treaters,
    };
}

before save => sub {
    my $self = shift;
    $self->override_template_name( 'home' );

    my $ecp = $self->emergency_contact_params;

    # If any of the contact params have a value other than 0, '', undef
    # and there is no phone number
    # give an error, number is required.
    if (
       ( grep { $_ } values %$ecp )
       and ( not $ecp->{phone_number} )
    ) {
        $self->add_error(
            'emergency_contact_rolodex_phone_number',
            'emergency_contact_rolodex_phone_number',
            'Emergency Contact Phone is required if an emergency contact is specified.'
        );
    }
};

sub on_error {
    my $self = shift;
    return $self->clone(
        client            => $self->client->new({ $self->Vars }),
        emergency_contact => eleMentalClinic::Rolodex->new(
            $self->emergency_contact_params
        ),
        primary_treater   => eleMentalClinic::Rolodex->new({ 
            rec_id => scalar $self->param('primary_treater_rolodex_id'),
        }),
    )->edit;
}

sub on_success {
    my $self = shift;
    my $client = $self->client;
    my $ecp = $self->emergency_contact_params;
    $client->save_emergency_contact( $ecp ) if $ecp->{phone_number};
    $client->save_primary_treater({
        primary_treater_rolodex_id => scalar $self->param('primary_treater_rolodex_id')
    });

    # staff id required by client update so that it can set a renewal progress
    # note if required by an update to renewal_date
    $client->update({ $self->Vars, staff_id => $self->current_user->staff_id });
    my $vars = $self->Vars;
    $self->save_phones(
        $client,
        $vars,
        [ qw(phone phone_2) ],
    );
    $self->save_address( $client, $vars );
    $self->edit;
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
