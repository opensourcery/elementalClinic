package eleMentalClinic::Financial::BillingClaim;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::BillingClaim

=head1 SYNOPSIS

The billing claim, which contains multiple billing progress notes.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::Financial::BillingService;
use eleMentalClinic::Financial::BillingPrognote;
use eleMentalClinic::Financial::Transaction;
use eleMentalClinic::Financial::TransactionDeduction;
use eleMentalClinic::Financial::ClaimsProcessor;
use eleMentalClinic::Financial::HCFA;
use eleMentalClinic::Financial::BillingPayment;
use eleMentalClinic::Log;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'billing_claim' }
    sub fields { [ qw/
        rec_id billing_file_id staff_id client_id
        client_insurance_id insurance_rank
        client_insurance_authorization_id
    /] }
    sub primary_key { 'rec_id' }
    sub accessors_retrieve_one {
        {
            client_insurance    => { client_insurance_id => 'eleMentalClinic::Client::Insurance' },
            billing_file        => { billing_file_id => 'eleMentalClinic::Financial::BillingFile' },
            personnel           => { staff_id   => 'eleMentalClinic::Personnel' },
        }
    }
    sub accessors_retrieve_many {
        {
            billing_services => { billing_claim_id => 'eleMentalClinic::Financial::BillingService' },
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 new_service()

Object method creates a BillingService associated with this BillingClaim.

Requires a valid BillingClaim.

dies if it cannot store the new billing_service record.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub new_service {
    my $self = shift;
    return unless $self->id;
   
    my $service = eleMentalClinic::Financial::BillingService->new({
        billing_claim_id    => $self->rec_id,
    });
    die 'Unable to save new billing_service' unless $service->save;

    return $service;
}

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO - This refactor requires either passing in a structure of prognotes
# sorted by combined_notes key or a refactor of how notes are sorted and
# organized in BillingFile->add_claims.
#
#=head2 add_services(prognotes)
#
#Object method to create new BillingServices for this BillingClaim
#from the passed array of prognotes.
#
# * prognotes - array ref of Prognote objects. (required, non-zero)
#
#Returns true if successful.
#
#dies if any problems storing to the database are encountered.
#
#=cut
#
## ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
#sub add_services {
#    my $self = shift;
#    my $prognotes = shift;
#    # prognotes must exist and be non-zero
#    return unless $prognotes and scalar(@$prognotes) > 0;
#    # billing_claim must exist
#    return unless $self->id;
#
#    for my $combined_note ( @$prognotes ) {
#
#        # Create a new BillingService object for all the ones that match
#        # (it will usually be just one per prognote)
#        my $billing_service = $billing_claim->new_service;
#
#        for my $prognote ( @$combined_note ) {
#            my $billing_prognote = eleMentalClinic::Financial::BillingPrognote->new({
#                billing_service_id  => $billing_service->rec_id,
#                prognote_id         => $prognote->rec_id,
#            });
#            die 'Unable to save new billing_prognote' unless $billing_prognote->save;
#
#        }
#    }
#
#    return 1;
#}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 prognotes_to_service_lines

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub prognotes_to_service_lines {
    my $self = shift;

    die 'Must call on stored object' unless $self->id; 

    my $service_lines;
    my $claim_data = {
        total_amount        => 0,
        claim_facility_code => undef,
    };

    my $billing_services = $self->billing_services;
    die 'No billing service lines found for this billing claim' unless $billing_services;
    for my $billing_service ( @$billing_services ){
        
        my $line; 
        eval { $line = $billing_service->service_line; };
        if( $@ ){
            Log_defer( "Error getting service line, billing_service " . $billing_service->rec_id . ": $@" );
            next;
        }
        push @$service_lines => $line;

        $claim_data->{ total_amount } += $line->{ charge_amount };

        # XXX Ideally, choose the facility code that is used most often. For now, use the first one.
        $claim_data->{ claim_facility_code } ||= $line->{ facility_code };
    }

    return( $service_lines, $claim_data );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 rendering_provider

Object method.

If the ECS file requires rendering provider IDs, this sends them. But
if it sends any IDs, it has to send an NPI and taxonomy code for each rendering provider
(there's one per billing claim). So this method dies if it can't find one.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub rendering_provider {
    my $self = shift;
   
    die 'Object requires staff_id and billing_file_id' unless $self->staff_id and $self->billing_file_id;

    my $personnel = eleMentalClinic::Personnel->retrieve( $self->staff_id );
    my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $self->billing_file_id );
    die "This claim's billing_file requires a claims_processor" unless $billing_file->claims_processor;

    # Don't send any of these segments unless we are sending one for each provider
    return unless $billing_file->requires_rendering_provider_ids;

    my $use_personnel_id = $billing_file->claims_processor->send_personnel_id;
    my $rendering_provider_id = $use_personnel_id ? $personnel->id : $personnel->national_provider_id;

    my $error = 'This claims processor requires information about each clinician (rendering provider). '; 
    die $error . 'Personnel staff_id [' . $self->staff_id . '] has no taxonomy_code.'
        unless $personnel->taxonomy_code;

    die $error . 'Personnel staff_id [' . $self->staff_id . '] has no national_provider_id.'
        unless $personnel->national_provider_id or $use_personnel_id;

    my $rendering_provider = {
        fname                    => $personnel->fname,
        lname                    => $personnel->lname,
        mname                    => $personnel->mname,
        name_suffix              => $personnel->name_suffix,
        taxonomy_code            => $personnel->taxonomy_code,
        medicaid_provider_number => $personnel->medicaid_provider_number,  # These three are different from the Clinic's number
        medicare_provider_number => $personnel->medicare_provider_number,
        rendering_provider_id    => $rendering_provider_id,
        id_is_employer_id        => $use_personnel_id,
    };

    return $rendering_provider;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 hcfa_rendering_provider

Object method.

Not as restrictive as ECS rendering_provider data. Sends the NPI if it
exists, otherwise sends the clinic's NPI.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub hcfa_rendering_provider {
    my $self = shift;
   
    die 'Object requires staff_id' unless $self->staff_id;

    my $personnel = eleMentalClinic::Personnel->retrieve( $self->staff_id );
    my $npi = $personnel->national_provider_id || $self->config->org_national_provider_id;

    my $rendering_provider = {
        national_provider_id     => $npi 
    };

    return $rendering_provider;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_latest_prognote_date {
    my $self = shift;

    return unless $self->rec_id;

    my $claim_id = $self->rec_id;
    my $where = qq/
        billing_service.billing_claim_id = $claim_id
        AND billing_prognote.billing_service_id = billing_service.rec_id
        AND prognote.rec_id = billing_prognote.prognote_id
    /;

    my $date = $self->db->select_one( 
        [ 'MAX( prognote.end_date )' ],
        'billing_service, billing_prognote, prognote',
        $where
    );

    $date->{ max } =~ s/^(\d{4}-\d{2}-\d{2}).*/$1/;
    return $date->{ max };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 diagnosis_codes( [$hcfa] )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub diagnosis_codes {
    my $self = shift;
    my( $hcfa ) = @_;

    die 'Object requires client_id' unless $self->client_id;

    my $diagnosis_date = $self->get_latest_prognote_date;

    my $diagnosis_codes;

    # XXX For now, just send the Axis I primary diagnosis. Technically,
    # each service should be linked to a diagnosis, so it should be perhaps sending 
    # a more specific diagnosis, or multiple ones
    #for( qw/ diagnosis_1a diagnosis_1b diagnosis_1c / ){
    
    for( qw/ diagnosis_1a / ){

        # Get the placement episode from when the latest progress note took place
        my $episode = eleMentalClinic::Client::Placement::Episode->get_by_client( $self->client_id, $diagnosis_date );
        next unless $episode;

        my $diagnosis_code;
        if( $episode->final_diagnosis ){
            $diagnosis_code = $episode->final_diagnosis->$_;
        } 
        elsif( $episode->initial_diagnosis ){
            $diagnosis_code = $episode->initial_diagnosis->$_;
        }

        $diagnosis_code = $self->diagnosis_code_f( $diagnosis_code, $hcfa );
        next unless $diagnosis_code;

        push @$diagnosis_codes => $diagnosis_code;
    }
 
    return $diagnosis_codes; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 diagnosis_code_f( $code[, $hcfa] )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub diagnosis_code_f {
    my $self = shift;
    my( $code, $hcfa ) = @_;

    return unless $code;
    return unless $code =~ /\w{3}\.\w{2}/;

    # Remove the diagnosis text
    # FIXME The diagnosis codes shouldn't always have 2 digits after the decimal.
    # They do now in the database, but technically that isn't correct for all codes.
    $code =~ s/(\w{3}\.\w{2}).*/$1/;
    return if $code eq '000.00';

    if( $hcfa ){
        # HCFA: Replace the decimal point with space 
        $code =~ s/\./ /g;
    }
    else {
        # EDI: Do not transmit the decimal points in the diagnosis codes. The decimal point is assumed
        $code =~ s/\.//;
    }

    return $code;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_other_insurance_subscriber( $client_insurance )

Object method.

Internal method returning a hashref of data relating the insurance 
subscriber. The subscriber may or may not be the client.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_other_insurance_subscriber {
    my $self = shift;
    my( $insurance ) = @_;

    return unless $insurance and $insurance->insured_relationship_id;

    my $subscriber;
    if( $insurance->insured_relationship_id == 1 ) {
        
        # XXX Refactor: this is duplicated in BillingFile
        my $client = eleMentalClinic::Client->retrieve( $insurance->client_id );
        my $dob = eleMentalClinic::ECS::Write837->get_date_f( $client->dob );
        my $gender = eleMentalClinic::ECS::Write837->get_gender_f( $client->sex );
        $subscriber = {
            dob             => $dob,
            gender          => $gender,
            lname           => $client->lname,
            fname           => $client->fname,
            mname           => $client->mname,
            name_suffix     => $client->name_suffix,
            address1        => $client->address->address1,
            address2        => $client->address->address2,
            city            => $client->address->city,
            state           => $client->address->state,
            zip             => $client->address->post_code,
        };
    }
    else {
        # The subscriber is someone other than the client
        my $dob = eleMentalClinic::ECS::Write837->get_date_f( $insurance->insured_dob );
        my $gender = eleMentalClinic::ECS::Write837->get_gender_f( $insurance->insured_sex );
        $subscriber = {
            dob             => $dob,
            gender          => $gender,
            lname           => $insurance->insured_lname,
            fname           => $insurance->insured_fname,
            mname           => $insurance->insured_mname,
            name_suffix     => $insurance->insured_name_suffix,
            address1        => $insurance->insured_addr,
            address2        => $insurance->insured_addr2,
            city            => $insurance->insured_city,
            state           => $insurance->insured_state,
            zip             => $insurance->insured_postcode,
        };
    }
    $subscriber->{ insurance_id } = $insurance->insurance_id;

    return $subscriber;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_other_insurances

Object method.

Internal method to get all other client insurances of the same type, for the same client,
that are authorized for the time period covered by these prognotes

NOTE: we're assuming here that when the prognotes were split up into claims
they've already been grouped so that each prognote in the claim has the same
client_insurances authorized for them.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_other_insurances {
    my $self = shift;
   
    die 'Object requires client_insurance_id' unless $self->client_insurance_id;

    # Find out if there are any other payers: primary, secondary, or tertiary
    my $current_insurance = eleMentalClinic::Client::Insurance->retrieve( $self->client_insurance_id );

    my $latest_prognote_date = $self->get_latest_prognote_date;
    return $current_insurance->other_authorized_insurers( $latest_prognote_date );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_deduction_groups( $transaction_id )

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_deduction_groups {
    my $class = shift;
    my( $transaction_id ) = @_;

    die 'transaction_id is required' unless $transaction_id;

    my $deductions = eleMentalClinic::Financial::TransactionDeduction->get_deductions( $transaction_id );

    # sort by group_code
    my $grouped_deductions;
    for( @$deductions ){
        push @{ $grouped_deductions->{ $_->{ group_code }} } => $_;
    }

    # create an array with an element for each group_code
    my @deduction_groups = map { 
        { 
            group_code => $_,
            deductions => $grouped_deductions->{ $_ },
        }
    } sort keys %$grouped_deductions;

    return \@deduction_groups;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_other_insurance_data

Object method.

Internal method to get a hashref of data relating to the client's
other insurances.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_other_insurance_data {
    my $self = shift;

    my $client_insurances = $self->get_other_insurances;
    return unless $client_insurances;

    my @other_insurance_data;
    for my $insurance ( @$client_insurances ){

        my $paid_amount = 0;
        my $rolodex = eleMentalClinic::Rolodex->new->get_by_role_id( 'mental_health_insurance', $insurance->rolodex_insurance_id );
        
        # Find out if any of the previous ones have paid or reported on the claim yet

        # TODO claim-level deductions from the 835 would be handled here

        my $subscriber = $self->get_other_insurance_subscriber( $insurance );
           
        #    my @remarks;
        #        my $remark = {
        #            remark_code    =>
        #        };

        #    my $moa = {
        #        reimbursement_rate      =>
        #        HCPCS_payable_amount    =>
        #        remarks                 => \@remarks,
        #        nonpayable_professional_component =>
        #    };

        # Get the current billing_services, to look up past billing_services for the same prognotes
        my $billing_services = $self->billing_services;

        my @service_lines;
        for my $billing_service ( @$billing_services ) {

            # Get the previous billing_services (if any) for this insurance...
            my $past_billing_services = $billing_service->get_other_billing_services( $insurance->rolodex_id );
            next unless $past_billing_services and $past_billing_services->[0];
           
            for my $past_service ( @$past_billing_services ) {
                
                # ... and see if it got a transaction
                my $transaction = $past_service->valid_transaction;
                next unless $transaction;
                
                my $deduction_groups = $self->get_deduction_groups( $transaction->rec_id );
                my $billing_payment = eleMentalClinic::Financial::BillingPayment->retrieve( $transaction->billing_payment_id );
                my( $paid_charge_code, $modifiers ) = eleMentalClinic::ECS::Write837->split_charge_code( $transaction->paid_charge_code );
                my $adjudication_date = eleMentalClinic::ECS::Write837->get_date_f( $billing_payment->interchange_date ); 

                my $service_line = {
                    billing_service_id  => $billing_service->rec_id,
                    paid_amount         => $transaction->paid_amount,
                    paid_service        => $paid_charge_code,
                    modifiers           => $modifiers,
                    paid_units          => $transaction->paid_units,
                    # bundled_line_number => 
                    deduction_groups   => $deduction_groups,
                    adjudication_date   => $adjudication_date,
                };

                # 0.00 must be sent as 0
                $service_line->{ paid_amount } = '0' if $service_line->{ paid_amount } == '0.00';
                $paid_amount += $service_line->{ paid_amount };

                push @service_lines => $service_line;
            }
        }

        my $insurance_rank = eleMentalClinic::ECS::Write837->get_insurance_rank_f( $insurance->rank );

        my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
        my $relationship = $valid_data->get( '_insurance_relationship', $insurance->insured_relationship_id );
        my $insurance_type = $valid_data->get( '_insurance_type', $insurance->insurance_type_id );

        my $insurance_data = {
            name                            => $rolodex->edi_name,
            id                              => $rolodex->edi_id,
            plan_rank                       => $insurance_rank,
            patient_relation_to_subscriber  => $relationship->{ code },
            patient_insurance_id            => $insurance->patient_insurance_id,
            group_number                    => $insurance->insured_group_id,
            group_name                      => $insurance->insured_group,
            insurance_type                  => $insurance_type->{ code },
            claim_filing_indicator_code     => $rolodex->edi_indicator_code,
            subscriber                      => $subscriber,
            paid_amount                     => $paid_amount,

         #   deduction_groups               => \@deduction_groups,
         #   patient_responsibility_amount   =>
         #   patient_paid_amount             =>
            # moa                             => $moa,
         #   adjudication_date               =>
         #   prior_auth_number               =>
         #   referral_number                 =>
            service_lines                   => \@service_lines,
        };

        push @other_insurance_data => $insurance_data;
    }

    return \@other_insurance_data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_subscriber_data( $billing_claims )

Class method.

Takes an arrayref of billing_claims that all belong to the same client.

Returns a hashref of all the ECS data for this client, including
all of the claim data, and subscriber data if different from the client.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_subscriber_data {
    my $class = shift;
    my( $billing_claims ) = @_;

    die 'billing_claims is required' unless $billing_claims;

    # all billing_claims are for the same client, so just use the first one to get client data
    my $client_data = $billing_claims->[0]->get_client_insurance_data;

    my @claim_data;
    for( @$billing_claims ) {
        my $data = $_->data_837;
        push @claim_data => $data if $data;
    }

    die 'No valid claims found for this subscriber' unless @claim_data;
    $client_data->{ claims } = \@claim_data;

    # XXX all billing_claims here are expected to have the same client_insurance_id
    my $insurance = eleMentalClinic::Client::Insurance->retrieve( $billing_claims->[0]->client_insurance_id );

    die 'Unable to retrieve the client_insurance record, rec_id ' . $billing_claims->[0]->client_insurance_id unless $insurance;
    die 'The client_insurance record ' . $insurance->rec_id . ' requires an insured_relationship_id' unless $insurance->insured_relationship_id;

    my $subscriber_data;
    if( $insurance->insured_relationship_id == 1 ){

        # If the client's insurance subscriber is his/herself
        $subscriber_data = $client_data;
    }
    else {

        # The client is a dependent
        # XXX Right now we are not able to check whether the client's subscriber is another client in the system

        my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
        my $relationship = $valid_data->get( '_insurance_relationship', $insurance->insured_relationship_id );

        $client_data->{ relation_to_subscriber } = $relationship->{ code };
        $client_data->{ insurance_id } = $insurance->patient_insurance_id;
        
        $subscriber_data = $class->get_subscriber_insurance_data( $insurance );
        $subscriber_data->{ dependents } = [ $client_data ];
    }

    # XXX There could be multiple claims here for one client & client_insurance combination
    # but they all'd better have the same insurance_rank!
    # ALSO, we can get the rank here either from the $insurance record, or from billing_claim, which already exists...

    my $insurance_rank = eleMentalClinic::ECS::Write837->get_insurance_rank_f( $insurance->rank );

    $subscriber_data->{ plan_rank    } = $insurance_rank;
    $subscriber_data->{ insurance_id } = $insurance->insurance_id;
    $subscriber_data->{ group_number } = $insurance->insured_group_id;
    $subscriber_data->{ group_name   } = $insurance->insured_group;

    my $rolodex = eleMentalClinic::Rolodex->new->get_by_role_id( 'mental_health_insurance', $insurance->rolodex_insurance_id );
    $subscriber_data->{ claim_filing_indicator_code } = $rolodex->{ edi_indicator_code } if $rolodex;

    return $subscriber_data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_subscriber_insurance_data( $insurance )

Class method.

Used only when the client is a dependent of the subscriber

XXX Perhaps this should be a method of Client::Insurance but I want to 
contain the EDI data structure info to the Billing* files.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_subscriber_insurance_data {
    my $class = shift;
    my( $insurance ) = @_;

    die 'insurance is required' unless $insurance;

    my $insured_dob = eleMentalClinic::ECS::Write837->get_date_f( $insurance->insured_dob );
    my $insured_gender = eleMentalClinic::ECS::Write837->get_gender_f( $insurance->insured_sex );

    # XXX Not supported:
    # When the destination payer (Loop 2010BB) is Medicare and Medicare is not the primary payer (SBR01 equals S or T)
    # This is "Medicare Secondary Payer" and it requires subscriber.insurance_type to specify exactly which kind of
    # Medicare Secondary Payer it is.

    my $data = {
        fname        => $insurance->insured_fname, 
        lname        => $insurance->insured_lname,
        mname        => $insurance->insured_mname,
        name_suffix  => $insurance->insured_name_suffix,
        address1     => $insurance->insured_addr,
        address2     => $insurance->insured_addr2,
        city         => $insurance->insured_city,
        state        => $insurance->insured_state,
        zip          => $insurance->insured_postcode,
        dob          => $insured_dob,
        gender       => $insured_gender,
    };

    return $data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_client_insurance_data

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_client_insurance_data {
    my $self = shift;

    return unless $self->client_id;

    my $client  = eleMentalClinic::Client->retrieve( $self->client_id );
    my $dob     = eleMentalClinic::ECS::Write837->get_date_f( $client->dob );
    my $gender  = eleMentalClinic::ECS::Write837->get_gender_f( $client->sex );

    my $data = {
        fname        => $client->fname, 
        lname        => $client->lname,
        mname        => $client->mname,
        name_suffix  => $client->name_suffix, 
        address1     => $client->address->address1,
        address2     => $client->address->address2,
        city         => $client->address->city,
        state        => $client->address->state,
        zip          => $client->address->post_code,
        dob          => $dob,
        gender       => $gender,
    };

    return $data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 data_837

Object method.

Pulls all the EDI data for this claim into a hashref.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub data_837 {
    my $self = shift;

    my( $service_lines, $claim_data ) = $self->prognotes_to_service_lines;
    # invalid claims should be skipped rather than breaking the whole 837
    return unless $service_lines and @$service_lines > 0; 

    my $rendering_provider = $self->rendering_provider;
    my $diagnosis_codes = $self->diagnosis_codes;
    die "Missing diagnosis code for client " . $self->client_id unless $diagnosis_codes;

    $claim_data->{ total_amount } = sprintf "%.2f", $claim_data->{ total_amount };

    my $other_insurances = $self->get_other_insurance_data;

    my $claim = {
        submitter_id        => $self->rec_id, 
        total_amount        => "$claim_data->{ total_amount }",
        facility_code       => $claim_data->{ claim_facility_code },
        provider_sig_onfile => 'Y', # Y or N
        patient_paid_amount => undef,
        diagnosis_codes     => $diagnosis_codes,
        rendering_provider  => $rendering_provider,
        referring_provider  => undef, # not used
        service_lines       => $service_lines,
        other_insurances    => $other_insurances,
    };

    return $claim;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 data_hcfa

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub data_hcfa {
    my $self = shift;

    return unless $self->rec_id;

    my $subscriber = $self->get_hcfa_subscriber_data;
    my $client     = $self->get_hcfa_client_data;
    my $rendering_provider = $self->hcfa_rendering_provider;

    return unless $subscriber
        and $client;

    my $data = {
        billing_claim_id    => $self->rec_id,
        subscriber          => $subscriber,
        client              => $client,
        rendering_provider  => $rendering_provider,
    };
    
    return $data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_hcfa_client_data

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_hcfa_client_data {
    my $self = shift;

    return unless $self->client_id;

    my $client = eleMentalClinic::Client->retrieve( $self->client_id );
    
    my $dob = eleMentalClinic::Financial::HCFA->get_date_f( $client->dob );
    my $gender = eleMentalClinic::Financial::HCFA->get_gender_f( $client->sex );
    my $name = eleMentalClinic::Financial::HCFA->get_name_f( $client );
    my $address1 = eleMentalClinic::Financial::HCFA->get_addr_f( $client->address ? $client->address->address1 : '' );
    my $phone = eleMentalClinic::Financial::HCFA->get_phone_f( $client->phone ? $client->phone->phone_number : '');
    my $is_married = eleMentalClinic::Financial::HCFA->is_married( $client->marital_status );

    my $diagnosis_codes = $self->diagnosis_codes( 'hcfa' );
    my $prior_auth_number = $self->get_hcfa_auth_code;
    my $other_insurance = $self->get_hcfa_other_insurance_data;
    my $service_lines   = $self->get_hcfa_service_lines;
    my $service_facility = $self->get_hcfa_service_facility;

    my $client_data = {
        client_id   => $client->client_id,
        name        => $name,
        dob         => $dob,
        gender      => $gender,
        address1    => $address1,
        city        => $client->address->city,
        state       => $client->address->state,
        zip         => $client->address->post_code,
        phone       => $phone,
        is_married  => $is_married,
        diagnosis_codes => $diagnosis_codes,
        prior_auth_number => $prior_auth_number,
        other_insurance => $other_insurance, 
        service_lines   => $service_lines,
        service_facility => $service_facility,
    };

    return $client_data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_hcfa_auth_code

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_hcfa_auth_code {
    my $self = shift;
    
    return unless $self->client_insurance_authorization_id;
    my $auth = eleMentalClinic::Client::Insurance::Authorization->retrieve( $self->client_insurance_authorization_id );
    return unless $auth;

    return $auth->code;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_hcfa_service_facility()

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_hcfa_service_facility {
    my $self = shift;

    return unless $self->client_id;

    my $client = eleMentalClinic::Client->retrieve( $self->client_id );
    return unless $client;

    my $program = $client->placement( $self->get_latest_prognote_date )->program;
    return unless $program;

    return if $program->{ is_referral };

    my $citystatezip;
    $citystatezip .= $program->{ city } . ',' if $program->{ city };
    $citystatezip .= ' ' . $program->{ state } if $program->{ state };
    $citystatezip .= ' ' . $program->{ zip } if $program->{ zip }; 

    return {
        name            => $program->{ name },
        addr            => $program->{ addr },
        citystatezip    => $citystatezip,
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_hcfa_other_insurance_data

Object method.

Gets the highest ranked insurance of all of the client's other insurances
and puts the data necessary for a HCFA into a hashref.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_hcfa_other_insurance_data {
    my $self = shift;

    my $client_insurances = $self->get_other_insurances;
    return unless $client_insurances;

    my $insurance = $client_insurances->[0];
    
    my( $name, $dob, $gender );
    if( $insurance->insured_relationship_id == 1 ) {
    
        # XXX Refactor: this is duplicated in get_other_insurance_subscriber
        my $client = eleMentalClinic::Client->retrieve( $insurance->client_id );
        
        $name = eleMentalClinic::Financial::HCFA->get_name_f( $client );
        $dob = eleMentalClinic::Financial::HCFA->get_date_f( $client->dob );
        $gender = eleMentalClinic::Financial::HCFA->get_gender_f( $client->sex );
    }
    else {
        $name  = eleMentalClinic::Financial::HCFA->get_name_f({
            lname           => $insurance->insured_lname,
            fname           => $insurance->insured_fname,
            mname           => $insurance->insured_mname,
            name_suffix     => $insurance->insured_name_suffix,
        });
        $dob = eleMentalClinic::Financial::HCFA->get_date_f( $insurance->insured_dob );
        $gender = eleMentalClinic::Financial::HCFA->get_gender_f( $insurance->insured_sex );

    }

    my $rolodex = eleMentalClinic::Rolodex->new->get_by_role_id( 'mental_health_insurance', $insurance->rolodex_insurance_id );

    my $other_insurance_data = {
        subscriber_name     => $name,
        subscriber_dob      => $dob,
        subscriber_gender   => $gender,
        insurance_name      => $rolodex->name,
        group_number        => $insurance->insured_group_id,
        group_name          => $insurance->insured_group,
        employer_or_school_name => $insurance->insured_employer,
    };

    return $other_insurance_data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_hcfa_service_lines()

Object method.

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_hcfa_service_lines {
    my $self = shift;

    my $billing_services = $self->billing_services;
    die 'No billing service lines found for this billing claim' unless $billing_services;
    my @service_lines;
    for my $billing_service ( @$billing_services ){
        my $hcfa_service_line;
        eval { $hcfa_service_line = $billing_service->service_line( 'is_hcfa' ); };
        if( $@ ){
            Log_defer( "Error getting service line in HCFA, billing service line " . $billing_service->rec_id . ": $@" );
            next;
        }
        push @service_lines => $hcfa_service_line;
    }

    return \@service_lines;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

=head2 get_hcfa_subscriber_data

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_hcfa_subscriber_data {
    my $self = shift;

    return unless $self->client_insurance_id;

    my $insurance = eleMentalClinic::Client::Insurance->retrieve( $self->client_insurance_id );
    return unless $insurance and $insurance->insured_relationship_id;

    my $dob = eleMentalClinic::Financial::HCFA->get_date_f( $insurance->insured_dob );
    my $gender = eleMentalClinic::Financial::HCFA->get_gender_f( $insurance->insured_sex );

    my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
    my $relationship = $valid_data->get( '_insurance_relationship', $insurance->insured_relationship_id );

    my $rolodex = eleMentalClinic::Rolodex->new->get_by_role_id( 'mental_health_insurance', $insurance->rolodex_insurance_id );

    my $subscriber_data = {
        insurance_id            => $insurance->insurance_id,
        dob                     => $dob,
        gender                  => $gender,
        employer_or_school_name => $insurance->insured_employer,
        insurance_name          => $rolodex->name,
        group_name              => $insurance->insured_group,
        client_relation_to_subscriber => $relationship->{ code },
        co_pay_amount           => $insurance->co_pay_amount,
    };

   unless ( $insurance->insured_relationship_id == 1 ) {
        
        my $name  = eleMentalClinic::Financial::HCFA->get_name_f({
            lname           => $insurance->insured_lname,
            fname           => $insurance->insured_fname,
            mname           => $insurance->insured_mname,
            name_suffix     => $insurance->insured_name_suffix,
        });
        my $address1 = eleMentalClinic::Financial::HCFA->get_addr_f( $insurance->insured_addr );
        my $address2 = eleMentalClinic::Financial::HCFA->get_addr_f( $insurance->insured_addr2 );
        my $phone = eleMentalClinic::Financial::HCFA->get_phone_f( $insurance->insured_phone );
        $subscriber_data = { %$subscriber_data, (
            name            => $name,
            address1        => $address1,
            address2        => $address2,
            city            => $insurance->insured_city,
            state           => $insurance->insured_state,
            zip             => $insurance->insured_postcode,
            group_number    => $insurance->insured_group_id,
            phone           => $phone,
        )};
    }

    return $subscriber_data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 save_as_billed( $manually )

Object method.

Save the billed information for each note in this claim.
This method must be wrapped in a transaction, or else failure may leave the database in a bad state.

 * manually - (OPTIONAL) if true, prognote billing_status will be set to 'BilledManually'
 
=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# XXX : when we upgrade to PG8, add nested transaction
sub save_as_billed {
    my $self = shift;
    my $manually = shift || 0;

    return unless $self->billing_services;

    my $line_number = 1;
    for my $billing_service ( @{ $self->billing_services } ){

        my $result = $billing_service->save_as_billed( $line_number, $manually );
        $line_number++ if $result;
    }

    return 1;
}

'eleMental';

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
