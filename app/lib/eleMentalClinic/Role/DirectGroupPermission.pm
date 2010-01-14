# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Role::DirectGroupPermission;
use strict;
use warnings;
use eleMentalClinic::Role;
use eleMentalClinic::Group;
use eleMentalClinic::Role::Cache qw/resets_role_cache/;

use base qw/ eleMentalClinic::DB::Object /;

=head1 NAME

eleMentalClinic::Role::DirectGroupPermission

=head1 DESCRIPTION

A permission object granting permissions against a group to a specific role.

=head1 METHODS

=over 4

=item role()

Returns the role in this permission.

=item group()

Returns the group in this permission.

=cut

sub table  { 'direct_group_permission' }
sub fields {[ qw/ rec_id role_id group_id /]}
sub primary_key { 'rec_id' }

sub accessors_retrieve_one {
    {
        role => { role_id => 'eleMentalClinic::Role' },
        group => { group_id => 'eleMentalClinic::Group' },
    };
}

'eleMental';

__END__

=back

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2009 OpenSourcery, LLC

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
