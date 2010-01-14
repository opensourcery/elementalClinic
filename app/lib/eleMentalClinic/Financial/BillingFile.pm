package eleMentalClinic::Financial::BillingFile;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::BillingFile

=head1 SYNOPSIS

The billing file, which contains multiple billing claims. 
Corresponds to one EDI file, but possibly multiple HCFAs (one HCFA for each claim).

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use Date::Calc qw/ Today_and_Now /;
use eleMentalClinic::ECS::Write837;
use eleMentalClinic::Financial::BillingClaim;
use eleMentalClinic::Financial::ClaimsProcessor;
use eleMentalClinic::Log;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'billing_file' }
    sub fields { [ qw/
        rec_id billing_cycle_id group_control_number
        set_control_number purpose type is_production submission_date 
        rolodex_id edi 
    /] }
    sub fields_required { [ qw/ billing_cycle_id rolodex_id /] }
    sub primary_key { 'rec_id' }
    sub methods {
        [ qw/ claims_processor payer / ]
    }
    sub accessors_retrieve_many {
        {
            billing_claims => { billing_file_id => 'eleMentalClinic::Financial::BillingClaim' },
        }
    }
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 defaults

Sets core object properties, unless they have already been set.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub defaults {
    {
        group_control_number    => 1,
        set_control_number      => 1,     
        purpose                 => '00',     # 00 = original (Noridian requires), 18 = transmission failed previously
        type                    => 'CH',     # CH = claims, RP = encounters
        is_production           => 0,
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 init( $args[, $options] )

Object method.

Initializes the object, sets properties based on passed parameters and sets
defaults for unset properties.

Retrieves the object's payer (Rolodex object) and ClaimsProcessor.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub init {
    my $self = shift;
    my( $args, $options ) = @_;

    $self->SUPER::init( $args, $options );

    my %defaults = %{ &defaults };
    while( my( $key, $value ) = each %defaults ) {
        defined $args->{ $key }
            ? $self->$key( $args->{ $key })
            : $self->$key( $value );
    }

    if( $self->rolodex_id ){
        my $payer = eleMentalClinic::Rolodex->retrieve( $self->rolodex_id );
        $self->payer( $payer );

        if( $payer->{ claims_processor_id } ){
            my $claims_processor = eleMentalClinic::Financial::ClaimsProcessor->retrieve( $payer->{ claims_processor_id } );
            $self->claims_processor( $claims_processor );
            $self->is_production( $claims_processor->send_production_files );
        }
    }

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 rec_id_f

Object method.

Returns the billing_file.rec_id as nine zero-padded digits 
- used as the interchange control number

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub rec_id_f {
    my $self = shift;

    return unless $self->rec_id;
    return sprintf( "%0*d", 9, $self->rec_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 set_control_number_f

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub set_control_number_f {
    my $self = shift;

    return unless $self->set_control_number;
    return sprintf( "%0*d", 4, $self->set_control_number );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 mode

Object method.

Returns 'P' if this BillingFile is getting generated in production,
'T' otherwise.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub mode {
    my $self = shift;

    $self->is_production ? return 'P' : return 'T';
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_submitter

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_submitter {
    my $self = shift;

    die 'Object requires claims_processor' unless $self->claims_processor;

    # EDI contact is the financial person chosen at the Admin level
    my $contact = eleMentalClinic::Personnel->retrieve( $self->config->edi_contact_staff_id );
    my $phone = $contact->work_phone;
    $phone =~ s/[-)( ]*//g if $phone;    

    my $submitter = {
        id                 => $self->claims_processor->clinic_submitter_id,
        name               => $self->config->org_name,
        contact_name       => $contact->fname . ' ' . $contact->lname,
        contact_method     => 'TE',                     # or EM for email
        contact_number     => $phone,                   # could also be email
        contact_extension  => $contact->work_phone_ext, # not required
    };
 
    return $submitter;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_payer_data

Object method.

$self->payer must be a Rolodex object

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_payer_data {
    my $self = shift;

    die 'Object requires payer, a Rolodex object' unless $self->payer
        and $self->payer->isa( "eleMentalClinic::Rolodex" );

    my $zip = $self->payer->address->post_code;
    $zip =~ s/-//g;

    my $payer = {
        name     => $self->payer->edi_name,
        id       => $self->payer->edi_id,
        address  => $self->payer->address->address1,
        address2 => $self->payer->address->address2,
        city     => $self->payer->address->city,
        state    => $self->payer->address->state,
        zip      => $zip,
        claims_processor_id => $self->payer->claims_processor_id,
        edi_indicator_code => $self->payer->edi_indicator_code,
    };

    return $payer;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_sender

Object method.

$self->claims_processor must be a ClaimsProcessor object

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_sender {
    my $self = shift;

    die 'Object requires an eleMentalClinic::Financial::ClaimsProcessor object' unless $self->claims_processor
        and $self->claims_processor->isa( "eleMentalClinic::Financial::ClaimsProcessor" );

    # tp###### and spaces right-right-padding to 15-bytes
    my $clinic_interchange_id = sprintf( "%-*s", 15, $self->claims_processor->clinic_trading_partner_id );
    
    # sender is different depending on the receiver - the receiver's ClaimsProcessor defines the sender fields too
    my $sender = {
        interchange_id_qualifier => $self->claims_processor->interchange_id_qualifier,
        padded_interchange_id    => $clinic_interchange_id,
        code                     => $self->claims_processor->clinic_trading_partner_id,
    };

    return $sender;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_receiver

Object method.

$self->claims_processor must be a ClaimsProcessor object

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_receiver {
    my $self = shift;

    die 'Object requires an eleMentalClinic::Financial::ClaimsProcessor object' unless $self->claims_processor
        and $self->claims_processor->isa( "eleMentalClinic::Financial::ClaimsProcessor" );

    my $receiver_interchange_id = sprintf( "%-*s", 15, $self->claims_processor->interchange_id );

    my $receiver = {  
        interchange_id_qualifier => $self->claims_processor->interchange_id_qualifier,
        padded_interchange_id    => $receiver_interchange_id,
        code                     => $self->claims_processor->code,
        name                     => $self->claims_processor->name,
        primary_id               => $self->claims_processor->primary_id,
    };

    return $receiver;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_billing_provider( [$hcfa] )

Object method.

$self->claims_processor must be a ClaimsProcessor object

If the $hcfa flag is true, the dashes are not stripped from the employer id,
and a citystatezip field is added to the data.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# FIXME enough differences have crept into here for HCFAs that there should
# probably be a separate method.
sub get_billing_provider {
    my $self = shift;
    my( $hcfa ) = @_;

    die 'Object requires a claims_processor unless a HCFA is getting generated' unless $hcfa or $self->claims_processor;

    die "Object's claims_processor must be an eleMentalClinic::Financial::ClaimsProcessor object, unless a HCFA is getting generated" unless $hcfa or
        $self->claims_processor->isa( "eleMentalClinic::Financial::ClaimsProcessor" );

    my $employer_id = $self->config->org_tax_id;
    $employer_id =~ s/-//g 
        unless $hcfa;

    my $billing_provider = {     
        name                    => $self->config->org_name,
        national_provider_id    => $self->config->org_national_provider_id,
        employer_id             => $employer_id,
        address1                => $self->config->org_street1,
        address2                => $self->config->org_street2,
        city                    => $self->config->org_city,
        state                   => $self->config->org_state,
        zip                     => $self->config->org_zip,
    };

    if( $hcfa ){
        $billing_provider->{ address1 } =  eleMentalClinic::Financial::HCFA->get_addr_f( $self->config->org_street1 );
        $billing_provider->{ address2 } =  eleMentalClinic::Financial::HCFA->get_addr_f( $self->config->org_street2 );
        $billing_provider->{ citystatezip } = $self->config->org_city . ' ' . $self->config->org_state . ' ' . $self->config->org_zip;
    }

    # If we're sending the taxonomy code for each rendering provider,
    # it shouldn't be sent for the whole clinic
    unless( ($self->claims_processor and $self->claims_processor->requires_rendering_provider_ids) or $hcfa ){
        $billing_provider->{ taxonomy_code } = $self->config->org_taxonomy_code;
    }

    # XXX Refactor: ideally, check if Client::Insurance.edi_indicator_code == 'MC' (medicaid) or 'MB' (medicare part b)
    # so these aren't sent unnecessarily
    $billing_provider->{ medicaid_provider_number } = $self->config->org_medicaid_provider_number || undef; 
    $billing_provider->{ medicare_provider_number } = $self->config->org_medicare_provider_number || undef;

    return $billing_provider;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_subscribers

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_subscribers {
    my $self = shift;

    my $billing_claims = $self->billing_claims;
    die 'Unable to get the billing claims for this file' unless $billing_claims;

    # Reorganize the claims: group by client_id and client_insurance_id,
    # so that when we push a subscriber onto our list, it contains all of its claims
    my %client_claims;
    for my $bill_claim ( @$billing_claims ){

        # client_claims{ client_id }{ client_insurance_id } = @billing_claims
        push @{ $client_claims{ $bill_claim->{ client_id } }{ $bill_claim->{ client_insurance_id } } } => $bill_claim;
    }

    my @subscribers;
    for my $client_id ( sort keys %client_claims ){

        for( keys %{ $client_claims{ $client_id } } ){
            
            my $subscriber_data;
            eval { $subscriber_data = eleMentalClinic::Financial::BillingClaim->get_subscriber_data( $client_claims{ $client_id }{ $_ } ); };
            if( $@ ){
                Log_defer( "Error getting subscriber data, client " . $client_id . ", client_insurance " . $_ . ": $@" );
                next;
            }
            push @subscribers => $subscriber_data;
        }
    }

    return \@subscribers;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_837_data

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_837_data {
    my $self = shift;

    my $submitter = $self->get_submitter;
    my $payer = $self->get_payer_data;
    my $sender = $self->get_sender;
    my $receiver = $self->get_receiver;
    my $billing_provider = $self->get_billing_provider;
    my $subscribers = $self->get_subscribers;

    return unless $submitter
        and $payer
        and $sender
        and $receiver
        and $billing_provider
        and $subscribers;

    my $data = {
        sender           => $sender,
        receiver         => $receiver,
        billing_file     => $self,
        submitter        => $submitter,
        billing_provider => $billing_provider,
        payer            => $payer,
        subscribers      => $subscribers,
    };

    return $data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_hcfa_data

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_hcfa_data {
    my $self = shift;

    my $payer = $self->get_hcfa_payer;
    return unless $payer;

    my $billing_provider = $self->get_billing_provider( 'hcfa' );
    return unless $billing_provider;

    my $contact = eleMentalClinic::Personnel->retrieve( $self->config->edi_contact_staff_id );
    my $phone = eleMentalClinic::Financial::HCFA->get_phone_f( $contact->work_phone );
    $billing_provider->{ contact_number } = $phone;

    my $claims = $self->get_hcfa_claims;
    return unless $claims;

    return {
        payer           => $payer,
        billing_provider => $billing_provider,
        claims          => $claims,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_hcfa_claims

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_hcfa_claims {
    my $self = shift;


    my $billing_claims = $self->billing_claims;
    die 'Unable to get the billing claims for this file' unless $billing_claims;

    my @claims = map { $_->data_hcfa } @$billing_claims;

    return \@claims;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_hcfa_payer

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_hcfa_payer {
    my $self = shift;

    return unless $self->payer;

    my $citystatezip = $self->payer->address->city . ', ' . $self->payer->address->state . ' ' . $self->payer->address->post_code;
    my $payer = {
        name     => $self->payer->name,
        address  => $self->payer->address->address1,
        address2 => $self->payer->address->address2,
        citystatezip => $citystatezip,
    };

    return $payer;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 save_as_billed( [$timestamp, $edi_data] )

Object method.

Save this BillingFile as billed: save each BillingClaim that is in 
this BillingFile as billed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub save_as_billed {
    my $self = shift;
    my( $timestamp, $edi_data ) = @_;

    $timestamp ||= $self->timestamp;

    $self->edi( $edi_data ) if $edi_data;
    $self->submission_date( $timestamp );
    
    $self->db->transaction_begin;
    eval {
        my $billing_claims = $self->billing_claims;
        die 'Unable to get billing_claims for this file' unless $billing_claims;
        
        for my $bill_claim ( @$billing_claims ){
            die 'Unable to save billing_claim as billed: ' . $bill_claim->rec_id unless $bill_claim->save_as_billed;
        }

        die 'Unable to save billing_file record' unless $self->save;
    };
    
    if( $@ ){
        Log_defer( "Error saving file as billed, billing file " . $self->rec_id . ": $@" );
        die $@;
        return $self->db->transaction_rollback;
    }
    
    return $self->db->transaction_commit;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 requires_rendering_provider_ids

Object method.

Wraps $self->claims_processor->requires_rendering_provider_ids.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub requires_rendering_provider_ids {
    my $self = shift;

    return unless $self->claims_processor;
    return $self->claims_processor->requires_rendering_provider_ids;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 list_by_billing_cycle( $billing_cycle_id[, $rolodex_id] )

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub list_by_billing_cycle {
    my $class = shift;
    my( $billing_cycle_id, $rolodex_id ) = @_;

    return unless $billing_cycle_id;

    my $fields = $class->fields_qualified;
    my $table = $class->table;
    my $where = 'billing_file.billing_cycle_id = ?';
    $where   .= ' AND billing_file.rolodex_id = ?' if $rolodex_id;
    my $query = qq/
        SELECT $fields
        FROM $table
        WHERE $where
        ORDER BY rec_id
    /;

    my @bind_vars;
    push @bind_vars => $billing_cycle_id;
    push @bind_vars => $rolodex_id if $rolodex_id;
    return $class->db->fetch_hashref( $query, @bind_vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_by_billing_cycle( $billing_cycle_id[, $rolodex_id] )

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_by_billing_cycle {
    my $class = shift;
    my( $billing_cycle_id, $rolodex_id ) = @_;
    return unless $billing_cycle_id;

    my $billing_files = $class->list_by_billing_cycle( $billing_cycle_id, $rolodex_id );
    return unless $billing_files;

    return[ map{ $class->new( $_ )} @$billing_files ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 date_edi_billed

Object method. Returns submission_date if edi was ever generated for
this billing_file.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub date_edi_billed {
    my $self = shift;
    die 'Must call on stored object' unless $self->id;

    return $self->submission_date
        if $self->edi;
    
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 label()

Object method.

Returns "$self->rolodex->name | $self->submission_date"

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub label {
    my $self = shift;

    return unless $self->rolodex and $self->submission_date;
    return $self->rolodex->name .' | '. $self->submission_date;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 new_claim(parameters)

Object method constructs a new BillingClaim from the passed parameters
associated with this BillingFile.

 * parameters - required hash ref, with following:
   * staff_id            => personnel.id of staff who saw client,
   * client_id           => client id,
   * client_insurance_id => client_insurance id,
   * insurance_rank      => bill 1st, bill 2nd, etc.,
   * client_insurance_authorization_id => client_insurance authorization id

dies if unable to save record.

Returns new eleMentalClinic::Financial::BillingClaim

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub new_claim {
    my $self = shift;
    my $parameters = shift;
    return unless $parameters and $self->id;

    $parameters->{billing_file_id} = $self->id;

    my $claim = eleMentalClinic::Financial::BillingClaim->new($parameters);
    die 'Unable to save new billing_claim' unless $claim->save;

    return $claim;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 add_claims(prognotes)

Object method constructs a set of BillingClaims for this file for the 
passed set of ProgressNotes.

 * prognotes : array ref of eleMentalClinic::ProgressNotes (required)

Returns true if successful.

Dies if unable to construct BillingClaim or BillingServices.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub add_claims {
    my $self = shift;
    my $prognotes = shift;
    # expect a non-zero array of progress notes
    return unless $prognotes and scalar(@$prognotes) > 0;

    # break out prognotes by client_id
    my $by_client = {};
    map { push @{ $by_client->{ $_->client_id } } => $_ } @$prognotes; 

    my $ignore_staff = ! $self->requires_rendering_provider_ids;

    # Create a new claim for each client-staff combination
    for my $client_id ( sort keys %$by_client ){

        my $combined_notes = eleMentalClinic::ProgressNote->combine_identical( $by_client->{ $client_id }, $ignore_staff );
            
        for my $staff_id ( sort keys %{ $combined_notes } ){

            my %by_insurance;
            my %ranks;
                
            my $notes_for_staff = $combined_notes->{ $staff_id };
            for my $combined_note_key ( sort keys %$notes_for_staff ) {

                # Find out which insurance record to use
                # NOTE when choosing the payer_id ($self->rolodex_id), we already checked the past transactions to see which to bill next
               
                # XXX Just use the first prognote, the date and client should all be the same
                my $sample_prognote = $notes_for_staff->{ $combined_note_key }[0];
                my $client_insurance = $sample_prognote->get_client_insurance( $self->rolodex_id );        
                my $auth = $client_insurance->authorization( $sample_prognote->start_date );

                # push { client_insurance_id }{ auth_id } => combined_note
                push @{ $by_insurance{ $client_insurance->rec_id }{ $auth->rec_id } } => $notes_for_staff->{ $combined_note_key };
                # ranks{ client_insurance_id } = rank
                $ranks{ $client_insurance->rec_id } = $client_insurance->rank;
            }

            for my $client_insurance_id ( sort keys %by_insurance ){
                for my $auth_id ( sort keys %{ $by_insurance{ $client_insurance_id } } ){

                    my $rank = $ranks{ $client_insurance_id };
                    my $billing_claim = $self->new_claim({
                        staff_id        => $staff_id,
                        client_id       => $client_id,
                        client_insurance_id => $client_insurance_id,
                        insurance_rank  => $rank,
                        client_insurance_authorization_id => $auth_id,
                    });

                    my $notes_for_claim = $by_insurance{ $client_insurance_id }{ $auth_id };
                    for my $combined_note ( @$notes_for_claim ) {

                        # Create a new BillingService object for all the ones that match
                        # (it will usually be just one per prognote)
                        my $billing_service = $billing_claim->new_service;

                        for my $prognote ( @$combined_note ) {
                            $billing_service->new_billing_prognote($prognote->rec_id);
                        }
                    }
                }
            }
        }
    }

    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_all_billed()

Class method. Returns only billing_files that have a submission_date.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_all_billed {
    my $class = shift;

    my $billing_files = $class->db->select_many(
        $class->fields,
        $class->table,
        "WHERE submission_date > DATE('0001-01-01')",
        "ORDER BY " . $class->primary_key
    );

    return unless $billing_files;
    return[ map{ $class->new( $_ )} @$billing_files ];
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
