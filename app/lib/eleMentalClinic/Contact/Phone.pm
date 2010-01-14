=head1 eleMentalClinic::Phone

Abstraction of the phone table which is a one-to-many mapping of clients and
rolodex entries to their phone numbers.

=head1 METHODS

=over

=cut

package eleMentalClinic::Contact::Phone;

use strict;
use warnings;

use base qw(eleMentalClinic::Contact);

{
    sub table { 'phone' }
    sub fields {
        [ qw/
            rec_id client_id rolodex_id phone_number message_ok call_ok
            active phone_type primary_entry
        /]
    }
    sub primary_key { 'rec_id' }
}

=item save_from_form($relation_id, $vars)

See eleMentalClinic::Contact::save_from_form()

=cut

sub save_from_form {
    my $self = shift;
    my ($relation_id, $vars) = @_;

    $self->SUPER::save_from_form('phone_id', $relation_id, $vars);
}

#            [% entry.phone.phone_number_web %]
#            [% $entry.address.address_web %]
#            <!-- [% "$entry.address.address1; $entry.address.city, $entry.address.state" %] -->

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 phone_number_web()

Object method.

Returns a string, if a phone number is present the string will be (NUMBER),
otherwise it will be null.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub phone_number_web {
    my $self = shift;
    return "(" . $self->phone_number . ")" if $self->phone_number;
    return "";
}

'eleMental';

__END__

=back

=head1 AUTHORS

=over 4

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
