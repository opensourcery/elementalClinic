package eleMentalClinic::Client::Income;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Income

=head1 SYNOPSIS

Client's income sources and history.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::ValidData;
use eleMentalClinic::Client;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_income' }
    sub fields { [ qw/
        rec_id client_id source_type_id start_date
        end_date income_amount account_id certification_date
        recertification_date has_direct_deposit
        is_recurring_income comment_text
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_all {
    my $self = shift;
    my( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    $self->db->select_many( $self->fields, $self->table,
        "WHERE client_id = $client_id",
        "ORDER BY start_date, rec_id"
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my $self = shift;
    return unless my $results = $self->list_all( @_ );

    my $class = ref $self;
    my @results;
    push @results => $class->new( $_ ) for @$results;
    return \@results;
}

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#sub income_source {
#    my $self = shift;
#    my( $source_type_id ) = @_;
#    $source_type_id ||= $self->source_type_id;
#    return unless $source_type_id and $self->client_id;
#
#    my $client = eleMentalClinic::Client->new({ client_id => $self->client_id })->retrieve;
#
#    return unless $client->dept_id;
#    my $valid_data = eleMentalClinic::ValidData->new({ dept_id => $client->dept_id });
#    $valid_data->get( '_income_sources', $source_type_id )->{ name };
#}


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
