# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Controller::Base::ClientScannedRecord;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Venus::ClientScannedRecord

=head1 SYNOPSIS

Controller for the Client's Scanned Records section.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI::ScannedRecord /;
use Data::Dumper;
use eleMentalClinic::Client::ScannedRecord;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'client_scanned_record.cgi',
        styles => [ 'layout/6633', 'gateway', 'client_scanned_record', 'date_picker' ],
        javascripts  => [ 'client_filter.js', 'scanned_record.js', 'jquery.js', 'date_picker.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    my $self = shift;
    (
        view_file => {
            client_scanned_record_id => [ 'Record ID', 'required' ],
        },
        home => {},
        wrong_client => {
            -alias  => 'Wrong Patient',
        },
        update_description => {
            -alias  => 'Update Description',
        },
    )
}

sub selected_file {
    my $self = shift;
    my $id = $self->param( 'client_scanned_record_id' );
    return unless $id;
    my $record = eleMentalClinic::Client::ScannedRecord->retrieve( $id );
    unless ( $record->rec_id ) {
        die "No such client scanned record: $id";
    }
    return $record;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $vars ) = @_;

    $vars->{ files } = eleMentalClinic::Client::ScannedRecord->new->get_byclient( $self->param( 'client_id' ) );
    $vars->{ selected_file } = $self->selected_file;

    $self->template->process_page( 'client_scanned_record/home', $vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub view_file {
    my $self = shift;
    my $record = $self->selected_file;

    unless ( $record->client_id ) {
        die "Record is not associated with a client: " . $record->rec_id;
    }

    return $self->send_record_file( $record );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub wrong_client {
    my $self = shift;
    
    my $scanned_record = eleMentalClinic::Client::ScannedRecord->new({ rec_id => $self->param( 'wrong_client_scanned_record_id' ) })->retrieve;
    eval{ $scanned_record->disassociate; };
    $self->add_error( 'filename', 'filename', 'Unable to disassociate the file from this client: ' . $@ ) if $@;

    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub update_description {
    my $self = shift;

    my $scanned_record = $self->selected_file;
    if( $scanned_record ) {
        $scanned_record->description( $self->param( 'description' ) );
        $scanned_record->save;
    }

    $self->home;
}

'eleMental';

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

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
