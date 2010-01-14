package eleMentalClinic::DB::Initialization;
use strict;
use warnings;

use eleMentalClinic::DB;

=head1 NAME

eleMentalClinic::DB::Initialization

=head1 SYNOPSIS

Provides functions used for initializing the database

=head1 METHODS

=cut

sub new {
    my $self = bless { }, shift;
    $self->{ db } = new eleMentalClinic::DB;
    #$self->{ dbh } = $self->{ db }->dbh;

    return $self;
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum <chad@opensourcery.com>

=item Erik Hollensbe <erikh@opensourcery.com>

=item Ryan Whitehurst <ryan@opensourcery.com>

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
