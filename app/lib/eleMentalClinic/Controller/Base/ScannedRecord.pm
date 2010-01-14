package eleMentalClinic::Controller::Base::ScannedRecord;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Venus::ScannedRecord

=head1 SYNOPSIS

Controller for the Scanned Records section.

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
        script => 'scanned_record.cgi',
        styles => [ 'layout/6633', 'scanned_record' ],
        javascripts  => [ 'client_filter.js', 'scanned_record.js' ],
    });
    $self->security( 'scanner' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    my $self = shift;
    (
        home => {},
        view_file => {
            filename => [ 'Filename', 'required' ],
        },
        save => {
            -alias  => 'Associate File with Patient',
        },
        invalid_file => {
            -alias  => 'Invalid File',
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $vars ) = @_;

    $vars->{ file } = eleMentalClinic::Client::ScannedRecord->get_oldest_file;
    $vars->{ history } = eleMentalClinic::Client::ScannedRecord->get_history;

    # remember field values in case of error
    $vars->{ description } = $self->param( 'description' )
        if $self->errors;

    $self->template->process_page( 'scanned_record/home', $vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub view_file {
    my $self = shift;
    # XXX fake up a record to make use of its methods; should probably be
    # refactored, but I'm not sure exactly how right now --hdp
    my $record = eleMentalClinic::Client::ScannedRecord->new({
        filename => $self->param( 'filename' ),
    });
    return $self->send_record_file( $record );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    if( $self->param( 'client_id' ) ){
        my $scanned_record = eleMentalClinic::Client::ScannedRecord->new({ $self->Vars, created_by => $self->current_user->id });
        eval{ $scanned_record->associate; };
        $self->add_error( 'filename', 'filename', 'Unable to associate the record: ' . $@ ) if $@;
    }
    else {
        $self->add_error( 'filename', 'filename', 'Please select a patient' );  # I'd use client_id here but that field comes from ajax and doesn't always appear
    }

    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub invalid_file {
    my $self = shift;

    eval{ eleMentalClinic::Client::ScannedRecord->invalid_file( $self->param( 'filename' ) ) };
    $self->add_error( 'filename', 'filename', 'Unable to move the file to the invalid list: ' . $@ ) if $@;

    $self->home;
}

'eleMental';

=head1 AUTHORS

=over 4

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
