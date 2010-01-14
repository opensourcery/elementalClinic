# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More skip_all => 'db problems - broken'; #tests => 179;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use Date::Calc;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Default::Assessment';
    require_ok( 'themes/Default/controllers/Assessment.pm' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
#    $test->delete_('client_assessment_field', '*');
#    $test->delete_('client_assessment', '*');
#    $test->delete_('assessment_template_fields', '*');
#    $test->delete_('assessment_template_sections', '*');
#    $test->delete_('assessment_templates', '*');
    $test->db_refresh;

    return unless shift;

    $test->insert_data;

    # This is nasty.
    # Basically the DB is wiped in several places in the test suite, this reloads the default template provided in a migration.
    # I really hate this, and have a feeling it is wrong and needs to be done differently. However
    # I am stuck on figuring out another way atm.
    my $query;
    open( MIGRATION, 'database/schema/411-old-assessment-template.sql' );
    {
        local $/;
        $query = <MIGRATION>;
        $query =~ s/'Default', 1, NOW/'Default', 1001, NOW/ig;
    }
    $CLASS->db->do_sql( $query, 1 );
    close( MIGRATION );

    #Most of these test were originally written w/ 1001 as the active template
    ok( eleMentalClinic::Client::AssessmentTemplate->retrieve( 1001 )->set_active );
}

sub last_id {
    return eleMentalClinic::DB->new->do_sql( 
        'select last_value from client_assessment_rec_id_seq' 
    )->[0]->{ last_value };
}

sub last_template_id {
    return eleMentalClinic::DB->new->do_sql( 
        'select last_value from assessment_templates_rec_id_seq' 
    )->[0]->{ last_value };
}

dbinit( 1 );
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
        home create edit clone print save
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home create edit clone print save
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home

    my $client = eleMentalClinic::Client->retrieve( 1001 );
    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,   
    );
    is_deeply( 
        $one->home,
        {
            current_assessment  => $client_assessment->{ 1002 },
            assessments         => [ $client_assessment->{ 1002 } ],
            action              => 'display',
            part_id             => '',
            part                => '',
            assessments => [ sort{ $b->{ assessment_date } cmp $a->{ assessment_date }} @{ $client->assessment_getall }],
        },
    );

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,   
        assessment_id => 1002,
    );
    is_deeply( 
        $one->home,
        {
            current_assessment  => $client_assessment->{ 1002 },
            assessments         => [ $client_assessment->{ 1002 } ],
            action              => 'display',
            part_id             => '',
            part                => '',
            assessments => [ sort{ $b->{ assessment_date } cmp $a->{ assessment_date }} @{ $client->assessment_getall }],
        },
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create
    
    # Save the old last_id so that we can be sure a new one is created.
    $client = eleMentalClinic::Client->retrieve( 1001 );
    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,   
        op => 'create',
    );
    # Create does not actually make one.
    ok( $one->create );

    # Save is where it is actually created.
    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,   
        op => 'save',
        start_date => '2007-01-01',
        end_date => '2008-01-01',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    my $results;
    ok( $results = $one->save );
    is( $results->{ action }, 'display', "Make sure a successful save returns us to 'display' mode." ); #test fix #793
    # Make sure the new assessment has focus
    is_deeply( 
        $results->{ current_assessment }, 
        eleMentalClinic::Client::Assessment->retrieve( last_id() )
    );

    # Get id, save, get new id, compare. We need to do this after the first save above otherwise the
    # last_id will match the new object invalidating the test. NOTE: This only occurs w/ a clean DB.
    my $tmp = last_id();
    ok( $results = $one->save );
    # Make sure the new assessment has focus
    is_deeply( 
        $results->{ current_assessment }, 
        eleMentalClinic::Client::Assessment->retrieve( last_id() )
    );
    ok( last_id() != $tmp );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# edit

    #No special logic outside the templates.

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save

    $client = eleMentalClinic::Client->retrieve( 1001 );
    #Use the assessment we just created in create()
    my $assessment = eleMentalClinic::Client::Assessment->retrieve( last_id() );
    
    # There are a LOT of fields to set, so we are going to get some values for them:
    # field_[ID if the field in the *TEMPLATE*] => ''
    # We want very predictable/obtainable values.
    my %vars = ();
    for my $section ( @{ $assessment->template->sections }) {
        for my $field ( @{ $section->section_fields }) {
            # If it is a multiple choice field select the second value (first is blank)
            # Otherwise use the label of the section followed by ' Comment ' and the fields ID
            $vars{ 'field[' . $field->id . '][tfield_id]' } = $field->id;
            $vars{ 'field[' . $field->id . '][value]' } = $field->choices ? $field->list_choices->[1]
                                                             : $section->label . " Comment " . $field->id;
        }
    }

    # Make sure the save changes the value of the field instead of creating a new one if the field already
    # has a value:
    $tmp = eleMentalClinic::Client::Assessment::Field->new({
        client_assessment_id => $assessment->id,
        template_field_id    => $assessment->template->sections->[0]->section_fields->[0]->id,
        value                => 'This should go away.',
    });
    $tmp->save;

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,   
        op => 'save',
        assessment_id => $assessment->id,
        start_date           => '2008-07-07',
        end_date             => '2009-07-07',
        %vars
    );

    ok( $one->save );

    $assessment = eleMentalClinic::Client::Assessment->retrieve( $assessment->id );

    # Make sure the assessment has the same number of fields as there are fields in %vars.
    # The number of fields needs to be doubled since the vars contain both value and ID for each.
    is( keys %vars, @{ $assessment->assessment_fields || [] } * 2); #[] is to prevent crashing when there are no fields

    for my $section ( @{ $assessment->template->sections }) {
        for my $field ( @{ $section->section_fields }) {
            my $afield = eleMentalClinic::Client::Assessment::Field->get_one_by_assessment_and_template_field( $assessment, $field );
            ok( $afield );
            is(
                $afield ? $afield->value : 'NO OBJECT', #the ? is so that the test will not die.
                $vars{ 'field[' . $field->id . '][value]' },
                'Save: ' . $section->label . ' ' . $field->label
            );
        }
    }

    $tmp = eleMentalClinic::Client::Assessment::Field->retrieve( $tmp->id );
    ok( $tmp->value ne 'This should go away.' );
    is( $assessment->start_date, '2008-07-07' );
    is( $assessment->end_date, '2009-07-07' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clone

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,   
        op => 'clone',
        assessment_id => $assessment->id,
    );
    is_deeply(
        $one->clone,
        {
            current_assessment  => eleMentalClinic::Client::Assessment->new({
                client_id => $client->id, 
                template_id => eleMentalClinic::Client::AssessmentTemplate->get_active( 'assessment' )->id, 
            }),
            assessments => [ sort{ $b->{ assessment_date } cmp $a->{ assessment_date }} @{ $client->assessment_getall }],
            fields => $assessment->all_fields,
            action => 'edit',
        }
    );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# print

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,   
        op => 'print',
        assessment_id => $assessment->id,
    );
    is_deeply(
        $one->print,
        {
            current_assessment  => $assessment,
            assessments         => [ sort{ $b->{ assessment_date } cmp $a->{ assessment_date }} @{ $client->assessment_getall }],
            clonable            => 1,
            part_id             => '',
            part                => '',
        }
    );
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Save errors, required fields.

    $tmp = eleMentalClinic::Client::AssessmentTemplate->new({
        name => 'Blah',
        staff_id => 1001,
    });
    $tmp->save;
    $tmp->set_active;
    eleMentalClinic::Client::AssessmentTemplate::Section->new({
        label => 'Uhg',
        assessment_template_id => $tmp->id,
    })->save;
    eleMentalClinic::Client::AssessmentTemplate::Field->new({
        label => 'A',
        assessment_template_section_id => $tmp->sections->[0]->id,
    })->save;
    eleMentalClinic::Client::AssessmentTemplate::Field->new({
        label => 'B',
        assessment_template_section_id => $tmp->sections->[0]->id,
    })->save;

    $one = $CLASS->new_with_cgi_params(
        client_id => 1003,   
        op => 'save',
        #start_date           => '2008-07-07',
        end_date             => '2009-07-07',

        'field[0][tfield_id]' => $tmp->sections->[0]->section_fields->[0]->id,
        'field[0][value]'     => 'hi',

        'field[1][tfield_id]' => $tmp->sections->[0]->section_fields->[1]->id,
        'field[1][value]'     => 'bye',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply( 
        $one->save,
        {
            current_assessment => eleMentalClinic::Client::Assessment->new({ 
                end_date => '2009-07-07',
                template_id => $tmp->id,
                client_id => 1003,
                staff_id => 1001,
            }),
            fields => {
                $tmp->sections->[0]->id => [
                    eleMentalClinic::Client::Assessment::Field->new({
                        template_field_id => $tmp->sections->[0]->section_fields->[0]->id,
                        value => 'hi',
                    }),
                    eleMentalClinic::Client::Assessment::Field->new({
                        template_field_id => $tmp->sections->[0]->section_fields->[1]->id,
                        value => 'bye',
                    }),
                ]
            },
            assessments => eleMentalClinic::Client::Assessment->get_all_by_client( 1003 ),
            part_id => '',
            part    => '',
            action  => 'edit',
            op      => 'create',
        }
    );
    is( @{$one->errors}, 1 );

    $one = $CLASS->new_with_cgi_params(
        client_id => 1003,   
        op => 'save',
        start_date           => '2008-07-07',
        #end_date             => '2009-07-07',

        'field[0][tfield_id]' => $tmp->sections->[0]->section_fields->[0]->id,
        'field[0][value]'     => 'hi',

        'field[1][tfield_id]' => $tmp->sections->[0]->section_fields->[1]->id,
        'field[1][value]'     => 'bye',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply( 
        $one->save,
        {
            current_assessment => eleMentalClinic::Client::Assessment->new({ 
                start_date => '2008-07-07',
                template_id => $tmp->id,
                client_id => 1003,
                staff_id => 1001,
            }),
            fields => {
                $tmp->sections->[0]->id => [
                    eleMentalClinic::Client::Assessment::Field->new({
                        template_field_id => $tmp->sections->[0]->section_fields->[0]->id,
                        value => 'hi',
                    }),
                    eleMentalClinic::Client::Assessment::Field->new({
                        template_field_id => $tmp->sections->[0]->section_fields->[1]->id,
                        value => 'bye',
                    }),
                ]
            },
            assessments => eleMentalClinic::Client::Assessment->get_all_by_client( 1003 ),
            part_id => '',
            part    => '',
            action  => 'edit',
            op      => 'create',
        }
    );
    is( @{$one->errors}, 1 );

    $one = $CLASS->new_with_cgi_params(
        client_id => 1003,   
        op => 'save',
        #start_date           => '2008-07-07',
        #end_date             => '2009-07-07',

        'field[0][tfield_id]' => $tmp->sections->[0]->section_fields->[0]->id,
        'field[0][value]'     => 'hi',

        'field[1][tfield_id]' => $tmp->sections->[0]->section_fields->[1]->id,
        'field[1][value]'     => 'bye',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply( 
        $one->save,
        {
            current_assessment => eleMentalClinic::Client::Assessment->new({ 
                template_id => $tmp->id,
                client_id => 1003,
                staff_id => 1001,
            }),
            fields => {
                $tmp->sections->[0]->id => [
                    eleMentalClinic::Client::Assessment::Field->new({
                        template_field_id => $tmp->sections->[0]->section_fields->[0]->id,
                        value => 'hi',
                    }),
                    eleMentalClinic::Client::Assessment::Field->new({
                        template_field_id => $tmp->sections->[0]->section_fields->[1]->id,
                        value => 'bye',
                    }),
                ]
            },
            assessments => eleMentalClinic::Client::Assessment->get_all_by_client( 1003 ),
            part_id => '',
            part    => '',
            action  => 'edit',
            op      => 'create',
        }
    );
    is( @{$one->errors}, 2 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#The following tests require there be no assessment_template's
    $test->delete_('client_assessment_field', '*');
    $test->delete_('client_assessment', '*');
    $test->delete_('assessment_template_fields', '*');
    $test->delete_('assessment_template_sections', '*');
    $test->delete_('assessment_templates', '*');


    $client = eleMentalClinic::Client->retrieve( 1001 );
    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,   
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1 ));
    is_deeply( 
        $one->home,
        {
            admin   => 1,
        },
    );

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->id,   
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1003 ));
    is_deeply( 
        $one->home,
        {
            admin   => 0,
        },
    );


dbinit( 0 );
