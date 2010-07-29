package eleMentalClinic::Financial::BillingService;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::BillingService

=head1 SYNOPSIS

The billing service line, relating a service line in a billing claim. Billing service lines
contain billing prognotes.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::Log;
use POSIX qw/ceil/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'billing_service' }
    sub fields { [ qw/
        rec_id billing_claim_id billed_amount billed_units line_number
    /] }
    sub primary_key { 'rec_id' }
    sub accessors_retrieve_one {
        {
            billing_claim => { billing_claim_id => 'eleMentalClinic::Financial::BillingClaim' },
        }
    }
    sub accessors_retrieve_many {
        {
            billing_prognotes => { billing_service_id => 'eleMentalClinic::Financial::BillingPrognote' },
            # XXX could add a 'transactions' method here, but it would not filter out entered_in_error or refunded transactions
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_prognotes

Object method. Gets the service's billing_prognotes and fetches 
an L<eleMentalClinic::ProgressNote> object for each of them.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_prognotes {
    my $self = shift;

    return unless $self->billing_prognotes;
    my @prognotes = map {
        eleMentalClinic::ProgressNote->retrieve( $_->{ prognote_id } )
    } @{ $self->billing_prognotes };

    return \@prognotes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_by_insurance( $prognote_id, $client_insurance_id )

Class method. Returns the L<eleMentalClinic::Financial::BillingService>
object found using the prognote_id and client_insurance_id passed in. 

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_by_insurance {
    my $class = shift;
    my( $prognote_id, $client_insurance_id ) = @_;

    return unless $prognote_id and $client_insurance_id;

    my $where = qq/
        billing_prognote.prognote_id = $prognote_id
        AND   billing_prognote.billing_service_id = billing_service.rec_id
        AND   billing_service.billing_claim_id = billing_claim.rec_id
        AND   billing_claim.client_insurance_id = $client_insurance_id
    /;
    # XXX Note: We're not supporting multiple billings of a prognote to the same 
    # insurance, so we're not expecting multiple matches here 
    my $billing_service = $class->new->db->select_one(
        [ $class->fields_qualified ],
        'billing_service, billing_prognote, billing_claim',
        $where,
    );
    
    return unless $billing_service;

    return $class->new( $billing_service );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 save_payment( $billing_payment_id, $claim[, $service] )

Object method.

Create a new transaction record and mark the payment for this billing_service.
It is assumed that if no $service hashref is passed in, then the service was paid in full.

This method must be wrapped in a transaction, or else failure may leave the database in a bad state.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# XXX : when we upgrade to PG8, add nested transaction
# TODO refactor sending in service and/or not if it's paid fully?
sub save_payment {
    my $self = shift;
    my( $billing_payment_id, $claim, $service ) = @_;
    
    return unless $billing_payment_id and $claim;

    my $transaction = eleMentalClinic::Financial::Transaction->new( { billing_service_id => $self->id } );
    $transaction->billing_payment_id( $billing_payment_id );

    if( $service ){
        $transaction->paid_amount( $service->{ payment_info }{ line_item_provider_payment_amount } );
        # 835 spec says that if this is not used, it's assumed to be 1
        $transaction->paid_units( $service->{ payment_info }{ units_of_service_paid_count } || 1 );

        my $code = $self->concat_charge_code( $service->{ payment_info }{ medical_procedure } );
        $transaction->paid_charge_code( $code );

        if( $service->{ payment_info }{ submitted_medical_procedure } ){
            # This means they paid a different code (the one in medical_procedure)
            # from the one we sent (they disagreed with our charge code choice)
            $code = $self->concat_charge_code( $service->{ payment_info }{ submitted_medical_procedure } );
            $transaction->submitted_charge_code_if_applicable( $code );
        }
        
        my $remarks = $self->concat_remarks( $service->{ remarks } ); 
        $transaction->remarks( $remarks );
    }
    else {
        $transaction->paid_amount( $self->billed_amount );
        $transaction->paid_units( $self->billed_units );

        # XXX There is no way to know what the paid charge code is, if there's no SVC line sent
        # For that matter, the only way to know the submitted charge code 
        # is to look at the original progress note.
        # Could possibly save it when we generate the 837
    }

    # FIXME These are claim-level items, better to store with billing_claim instead - 
    # UNLESS more than one transaction is allowed per billing_claim?
    $transaction->claim_status_code( $claim->{ status_code } );
    $transaction->patient_responsibility_amount( $claim->{ patient_responsibility_amount }  );
    $transaction->payer_claim_control_number( $claim->{ payer_claim_control_number } );

    # XXX Would be good to check for procedure code bundling/unbundling - warn if it happens. 
    # It's not expected to happen, with mental health codes, currently.

    return unless $transaction->save;
   
    # Mark the payment status of this prognote
    if( !$service or ($transaction->paid_amount == $self->billed_amount) ){
        return unless $self->update_billing_status( 'Paid' );
    }
    else {
        return unless $self->update_billing_status;
    }

    return $self->save_service_deductions( $transaction->rec_id, $service->{ deductions } )
        if $service;

    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub concat_charge_code {
    my $self = shift;
    my( $procedure ) = @_;

    return unless $procedure;
    
    if( $procedure->{ code_qualifier } ne 'HC' ) {
        warn "Expecting HCPCS codes for charge codes, while parsing 835";
        return;
    }

    my $modifiers = join '' => @{$procedure->{ modifiers }};
    my $code = $procedure->{ code } . $modifiers;

    return $code;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub concat_remarks {
    my $self = shift;
    my( $remarks ) = @_;

    return unless $remarks;

    my @codes = map { $_->{ code } } @$remarks;
    my $concat = join ':' => @codes;
    return $concat;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 update_billing_status( [$status] )

Object method. Sets the billing_status of $status for each prognote
that's part of this billing service line. Determines if $status should be
Paid or Partial, if it's not passed in.

Note that a prognote is marked 'Partial' paid even if the amount paid is zero
- because this indicates that the payer did process it, and we're not awaiting payment.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub update_billing_status {
    my $self = shift;
    my( $status ) = @_;

    die 'Must call on stored object' unless $self->id;

    # if status is sent, don't check transactions or billed amount - just assume it's correct
    unless( $status ) {
        return unless $self->billed_amount and $self->valid_transaction;
        $status = $self->is_fully_paid ? 'Paid' : 'Partial';
    }
    
    my $prognotes = $self->get_prognotes;
    for my $prognote ( @$prognotes ){
        $prognote->billing_status( $status );
        return 0 unless $prognote->save;
    }

    return 1;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 is_fully_paid

Object method. Adds up all payments to each of the prognotes in this service line
(including payments to this service line). Compares total payment to billed_amount.

XXX See ticket #551 - how should this work when different payers are billed different
amounts due to payers overriding the charge code payment amounts?

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub is_fully_paid {
    my $self = shift;

    die 'Must call on stored object' unless $self->id;
    return 0 unless $self->billed_amount;

    my $total_paid = $self->valid_transaction->paid_amount if $self->valid_transaction;
    $total_paid += $self->get_total_paid_previous;

    return 0 unless $total_paid;

    # Avoid floating point error
    return $self->__about_equal($total_paid, $self->billed_amount) ? 1 : 0;
}

sub __about_equal {
    my $self = shift;
    my($this, $that, $epsilon) = @_;
    $epsilon = 0.0000001 unless defined $epsilon;

    return abs($this - $that) < $epsilon;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_total_paid_previous([ $rolodex_ids ])

Object method.

Adds together all payments made for all prognotes that this billing_service line contains.

Will only include payments by the list of insurers if that's sent in.

Does NOT include the amount paid by this billing_service's insurer,
because only previous payments are included.
So if this billing_prognote's insurer == rolodex_id, will return zero.

Uses get_other_billing_services, see that method for more details on how
previous billings are found, and what edge cases are not allowed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_total_paid_previous {
    my $self = shift;
    my( $rolodex_ids ) = @_;

    die 'Must call on stored object' unless $self->id;

    my $total = 0;
    my $billing_services;

    # Get other billing_services that have been billed before for our same set of notes
    # FIXME this is a bit of ugliness - could refactor get_other_billing_services to take an array of rolodex_ids
    if( $rolodex_ids ) {
        push @$billing_services => @{ $self->get_other_billing_services( $_ ) }
            for @$rolodex_ids;
    }
    else {
        $billing_services = $self->get_other_billing_services;
    }
    
    # Find payments for those billing_services
    $total += $_->transaction_amount
        for @$billing_services;

    return sprintf "%.2f", $total;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_other_billing_services([ $rolodex_id ])

Object method. Gets all matching service lines that contain the same group
of prognotes as ours does, or that contain a smaller subset of our notes.

Errors are thrown if a matching service with our note(s) contains other notes.

XXX NOTE that it doesn't check if the billing_services were actually billed.
Could probably refactor to filter unbilled ones out.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_other_billing_services {
    my $self = shift;
    my( $rolodex_id ) = @_;
    my $billing_services = [];

    die 'Must call on stored object' unless $self->id;

    # database table relationships 
    # prognote 1-n billing_prognotes n-1 billing_service

    # Prognotes in our service 
    my $prognotes = $self->get_prognotes;
    for my $prognote ( @$prognotes ) {
        
        # Use to find any billing_prognotes its ever been a part of 
        my $possible_billing_prognotes = $prognote->billing_prognotes;
        for my $possible ( @$possible_billing_prognotes ){
            
            # Use to find the billing_services
            my $possible_service = $possible->billing_service;

            # Don't include our own service
            next if $possible_service->rec_id == $self->rec_id;
            # Or services we've already looked at
            next if grep { $possible_service->rec_id == $_->rec_id } @$billing_services;

            # Match only those that are billed to rolodex_id
            next if $rolodex_id and $possible_service->billing_claim->billing_file->rolodex_id != $rolodex_id;

            if( @$prognotes == 1 ){
                if( @{ $possible_service->billing_prognotes } != 1 ){
                    # error 1: our service has 1 note, we find other services with combined notes
                    die "Notes previously sent combined are now sent individually; not supported";
                }
                push @$billing_services => $possible_service;
            }
            else {

                # Add in any service lines that contain a subset of our prognotes
                if( $self->contains_subset_prognotes( $possible_service ) ){
                    push @$billing_services => $possible_service;
                }
                else {
                    # error 2: our service has > 1 note, we find service lines that are not an exact match
                    die "Notes previously sent as one combined group are not all getting sent combined now; not supported";
                }
            }
        }
    }

    my @sorted_services = sort { $a->rec_id <=> $b->rec_id } @$billing_services;
    return \@sorted_services;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 contains_subset_prognotes( $other_service )

Object method. Tests if the given service contains the same
or a smaller subset of prognotes than ours does.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub contains_subset_prognotes {
    my $self = shift;
    my( $other_service ) = @_;

    die 'other service is required' unless $other_service;

    my $my_prognotes = $self->get_prognotes;
    my $other_prognotes = $other_service->get_prognotes;
   
    # check if each of the notes in the other set is also in our set
    for my $note ( @$other_prognotes ){
        return 0 unless grep { $note->rec_id == $_->rec_id } @$my_prognotes;
    }

    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 save_service_deductions( $transaction_id, $deductions )

Object method.

This method must be wrapped in a transaction, or else failure may leave the database in a bad state.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# XXX : when we upgrade to PG8, add nested transaction
sub save_service_deductions {
    my $self = shift;
    my( $transaction_id, $deductions ) = @_;

    return unless $transaction_id;

    for( @$deductions ){
        my $deduction = eleMentalClinic::Financial::TransactionDeduction->new( { transaction_id => $transaction_id } );
        $deduction->amount( $_->{ deduction_amount } );
        $deduction->units( $_->{ deduction_quantity } );
        $deduction->group_code( $_->{ group_code } );
        $deduction->reason_code( $_->{ reason_code } );

        return unless
            $deduction->save;
    }

    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 charge_code( $rolodex_id )

Object method.

Returns the L<eleMentalClinic::ValidData> object corresponding to this
service line's charge code, using the first prognote associated with this
line, since they should all have the same code.  Any insurer-specific charge code 
customizations at time of note will be accounted for.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub charge_code {
    my $self = shift;
    my( $rolodex_id ) = @_;
    
    die 'Billing service has no prognotes' 
        unless my $prognotes = $self->get_prognotes;
    return $prognotes->[0]->charge_code( $rolodex_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 amount_to_bill

Object method.

Calculates the units and dollar amount to bill for this prognote.

Returns ( $amount, $units )

FIXME: This method is getting called twice: once when the 837/hcfa is generated, and again when the note is saved as "billed".
Seems like this should be refactored. But it either means I save an "amount to be billed" as well as "amount billed",
or I add a flag to the billing_service table: "billed". This would change some reports I bet.
This would also solve a potential bug where a note is not billed due to charge code problems, but is still marked
as billed (save_as_billed) if the charge code problems are fixed by the time it gets to that code. (Unlikely but possible).
See also ticket #567.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub amount_to_bill {
    my $self = shift;
    my $class = ref $self;

    die "Billing Claim's client_insurance_id is required" unless $self->billing_claim and $self->billing_claim->client_insurance_id;

    my $insurance = eleMentalClinic::Client::Insurance->retrieve( $self->billing_claim->client_insurance_id );
    my $charge_code = $self->charge_code( $insurance->rolodex_id );
    die 'Charge code for this service line has no name, service line ' . $self->rec_id unless $charge_code->{ name };
  
    my $total_duration = 0;
    my( $amount, $units );
    eval {

        for my $billing_prognote ( @{ $self->billing_prognotes } ){
            
            my $prognote = $billing_prognote->prognote;
            die "Progress note's amount_to_bill cannot be calculated: note is missing a start_date and/or end_date." 
                unless $prognote->start_date and $prognote->end_date;

            my ( $d, $h, $m ) = @{ $prognote->note_duration };
            $total_duration += $d * 24 * 60 + $h * 60 + $m;
        }

        ( $amount, $units ) = $class->calculate_amount_to_bill( $charge_code, $total_duration );
        die 'Billing Service ' . $self->id . ' has zero charge amount or units' 
            unless( $amount and $amount > 0 and $units );
    };
    die "Error calculating amount_to_bill for billing_service " . $self->id . ": $@"
        if $@;

    return ( $amount, $units );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 calculate_amount_to_bill( $charge_code, $duration )

Class method.

Calculates the units and dollar amount to bill for this duration of time, 
using one of three methods specified by the charge code's cost_calculation_method.

Returns ( $amount, $units )


=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub calculate_amount_to_bill {
    my $class = shift;
    my( $charge_code, $duration ) = @_;
    my( $units, $charge_amount );

    die 'Charge Code is required' unless $charge_code;
    die 'Duration is required' unless $duration;

    my $error = "Billing Service's amount_to_bill cannot be calculated: charge code is missing minutes_per_unit and/or dollars_per_unit.";
    $error .= " Charge Code Id: " . $charge_code->{ charge_code_id } if $charge_code->{ charge_code_id };  
    die $error 
        unless $charge_code->{ minutes_per_unit }
        and    $charge_code->{ dollars_per_unit } and $charge_code->{ dollars_per_unit } > 0;

    # Depending on type of charge_code
    # use one of three methods:
    if( $charge_code->{ cost_calculation_method } eq 'Dollars per Unit' ) {
    
        $units = $duration / $charge_code->{ minutes_per_unit };
        
        # round up to nearest integer before calculating dollar amount
        $units = ceil( $units );
        $charge_amount = $units * $charge_code->{ dollars_per_unit };
    }
    elsif( $charge_code->{ cost_calculation_method } eq 'Pro Rated Dollars per Unit' ) {

        $units = $duration / $charge_code->{ minutes_per_unit };
        $charge_amount = $units * $charge_code->{ dollars_per_unit };

        # round up the units to nearest integer after calculating dollar amount
        $units = ceil( $units );
    }
    else { # Per Session -- default, Amy said that this is the most common for our code set 

        $units = 1;
        $charge_amount = $charge_code->{ dollars_per_unit };
    }

    $charge_amount = sprintf "%.2f", $charge_amount;

    return ( $charge_amount, $units );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 service_dates

Object method. Returns the prognote start and end dates (time stripped off), for the 
first prognote associated with this service line. All prognotes combined
into this line should be on the same date. (But will of course be at different times).

XXX Note that two notes with the same start date are combined - but the end date
is ignored. This is a case we haven't considered: two notes with same start but different end dates.
Not likely at this point.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub service_dates {
    my $self = shift;

    die 'Billing service has no prognotes' 
        unless my $prognotes = $self->get_prognotes;

    my $start_date = $prognotes->[0]->start_date;
    $start_date =~ s/ \d\d:\d\d:\d\d//; # strip off the time 
    my $end_date = $prognotes->[0]->end_date;
    $end_date =~ s/ \d\d:\d\d:\d\d//;
    
    return( $start_date, $end_date );    
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 facility_code

Object method. Returns the facility code from the first prognote
associated with this billing service line. Looks up the code from
the valid_data record matching the prognote's note_location_id. 
All prognotes combined on this line must have the same location.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub facility_code {
    my $self = shift;

    my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
    die 'Billing service has no prognotes' 
        unless my $prognotes = $self->get_prognotes;

    return $valid_data->get( '_prognote_location', $prognotes->[0]->note_location_id )->{ facility_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_other_insurances_paid_amount

Object method. Used for the HCFA, it calculates the amount paid
for all billing services that have the exact same prognotes as
this billing service line.

Also used in the Medicaid Adjustment form.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_other_insurances_paid_amount {
    my $self = shift;
   
    die 'Must call on stored object' unless $self->id;

    my $insurances = $self->billing_claim->get_other_insurances;
    return '0.00' unless $insurances;

    my @rolodex_ids;
    for( @$insurances ){
        push @rolodex_ids => $_->rolodex_id;
    }

    return $self->get_total_paid_previous( \@rolodex_ids );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 service_line( $is_hcfa )

Object method. Retrieves all the data needed for a service line in an 837,
from this object.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub service_line {
    my $self = shift;
    my( $is_hcfa ) = @_;

    my( $charge_amount, $units ) = $self->amount_to_bill;
    my $facility_code = $self->facility_code;

    my( $service, $modifiers ) = eleMentalClinic::ECS::Write837->split_charge_code( $self->charge_code->{ name } );
    my( $start_date, $end_date ) = $self->service_dates;        

    my $service_line = {
        service                 => $service,
        modifiers               => $modifiers,
        facility_code           => $facility_code,
        diagnosis_code_pointers => [ '1', ],  # XXX This could get further defined. There are no diagnoses assoc with prognotes currently...
        charge_amount           => "$charge_amount",
        units                   => "$units",
    };

    if( $is_hcfa ) {
        $start_date = eleMentalClinic::Financial::HCFA->get_shortdate_f( $start_date );
        $end_date = eleMentalClinic::Financial::HCFA->get_shortdate_f( $end_date );
        my $paid_amount = $self->get_other_insurances_paid_amount;

        # HCFA-only additions
        $service_line->{ start_date }   = $start_date;
        $service_line->{ end_date }     = $end_date;
        $service_line->{ paid_amount }  = "$paid_amount" || '0.00';
        $service_line->{ emergency }    = undef; # Not used currently
    }
    else {
        $start_date = eleMentalClinic::ECS::Write837->get_date_f( $start_date );

        # 837-only additions
        $service_line->{ billing_service_id } = $self->rec_id;
        $service_line->{ service_date }       = $start_date;
    }

    return $service_line;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_unpaid( $rolodex_id )

Class method. 

Returns a hashref: 
    { 
        client_id => { client_name => name, billing_services => [BillingService objects], },
        client_id => { client_name => name, billing_services => [BillingService objects], }, 
    }.

Billing Services are all those that have been billed to the payer (rolodex_id),
but have no Transactions recorded for them (grouped by client_id).

Note that it's get_unPAID, but it really means get_un"processed by the payer". A note which is
processed and has zero $ paid will not show up in this list.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_unpaid {
    my $class = shift;
    my( $rolodex_id ) = @_;

    return unless $rolodex_id;

    my $client_name_clause = eleMentalClinic::Client->name_clause;
    my $where = qq/ 
        billing_service.rec_id IN (SELECT rec_id FROM view_unpaid_billed_services)
        AND billing_service.billing_claim_id = billing_claim.rec_id
        AND billing_claim.billing_file_id = billing_file.rec_id
        AND billing_service.rec_id = billing_prognote.billing_service_id
        AND billing_prognote.prognote_id = prognote.rec_id
        AND billing_file.rolodex_id = ?
        AND client.client_id = prognote.client_id
    /;
    my $query = qq/
        SELECT DISTINCT billing_service.*, prognote.client_id, $client_name_clause AS client_name
        FROM billing_service, billing_prognote, billing_file, billing_claim, prognote, client
        WHERE $where
        ORDER BY client_name, billing_service.rec_id
    /;

    my $billing_services = $class->db->fetch_hashref( $query, $rolodex_id );
    return unless $billing_services;

    my %billservices_byclient;

    for( @$billing_services ){
        $billservices_byclient{ $_->{ client_id } }{ client_name } = $_->{ client_name };
        push @{ $billservices_byclient{ $_->{ client_id } }{ billing_services } }  => $class->new( $_ );
    }

    return \%billservices_byclient;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_other_insurance_patient_liability( $rolodex_id )

Object method. Used for the Medicaid Adjustment form.

Calculates the total that the client's other insurances
have paid, EXCLUDING the $rolodex_id insurance, AND the billing_prognote's
insurer; PLUS this billing_prognote's client_insurance co_pay.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_other_insurance_patient_liability {
    my $self = shift;
    my( $rolodex_id ) = @_;
  
    die 'Rolodex is required' unless $rolodex_id;

    my $rolodex_paid = $self->get_total_paid_previous( [ $rolodex_id ] ) || 0;
    my $total_paid = $self->get_other_insurances_paid_amount || 0;

    # Also add this client's co_pay
    my $co_pay = $self->billing_claim->client_insurance->co_pay_amount || 0;

    my $total = ($total_paid - $rolodex_paid) + $co_pay;

    return sprintf "%.2f", $total;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 save_as_billed( $line_number )

Object method.

Save the billed information for this note.
This method must be wrapped in a transaction, or else failure may leave the database in a bad state.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# XXX : when we upgrade to PG8, add nested transaction
sub save_as_billed {
    my $self = shift;
    my( $line_number, $manually ) = @_;
    my $billing_status = $manually ? 'BilledManually' : 'Billed';

    die 'Line number is required' unless $line_number;

    my( $charge_amount, $units );
    eval { ( $charge_amount, $units ) = $self->amount_to_bill; };
    if( $@ ){
        warn $@;
        return;
    }

    $self->billed_amount( "$charge_amount" ) if $charge_amount;
    $self->billed_units( "$units" ) if $units;
    $self->line_number( $line_number );
    return unless $self->save;

    # Mark prognote's billing status as 'Billed'
    return $self->update_billing_status( $billing_status );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 valid_transaction

Object method. Returns the first transaction record for this
billing service that is not entered in error, or refunded.
XXX Note that the system does not expect more than one transaction
to match a billing_service.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub valid_transaction {
    my $self = shift;

    die 'Must call on stored object' unless $self->id;

    my $id = $self->id;
    my $where = qq/
        billing_service_id = $id 
        AND (entered_in_error != TRUE OR entered_in_error IS NULL)
        AND (refunded != TRUE OR refunded IS NULL)
    /;

    my $transaction = $self->new->db->select_one(
        [ 'transaction.*' ],
        'transaction',
        $where,
        'ORDER BY transaction.rec_id'
    );
    return unless $transaction;

    return eleMentalClinic::Financial::Transaction->new( $transaction );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 all_transactions()

Object method. Returns all transactions for this billing service,
including entered_in_error and refunded ones. Could have used an accessors_retrieve_many,
but I kept it separate so that it's not accidentally called when really
what's wanted is valid_transaction.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub all_transactions {
    my $self = shift;
    
    die 'Must call on stored object' unless $self->id;

    my $id = $self->id;
    my $transactions = $self->new->db->select_many(
        [ 'transaction.*' ],
        'transaction',
        "WHERE billing_service_id = $id",
        'ORDER BY transaction.rec_id'
    );
    return unless $transactions;

    return[ map{ eleMentalClinic::Financial::Transaction->new( $_ )} @$transactions ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 transaction_amount()

Object method. Returns the paid amount for the valid transaction
for this service, if any.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub transaction_amount {
    my $self = shift;

    my $transaction = $self->valid_transaction;

    # we want to return 0 instead of 0.00 
    return 0 unless $transaction;
    return 0 unless $transaction->paid_amount > 0;

    return sprintf "%.2f", $transaction->paid_amount;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 new_billing_prognote(prognote_id)

Object method to create a new BillingPrognote for a BillingService.

 * prognote_id - id of the actual eleMentalClinic::ProgressNote being 
   linked. (required)

Returns BillingPrognote created.

dies if unable to store in database.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub new_billing_prognote {
    my $self = shift;
    my $prognote_id = shift;
    return unless $prognote_id and $self->id;
    
    my $billing_prognote = eleMentalClinic::Financial::BillingPrognote->new({
        billing_service_id  => $self->rec_id,
        prognote_id         => $prognote_id,
    });
    die 'Unable to save new billing_prognote' unless $billing_prognote->save;

    return $billing_prognote;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 save_manual_payment( $vars )

Object method. Takes a hash of variables that are used to create the transaction
for this manual payment, as well as:

    deduction_1, deduction_2, deduction_3, deduction_4 : amounts deducted
    reason_1,    reason_2,    reason_3,    reason_4    : reasons for each deduction

Returns an error string on failure, otherwise null.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub save_manual_payment {
    my $self = shift;
    my( $vars ) = @_;

    die 'Must call on stored object' unless $self->id;
    die 'Missing parameters' unless $vars;

    my $transaction = eleMentalClinic::Financial::Transaction->new({
        %$vars,
    });
    # only save the submitted code if they've entered something for paid_charge_code 
    $transaction->submitted_charge_code_if_applicable( '' )
        unless $transaction->paid_charge_code;

    # check that deductions add up to billed amount
    my $deduction_sum;
    $deduction_sum += $vars->{ "deduction_$_" } || 0 
        for( 1 .. 4 );

    if( my $unaccounted = $self->billed_amount - ($transaction->paid_amount + $deduction_sum)  ){
        return 'Amount paid + deductions must add up to billed amount. Unaccounted for: $' . sprintf "%.2f", $unaccounted;
    }

    # check that deductions have reasons
    for( 1 .. 4 ) {
        if( $vars->{ "deduction_$_" } xor $vars->{ "reason_$_" } ){
            return 'Deductions must have both an amount and a reason.';
        }
    }

    # start database transaction
    $self->db->transaction_begin;

    unless( $transaction->save ){
        $self->db->transaction_rollback;
        die 'Unable to save transaction record!';
    }

    # now add the transaction deductions
    for ( 1 .. 4 ) {

        next unless $vars->{ "deduction_$_" } and $vars->{ "reason_$_" };

        my $transaction_deduction = eleMentalClinic::Financial::TransactionDeduction->new({
            transaction_id  => $transaction->rec_id,
            amount          => $vars->{ "deduction_$_" },
            reason_code     => $vars->{ "reason_$_" },
        });
        
        unless( $transaction_deduction->save ){
            $self->db->transaction_rollback;
            die 'Unable to save transaction deduction!';
        }
    }

    # commit database transaction
    $self->db->transaction_commit;

    $self->update_billing_status;

    return;
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
