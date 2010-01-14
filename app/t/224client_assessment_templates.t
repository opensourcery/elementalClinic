# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 619;
use Test::Exception;
use Data::Dumper;
use POSIX qw(strftime);
use eleMentalClinic::Test;

my $SET_CLASS = "eleMentalClinic::Client::AssessmentTemplate";
my $SECTION_CLASS = "eleMentalClinic::Client::AssessmentTemplate::Section"; 
my $FIELD_CLASS = "eleMentalClinic::Client::AssessmentTemplate::Field";

our ($CLASS, $one, $two, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::AssessmentTemplate';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    # XXX I don't know why these need to be deleted AFTER a db_refresh -- maybe
    # part of base-sys is unsuitable for this tests? --hdp
    $test->delete_('client_assessment_field', '*');
    $test->delete_('client_assessment', '*');
    $test->delete_('assessment_template_fields', '*');
    $test->delete_('assessment_template_sections', '*');
    $test->delete_('assessment_templates', '*');
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    use_ok($SET_CLASS);
    use_ok($SECTION_CLASS);
    use_ok($FIELD_CLASS);

    # these should all work thanks to the fixtures
    ok ($one = $SET_CLASS->retrieve(1001));
    isa_ok($one, $SET_CLASS);

    ok ($one = $SECTION_CLASS->retrieve(1001));
    isa_ok($one, $SECTION_CLASS);

    ok ($one = $FIELD_CLASS->retrieve(1001));
    isa_ok($one, $FIELD_CLASS);

    # test sections

    ok($one = $SET_CLASS->retrieve(1001));
    can_ok($one, 'sections');

    is(ref($one->sections), 'ARRAY');

    foreach my $section (@{$one->sections}) {
        isa_ok($section, $SECTION_CLASS);
        ok($section->id);
        is($section->assessment_template_id, 1001);
    }

    # this checks the ordering and the field names.
    is_deeply(
        [
            'Admission', 'Alerts', 'Development', 'Medical',
            'Mental',    'Psycho Social'
        ],
        [ map { $_->label } @{ $one->sections } ]
    );

    # test the set of fields. 
    #
    # XXX the map below is actually a (somewhat confusing) double map. the
    # rightmost $_ is a section object from $one->sections, and the innermost
    # $_ is a field object from the original $_->section_fields.
    is_deeply([ map { [ map { $_->label } @{$_->section_fields} ] } @{$one->sections} ], [                                          
        [
            'Admission reason',
            'Referral reason',
            'Social environment'
        ],
        [
            'Danger to others',
            'Danger to self',
            'Drug/alcohol abuse',
            'Medical conditions/problems',
            'Medication side effects',
            'Needle disposal',
            'Notes',
            'Other alerts',
            'Physical/sexual abuse',
            'Special dietary needs'
        ],
        [
            'Birth history',
            'Dating history',
            'Early childhood diseases',
            'Education history',
            'Milestone adjustments',
            'Psychosexual history',
            'Social/relationship history'
        ],
        [
            'Dental history',
            'Diagnosis history for all physical disorders',
            'History of past illnesses',
            'Medical strengths/proactivity',
            'Medical vulnerabilities',
            'Nutritional assessment/needs',
            'Significant family illnesses'
        ],
        [
            'Affect',
            'Appearance',
            'Blocking',
            'Circumstantiality',
            'Coherency',
            'Delusions',
            'Echolalia',
            'Functional state',
            'Hallucination',
            'Homicidal ideation',
            'Impulse control',
            'Insight',
            'Intelligence',
            'Judgement',
            'Manner',
            'Mood and affect notes/description',
            'Mood',
            'Neologisms',
            'Obsession',
            'Orientation',
            'Perseveration',
            'Psychomotor activity',
            'Recent',
            'Relevency',
            'Remote',
            'Speech flow',
            'Speech tone/volume',
            'Suicidal ideation',
            'Tangentiality',
            'Thought content notes/description',
            'Word salad'
        ],
        [
            'Addictive behaviors',
            'Financial status',
            'History of homelessness',
            'Legal status',
            'Military service history',
            'Most recent difficulties/precipitating events',
            'Past psychiatric history',
            'Patient description',
            'Religious/spiritual/cultural orientation',
            'Social functioning',
            'Social strengths',
            'Work history'
        ],
    ]);

    # now a couple of big-ass is_deeply tests

    is_deeply(
        {
            'active_end'    => '2007-05-31 00:00:00',
            'active_start'  => '2007-05-16 00:00:00',
            'created_date'  => '2007-05-15',
            'name'          => 'Default Assessment',
            'rec_id'        => '1001',
            'staff_id'      => '1001',
            'intake_start'  => undef,
            'intake_end'    => undef,
            'is_intake'     => undef,
        },
        $one
    );

    is_deeply(
        [
            {
                'label'           => 'Admission',
                'position'        => '0',
                'rec_id'          => '1001',
                'assessment_template_id' => '1001'
            },
            {
                'label'           => 'Alerts',
                'position'        => '1',
                'rec_id'          => '1002',
                'assessment_template_id' => '1001'
            },
            {
                'label'           => 'Development',
                'position'        => '2',
                'rec_id'          => '1003',
                'assessment_template_id' => '1001'
            },
            {
                'label'           => 'Medical',
                'position'        => '3',
                'rec_id'          => '1004',
                'assessment_template_id' => '1001'
            },
            {
                'label'           => 'Mental',
                'position'        => '4',
                'rec_id'          => '1005',
                'assessment_template_id' => '1001'
            },
            {
                'label'           => 'Psycho Social',
                'position'        => '5',
                'rec_id'          => '1006',
                'assessment_template_id' => '1001'
            },
        ],
        $one->sections
    );

    # test a field for structure integrity
    is_deeply(
        {
            field_type          => 'text::words',
            label               => 'Admission reason',
            position            => '0',
            rec_id              => '1001',
            assessment_template_section_id => '1001',
            choices             => undef,
        }, $one->sections->[0]->section_fields->[0]
    );

    # now test section retrieval
    ok ($one = $SECTION_CLASS->retrieve(1001));
    
    foreach my $field (@{$one->section_fields}) {
        isa_ok($field, $FIELD_CLASS);
        ok($field->id);
        is($field->assessment_template_section_id, 1001);
    }

    # check ordering and labels
    is_deeply( [ 'Admission reason', 'Referral reason', 'Social environment' ],
        [ map { $_->label } @{ $one->section_fields } ] );

    # now test field retrieval

    ok ($one = $FIELD_CLASS->retrieve(1001));
    can_ok($one, 'label');
    is ($one->assessment_template_section_id, 1001);

dbinit(1);

    # test writes

    # these next few tests should fail, as they reference invalid sets or sections

    ok ($one = $FIELD_CLASS->retrieve(1001));
    $one->assessment_template_section_id(1);
    dies_ok { $test->db->transaction_do(sub { $one->save }) };

    ok ($one = $SECTION_CLASS->retrieve(1001));
    $one->assessment_template_id(1);
    dies_ok { $test->db->transaction_do(sub { $one->save }) };

    # create a whole new Client::AssessmentTemplate set from scratch
    # this creates two sections, each with one field in them.
   
    ok ($one = $SET_CLASS->new);

    $one->staff_id(1001);
    $one->name("Monkeys");
    
    lives_ok { $one->save };

    my $set_id = $one->id;

    ok ($one = $SECTION_CLASS->new);

    $one->label("Section 0");
    $one->position(0);
    $one->assessment_template_id($set_id);

    lives_ok { $one->save };

    my $section_id = $one->id;

    ok ($one = $FIELD_CLASS->new);

    $one->label("Field 0");
    $one->position(0);
    $one->assessment_template_section_id($section_id);

    lives_ok { $one->save };

    $two = $one;

    ok ($one = $SECTION_CLASS->new);

    $one->label("Section 1");
    $one->position(1);
    $one->assessment_template_id($set_id);

    lives_ok { $one->save };

    $two->rec_id(undef);
    $two->assessment_template_section_id($one->id);

    lives_ok { $two->save };

    # ok, now retrieve it.
   
    ok ($one = $SET_CLASS->retrieve($set_id));
    isa_ok($one, $SET_CLASS);
    is($one->id, $set_id);

    is_deeply_except({ rec_id => qr/^\d+$/ }, $one, {
        active_end    => undef,
        active_start  => undef,
        created_date  => strftime("%Y-%m-%d", localtime),
        name          => 'Monkeys',
        staff_id      => 1001,
        intake_end    => undef,
        intake_start  => undef,
        is_intake     => undef,
    });

    is_deeply_except({ rec_id => qr/^\d+$/, }, $one->sections, [
        {
            label               => 'Section 0',
            position            => 0,
            assessment_template_id     => $one->id,
        },
        {
            label               => 'Section 1',
            position            => 1,
            assessment_template_id     => $one->id,
        }
    ]);

    is_deeply_except({ rec_id => qr/^\d+$/, }, $one->sections->[ 0 ]->section_fields, [
        {
            field_type          => 'text::words',
            label               => 'Field 0',
            position            => '0',
            assessment_template_section_id => $one->sections->[ 0 ]->id,
            choices             => undef,
        }
    ]);

    is_deeply_except({ rec_id => qr/^\d+$/, }, $one->sections->[ 1 ]->section_fields, [
        {
            field_type          => 'text::words',
            label               => 'Field 0',
            position            => 0,
            rec_id              => 2,
            assessment_template_section_id => $one->sections->[ 1 ]->id,
            choices             => undef,
        }
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# addressing #724, and only that
# TODO these methods needs more tests
    can_ok( $CLASS, 'get_where' );
    can_ok( $CLASS, 'get_active' );
    can_ok( $CLASS, 'get_archived' );
    can_ok( $CLASS, 'get_in_progress' );

    ok( ! $CLASS->get_where );
    ok( $CLASS->get_active );
    ok( $CLASS->get_archived );
    ok( $CLASS->get_in_progress );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit(1);

    # test Client::AssessmentTemplate state-tracking methods 

    # 1002 has no active_start/end, it should not be active and be editable

    ok ($one = $SET_CLASS->retrieve(1002));
    ok ($one->editable);
    ok (!$one->active);

    # 1001 has both an active_start and end, it should not be editable and not be active.
    
    ok ($one = $SET_CLASS->retrieve(1001));
    ok (!$one->editable);
    ok (!$one->active);

    # 1003 has an active_start and no end, it should not be editable and be active.
   
    ok ($one = $SET_CLASS->retrieve(1003));
    ok (!$one->editable);
    ok (!$one->active);

    ok ($one = $SET_CLASS->retrieve(1006));
    ok (!$one->editable);
    ok ($one->active);

    # test the initial list of states...
    is_deeply([1006], [map { $_->id } ( $SET_CLASS->get_active( 'assessment' ))]);
    is_deeply([1001, 1003, 1005, 1007 ], [map { $_->id } @{$SET_CLASS->get_archived('assessment')}]);
    is_deeply([1002], [ map { $_->id } @{$SET_CLASS->get_in_progress('assessment')}]);

    # This sets activating and de-activating.
    # As well this tests setting an active assessment with no current
    # active one, which recently caused a problem.

    # let's change the date to be in the past.
    my @time = localtime;
    $time[4]++;
    @time[5,4,3] = Date::Calc::Add_Delta_Days(@time[5,4,3], -1);
    $time[4]--; 
    $one->active_end(strftime("%Y-%m-%d %H:%M:%S", @time));

    # now it should not be active.
    
    ok(!$one->active); 

    lives_ok { $one->save };

    # it shouldn't be in this list either, now.
    ok( not $SET_CLASS->get_active( 'assessment' ));
    is_deeply([1001, 1003, 1005, 1006, 1007 ], [map { $_->id } @{$SET_CLASS->get_archived('assessment')}]);
    is_deeply([1002], [ map { $_->id } @{$SET_CLASS->get_in_progress('assessment')}]);

    $one->set_active;

    is_deeply([1006], [map { $_->id } ( $SET_CLASS->get_active('assessment'))]);
    is_deeply([1001, 1003, 1005, 1007], [map { $_->id } @{$SET_CLASS->get_archived('assessment')}]);
    is_deeply([1002], [ map { $_->id } @{$SET_CLASS->get_in_progress('assessment')}]);

    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clone

# a test of fields between $one and $tmp is pointless, the db fields such as dates, rec_id,
# and so on are not cloned, that leaves name which must be unique.
sub test_clone {
    my ( $a, $b, $count ) = @_;

    my $name = "Copy of " . $a->name;
    $name .= "-$count" if $count;
    is( $b->name, $name );

    is( $b->staff_id, $a->staff_id );

    is( @{ $b->sections }, @{ $a->sections } );
    for( my $i = 0; $i< @{ $b->sections }; $i++ ) {
        my $original = $a->sections->[$i];
        my $clone = $b->sections->[$i];
        is_deeply_except( 
            { 
                rec_id => undef,
                assessment_template_id => undef,
            },
            $clone,
            $original,
        );

        is( @{ $clone->section_fields }, @{ $original->section_fields } );
        for( my $j = 0; $j < @{ $clone->section_fields }; $j++ ){
            my $original_field = $original->section_fields->[$j];
            my $clone_field = $clone->section_fields->[$j];
            is_deeply_except( 
                { 
                    rec_id => undef,
                    assessment_template_section_id => undef,
                },
                $clone_field,
                $original_field,
            );
        }
    }
}

    $one = $CLASS->retrieve( 1003 );
    ok( $tmp = $one->clone );
    test_clone( $one, $tmp ); 

    $one = $CLASS->retrieve( 1001 );
    ok( $tmp = $CLASS->clone( $one ));
    test_clone( $one, $tmp ); 

    ok( $tmp = $CLASS->clone( 1004 ));
    test_clone( $CLASS->retrieve( 1004 ), $tmp ); 

    #Run the clone 10 times to make sure we do not have a duplicate name error.
    for ( 1 .. 10 ) {
        ok( $tmp = $CLASS->clone( 1004 ));
        test_clone( $CLASS->retrieve( 1004 ), $tmp, $_ ); 
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# name_used

    # as an object method
    $one = $CLASS->retrieve( 1003 );
    ok( $one->name_used( 'Simple assessment' ));
    ok(! $one->name_used( 'Free Name' ));
    ok(! $one->name_used );

    # As a class method
    ok( $CLASS->name_used( 'Simple assessment' ));
    ok(! $CLASS->name_used( 'Free Name' ));
    ok(! $CLASS->name_used );

dbinit(1);
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get Alerts section

    $one = $CLASS->retrieve( 1001 );
    is_deeply(
        $one->get_alerts_section,
        $assessment_template_sections->{ 1002 },
    );

    $one = $CLASS->retrieve( 1002 );
    ok( not $one->get_alerts_section );

    $one = $CLASS->retrieve( 1003 );
    is_deeply(
        $one->get_alerts_section,
        $assessment_template_sections->{ 1008 },
    );

    $one = $CLASS->retrieve( 1004 );
    ok( not $one->get_alerts_section );

    $one = $CLASS->retrieve( 1005 );
    ok( not $one->get_alerts_section );

    $one = $CLASS->retrieve( 1006 );
    is_deeply(
        $one->get_alerts_section,
        $assessment_template_sections->{ 1011 },
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# delete
    # attempt to delete archived (should fail)
    $one = $CLASS->retrieve( 1001 );
    dies_ok { $one->delete };
    ok( $CLASS->retrieve( 1001 ));

    # attempt to delete active (should fail)
    $one = $CLASS->retrieve( 1003 );
    dies_ok { $one->delete };
    ok( $CLASS->retrieve( 1003 ));

    # attempt to delete in progress (should pass)
    $one = $CLASS->retrieve( 1004 );

    # Save lists of sections and fields from this template to verify they go away.
    my $sections = $one->sections;
    my $fields = [];
    push( @$fields, @{ $_->section_fields }) foreach ( @$sections );

    # Delete
    ok( $one->delete );

    # Make sure everything is gone.
    ok( 
        not $FIELD_CLASS->retrieve( $_->rec_id )->rec_id, 
    ) foreach ( @$fields );

    ok( 
        not $SECTION_CLASS->retrieve( $_->rec_id )->rec_id,
    ) foreach ( @$sections );

    ok( not $CLASS->retrieve( 1004 )->rec_id);
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#Create the template
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

is_deeply(
    $template->sections_view,
    [
        eleMentalClinic::Client::AssessmentTemplate::Section->retrieve( $section1->id ),
    ],
);


dbinit(0);
