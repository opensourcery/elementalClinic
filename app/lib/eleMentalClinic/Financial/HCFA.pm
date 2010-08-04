package eleMentalClinic::Financial::HCFA;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::HCFA

=head1 SYNOPSIS

Writes Health Insurance Claim Form PDFs - HCFAs. Child of 
L<eleMentalClinic::Financial::WriteClaim>.

=head1 DESCRIPTION

HCFA is a simple wrapper for controlling production of HCFA paper forms
from eleMentalClinic::Financial::BillingFile objects.

=head1 Usage

    my $hcfa = eleMentalClinic::Financial::HCFA->new( { billing_file => $billing_file_ref } )

    # Call write() to have the HCFA output as a pdf file in the current 
    # $config->pdf_out_root directory
    $hcfa->write();

=head1 METHODS

=cut


use base qw/ eleMentalClinic::Financial::WriteClaim /;
use Data::Dumper;
use eleMentalClinic::PDF;
use YAML::Syck qw/ LoadFile /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args, $options ) = @_;
    my $class = ref $self;

    $self->SUPER::init( $args, $options );
    eleMentalClinic::Base::attribute( $class, 'pdf' ); # add a 'pdf' method. can't just define sub method - that overrides base's methods.
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 defaults()

Sets core object properties, unless they have already been set.

 * output_root is taken from the Config, although it 
may be set manually /after/ construction.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub defaults {
    my $self = shift;
    
    $self->SUPER::defaults;

    $self->output_root( $self->config->pdf_out_root );
    warn "config's pdf_out_root is blank" unless $self->output_root;

    # uncomment to print the form as well as the data
    #$self->template( 'hcfa1500.pdf' );

    $self->valid_lengths( LoadFile( $self->config->hcfa_fieldlimits ) );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 make_filename( $billing_file_id, $payer_name )
 
Generates a filename in the following format "%d%sHCFA%04d" as filled by 
the billing_file rec_id, payer name, and month & day of the date_stamp.

[billingfileid][payername]HCFAmmdd.pdf

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub make_filename {
    my $self = shift;
    my( $billing_file_id, $payer_name ) = @_;

    return unless $billing_file_id
        and $payer_name;

    # strip characters to make a better filename
    $payer_name =~ s/\W//g;

    my $date = $self->date_stamp;
    return unless $date and length $date == 8;

    $date =~ s/^(\d{4})(\d{2})(\d{2})$/$2$3/;

    return sprintf '%d%sHCFA%04d.pdf', ( 
        $billing_file_id,
        $payer_name,
        $date
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 write()

Object method.

Creates HCFA forms based on the currently set BillingFile object.

Dies if unable to get the key data.

Returns a list of the filenames created.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub write {
    my $self = shift;

    return unless $self->date_stamp;
    return unless $self->date_stamp =~ /\d{8}/;  # CCYYMMDD
    return unless $self->billing_file;

    my $hcfa_data = $self->billing_file->get_hcfa_data;
    die 'Unable to get data for HCFA generation.'
        unless $hcfa_data;

    $hcfa_data = $self->validate( $hcfa_data );

    return $self->generate_hcfas( $hcfa_data );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 generate_hcfas( $hcfa_data )

Object method.

Takes hash of data and generates all HCFAs from it.

One HCFA is generated for each claim, except claims that
have more than 6 service lines are separated into different 
HCFA files.

All HCFAs are returned in a single PDF file.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub generate_hcfas {
    my $self = shift;
    my( $hcfa_data ) = @_;

    return unless $hcfa_data and $self->billing_file;

    my $file_path = $self->output_root . '/' . 
        $self->make_filename( $self->billing_file->rec_id, $hcfa_data->{ payer }{ name } );
    unlink $file_path;
 
    $self->pdf( eleMentalClinic::PDF->new );
    my $form = $self->template ? $self->config->template_path . '/hcfa_billing/' . $self->template : undef;
    $self->pdf->start_pdf( $file_path, $form );

    # Resize For Proper Printing
    $self->pdf->adjustmbox( 0, 0, 612, 798 );

    for my $claim ( @{ $hcfa_data->{ claims } } ) {
       
        my @lines = @{ $claim->{ client }{ service_lines } || [] };
        while( @lines ){

            $claim->{ client }{ service_lines } = [ splice @lines, 0, 6 ];
            $self->generate_hcfa( $hcfa_data->{ payer }, $hcfa_data->{ billing_provider }, $claim );
            $self->pdf->newpage;
        }
    }
    
    return $self->pdf->finish_pdf;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 generate_hcfa( $payer, $billing_provider, $claim_data )

Object method.

Generates a single HCFA from the data. A PDF must already be started for writing.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub generate_hcfa {
    my $self = shift;
    my( $payer, $billing_provider, $claim_data ) = @_;

    return unless $payer
        and $billing_provider
        and $claim_data
        and $self->pdf;

    my $subscriber = $claim_data->{ subscriber };
    my $client = $claim_data->{ client };

    my $fields = [
        # carrier address
        { x => 325, y => 742, value => $payer->{ name } }, 
        { x => 325, y => 730, value => $payer->{ address } },
        { x => 325, y => 718, value => $payer->{ address2 } },
        { x => 325, y => 706, value => $payer->{ citystatezip } },
        # line 1
        { x => 340, y => 680, value => 'X' },   #  1. Other checkbox
        { x => 378, y => 680, value => $subscriber->{ insurance_id } },         # 1a. Insured's ID
        # line 2
        { x =>  25, y => 658, value => $client->{ name } },                     # 2. Patient Name
        { x => 240, y => 655, value => $client->{ dob } },                      # 3. Patient DOB
        { x => 318, y => 655, value => ( $client->{ gender } eq 'M' ? 'X' : '' ) }, #    Patient SEX (M)
        { x => 352, y => 655, value => ( $client->{ gender } eq 'F' ? 'X' : '' ) }, #    Patient SEX (F)
        # line 3
        { x =>  25, y => 634, value => $client->{ address1 } },                 # 5. Patient Address
        # line 4
        { x =>  25, y => 611, value => $client->{ city } },                     # 5...City
        { x => 206, y => 611, value => $client->{ state } },                    # 5...State
        { x => 310, y => 611, value => ( defined $client->{ is_married } and $client->{ is_married } ? 'X' : '' ) },        # 8. Patient Status: Married
        { x => 267, y => 611, value => ( defined $client->{ is_married } and $client->{ is_married } == 0 ? 'X' : '' ) },   # 8. Patient Status: Single
        # line 5
        { x =>  25, y => 584, value => $client->{ zip } },                      # 5...Post Code
        { x => 125, y => 584, value => $client->{ phone } },
        # line 8
        { x => 378, y => 511, value => $subscriber->{ employer_or_school_name } },    # 11b. Employer/School
        { x => 378, y => 487, value => $subscriber->{ insurance_name } },             # 11c. Insurance Plan
        # line 11
        { x =>  65, y => 416, value => "Signature On File" },                   # 12. Patient Signature
        # line 15
        { x =>  38, y => 317, value => $client->{ diagnosis_codes }[0] },       # 21 - 1 ICD 9 DX 1 (Diagnosis)
        { x =>  38, y => 295, value => $client->{ diagnosis_codes }[1] },       # 21 - 2 ICD 9 DX 1 (Diagnosis) 
        { x => 233, y => 317, value => $client->{ diagnosis_codes }[2] },       # 21 - 3 ICD 9 DX 1 (Diagnosis)
        { x => 233, y => 295, value => $client->{ diagnosis_codes }[3] },       # 21 - 4 ICD 9 DX 1 (Diagnosis)
        # line 16
        { x => 378, y => 295, value => $client->{ prior_auth_number } },         # 23. Prior Authorization Number
        # line 20
        { x =>  27, y =>  99, value => $billing_provider->{ employer_id } },    # 25. Federal Tax ID Number
        { x => 153, y =>  99, value => 'X' },                                   # ... Federal Tax: EIN
        { x => 186, y =>  99, value => $client->{ client_id } },                # 26. Patient Account Nr.
        { x => 290, y =>  99, value => 'X' },                                   # 27. Accept Assign: YES
        # line 21
        { x => 493, y =>  87, value => $billing_provider->{ contact_number } }, # 33. Billing Provider phone
        # line 22
        { x => 186, y =>  77, value => $client->{ service_facility }{ name } }, # 32. Facility Name (Program Name)
        { x => 384, y =>  77, value => $billing_provider->{ name } },           # 33. Billing Provider name 
        # line 23
        { x => 186, y =>  65, value => $client->{ service_facility }{ addr } }, # 32. Facility Addr
        { x => 384, y =>  65, value => $billing_provider->{ address1 } },       # 33. Practice Addr
        # line 24    
        { x =>  25, y =>  48, value => "Signature On File" },                   # 31. Physician Signature
        { x => 125, y =>  48, value => $self->get_sigdate_f( $self->date_stamp ) },  # 31. Date
        { x => 186, y =>  53, value => $client->{ service_facility }{ citystatezip } },   # 32. Facility City, State Zip
        { x => 384, y =>  53, value => $billing_provider->{ citystatezip } },   # 33. Practice City, State Zip
        # line 25 
        { x => 384, y =>  38, value => $billing_provider->{ national_provider_id } }, # 33a. National Provider ID
        # TODO assume we don't need the non-NPI ID?
    ];

    my $relationship = $subscriber->{ client_relation_to_subscriber };
    if( $self->client_is_self( $relationship ) ) { 
        push @$fields => { x => 252, y => 632, value => 'X' };               # 6. Patient Relation: Self
    } 
    else {

        # line 3
        push @$fields => { x => 288, y => 632, value => $self->client_is_spouse( $relationship ) ? 'X' : '' };          # 6. Patient Relation: Spouse
        push @$fields => { x => 318, y => 632, value => $self->client_is_child( $relationship )  ? 'X' : '' };           # 6. Patient Relation: Child
        push @$fields => { x => 354, y => 632, value => ( $self->client_is_spouse( $relationship ) or $self->client_is_child( $relationship ) ? '' : 'X' ) };  # 6. Patient Relation: Other
        
        push @$fields => { x => 378, y => 658, value => $subscriber->{ name } };        # 4. Insured's Name
        push @$fields => { x => 378, y => 634, value => $subscriber->{ address1 } };    # 7. Insured Address
        # line 4
        push @$fields => { x => 378, y => 611, value => $subscriber->{ city } };        # 7...City 
        push @$fields => { x => 550, y => 611, value => $subscriber->{ state } };       # 7...State
        # line 5
        push @$fields => { x => 378, y => 584, value => $subscriber->{ zip } };         # 7...Post Code
        push @$fields => { x => 479, y => 584, value => $subscriber->{ phone } };
        # line 6
        push @$fields => { x => 378, y => 560, value => $subscriber->{ group_number } };  # 11. Insured Group/Policy
        
        # line 7
        push @$fields => { x => 399, y => 534, value => $subscriber->{ dob } };         # 11a. Insured DOB
        push @$fields => { x => 507, y => 534, value => ( $subscriber->{ gender } eq 'M' ? 'X' : '' ) };        # 11a. Insured Sex: M
        push @$fields => { x => 557, y => 534, value => ( $subscriber->{ gender } eq 'F' ? 'X' : '' ) };      # 11a. Insured Sex: F
    }

    my $other_insurance = $client->{ other_insurance };
    if( $other_insurance ){
        
        # line 6
        push @$fields => { x =>  25, y => 560, value => $other_insurance->{ subscriber_name } };    # 9. Other Insured
        # line 7
        push @$fields => { x =>  25, y => 536, value => $other_insurance->{ group_number } };       # 9a. Other Group
        # line 8
        push @$fields => { x =>  30, y => 511, value => $other_insurance->{ subscriber_dob } };     # 9b. Other DOB
        push @$fields => { x => 145, y => 511, value => ( $other_insurance->{ subscriber_gender } eq 'M' ? 'X' : '' ) }; #    Other Insured SEX (M)
        push @$fields => { x => 188, y => 511, value => ( $other_insurance->{ subscriber_gender } eq 'F' ? 'X' : '' ) }; #    Other Insured SEX (F)
        # line 9
        push @$fields => { x =>  27, y => 487, value => $other_insurance->{ employer_or_school_name } };  # 9c. Employer or School
        # line 10
        push @$fields => { x =>  27, y => 463, value => $other_insurance->{ insurance_name } };     # 9d. Insurance Plan
        push @$fields => { x => 387, y => 463, value => 'X' };                                      # 11d. Other Plan: YES
        # line 11
        push @$fields => { x => 420, y => 416, value => 'Signature on File' };                      # 13. Insured Signature
    }
    else {
        # line 9
        push @$fields => { x => 427, y => 462, value => 'X' };                                      # 11d. Other Plan: NO
    }

    # line 14..19
    my( $total_charged, $total_paid ) = ( 0, 0 );
    my $y = 245;
    for my $service_line ( @{ $client->{ service_lines } } ) {

        $total_charged += $service_line->{ charge_amount };
        $total_paid += $service_line->{ paid_amount } if $service_line->{ paid_amount };
        $total_paid += $subscriber->{ co_pay_amount } if $subscriber->{ co_pay_amount };
        my $charge_amount = $service_line->{ charge_amount };
        $charge_amount = eleMentalClinic::Financial::HCFA->format_dollars( $charge_amount );

        push @$fields => { x =>  25, y => $y, value => $service_line->{ start_date } }; # 24 A. Service Date From
        push @$fields => { x =>  90, y => $y, value => $service_line->{ end_date } };   # 24 A. Service Date To
        push @$fields => { x => 152, y => $y, value => $service_line->{ facility_code } };  # 24 B. Place Of Service Code
        push @$fields => { x => 174, y => $y, value => $service_line->{ emergency } };    # 24 C. Emergency
        push @$fields => { x => 204, y => $y, value => $service_line->{ service } };      # 24 D. CPT/HCPCS
        push @$fields => { x => 248, y => $y, value => $service_line->{ modifiers }[0] } if $service_line->{ modifiers };  # 24 D. MOD (1)
        push @$fields => { x => 273, y => $y, value => $service_line->{ modifiers }[1] } if $service_line->{ modifiers };  # 24 D. MOD (2)
        push @$fields => { x => 295, y => $y, value => $service_line->{ modifiers }[2] } if $service_line->{ modifiers };  # 24 D. MOD (1)
        push @$fields => { x => 314, y => $y, value => $service_line->{ modifiers }[3] } if $service_line->{ modifiers };  # 24 D. MOD (2)
        push @$fields => { x => 338, y => $y, value => $service_line->{ diagnosis_code_pointers }[0] } if $service_line->{ diagnosis_code_pointers };   # 24 E. Diagnosis Pointer
        push @$fields => { x => 435, y => $y, value => $charge_amount, align => 'right' };                # 24 F. Charges
        push @$fields => { x => 445, y => $y, value => $service_line->{ units } };      # 24 G. Units/Days

#        push @$fields => { x => 483, y => $y+12, value => $claim_data->{ rendering_provider }{ } };                    # 24 I. ID Qual 
#        push @$fields => { x => 483, 502, $y+12, value => $claim_data->{ rendering_provider }{ medicaid_provider_number } };    # 24 J. Rendering Provider Non-NPI ID 
        push @$fields => { x => 507, y => $y, value => $claim_data->{ rendering_provider }{ national_provider_id } };   # 24 J. Rendering Provider NPI 

        $y -= 24;
    }

    my $balance_due = $total_charged - $total_paid;
    $balance_due = eleMentalClinic::Financial::HCFA->format_dollars( $balance_due );
    $total_charged = eleMentalClinic::Financial::HCFA->format_dollars( $total_charged );
    $total_paid = eleMentalClinic::Financial::HCFA->format_dollars( $total_paid );
    push @$fields => { x => 450, y =>  99, value => $total_charged, align => 'right' };   # 28. Total Charges $self->amount_charged( $dept_id ) 
    push @$fields => { x => 523, y =>  99, value => $total_paid, align => 'right' };      # 29. Amount Paid
    push @$fields => { x => 588, y =>  99, value => $balance_due, align => 'right' };     # 30. Balance Due  # not in edi 
    
    # :MC: unused fields follow. {{{
    
  # line 1
# PDF::Reuse::prText( 25, 676, "$param->{sbr_medicare}");    # 1. Medicare
# PDF::Reuse::prText( 75, 676, "$param->{sbr_medicaid}");    #    Medicaid
# PDF::Reuse::prText(127, 676, "$param->{sbr_champus}");     #    Champus
# PDF::Reuse::prText(190, 676, "$param->{sbr_champva}");     #    Champva
# PDF::Reuse::prText(240, 676, "$param->{sbr_group_bc}");    #    Group Blue Cross
# PDF::Reuse::prText(298, 676, "$param->{sbr_feca}");        #    FECA

# line 4
# PDF::Reuse::prText( 354, 603, 'X' );     # 8. Patient Status: Other

  # line 5
# PDF::Reuse::prText(268, 581, "$param->{pat_employed}");    # 8. Patient Status: Employed
# PDF::Reuse::prText(312, 581, "$param->{pat_full_time}");   # 8. Patient Status: FT Student
# PDF::Reuse::prText(356, 581, "$param->{pat_part_time}");   # 8. Patient Status: PT Student

  # line 6
# PDF::Reuse::prText(268, 534, "$param->{clm_work_yes}");    # 10a. Condition Employment: YES
# PDF::Reuse::prText(312, 534, "$param->{clm_work_no}");     # 10a. Condition Employment: NO
  
  # line 7
# PDF::Reuse::prText(268, 509, "$param->{clm_auto_yes}");    # 10b. Condition Auto: YES
# PDF::Reuse::prText(312, 509, "$param->{clm_auto_no}");     # 10b. Condition Auto: NO
# PDF::Reuse::prText(345, 512, "$param->{clm_state}");       # 10b. Auto State
  
    # line 8
# PDF::Reuse::prText(268, 485, "$param->{clm_other_yes}");   # 10c. Condition Other: YES
# PDF::Reuse::prText(312, 485, "$param->{clm_other_no}");    # 10c. Condition Other: NO
  
  # line 11
# PDF::Reuse::prText( 34, 389, "$param->{dtp_431_date}");    # 14. Current Onset
# PDF::Reuse::prText(287, 389, "$param->{dtp_438_date}");    # 15. Similar Date
# PDF::Reuse::prText(408, 389, "$param->{dtp_297_date}");    # 16. Out Of Work
# PDF::Reuse::prText(510, 389, "$param->{dtp_296_date}");    # 16. Back To Work
  
  # line 12
# PDF::Reuse::prText( 27, 368, "$param->{nm1_dn_ref_md}");   # 17. Referring MD
# PDF::Reuse::prText(224, 368, "$param->{nm1_dn_ref_id}");   # 17a. Referring ID
# PDF::Reuse::prText(408, 365, "$param->{dtp_435_date}");    # 18. Admission Date
# PDF::Reuse::prText(510, 365, "$param->{dtp_096_date}");    # 18. Discharge Date
  
  # line 13
# PDF::Reuse::prText(390, 343, "$param->{outside_lab_yes}"); # 20. Outside Lab (YES)
# PDF::Reuse::prText(427, 343, "$param->{outside_lab_no}");  # 20. Outside Lab (NO)
# PDF::Reuse::prText(465, 343, "$param->{outside_fee}");     # ... Outside Lab Fee
# PDF::Reuse::prText(535, 343, "}");                         # ... Outside Lab Fee
# PDF::Reuse::prText(241, 318, "$param->{hi_bf_dx2}");       # 21 - 3 ICD 9 DX 3
# PDF::Reuse::prText(378, 318, "$param->{medicaid_resubmit}");  # 22. Medicaid Resubmit
# PDF::Reuse::prText(462, 318, "$param->{medicaid_ref_nr}"); # 22. Original Ref. Nr.
# PDF::Reuse::prText( 43, 295, "$param->{hi_bf_dx3}");       # 21 - 2 ICD 9 DX 2
# PDF::Reuse::prText(241, 295, "$param->{hi_bf_dx4}");       # 21 - 4 ICD 9 DX 4
  
  # line 14..19
# PDF::Reuse::prText(468, $y[$i], $param->{'clm_epsdt_'.$j});     # 24-$j H. EPSDT
# PDF::Reuse::prText(490, $y[$i], $param->{'sv1_emer_'.$j});      # 24-$j I. EMG
# PDF::Reuse::prText(510, $y[$i], $param->{'sv1_cob_'.$j});       # 24-$j J. COB

  # line 20
# PDF::Reuse::prText(140, 103, "$param->{ssn}");             # ... Federal Tax: SSN
# PDF::Reuse::prText(327, 102, "$param->{assign_no}");       # 27. Accept Assign: NO

  # line 24
# PDF::Reuse::prText(504, 44,  "$param->{nm1_85_id}");       # ... GRP Number
    # }}}

    return $self->pdf->write_pdf( $fields );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 format_dollars( $amount )

Class method. Adds zeros for cents, replaces decimal with space.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub format_dollars {
    my $class = shift;
    my( $amount ) = @_;
    return unless $amount;

    $amount = sprintf( "%.2f", $amount );
    $amount =~ s/\./ /g;
    return $amount;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_date_f( $date )

Class method.

Formatting for HCFAs

Takes a date in the format "CCYY-MM-DD" and returns it 
in the format "MM  DD  CCYY"

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_date_f {
    my $class = shift;
    my( $date ) = @_;
    
    return unless $date and $date =~ /(\d{4})-(\d\d?)-(\d{2})/;

    return sprintf( "%02d  %02d  %04d", $2, $3, $1 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_shortdate_f( $date )

Class method.

Formatting for HCFAs

Takes a date in the format "CCYY-MM-DD" and returns it 
in the format "MM DD YY"

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_shortdate_f {
    my $class = shift;
    my( $date ) = @_;
    
    return unless $date and $date =~ /(\d{2})(\d{2})-(\d\d?)-(\d{2})/;

    return sprintf( "%02d  %02d  %02d", $3, $4, $2 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_sigdate_f( $date )

Class method.

Formatting for HCFAs

Takes a date in the format "CCYYMMDD" and returns it 
in the format "MM/DD/YY"

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_sigdate_f {
    my $class = shift;
    my( $date ) = @_;

    return unless $date and $date =~ /(\d{2})(\d{2})(\d{2})(\d{2})/;

    $date =~ s/^(\d{2})(\d{2})(\d{2})(\d{2})$/$3\/$4\/$2/;
    return $date;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_name_f( $person )

Class method.

Send in a hashref with keys: lname, fname, and optionally mname
and name_suffix, and a formatted string ("Smith Jr., Fred, Q")
will be returned.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_name_f {
    my $class = shift;
    my( $person ) = @_;

    return unless $person;

    my $name = $person->{ lname };
    $name .= " $person->{ name_suffix }" if $person->{ name_suffix };
    $name .= ", $person->{ fname }" if $person->{ fname };
    $name .= sprintf( ", %.1s", $person->{ mname } ) if $person->{ mname };

    # remove periods from the name
    $name =~ s/\.//g;

    return $name;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_addr_f( $address )

Class method.

Strips out the commas, periods, and #'s in the address.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_addr_f {
    my $class = shift;
    my( $address ) = @_;

    return unless $address;
    $address =~ s/[,\.#]//g;

    return $address;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_phone_f( $phone )

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_phone_f {
    my $class = shift;
    my( $phone ) = @_;

    return unless $phone;
    $phone =~ s/-//g;

    return $phone;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 client_is_self( $relationship )

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub client_is_self {
    my $class = shift;
    my( $relationship ) = @_; 
    return '1' unless $relationship;
    
    return grep /^$relationship$/ => qw/ 00 /;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 client_is_spouse( $relationship )

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub client_is_spouse {
    my $class = shift;
    my( $relationship ) = @_; 
    return unless $relationship;

    return grep /^$relationship$/ => qw/ 01 /;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 client_is_child( $relationship )

Class method.

Values used to determine: Child = 19, Adopted Child = 09, Foster Child = 10, Stepson/Stepdaughter = 17

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub client_is_child {
    my $class = shift;
    my( $relationship ) = @_; 
    return unless $relationship;

    return grep /^$relationship$/ => qw/ 19 09 10 17 /;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 is_married( $status )

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub is_married {
    my $class = shift;
    my( $status ) = @_;

    my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
    $valid_data = $valid_data->get_byname( '_marital_status', $status );
    return unless $valid_data;

    return $valid_data->{ is_married };
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Martin Chase

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
