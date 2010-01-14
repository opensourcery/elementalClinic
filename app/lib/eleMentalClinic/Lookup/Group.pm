package eleMentalClinic::Lookup::Group;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Lookup::Group

=head1 SYNOPSIS

TODO

=head1 METHODS

=cut

use base 'eleMentalClinic::DB::Object';
use Data::Dumper;
use eleMentalClinic::ValidData;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'lookup_groups' }
    sub primary_key { 'rec_id' }
    sub fields { [ qw/
        rec_id parent_id name description active system
    /] }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get all lookup groups for the specified table
# table is specified by id, not name
# dies with no incoming table id
sub get_by_table {
    my $self = shift;
    my( $table_id, $options ) = @_;

    die "Table id required" unless $table_id;
    my $where = 'WHERE parent_id = '. $table_id;
    if( $options ) {
        die "Options must be a hashref"
            unless ref $options eq 'HASH';
        # turning hashref into string where clause
        $where .= " AND $_ = ". $self->db->dbh->quote( $options->{ $_ })
            for keys %$options;
    }
    $self->db->select_many(
        $self->fields,
        $self->table,
        $where,
        'ORDER BY name, '. $self->primary_key,
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME should return undef with no results.  duh.
sub members {
    my $self = shift;

    return [] unless $self->id;
    my $result = $self->db->select_many_arrayref(
        [ 'item_id' ],
        'lookup_group_entries',
        'WHERE group_id = '. $self->id,
        'ORDER BY item_id'
    );
    $result;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub members_lookup {
    my $self = shift;
    $self->make_lookup_hash( $self->members );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_member {
    my $self = shift;
    my( $item_id ) = @_;

    die 'Item id is required.'
        unless $item_id;
    die 'No group id: cannot check membership of an undefined group.'
        unless $self->id;
    my $result = $self->db->select_one(
        [ 'rec_id' ],
        'lookup_group_entries',
        'group_id = '. $self->id
        ." AND item_id = $item_id",
    );
    return 1 if $result->{ rec_id };
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# empty arrayref removes all items; this is desired behavior
sub set_members {
    my $self = shift;
    my( $member_ids ) = @_;

    return unless $member_ids;
    die 'Member ids must be an arrayref.'
        unless ref $member_ids eq 'ARRAY';

    # delete all entries for this group
    $self->db->do_sql(
        'DELETE FROM lookup_group_entries WHERE group_id = ' . $self->id,
        'return' # avoid extra work
    );
    for( $self->unique( $member_ids )) {
        $self->db->insert_one(
            'lookup_group_entries',
            [ qw/ group_id item_id /],
            [ $self->id, $_ ],
        );
    }
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# name exists should return true if:
# - name matches
# - parent_id matches
# - rec_id does not match
sub name_is_dup {
    my $self = shift;

    die 'Name and parent_id are required by "Group::name_is_dup".'
        unless $self->name and $self->parent_id;

    my $result = $self->db->select_one(
        [ 'rec_id' ],
        'lookup_groups',
        ' parent_id = '. $self->parent_id
        ." AND name = '". $self->name ."'"
    );

    no warnings qw/ uninitialized /;
    return 1 if
        $result->{ rec_id }
        and $result->{ rec_id } != $self->id;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns arrayref of lookup group objects with which $staff_id
# is associated.  adds a hash key "sticky" to each object, which
# is 1 or 0 depending on whether the association is sticky
sub get_by_personnel_association {
    my $self = shift;
    my( $table_id, $staff_id ) = @_;

    die 'Table id and staff id are required by Lookup::Groups::get_by_personnel_association.'
        unless $table_id and $staff_id;

    my $results = $self->db->select_many(
        [ 'lookup_groups.rec_id, name, description, parent_id, active, system, sticky' ],
        'personnel_lookup_associations, lookup_groups',
        'WHERE lookup_group_id = lookup_groups.rec_id'
        ." AND staff_id = $staff_id"
        ." AND parent_id = $table_id",
        'ORDER BY name, lookup_groups.rec_id'
    );
    return unless $results;
    my $class = ref $self;
    my @groups;

    for( @$results ) {
        my $group = $class->new( $_ );
        # FIXME this is a little evil, setting a hash key that isn't really an attribute
        $group->{ sticky } = $_->{ sticky };
        push @groups => $group;
    }
    \@groups;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub lookup_associations {
    my $self = shift;
    my( $table_id ) = @_;

    die 'Group id is required by Lookup::Groups::lookup_associations.'
        unless $self->rec_id;
    die 'Table id is required by Lookup::Groups::lookup_associations.'
        unless $table_id;

    return $self->db->select_many_arrayref(
        [ 'lookup_item_id' ],
        'lookup_associations',
        'WHERE lookup_group_id = '. $self->id,
        ' AND lookup_table_id = '. $table_id,
        'ORDER BY lookup_item_id'
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub lookup_associations_hash {
    my $self = shift;
    my( $table_id ) = @_;

    $self->make_lookup_hash( $self->lookup_associations( $table_id ));
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_lookup_associations {
    my $self = shift;
    my( $table_id, $item_ids ) = @_;

    die 'Table id is required by Lookup::Groups::set_lookup_associations.'
        unless $table_id;
    return unless $item_ids;
    die 'Lookup ids must be an arrayref at Lookup::Groups::set_lookup_associations.'
        if $item_ids and ref $item_ids ne 'ARRAY';

    # delete all entries for this group
    $self->db->do_sql(
        'DELETE FROM lookup_associations'
        .' WHERE lookup_group_id = '. $self->id
        .' AND lookup_table_id = '. $table_id,
        'return' # avoid extra work
    );

    for( $self->unique( $item_ids )) {
        $self->db->insert_one(
            'lookup_associations',
            [ qw/ lookup_table_id lookup_item_id lookup_group_id /],
            [ $table_id, $_, $self->id ],
        );
    }
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_ids_by_group_name_and_parent {
    my $self = shift;
    my( $name, $parent ) = @_;

    my $codes = $self->get_codes_by_group_name_and_parent( $name, $parent );
    return unless $codes;

    my @items;
    push @items => $_->{ rec_id } for @$codes;
    \@items;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_codes_by_group_name_and_parent {
    my $self = shift;
    my( $name, $parent ) = @_;

    die 'Group and parent name are required by ::Lookup::Group::get_codes_by_group_name_and_parent.'
        unless $name and $parent;

    $name = $self->db->dbh->quote( $name );
    my $parent_q = $self->db->dbh->quote( $parent );
    my $query = qq/
        SELECT rec_id, dept_id, name, description, active,
            min_allowable_time, max_allowable_time, minutes_per_unit,
            dollars_per_unit, max_units_allowed_per_encounter,
            max_units_allowed_per_day, cost_calculation_method
        FROM $parent
        WHERE rec_id IN (
            SELECT item_id FROM lookup_group_entries
            WHERE group_id = (
                SELECT rec_id FROM lookup_groups
                WHERE name = $name
                AND parent_id = (
                    SELECT rec_id
                    FROM valid_data_valid_data
                    WHERE name = $parent_q
                )
            )
        )
        ORDER BY name
    /;
  0 and print STDERR Dumper $query;
    my $results = $self->db->do_sql( $query );
    return unless $results->[ 0 ];
    my @items;
    push @items => $_ for @$results;
    \@items;
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

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
