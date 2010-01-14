#!/usr/bin/perl
# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
use warnings;
use strict;

=head1 NAME

benchmark_validation.pl

=head1 SYNOPSIS

Benchmarks creation and validation of an arbitrary number of progress notes,
defined by the first parameter passed to this script.

=head1 USE

    ./benchmark_validation.pl          # add default number of notes

... or ...

    ./benchmark_validation.pl 1000     # add 1,000 notes

=cut

use lib 'lib';
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Financial::ValidationSet;
use Time::HiRes qw/ gettimeofday tv_interval /;

my $COUNT = shift;
my( $TIME, $total );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
timeme( 'Init' );
$test->add_prognotes( $COUNT || 10_000 );

timeme( 'Creating prognotes' );
my $set = eleMentalClinic::Financial::ValidationSet->create({
    creation_date   => '2006-07-15',
    staff_id        => 1005,
    type            => 'billing',
    from_date       => '2006-07-15',
    to_date         => '2006-07-31',
});
print "Set contains ", scalar @{ $set->prognotes }, " progress notes.\n";

timeme( 'Creating validation set' );
$set->system_validation([ qw/ 1001 1002 1003 1004 1009 1010 1011 1012 /]);

timeme( 'System validation' );
$set->payer_validation([ qw/ 1005 1006 1007 1008 /], 1009 );

timeme( 'Payer validation, 1009' );
$set->payer_validation([ qw/ 1005 1006 1007 1008 /], 1015 );

timeme( 'Payer validation, 1015' );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub timeme {
    my( $message ) = @_;

    $message ||= 'Elapsed';
    if( $TIME ) {
        print "$message: ", tv_interval( $TIME ), "\n";
        $total += $TIME;
    }
    $TIME = [ gettimeofday ];
}

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

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
