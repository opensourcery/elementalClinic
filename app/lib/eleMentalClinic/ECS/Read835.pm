package eleMentalClinic::ECS::Read835;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::ECS::Read835

=head1 SYNOPSIS

Reads and parses an EDI file in 837 format.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base /;
use Data::Dumper;
use X12::Parser;
use YAML::Syck qw/ LoadFile /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub methods {
        [ qw/ parser file config_file yaml_file edi_data composite_delimiter / ]
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    
    $self->parser( X12::Parser->new );
 
    $self->config_file( $self->config->ecs835_cf_file );
    $self->yaml_file( $self->config->ecs835_yaml_file );

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 valid_file( $file )

Object method. Quick rough check to see if this file can even be parsed as an 835.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub valid_file {
    my $self = shift;
    my( $file ) = @_;

    die 'File is required' unless $file;

    open( EDIFILE, $file ) or die "Cannot open file $file\n";
    my $edi = do { local $/; <EDIFILE> };
    close EDIFILE;

    return 1 if $edi =~ /ISA.*GS.*004010X091.*ST.835/s;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 parse

Object method. Parse a file with the transaction specific configuration file.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub parse {
    my $self = shift;

    die "Object's file and config_file are required" unless $self->file and $self->config_file;

    eval { $self->parser->parsefile( file => $self->file, conf => $self->config_file ); };
    #warn $self->parser->print_tree;
    return 1 unless $@;

    warn $@;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _load_yaml {
    my $self = shift;

    return unless $self->yaml_file;

    my( $yaml_hashref ) = LoadFile( $self->yaml_file );

    return $yaml_hashref;
}    
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_raw_edi {
    my $self = shift;

    my $file = $self->file;
    return unless $file;

    open( EDIFILE, $file ) or die "Cannot open file $file\n";
    my $edi = do { local $/; <EDIFILE> };
    close EDIFILE;

    return $edi;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_edi_data

Object method. Uses the self's X12::Parser to loop through the 835, line
by line, building a custom hash data structure that is stored in
self->edi_data.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# TODO refactor
sub get_edi_data {
    my $self = shift;
    
    die "Object's file, config_file, and yaml_file are required" unless $self->file and $self->config_file and $self->yaml_file;
    
    # 0.8 fixed some spelling, but broke backwords compatibility.
    my $method = $self->parser->can('get_element_seperator') ? 'get_element_seperator' : 'get_element_separator';

    my $elem_sep = $self->parser->$method;

    die 'Unable to find the element separator in the 835' unless $elem_sep;
    
    my $yaml_hashref = $self->_load_yaml;
    my $edi_data;

    my( $level_one_loop_name, $level_two_loop_name, $level_three_loop_name );
    my( $cur_level_one_loop, $cur_level_two_loop, $cur_level_three_loop ) = ( -1, -1, -1 ); 
         
    my( $level_one_ref, $level_two_ref, $level_three_ref );
    
    # get next loop
    while ( my( $pos, $level, $loop ) = $self->parser->get_next_pos_level_loop ) {
        if ( $level != 0 ) {
            my @loop = $self->parser->get_loop_segments;

            my $loop_name = $yaml_hashref->{ loop_name }{ $loop };
            
            # get each segment in the loop
            foreach my $segment (@loop) {
            
                my @elements = split /\*/, $segment;

                my $seg_id = $elements[0];
                # Note: I used hashes instead of arrays for the segment elements 
                # so it is easier to read which number a specific item is in (in the YAML file)
                my $seg_name = $yaml_hashref->{ $loop }{ $seg_id }{ 0 };
                die 'Error parsing 835: unable to find the segment name' unless $seg_name;
                
                my $i = 0;
                my %elements;
                for( @elements ){
                    my $tag = $yaml_hashref->{ $loop }{ $seg_id }{ $i };
                    $elements{ $tag } = $elements[ $i ] if $tag;
                    $i++;
                }

                my $qualifier = $elements[1];
                my $qual_flag = $yaml_hashref->{ $loop }{ $seg_id }{ 1 };
                my $use_qualifier = ( $qual_flag and $qual_flag eq 'qualifier' ) ? 1 : 0;
                my $qual_value = $qualifier ? $yaml_hashref->{ $loop }{ $seg_id }{ $qualifier } : '';
           
                if( $loop ) {
                    # $self->_simple_level_one_loops
                    if( $loop =~ /^ISA|GS|SE|GE|IEA$/ ) {
                        $edi_data->{ $loop_name } = \%elements;
                    }
                    # $self->simple_level_one_repeat_loops
                    elsif( $loop =~ /^PLB$/ ) {
                        push @{ $edi_data->{ $loop_name } } => \%elements;
                    }
                    # $self->_level_one_loops
                    elsif( $loop =~ /^ST|1000A|1000B$/ ) {
                        $level_one_loop_name = $loop_name;
                        if( $use_qualifier ){
                            $edi_data->{ $loop_name }{ $seg_name }{ $qual_value } = \%elements;
                        } else {
                            $edi_data->{ $loop_name }{ $seg_name } = \%elements;
                        }
                    }
                    # $self->_level_one_repeat_loops 
                    elsif( $loop =~ /^2000$/ ) {
                        if( $seg_id eq 'LX' ){
                            $cur_level_one_loop++;
                            $level_one_loop_name = $loop_name;
                            $level_two_loop_name = undef;
                            $cur_level_two_loop = -1;
                            $level_three_loop_name = undef;
                            $cur_level_three_loop = -1;
                        }
#                        $level_one_ref = $edi_data->{ $loop_name }[
                        
                        if( $use_qualifier ){
                            $edi_data->{ $loop_name }[ $cur_level_one_loop ]{ $seg_name }{ $qual_value } = \%elements;
                        } else {    
                            $edi_data->{ $loop_name }[ $cur_level_one_loop ]{ $seg_name } = \%elements;
                        }
                    }
                    # $self->_level_two_repeat_loops
                    elsif( $loop =~ /^2100$/ ) {
                        if( $seg_id eq 'CLP' ){
                            $cur_level_two_loop++;
                            $level_two_loop_name = $loop_name;
                            $level_three_loop_name = undef;
                            $cur_level_three_loop = -1;
                        }
                        # repeating element within the loop XXX There are other repeating elements not caught here
                        if( grep /$seg_id/ => qw/ CAS / ){

                            #warn Dumper $edi_data->{ $level_one_loop_name }[ $cur_level_one_loop ]{ $loop_name };
                            push @{ $edi_data->{ $level_one_loop_name }[ $cur_level_one_loop ]{ $loop_name }[ $cur_level_two_loop ]{ $seg_name } } => \%elements;
                        } elsif( $use_qualifier ){
                            $edi_data->{ $level_one_loop_name }[ $cur_level_one_loop ]{ $loop_name }[ $cur_level_two_loop ]{ $seg_name }{ $qual_value } = \%elements;
                        } else {
                            $edi_data->{ $level_one_loop_name }[ $cur_level_one_loop ]{ $loop_name }[ $cur_level_two_loop ]{ $seg_name } = \%elements;
                        }
                    }
                    # $self->_level_three_repeat_loops
                    elsif( $loop =~ /^2110$/ ) {
                        if( $seg_id eq 'SVC' ){
                            $cur_level_three_loop++;
                            $level_three_loop_name = $loop_name;
                        }
                        # XXX There are other repeating elements not caught here
                        if( grep /$seg_id/ => qw/ CAS LQ / ){
                            push @{ $edi_data->{ $level_one_loop_name }[ $cur_level_one_loop ]{ $level_two_loop_name }[ $cur_level_two_loop ]{ $loop_name }[ $cur_level_three_loop ]{ $seg_name } } => \%elements;
                        } elsif( $use_qualifier ){
                            $edi_data->{ $level_one_loop_name }[ $cur_level_one_loop ]{ $level_two_loop_name }[ $cur_level_two_loop ]{ $loop_name }[ $cur_level_three_loop ]{ $seg_name }{ $qual_value } = \%elements;
                        } else {
                            $edi_data->{ $level_one_loop_name }[ $cur_level_one_loop ]{ $level_two_loop_name }[ $cur_level_two_loop ]{ $loop_name }[ $cur_level_three_loop ]{ $seg_name } = \%elements;
                        }
                    }
                }
                else {
                    die "$loop is not an expected loop!";
                }
            }    
        }
    }

    $self->edi_data( $edi_data );

    $self->composite_delimiter( $edi_data->{ interchange_control_header }{ composite_delimiter } );

    return 1 if $self->get_transaction_set_identifier_code eq '835';

    warn 'This file is not a valid 835 file: [' . $self->file . ']';
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub format_ccyymmdd {
    my $self = shift;
    my( $date ) = @_;
    return unless $date and length $date == 8;
    
    $date =~ s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
   
    return $date; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods to retrieve actual data from the 835

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_sender_interchange_id {
    my $self = shift;
 
    return unless $self->edi_data;

    my $id = $self->edi_data->{ interchange_control_header }{ sender_interchange_id };
    $id =~ s/\s+$//;
    return $id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_receiver_interchange_id {
    my $self = shift;
    
    return unless $self->edi_data;

    my $id = $self->edi_data->{ interchange_control_header }{ receiver_interchange_id };
    $id =~ s/\s+$//;
    return $id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_interchange_date {
    my $self = shift;
   
    return unless $self->edi_data;

    # YYMMDD
    my $date = $self->edi_data->{ interchange_control_header }{ interchange_date };
    # warning: 2000 century assumed by the 835
    $date =~ s/^(\d{2})(\d{2})(\d{2})$/20$1-$2-$3/;
    return $date;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_interchange_time {
    my $self = shift;
   
    return unless $self->edi_data;

    my $time = $self->edi_data->{ interchange_control_header }{ interchange_time };
    $time =~ s/^(\d{2})(\d{2})$/$1:$2/;
    return $time; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_interchange_control_number {
    my $self = shift;
  
    return unless $self->edi_data;

    my $header_num = $self->edi_data->{ interchange_control_header }{ interchange_control_number };
    my $trailer_num = $self->edi_data->{ interchange_control_trailer }{ interchange_control_number };

    die "Interchange control number in the ISA header ($header_num) and IEA trailer ($trailer_num) don't match!"
        unless $header_num eq $trailer_num;

    return $header_num;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_functional_group_count {
    my $self = shift;
   
    return unless $self->edi_data;

    my $count = $self->edi_data->{ interchange_control_trailer }{ functional_group_count };
    die "Not expecting more than one functional group - GS"
        unless $count == 1;
        
    # XXX Could actually count the groups to verify that the count is correct 
    return $count;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_ack_requested {
    my $self = shift;
   
    return unless $self->edi_data;

    return $self->edi_data->{ interchange_control_header }{ interchange_ack_requested };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_production {
    my $self = shift;
  
    return unless $self->edi_data;

    my $mode = $self->edi_data->{ interchange_control_header }{ mode };

    return 1
        if $mode eq 'P';
    
    return 0; # T = testing
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_functional_identifier_code {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ functional_group_header }{ functional_identifier_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_sender_code {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ functional_group_header }{ sender_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_receiver_code {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ functional_group_header }{ receiver_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_functional_group_date {
    my $self = shift;

    return unless $self->edi_data;

    # CCYYMMDD
    my $date = $self->edi_data->{ functional_group_header }{ functional_group_date };
    
    return $self->format_ccyymmdd( $date );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_functional_group_time {
    my $self = shift;
   
    return unless $self->edi_data;

    my $time = $self->edi_data->{ functional_group_header }{ functional_group_time };
    $time =~ s/^(\d{2})(\d{2})$/$1:$2/;
    return $time; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_group_control_number {
    my $self = shift;

    return unless $self->edi_data;

    my $header_num = $self->edi_data->{ functional_group_header }{ group_control_number };
    my $trailer_num = $self->edi_data->{ functional_group_trailer }{ group_control_number };

    die "Group control number in the GS header ($header_num)  and GE trailer ($trailer_num) don't match!"
        unless $header_num eq $trailer_num;

    return $header_num;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_transaction_set_count {
    my $self = shift;
   
    return unless $self->edi_data;

    my $count = $self->edi_data->{ functional_group_trailer }{ transaction_set_count };
    die "Not expecting more than one transaction set - ST"
        unless $count == 1;
        
    # XXX Could actually count the sets to verify that the count is correct 
    return $count;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_x12_version {
    my $self = shift;

    return unless $self->edi_data;

    my $version = $self->edi_data->{ functional_group_header }{ x12_version };
    die "X12 version is $version, not 004010X091 as expected"
        unless $version eq '004010X091';

    return $version;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_transaction_set_identifier_code {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ transaction_set_header }{ transaction_set_header }{ identifier_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_transaction_set_control_number {
    my $self = shift;

    return unless $self->edi_data;

    my $header_num  = $self->edi_data->{ transaction_set_header }{ transaction_set_header }{ control_number };
    my $trailer_num = $self->edi_data->{ transaction_set_trailer }{ control_number };

    die "Transaction set control number in the ST header ($header_num) and SE trailer ($trailer_num) don't match!"
         unless $header_num eq $trailer_num;

    return $header_num;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_segment_count {
    my $self = shift;
   
    return unless $self->edi_data;

    # XXX Could actually count the segments to verify that the count is correct 
    return $self->edi_data->{ transaction_set_trailer }{ segment_count };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_transaction_handling_code {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ transaction_set_header }{ financial_info }{ transaction_handling_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_transaction_monetary_amount {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ transaction_set_header }{ financial_info }{ monetary_amount };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_credit_debit_flag_code {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ transaction_set_header }{ financial_info }{ credit_debit_flag_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_payment_method {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ transaction_set_header }{ financial_info }{ payment_method };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_paidby_check {
    my $self = shift;

    my $method = $self->get_payment_method;
    
    return 1
        if $method and $method eq 'CHK';

    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_payment_format_code {
    my $self = shift;

    return unless $self->edi_data;

    my $code = $self->edi_data->{ transaction_set_header }{ financial_info }{ payment_format_code };
    
    # return undef if the string is empty
    return $code
        if $code;
    
    return undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_payment_date {
    my $self = shift;

    return unless $self->edi_data;

    # CCYYMMDD
    my $date = $self->edi_data->{ transaction_set_header }{ financial_info }{ payment_date };
    
    return $self->format_ccyymmdd( $date );
}
 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_payment_trace_type {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ transaction_set_header }{ trace_number }{ trace_type };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_check_number {
    my $self = shift;

    return unless $self->edi_data;
    return unless $self->is_paidby_check;

    return $self->edi_data->{ transaction_set_header }{ trace_number }{ payment_number };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_originating_company_id {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ transaction_set_header }{ trace_number }{ originating_company_id };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_originating_company_supplemental_code {
    my $self = shift;

    return unless $self->edi_data;

    my $code = $self->edi_data->{ transaction_set_header }{ trace_number }{ originating_company_supplemental_code };
    
    # return undef if the string is empty
    return $code
        if $code;
    
    return undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Should be empty - this is only used for when the receiver is not the payee
sub get_receiver_id {
    my $self = shift;

    return unless $self->edi_data;

    my $id = $self->edi_data->{ transaction_set_header }{ REF }{ receiver_id }{ id };

    # return undef if the string is empty
    return $id
        if $id;
    
    return undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_system_version {
    my $self = shift;

    return unless $self->edi_data;

    return $self->edi_data->{ transaction_set_header }{ REF }{ version_id }{ id };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_production_cycle_end_date {
    my $self = shift;

    return unless $self->edi_data;

    my $date = $self->edi_data->{ transaction_set_header }{ production_date }{ production_cycle_end_date }{ date };
    
    return $self->format_ccyymmdd( $date );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_payer_name {
    my $self = shift;

    return unless $self->edi_data;
    return
        unless $self->edi_data->{ payer }{ identification }{ name_qualifier } eq 'PR';

    return $self->edi_data->{ payer }{ identification }{ name };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_payer_address {
    my $self = shift;

    return unless $self->edi_data;

    my %address;
    my $payer = $self->edi_data->{ payer };
    $address{ addr_1 }  = $payer->{ address }{ addr_1 };
    $address{ addr_2 }  = $payer->{ address }{ addr_2 };
    $address{ city }    = $payer->{ city_state_zip }{ city };
    $address{ state }   = $payer->{ city_state_zip }{ state };
    $address{ zip }     = $payer->{ city_state_zip }{ zip };

    return \%address;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_payer_contact {
    my $self = shift;
    
    return unless $self->edi_data;
    return undef
        unless $self->edi_data->{ payer }{ payer_contact }{ contact_function_code } eq 'CX';

    my %contact;
    $contact{ name } = $self->edi_data->{ payer }{ payer_contact }{ name };

    for( 1 .. 3 ){
       
        my $qualifier =  $self->edi_data->{ payer }{ payer_contact }{ 'number_' . $_ . '_qualifier' };
        my $value     =  $self->edi_data->{ payer }{ payer_contact }{ 'number_' . $_ };
        
        next unless $qualifier and $value;       

        if( $qualifier eq 'TE' ){
            # XXX The phone number could be formatted for better display in the UI
            $contact{ phone } = $value;
        } elsif( $qualifier eq 'EM' ){
            $contact{ email } = $value;
        } elsif( $qualifier eq 'EX' ){
            $contact{ extension } = $value;
        } elsif( $qualifier eq 'FX' ){
            $contact{ fax } = $value;
        }
    }

    return \%contact;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_provider_name {
    my $self = shift;

    return unless $self->edi_data;
    return undef
        unless $self->edi_data->{ provider }{ identification }{ name_qualifier } eq 'PE';

    return $self->edi_data->{ provider }{ identification }{ name };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_provider_NPI {
    my $self = shift;

    return unless $self->edi_data;
    return undef
        unless $self->edi_data->{ provider }{ identification }{ code_qualifier } eq 'XX';
    
    return $self->edi_data->{ provider }{ identification }{ code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_provider_address {
    my $self = shift;

    return unless $self->edi_data;

    my %address;
    my $provider = $self->edi_data->{ provider };
    $address{ addr_1 }  = $provider->{ address }{ addr_1 };
    $address{ addr_2 }  = $provider->{ address }{ addr_2 };
    $address{ city }    = $provider->{ city_state_zip }{ city };
    $address{ state }   = $provider->{ city_state_zip }{ state };
    $address{ zip }     = $provider->{ city_state_zip }{ zip };

    return \%address;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_provider_tax_id {
    my $self = shift;

    return unless $self->edi_data;

    # try the REF segment first    
    # XXX The REF segment can be repeated - handle that!
    my $qualifier = $self->edi_data->{ provider }{ additional_id }{ reference_id_qualifier };

    return $self->edi_data->{ provider }{ additional_id }{ id }
        if $qualifier eq 'TJ';

    # then try the N1 segment
    $qualifier = $self->edi_data->{ provider }{ identification }{ code_qualifier }; 

    return $self->edi_data->{ provider }{ identification }{ code }
        if $qualifier eq 'FI';
    
    return undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_claim_headers {
    my $self = shift;

    return unless $self->edi_data;

    my @claim_headers;

    for my $header_data ( @{ $self->edi_data->{ claim_header } } ){
        
        my %header;
        # XXX There are other fields here that are not getting pulled out, but I don't think we need them 
        $header{ header_number } = $header_data->{ header_number }{ assigned_number };

        for( qw/ provider_id facility_code total_claim_count total_claim_charge_amount 
                 total_covered_charge_amount total_noncovered_charge_amount total_denied_charge_amount
                 total_provider_payment_amount total_interest_amount total_contractual_adjustment_amount / ){
            $header{ $_ } = $header_data->{ provider_summary_info }{ $_ } || undef;
        }
        
        $header{ fiscal_period_date } = $self->format_ccyymmdd( $header_data->{ provider_summary_info }{ fiscal_period_date } );

        my $claims_data = $header_data->{ claims };
        @{ $header{ claim_ids } } =  map { $_->{ claim_payment_info }{ id } } @$claims_data; 

        push @claim_headers => \%header;
    }

    return \@claim_headers;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_claims {
    my $self = shift;

    return unless $self->edi_data;

    my @claims;

    for my $header_data ( @{ $self->edi_data->{ claim_header } } ){
        
        for my $claim_data ( @{ $header_data->{ claims } } ){

            push @claims => $self->get_claim( $claim_data, $header_data->{ header_number }{ assigned_number } );
        }
    }

    return \@claims;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_claim {
    my $self = shift;
    my( $claim_data, $header_id ) = @_;
    my %claim;
    
    return unless $claim_data;

    # XXX Not getting this data, but it doesn't appear necessary: 
    # Service Provider Name (Rendering Provider), Crossover Carrier Name 

    my $payment_info    = $self->get_claim_payment_info( $claim_data );
    my $ref_ids         = $self->get_qualified_info( $claim_data, 'reference_ids', 'id' );
    my $dates           = $self->get_dates( $claim_data, 'claim' );
    my $supp_info       = $self->get_qualified_info( $claim_data, 'claim_supplemental_info', 'amount' );
    my $supp_qty        = $self->get_qualified_info( $claim_data, 'claim_supplemental_info_quantity', 'quantity' );

    %claim = ( %claim, %$payment_info ) if $payment_info;
    %claim = ( %claim, %$ref_ids )      if $ref_ids;
    %claim = ( %claim, %$dates )        if $dates;
    %claim = ( %claim, %$supp_info )    if $supp_info;
    %claim = ( %claim, %$supp_qty )     if $supp_qty;

    # warn if there is a collision of the hash keys
    die "Claim hash keys collision when building up the claim data" unless scalar( keys %claim ) == 
        scalar( keys %$payment_info ) + 
        scalar( keys %$ref_ids ) + 
        scalar( keys %$dates ) + 
        scalar( keys %$supp_info ) +
        scalar( keys %$supp_qty );

    $claim{ deductions }       = $self->get_deductions( $claim_data, 'claim' ); 
    $claim{ patient }           = $self->get_claim_person( $claim_data, 'patient' );
    $claim{ subscriber }        = $self->get_claim_person( $claim_data, 'subscriber' );
    $claim{ corrected_patient } = $self->get_claim_person( $claim_data, 'corrected_insured_name' );
    $claim{ corrected_payer }   = $self->get_priority_payer( $claim_data );
    $claim{ inpatient_adjudication_info }  = $self->get_adjudication_info( $claim_data, 'inpatient' );
    $claim{ outpatient_adjudication_info } = $self->get_adjudication_info( $claim_data, 'outpatient' );
    $claim{ claim_contact }     = $self->get_claim_contact( $claim_data );
    $claim{ service_lines }     = $self->get_service_lines( $claim_data );
    $claim{ claim_header_id }   = $header_id;
    
    return \%claim;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_claim_payment_info {
    my $self = shift;
    my( $claim_data ) = @_;

    return unless $claim_data;

    my @payment_keys = qw/ id status_code total_charge_amount payment_amount 
                            patient_responsibility_amount claim_filing_indicator_code 
                            payer_claim_control_number facility_code /;
    my %claim_payment = map { $_ => $claim_data->{ claim_payment_info }{ $_ } || undef } @payment_keys;
    
    return \%claim_payment;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_deductions( $data, $type )

Object method. The 835 spec calls these adjustments: the amount that a payer will not pay. 
To avoid confusion with eMC's Medicaid Adjustment, we're calling them deductions.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_deductions {
    my $self = shift;
    my( $data, $type ) = @_;
    my @deductions;

    return unless $data;
    return unless $type and $type eq 'claim' or $type eq 'service';

    # CAS segments can be repeated
    for my $adjustment_data ( @{ $data->{ "${type}_adjustment" } } ){

        # the single line of a CAS segment can contain several reason codes & adjustment amounts
        for( 1 .. 6 ){
            
            my $code = $adjustment_data->{ "reason_$_" };
            next unless $code;

            my %deduction;
            $deduction{ reason_code } = $code;

            # XXX Refactor: I don't think this lookup for reason_text needs to be here.
            # Rather it should be later when the text is displayed in the UI.
            my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
            $valid_data = $valid_data->get_byname( '_claim_adjustment_codes', $deduction{ reason_code } );
            $deduction{ reason_text } = $valid_data->{ description } if $valid_data;

            $deduction{ deduction_amount } = $adjustment_data->{ "adjustment_amount_$_" } || undef;
            $deduction{ deduction_quantity } = $adjustment_data->{ "adjustment_quantity_$_" } || undef;
        
            # this is only specified once per CAS segment, but we'll add it to each group of reasons
            $deduction{ group_code } = $adjustment_data->{ group_code }; 
            push @deductions => \%deduction;
        }
    }
    
    return \@deductions;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_claim_person {
    my $self = shift;
    my( $claim_data, $role ) = @_;

    return unless $claim_data;
    return undef
        unless $role and $role eq 'patient' or $role eq 'subscriber';

    # make sure this data refers to a person, not an organization
    my $type_qualifier = $claim_data->{ name }{ $role }{ entity_type_qualifier };
    return undef
        unless $type_qualifier and $type_qualifier == 1;

    my @name_keys = qw/ lname fname mname name_suffix /;
    my %claim_person = map { $_ => $claim_data->{ name }{ $role }{ $_ } || undef } @name_keys;
   
    my %id_qualifiers = ( 
        'HN' => 'health_insurance_claim_number',
        '34' => 'ssn',
        'MI' => 'member_id_number',
        'MR' => 'medicaid_recipient_id_number',
        'C'  => 'changed_id_number',
    );

    my $id_qualifier = $claim_data->{ name }{ $role }{ id_code_qualifier };
    $claim_person{ $id_qualifiers{ $id_qualifier } } = $claim_data->{ name }{ $role }{ id_code }
        if $id_qualifier;
 
    return \%claim_person;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_priority_payer {
    my $self = shift;
    my( $claim_data ) = @_;

    return unless $claim_data;

    # make sure this data refers to an organization, not a person
    my $type_qualifier = $claim_data->{ name }{ corrected_priority_payer }{ entity_type_qualifier };
    return undef
        unless $type_qualifier and $type_qualifier == 2;

    my %priority_payer;
    $priority_payer{ name } = $claim_data->{ name }{ corrected_priority_payer }{ lname } || undef;
   
    my %id_qualifiers = ( 
        FI => 'tax_id',
        NI => 'NAIC_id',
        PI => 'payor_id',
        XV => 'HCFA_national_plan_id',
    );

    my $id_qualifier = $claim_data->{ name }{ corrected_priority_payer }{ id_code_qualifier };
    $priority_payer{ $id_qualifiers{ $id_qualifier } } = $claim_data->{ name }{ corrected_priority_payer }{ id_code }
        if $id_qualifier;
 
    return \%priority_payer;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_adjudication_info {
    my $self = shift;
    my( $claim_data, $type ) = @_;

    return unless $claim_data;
    return undef
        unless $type and $type eq 'inpatient' or $type eq 'outpatient';

    my @inpatient_keys = qw/ PPS_operating_outlier_amount lifetime_psychiatric_days_count claim_DRG_amount 
                             claim_disproportionate_share_amount claim_MSP_pass_through_amount 
                             claim_PPS_capital_amount PPS_capital_FSP_DRG_amount PPS_capital_HSP_DRG_amount 
                             PPS_capital_DSH_DRG_amount old_capital_amount PPS_capital_IME_amount 
                             PPS_operating_hospital_specific_DRG_amount cost_report_day_count 
                             PPS_operating_federal_specific_DRG_amount claim_PPS_capital_outlier_amount 
                             claim_indirect_teaching_amount nonpayable_professional_component_amount
                             PPS_capital_exception_amount /;

    my @outpatient_keys = qw/ reimbursement_rate claim_HCPCS_payable_amount
                              claim_ESRD_payment_amount nonpayable_professional_component_amount  /;

    my $keys = $type eq 'inpatient' ? \@inpatient_keys : \@outpatient_keys;

    my %info = map { $_ => $claim_data->{ "${type}_adjudication_info" }{ $_ } || undef } @$keys;

    my @remarks;
    for( 1 .. 5 ){
    
        my $code = $claim_data->{ "${type}_adjudication_info" }{ "remark_code_$_" };
        next unless $code;

        my %remark;
        $remark{ code } = $code;
        
        # XXX Refactor: I don't think this lookup for text needs to be here.
        # Rather it should be later when the text is displayed in the UI.
        my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
        $valid_data = $valid_data->get_byname( '_remittance_remark_codes', $remark{ code } );
        $remark{ text } = $valid_data->{ description } if $valid_data;
        
        push @remarks => \%remark;
    }
    $info{ remarks } = \@remarks;

    return \%info;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# used for the claim or service line's REF, AMT, QTY segments
sub get_qualified_info {
    my $self = shift;
    my( $data, $name, $field_name ) = @_;
    my %info;

    return unless $data;

    # these segments can be repeated
    for my $info_key ( keys %{ $data->{ $name } } ){

        $info{ $info_key } = $data->{ $name }{ $info_key }{ $field_name };
    }
 
    return \%info;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_dates {
    my $self = shift;
    my( $data, $type ) = @_;
    my %dates;

    return unless $data;
    return unless $type and $type eq 'claim' or $type eq 'service';

    # DTM segments can be repeated
    for my $date_key ( keys %{ $data->{ "${type}_dates" } } ){

        $dates{ $date_key } = $self->format_ccyymmdd( $data->{ "${type}_dates" }{ $date_key }{ date } );
    }
 
    return \%dates;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_claim_contact {
    my $self = shift;
    my( $claim_data ) = @_;
    my %contact;

    return unless $claim_data;

    my $function_code = $claim_data->{ claim_contact }{ contact_function_code };
    return unless $function_code and $function_code eq 'CX';

    $contact{ name } = $claim_data->{ claim_contact }{ name }
        if $claim_data->{ claim_contact }{ name };

    my %number_names = (
        EM => 'email',
        FX => 'fax',
        TE => 'phone',
        EX => 'phone_ext',
    );
    
    for( 1 .. 3 ){
        
        my $qualifier = $claim_data->{ claim_contact }{ "number_${_}_qualifier" };
        last unless $qualifier;        
    
        $contact{ $number_names{ $qualifier } } = $claim_data->{ claim_contact }{ "number_$_" } || undef;
    }

    return \%contact;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_service_lines {
    my $self = shift;
    my( $claim_data ) = @_;
    my @service_lines;

    return unless $claim_data;

    for my $service_data ( @{ $claim_data->{ service_lines } } ){
        push @service_lines => $self->get_service_line( $service_data );
    }

    return \@service_lines;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_service_line {
    my $self = shift;
    my( $service_data ) = @_; 
    my %service_line;

    return unless $service_data;

    my $dates       = $self->get_dates( $service_data, 'service' );
    my $ref_ids     = $self->get_qualified_info( $service_data, 'reference_ids', 'id' );
    my $supp_info   = $self->get_qualified_info( $service_data, 'service_supplemental_info', 'amount' );
    my $supp_qty    = $self->get_qualified_info( $service_data, 'service_supplemental_info_quantity', 'quantity' );

    %service_line = ( %service_line, %$dates )      if $dates;
    %service_line = ( %service_line, %$ref_ids )    if $ref_ids;
    %service_line = ( %service_line, %$supp_info )  if $supp_info;
    %service_line = ( %service_line, %$supp_qty )   if $supp_qty;

    # warn if there is a collision of the hash keys
    die "Service line hash keys collision when building up the service line data" unless scalar( keys %service_line ) == 
        scalar( keys %$dates ) + 
        scalar( keys %$ref_ids ) +
        scalar( keys %$supp_info ) +
        scalar( keys %$supp_qty );

    $service_line{ payment_info }   = $self->get_service_payment_info( $service_data );
    $service_line{ deductions }     = $self->get_deductions( $service_data, 'service' );
    $service_line{ remarks }        = $self->get_remarks( $service_data );

    return \%service_line;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_service_payment_info {
    my $self = shift;
    my( $service_data ) = @_;

    return unless $service_data;

    my @payment_keys = qw/ line_item_charge_amount line_item_provider_payment_amount
                           national_uniform_billing_committee_revenue_code units_of_service_paid_count
                           original_units_of_service_count /;

    my %service_payment = map { $_ => $service_data->{ service_payment_info }{ $_ } || undef } @payment_keys;

    # unravel the composite elements
    for my $composite_name ( qw/ medical_procedure submitted_medical_procedure / ){

        my $composite = $service_data->{ service_payment_info }{ "composite_$composite_name" } || undef;

        next unless $composite;

        my $delimiter = $self->composite_delimiter;
        my @components = split /$delimiter/ => $composite;
 
        # specifies the order the composite components are in
        my @component_keys = qw/ code_qualifier code modifier_1 modifier_2 modifier_3 modifier_4 description /;
 
        my @modifiers;
        for my $i ( 0 .. $#component_keys ){

            my $component = $components[ $i ];
            last unless $component;

            my $key = $component_keys[ $i ];
            if( $key =~ /modifier/ ){
                push @modifiers => $component;
            } else {
                $service_payment{ $composite_name }{ $key } = $component;
            }
        }
        $service_payment{ $composite_name }{ modifiers } = \@modifiers;
   } 

    return \%service_payment;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_remarks {
    my $self = shift;
    my( $service_data ) = @_;
    my @remarks;

    return unless $service_data;

    for( @{ $service_data->{ health_care_remark_codes } }){

        # NOTE We're only supporting the Remittance Advice Remark Codes right now -
        # it looks like the only other code list used is the National Council 
        # for Prescription Drug Programs Reject/Payment code list ('RX' qualifier)
        return unless $_->{ qualifier } eq 'HE';
 
        my $code = $_->{ remark_code };
        next unless $code;

        my %remark;
        $remark{ code } = $code;

        # XXX Refactor: I don't think this lookup for text needs to be here.
        # Rather it should be later when the text is displayed in the UI.
        my $valid_data = eleMentalClinic::ValidData->new({ dept_id => 1001 });
        $valid_data = $valid_data->get_byname( '_remittance_remark_codes', $remark{ code } );
        $remark{ text } = $valid_data->{ description } if $valid_data;

        push @remarks => \%remark;
    }

    return \@remarks;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_provider_deductions

Object method. The 835 spec calls these adjustments: the amount that a payer will not pay. 
To avoid confusion with eMC's Medicaid Adjustment, we're calling them deductions.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_provider_deductions {
    my $self = shift;

    return unless $self->edi_data;

    my @deductions;
    for my $adjustment_data ( @{ $self->edi_data->{ provider_adjustments } } ) {

        for( 1 .. 6 ){
            
            my $composite = $adjustment_data->{ "composite_adjustment_id_$_" };
            next unless $composite;

            my %deduction;
            my $delimiter = $self->composite_delimiter;

            ( $deduction{ reason_code }, $deduction{ id } ) = split /$delimiter/ => $composite;
            $deduction{ amount } = $adjustment_data->{ "amount_$_" };
            
            # these are only specified once per PLB segment, but we'll add it to each group of adjustments 
            $deduction{ provider_id }          = $adjustment_data->{ provider_id };
            $deduction{ fiscal_period_date }   = $self->format_ccyymmdd( $adjustment_data->{ fiscal_period_date } );

            push @deductions => \%deduction;
        }
    }

    return \@deductions;
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
