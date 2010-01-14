package eleMentalClinic::Client::Insurance;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Insurance

=head1 SYNOPSIS

Client insurance relationship and history records, join between rolodex insurance tables and client.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::ValidData;
use eleMentalClinic::Rolodex;
use eleMentalClinic::Client::Insurance::Authorization;
use eleMentalClinic::Util;
use Date::Calc qw/ Date_to_Days /;
use Data::Dumper;


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_insurance' }
    sub fields { [ qw/ 
        rec_id client_id rolodex_insurance_id rank
        carrier_type carrier_contact
        insurance_name insurance_id patient_insurance_id
        insured_name insured_fname insured_lname
        insured_mname insured_name_suffix
        insured_relationship_id insured_addr
        insured_addr2 insured_city insured_state insured_postcode
        insured_phone insured_group insured_group_id insured_dob
        insured_sex insured_employer insurance_type_id
        other_plan other_name other_group other_dob 
        other_sex other_employer other_plan_name
        co_pay_amount
        deductible_amount license_required 
        comment_text start_date end_date
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub contact {
    my $self = shift;
    $self->rolodex(@_);
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 active_insurance_clause([ $date, $active ])

Class method.

Returns part of an SQL C<WHERE> clause to filter Insurance entries by date and
catch only ones which we consider 'active.'  This is a separate routine since
it's used in at least two place, and is error-prone.

If C<$date> is not supplied, the current date will be used.

If C<$active> is supplied and is false, C<NOT> is prepended to the C<WHERE>
clause so that inactive insurers are selected.

NOTE that the SQL part returned disambiguates the C<start_date> and C<end_date>
columns by prepending C<client_insurance.>.  If this conflicts with an alias in
a calling subroutine, the two options are:

=over 4

=item Refactor this routine to accept an optional table name/alias,

=item Refactor the calling routine to use the full table name.

=back

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub active_insurance_clause {
    my $class = shift;
    my( $date, $active ) = @_;

    $date ||= $class->today;
    my $query = qq/date( '$date' ) >= client_insurance.start_date
        AND( client_insurance.end_date IS NULL OR date( '$date' ) <= client_insurance.end_date )/;
    return ( defined $active and not $active )
        ? qq/ AND NOT( $query )/
        : qq/ AND $query/;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub mh_provider {
    my $class = shift;
    my( $client_id, $date ) = @_;
    return unless $client_id and $date;

    my $where = qq/
        client_id = $client_id 
        AND carrier_type = 'mental health' 
    /;
    $where .= $class->active_insurance_clause( $date );
    my $other = 'ORDER BY start_date desc LIMIT 1';
    return unless
        my $hashref = $class->db->select_one(
            $class->fields,
            $class->table,
            $where,
            $other
        );
    $class->new( $hashref );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 getall_bytype( $client_id, $type )

Class method.

Returns all C<eleMentalClinic::Insurance> objects associated with C<$client_id>
and C<$type>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub getall_bytype {
    my $class = shift;
    my( $client_id, $type, $active ) = @_;

    die 'Client id and type are required'
        unless $client_id and $type;
    
    my $where = "WHERE client_id = $client_id AND carrier_type = '$type'";
    $where .= $class->active_insurance_clause( undef, $active )
        if defined $active;
    my $order = 'ORDER BY rank, start_date, end_date';

    return unless
        my $results = $class->db->select_many( $class->fields, $class->table, $where, $order );
    return [ map{ $class->new( $_ )} @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex_id {
    my $self = shift;
    return unless $self->rolodex_insurance_id and $self->carrier_type;
    my $type = $self->carrier_type . "_insurance";
    $type =~ s/ /_/g;

    my $table = "rolodex_$type";
    my $fields = [qw/ rec_id rolodex_id /];
    my $where = "rec_id = '" . $self->rolodex_insurance_id . "'";

    return unless my $result = $self->db->select_one($fields, $table, $where);
    return $result->{ rolodex_id };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# sub save {
#     my $self = shift;
#     if( $self->rank and $self->carrier_type 
#         and ( $self->rank == 1 or $self->rank == 2 )
#     ) {
#         my $rank = $self->rank;
#         my $client_id = $self->client_id;
#         my $carrier_type = $self->carrier_type;
# 
#         my $where = qq/
#             WHERE client_id = $client_id
#             AND   rank = '$rank'
#             AND   carrier_type = '$carrier_type'
#         /;
#         my $conflicts = $self->db->select_many(
#             $self->fields,
#             $self->table,
#             $where
#         );
#         my $class = ref $self;
#         if( $conflicts ){
#             $class->new($_)->rank( 3 )->save for @$conflicts;
#         }
#     }
#     $self->SUPER::save;
# }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# authorizations
# by default, gets most recent active
# pass $date to get auth for that date
sub authorization {
    my $self = shift;
    my( $date ) = @_;

    return unless $self->id and $self->client_id;
    return eleMentalClinic::Client::Insurance::Authorization->get_by_client_insurance( $self->id, $date );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# authorizations
# gets all in reverse order
sub all_authorizations {
    my $self = shift;

    return unless $self->id and $self->client_id;
    return eleMentalClinic::Client::Insurance::Authorization->get_all_by_client_insurance( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_authorized_insurers( $client_id, [ $carrier_type, $date ])

Class method.

Returns all authorized insurers for C<$client_id>, either all or of
C<$carrier_type>, on today or C<$date>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_authorized_insurers {
    my $class = shift;
    my( $client_id, $carrier_type, $date ) = @_;

    die 'Client id is required'
        unless $client_id;

    $date ||= $class->today;

    my @bind = ($client_id, ($date) x 3);
    my $fields = $class->fields_qualified;
    my $where = '';
    if ($carrier_type) {
        $where = 'AND client_insurance.carrier_type = ?';
        push @bind, $carrier_type;
    }
    my $query = qq/
        SELECT $fields
        FROM client_insurance
            LEFT JOIN client_insurance_authorization ON client_insurance_authorization.client_insurance_id = client_insurance.rec_id
        WHERE client_insurance.client_id = ?
            AND DATE( ? ) between DATE( client_insurance_authorization.start_date ) and DATE( client_insurance_authorization.end_date )
            AND CASE WHEN client_insurance.end_date IS NOT NULL
                THEN DATE( ? ) between DATE( client_insurance.start_date ) AND DATE( client_insurance.end_date )
                ELSE DATE( ? ) >= DATE( client_insurance.start_date )
            END
            $where
    /;
    return unless
        my $insurers = $class->db->fetch_hashref( $query, @bind );
    return[ map{ $class->new( $_ )} @$insurers ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 other_authorized_insurers( $date )

Object method.

Wraps C<get_authorized_insurers()> and removes own record from results, if
applicable.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get the client_insurances for a specific client
# that has an authorization that covers a specific date
# EXCLUDING this here insurance
sub other_authorized_insurers {
    my $self = shift;
    my( $date ) = @_;

    my $type = $self->carrier_type;
    my $client_id = $self->client_id;
    my $client_insurance_id = $self->rec_id;

    return unless $date and $client_id and $type;

    return unless 
        my $insurers = __PACKAGE__->get_authorized_insurers( $client_id, $type, $date );
    # FIXME there must be a better way to do this
    my @cleaned = ();
    for( @$insurers ) {
        push @cleaned => $_
            unless $_->id == $self->id
    }
    return unless @cleaned;
    return \@cleaned;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 is_active()

Object method.

Returns C<1> is object is active on the current date.  Returns C<0> if object
is inactive.

Returns C<undef> if end_date is not defined.  This will still evaluate to
false, but gives us a little granularity.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub is_active {
    my $self = shift;
    my( $date ) = @_;

    $date ||= $self->today;
    return 1 unless defined $self->end_date;

    my $days = Date_to_Days( split /-/ => $date );
    my $start_days = Date_to_Days( split /-/ => $self->start_date );
    my $end_days = Date_to_Days( split /-/ => $self->end_date );

    return 0
        if $start_days gt $days
        or $end_days   lt $days;
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 role_name()

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub role_name {
    my $self = shift;

    return unless
        my $type = $self->carrier_type;
    $type =~s/ /_/g;
    return "${ type }_insurance";
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
