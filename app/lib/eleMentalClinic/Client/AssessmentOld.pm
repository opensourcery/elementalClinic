package eleMentalClinic::Client::AssessmentOld;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::AssessmentOld

=head1 SYNOPSIS

Old Client mental health assessment.

This object is obsolete, it is only here for ease of migration

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_assessment_old' }
    sub primary_key { 'rec_id' }
    sub meta_fields { [ qw/
        rec_id client_id chart_id audit_trail 
    /] }
    sub admit_fields { [ qw/
        admit_reason refer_reason social_environ esof_id 
        esof_date esof_name esof_note start_date end_date staff_id
    /] }
    sub alert_fields { [ qw/
        danger_others danger_self chemical_abuse
        physical_abuse side_effects sharps_disposal
        special_diet alert_medical 
        alert_other alert_note
    /] }
    sub develop_fields { [ qw/
        history_birth history_child history_milestone 
        history_school history_social history_sexual
        history_dating
    /] }
    sub medical_fields { [ qw/
        medical_strengths medical_limits history_diag
        illness_past illness_family history_dental
        nutrition_needs
    /] }
    sub mental_fields { [ qw/
        appearance manner orientation functional mood 
        affect mood_note relevant coherent tangential 
        circumstantial blocking neologisms word_salad 
        perseveration echolalia delusions hallucination 
        suicidal homicidal obsessive thought_content 
        psycho_motor speech_tone impulse_control 
        speech_flow memory_recent memory_remote 
        judgement insight intelligence
    /] }
    sub social_fields { [ qw/
        present_problem psych_history homeless_history
        social_portrait work_history social_skills
        mica_history social_strengths financial_status
        legal_status military_history spiritual_orient
    /] }
    sub fields {
        my $fields;
        push @$fields, @{ &meta_fields };
        push @$fields, @{ &admit_fields };
        push @$fields, @{ &alert_fields };
        push @$fields, @{ &develop_fields };
        push @$fields, @{ &medical_fields };
        push @$fields, @{ &mental_fields };
        push @$fields, @{ &social_fields };
        return $fields;
    }

    sub part_names { [qw/
        admit alert develop medical mental social
    /] }

    sub alert_labels {{
        alert_medical      => 'Medical conditions/problems',
        alert_note         => 'Note',
        alert_other        => 'Other alerts',
        chemical_abuse     => 'Drug/alcohol abuse',
        danger_others      => 'Danger to others',
        danger_self        => 'Danger to self',
        physical_abuse     => 'Physical/sexual abuse',
        sharps_disposal    => 'Sharps disposal',
        side_effects       => 'Medication side effects',
        special_diet       => 'Special dietary needs',
    }}
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    my( $part ) = @_;

    my $id = $self->id;
    if( $id ) {
        return unless $part and $self->valid_part($part);
        my $part_fields = $part . "_fields";
        my $part_values;
        for (@{$self->$part_fields}) {
            push @$part_values, $self->{ $_ };
        }

        $self->db->update_one(
            $self->table,
            $self->$part_fields,
            $part_values,
            "rec_id = $id"
        );
    }
    else {
        #FIXME should call $self->SUPER::save;
        $self->db->obj_insert($self);
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my $self = shift;
    my ( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    my $class = ref $self;
    
    return unless my $hashrefs = $self->list_all($client_id);
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_all {
    my $self = shift;
    my ( $client_id ) = @_;
    return unless $client_id;

    my $where = "WHERE client_id = $client_id";
    my $order_by = 'ORDER BY start_date IS NULL, start_date DESC, rec_id DESC';

    my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_staff_all {
    my $self = shift;
    my $args = shift;
    my $class = ref $self;
    
    my $staff_id = $args->{ staff_id };
    return unless $staff_id;
    
    my $where = "WHERE staff_id = $staff_id";
    $where .= "  AND end_date < ( now() - INTERVAL '1 YEAR') " if $args->{ year_old };
    my $order_by = "ORDER BY start_date DESC";
    
    my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results if @results;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub valid_part {
    my $self = shift;
    my( $part ) = @_;
    return unless $part;

    my $list = $self->part_names;
    for (@$list) {
        return 1 if $part eq $_;
    }
    return 0;
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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# return an arrayref of alert fields in the current assessment
# that have data
sub active_alerts {
    my $self = shift;

    my @alerts;
    for( @{ $self->alert_fields }) {
        push @alerts => $_
            if $self->$_;
    }
    return unless @alerts;
    return [ sort @alerts ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# return an arrayref of alert labels
sub active_alerts_labels {
    my $self = shift;

    return unless my $alerts = $self->active_alerts;
    my @labels;
    for( @$alerts ) {
        push @labels => $self->alert_labels->{ $_ }
    }
    return [ sort @labels ];
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

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
