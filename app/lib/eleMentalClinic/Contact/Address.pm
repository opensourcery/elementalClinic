=head1 eleMentalClinic::Address

Abstraction of the address table which is a one-to-many mapping of clients and
rolodex entries to their phone numbers.

=head1 METHODS

=over

=cut

package eleMentalClinic::Contact::Address;

use strict;
use warnings;

use base qw(eleMentalClinic::Contact);

{
    sub table { 'address' }
    sub fields {
        [
            qw/
              rec_id client_id rolodex_id address1 address2 city state
              post_code county active primary_entry
              /
        ]
    }
    sub primary_key { 'rec_id' }
}

=item save_from_form($relation_id, $vars)

See eleMentalClinic::Contact::save_from_form()

=cut

sub save_from_form {
    my $self = shift;
    my ($relation_id, $vars) = @_;

    $self->SUPER::save_from_form('address_id', $relation_id, $vars);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 address_web()

Object method.

returns a string containing the full address, cleaned up specifically for
display in the ui.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub address_web {
    my $self = shift;
    my $out = ""; #Make sure it contains an empty string if nothing else.
    $out .= $self->address1 . "; " if $self->address1;
    $out .= $self->city . ", " if $self->city;
    $out .= $self->state;
    return $out;
}

'eleMental';

__END__

=back

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

=item Erik Hollensbe L<erikh@opensourcery.com>

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
