package eleMentalClinic::Financial::BillingPayment;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::BillingPayment

=head1 SYNOPSIS

The billing payment record, which records an 835 that is received.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::ECS::Read835;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'billing_payment' }
    sub fields { [ qw/
        rec_id interchange_control_number
        is_production date_received
        transaction_handling_code payment_amount
        payment_method payment_date payment_number
        payment_company_id interchange_date
        entered_by_staff_id rolodex_id edi
        edi_filename
    /] }
    sub primary_key { 'rec_id' }

    sub methods {
        [ qw/ read835 / ]
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 process_remittance_advice( $filename, $date_received )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub process_remittance_advice {
    my $self = shift;
    my( $filename, $date_received ) = @_;

    die 'filename and date_received are required' unless $filename and $date_received;

    $self->read835( eleMentalClinic::ECS::Read835->new );

    $self->read835->file( $filename );
    die 'Unable to parse 835' unless $self->read835->parse;
    
    die 'Unable to get the EDI data out of the 835' unless $self->read835->get_edi_data;

    my $edi_filename = $filename;
    $edi_filename =~ s/.*\///g; # remove the path
    $self->edi_filename( $edi_filename );

    $self->interchange_control_number( $self->read835->get_interchange_control_number );
    $self->is_production( $self->read835->is_production );
    $self->edi( $self->read835->get_raw_edi ); 
    $self->transaction_handling_code( $self->read835->get_transaction_handling_code );
    $self->payment_amount( $self->read835->get_transaction_monetary_amount );
    $self->payment_method( $self->read835->get_payment_method );
    $self->payment_date( $self->read835->get_payment_date );
    $self->payment_number( $self->read835->get_check_number );
    $self->payment_company_id( $self->read835->get_originating_company_id );
    $self->interchange_date( $self->read835->get_interchange_date );
    $self->rolodex_id( $self->get_payer_id );

    $self->date_received( $date_received );

    if( $self->already_processed ){
        die 'This file (control num ' . $self->interchange_control_number . ', rolodex ' . $self->rolodex_id . ') has already been processed.';
    }

    $self->db->transaction_begin;
    eval {
        die 'Unable to save billing_payment' unless $self->save;

        $self->process_claims;
    };
    if( $@ ){
        my $error = $@;
        $self->db->transaction_rollback;
        die $error;
    }

    return $self->db->transaction_commit;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 process_claims

Object method.

$self->read835 (an eleMentalClinic::ECS::Read835 object) must be defined to use this method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub process_claims {
    my $self = shift;

    die 'ECS::Read835 object is required' unless $self->read835;
    my $claims = $self->read835->get_claims;

    warn qq/Provider Adjustment found in the 835 - 
    this is a deduction that is NOT specific to a particular claim or service, 
    and deducts (or adds) to the amount of the total payment. 
    eMC does not account for these currently./
        if $self->read835->get_provider_deductions->[0];

    for my $claim ( @$claims ){

        my $service_lines = $claim->{ service_lines };
        my $claim_deductions = $claim->{ deductions };
        my $billing_claim = eleMentalClinic::Financial::BillingClaim->retrieve( $claim->{ id } );
        die 'Unable to get billing_claim' unless $billing_claim->{ rec_id };
        die 'Unable to get_billing_services' unless my $billing_services = $billing_claim->billing_services;
        
        if( scalar @$claim_deductions ){
            die 'Claim Adjustment found in the 835 -
            this is a deduction to the amount paid for a claim. It is not itemized
            at the service line level.';
        }

        # Find out where the deductions to the payment are located in the 835:
        if( scalar @$service_lines and scalar @$claim_deductions ){
        
            # Some deductions are at the service level, some are at the claim level
            
            # TODO
            # Thoughts on adding processing for claim level deductions:
            # new method to save_payment for a claim
            # saves all the line deductions first
            # then splits up the claim-level deductions among the notes
            #
            # Does this make things tricky for billing the second insurance?
            # yes, unless there is a way of knowing what is a claim level deductions
            # and what's a service-line level deduction
        }
        elsif( scalar @$claim_deductions ){
            
            # All deductions at claim level
            
            # TODO
            # Thoughts on how to handle this case:
            # new method to save_payment for a claim
            # which will take all prognotes in the claim
            # and apply the claim level deductions one by one
            # until each prognote is 'paid'?
        }
        else {
        
            # We've sent the billing_service_id in the 837 as the line_item_control_number (REF*6R*), 
            # so they have to send it back to us to use. Use it here as an index to the service lines.
            my %services = map { $_->{ line_item_control_number } => $_ } @$service_lines;

            # - all deductions at service line level
            for my $billing_service ( @$billing_services ){
               
                next unless $billing_service->billed_amount;
                if( ! defined $services{ $billing_service->rec_id } ){

                    if( $claim->{ total_charge_amount } == $claim->{ payment_amount } ){
                        die 'Unable to save_payment on billing_service ' . $billing_service->rec_id 
                            unless $billing_service->save_payment( $self->rec_id, $claim );
                    }
                    else {
                        die 'Unable to find the matching service line for billing_service [' . $billing_service->rec_id . '], and the claim was not paid in full.'
                        # TODO test
                        # TODO is this a possible situation when a service line is pending? or is it only claims that can be pending payment?
                    }
                }
                else {

                    die 'Unable to save_payment on billing_service ' . $billing_service->rec_id 
                        unless $billing_service->save_payment( $self->rec_id, $claim, $services{ $billing_service->rec_id } );
                }
            }
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_payer_id

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_payer_id {
    my $self = shift;

    return unless $self->read835;

    my $claim_headers = $self->read835->get_claim_headers;
    return unless $claim_headers and $claim_headers->[0]->{ claim_ids };

    # get the first billing_claim in the file
    # to find out which payer this file came from
    my $billing_claim = eleMentalClinic::Financial::BillingClaim->retrieve( $claim_headers->[0]->{ claim_ids }->[0] );
    return unless $billing_claim;

    my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $billing_claim->billing_file_id );
    return unless $billing_file;
    
    return $billing_file->rolodex_id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 is_electronic()

Object method.

Tells us whether we received this payment electronically or not.  Currently,
this is based on presence or absence of the C<edi> property.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub is_electronic {
    my $self = shift;
    return $self->edi
        ? 1
        : 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 staff_id()

Object method.

Returns the value of the object's C<entered_by_staff_id> property.  This way we
can use L<eleMentalClinic::Base>'s C<personnel()> method to get the
L<eleMentalClinic::Personnel> object associated with this record.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub staff_id {
    my $self = shift;

    return unless $self->entered_by_staff_id;
    return $self->entered_by_staff_id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 last_received_for_rolodex()

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub last_received_for_rolodex {
    my $class = shift;
    my( $rolodex_id ) = @_;

    die 'rolodex_id required' unless $rolodex_id;

    return unless my $date = $class->db->select_one( 
        ['MAX( date_received )'],
        $class->table, 
        "rolodex_id = $rolodex_id"
    );
    return $date->{ max };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 already_processed()

Object method. Check that this file hasn't already been parsed:
interchange_control_number and rolodex_id combination must be unique.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub already_processed {
    my $self = shift;

    return unless $self->interchange_control_number and $self->rolodex_id;

    return unless my $count = $self->db->select_one(
        ['COUNT(*)'],
        $self->table,
        "interchange_control_number = " . $self->interchange_control_number . " AND rolodex_id = " . $self->rolodex_id
    );
    return $count->{ count };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 list_manual_by_rolodex( $rolodex_id )

Class method. Lists only payments entered manually: those that have no edi_filename.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub list_manual_by_rolodex {
    my $class = shift;
    my( $rolodex_id ) = @_;

    die 'rolodex_id is required' unless $rolodex_id;

    return $class->new->db->select_many(
        $class->fields,
        $class->table,
        "WHERE rolodex_id = $rolodex_id AND edi_filename IS NULL",
        "ORDER BY " . $class->primary_key
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_manual_by_rolodex( $rolodex_id )

Class method. Gets only payments entered manually: those that have no edi_filename.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_manual_by_rolodex {
    my $class = shift;
    my( $rolodex_id ) = @_;

    die 'rolodex_id is required' unless $rolodex_id;

    return unless my $payments = $class->list_manual_by_rolodex( $rolodex_id );
    return[ map{ $class->new( $_ )} @$payments ];
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 label( \%options )

Object method. Returns string "payment_date | #payment_number",
for example "2007-03-13 | #444123".

If C<%options> includes a true value for C<include_rolodex>, the return string
is prepended with the name of the Rolodex object associated with this object's
C<rolodex_id>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub label {
    my $self = shift;
    my( $options ) = @_;

    return unless $self->payment_date;

    my $label = $self->payment_date;
    $label .= ' | #' . $self->payment_number
        if $self->payment_number;

    if( $options and %$options ) {
        $label = $self->rolodex->name ." | $label"
            if $options->{ include_rolodex };
    }
    return $label;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 label_rolodex

Wrapper for C<label>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub label_rolodex {
    my $self = shift;
    return $self->label({ include_rolodex => 1 });
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

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
