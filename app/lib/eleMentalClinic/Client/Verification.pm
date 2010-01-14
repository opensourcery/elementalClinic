# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Client::Verification;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Verification

=head1 SYNOPSIS

Eligibility verification letter and history.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_verification' }
    sub fields { [ qw/ rec_id client_id apid_num verif_date rolodex_treaters_id created staff_id /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_byclient {
    my $class = shift;
    my( $client_id, $active ) = @_;
    return unless $client_id;

    my $active_clause = defined $active
        ? " AND active = $active"
        : '';
    return $class->new->db->select_many(
        $class->fields,
        $class->table,
        "WHERE client_id = $client_id" . $active_clause,
        'ORDER BY verif_date'
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_byclient {
    my $class = shift;
    return unless my $hashrefs = $class->list_byclient( @_ );

    my @results;
    push @results, $class->new( $_ ) for @$hashrefs;
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# overriding save to insert verify log
sub save {
    my $self = shift;

    my $rc = 0; # this seems meaningless --hdp
    $self->db->transaction_do(sub {
        my $previous = ref($self)->new( { rec_id => $self->id } )->retrieve;

        $rc = $self->SUPER::save;

        if ($rc) {
            $rc = $self->verify($previous);
        }
    });

    return $rc; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 verify()

Logs an entry in the audit trail if this verification has been updated.

=cut

sub verify {
    my $self = shift;
    my( $previous ) = @_;

    return unless $previous;
    die "Wrong rec_id ".$previous->rec_id
        if $previous->rec_id && $previous->rec_id != $self->rec_id;

    if ( $previous->apid_num != $self->apid_num ||
         $previous->verif_date ne $self->verif_date ||
         $previous->rolodex_treaters_id != $self->rolodex_treaters_id ) {
        
        my $rolodex = $self->rolodex;
        my $doctor = $rolodex ? $rolodex->lname : '';
        eleMentalClinic::Auditor->new->audit(
            $self->client_id,
            "VERIFIED",
            "APID: ".$self->apid_num.", Date: ".$self->verif_date.", Doctor: $doctor",
        );
    }
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
