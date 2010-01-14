package eleMentalClinic::Financial::Transaction;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::Transaction

=head1 SYNOPSIS

The transaction, which records a payment for a billing prognote.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::ProgressNote;
use eleMentalClinic::Financial::BillingClaim;
use eleMentalClinic::Financial::BillingCycle;
use eleMentalClinic::Financial::TransactionDeduction;
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'transaction' }
    sub fields { [ qw/
        rec_id billing_service_id billing_payment_id
        paid_amount paid_units
        claim_status_code patient_responsibility_amount
        payer_claim_control_number paid_charge_code
        submitted_charge_code_if_applicable
        remarks entered_in_error refunded
    /] }
    sub methods {[ qw/
        billing_claim_id billing_file_id billing_cycle_id
    /]}
    sub primary_key { 'rec_id' }
    sub accessors_retrieve_one {
        {
            billing_service => { billing_service_id => 'eleMentalClinic::Financial::BillingService' },
            billing_payment => { billing_payment_id => 'eleMentalClinic::Financial::BillingPayment' },
        }
    }
    sub accessors_retrieve_many {
        {
            deductions => { transaction_id => 'eleMentalClinic::Financial::TransactionDeduction' },
        };
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 populate()

Object method.

Runs one query to set the value of the following accessors:

=over 4

=item billing_claim_id

=item billing_file_id

=item billing_cycle_id

=back

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub populate {
    my $self = shift;

    die 'Must be called on stored object'
        unless $self->id;
    my $query = qq/
        SELECT
            billing_service.rec_id         AS billing_service_id,
            billing_claim.rec_id           AS billing_claim_id,
            billing_file.rec_id            AS billing_file_id,
            billing_cycle.rec_id           AS billing_cycle_id
        FROM transaction
            LEFT JOIN billing_service ON transaction.billing_service_id = billing_service.rec_id
            LEFT JOIN billing_claim ON billing_service.billing_claim_id = billing_claim.rec_id
            LEFT JOIN billing_file ON billing_claim.billing_file_id = billing_file.rec_id
            LEFT JOIN billing_cycle ON billing_file.billing_cycle_id = billing_cycle.rec_id
        WHERE transaction.rec_id = ?
    /;

    return unless
        my $ids = $self->db->fetch_hashref( $query, $self->id );
    if( @$ids != 1 ) {
        my $id = $self->id;
        die "Got more than one set of data for transaction $id.  This should never happen."
    }

    $self->$_( $ids->[ 0 ]{ $_ })
        for keys %{ $ids->[ 0 ]};
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 billing_claim()

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub billing_claim {
    my $self = shift;

    $self->populate unless $self->billing_claim_id;
    return unless $self->billing_claim_id;
    return eleMentalClinic::Financial::BillingClaim->retrieve( $self->billing_claim_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 billing_cycle()

Object method.

Returns the associated L<eleMentalClinic::Financial::BillingCycle> object.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub billing_cycle {
    my $self = shift;

    $self->populate unless $self->billing_cycle_id;
    return unless $self->billing_cycle_id;
    return eleMentalClinic::Financial::BillingCycle->retrieve( $self->billing_cycle_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 deductions()

Object method.

Returns all L<eleMentalClinic::Financial::TransactionDeduction> objects associated with this object.

=cut

# implemented by accessors_retrieve_many

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 client()

Object method.

Returns the L<eleMentalClinic::Client> object associated with this object.

FIXME: wraps the C<billing_service> and C<billing_prognotes> methods, so could be more efficient.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub client {
    my $self = shift;
    my $billing_prognotes = $self->billing_service->billing_prognotes;
    return unless $billing_prognotes and $billing_prognotes->[0];

    my $prognote = $billing_prognotes->[0]->prognote;
    return unless $prognote;

    return $prognote->client;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_for_adjustment( $client_id, $rolodex_id )

Class method.

Used for Medicaid Adjustment - NOT 'adjustments' in an 835 (now called 'deductions').
Returns list of all Transaction objects associated with C<$client_id> and
C<$rolodex_id>, organized in the following data structure:

    payment_id => {
        payment_date    => '2006-06-29'
        payment_number  => '2006-06-29'
        billing_claims => {
            billing_claim_id => {
                personnel => { personnel object }
                billed_date => '2006-06-29 16:04:25'
                transactions => [
                    .. transaction objects ..
                ],
            },
        },
    }

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_for_adjustment {
    my $class = shift;
    my( $client_id, $rolodex_id ) = @_;

    croak 'Client id is required'
        unless $client_id;
    croak 'Rolodex id is required'
        unless $rolodex_id;

    my $fields = $class->fields_qualified;
    my $where = 'billing_claim.client_id = ? and billing_file.rolodex_id = ?';
    my $query = qq/
        SELECT $fields, billing_payment.rec_id AS billing_payment_id, billing_payment.payment_date, billing_payment.payment_number, 
            billing_claim.rec_id AS billing_claim_id, billing_claim.staff_id, billing_file.submission_date
        FROM transaction LEFT JOIN billing_service ON transaction.billing_service_id = billing_service.rec_id
            LEFT JOIN billing_claim ON billing_service.billing_claim_id = billing_claim.rec_id
            LEFT JOIN billing_file ON billing_claim.billing_file_id = billing_file.rec_id
            LEFT JOIN billing_payment ON transaction.billing_payment_id = billing_payment.rec_id
        WHERE $where
            AND (transaction.entered_in_error != TRUE OR transaction.entered_in_error IS NULL)
            AND (transaction.refunded != TRUE OR transaction.refunded IS NULL)
        ORDER BY billing_payment.rec_id, billing_claim.rec_id, transaction.rec_id
    /;

    return unless
        my $results = $class->db->fetch_hashref( $query, $client_id, $rolodex_id );
    
    my %payments;
    
    for my $result ( @$results ){

        # prepare empty hashrefs if necessary
        $payments{ $result->{ billing_payment_id } } ||= {};
        $payments{ $result->{ billing_payment_id } }{ billing_claims } ||= {};
        $payments{ $result->{ billing_payment_id } }{ billing_claims }{ $result->{ billing_claim_id } } ||= {};
        
        # fill in the data
        $payments{ $result->{ billing_payment_id } }{ payment_date } ||= $result->{ payment_date };
        $payments{ $result->{ billing_payment_id } }{ payment_number } ||= $result->{ payment_number };
        $payments{ $result->{ billing_payment_id } }{ billing_claims }{ $result->{ billing_claim_id } }{ personnel } 
            ||= eleMentalClinic::Personnel->retrieve( $result->{ staff_id } );
        $payments{ $result->{ billing_payment_id } }{ billing_claims }{ $result->{ billing_claim_id } }{ billed_date } ||= $result->{ submission_date };
        push @{ $payments{ $result->{ billing_payment_id } }{ billing_claims }{ $result->{ billing_claim_id } }{ transactions } } => $class->new( $result );
    }

    return \%payments;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 refund()

Object method to mark this Transaction as refunded.

dies if unable to update the database.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub refund {
    my $self = shift;
    
    die 'Unable to refund a transaction that has not been stored in the database.' unless $self->id;

    $self->refunded(1)->save or die 'Unable to store refunded state.';
    
    return 1; 
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Partlow L<jpartlow@opensourcery.com>

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
