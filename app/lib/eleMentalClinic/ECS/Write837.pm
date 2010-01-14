package eleMentalClinic::ECS::Write837;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::ECS::Write837

=head1 SYNOPSIS

Writes 837 EDI files. Child of L<eleMentalClinic::Financial::WriteClaim>.

=head1 DESCRIPTION

Write837 is a simple wrapper for controlling production of 837 EDI forms
from eleMentalClinic::Financial::BillingFile objects.

=head1 Usage

    my $write_837 = eleMentalClinic::ECS::Write837->new( { billing_file => $billing_file_ref } )

    # Call generate() to just obtain the EDI data as a string
    my $edi_data = $write_837->generate;

    # Or call write() to have the edi form output as a text file in the current 
    # $config->edi_out_root directory
    $write_837->write;

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Financial::WriteClaim /;
use Data::Dumper;
use eleMentalClinic::ECS::Template;
use YAML::Syck qw/ LoadFile /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 defaults

Sets core object properties, unless they have already been set.

 * output_root is taken from the Config, although it 
may be set manually /after/ construction.

=cut

sub defaults {
    my $self = shift;
    
    $self->SUPER::defaults;
    
    $self->template( eleMentalClinic::ECS::Template->new({
        template_path       => $self->config->template_path,
    }));
    $self->output_root( $self->config->edi_out_root );
    $self->valid_lengths( LoadFile( $self->config->ecs_fieldlimits ) );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 make_filename()
 
Generates a filename in the following format "%d%s837P%04d" as filled by 
the billing_file_rec_id, billing_file->mode, and month & day of the date_stamp.

[filenum]t837Pmmdd.txt

=cut

sub make_filename {
    my $self = shift;

    my $date = $self->date_stamp;
    return unless $date and length $date == 8;

    $date =~ s/^(\d{4})(\d{2})(\d{2})$/$2$3/;
    my $mode = $self->billing_file->mode;

    return sprintf '%d%s837P%04d.txt', ( 
        $self->billing_file->rec_id,
        "\l$mode",
        $date,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 generate()

Creates EDI 837 form based on the currently set BillingFile object.

Returns the EDI 837 form data as a string.

Dies if unable to get the key data.

=cut

sub generate {
    my $self = shift;

    die 'Object requires date_stamp and time_stamp' unless $self->date_stamp and $self->time_stamp;
    die 'Invalid format for date_stamp: CCYYMMDD required' unless $self->date_stamp =~ /\d{8}/;
    die 'Invalid format for time_stamp: HHMM required' unless $self->time_stamp =~ /\d{4}/;

    my $data_837 = $self->billing_file->get_837_data;
    die 'Unable to get data for EDI generation.'
        unless $data_837;

    # Set up the dates
    my $shortdate = substr( $self->date_stamp, 2, 6 );
    $data_837 = { %$data_837, (
        date             => $shortdate,
        time             => $self->time_stamp,
        date_long        => $self->date_stamp,
    )};

    $data_837 = $self->validate( $data_837 );
    my $edi = $self->template->process_block( 'write_837', $data_837 );
    
    # OMAP requires carriage returns be stripped out,
    # so use ~ as a segment delimiter. 
    $edi =~ s/\n/~/g if $edi;
   
    # Now remove any trailing '*' characters (element separators) at the end of 
    # all segments.
    $edi =~ s/\*+~/~/g if $edi;

    return $edi;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 write()

Object method.

Generates the claim data and writes it to a file.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub write {
    my $self = shift;

    my $edi_data = $self->generate;

    my $edi_file_path = $self->output_root.'/'.$self->make_filename;
    unlink $edi_file_path;

    my $EDI;
    open $EDI, ">$edi_file_path"
        or die "Can't create $edi_file_path.";
    
    print $EDI "$edi_data";
    close $EDI;

    return( $edi_file_path, $edi_data );
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_date_f()

Formatting for 837 ECS

Takes a date in the format "CCYY-MM-DD" and returns it 
in the format "CCYYMMDD"

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_date_f {
    my $class = shift;
    my( $date ) = @_;

    return unless $date and $date =~ /\d{4}-\d\d?-\d{2}/;

    return sprintf "%4d%02d%02d", split( "-", $date );
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

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
