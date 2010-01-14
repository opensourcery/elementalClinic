#!/usr/bin/env perl
use strict;
use warnings;

=head1 NAME

fixture_export.pl

=head1 SYNOPSIS

Dump the contents of the eMC database to YAML fixture datafiles.

=cut

$|++;

use Getopt::Long;

use lib 'lib';
use eleMentalClinic::Fixtures;

my $path;
my $clean = 1;
GetOptions(
    "help"        => \&help,
    "directory=s" => \$path,
    "clean!"      => \$clean,
);

die( "$0: No directory specified for loading.\nTry `$0 --help` for more information.\n" ) unless $path;

print "Exporting fixture data...";
my $test = eleMentalClinic::Fixtures->new;
$test->export_db( $path, 1 );
print "done.\n";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub help {
    print STDERR <<"EOF";
Usage: $0 [options]

    This program is used to export the contents of a database into
a specified directory. A directory is specified after -d or --directory
and the data is dumped into that directory as a YAML fixture dataset.
If the directory does not exist, it will be created. By default, any
preexisting dataset in the directory will be deleted, but if the --noclean
flag is specified, the directory will be left alone and warnings issued
for any duplicate entries.

Options:
   -h   --help      Display this help message.
   -d   --directory Specify a directory to put exported fixtures
        --noclean   Do not empty out the contents of the directory
EOF
    exit( 0 );
}


__END__

=head1 AUTHORS

=over 4

=item Ryan Whitehurst L<ryan@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see
L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for
known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2008 OpenSourcery, LLC

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
