#!/usr/bin/perl
# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
use strict;
use warnings;

=head1 NAME

billingcycle_data.pl

=head1 SYNOPSIS

Script to populate the validation_set, billing_cycle tables, to use when wanting
to test financial tools after the billing cycle is created.

=head1 USE

    ./billingcycle_data.pl [system|payer|billed|billed_identical]

Requires the test data in Test.pm to be in the database (use 'make testdata-jazz'
in database/).

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use lib qw# ../lib #;
use Data::Dumper;
use eleMentalClinic::Test;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my $arg = shift;
my $billing_cycle;

die "Only args 'system', 'payer', 'billed' and 'billed_identical' are supported by this script"
    unless !$arg or ( grep { $_ eq $arg } qw/ system payer billed billed_identical / );

# XXX Could be refactored further / folded into financial_setup in Test.pm

unless( defined $arg and $arg eq 'billed_identical' ) {
    $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 );
}

# run various stages of the first billing cycle
if( defined $arg and ($arg eq 'system' or $arg eq 'payer' or $arg eq 'billed') ) {

    $test->financial_setup_system_validation( $billing_cycle );

    if( $arg eq 'payer' or $arg eq 'billed' ) {

        $test->financial_setup_payer_validation( $billing_cycle );
        $billing_cycle->status( 'Validating' );

        if( $arg eq 'billed' ){
            $test->financial_setup_bill( $billing_cycle ); 
        }
    }
    $billing_cycle->save;
}

# OR run billing cycle 1 and start 2, throwing in a new note that's 'identical'
if( defined $arg and $arg eq 'billed_identical' ) {

    $test->financial_setup( 1, '../' );

    # move two notes into the billing cycle date range
    eleMentalClinic::ProgressNote->retrieve( 1444 )->start_date( '2006-07-05 14:00:00' )->save;
    eleMentalClinic::ProgressNote->retrieve( 1444 )->end_date( '2006-07-05 15:00:00' )->save;

    eleMentalClinic::ProgressNote->retrieve( 1445 )->start_date( '2006-07-07 14:00:00' )->save;
    eleMentalClinic::ProgressNote->retrieve( 1445 )->end_date( '2006-07-07 15:00:00' )->save;
    
    # start a new cycle for UI testing, do system validation with 1013 (combined note rule)
    $billing_cycle = $test->financial_setup_billingcycle;
    $test->financial_setup_system_validation( $billing_cycle, [ qw/ 1001 1003 1004 1013 / ] );
    
    # mark a transaction for one of the identical notes as entered_in_error
    # to test that the notes now get marked as "defer_until_payment" 
    eleMentalClinic::Financial::Transaction->retrieve( 1002 )->entered_in_error( 1 )->save;
}


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
