package eleMentalClinic::Group::Member;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Group::Member

=head1 SYNOPSIS

Join between client and group membership.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Client;

use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'group_members' }
    sub fields { [ qw/
        rec_id group_id client_id active
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_bygroup {
    my $class = shift;
    my( $group_id ) = @_;
    return unless $group_id;

    my $table = $class->table;
    return unless my $client_ids = $class->db->select_many(
        ["$table.client_id"],
        "$table, client",
        qq/
            WHERE group_id = $group_id
            AND   client.client_id = $table.client_id
        /,
        "ORDER BY client.lname, client.fname"
    );

    my @clients;
    push @clients, eleMentalClinic::Client->new({ client_id => $_->{ client_id } })->retrieve
        for( @$client_ids );
    return \@clients;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client {
    my $self = shift;
    return unless $self->client_id;

    eleMentalClinic::Client->new({ client_id => $self->client_id })->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_byclient_group {
    my $class = shift;
    my( $client_id, $group_id ) = @_;

    return unless $client_id and $group_id;

    return unless my $member = $class->db->select_one(
        [ $class->primary_key ],
        $class->table,
        "client_id = $client_id AND group_id = $group_id"
    );

    $class->new($member)->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub remove {
    my $self = shift;
    return unless my $rec_id = $self->rec_id;
    $self->db->delete_one(
        $self->table,
        "rec_id = $rec_id"
    );
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
