package eleMentalClinic::Client::Letter;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Letter

=head1 SYNOPSIS

Simple letter feature.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::Rolodex;
use eleMentalClinic::Client;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_letter_history' }
    sub fields { [ qw/
        rec_id client_id rolodex_relationship_id letter_type 
        letter sent_date print_header_id relationship_role
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub history {
    my $self = shift;
    my ( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless defined $client_id;

    my $class = ref $self;
    
    my $where = "WHERE client_id = $client_id";
    my $order_by = 'ORDER BY sent_date IS NULL, sent_date DESC';

    return unless my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO this could be generated automagically by base:
# (if the object has a field that is one of the valid_data fields, generate a sub like this)
sub print_header {
    my $self = shift;
    return unless $self->print_header_id;

    return unless my $hashref = eleMentalClinic::ValidData->new({dept_id => 1001})->get( '_print_header', $self->print_header_id );
    $hashref->{ description };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_relationship {
    my $self = shift;

    $self->client->relationship_getone({
        role            => $self->relationship_role,
        relationship_id => $self->rolodex_relationship_id,
    });
}
# maybe useful later ...
#     my( $role, $id ) = @_;
#     $self->client->relationship_getone({
#         role            => $role || $self->relationship_role,
#         relationship_id => $id || $self->rolodex_relationship_id,
#     });


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
