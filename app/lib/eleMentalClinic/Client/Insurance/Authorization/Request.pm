package eleMentalClinic::Client::Insurance::Authorization::Request;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Insurance::Reauthorization

=head1 SYNOPSIS

Writes Health Insurance Authorization Form PDFs.

=head1 DESCRIPTION

Reauthorization is a simple wrapper for controlling production of paper
insurance authorizations.

=head1 USAGE

    my $auth = eleMentalClinic::Client::Insurance::Reauthorization->new( )

    # Call write() to have the pdf file output in the current 
    # $config->pdf_out_root directory
    $auth->write;

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::PDF;
use Date::Calc qw/ Month_to_Text English_Ordinal /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_insurance_authorization_request' }
    sub fields {[ qw/ 
        rec_id client_id client_insurance_authorization_id start_date end_date
        form provider_agency location diagnosis_primary diagnosis_secondary ohp
        medicare general_fund ohp_id medicare_id general_fund_id date_requested
    /]}
    sub fields_required {[ qw/ 
        client_id start_date
    /]}
    sub primary_key { 'rec_id' }
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args, $options ) = @_;

    $self->SUPER::init( @_ );
    $self->date_requested( $args->{ date_requested } || $self->today );

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 populate()

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub populate {
    my $self = shift;

    return unless $self->client;

    my $diagnoses = $self->get_diagnoses || [];
    $self->diagnosis_primary( $diagnoses->[ 0 ]);
    $self->diagnosis_secondary( $diagnoses->[ 1 ]);

    $self->form( 'wacoauth' );
    $self->location( $self->get_location );
    my $insurers = $self->client->insurance_bytype( 'mental health', 1 );
    for( @$insurers ) {
        if( $_->rolodex_id == $self->config->ohp_rolodex_id ) {
            $self->ohp( 1 );
            $self->ohp_id( $_->insurance_id );
        }
        elsif( $_->rolodex_id == $self->config->medicare_rolodex_id ) {
            $self->medicare( 1 );
            $self->medicare_id( $_->insurance_id );
        }
        elsif( $_->rolodex_id == $self->config->generalfund_rolodex_id ) {
            $self->general_fund( 1 );
            $self->general_fund_id( $_->insurance_id );
        }
    }

    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 write()

Object method.

Creates Insurance Authorization forms based on the data input.

Dies if unable to get the key data.

Returns the filename created.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub write {
    my $self = shift;

    die 'Form and end date are required'
        unless $self->form and $self->end_date;
   
    # TODO these values aren't tested on the generated PDF

    my $fields = [
        { x => 168, y => 619, value => $self->provider_agency },
        { x => 168, y => 600, value => $self->format_date( $self->start_date ) },
        { x => 416, y => 619, value => $self->location },
        { x => 416, y => 600, value => $self->format_date( $self->end_date ) },
        { x => 145, y => 559, value => $self->client->lname },
        { x => 392, y => 559, value => $self->client->fname },
        { x => 145, y => 539, value => $self->client->dob },
        { x => 392, y => 539, value => $self->client->ssn },
        { x => 219, y => 522, value => $self->diagnosis_primary },
        { x => 224, y => 506, value => $self->diagnosis_secondary },
        { x => 125, y => 467, value => $self->ohp_id },
        { x => 153, y => 451, value => $self->medicare_id },
        { x => 370, y => 435, value => $self->general_fund_id },
        { x =>  64, y => 467, value => ( $self->ohp ? 'X' : '' ) },
        { x =>  64, y => 451, value => ( $self->medicare ? 'X' : '' ) },
        { x =>  64, y => 435, value => ( $self->general_fund ? 'X' : '' ) },
    ];

    my $pdf = eleMentalClinic::PDF->new;
    $pdf->start_pdf( $self->config->pdf_out_root .'/'. $self->filename, $self->form );

    # Resize For Proper Printing
    $pdf->adjustmbox( 0, 0, 612, 798 );

    $pdf->write_pdf( $fields );
    return $pdf->finish_pdf;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub format_date {
    my $self = shift;
    my( $date ) = @_;

    return unless $date and $date =~ /^(\d{4})-(\d\d?)-(\d{2})$/;
    return sprintf( "%s %s, %d", Month_to_Text( $2 ), English_Ordinal( $3 ), $1 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub provider_agency {
    my $self = shift;
    $self->config->org_name;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 filename()
 
Generates a filename in the following format "Client%dAuth%06d-%06d" as filled by 
the client id, and month, day and year of the date_stamps.

Client[ID]Authmddyy-mmddyy.pdf

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub filename {
    my $self = shift;

    die 'Client id and start/end dates are required'
        unless $self->client_id and $self->start_date and $self->end_date
        and $self->client_id =~ /\d/;

    my( $start_date, $end_date ) = ( $self->start_date, $self->end_date );
    for( $start_date, $end_date ) {
        return unless length $_ == 10;
        $_ =~ s/^\d{2}(\d{2})-(\d{2})-(\d{2})$/$2$3$1/;
    }

    return sprintf 'Client%dAuth%06d-%06d.pdf', ( 
        $self->client_id,
        $start_date,
        $end_date,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_location

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_location {
    my $self = shift;

    die 'Client id is required'
        unless $self->client_id;

    return unless $self->client->placement->program;

    return $self->client->placement->program->{ name };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_diagnoses

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_diagnoses {
    my $self = shift;

    die 'Client id is required'
        unless $self->client_id;

    my( $diagnosisI, $diagnosisII );

    my $episode = $self->client->placement->episode;
    return unless $episode; # TODO this line is untested

    if( $episode->final_diagnosis ){
        $diagnosisI = $episode->final_diagnosis->diagnosis_1a;
        $diagnosisII = $episode->final_diagnosis->diagnosis_1b;
    } 
    elsif( $episode->initial_diagnosis ){
        $diagnosisI = $episode->initial_diagnosis->diagnosis_1a;
        $diagnosisII = $episode->initial_diagnosis->diagnosis_1b;
    }

    for( $diagnosisI, $diagnosisII ){
        # Remove the diagnosis text
        $_ =~ s/(\w{3}\.\w{2}).*/$1/ if $_;
        $_ = '' if $_ and $_ eq '000.00';
    }
 
    return[ $diagnosisI, $diagnosisII ]; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_insurance_authorization {
    my $self = shift;
    return unless $self->client_insurance_authorization_id;
    return eleMentalClinic::Client::Insurance::Authorization->retrieve( $self->client_insurance_authorization_id );
}


'eleMental';

__END__

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
