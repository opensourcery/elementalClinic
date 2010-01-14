# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 129;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Client::AssessmentOld;

our ($CLASS, $one, $two, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Assessment';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;

    return unless shift;

    $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'client_assessment' );
    is( $one->primary_key, 'rec_id' );
    is_deeply( $one->fields, [ qw/
        rec_id assessment_date client_id template_id start_date end_date staff_id 
    /]);
    is_deeply( [ sort @{ $CLASS->fields } ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( $one = $CLASS->retrieve( 1002 ));
    is_deeply(
        $one->assessment_fields,
        [
           $client_assessment_field->{1001},
           $client_assessment_field->{1002},
           $client_assessment_field->{1003},
           $client_assessment_field->{1004},
           $client_assessment_field->{1005},
           $client_assessment_field->{1006},
           $client_assessment_field->{1007},
           $client_assessment_field->{1008},
           $client_assessment_field->{1009},
           $client_assessment_field->{1010},
           $client_assessment_field->{1090},
        ]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# new_from_old

    # Sanity checks on the translator.
    ok( not $one->translate_old_field( 'fake' ));
    ok( not $one->translate_old_field );

    is( @{ $one->new_fields }, @{ $one->old_fields }, "Do the new and the old fields line up?" );

    # Useful for debugging, left in but commented:
    #my $oldf = $one->old_fields;
    #my $newf = $one->new_fields;
    #while( my $old = pop(@{ $oldf })) {
    #    print STDERR $old . "\t|\t" . pop( @{ $newf }) . "\n";
    #}

    my $old = eleMentalClinic::Client::AssessmentOld->retrieve( 1001 );
    ok( $one = $CLASS->new_from_old( $old ));
    for my $field ( @{ $old->fields }) {
        my $new_field = $CLASS->translate_old_field( $field );
        next unless $new_field;
        my $field_id = eleMentalClinic::Client::AssessmentTemplate::Field->get_one_by_( 'label', $new_field )->id;
        my $newfield = eleMentalClinic::Client::Assessment::Field->get_one_by_assessment_and_template_field( $one, $field_id );
        is( $newfield->value, $old->$field );
    }
    is( $one->start_date, $old->start_date );
    is( $one->end_date, $old->end_date );
    is( $one->client_id, $old->client_id );

    # Check for consistancy
    # verify that it works as an object method as well as a class method.
    ok( $tmp = $one->new_from_old( $old ));
    is_deeply_except({ rec_id => undef }, $one, $tmp );


    sub get_field {
        my ( $assessment, $label ) = @_;
        return unless $label;
        my $template_field = eleMentalClinic::Client::AssessmentTemplate::Field->get_one_by_( 'label', $label );
        return eleMentalClinic::Client::Assessment::Field->get_one_by_assessment_and_template_field( $one, $template_field );
    }
    # I chose several values for comparison to make sure things line up.
    is( get_field( $one, 'Affect' )->value,      $old->affect );
    is( get_field( $one, 'Appearance' )->value,  $old->appearance );
    is( get_field( $one, 'Blocking' )->value,    $old->blocking );
    is( get_field( $one, 'Coherency' )->value,    $old->coherent );
    is( get_field( $one, 'Delusions' )->value,   $old->delusions );
    is( get_field( $one, 'Echolalia' )->value,   $old->echolalia );
    is( get_field( $one, 'Insight' )->value,     $old->insight );
    is( get_field( $one, 'Judgement' )->value,   $old->judgement );
    is( get_field( $one, 'Relevency' )->value,   $old->relevant );
    is( get_field( $one, 'Speech flow' )->value, $old->speech_flow );
    is( get_field( $one, 'Danger to self' )->value,  $old->danger_self );
    is( get_field( $one, 'Birth history' )->value,   $old->history_birth );
    is( get_field( $one, 'Impulse control' )->value, $old->impulse_control );
    is( get_field( $one, 'Intelligence' )->value,    $old->intelligence );
    is( get_field( $one, 'Homicidal ideation' )->value,     $old->homicidal );
    is( get_field( $one, 'Speech tone/volume' )->value,     $old->speech_tone );
    is( get_field( $one, 'Psychomotor activity' )->value,   $old->psycho_motor );
    is( get_field( $one, 'Drug/alcahol abuse' )->value, $old->chemical_abuse );
    is( get_field( $one, 'Admission reason' )->value,   $old->admit_reason );
    is( get_field( $one, 'Danger to others' )->value,   $old->danger_others );
    is( get_field( $one, 'Early childhood diseases' )->value,    $old->history_child );
    is( get_field( $one, 'Medical vulnerabilities' )->value, $old->medical_limits );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# active_alerts

    my $old_rec_id = $one->rec_id;

    $one = $CLASS->retrieve( $old_rec_id );
    is( @{ $one->active_alerts }, 4 );
    
    $one = $CLASS->retrieve( 1002 );
    is_deeply(
        $one->active_alerts,
        [
            $client_assessment_field->{1006},
            $client_assessment_field->{1008},
            $client_assessment_field->{1009},
            $client_assessment_field->{1010},
        ],
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# active_alerts
    sub build_field {    
        return eleMentalClinic::Client::Assessment::Field->new({ 
            client_assessment_id => $one->rec_id,
            template_field_id    => shift,
        });
    }

    $one = $CLASS->retrieve( 1002 );
    is_deeply(
        $one->all_fields,
        {
            1010 => [
                $client_assessment_field->{1001},
                $client_assessment_field->{1002},
                $client_assessment_field->{1003},
                $client_assessment_field->{1004},
                $client_assessment_field->{1005},
            ],
            1011 => [
                $client_assessment_field->{1006},
                $client_assessment_field->{1007},
                $client_assessment_field->{1008},
                $client_assessment_field->{1009},
                $client_assessment_field->{1010},
                $client_assessment_field->{1090},
            ],
        }
    );

    $one = $CLASS->new({ 
        client_id => 1002, 
        template_id => 1006,
        staff_id => 1001,
        start_date => '2007-01-01',
        end_date => '2008-01-01',
    });
    $one->save;
    is_deeply(
        $one->all_fields,
        {
            1010 => [
                build_field( 1101 ),
                build_field( 1102 ),
                build_field( 1103 ),
                build_field( 1104 ),
                build_field( 1105 ),
            ],
            1011 => [
                build_field( 1106 ),
                build_field( 1107 ),
                build_field( 1108 ),
                build_field( 1109 ),
                build_field( 1110 ),
                build_field( 1111 ),
            ],
        }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# all_fields    

# all_fields was failing if there was an empty section, this test is for that

#Create the template
#{{{
my $template = eleMentalClinic::Client::AssessmentTemplate->new({
    name => 'empty test',
    staff_id => 1001,
});
$template->save;

#Create a section that will have a field
my $section1 = eleMentalClinic::Client::AssessmentTemplate::Section->new({
    assessment_template_id => $template->id,
    label => 'Populated',
});
$section1->save;

#Create a field for the section
my $field = eleMentalClinic::Client::AssessmentTemplate::Field->new({
    label => 'A Field',
    assessment_template_section_id => $section1->id,
});
$field->save;

# Create a section with no fields
my $section2 = eleMentalClinic::Client::AssessmentTemplate::Section->new({
    assessment_template_id => $template->id,
    label => 'Empty',
});
$section2->save;

#Activate the new template
$template->set_active;
#}}}
# Create the assessment
$one = $CLASS->new({
    client_id => 1001,
    template_id => $template->id,
    staff_id => 1001,
    start_date => '2007-01-01',
    end_date => '2008-01-01',
});
$one->save;

# Make sure everything works.
is_deeply(
    $one->all_fields,
    {
        $section1->id => [
            eleMentalClinic::Client::Assessment::Field->new({
                template_field_id => $field->id,
                client_assessment_id => $one->id,
            }),
        ],
        $section2->id => [],
    }
);

dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_staff_all

ok( not $one->get_staff_all );
is_deeply(
    sort_objects( $one->get_staff_all({ staff_id => 1001 })),
    [
        $client_assessment->{ 1002 },
        $client_assessment->{ 1003 },
        $client_assessment->{ 1004 },
        $client_assessment->{ 1005 },
        $client_assessment->{ 1006 },
        $client_assessment->{ 1007 },
        $client_assessment->{ 1008 },
    ]
);

is_deeply( 
    $one->get_staff_all({ staff_id => 1001, year_old => 1 }),
    [
        $client_assessment->{ 1003 },
        $client_assessment->{ 1004 },
        $client_assessment->{ 1005 },
    ]
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( 1 );

sub make_assessment {
    my $params = shift;
    my $assessment = eleMentalClinic::Client::Assessment->new({
        client_id   => 1005,
        template_id => 1006,
        staff_id    => 1001,
        %$params,
    });
    $assessment->save;
    return eleMentalClinic::Client::Assessment->retrieve( $assessment->id );
}

my $sorted = [
    #Open (until 2027 anyway)
    { start_date => '2008-05-01', end_date => '2027-06-01' },
    { start_date => '2008-04-01', end_date => '2027-05-01' },
    { start_date => '2008-04-01', end_date => '2027-05-01' }, #Duplicate start, sort by rec_id
    { start_date => '2008-03-01', end_date => '2027-04-01' },
    { start_date => '2008-02-01', end_date => '2027-03-01' },
    { start_date => '2008-01-01', end_date => '2027-02-01' },

    #Closed
    { start_date => '2007-05-01', end_date => '2007-06-01' },
    { start_date => '2007-04-01', end_date => '2007-05-01' },
    { start_date => '2007-04-01', end_date => '2007-05-01' }, #Duplicate start, make sure sorted by rec_id
    { start_date => '2007-03-01', end_date => '2007-04-01' },
    { start_date => '2007-02-01', end_date => '2007-03-01' },
    { start_date => '2007-01-01', end_date => '2007-02-01' },
];

#Make the assessments.
$_ = make_assessment( $_ ) for ( @$sorted );

### Swap the duplicates so that newer rec id comes first.
( $sorted->[1], $sorted->[2] ) = ( $sorted->[2], $sorted->[1] );
( $sorted->[7], $sorted->[8] ) = ( $sorted->[8], $sorted->[7] );

#Randomise the list
my $unsorted = [ @$sorted ];
$unsorted = [ sort { int(rand(2)) ? 1 : -1 } @$unsorted ]; 

is_deeply(
    [ sort { eleMentalClinic::Client::Assessment::assessment_sort($a, $b) } @$unsorted ],
    $sorted
);

is_deeply(
    eleMentalClinic::Client::Assessment->get_all_by_client( 1005 ),
    $sorted
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( 1 );

#{{{
$template = eleMentalClinic::Client::AssessmentTemplate->new({
    name => 'No Alerts section',
    staff_id => 1001,
});
$template->save;
#Activate the new template
$template->set_active;
#}}}
# Create the assessment
$one = $CLASS->new({
    client_id => 1001,
    template_id => $template->id,
    staff_id => 1001,
    start_date => '2007-01-01',
    end_date => '2008-01-01',
});
$one->save;
ok( $one->active_alerts );

#{{{
$template = eleMentalClinic::Client::AssessmentTemplate->new({
    name => 'No Alerts',
    staff_id => 1001,
});
$template->save;

#Create an empty alerts section
$section1 = eleMentalClinic::Client::AssessmentTemplate::Section->new({
    assessment_template_id => $template->id,
    label => 'Alerts',
});
$section1->save;

#Activate the new template
$template->set_active;
#}}}
# Create the assessment
$one = $CLASS->new({
    client_id => 1001,
    template_id => $template->id,
    staff_id => 1001,
    start_date => '2007-01-01',
    end_date => '2008-01-01',
});
$one->save;
ok( $one->active_alerts );

#{{{ Test for #798 no sections, empty template.
$template = eleMentalClinic::Client::AssessmentTemplate->new({
    name => 'No Sections',
    staff_id => 1001,
});
$template->save;
is_deeply( $template->sections_view, [] );

#Activate the new template
$template->set_active;
#}}}
# Create the assessment
$one = $CLASS->new({
    client_id => 1001,
    template_id => $template->id,
    staff_id => 1001,
    start_date => '2007-01-01',
    end_date => '2008-01-01',
});
ok( $one->save );
ok( $one->active_alerts );
ok( $one->all_fields );

dbinit( );

