package eleMentalClinic::Controller::Base::Discharge;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Discharge

=head1 SYNOPSIS

Base Discharge Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Client::Referral;
use eleMentalClinic::Client::Discharge;
use eleMentalClinic::Rolodex;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/5050', 'discharge' ],
        script => 'discharge.cgi',
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub old_home {#{{{
    my $self = shift;
    my( $current ) = @_;

    my $client = $self->client;
    my $discharge = eleMentalClinic::Client::Discharge->new( $current );
    $discharge = $discharge->get_latest( $client->id );

    # if the latest discharge returned is uncommitted, we edit that one
    # instead of allowing creation of a new one
    unless( $self->errors or !$discharge or $discharge->{ committed } ) {
        $current = $discharge;
        $current->{ termination_reason_manual } = $current->{ termination_reason };
    }

    my $legal_history = 0;
    $legal_history = 1 if $self->client->legal_past_issues;

    $current->{ legal_history }     = $legal_history;
    $current->{ last_contact_date } = $self->_last_contact_date;
    $current->{ staff_name }        = $self->client->personnel->fname . ' ' . $self->client->personnel->lname;

    my $err_note;
    if( $self->op eq 'save_for_later' and $self->errors ){
        $err_note = qq/ Discharge has been saved. Please correct these errors before finalizing: /;
    }

    $self->template->process_page( 'discharge/home', {
        current => $current,
        err_note => $err_note,
    });
}#}}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub discharge {
    my $self = shift;

    unless( $self->errors ) {
        $self->_save_discharge( 'commit' );
        $self->client->placement->change(
            event_date          => $self->today,
            input_by_staff_id   => $self->current_user->staff_id,
        );

        $ENV{ REQUEST_URI } =~ m#(.*)/gateway/.*#; # get the first part of the URI
        return( undef, "$1/gateway/placement.cgi?client_id=". $self->client->id ); # redirect
    }
    else {
        my $current = $self->Vars;
        $self->home( $current );
    }
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
