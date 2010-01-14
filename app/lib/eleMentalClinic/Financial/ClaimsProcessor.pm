package eleMentalClinic::Financial::ClaimsProcessor;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::ClaimsProcessor

=head1 SYNOPSIS

Processes an EDI document on behalf of an insurer.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use Date::Calc qw/ Today Delta_Days Add_Delta_Days /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'claims_processor' }
    sub fields { [ qw/
        rec_id interchange_id_qualifier interchange_id
        code name primary_id clinic_trading_partner_id
        clinic_submitter_id
        requires_rendering_provider_ids template_837
        password_active_days password_expires password_min_char 
        username password sftp_host sftp_port
        dialup_number get_directory put_directory send_personnel_id
        send_production_files
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_by_password_expiration {
    my $class = shift;
    my( $date ) = @_;

    $date ||= join '-' => Today;
    return unless
        my $processors = $class->new->db->select_many(
            $class->fields,
            $class->table,
            qq/ WHERE DATE( password_expires ) <= DATE( '$date' ) /,
            'ORDER BY DATE( password_expires ) ASC, rec_id',
        );
    return[ map{ $class->new( $_ )} @$processors ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 password_expired([ $date ])

Object method.

If the object's transmission credentials have expired, returns the number of days since expiration (which will evaluate to true).  Otherwise returns 0.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub password_expired {
    my $self = shift;
    my( $date ) = @_;

    return unless $self->password_expires;
    $date ||= join '-' => $self->today;

# print STDERR Dumper[ $date, $self->password_expires ];

    my $delta = Delta_Days(
        ( split /-/ => $self->password_expires ),
        ( split /-/ => $date ),
    );
    return 0
        unless $delta > 0;
    return $delta;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 save()

Object method.

Overrides L<eleMentalClinic::Base>'s C<save()> method.  Updates the C<password_expires> date field if the password was changed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub save {
    my $self = shift;

    for( $self ) {
        next unless $self->id;
        next unless $self->password;
        next unless $self->password_active_days;

        my $class = ref $self;
        my $current = $class->retrieve( $self->id );
        next if $self->password eq $current->password;

        $self->password_expires( join '-' => Add_Delta_Days( Today, $self->password_active_days ));
    }
    $self->SUPER::save;
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

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
