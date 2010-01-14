# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Controller::Base::Financial;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Financial

=head1 SYNOPSIS

Base Financial Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use Data::Dumper;
use eleMentalClinic::ProgressNote;
use eleMentalClinic::Rolodex;
use eleMentalClinic::Financial::BillingCycle;
use eleMentalClinic::Financial::BillingPayment;
use eleMentalClinic::Financial::ValidationSet;
use eleMentalClinic::Financial::ValidationRule;
use eleMentalClinic::Financial::ClaimsProcessor;
use eleMentalClinic::Financial::MedicaidAdjustment;
use eleMentalClinic::Client::Insurance::Authorization;
use eleMentalClinic::Client::Insurance::Authorization::Request;
use eleMentalClinic::Report;
use eleMentalClinic::ECS::SFTP;
use eleMentalClinic::ECS::DialUp;
use eleMentalClinic::ECS::Read997;
use eleMentalClinic::ECS::ReadTA1;
use eleMentalClinic::Util;

our $DEFAULT_SECTION = "home";


sub redirected {
    my ($self, $redir) = @_;
    $self->{redirected} = $redir if defined($redir);
    return $self->{redirected};
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->security( 'financial' );
    $self->session->param( client_insurance_authorization_subnav => 'current' )
        unless $self->session->param( 'client_insurance_authorization_subnav' );

    my $body_class = 'financial';
    $body_class .= '_'. $self->current_page
        if $self->current_page;
    $self->template->vars({
        body_class  => $body_class,
        script      => 'financial.cgi',
        styles      => [ 'layout/00', 'financial', 'date_picker' ],
        javascripts => [
            'financial.js',
            'calendar.js',
            'jquery.js',
            'date_picker.js'
        ],
    });

    $self->redirected(0);
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            section     => [ 'Section', 'text::word' ],
            step        => [ 'Step', 'number::integer' ],
        },
        select_validation_set => {
            validation_set_id  => [ 'Validation set', 'required', 'number::integer' ],
        },
        select_billing_cycle => {
            billing_cycle_id  => [ 'Billing cycle', 'required', 'number::integer' ],
        },
        billing_1_select => {
            start_date  => [ 'Start date', 'required', 'date::iso' ],
            end_date    => [ 'End date', 'required', 'date::iso' ],
            cycle_type  => [ 'Cycle type', 'required', 'text::word' ],
        },
        billing_2 => {},
        billing_2_unselected => {},
        prognote_toggle_billable => {
            prognote_id => [ 'Progress note', 'number::integer', 'required' ],
        },
        prognote_toggle_validity => {
            validation_prognote_id => [ 'Progress note', 'number::integer', 'required' ],
        },
        prognote_toggle_manual => {
            prognote_id => [ 'Progress note', 'number::integer', 'required' ],
        },
        billing_3_validate => {},
        billing_4 => {
            -alias          => 'Payer Validation',
        },
        billing_4_validate => {
            rolodex_id  => [ 'Insurer', 'required' ],
        },
        billing_5 => {
            -alias          => 'Billing',
        },
        billing_5_ecs => {
            -alias          => 'Electronic Billing',
        },
        billing_5_hcfa => {
            -alias          => 'Print HCFA',
        },
        billing_load_prognotes => {
            validation_set_id => [ 'Validation set', 'required', 'number::integer' ],
            rolodex_id => [ 'Insurer', 'number::integer' ],
        },
        billing_show_results => {
            validation_set_id => [ 'Validation set', 'required', 'number::integer' ],
            rolodex_id => [ 'Insurer', 'number::integer' ],
        },
        billing_load_results => {
            validation_set_id => [ 'Validation set', 'required', 'number::integer' ],
            rolodex_id => [ 'Insurer', 'number::integer' ],
        },
        billing_set_failures_unbillable => { 
            validation_set_id => [ 'Validation set', 'required', 'number::integer' ], 
            rolodex_id => [ 'Insurer', 'number::integer' ], 
        }, 
        payments_1_new => {
        },
        payments_1_save => {
            rolodex_id  => [ 'Insurer', 'required' ],
            payment_amount  => [ 'Amount', 'required', 'number::decimal' ],
            payment_date  => [ 'Payment date', 'required', 'date::iso' ],
        },
        payments_1_new => {},
        payments_2_transaction_toggle_error => {},
        payments_3_save => {
            paid_amount  => [ 'Paid As amount', 'required', 'number::decimal' ],
            paid_units  => [ 'Paid units', 'required', 'number::integer' ],
            billing_payment_id  => [ 'Master Payment', 'required', 'number::integer' ],
            claim_status_code  => [ 'Claim status', 'required', 'number::integer' ],
            payer_claim_control_number  => [ 'Payer Claim Control Number (aka Internal Control Number)', 'required' ],
            patient_responsibility_amount => [ 'Patient Responsibility Amount', 'number::decimal' ],
            deduction_1 => [ 'Deduction amount 1', 'number::decimal' ],
            deduction_2 => [ 'Deduction amount 2', 'number::decimal' ],
            deduction_3 => [ 'Deduction amount 3', 'number::decimal' ],
            deduction_4 => [ 'Deduction amount 4', 'number::decimal' ],
        },
        reports_1_run => {
            report_name => [ 'Report', 'required' ],
        },
        tools_1 => {},
        client_insurance_authorization_request => {},
        client_insurance_authorization_request_save => {
            client_id                           => [ 'Client', 'required' ],
            client_insurance_authorization_id   => [ 'Insurance authorization' ],
        },
        client_insurance_authorization_request_print => {
            client_insurance_authorization_request_id        => [ 'Request', 'required' ],
            section     => [ 'Section', 'text::word', 'required' ],
            step        => [ 'Step', 'number::integer', 'required' ],
        },
        tools_2 => {},
        tools_2_save => {
            -alias  => 'Save Claims Processor',
            username    => [ 'Username', 'text', 'required' ],
            password    => [ 'Password', 'text::liberal', 'required' ],
            interchange_id_qualifier => [ 'Interchange id qualifier', 'text', 'required', 'length(2,2)' ],
            interchange_id => [ 'Interchange ID', 'text', 'required', 'length(2,15)' ],
            clinic_trading_partner_id => [ 'Trading partner ID', 'text', 'required', 'length(2,15)' ],
            code => [ 'Code', 'text', 'required', 'length(2,15)' ],
            name => [ 'Name', 'text', 'required', 'length(2,35)' ],
            primary_id => [ 'Primary ID', 'text', 'required', 'length(2,80)' ],
            clinic_submitter_id => [ 'Submitter ID', 'text', 'required', 'length(2,80)' ],
            requires_rendering_provider_ids => [ "Requires each clinician's id", 'checkbox::boolean' ],
            send_personnel_id => [ "Send clinician's personnel id", 'checkbox::boolean' ],
            send_production_files => [ "Send production files", 'checkbox::boolean' ],
        },
        tools_3_save => {
            -alias  => 'Save Validation Rule',
            name           => [ 'Name', 'required' ],
            error_message  => [ 'Error message', 'required' ],
            rule_select    => [ 'SELECT' ],
            rule_from      => [ 'FROM' ],
            rule_where     => [ 'WHERE' ],
            rule_order     => [ 'ORDER BY' ],
        },
        tools_3_new => {
            -alias  => 'validation_rule_new',
        },
        tools_3_preview => {
            -alias  => 'validation_rule_preview',
        },
        tools_3_results => {
            -alias  => 'validation_rule_results',
            start_date  => [ 'Start date', 'required', 'date::iso' ],
            end_date    => [ 'End date', 'required', 'date::iso' ],
            payer_id    => [ 'Payer', 'number::integer' ],
        },
        tools_4_select_notes => {},
        tools_4_generate_pdf => {
        },
        tools_6_bill_manually => {
            client_insurance_id => [ 'Payer', 'required', 'number::integer' ],
            note_ids => [ 'Note ids', 'required', 'number::integer' ],
            form_done => [ 'Form done', 'required', 'checkbox::boolean' ],
        },
        finish => {
            confirm => [ 'Confirm completion', 'required', 'checkbox::boolean' ],
        },
        prognote_bounce_prep => {},
        prognote_bounce => {
            prognote_id     => [ 'Prognote', 'required' ],
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( %vars ) = @_;

    my $current = $self->_get_Current( %vars );
    if( ! $self->redirected and $self->op eq 'home'
        and $current->{ section } and defined $current->{ step }
    ) {
        $self->redirected(1);
        my $runmode = $self->current_page;
        return $self->$runmode
            if $self->can( $runmode );
    }

    $vars{ 'allow_bounce' } = $self->param( 'result_set_id' ) =~ /_failed$/ ? 1 : 0 
        unless defined $vars{ 'allow_bounce' }; 

    $self->template->process_page( 'financial/home', {
        default_section => $DEFAULT_SECTION,
        Current => $current,
        %vars,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub current_page {
    my $self = shift;
    my( %vars ) = @_;

    my $current = $self->_get_Current( %vars );
    return unless
        $current->{ section } and defined $current->{ step };
    return $current->{ section } .'_'. $current->{ step };
}

# billing {{{
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_1 {
    my $self = shift;
    my( %vars ) = @_;

    $vars{ validation_sets } = eleMentalClinic::Financial::ValidationSet->get_active;
    $vars{ billing_cycles  } = eleMentalClinic::Financial::BillingCycle->get_active;
    return $self->home( %vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_1_select {
    my $self = shift;

    return $self->home
        if $self->errors;

    return $self->home( error_message => 'No notes found for date range.' )
        unless my $set = eleMentalClinic::Financial::ValidationSet->create({
            creation_date   => $self->today,
            staff_id        => $self->current_user->id,
            type            => $self->param( 'cycle_type' ),
            from_date       => $self->param( 'start_date' ),
            to_date         => $self->param( 'end_date' ),
            step            => 2,
        });

    my %vars;
    for( qw/ start_date end_date cycle_type /) {
        $vars{ $_ } = $self->param( $_ )
            if defined $self->param( $_ );
    }
    $self->session->param( validation_set_id => $set->id );
    return $self->home( %vars, step => 2 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_2 {
    my $self = shift;

    return $self->home
        if $self->errors;

    my %vars;
#     $vars{ prognotes } = $self->_get_validation_set->prognotes;
    return $self->home( %vars, 
        section => 'billing',
        step    => 2,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_2_unselected {
    my $self = shift;

    return $self->home
        if $self->errors;

    my %vars;
    my $set = $self->_get_validation_set;

    $vars{ prognotes } = $set->prognotes_not_selected;
    return $self->home( %vars, 
        section => 'billing',
        step    => 2,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognote_toggle_billable {
    my $self = shift;

    return $self->home
        if $self->errors;
    my $note = $self->_get_prognote;
    ( $note->billing_status and $note->billing_status eq 'Unbillable' )
        ? $note->billing_status( 'Prebilling' )
        : $note->billing_status( 'Unbillable' );
    $note->save;

    # mark combined notes unbillable too. Fixes #596.
    foreach my $billing_service (map eleMentalClinic::Financial::BillingService->retrieve($_->{billing_service_id}), @{$note->billings}) {
        foreach my $combined_note (@{$billing_service->get_prognotes}) {
            if ($note->id != $combined_note->id) {
                $combined_note->billing_status($note->billing_status);
                $combined_note->save;
            }
        }
    }

    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognote_toggle_validity {
    my $self = shift;

    return $self->home
        if $self->errors;

    my $set = $self->_get_validation_set;
    my $force = $self->param( 'current_validity' ) * -1 + 1;

    $set->validation_prognote_force_valid( $self->param( 'validation_prognote_id' ), $force );
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognote_toggle_manual {
    my $self = shift;

    return $self->home
        if $self->errors;
    my $note = $self->_get_prognote;
    $note->bill_manually ? $note->bill_manually( 0 ) : $note->bill_manually( 1 );
    $note->save;

    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_3 {
    my $self = shift;

    return $self->home
        if $self->errors or not my $set = $self->_get_validation_set;
    $set->step( 3 )->save
        unless $set->step > 3;
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_3_validate {
    my $self = shift;

    return $self->home
        if $self->errors;

    my $rule_ids = $self->get_item_ids({ $self->Vars }, 'rule' );
    my %rules = map{ $_ => 1 } @$rule_ids;
    return $self->home( force_confirm => 1, selected_rules => \%rules )
        if not @$rule_ids and not $self->param( 'confirm' );

    unless (@$rule_ids) {
        # this deliberately does not update %rules (and therefore the display
        # of selected rules); we still want to pretend that no rules are
        # selected
        @$rule_ids = map { $_->rec_id } 
            @{ eleMentalClinic::Financial::ValidationRule->system_default_rules };
    }
    
    my $set = $self->_get_validation_set;

    if( $set->step >= 3 and $set->status eq 'Validated' ) {
        $self->add_error(
            'step',
            'step',
            'Validation has already been run for this set.'
        )
    }
    else {
        eleMentalClinic::Financial::ValidationRule->save_rules( $rule_ids );
        $set->system_validation( $rule_ids );
    }
    return $self->home( selected_rules => \%rules );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_3_results {
    my $self = shift;

    $self->ajax( 1 )
        if $self->param( 'live' );

    my $set = $self->_get_validation_set;
    my $pass = $self->param( 'pass' );
    my $rolodex_id = $self->param( 'rolodex_id' );
    my $results = $set->results( defined $pass ? $pass : undef, $rolodex_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_4 {
    my $self = shift;

    return $self->home
        if $self->errors;

    my $set = $self->_get_validation_set;
    unless( defined($set->step) && $set->step > 4 ) {
        $set->step( 4 );
        $set->status( 'Begun' );
        $set->save;
    }

    my $rolodex = $self->_get_rolodex;
    unless( $set->insurers ) {
        # FIXME better error message
        die 'failed'
            unless $set->group_prognotes_by_insurer;
    }

    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_4_validate {
    my $self = shift;

    return $self->home
        if $self->errors;

    my $rule_ids = $self->get_item_ids({ $self->Vars }, 'rule' );
    my %rules = map{ $_ => 1 } @$rule_ids;
    return $self->home(
        force_confirm   => 1,
        selected_rules  => \%rules,
        )
        if not @$rule_ids and not $self->param( 'confirm' );

    unless (@$rule_ids) {
        @$rule_ids = map { $_->rec_id } 
            @{ eleMentalClinic::Financial::ValidationRule->payer_default_rules };
    }
    
    my $set = $self->_get_validation_set;
    my $insurer = $self->_get_rolodex;

    if( $set->step >= 4 and $set->status eq 'Validated' ) {
        $self->add_error(
            'step',
            'step',
            'Payer validation has already been run.'
        )
    }
    else {
        eleMentalClinic::Financial::ValidationRule->save_rules( $rule_ids, $insurer->id );
        $set->payer_validation( $rule_ids, $insurer->id );
    }
    return $self->home(
        selected_rules  => \%rules,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_5 {
    my $self = shift;

    return $self->home
        if $self->errors;

    my $set = $self->_get_validation_set;
    $set->step( 5 );
    $set->save;
    
    unless( $set->billing_cycle->get_billing_files ) {
        # move all notes to billing - if there aren't any billing files yet
        my $insurers = $set->insurers;
        $set->billing_cycle->move_notes_to_billing( $_->rec_id )
            for @$insurers;
    }

    # XXX Would be nice to look up the last sent file and display the resulting files.
    # That might require adding a billing_file_id to ecs_file_downloaded?

    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_5_ecs {
    my $self = shift;

    return $self->home
        if $self->errors;

    return $self->send_837;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub send_837 {
    my $self = shift;
    my %vars;

    return $self->home( write_result => 'Missing billing_file_id' )
        unless $self->param( 'billing_file_id' );
    
    my $set = $self->_get_validation_set;
    return $self->billing_1(
        step    => 1,
    ) unless $set;

    my( $file837, $edi_data );
    eval { ( $file837, $edi_data ) = $set->billing_cycle->write_837( $self->param( 'billing_file_id' ) ); };
    return $self->home( write_result => 'Error writing 837 file. ' . eleMentalClinic::Log::Log_tee( $@ ) )
        if $@ or !$file837;
    
    warn "ECS billing file " . $self->param( 'billing_file_id' ) . " generated: $file837";

    my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $self->param( 'billing_file_id' ) );
    return $self->home( write_result => 'Unable to get the billing file just created, from the database.' ) unless $billing_file;
 
    my $connect;
    eval { $connect = eleMentalClinic::ECS::Connection->new({ claims_processor_id => $billing_file->payer->claims_processor_id })->get_connection; };
    return $self->home( write_result => 'Error setting up the connection. ' . eleMentalClinic::Log::Log_tee( $@ ) ) unless $connect;

    my( $response_files, $result );
    eval { ( $response_files, $result ) = $connect->put_file( $file837 ); };
    $vars{ write_result }  = $result if $result;
    $vars{ write_result } .= "\n" . eleMentalClinic::Log::Log_tee( $@ ) if $@;

    if( $result and $result =~ /Successfully sent billing file/ ){
        eval { $billing_file->save_as_billed( $self->timestamp, $edi_data )  };
        $vars{ write_result } .= "\n" . eleMentalClinic::Log::Log_tee( $@ ) if $@;
    }
    @{ $vars{ download_results } } = map { $self->process_files( $_ ) } @$response_files;
    $vars{ connect_log } = $connect->log;

    return $self->home( %vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_5_hcfa {
    my $self = shift;

    return $self->home
        if $self->errors;

    return $self->home( write_result => 'Missing billing_file_id' )
        unless $self->param( 'billing_file_id' );
    
    my $set = $self->_get_validation_set;
    my( $filename );
    eval { $filename = $set->billing_cycle->write_hcfas( $self->param( 'billing_file_id' ) ); };
    return $self->home( write_result => 'Unable to generate the HCFA. ' . eleMentalClinic::Log::Log_tee( $@ ) )
        unless $filename;
        
    $self->send_file({
        path        => $filename,
        name        => 'HCFA.pdf',
        mime_type   => 'application/pdf',
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub select_validation_set {
    my $self = shift;

    return $self->home( error_message => 'Validation set not found.' )
        unless my $set = $self->_get_validation_set;
    $self->session->param( validation_set_id => $set->id );
    $self->home(
        section => 'billing',
        step    => $set->step || 2,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub select_billing_cycle {
    my $self = shift;

    my $cycle = $self->_get_billing_cycle;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub finish {
    my $self = shift;

    return $self->home( step => 0 )
        if $self->errors;

    $self->_get_validation_set->finish;
    $self->session->clear( 'validation_set_id' );
    return $self->billing_1(
        step    => 1,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_load_prognotes {
    my $self = shift;

    return if $self->errors;
    $self->ajax( 1 );

    return $self->template->process_page( 'financial/billing/notes', {
        Current     => $self->_get_Current,
        prognotes   => $self->_get_validation_set->prognotes( $self->param( 'rolodex_id' )),
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME: sometimes there is no param 'result_set_id', so the hash sent
# to $self->home has an odd number of elements (warning).
sub billing_show_results {
    my $self = shift;

    return $self->home
        if $self->errors;
    my $set = $self->_get_validation_set;
    my $pass = $self->param( 'result_set_id' ) =~ /_failed$/    ? 0
        : $self->param( 'result_set_id' ) =~ /_passed$/         ? 1
        :                                                         undef;
    return $self->home(
        result_set_id   => $self->param( 'result_set_id' ),
        results         => $set->results( $pass, $self->param( 'rolodex_id' )),
        rules           => $set->payer_rules_used( $self->param( 'rolodex_id' )),
        allow_bounce    => $pass ? 0 : defined $pass ? 1 : 0, #allow_bounce should be false if $pass is true or undef. 
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_load_results {
    my $self = shift;

    return $self->home
        if $self->errors;
    $self->ajax( 1 );
    my $set = $self->_get_validation_set;
    my $pass = $self->param( 'result_set_id' ) =~ /_failed$/    ? 0
        : $self->param( 'result_set_id' ) =~ /_passed$/         ? 1
        :                                                         undef;

    return $self->template->process_page( 'financial/billing/results', {
        result_set_id   => $self->param( 'result_set_id' ),
        Current         => $self->_get_Current,
        results         => $set->results( $pass, $self->param( 'rolodex_id' )),
        allow_bounce    => $pass ? 0 : defined $pass ? 1 : 0, #allow_bounce should be false if $pass is true or undef. 
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub billing_set_failures_unbillable {  print STDERR "sub billing_set_failures_unbillable { \n";
    my $self = shift; 
 
    my $set = $self->_get_validation_set; 
    $set->set_notes_which_fail_rule( $self->param( 'validation_rule_id' ), 'Unbillable', $self->param( 'rolodex_id' )); 
    return $self->billing_show_results; 
} 
#}}}
# bouncing {{{
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognote_bounce_prep {
    my $self = shift;
    my( %vars ) = @_;

    $self->ajax( 1 );
    $vars{ prognote } = eleMentalClinic::ProgressNote->retrieve( $self->param( 'prognote_id' ));
    $vars{ Current } = $self->_get_Current;
    $self->template->process_page( 'financial/billing/prognote_bounce', {
        %vars,
        ajax        => 1,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognote_bounce {
    my $self = shift;
    my( %vars ) = @_;

    return $self->home
        if $self->errors;

    my $prognote = $self->_get_prognote;
    my $rules = $prognote->validation_rules_failed( $self->_get_validation_set->id );
    my $message;
    if( $rules ) {
        my $text = join "\n" => map{ '- '. $_->name } @$rules;
        $message = "Rules:\n$text";
    }
    $prognote->bounce( $self->current_user, $message );
    $self->home;
}
# }}}
# payments {{{
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payments_1 {
    my $self = shift;
    my( %vars ) = @_;

    $vars{ billing_payments } = eleMentalClinic::Financial::BillingPayment->get_all;
    $vars{ current_payment } ||= $self->_get_billing_payment;
    $vars{ insurers } = $self->_get_insurers;

    return $self->home( %vars,
        section => 'payments',
        step    => 1,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payments_1_new {
    my $self = shift;

    return $self->payments_1
        if $self->errors;
    return $self->payments_1( current_payment => {} );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payments_1_save {
    my $self = shift;

    my $vars = $self->Vars;
    return $self->payments_1( current_payment => $vars )
        if $self->errors;

    my $payment = $self->_get_billing_payment
        || eleMentalClinic::Financial::BillingPayment->new({
            %$vars,
            entered_by_staff_id => $self->current_user->id || $self->param( 'entered_by_staff_id' )
        });
    # TODO
    die 'error' # FIXME more descriptive
        unless $payment->save;
    return $self->payments_1( current_payment => $payment );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payments_2_transaction_toggle_error {
    my $self = shift;

    $self->ajax( 1 );
    my $transaction = $self->_get_transaction;
    $transaction->entered_in_error
        ? $transaction->entered_in_error( 0 )
        : $transaction->entered_in_error( 1 );
    return 1
        if $transaction->save;

    # TODO
    die 'should not happen';
    my %vars;
    $vars{ Current } = $self->_get_Current;
    $vars{ transaction } = $transaction;
    # the ~ is a record separator, so we know which transaction to update
    return 'transaction_'. $transaction->id .'~'.
        $self->template->process_page( 'financial/payments/transaction', {
            %vars,
        });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payments_3 {
    my $self = shift;
    my( %vars ) = @_;

    $vars{ insurers } = $self->_get_insurers;
    $vars{ current_insurer } = $self->_get_rolodex;

    if( $vars{ current_insurer } ){
        $vars{ outstanding } = eleMentalClinic::Financial::BillingService->get_unpaid( $vars{ current_insurer }->rec_id );
        $vars{ billing_payments } = eleMentalClinic::Financial::BillingPayment->get_manual_by_rolodex( $vars{ current_insurer }->rec_id );
        $vars{ reason_codes } = $self->current_user->valid_data->get_name_desc_list( '_claim_adjustment_codes' );
    }

    return $self->home( %vars,
        section => 'payments',
        step    => 3,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payments_3_save {
    my $self = shift;
    my $vars = $self->Vars;

    # preserve the entered fields in case there is an error
    for( qw/ paid_charge_code paid_amount paid_units deduction_1 deduction_2
            deduction_3 deduction_4 reason_1 reason_2 reason_3 reason_4 
            payer_claim_control_number patient_responsibility_amount remarks 
            billing_service_id billing_payment_id claim_status_code / ) 
    {
        $vars->{ current_transaction }{ $_ } = $vars->{ $_ };
    }

    return $self->payments_3( %$vars )
        if $self->errors;

    my $billing_service = eleMentalClinic::Financial::BillingService->retrieve( 
        $vars->{ billing_service_id } 
    );

    my $error = $billing_service->save_manual_payment( $vars );
    if( $error ) {
        $self->add_error( 'step', 'step', $error );
        return $self->payments_3( %$vars );
    }

    # FIXME send the current transaction back, to be displayed as read-only
    # - otherwise it will disappear as the prognote is no longer outstanding.
    # for now, show a 'saved' message
    $vars->{ saved } = 1;

    return $self->payments_3( %$vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payments_4 {
    my $self = shift;

    my %vars;
    $vars{ insurers } = $self->_get_edi_insurers;

    %vars = $self->get_payments( %vars );

    # XXX Not used in the UI, but useful for testing
    push @{ $vars{ download_results } } => $self->process_files( $self->param( 'file' ) )
        if $self->param( 'file' );

    return $self->home( %vars,
        section => 'payments',
        step    => 4,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_payments {
    my $self = shift;
    my( %vars ) = @_;
    
    return %vars
        unless $self->param( 'rolodex_id' );

    my $rolodex = eleMentalClinic::Rolodex->retrieve( $self->param( 'rolodex_id' ) );
    return %vars unless $rolodex;
  
    my $connect;
    eval { $connect = eleMentalClinic::ECS::Connection->new({ claims_processor_id => $rolodex->claims_processor_id })->get_connection; };
    unless( $connect ){
        $vars{ receive_error } = 'Error setting up the connection. ' . eleMentalClinic::Log::Log_tee( $@ );
        return %vars;
    }

    my( $files, $error );
    eval { ( $files, $error ) = $connect->get_new_files; };
    $vars{ receive_error } = $error if $error;
    $vars{ receive_error } .= "\n" . eleMentalClinic::Log::Log_tee( $@ ) if $@;
    @{ $vars{ download_results } } = map { $self->process_files( $_ ) } @$files;

    $vars{ connect_log } = $connect->log;

    return %vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub process_files {
    my $self = shift;
    my( $filename ) = @_;

    return unless $filename;

    my $file = $self->config->edi_in_root . '/' . $filename;

    if( eleMentalClinic::ECS::Read835->valid_file( $file ) ){
        
        my $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
        eval { $billing_payment->process_remittance_advice( $file, $self->timestamp ); }; # timestamp = date received

        my %response = ( file => $filename, billing_payment => $billing_payment );
        $response{ error } = eleMentalClinic::Log::Log_tee( $@ ) if $@;
        return \%response;
    }
    elsif( eleMentalClinic::ECS::Read997->valid_file( $file ) ){
       
        my $read_997 = eleMentalClinic::ECS::Read997->new;
        $read_997->file( $file );
        eval { $read_997->parse; };
        eval { $read_997->get_edi_data; } unless $@;

        my %response = ( file => $filename, read_997 => $read_997 );
        $response{ error } = eleMentalClinic::Log::Log_tee( $@ ) if $@;
        return \%response;
    }
    elsif( eleMentalClinic::ECS::ReadTA1->valid_file( $file ) ){
        my $read_ta1 = eleMentalClinic::ECS::ReadTA1->new;
        $read_ta1->file( $file );
        eval { $read_ta1->parse; };
        eval { $read_ta1->get_edi_data; } unless $@;
        
        my %response = ( file => $filename, read_ta1 => $read_ta1 );
        $response{ error } = eleMentalClinic::Log::Log_tee( $@ ) if $@;
        return \%response;
    }

    open EDI_FILE, "< $file" or return;
    my $content = join( '', <EDI_FILE> );
    close EDI_FILE;
    return { file => $filename, file_content => $content };
}

# }}}
# reports {{{
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub reports_1 {
    my $self = shift;

    my %vars = $self->_report_vars;
    delete $vars{ current_report }{ $_ } for qw/data run sublabel/;
    return $self->home(
        %vars,
        section => 'reports',
        step    => 1,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub reports_1_run {
    my $self = shift;

    return $self->reports_1
        if $self->errors;

    my %vars = $self->_report_vars;
    my $method = $vars{ current_report }{ name };
    # _report_vars() makes sure this is a valid method
    # or it should, anyway :)
    my %args = $self->Vars;
    delete $args{ $_ } for grep { !defined $args{ $_ } } keys %args;
    eval{ $vars{ current_report }{ data } = eleMentalClinic::Report->new(
        name => $method,
        %args
    )->with_data->data };
    #Because of moose these errors can get nasty and long
    if( my $orig_error = $@ ) {
        my $error = $orig_error;
        # If an attribute has a problem we guess at it's name and say its required (Not optimal)
        if ( $error =~ s/^Attribute \(([^\)]*)\).*/$1/sg ) {
            $error =~ s/_.*//;

            # Rolodex is only in one place as insurer.
            # XXX We need a better way to parse these errors.
            $error = 'Insurer' if $error eq 'rolodex';

            $error = "$error is required.";
        }
        else {
            #If nothing else at least remove all but the first line, we do not
            #need to scare the clinician with 3 pages of stack trace.
            $error =~ s/\n.*//s;
            $error =~ s# at /.*#.#;
        }
        $self->add_error( 'report_name', 'report_name', $error )
    }
    else {
        $vars{ current_report }{ run } = 1;
        $vars{ current_report }{ sublabel } = $vars{ sublabel };
        # XXX hmmm, should find a better way to set these.  also in Report controller.
        $self->template->vars({
            styles          => [ 'layout/00', 'financial', 'report', 'date_picker' ],
            print_styles    => [ 'report_print_new' ],
        });
    }
    return $self->home( %vars,
        section => 'reports',
        step    => 1,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _report_vars {
    my $self = shift;

    my %vars;
    return unless
        $vars{ financial_reports } = eleMentalClinic::Report->financial_report;
    return %vars
        unless my $name = $self->param( 'report_name' );

    # get the Report module's data
    for( @{ $vars{ financial_reports }}) {
        if( $_->{ name } eq $name ) {
            $vars{ current_report } = $_;
            last;
        }
    }

    # get any setup data specific to this report
    if( $name and $self->can( "_report_$name" )) {
        my $method = "_report_$name";
        %vars = ( %vars, $self->$method );
    }
    return %vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _report_services_by_client {
    my $self = shift;

    return
        unless $self->client->id;

    my $prognotes = $self->client->prognotes_billed(
        $self->param( 'start_date' ),
        $self->param( 'end_date' ),
    );
    return( prognotes => $prognotes );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _report_billing_totals_by_program {
    my $self = shift;

    my $billing_file;
    $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $self->param( 'billing_file_id' ))
        if $self->param( 'billing_file_id' );

    return(
        billing_files => eleMentalClinic::Financial::BillingFile->get_all,
        sublabel      => $billing_file ? $billing_file->label : '',
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _report_payment_totals_by_program {
    my $self = shift;

    my $billing_payment;
    $billing_payment = eleMentalClinic::Financial::BillingPayment->retrieve( $self->param( 'billing_payment_id' ))
        if $self->param( 'billing_payment_id' );
    $billing_payment = eleMentalClinic::Financial::BillingPayment->get_one_by_( 'payment_number', $self->param( 'payment_number' ))
        if $self->param( 'payment_number' );

    return(
        sublabel      => $billing_payment ? $billing_payment->label : '',
        billing_payments => eleMentalClinic::Financial::BillingPayment->get_all,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _report_monthly_summary_by_insurer {
    my $self = shift;
    return( insurers => $self->_get_insurers );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _report_audit_trail_by_client {
    my $self = shift;

    my $date = $self->param( 'date' );
    return unless $date;
    return( this_month => $date, last_month => date_calc( $date, '-1m' ));
}
#}}}
# tools {{{
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_1 {
    my $self = shift;
    my( %vars ) = @_;

    $self->session->param( client_insurance_authorization_subnav
            => $self->param( 'client_insurance_authorization_subnav' )
        )
        if $self->param( 'client_insurance_authorization_subnav' );

    $vars{ auth_month } = $self->param( 'auth_month' ) || $self->today;
    $vars{ auths_expiring } = eleMentalClinic::Client::Insurance::Authorization->renewals_due_in_month( $vars{ auth_month })
        if $self->session->param( 'client_insurance_authorization_subnav' ) eq 'current';
    $vars{ auths_all } = eleMentalClinic::Client->get_all
        if $self->session->param( 'client_insurance_authorization_subnav' ) eq 'all';
    return $self->home( %vars,
        section => 'tools',
        step    => 1,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_insurance_authorization_request {
    my $self = shift;

    my %vars;
    $vars{ current_auth } = $self->_get_insurance_authorization;
    $vars{ current_request } = $vars{ current_auth }->authorization_request
        if $vars{ current_auth };
    $self->tools_1( %vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_insurance_authorization_request_save {
    my $self = shift;

    my %vars;
    $vars{ current_auth } = $self->_get_insurance_authorization;
    return $self->home( %vars )
        if $self->errors;

    my $request = eleMentalClinic::Client::Insurance::Authorization::Request->new({
        client_id   => $self->client->id,
        start_date  => $self->param( 'start_date' ),
        end_date    => $self->param( 'end_date' ),
    });
    $request->client_insurance_authorization_id( $vars{ current_auth }->id )
        if $vars{ current_auth };
    $request->populate;

    die 'error' unless $request->save; # FIXME more descriptive
    $self->tools_1( %vars, current_request => $request );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_insurance_authorization_request_print {
    my $self = shift;

    return $self->tools_1
        if $self->errors;
    my $request = eleMentalClinic::Client::Insurance::Authorization::Request->retrieve( $self->param( 'client_insurance_authorization_request_id' ));

    die 'error' unless $request->write; # FIXME more descriptive
    $self->send_file({
        path        => $self->config->pdf_out_root .'/'. $request->filename,
        name        => 'InsuranceAuthorization.pdf',
        mime_type   => 'application/pdf',
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_2 {
    my $self = shift;
    my( %vars ) = @_;

    $vars{ claims_processor } ||= $self->_get_claims_processor;
    $vars{ claims_processors } = eleMentalClinic::Financial::ClaimsProcessor->get_all;
    return $self->home( %vars,
        section => 'tools',
        step    => 2,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_2_save {
    my $self = shift;

    # don't allow creation of new ones
    return $self->tools_2
        unless my $cp = $self->_get_claims_processor;
    my $vars = $self->Vars;
    # FIXME ew this sucks
    $vars->{ rec_id } = $vars->{ claims_processor_id };
    $vars->{ id } = $vars->{ claims_processor_id };
    
    # check password length
    my $min_length = $vars->{ password_min_char } or $cp->password_min_char;
    if( $min_length and length $vars->{ password } < $min_length ) {
        $self->add_error(
            'password',
            'password',
            "Password must be at least $min_length characters."
        )
    }
    unless( $self->errors ) {
        $cp->update( $vars );
    }
    else {
        $cp = $vars;
    }
    return $self->tools_2( claims_processor => $cp );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_3 {
    my $self = shift;
    my( %vars ) = @_;

    $vars{ current_rule } ||= $self->_get_validation_rule;
    $vars{ validation_query } = $self->_get_validation_query( $vars{ current_rule });
    $vars{ rules } = eleMentalClinic::Financial::ValidationRule->get_all;
    return $self->home( %vars,
        section => 'tools',
        step    => 3,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_3_save {
    my $self = shift;

    my $vars = $self->Vars;
    # FIXME ew this sucks
    $vars->{ rec_id } = $vars->{ validation_rule_id };
    $vars->{ id } = $vars->{ validation_rule_id };

    my $rule = eleMentalClinic::Financial::ValidationRule->new( $vars );
    for( qw/ select from where order /) {
        my $ok = eleMentalClinic::Financial::ValidationRule->sanitize( $_, $self->param( "rule_$_" ));
        next if defined $ok;

        my $label = uc $_;
        $self->add_error(
            "rule_$_",
            "rule_$_",
            "Semicolons, comments, and SELECT, DELETE, DROP, UPDATE, INTO are not allowed in <strong>$label</strong>."
        )
    }
    return $self->tools_3( current_rule => $rule )
        if $self->errors;

    $vars->{ scope } = lc $vars->{ scope };
    # TODO check password length
    if( $rule ) {
        $rule->update( $vars );
    }
    else {
        $rule = eleMentalClinic::Financial::ValidationRule->new( $vars )->save;
    }
    return $self->tools_3( current_rule => $rule );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_3_new {
    my $self = shift;

    return $self->tools_3(
        op => 'validation_rule_new',
        current_rule => undef,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_3_preview {
    my $self = shift;

    my %vars;
    $vars{ current_rule } = $self->_get_validation_rule;
    $vars{ insurers } = $self->_get_insurers;

    return $self->tools_3(
        %vars,
        op                  => 'validation_rule_preview',
        validation_rule_nav => 'preview',
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_3_results {
    my $self = shift;

    my %vars;
    $vars{ current_rule } = $self->_get_validation_rule;
    unless( $self->errors ) {
        $vars{ rules } = $vars{ current_rule };
        $vars{ start_date } = $self->param( 'start_date' );
        $vars{ validation_query } = $self->_get_validation_query( $vars{ current_rule });
        $vars{ end_date } = $self->param( 'end_date' );
        $vars{ payer_id } = $self->param( 'payer_id' );

        $vars{ note_clients } = {};
        for my $client ( @{ eleMentalClinic::Client->get_all }) {
            $vars{ note_clients }->{ $client->client_id } = $client;
        }

        eval {
            $vars{ result_sets } = [
                {
                    id      => 'results',
                    label   => 'All Notes',
                    results => $vars{ current_rule }->results_preview(
                        $self->param( 'start_date' ),
                        $self->param( 'end_date' ),
                        $self->param( 'payer_id' )
                    ),
                },
            ];
        };
        $self->add_error(
            'validation_rule_id',
            'validation_rule_id',
            'Your query has an error: '. $@
        )
        if $@;
    }

    $vars{ insurers } = $self->_get_insurers;
    return $self->tools_3(
        %vars,
        op                  => 'validation_rule_results',
        validation_rule_nav => 'preview',
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_validation_query {
    my $self = shift;
    my( $rule ) = @_;

    my %vars = (
        select  => $eleMentalClinic::Financial::ValidationRule::SELECT,
        from    => $eleMentalClinic::Financial::ValidationRule::FROM,
        where   => $eleMentalClinic::Financial::ValidationRule::WHERE,
        order   => $eleMentalClinic::Financial::ValidationRule::ORDER,
    );
    if( $rule ) {
        $vars{ query } = $rule->validation_query(
            $self->param( 'start_date' ) || $self->today,
            $self->param( 'end_date' ) || $self->today,
            $self->param( 'payer_id' )
        );
    }
    return \%vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_4 {
    my $self = shift;
    my $vars = $self->Vars;

    if( $self->config->medicaid_rolodex_id ){
        if( $vars->{ client_id } ){
            $vars->{ payments } = eleMentalClinic::Financial::Transaction->get_for_adjustment( $vars->{ client_id }, $self->config->medicaid_rolodex_id );
        }
        $vars->{ rolodex } = eleMentalClinic::Rolodex->retrieve( $self->config->medicaid_rolodex_id );
    }
    return $self->home( %$vars,
        section => 'tools',
        step    => 4,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_4_select_notes {
    my $self = shift;
    my $vars = $self->Vars;

    return $self->home
        if $self->errors;
    
    $vars = $self->get_transaction_ids( $vars );

    unless( scalar @{ $vars->{ transaction_ids } } > 0 ) {
        $self->add_error( 'step', 'step', 'No transactions from this claim are selected' );
        return $self->tools_4;
    }
 
    $vars->{ adjustment } = eleMentalClinic::Financial::MedicaidAdjustment->new( $vars );

    return $self->home( %$vars,
        section => 'tools',
        step    => 4,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_4_generate_pdf {
    my $self = shift;
    my $vars = $self->Vars;

    $vars = $self->get_transaction_ids( $vars );

    my $adjustment;
    $adjustment = eleMentalClinic::Financial::MedicaidAdjustment->new( $vars );
    my $filename = $adjustment->write;

    # TODO display errors in template
    return $self->home( write_result => 'Unable to generate the Medicaid Adjustment. ' . eleMentalClinic::Log::Log_tee( $@ ) )
        unless $filename;

    # TODO display warnings (are there any?)
    $self->send_file({
        path        => $filename,
        name        => 'MedicaidAdjustment.pdf',
        mime_type   => 'application/pdf',
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_transaction_ids {
    my $self = shift;
    my( $vars ) = @_;
    my @transaction_ids;

    for( keys %$vars ){
        if( /^transaction_(\d*)$/ ){
            push @transaction_ids => $1;
        }
    }
    $vars->{ transaction_ids } = \@transaction_ids;
    return $vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub tools_5 {
    my $self = shift;
    my( %vars ) = @_;

    $vars{ bounced_prognotes } = eleMentalClinic::ProgressNote::Bounced->get_active;
    return $self->home( %vars,
        section => 'tools',
        step    => 5,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Present the Manual Billing Notes Screen
sub tools_6 {
    my $self = shift;
    my( %vars ) = @_;

    $vars{ manual_notes } = eleMentalClinic::ProgressNote->get_manual_to_bill;
    return $self->home( %vars,
        section => 'tools',
        step    => 6,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Process a request to manually bill a group of notes and return
# the Manual Billing Notes Screen
sub tools_6_bill_manually {
    my $self = shift;
    my( %vars ) = @_;

    unless ($self->errors) {

        eleMentalClinic::Financial::BillingCycle->bill_manual_combined_notes(
            $self->param( 'note_ids' ),
            $self->current_user->id,
            $self->param( 'client_insurance_id' )
        ); 
   
    }
    
    $vars{ manual_notes } = eleMentalClinic::ProgressNote->get_manual_to_bill;
    return $self->home( %vars,
        section => 'tools',
        step    => 6,
    );
}

#}}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_Current {
    my $self = shift;
    my( %vars ) = @_;

    %vars = ( $self->Vars )
        unless %vars;
    # automatically constructs a runmode out of 'section' and 'step',
    # if we get them, and tries to run it
    my $section = $vars{ section } || $self->_section;
    my $step = defined $vars{ step }        ? $vars{ step }
        : defined $self->param( 'step' )    ? $self->param( 'step' )
        :                                     1;

    my $validation_set = $self->_get_validation_set;
    # XXX this doesn't account for billing cycle
    $step = 1 # with no set or cycle, can't progress
        if $section eq 'billing' and not $validation_set;

    my %current = (
        section         => $section,
        step            => $step,
        validation_set  => $validation_set || 0,
        insurer         => $self->_get_rolodex || 0,
    );

    return \%current;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _section {
    my $self = shift;

    my $section = $self->param( 'section' );
    return $section
        if $section and grep /^$section$/ => qw/ home billing payments reports tools /;
    return $DEFAULT_SECTION;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_validation_set {
    my $self = shift;

    return unless
        my $id = $self->param( 'validation_set_id' )
            || $self->session->param( 'validation_set_id' );
    return eleMentalClinic::Financial::ValidationSet->retrieve( $id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_billing_cycle {
    my $self = shift;

    return unless
        my $id = $self->session->param( 'billing_cycle_id' )
              || $self->param( 'billing_cycle_id' );
    return eleMentalClinic::Financial::BillingCycle->retrieve( $id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_claims_processor {
    my $self = shift;

    return unless
        my $id = $self->session->param( 'claims_processor_id' )
              || $self->param( 'claims_processor_id' );
    return eleMentalClinic::Financial::ClaimsProcessor->retrieve( $id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_validation_rule {
    my $self = shift;

    return unless
        my $id = $self->session->param( 'validation_rule_id' )
              || $self->param( 'validation_rule_id' );
    return eleMentalClinic::Financial::ValidationRule->retrieve( $id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_prognote {
    my $self = shift;

    return unless
        my $id = $self->session->param( 'prognote_id' )
              || $self->param( 'prognote_id' );
    return eleMentalClinic::ProgressNote->retrieve( $id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_insurance_authorization {
    my $self = shift;

    return unless $self->param( 'client_insurance_authorization_id' );
    return eleMentalClinic::Client::Insurance::Authorization->retrieve(
        $self->param( 'client_insurance_authorization_id' )
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_billing_payment {
    my $self = shift;

    return unless $self->param( 'billing_payment_id' );
    return eleMentalClinic::Financial::BillingPayment->retrieve(
        $self->param( 'billing_payment_id' )
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_insurers {
    my $self = shift;
    return eleMentalClinic::Rolodex->new->get_byrole( 'mental_health_insurance' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_edi_insurers {
    my $self = shift;
    return eleMentalClinic::Rolodex->get_edi_rolodexes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_transaction {
    my $self = shift;

    return unless $self->param( 'transaction_id' );
    return eleMentalClinic::Financial::Transaction->retrieve( $self->param( 'transaction_id' ));
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
