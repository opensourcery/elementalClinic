=head1 eleMentalClinic::Contact

Base class for various bits of contact information (phone, address, f.e.)

=head1 METHODS

=over

=cut

package eleMentalClinic::Contact;

use strict;
use warnings;

use base qw(eleMentalClinic::DB::Object);
use Data::Dumper;

=item save

Saves the item. See eleMentalClinic::DB::Object.

=cut

sub save {
    my $self = shift;
    
    # ticket #80, make sure primary entree is always true or false (0 or 1) and never null.
    $self->primary_entry( 0 ) unless defined $self->primary_entry;

    if ($self->primary_entry) {
        $self->db->update_one( $self->table, ['primary_entry'], [0],
            (
                $self->client_id
                ? [ 'client_id = ?',  $self->client_id ]
                : [ 'rolodex_id = ?', $self->rolodex_id ]
            ) 
        );
    }

    return $self->SUPER::save;
}

=item get_by_

Wrapper. See eleMentalClinic::DB::Object::get_by_

=cut

sub get_by_ {
    my $self = shift;
    my $primary_key = shift;

    $primary_key = $primary_key eq 'client_id' ? 'client_id' : 'rolodex_id';

    $self->SUPER::get_by_($primary_key, @_);
}

=item is_active

If the item is an active item, returns true.

=cut

sub is_active {
    my $self = shift;
    return $self->active
}

=item save_from_form($id_type, $relation_id_type, $vars)

This method expects specific vars to transform into others. It does this so
that these Contact objects can co-exist with Rolodex and Demographics on a form.

The list of transformations is:

=over

=item $id_type transformed to rec_id

=item primary_entry is set to true

=item rec_id is transformed to $relation_id_type 

=back

This is intended to be overloaded by the subclasses with the $id_type populated
already, yielding a method with an arity of 2 instead of 3.

=cut

sub save_from_form {
    my $self = shift;
    my ($id_type, $relation_id_type, $vars) = @_;

    my %fields = map { $_ => $vars->{$_} } @{$self->fields};

    if ($relation_id_type ne 'client_id') {
        $fields{$relation_id_type} = $vars->{rec_id};
    }
    $fields{rec_id}            = $vars->{$id_type};
    $fields{primary_entry}     = 1;
    $fields{active}            = 1;

    $self->new(\%fields)->save;
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
