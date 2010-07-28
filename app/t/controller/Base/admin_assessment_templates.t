# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 157;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Client::AssessmentTemplate;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::AdminAssessmentTemplates';
    use_ok( q/eleMentalClinic::Controller::Base::AdminAssessmentTemplates/ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
#    $test->delete_('client_assessment_field', '*');
#    $test->delete_('client_assessment', '*');
#    $test->delete_('assessment_template_fields', '*');
#    $test->delete_('assessment_template_sections', '*');
#    $test->delete_('assessment_templates', '*');
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

sub last_id {
    return eleMentalClinic::DB->new->do_sql( 
        'select last_value from assessment_templates_rec_id_seq' 
    )->[0]->{ last_value };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runmodes
    can_ok( $CLASS, 'ops' );
    ok( my %ops = $CLASS->ops );
    is_deeply( [ sort keys %ops ], [ sort qw/
        save clone_template create delete_template home activate _field _field_remove _section
    /]);
    can_ok( $CLASS, $_ ) for qw/
        save clone_template create delete_template home activate _field _field_remove _section
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Make sure home has the correct assessment, old test before the rest was tested, but does not hurt to keep it.
    for ( 1001 .. 1005 ) {
        $one = $CLASS->new_with_cgi_params(
            assessment_id => $_,
        );
        is_deeply(
            $one->home->{ current_assessment },
            eleMentalClinic::Client::AssessmentTemplate->retrieve( $_ ) 
        );
    }
    $one = $CLASS->new_with_cgi_params();
    is_deeply(
        $one->home->{ current_assessment },
        # Should be the active one if none is specified.
        eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ) 
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# current_assessment

    # by CGI
    $one = $CLASS->new_with_cgi_params(
        assessment_id => 1001,
    );
    is_deeply(
        $one->current_assessment,
        eleMentalClinic::Client::AssessmentTemplate->retrieve( 1001 ) 
    );

    # By parameter
    $one = $CLASS->new;
    is_deeply(
        $one->current_assessment( 1004 ),
        eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 ) 
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home

    $one = $CLASS->new;
    is_deeply(
        $one->home,
        {
            current_assessment      => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessment_intake       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 ),
            assessment_active       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessments_in_progress => eleMentalClinic::Client::AssessmentTemplate->get_in_progress( 'assessment' ),
            assessments_archived    => eleMentalClinic::Client::AssessmentTemplate->get_archived( 'assessment' ),
            part_id                 => '',
            part                    => '',
        }
    );
    is( $one->override_template_name, 'home' );

    $one = $CLASS->new_with_cgi_params(
        assessment_id => 1001,
    );
    is_deeply(
        $one->home,
        {
            current_assessment      => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1001 ),
            assessment_intake       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 ),
            assessment_active       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessments_in_progress => eleMentalClinic::Client::AssessmentTemplate->get_in_progress( 'assessment' ),
            assessments_archived    => eleMentalClinic::Client::AssessmentTemplate->get_archived( 'assessment' ),
            part_id                 => '',
            part                    => '',
        }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clone

    # Re-Running the test, the sequence is not reset, this id changes every time.
    # This lets us grab it and know it for the test.

    $tmp = eleMentalClinic::Client::AssessmentTemplate->retrieve( 1003 );
    $one = $CLASS->new_with_cgi_params(
        op => 'clone_template',
        assessment_id => $tmp->rec_id,
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply(
        $one->clone_template,
        {
            current_assessment      => eleMentalClinic::Client::AssessmentTemplate->retrieve( last_id() ),
            assessment_intake       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 ),
            assessment_active       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessments_in_progress => eleMentalClinic::Client::AssessmentTemplate->get_in_progress( 'assessment' ),
            assessments_archived    => eleMentalClinic::Client::AssessmentTemplate->get_archived( 'assessment' ),
            part_id                 => '',
            part                    => '',
        }
    );
    is( $one->override_template_name, 'home' );

dbinit( 1 ); 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create

    $one = $CLASS->new_with_cgi_params(
        new_name => 'New Template',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply(
        $one->create,
        {
            current_assessment      => eleMentalClinic::Client::AssessmentTemplate->retrieve( last_id() ),
            assessment_intake       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 ),
            assessment_active       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessments_in_progress => eleMentalClinic::Client::AssessmentTemplate->get_in_progress( 'assessment' ),
            assessments_archived    => eleMentalClinic::Client::AssessmentTemplate->get_archived( 'assessment' ),
            part_id                 => '',
            part                    => '',
        }
    );
    is( $one->override_template_name, 'home' );

# Create 2 w/ the same name.
    $one = $CLASS->new_with_cgi_params(
        new_name => 'A',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply(
        $one->create,
        {
            current_assessment      => eleMentalClinic::Client::AssessmentTemplate->retrieve( last_id() ),
            assessment_intake       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 ),
            assessment_active       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessments_in_progress => eleMentalClinic::Client::AssessmentTemplate->get_in_progress( 'assessment' ),
            assessments_archived    => eleMentalClinic::Client::AssessmentTemplate->get_archived( 'assessment' ),
            part_id                 => '',
            part                    => '',
        }
    );
    is( $one->override_template_name, 'home' );

    $one = $CLASS->new_with_cgi_params(
        new_name => 'A',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply(
        $one->create,
        {
                                                       # FIXME: No way to know last ID, uses active.
            current_assessment      => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessment_intake       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 ),
            assessment_active       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessments_in_progress => eleMentalClinic::Client::AssessmentTemplate->get_in_progress( 'assessment' ),
            assessments_archived    => eleMentalClinic::Client::AssessmentTemplate->get_archived( 'assessment' ),
            part_id                 => '',
            part                    => '',
        }
    );
    is( $one->override_template_name, 'home' );
    is_deeply(
        $one->errors,
        [ 'Template: "A" already exists.' ],
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AJAX functions

# _section
    $tmp = eleMentalClinic::Client::AssessmentTemplate->retrieve( last_id() ),
    $one = $CLASS->new_with_cgi_params(
        label         => 'A_Section',
        assessment_id => $tmp->rec_id,
    );
    ok( $one->_section );
    my $section = eleMentalClinic::Client::AssessmentTemplate::Section->get_one_by_( 'label', 'A_Section' );
    is_deeply( 
        $tmp->sections->[1],
        $section
    );
    is( $section->label, 'A_Section' );
    is( $section->position, 1 );
    is( $section->assessment_template_id, $tmp->rec_id );
    # creating the section should create an initial field.
    ok( my $field = $section->section_fields->[0] );
    is( $field->position, 0 );
    is( $field->assessment_template_section_id, $section->rec_id );

# _field
    $one = $CLASS->new_with_cgi_params(
        section_id => $section->rec_id,
    );
    ok( $one->_field );
    ok( $field = $section->section_fields->[1] );
    is( $field->position, 1 );
    is( $field->assessment_template_section_id, $section->rec_id );

    #Create a second field for use in the next test.
    $one = $CLASS->new_with_cgi_params(
        section_id => $section->rec_id,
    );
    ok( $one->_field );
    ok( $field = $section->section_fields->[2] );
    is( $field->position, 2 );
    is( $field->assessment_template_section_id, $section->rec_id );

# _field_remove
    $one = $CLASS->new_with_cgi_params(
        position   => 2,
        section_id => $section->rec_id,
    );
    ok( $one->_field_remove );
    ok( not $field = $section->section_fields->[2] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save

    $tmp = eleMentalClinic::Client::AssessmentTemplate->retrieve( last_id() ),
    $section = $tmp->sections->[1];
    my $fielda = $section->section_fields->[0];
    my $fieldb = $section->section_fields->[1];

    $one = $CLASS->new_with_cgi_params(
        op => 'save',
        assessment_id => $tmp->rec_id,

        'section[0][label]' => 'New Section Label',
        'section[0][position]' => $section->position,
        'section[0][rec_id]' => $section->rec_id,

        'field[0][label]'      => 'New Field Label A',
        'field[0][choices]'      => 'a, b, c', #Optional spaces.
        'field[0][section_id]' => $fielda->assessment_template_section_id,
        'field[0][rec_id]'     => $fielda->rec_id,

        'field[1][label]'      => 'New Field Label B',
        'field[1][choices]'      => 'a,b,c', #Space is optional
        'field[1][section_id]' => $fieldb->assessment_template_section_id,
        'field[1][rec_id]'     => $fieldb->rec_id,
    );
    is_deeply(
        $one->save,
        {
            current_assessment      => { %$tmp, is_intake => 0 },
            assessment_intake       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 ),
            assessment_active       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessments_in_progress => eleMentalClinic::Client::AssessmentTemplate->get_in_progress( 'assessment' ),
            assessments_archived    => eleMentalClinic::Client::AssessmentTemplate->get_archived( 'assessment' ),
            part_id                 => '',
            part                    => '',
        }
    );

    is( $tmp->sections->[1]->label, 'New Section Label' );
    ok( not $tmp->sections->[2] ); #make sure no new records were created for this.
    is_deeply( 
        $tmp->sections->[1]->section_fields->[0],
        {
            label      => 'New Field Label A',
            choices    => 'a, b, c',
            position   => $fielda->position,
            rec_id     => $fielda->rec_id,
            field_type => 'text::words',
            assessment_template_section_id => $fielda->assessment_template_section_id,
        }
    );
    is_deeply( 
        $tmp->sections->[1]->section_fields->[1], 
        {
            label => 'New Field Label B', 
            choices    => 'a,b,c',
            position   => $fieldb->position,
            rec_id     => $fieldb->rec_id,
            field_type => 'text::words',
            assessment_template_section_id => $fieldb->assessment_template_section_id,
        }
    );
    ok( not $tmp->sections->[1]->section_fields->[2] );

    $tmp = eleMentalClinic::Client::AssessmentTemplate->retrieve( last_id() ),
    $section = $tmp->sections->[1];
    $fieldb = $section->section_fields->[1];
    $one = $CLASS->new_with_cgi_params(
        op => 'Save',
        assessment_id => $tmp->rec_id,

        'field[1][label]'   => 'Skipped One',
        'field[1][section_id]' => $fieldb->assessment_template_section_id,
        'field[1][rec_id]'     => $fieldb->rec_id,
        'field[1][choices]'    => 'x,y,z',
    );
    ok( $one->save );
    is_deeply( 
        $tmp->sections->[1]->section_fields->[1], 
        {
            label => 'Skipped One', 
            choices    => 'x,y,z',
            position   => $fieldb->position,
            rec_id     => $fieldb->rec_id,
            field_type => 'text::words',
            assessment_template_section_id => $fieldb->assessment_template_section_id,
        }
    );

    # Saving w/ a new name that is already used.
    $one = $CLASS->new_with_cgi_params(
        op => 'Save',
        assessment_id => 1001,
        name => 'Simple assessment',
    );
    ok( $one->save );
    is_deeply( $one->errors, [ 'Template name "Simple assessment" is taken.' ]);

    dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Complicated save

# Create a template
    $one = $CLASS->new_with_cgi_params(
        new_name => 'New Template',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply(
        $one->create,
        {
            current_assessment      => eleMentalClinic::Client::AssessmentTemplate->retrieve( last_id() ),
            assessment_intake       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 ),
            assessment_active       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessments_in_progress => eleMentalClinic::Client::AssessmentTemplate->get_in_progress( 'assessment' ),
            assessments_archived    => eleMentalClinic::Client::AssessmentTemplate->get_archived( 'assessment' ),
            part_id                 => '',
            part                    => '',
        }
    );
    ok( my $template = eleMentalClinic::Client::AssessmentTemplate->retrieve( last_id() ));

# Create 2 sections    

    $one = $CLASS->new_with_cgi_params(
        label         => 'Section_a',
        assessment_id => $template->rec_id,
    );
    ok( $one->_section );
    ok( my $sectiona = eleMentalClinic::Client::AssessmentTemplate::Section->get_one_by_( 'label', 'Section_a' ));
    is_deeply( 
        $template->sections->[1],
        $sectiona
    );
    is( $sectiona->label, 'Section_a' );
    is( $sectiona->position, 1 );
    is( $sectiona->assessment_template_id, $template->rec_id );
    ok( $field = $sectiona->section_fields->[0] );
    is( $field->position, 0 );
    is( $field->assessment_template_section_id, $sectiona->rec_id );

    $one = $CLASS->new_with_cgi_params(
        label         => 'Section_b',
        assessment_id => $template->rec_id,
    );
    ok( $one->_section );
    ok( my $sectionb = eleMentalClinic::Client::AssessmentTemplate::Section->get_one_by_( 'label', 'Section_b' ));
    is_deeply( 
        $template->sections,
        [ 
            $template->sections->[0], #I know, this is obviously gonna pass, but I do not care about the alerts section for this test.
            $sectiona, 
            $sectionb 
        ]
    );
    is( $sectionb->label, 'Section_b' );
    is( $sectionb->position, 2 );
    is( $sectionb->assessment_template_id, $template->rec_id );
    ok( $field = $sectionb->section_fields->[0] );
    is( $field->position, 0 );
    is( $field->assessment_template_section_id, $sectionb->rec_id );

# Create 3 fields for each section:
    for $section ( $sectiona, $sectionb ) {
        for ( 1 .. 3 ) {
            $one = $CLASS->new_with_cgi_params(
                section_id => $section->rec_id,
            );
            ok( $one->_field );
            ok( $field = $section->section_fields->[$_] );
            is( $field->position, $_ );
            is( $field->assessment_template_section_id, $section->rec_id );
        }
    }

    is( @{ $sectiona->section_fields }, 4 );
    is( @{ $sectionb->section_fields }, 4 );
# Now the massive save!

    $one = $CLASS->new_with_cgi_params(
        op => 'Save',
        assessment_id => $template->rec_id,
        name => $template->name,
        
        # Originally I was going to use 'position' for the index, however this test showed that
        # there would be problems with that idea, so now the view uses 'rec_id' to index objects.
        # For ease of the test though I have used manual indexing.

        'section[0][label]'    => 'Section A Renamed',
        'section[0][rec_id]'   => $sectiona->rec_id,

        # Make sure a section is tested by position
        'section[1][label]'    => 'Section B Renamed',
        'section[1][position]' => $sectionb->position,

        # Make sure a field is tested by position
        'field[0][label]'      => 'Section A Field 0',
        'field[0][section_id]' => $sectiona->section_fields->[0]->assessment_template_section_id,
        'field[0][position]'   => $sectiona->section_fields->[0]->position,
        'field[0][choices]'    => 'a,b,c',

        'field[1][label]'      => 'Section A Field 1',
        'field[1][section_id]' => $sectiona->section_fields->[1]->assessment_template_section_id,
        'field[1][rec_id]'     => $sectiona->section_fields->[1]->rec_id,
        'field[1][choices]'    => 'd,e,f',

        'field[2][label]'      => 'Section A Field 2',
        'field[2][section_id]' => $sectiona->section_fields->[2]->assessment_template_section_id,
        'field[2][rec_id]'     => $sectiona->section_fields->[2]->rec_id,
        'field[2][choices]'    => 'g,h,i',

        'field[3][label]'      => 'Section A Field 3',
        'field[3][section_id]' => $sectiona->section_fields->[3]->assessment_template_section_id,
        'field[3][rec_id]'     => $sectiona->section_fields->[3]->rec_id,
        'field[3][choices]'    => 'j,k,l',

        'field[4][label]'      => 'Section B Field 0',
        'field[4][section_id]' => $sectionb->section_fields->[0]->assessment_template_section_id,
        'field[4][rec_id]'     => $sectionb->section_fields->[0]->rec_id,
        'field[4][choices]'    => 'm,n,o',

        'field[5][label]'      => 'Section B Field 1',
        'field[5][section_id]' => $sectionb->section_fields->[1]->assessment_template_section_id,
        'field[5][rec_id]'     => $sectionb->section_fields->[1]->rec_id,
        'field[5][choices]'    => 'p,q,r',

        'field[6][label]'      => 'Section B Field 2',
        'field[6][section_id]' => $sectionb->section_fields->[2]->assessment_template_section_id,
        'field[6][rec_id]'     => $sectionb->section_fields->[2]->rec_id,
        'field[6][choices]'    => 's,t,u',

        'field[7][label]'      => 'Section B Field 3',
        'field[7][section_id]' => $sectionb->section_fields->[3]->assessment_template_section_id,
        'field[7][rec_id]'     => $sectionb->section_fields->[3]->rec_id,
        'field[7][choices]'    => 'v,w,x',
    );
    is_deeply(
        $one->save,
        {
            current_assessment      => { %$template, is_intake => 0 },
            assessment_intake       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 ),
            assessment_active       => eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 ),
            assessments_in_progress => eleMentalClinic::Client::AssessmentTemplate->get_in_progress( 'assessment' ),
            assessments_archived    => eleMentalClinic::Client::AssessmentTemplate->get_archived( 'assessment' ),
            part_id                 => '',
            part                    => '',
        }
    );
    
    is( @{ $sectiona->section_fields }, 4 );
    is( @{ $sectionb->section_fields }, 4 );

    my $alpha = [( 'a' .. 'z' )];
    my $l;
    for $section ( $sectiona, $sectionb ) {
        $l = $l ? 'B' : 'A';
        # reload the section object
        $section = eleMentalClinic::Client::AssessmentTemplate::Section->retrieve( $section->rec_id );
        is( $section->label, "Section ${l} Renamed" );
        for ( 0 .. 3 ) {
            ok( $field = $section->section_fields->[$_] );
            is_deeply_except({ rec_id => undef },
                $field, 
                {
                    label      => "Section ${l} Field ${_}",
                    # FIXME - There has to be a better way than shifting 3 times.
                    choices    => join( ',', ( shift(@$alpha), shift(@$alpha), shift(@$alpha) )),
                    position   => $_,
                    field_type => 'text::words',
                    assessment_template_section_id => $section->rec_id,
                }
            );
        }
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# activate

    $field = eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 )->sections->[0]->section_fields->[0];
    $one = $CLASS->new_with_cgi_params(
        op => 'Activate',
        assessment_id => 1004,

        'field[0][label]'   => 'A Label',
        'field[0][section_id]' => $field->assessment_template_section_id,
        'field[0][rec_id]'     => $field->rec_id,
        'field[0][choices]'    => 'aa,bb,cc',
    );
    ok( $one->activate );
    $tmp = eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 );
    ok( $tmp->active_start );
    # Make sure activate saves any changes.
    is_deeply(
        $tmp->sections->[0]->section_fields->[0],
        {
            label => 'A Label',
            rec_id => $field->rec_id,
            choices => 'aa,bb,cc',
            position => $field->position,
            field_type => $field->field_type,
            assessment_template_section_id => $field->assessment_template_section_id
        }
    );
    ok( eleMentalClinic::Client::AssessmentTemplate->retrieve( 1006 )->active_end );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# delete
dbinit( 1 );

    # Delete option will only be available in the view on 'in progress'
    # so only they need to be tested
    $one = $CLASS->new_with_cgi_params(
        op => 'Delete',
        assessment_id => 1004,
    );
    is_deeply(
      [ $one->delete_template ],
      [ '', { Location => '/admin_assessment_templates.cgi' } ],
      'redirect after delete',
    );
    ok( not eleMentalClinic::Client::AssessmentTemplate->retrieve( 1004 )->rec_id );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $tmp = eleMentalClinic::Client::AssessmentTemplate->retrieve( 1001 ),
    $section = $tmp->sections->[1];
    $fielda = $section->section_fields->[0];

    # Saving with a blank section label
    $one = $CLASS->new_with_cgi_params(
        op => 'Save',
        assessment_id => $tmp->rec_id,
        name => $tmp->name,

        'section[0][position]' => $section->position,
        'section[0][rec_id]' => $section->rec_id,
    );
    ok( $one->save );
    is_deeply( $one->errors, [ "You must specify a 'label' for each section." ]);

    # Saving with a blank field label
    $one = $CLASS->new_with_cgi_params(
        op => 'Save',
        assessment_id => $tmp->rec_id,
        name => $tmp->name,

        'field[1][section_id]' => $fielda->assessment_template_section_id,
        'field[1][rec_id]'     => $fielda->rec_id,
        'field[1][choices]'    => 'x,y,z',
    );
    ok( $one->save );
    is_deeply( $one->errors, [ "You must specify a 'label' for each field." ]);



dbinit();
