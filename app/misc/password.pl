#!/usr/bin/perl
use strict;
use warnings;

=head1 NAME

password.pl

=head1 SYNOPSIS

./password.pl <login> <password>

Generates a password hash.  This program is a command-line wrapper for
L<eleMentalClinic::Personnel>'s C<crypt_password> method.

Note that the config file must be present in, or symlinked to, the current
directory.

=cut

use lib qw/ lib /;
use eleMentalClinic::Personnel;
use Pod::Usage;

pod2usage()
    unless my( $login, $password ) = @ARGV;
print eleMentalClinic::Personnel->crypt_password( $login, $password ), "\n";

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

Copyright (C) 2006-2007 OpenSourcery, LLC

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
