package eleMentalClinic::Client::Assessment;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Assessment

=head1 SYNOPSIS

New Client mental health assessment.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::Client::Assessment::Field;
use eleMentalClinic::Client::AssessmentTemplate;
use Date::Calc;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub table { 'client_assessment' }
sub primary_key { 'rec_id' }
sub fields {[ qw/ rec_id assessment_date client_id template_id start_date end_date staff_id / ]}

sub accessors_retrieve_many {
    {
        assessment_fields => { client_assessment_id => 'eleMentalClinic::Client::Assessment::Field' },
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 new_from_old()

Class method.

Converts an old style assessment to a new one, this should only be used for migrating data.
This function will automatically save the assessment and all fields.

Returns the new assessment.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub new_from_old {
    my $class = shift;
    $class = ref $class || $class;
    my ( $old ) = @_;

    my $template = eleMentalClinic::Client::AssessmentTemplate->get_one_by_( 'name', 'General Assessments' );

    my $new = $class->new({
        assessment_date => $old->start_date,
        client_id => $old->client_id,
        template_id => $template->id,
        start_date => $old->start_date,
        end_date => $old->end_date,
        staff_id => $old->staff_id,
    });
    $new->save;

    for my $field ( @{ $old->fields }) {
        my $new_field = $class->translate_old_field( $field );
        next unless $new_field;
        my $field_id = eleMentalClinic::Client::AssessmentTemplate::Field->get_one_by_( 'label', $new_field )->id;
        eleMentalClinic::Client::Assessment::Field->new({
            client_assessment_id => $new->rec_id,
            template_field_id => $field_id,
            value => $old->$field,
        })->save;
    }
    return $class->retrieve( $new->rec_id );
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 active_alerts()

Object method.

Get a list of alerts for the client. An active alert is one that has data.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub active_alerts {
    my $self = shift;
    my $alerts = [];

    my $section = $self->template->get_alerts_section;
    return $alerts unless $section and $section->section_fields;

    for my $template_field ( @{ $self->template->get_alerts_section->section_fields }) {
        my $assessment_field = eleMentalClinic::Client::Assessment::Field->get_one_by_assessment_and_template_field(
           $self,
           $template_field
        );
        push( @$alerts, $assessment_field )
          if $assessment_field
          and $assessment_field->value
          and lc($assessment_field->value) ne 'n/a';
    }

    return $alerts;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 template()

Object method.

returns the template this assessment was generated from.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub template {
    my $self = shift;
    return eleMentalClinic::Client::AssessmentTemplate->retrieve( $self->template_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 all_fields()

Object method.

returns a data structure containing all fields for each section seperated by section
where the section id is the first index. Fields are sorted by position.
example:
{
    1001 => [ #Section ID
        eleMentalClinic::Client::Assessment::Field{ rec_id => 1001 },
        eleMentalClinic::Client::Assessment::Field{ rec_id => 1002 },
        # If this assessment has a template field that is not filled in then
        # It will return a new Field object
        eleMentalClinic::Client::Assessment::Field->new,
        eleMentalClinic::Client::Assessment::Field{ rec_id => 1004 },
    ],
    1002 => [ #Section ID
        eleMentalClinic::Client::Assessment::Field{ rec_id => 1005 },
        eleMentalClinic::Client::Assessment::Field{ rec_id => 1006 },
    ],
};

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub all_fields {
    my $self = shift;
    my $out = {};
    foreach my $section ( @{ $self->template->sections || [] }) {
        $out->{ $section->id } = [];
        my $fields = $section->section_fields;
        next unless $fields;
        $fields = [( sort { $a->position <=> $b->position } @$fields )] if (@$fields > 1);

        foreach my $field ( @{$fields} ) {
            my $a_field = eleMentalClinic::Client::Assessment::Field->get_one_by_assessment_and_template_field(
                $self,
                $field,
            );
            # Create a new field object if none was found
            $a_field = eleMentalClinic::Client::Assessment::Field->new({
                client_assessment_id => $self->id,
                template_field_id => $field->id,
            }) unless $a_field;
            push( @{ $out->{ $section->id }}, $a_field );
        }
    }
    return $out;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_all_by_client()

Object method.

Override the get_all_by_client from base to sort the results.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_all_by_client {
    my $self = shift;
    my ( $client_id ) = @_;

    my $list = $self->get_by_( 'client_id', $client_id );
    return [] unless $list;

    #ORDER BY is insufficient to sort this list, so we sort w/ a custom algorithm:

    $list = [ sort { assessment_sort($a, $b) } @$list ];

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 assessment_sort()

Class method.

Sort algorithm for assessments.
Open come before closed
most recent start date comes first
rec_id if multiple have the same start date.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub assessment_sort {
    my ( $a, $b ) = @_;
    my $now = time();

    my $astart = Date::Calc::Mktime(split(/-/, $a->start_date), 0, 0, 0 );
    my $aend   = Date::Calc::Mktime(split(/-/, $a->end_date), 0, 0, 0 );
    my $aopen  = ($aend > $now && $now >= $astart) ? 1 : 0;

    my $bstart = Date::Calc::Mktime(split(/-/, $b->start_date), 0, 0, 0 );
    my $bend   = Date::Calc::Mktime(split(/-/, $b->end_date), 0, 0, 0 );
    my $bopen  = ($bend > $now && $now >= $bstart) ? 1 : 0;

    # If only one of the assessments is open then the open one is 'higher'
    if ( $aopen or $bopen ) {
        return -1 if ($aopen and not $bopen);
        return 1 if ($bopen and not $aopen);
    }

    #If they are both open/closed then order by start date
    return -1 if ($astart > $bstart);
    return 1 if ($bstart > $astart);

    #If they have the same start date order by the record ID
    return ( $b->rec_id <=> $a->rec_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 translate_old_field()

Object or Class method.

Translates a DB field label in an old assessment to a
record ID in the default assessment template.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub translate_old_field {
    my $self = shift;
    my ( $label ) = @_;
    return unless $label;
    my %translator;

    my @old_fields = @{ $self->old_fields };
    my @new_fields = @{ $self->new_fields };

    while ( my $old = pop( @old_fields )) {
        $translator{ $old } = pop( @new_fields );
    }
    return $translator{ $label };
}

# The order of fields in this list needs to be the same as their counterparts in the default template
sub old_fields {
    return [ qw/
        admit_reason refer_reason social_environ danger_others danger_self chemical_abuse physical_abuse
        side_effects sharps_disposal special_diet alert_medical alert_other alert_note history_birth
        history_child history_milestone history_school history_social history_sexual history_dating
        medical_strengths medical_limits history_diag illness_past illness_family history_dental
        nutrition_needs psycho_motor speech_tone impulse_control speech_flow mood affect orientation
        functional relevant coherent judgement insight intelligence tangential circumstantial blocking
        neologisms word_salad perseveration echolalia delusions hallucination suicidal homicidal obsessive
        memory_recent memory_remote appearance manner mood_note thought_content present_problem psych_history
        homeless_history social_portrait work_history social_skills mica_history social_strengths
        financial_status legal_status military_history spiritual_orient
    / ];
}
sub new_fields {
    return [
        'Admission reason', 'Referral reason', 'Social environment', 'Danger to others', 'Danger to self',
        'Drug/alcahol abuse', 'Physical/sexual abuse', 'Medication side effects', 'Needle disposal',
        'Special dietary needs', 'Medical conditions/problems', 'Other alerts', 'Notes', 'Birth history',
        'Early childhood diseases', 'Milestone asjustments', 'Education history', 'Social/relationship history',
        'Psychosexual history', 'Dating History', 'Medical strengths/proactivity', 'Medical vulnerabilities',
        'Diagnosis history for all physical disorders', 'History of past illnesses', 'Significant family illnesses',
        'Dental history', 'Nutritional assessment/needs', 'Psychomotor activity', 'Speech tone/volume', 'Impulse control',
        'Speech flow', 'Mood', 'Affect', 'Orientation', 'Functional State', 'Relevency', 'Coherency', 'Judgement',
        'Insight', 'Intelligence', 'Tangentiality', 'Circumstantiality', 'Blocking', 'Neologisms', 'Word salad',
        'Perseveration', 'Echolalia', 'Delusions', 'Hallucination', 'Suicidal ideation', 'Homicidal ideation',
        'Obsession', 'Recent memory impairment', 'Remote memory impairment', 'Appearance', 'Manner',
        'Mood and affect notes/description', 'Thought content notes/description',
        'Most recent difficulties/precipitating events', 'Past psychiatric history', 'History of homelessness',
        'Patient description', 'Work history', 'Social functioning', 'Addictive behaviors', 'Social strengths',
        'Financial status', 'Legal status', 'Military service history', 'Religious/spiritual/cultural orientation',
    ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This function was copied from the old assessment, now AssessmentOld.pm
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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub create_or_update {
    my $class = shift;
    my %params = @_;

    my $fields = delete $params{ fields };
    my $self = $params{ rec_id } ? $class->retrieve( $params{ rec_id })
                                 : $class->new( \%params );

    $self->start_date( $params{ start_date });
    $self->end_date( $params{ end_date });
    $self->save;

    for my $field_proto ( @$fields ) {
        # get the existing field if there is one.
        my $field = eleMentalClinic::Client::Assessment::Field->get_one_by_assessment_and_template_field(
            $self->rec_id,
            $field_proto->{ template_field_id },
        );

        if( $field and $field->rec_id ) {
            $field->value( $field_proto->{ value });
        }
        else {
            $field = eleMentalClinic::Client::Assessment::Field->new({
                %$field_proto,
                client_assessment_id => $self->rec_id,
            });
        }

        $field->save;
    }

    return $self;
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2008 OpenSourcery, LLC

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
