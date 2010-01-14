# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Controller::Venus::Intake;
use strict;
use warnings;
# for saving phones and addresses
use base qw/ eleMentalClinic::CGI::Rolodex /;

=head1 NAME

eleMentalClinic::Controller::Venus::Intake

=head1 SYNOPSIS

Intake Controller for Venus theme.

=head1 METHODS

=head2 init

=cut

sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'intake.cgi',
        styles => [ 'layout/5050', 'date_picker' ],
        javascripts  => [ 'client_filter.js', 'jquery.js', 'date_picker.js' ],
    });
    return $self;
}

=head2 ops

Extends L<eleMentalClinic::CGI::Intake/ops> with Venus-specific validation.

=cut

sub ops {
    my $self = shift;
    (
        home => {},
        reactivate => {},
        activate_home => {},
        intake  => {
            lname   => [ 'Last name', 'required', 'text::liberal', 'length(0,30)' ],
            fname   => [ 'First name', 'required', 'text::words', 'length(0,30)' ],
            mname	=> [ 'MI',  'text::words', 'length(0,30)' ],
            ssn     => [ 'Social Security number', 'demographics::us_ssn(integer)' ],
            dob     => [ 'Birth date', 'date::general' ],
            event_date  => [ 'Admit date', 'date::general' ],
            last_dr => [ 'Last Doctor', 'text::words' ],
            state   => [ 'State', 'demographics::us_state2' ],
            post_code   => [ 'Zip code', 'number::integer', 'length(0,10)' ],
            address1 => [ 'Address', 'text::hippie', 'length(0,255)' ],
            address2 => [ 'Address 2', 'text::hippie', 'length(0,255)' ],
            city => [ 'City', 'length(0,255)' ],
            phone => [ 'Phone', 'length(0,25)' ],
            phone_2 => [ 'Second Phone', 'length(0,25)' ],
            email => ['Email Address', 'length(0,64)' ],
        },
    )
}

=head2 home

=cut

sub home {
    my $self = shift;
    my( $client, $duplicates, $dupsok ) = @_;

    $client ||= 0;
    $duplicates ||= 0;
    $dupsok ||= 0;

    if( $client ) {
        $client->{ program_id } = $self->program_id;
    }
    $self->template->vars({
        styles => [ 'layout/5050', 'gateway', 'intake', 'date_picker' ],
    });

    # This needs to be called for pretty much every other op, so put it here to
    # simplify things.
    $self->override_template_name( 'home' );
    return {
        current     => $client,
        dupsok      => $dupsok,
        intake_type => $self->param( 'intake_type' ) || 0,
        duplicates  => $duplicates,
    };
}

=head2 intake

=cut

sub intake {
    my $self = shift;

    my $vars = $self->Vars;
    unless( $vars->{ event_date } le $self->today ) {
        $self->add_error( 'event_date', 'event_date', "<strong>Intake date</strong> cannot be in the future" );
        undef $vars->{ event_date };
    }
    if( $self->errors ) {
        $vars->{ ssn_f } = $vars->{ ssn };
        return $self->home( $vars );
    }
    else {
        my $client = eleMentalClinic::Client->new( $vars );
        my $duplicates = $client->dup_check;

        if( $duplicates->{ ssn }) {
            return {
                %$vars, #Data Carry-Over
                %{ $self->home( $client, $duplicates )}
            };
        }
        elsif( ($duplicates->{ lname_dob } or
                $duplicates->{ lname_fname})
                and ! $self->param( 'dupsok' ) ) {

            return {
                %$vars, #Data Carry-Over
                %{ $self->home( $client, $duplicates, 'dupsok' )}
            };
        }
        else {
            return $self->activate_home( $client );
        }
    }
}

=head2 reactivate

=cut

sub reactivate {
    my $self = shift;

    return $self->activate_home( $self->client );
}

=head2 activate_home

=cut

sub activate_home {
    my $self = shift;
    my( $client ) = @_;

    # wrap this in a transaction because we don't want save things in an
    # inconsistent state
    $self->db->transaction_do(sub {

        $client->save;
        $self->current_user->primary_role->grant_client_permission( $client );

        my $vars = { $self->Vars };

        $self->save_phones(
            $client,
            $vars,
            [ $self->phone_number_params ],
        );

        $self->save_address(
            $client,
            $vars,
        );

        my %placement = ();
        $placement{ level_of_care_id } = $self->param( 'level_of_care_id' )
            if defined $self->param( 'level_of_care_id' );
        $placement{ staff_id } = $self->param( 'staff_id' )
            if defined $self->param( 'staff_id' );

        $client->placement->change(
            dept_id            => $self->current_user->dept_id,
            program_id         => $self->program_id,
            event_date         => $self->param( 'event_date' ),
            intake_id          => 1,
            active             => 1,
            %placement,
        );
        # don't think we can do this here -- wait for placement screen
        if( 0 and $self->param( 'intake_type' ) eq 'Referral' ) {
            eleMentalClinic::Client::Referral->new({
                client_id   => $client->id,
                active      => 1,
                client_placement_event_id   => $client->placement->rec_id,
            })->save;
        }

    });

    return $self->on_activate_success( $client );
}

=head2 on_activate_success

    $controller->on_activate_success( $client );

Called automatically by L</activate_home> when a client is successfully saved.

The default action is to redirect to the C<Schedule> controller, with the
just-saved client selected.

=cut

sub on_activate_success {
    my $self = shift;
    my ( $client ) = @_;
    return $self->redirect_to( schedule => $client->id );
}

=head2 phone_number_params

    for ($self->phone_number_params) { ... }

Return the names of all parameters that correspond to phone numbers.  Used by
L</activate_home> to save phone numbers.

The default is C<phone, phone2>.

=cut

sub phone_number_params {
    qw(phone phone_2)
}

=head2 program_id

Choose the correct program id parameter based on the C<intake_type> parameter.

=cut

sub program_id {
    my $self = shift;

    return $self->param( 'admission_program_id' )
        if $self->param( 'intake_type' ) eq 'Admission';
    return $self->param( 'referral_program_id' )
        if $self->param( 'intake_type' ) eq 'Referral';
    return 0;
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
