package eleMentalClinic::ECS::ReadTA1;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::ECS::ReadTA1

=head1 SYNOPSIS

Reads and parses an EDI file in TA1 format.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base /;
use Data::Dumper;
use X12::Parser;
use YAML::Syck qw/ LoadFile /;

# TODO create a parent class and subclass this and Read835 from it

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
    $self->config_file( $self->config->ecsta1_cf_file );
    $self->yaml_file( $self->config->ecsta1_yaml_file );

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 valid_file( $file )

Object method. Quick rough check to see if this file can even be parsed as a TA1.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub valid_file {
    my $self = shift;
    my( $file ) = @_;

    die 'File is required' unless $file;

    open( EDIFILE, $file ) or die "Cannot open file $file\n";
    my $edi = do { local $/; <EDIFILE> };
    close EDIFILE;

    return 1 if $edi =~ /ISA.*TA1/s;
    # TA1s might not actually contain a TA1 segment
    # so check that it's a general EDI file
    return 1 if $edi =~ /ISA.*GS.*GE.*IEA/s;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 parse

Object method. Parse a file with the transaction specific configuration file.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub parse {
    my $self = shift;

    return unless $self->file and $self->config_file;
    
    $self->parser->parsefile( file => $self->file, conf => $self->config_file );
    #warn $self->parser->print_tree;
    
    return 1;
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
sub get_edi_data {
    my $self = shift;
    
    return unless $self->file and $self->config_file and $self->yaml_file;
    
    my $method = $self->parser->can('get_element_seperator') ? 'get_element_seperator' : 'get_element_separator';

    my $elem_sep = $self->parser->$method;

    return unless $elem_sep;
    
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
                
                my $i = 0;
                my %elements;
                for( @elements ){
                    my $tag = $yaml_hashref->{ $loop }{ $seg_id }{ $i };
                    $elements{ $tag } = $elements[ $i ] if $tag;
                    $i++;
                }
                
                if( $loop ) {
                    # $self->_simple_level_one_loops
                    if( $loop =~ /^ISA|TA1|GS|AK1|AK9|GE|IEA$/ ) {
                        $edi_data->{ $loop_name } = \%elements;
                    }
                    else { die "$loop is not an expected loop!"; }
                }
            }    
        }
    }

    $self->edi_data( $edi_data );

    $self->composite_delimiter( $edi_data->{ interchange_control_header }{ composite_delimiter } );
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
# Methods to retrieve actual data from the TA1

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
    # warning: 2000 century assumed by the 997
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
sub get_orig_interchange_control_number {
    my $self = shift;
    
    return unless $self->edi_data;
    return $self->edi_data->{ interchange_ack }{ orig_interchange_control_number };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_orig_interchange_date {
    my $self = shift;

    return unless $self->edi_data;

    # YYMMDD
    my $date = $self->edi_data->{ interchange_ack }{ orig_interchange_date };
    # warning: 2000 century assumed by the TA1
    $date =~ s/^(\d{2})(\d{2})(\d{2})$/20$1-$2-$3/;
    return $date;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_orig_interchange_time {
    my $self = shift;
    
    return unless $self->edi_data;
    
    my $time = $self->edi_data->{ interchange_ack }{ orig_interchange_time };
    $time =~ s/^(\d{2})(\d{2})$/$1:$2/;
    return $time; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_interchange_ack_code {
    my $self = shift;
    
    return unless $self->edi_data;
    return $self->edi_data->{ interchange_ack }{ interchange_ack_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_interchange_note_code {
    my $self = shift;
    
    return unless $self->edi_data;
    return $self->edi_data->{ interchange_ack }{ interchange_note_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_functional_group_count {
    my $self = shift;
   
    return unless $self->edi_data;

    my $count = $self->edi_data->{ interchange_control_trailer }{ functional_group_count };
    
    # TA1s may not have a GS loop at all
    die "Not expecting more than one functional group - GS"
        unless $count == 1 or $count == 0;
        
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

    return unless $self->edi_data and $self->edi_data->{ functional_group_header };

    return $self->edi_data->{ functional_group_header }{ functional_identifier_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_sender_code {
    my $self = shift;

    return unless $self->edi_data and $self->edi_data->{ functional_group_header };

    return $self->edi_data->{ functional_group_header }{ sender_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_receiver_code {
    my $self = shift;

    return unless $self->edi_data and $self->edi_data->{ functional_group_header };

    return $self->edi_data->{ functional_group_header }{ receiver_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_functional_group_date {
    my $self = shift;

    return unless $self->edi_data and $self->edi_data->{ functional_group_header };

    # CCYYMMDD
    my $date = $self->edi_data->{ functional_group_header }{ functional_group_date };
    
    return $self->format_ccyymmdd( $date );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_functional_group_time {
    my $self = shift;
   
    return unless $self->edi_data and $self->edi_data->{ functional_group_header };

    my $time = $self->edi_data->{ functional_group_header }{ functional_group_time };
    $time =~ s/^(\d{2})(\d{2})$/$1:$2/;
    return $time; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_group_control_number {
    my $self = shift;

    return unless $self->edi_data and $self->edi_data->{ functional_group_header };

    my $header_num = $self->edi_data->{ functional_group_header }{ group_control_number };
    my $trailer_num = $self->edi_data->{ functional_group_trailer }{ group_control_number };

    die "Group control number in the GS header ($header_num)  and GE trailer ($trailer_num) don't match!"
        unless $header_num eq $trailer_num;

    return $header_num;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_transaction_set_count {
    my $self = shift;
   
    return unless $self->edi_data and $self->edi_data->{ functional_group_trailer };

    my $count = $self->edi_data->{ functional_group_trailer }{ transaction_set_count };
    
    die "Not expecting more than one transaction set - ST"
        unless $count == 1;
        
    # XXX Could actually count the sets to verify that the count is correct 
    return $count;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_x12_version {
    my $self = shift;

    return unless $self->edi_data and $self->edi_data->{ functional_group_header };

    my $version = $self->edi_data->{ functional_group_header }{ x12_version };
    die "X12 version is $version, not 004010X098A1 as expected"
        unless $version eq '004010X098A1';

    return $version;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_orig_functional_group_identifier_code {
    my $self = shift;

    return unless $self->edi_data and $self->edi_data->{ functional_group_response_header };

    return $self->edi_data->{ functional_group_response_header }{ identifier_code };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_orig_functional_group_control_number {
    my $self = shift;

    return unless $self->edi_data and $self->edi_data->{ functional_group_response_header };

    return $self->edi_data->{ functional_group_response_header }{ group_control_number };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_functional_group_response {
    my $self = shift;

    return unless $self->edi_data and $self->edi_data->{ functional_group_response_trailer };

    my %response;
    for( qw/ ack_code number_transaction_sets_included 
             number_transaction_sets_received number_transaction_sets_accepted / ) {
        $response{ $_ } = $self->edi_data->{ functional_group_response_trailer }{ $_ };
    }

    push @{ $response{ syntax_error_codes } } => $self->edi_data->{ functional_group_response_trailer }{ 'syntax_error_code_' . $_ }
        for 1 .. 5;

    return \%response;
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

