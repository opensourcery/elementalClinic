package eleMentalClinic::Client::Diagnosis;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Diagnosis

=head1 SYNOPSIS

Client mental health diagnosis.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::Client::Discharge;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_diagnosis' }
    sub fields { [ qw/
        rec_id client_id diagnosis_date 
        diagnosis_1a diagnosis_1b diagnosis_1c 
        diagnosis_2a diagnosis_2b diagnosis_3 
        diagnosis_4 diagnosis_5_highest 
        diagnosis_5_current comment_text
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_byclient {
    my $self = shift;
    my( $client_id ) = @_;
    return unless $client_id;

    my $class = ref $self;

    return unless my $hashrefs = $self->db->select_many(
        $self->fields,
        $self->table,
        "WHERE client_id = $client_id",
        'ORDER BY diagnosis_date DESC'
    );

    my @results;
    push @results => $class->new( $_ ) for @$hashrefs;
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub clone {
    my $self = shift;
    my( $old_id ) = @_;
    $old_id ||= $self->id;
    return unless $old_id;

    my $clone = $self->new({ rec_id => $old_id })->retrieve;
    $clone->rec_id('');
    $clone->save;
    return $clone->rec_id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 code( $axis )

Object method.

Parses a diagnosis string and returns the code.  E.g., given C<1a>, and if
C<diagnosis_1a> is

    296.80 Bipolar Disorder NOS

Will return: C<296.00>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub code {
    my $self = shift;
    my( $axis ) = @_;

    return unless $axis;
    die 'Invalid diagnosis type'
        unless grep /^$axis$/ => qw/ 1a 1b 1c 2a 2b /;

    my $property = "diagnosis_$axis";
    return
        unless $self->$property and $self->$property =~ /^(\d+\.\d+)\s/;
    return $1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1

Class method to return the most recent diagnosis for a given
client_id as a Client::Diagnosis.

Returns undef if no client_id or no diagnosis is available.

=cut

sub get_current_byclient {
    my $class = shift;
    my( $client_id ) = @_;

    return unless $client_id;

    return unless my $hashref = $class->new->db->select_one(
        $class->fields,
        $class->table,
        "client_id = $client_id",
        'ORDER BY diagnosis_date DESC LIMIT 1'
    );

    return $class->new( $hashref );
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
