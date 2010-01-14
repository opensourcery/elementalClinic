package eleMentalClinic::Controller::Base::Verification;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Venus::Verification

=head1 SYNOPSIS

Base Verification Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/3366', 'gateway', 'verification', 'date_picker' ],
        script => 'verification.cgi',
		javascripts  => [ 'client_filter.js', 'jquery.js', 'date_picker.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        save => {
			apid_num => [ 'APID#', 'required', 'number::integer', 'length(1,6)'],
            rolodex_treaters_id => [ 'Doctor', 'required', 'number::integer'],
			verif_date => ['Date', 'required', 'date::general']
        },
        edit => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $current ) = @_;

    $self->template->process_page( 'verification/home', {
        current           => $current,
        rolodex_treaters  => eleMentalClinic::Rolodex->new->get_byrole('treaters') || 0,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    my $current = $self->Vars;

    if( $self->errors ) {
        return $self->edit;
    }

    $self->db->transaction_do_eval(sub {
        # All edits to a verification are being treated as though
        # a new entry is made (i.e., date and staff id are
        # updated, and a log entry set)
        my $verification = eleMentalClinic::Client::Verification->new( { 
            %$current,
            created  => $self->today,
            staff_id => $self->current_user->staff_id,
        } );
        $verification->save;
     
        my $client = $verification->client;
        # FIXME This probably should not have the program id hardset.
        if ( not $client->placement->is_admitted ) {
            $client->placement->change(
                dept_id            => $self->current_user->dept_id,
                program_id         => 2,
                event_date         => $self->timestamp,
                intake_id          => 1,
                staff_id           => $self->current_user->staff_id,
            );
        }
    });
    if (my $e = $@) {
        if ($e =~ /"(client_verification_business_key)"/) {
            $self->add_error(
                'apid_num',
                "$1",
                "APID# $current->{apid_num} is already in use for this patient."
            );
            return $self->edit;
        }
        die $e;
    }
  
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;

    my $current = eleMentalClinic::Client::Verification->new({
        rec_id   => $self->param( 'rec_id' )})->retrieve;
    $self->home( $current );
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
