#!/usr/bin/perl
use strict;
use warnings;

=head1 NAME

generate835.from837.pl

=head1 SYNOPSIS

TODO

=head1 USE

    ./generate835.from837.pl BILLING_FILE_ID

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my $arg = shift;

die "A billing_file ID is required"
    unless $arg and $arg =~ /^\d+$/;

my $write835 = new eleMentalClinic::ECS::Write835;
$write835->write( $arg );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package eleMentalClinic::ECS::Write835;
use strict;
use warnings;

use lib qw# ../lib/ #;
use base qw/ eleMentalClinic::Base /;
use Template 1.10;
use Data::Dumper;
use eleMentalClinic::Financial::BillingFile;

sub write {
    my $self = shift;
    my( $billing_file_id ) = @_;
    
    # Generate an *837* for this billing_file, and then...
    my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $billing_file_id );

    my $data_837 = $billing_file->get_837_data;
    die 'Unable to get data for EDI generation.'
        unless $data_837;

    # TODO use a fixed date?
    my( $date, $time ) = split ' ' => $self->timestamp;
    $date =~ s/-//g;
    $time =~ s/^(\d{2}):(\d{2}).*/$1$2/;
    my $shortdate = substr( $date, 2, 6 );
    $data_837 = { %$data_837, (
        shortdate   => $shortdate,
        time        => $time,
        date        => $date,
        checknum    => $shortdate
    )};


    # ... we'll use the data structure to fill in a fake *835*
    my $template = eleMentalClinic::ECS::Template->new({
        template_path       => $self->config->template_path,
    });
    my $edi = $template->process_block( 'write_835', $data_837 );

#    $edi =~ s/\n/~/g if $edi;

    # Now remove any trailing '*' characters (element separators) at the end of all segments.
#    $edi =~ s/\*+~/~/g if $edi;

    my $edi_file_path = $self->config->edi_in_root . '/' . $self->make_filename( $billing_file_id, $date );
    unlink $edi_file_path;

    my $EDI;
    open $EDI, ">$edi_file_path"
        or die "Can't create $edi_file_path.";

    print $EDI "$edi";
    close $EDI;

    print $edi_file_path . " generated\n\n";
}


sub make_filename {
    my $self = shift;
    my( $billing_file_id, $date ) = @_;

    return unless $date and length $date == 8;

    $date =~ s/^(\d{4})(\d{2})(\d{2})$/$2$3/;

    return sprintf '%dt835P%04d.txt', (
        $billing_file_id,
        $date,
    );
}


# Notes for further development

#    For each claim
#
#    my $patient_resp = '42.16';
#    my $claim_filing_indicator = 'MB'; # MB = Medicare B, MC = Medicaid
#    my $client_num = '666666666A'; # and for Medicaid, "HN" should be "MR"
#
#    my $numclaims = 1;
#    my $claimnoncovered = '25.00';
#    my $claimdenied = '50.00';
#TS3*1730167982*$facilitycode*20061231*$numclaims*$claimcharge*$claimpaid*$claimnoncovered*$claimdenied***

#    For each service
#    For each deduction

#CAS*CO*A2*75.00
#CAS*PR*A2*42.16*1

#    For each claim payment remark

#LQ*HE*M137
#LQ*HE*M1


=head1 AUTHORS

=over 4

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
