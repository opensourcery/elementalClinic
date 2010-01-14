#!/usr/bin/perl
# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
use strict;
use warnings;

=head1 NAME

payment_data.pl

=head1 SYNOPSIS

Script to populate the transactions, billing_payment, etc tables,
by processing an 835 remittance advice.

=head1 USE

    ./payment_data.pl [sample filenum]

[sample filenum] specifies which sample remittance advice to process. 
Sample files are found like this: "t/resource/sample_835.$filenum.txt";
If called with no arguments, the sample file used is t/resource/sample_835.1.txt.
Currently the other files available are sample_835.2.txt, sample_835.3.txt, and sample_835.4.txt.

Requires the test data in Test.pm to be in the database (use 'make testdata-jazz'
in database/).

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use lib qw# ../lib #;
use Data::Dumper;
use eleMentalClinic::Test;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my $filenum = shift || 1;

die "Only files 1, 2, 3 and 4 are supported by this script"
    unless $filenum >= 1 and $filenum <= 4 and $filenum =~ /^\d$/;

print "Processing EDI file $filenum...";
# the map statement sends all other arguments in as options
$test->financial_setup( $filenum, '../', { map{ $_ => 1 } @ARGV });
print "done.\n";

__END__

=head1 AUTHORS

=over 4

=item Kirsten Comandich L<kirsten@opensourcery.com>

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

