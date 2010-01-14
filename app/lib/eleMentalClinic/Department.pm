package eleMentalClinic::Department;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Department

=head1 SYNOPSIS

Department object.  To some degree, the parent of all other objects.  Not used as much as it could be.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use Date::Calc qw/ Today Add_Delta_Days /;

use eleMentalClinic::Client;
use eleMentalClinic::ValidData;
use eleMentalClinic::Personnel;
use eleMentalClinic::Financial::ClaimsProcessor;
use eleMentalClinic::Financial::BillingCycle;
use eleMentalClinic::Financial::ValidationSet;
use eleMentalClinic::Log;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub valid_data {
    eleMentalClinic::ValidData->new({ dept_id => 1001 });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_programs {
    my $self = shift;
    my( $type ) = @_;

    my $programs = eleMentalClinic::ValidData->new({ dept_id => 1001 })->list( '_program' );
    # add "full_name" hash key
    @$programs = map { $_ = { %$_, full_name => "($$_{ number }) $$_{ name }" }} @$programs;
    return $programs unless $type;
    # could do another query, but this works for now
    if( $type eq 'referral' ) {
        @$programs = grep { $_->{ is_referral }} @$programs;
    }
    elsif( $type eq 'admission' ) {
        @$programs = grep { not $_->{ is_referral }} @$programs;
    }
    return $programs;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_active_byrole {
    my $self = shift;
    my ( $role ) = @_;
    return [ 
        grep { $_->active }
        @{ eleMentalClinic::Personnel->get_byrole( $role ) || [] }
    ];
}

for my $role (qw(writer service_coordinator supervisor)) {
    no strict 'refs';
    *{"get_${role}s"} = sub { shift->_get_active_byrole( $role ) };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_financial_personnel()

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_financial_personnel {
    my $class = shift;

    return eleMentalClinic::Personnel->get_byrole( 'financial' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dsm4_axis1 {
    my $self = shift;
    return $self->db->select_many(
        [qw/
            rec_id axis name level_num category hdr description
        /],
        'valid_data_dsm4',
        'WHERE axis = 1',
        'ORDER BY name'
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dsm4_axis2 {
    my $self = shift;
    return $self->db->select_many(
        [qw/
            rec_id axis name level_num category hdr description
        /],
        'valid_data_dsm4',
        'WHERE axis = 2',
        'ORDER BY name'
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub claims_processors_with_expired_credentials {
    my $self = shift;
    my( $date ) = @_;

    my $delta = $self->config->cp_credentials_expire_warning || 0;
    $date or $date = join '-' => Today;
    $date = join '-' => Add_Delta_Days(( split /-/ => $date ), $delta );
    return eleMentalClinic::Financial::ClaimsProcessor->get_by_password_expiration( $date );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 earliest_prognote()

Object method.

Returns the C<eleMentalClinic::ProgressNote> object with the earliest
C<start_date> field.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub earliest_prognote {
    my $self = shift;
    return eleMentalClinic::ProgressNote->get_earliest;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub clients {
    my $self = shift;
    return eleMentalClinic::Client->get_all;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub deferred_log {
    my $self = shift;
   
    my $deferred;
    $deferred .= $_
        for @{ eleMentalClinic::Log->Retrieve_deferred };

    return $deferred;
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
