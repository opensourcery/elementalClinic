package eleMentalClinic::Client::Discharge;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Discharge

=head1 SYNOPSIS

Client discharge record, and basic after-care notes.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Client::Placement::Object /;
use eleMentalClinic::Client::Diagnosis;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_discharge' }
    sub fields { [ qw/
        rec_id client_id chart_id
        staff_name physician initial_diag_id
        final_diag_id admit_note history_clinical
        history_psych history_medical discharge_note
        after_care addr addr_2 city state post_code
        phone ref_agency ref_cont ref_date sent_summary
        sent_psycho_social sent_mental_stat sent_tx_plan
        sent_other sent_to sent_physical esof_id
        esof_date esof_name esof_note last_contact_date
        termination_notice_sent_date
        client_contests_termination education income
        employment_status employability_factor
        criminal_justice termination_reason
        audit_trail committed
        client_placement_event_id
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub initial_diagnosis {
    my $self = shift;

    return unless $self->initial_diag_id;
    return eleMentalClinic::Client::Diagnosis->new({ rec_id => $self->initial_diag_id })->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub final_diagnosis {
    my $self = shift;

    return unless $self->final_diag_id;
    return eleMentalClinic::Client::Diagnosis->new({ rec_id => $self->final_diag_id })->retrieve;
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
