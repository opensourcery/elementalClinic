#!/usr/bin/perl
# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
use strict;
use warnings;

=head1 NAME

billingcycle_huge.pl

=head1 SYNOPSIS

Script to populate the validation_set, billing_cycle tables, to use when wanting
to test financial tools after the billing cycle is created.

For use with testdata-huge.

=head1 USE

    ./billingcycle_huge.pl [system|payer|billed|payment]

Requires the huge test data to be in the database (use 'make testdata-huge'
in database/).

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use lib qw# ../lib #;
use Data::Dumper;
use eleMentalClinic::Test;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my $arg = shift;

die "Only args 'system', 'payer', 'billed' and 'payment' are supported by this script"
    unless !$arg or $arg =~ /^system$|^payer$|^billed$|^payment$/;

my $billing_cycle = $test->financial_setup_billingcycle( 
    reset_sequences => 1, 
    staff_id => 1,
    creation_date => eleMentalClinic::Base->today,
    from_date   => '2006-11-21',
    to_date     => '2006-12-21',
);

if( defined $arg and ($arg =~ /^system$|^payer$|^billed$|^payment$/) ) {
   
    $test->financial_setup_system_validation( $billing_cycle, [ qw/ 1001 1003 1004 1011 1012 1013 /]);

    if( $arg =~ /^payer$|^billed$|^payment$/ ) {

        # 1396 is General Fund # 597 is Oregon Health Plan
        # 1394 is Medicare # 1395 is Xix - Medicaid 
        $test->financial_setup_payer_validation( $billing_cycle, [ qw/ 1005 1006 1008 1014 /], [ qw/ 1396 597 / ] );
   
        # claims processors: 1 OMAP, 2 PHTech, 3 Medicare 

        if( $arg =~ /^billed$|^payment$/ ){

            $test->financial_setup_bill( $billing_cycle, [ qw/ 1001 1002 / ] );
            
            if( $arg eq 'payment' ){
                $test->financial_setup_payment( '1001huge', '../' );
                $test->financial_setup_payment( '1002huge', '../' );
            }
        }
    }
    
    $billing_cycle->save;
}

print $_
    for @{ eleMentalClinic::Log->Retrieve_deferred };

__END__

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

