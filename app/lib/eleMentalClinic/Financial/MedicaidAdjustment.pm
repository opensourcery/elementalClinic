package eleMentalClinic::Financial::MedicaidAdjustment;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::MedicaidAdjustment

=head1 SYNOPSIS

Writes Medicaid Claim Adjustment Form PDFs, specific to Oregon's Division
of Medical Assistance Programs (DMAP). Child of L<eleMentalClinic::Financial::WriteClaim>.

DMAP 1036  Rev 01/07

=head1 DESCRIPTION

MedicaidAdjustment is a simple wrapper for controlling production of Medicaid Adjustment paper forms.

=head1 Usage

    my $adjustment = eleMentalClinic::Financial::MedicaidAdjustment->new( $vars )
    # See t/546medicaid_adjustment.t for vars

    # Call write() to have the Adjustment form output as a pdf file in the current 
    # $config->pdf_out_root directory
    $adjustment->write();

=head1 METHODS

=cut


use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::PDF;
use eleMentalClinic::Util;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub fields  { [ 
        qw/ form transactions billing_claim_id billing_payment_id client_id date_requested 
            underpayment internal_control_number ra_date recipient_name
            recipient_id provider_name provider_number provider_npi
            provider_taxonomy place charge_code modifier units diagnosis performing_provider billed_amount 
            medicare_payment other_payment coinsurance other remarks / 
    ] }
    sub fields_required { [ qw/ transaction_ids /] }
    sub accessors_retrieve_one {
        {
            billing_claim => { billing_claim_id => 'eleMentalClinic::Financial::BillingClaim' },
            billing_payment => { billing_payment_id => 'eleMentalClinic::Financial::BillingPayment' },
            client => { client_id => 'eleMentalClinic::Client' },
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->populate( $args );

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 filename
 
Generates a filename in the following format "MedicaidAdjustment%d.%06d" as filled by 
the billing claim id, and the month, day and year of the date_requested.

MedicaidAdjustment1001.mddyy.pdf

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub filename {
    my $self = shift;

    die 'date_requested is required' unless $self->date_requested;
    die 'billing_claim_id is required' unless $self->billing_claim_id;

    my $date = $self->date_requested;
    $date =~ s/^\d{2}(\d{2})-(\d{2})-(\d{2})$/$2$3$1/;
    return sprintf 'MedicaidAdjustment%d.%06d.pdf', ( $self->billing_claim_id, $date );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 populate

Object method. Populates the object's internal values, using data from
the $args to gather needed data from database and objects.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub populate {
    my $self = shift;
    my( $args ) = @_;

    $self->form( 'medicaidadjustment' );
    $self->date_requested( $args->{ date_requested } || $self->today );

    if( $args->{ transaction_ids } ){

        # FIXME Could be refactored to only choose the transactions chosen to be changed, 
        # not all the ones chosen originally
        my @transactions;
        push @transactions => eleMentalClinic::Financial::Transaction->retrieve( $_ )
            for sort @{ $args->{ transaction_ids } };
        $self->transactions( \@transactions );
        
        # The transactions chosen must be for the same billing_claim 
        # (which implies that they are for the same client & payer)
        # and the same billing_payment.
        # This ensures that the payer_claim_control_number and interchange_date
        # are the same for all transactions.
        my( %payment_ids, %billing_claim_ids );
        for( @transactions ){ 
            $billing_claim_ids{ $_->billing_service->billing_claim_id } = 1;
            $payment_ids{ $_->billing_payment_id } = 1;
        }

        die 'Selected transactions are from different Master Payments'
            if scalar keys %payment_ids > 1;

        die 'Selected transactions are from different billing claims'
            if scalar keys %billing_claim_ids > 1;

        $self->billing_payment_id( $transactions[0]->billing_payment_id );
        $self->client_id( $transactions[0]->billing_service->billing_claim->client_id );
        $self->billing_claim_id( $transactions[0]->billing_service->billing_claim_id );

        # FIXME ideally this is in the billing_claim, not transaction
        $self->internal_control_number( $transactions[0]->payer_claim_control_number );

        # XXX can't use interchange_date, in case of manual payment
        $self->ra_date( format_date( $self->billing_payment->payment_date ) );
    
        my $client_insurance = $transactions[0]->billing_service->billing_claim->client_insurance;
        $self->recipient_id( $client_insurance->insurance_id );
        $self->recipient_name( $self->client->eman  );  
        $self->provider_name( $self->config->org_name );
        $self->provider_number( $self->config->org_medicaid_provider_number );
        $self->provider_npi( $self->config->org_national_provider_id );
        $self->provider_taxonomy( $self->config->org_taxonomy_code );

        $self->populate_transactions( $args );
    }

    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 populate_transactions( $args )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub populate_transactions {
    my $self = shift;
    my( $args ) = @_;

    # Theoretically there could be multiple values for service_date, etc
    # (if two lines need to be changed to different charge codes, for example),
    # although the form doesn't support it.
    # See XXX notes below.

    for( sort keys %$args ){

        # looking for checkboxes such as place_1004, charge_code_1001, etc - this means they want to change this value for this transaction
        if( /^(\w*)_(\d*)$/ ){
            next if /^transaction_(\d*)$/; # all transaction ids are sent and handled separately
            next if /^(\w*)_right_(\d*)$/; # looked up below

            my $transaction;
            if( $2 ){
                $transaction = eleMentalClinic::Financial::Transaction->retrieve( $2 );
            }
            if( $transaction and $self->can( $1 ) ){
                # add the line number to the list for this value ('place', 'charge code', etc)
                push @{ $self->{ $1 }->{ line_numbers } } => $transaction->billing_service->line_number;

                # If we've already set the service_date for $1 ('place', 'charge code', etc), then
                # assume we've already set right & wrong too
                # XXX This means that service_date and 'right' only get set for the first transaction chosen
                # XXX This assumes they are the same for every transacation chosen.
                unless( $self->$1->{ service_date } ){
                    # FIXME rewrite in a cleaner, safer way
                    $self->$1->{ service_date } = format_date_remove_time( $transaction->billing_service->billing_prognotes->[0]->prognote->start_date );
                    $self->$1->{ right } = $args->{ "$1_right_$2" };
                    $self->$1->{ wrong } = $args->{ "$1_wrong" };

                    # special cases
                    $self->other->{ right } = $args->{ "other_right" }
                        if $1 eq 'other';
                    $self->coinsurance->{ right } = $args->{ "coinsurance_right" }
                        if $1 eq 'coinsurance';
                }
            }
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 write()

Object method.

Creates Medicaid Adjustment forms based on object's internal values.

Dies if $self->form is not defined.

Returns the filename created.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub write {
    my $self = shift;

    die 'Form is required'
        unless $self->form;

    # FIXME these values aren't tested on the generated PDF
    my $fields = [
        { x => 165, y => 650, value => $self->underpayment ? 'X' : '' },
        { x => 165, y => 633, value => $self->underpayment ? '' : 'X' },
        { x => 505, y => 502, value => $self->ra_date },
        { x => 140, y => 475, value => $self->recipient_name },
        { x => 135, y => 448, value => $self->provider_name },
        { x => 105, y => 145, value => $self->remarks },
    ];
   
    push @$fields => string_to_boxes( $self->internal_control_number, 190, 502 );
    push @$fields => string_to_boxes( $self->recipient_id, 450, 475 );
    push @$fields => string_to_boxes( $self->provider_number, 484, 448 );
    push @$fields => string_to_boxes( $self->provider_npi, 82, 422 );
    push @$fields => string_to_boxes( $self->provider_taxonomy, 412, 422 );

    my $y = 366;
    for my $item_to_change ( 
        qw/ place charge_code modifier units diagnosis performing_provider billed_amount 
            medicare_payment other_payment coinsurance other / ) 
    {
        if( $self->$item_to_change and $self->$item_to_change->{ line_numbers } and @{ $self->$item_to_change->{ line_numbers } } ){
            push @$fields => { x =>  27, y => $y, value => 'X' };
            push @$fields => { x => 233, y => $y, value => join ', ' => @{ $self->$item_to_change->{ line_numbers } } };
            push @$fields => { x => 285, y => $y, value => $self->$item_to_change->{ service_date } };
            push @$fields => { x => 360, y => $y, value => $self->$item_to_change->{ wrong } };
            push @$fields => { x => 478, y => $y, value => $self->$item_to_change->{ right } };
        }
        $y -= 19;
    }

    # Phone number and Date at bottom of the page
    push @$fields => { x => 522, y => 50, value => format_date( $self->date_requested ) };
    push @$fields => { x => 365, y => 50, value => eleMentalClinic::Personnel->retrieve( $self->config->edi_contact_staff_id )->work_phone };

    my $pdf = eleMentalClinic::PDF->new;
    $pdf->start_pdf( $self->config->pdf_out_root .'/'. $self->filename, $self->form );

    # Resize For Proper Printing
    $pdf->adjustmbox( 0, 0, 612, 798 );

    $pdf->write_pdf( $fields );
    return $pdf->finish_pdf;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 string_to_boxes( $string, $x, $y )

Function. Takes a string and prints each letter spaced out by blank 
space - so that the string fits in a row of boxes.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub string_to_boxes {
    my( $string, $x, $y ) = @_;
    my $count = 0; 
    my @coordinates;

    return () unless $string;
    $x = $x || 0;
    $y = $y || 0;
    
    while( $count < length( $string ) ){
        push @coordinates => { x => $x, y => $y, value => substr( $string, $count, 1 ) };
        $x += 18;
        $count++;
    }

    return @coordinates;
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
