package eleMentalClinic::Client::Relationship;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Relationship

=head1 SYNOPSIS

Parent object for all client relationships.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  {
        die "You must subclass eleMentalClinic::Client::Relationship and override the 'table' method.";
    }
    sub fields {
        die "You must subclass eleMentalClinic::Client::Relationship and override the 'fields' method.";
    }
    sub primary_key {
        die "You must subclass eleMentalClinic::Client::Relationship and override the 'primary_key' method.";
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all  {
    my $self = shift;
    my( %where ) = @_;

    return unless $self->client_id;

    my $where = 'WHERE client_id = '. $self->db->dbh->quote( $self->client_id );
    if( %where ) {
        while( my( $key, $value ) = each %where ) {
            $where .= " AND $key = ". $self->db->dbh->quote( $value );
        }
    }

    my $class = ref $self;
    my $order_by = "ORDER BY " . $self->primary_key;
    return unless
        my $hashrefs = $self->db->select_many(
            $self->fields,
            $self->table,
            $where,
            "ORDER BY " . $self->primary_key,
        );
    my @results;
    foreach my $hashref( @$hashrefs ) {
        push @results => $class->new( $hashref ) if $hashref;
    }
    return \@results;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_of_active {
    my $self = shift;
    my( $active ) = @_;

    # this is a special-purpose wrapper method, and its only
    # legitimate use is as a shortcut for get_all when you must
    # filter by active status
    die 'Parameter is required for get_of_active; must be 1 or 0 "active" status'
        unless defined $active;
    $self->get_all( active => $active );
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
