#!/usr/bin/perl
use strict;
use warnings;

=head1 NAME

bencmark_compilation.pl

=head1 SYNOPSIS

Times compile time of all modules in distribution.  Specify a number of times
to iterate, or the default will be used.

=head1 METHODS

=cut

use File::Next;
use Time::HiRes qw/ gettimeofday tv_interval /;
use Data::Dumper;
use YAML qw/ LoadFile DumpFile /;
use Date::Calc qw/ Today_and_Now /;

my $COUNT_RUNS = shift || 3;

my %times;

# run the benchmark $COUNT_RUNS number of times
for( 1..$COUNT_RUNS ) {
    my $files = File::Next->files( 'lib/' );
    while ( my $file = $files->() ) {
        next unless $file =~ /\.pm$/;
        next if $file =~ /Simple/;

        my $time = [ gettimeofday ];
        system 'perl', '-Ilib', '-c', $file;
        $times{ $file } += tv_interval( $time );
    }
}

# calculate the results
my @sorted = map{ $times{ $_ } / $COUNT_RUNS .": $_" } sort{ $times{ $b } <=> $times{ $a }} keys %times;
DumpFile '.compilation.'. time, "$COUNT_RUNS of compilation at ". sprintf( "%d-%02d-%02d %02d:%02d:%02d", Today_and_Now ), \@sorted

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
