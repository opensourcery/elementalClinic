package eleMentalClinic::Controller::Base::AdminAssessmentTemplates;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::AdminAssessmentTemplates

=head1 SYNOPSIS

Admin controller for managing configurable assessments.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use Data::Dumper;
use eleMentalClinic::Client::AssessmentTemplate;
use eleMentalClinic::Client::AssessmentTemplate::Section;
use JSON;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->script( 'admin_assessment_templates.cgi' );
    $self->security( 'admin' );
    $self->template->vars({
        styles => [ 'admin', 'configurable_assessment', 'admin_assessment_templates', 'feature/selector' ],
        script => 'admin_assessment_templates.cgi',
        javascripts  => [ 'configurable_assessment.js' ],
    });
    $self->override_template_path( 'admin/assessment_template' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            assessment_id => [ 'Assessment Template ID' ],
        },
        create => {
            -alias => [ 'New', 'Create a new assessment template:' ],
            -on_error   => 'home',
            new_name => [ 'New Template Name', 'required' ],
        },
        delete_template => {
            -alias => [ 'Delete' ],
            assessment_id => [ 'Assessment Template ID', 'required' ],
        },
        clone_template => {
            -alias => [ 'Clone' ],
            assessment_id => [ 'Assessment Template ID' ],
        },
        activate => {
            -alias => [ 'Activate' ],
            -on_error   => 'home',
            is_intake     => [ 'Use as intake assessment', 'checkbox::boolean' ],
            assessment_id => [ 'Assessment Template ID', 'required' ],
            name => [ 'Template Name', 'required' ],
            part_id => [ 'Last section viewed' ],
            section => {
                label    => [ 'Section Name' ],
                rec_id   => [ 'Section ID' ],
            },
            field => {
                label      => [ 'Field Name' ],
                rec_id     => [ 'Field ID' ],
                section_id => [ 'Field Section' ],
                choices    => [ 'Field Choices' ],
            },
        },
        save => {
            -alias => [ 'Save assessment' ],
            -on_error   => 'home',
            is_intake     => [ 'Use as intake assessment', 'checkbox::boolean' ],
            name => [ 'Template Name', 'required' ],
            assessment_id => [ 'Assessment Template ID' ],
            # Objects cannot have errors issued on them, so we create 'component' to add errors to #FIXME
            component => [ 'Template Component' ],
            part_id => [ 'Last section viewed' ],
            section => {
                label    => [ 'Section Name' ],
                rec_id   => [ 'Section ID' ],
                position => [ 'Section Position' ],
            },
            field => {
                label      => [ 'Field Name' ],
                rec_id     => [ 'Field ID' ],
                section_id => [ 'Field Section' ],
                choices    => [ 'Field Choices' ],
                position   => [ 'Field Position' ],
            },
        },
        _field => { # adds new field to section
            section_id => [ 'Section ID', 'required' ]
        },
        _field_remove => {
            section_id    => [ 'Field Section', 'required' ],
            position      => [ 'Field Position', 'required' ],
        },
        _section => {}, # adds new section to assessment
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my ( $assessment_id ) = @_;
    my $active = eleMentalClinic::Client::AssessmentTemplate->get_active();
    my $intake = eleMentalClinic::Client::AssessmentTemplate->get_intake();
    my $in_progress = eleMentalClinic::Client::AssessmentTemplate->get_in_progress();
    my $assessment;

    if( $assessment_id or $self->param( 'assessment_id' )) {
        $assessment = $self->current_assessment( $assessment_id );
    }

    $self->override_template_name( 'home' );

    my $section_id = $self->param( 'part_id' );
    my $section = eleMentalClinic::Client::AssessmentTemplate::Section->retrieve( $section_id ) if $section_id;
    my $part = $section ? $section->label : $self->param( 'part' );

    return {
        current_assessment      => $assessment || $active,
        assessment_intake       => $intake,
        assessment_active       => $active,
        assessments_in_progress => $in_progress,
        assessments_archived    => eleMentalClinic::Client::AssessmentTemplate->get_archived(),
        part_id                 => $section_id || '',
        part                    => $part || '',
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
    my $self = shift;
    my $assessment_class = 'eleMentalClinic::Client::AssessmentTemplate';

    # Make sure the provided name is not already used.
    if ( $assessment_class->name_used( $self->param( 'new_name' ))) {
        $self->add_error( 
            'new_name', 
            'new_name', 
            'Template: "' . $self->param( 'new_name' ) . '" already exists.',
        );
        $self->Vars( 'new_name', $self->param( 'new_name' ));
        return $self->home;
    }

    my $assessment = $assessment_class->new({
        staff_id => $self->current_user->staff_id,
        name => $self->param( 'new_name' ),
    });
    $assessment->save;
    $assessment = $assessment_class->retrieve( $assessment->id );

    # Create an empty alerts section.
    eleMentalClinic::Client::AssessmentTemplate::Section->new({
        label => 'Alerts',
        assessment_template_id => $assessment->rec_id,
    })->save;

    return $self->home( $assessment->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub clone_template {
    my $self = shift;
    return $self->home( $self->current_assessment->clone->rec_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub activate {
    my $self = shift;
    # The activate option is shown where save is shown, people can make changes and then hit
    # activate, those changes should be saved.
    $self->save_template;
    $self->current_assessment->activate;
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub delete_template {
    my $self = shift;

    my $assessment = eleMentalClinic::Client::AssessmentTemplate->retrieve( $self->param( 'assessment_id' ));
    $assessment->delete;

    # redirect back to myself; use this instead of just calling $self->home
    # directly because home gets confused by the assessment_id param
    return '', { Location => '/' . $self->script };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_template {
    my $self = shift;
    my $assessment = $self->current_assessment;
    my $assessment_class = 'eleMentalClinic::Client::AssessmentTemplate';

    # Makes no sence to save w/o a current assessment.
    return $self->home unless $assessment;

    if ( 
        # Make sure we have the 'name' paramater prior to this check
        $self->param( 'name' )
        # This is only relevant if the name is changing
        and ( $assessment->name ne $self->param( 'name' ))
        # If the new name is already taken.
        and $assessment_class->name_used( $self->param( 'name' ))
    ) {
        $self->add_error( 
            'name', 
            'name', 
            'Template name "' . $self->param( 'name' ) . '" is taken.',
        );
        return $self->home;
    }

    $assessment->name( $self->param( 'name' )) if $self->param( 'name' );
    $assessment->is_intake( $self->param( 'is_intake' ) ? 1 : 0 );
    $assessment->save;

    for my $type ( qw/ section field / ) {
        my $class = $assessment_class . "::" . ucfirst($type);
        for my $changes (@{ $self->objects( $type ) }) {
            unless ( $changes->{ label } ) {
                $self->add_error(
                    #FIXME Should be able to add errors to 'objects'
                    #$type . '[' . $changes->{ rec_id } . '][' . $change_field . ']', 
                    #$type . '[' . $changes->{ rec_id } . '][' . $change_field . ']', 
                    'component',
                    'component',
                    "You must specify a 'label' for each $type.",
                );
                return $self->home;
            }
            # FIXME  This might be hard to read, perhapse change to if statements.
            my $object = defined( $changes->{ rec_id })
                ? $class->retrieve( $changes->{ rec_id }) #If we have a rec_id use it
                : ( $type eq 'section' ) 
                    # Try to find the object the hard way.
                    ? $class->get_one_by_position_in_template(
                        $changes->{ position },
                        $assessment->rec_id,
                      )
                    : $class->get_one_by_position_in_section(
                        $changes->{ position },
                        $changes->{ section_id },
                      );

            # Must delete an empty position or it will fail during update.
            # Same for rec_id except it spawns a new field object
            for (qw/ position rec_id /) {
                delete $changes->{ $_ } unless $changes->{ $_ };
            }

            $object->update( $changes );
            $object->save;
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    $self->save_template;
    return $self->home;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _field_remove {
    my $self = shift;

    $self->ajax( 1 );

    my $position = $self->param( 'position' );
    my $section_id = $self->param( 'section_id' );

    my $field = eleMentalClinic::Client::AssessmentTemplate::Field->get_one_by_position_in_section( 
        $position, 
        $self->param( 'section_id' )
    ); 
    $field->delete;

    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _field {
    my $self = shift;

    $self->ajax( 1 );
    $self->override_template_name( '_field' );

    my $field = eleMentalClinic::Client::AssessmentTemplate::Field->new({
        # Label must be unique, and not null. w/o this we would be unable to
        # create more than 1 field between saves.
        # I chose this over creating at save to be consistant w/ _section which works quite nicely.
        label    => "New Field", 
        assessment_template_section_id => $self->param( 'section_id' ), 
    });
    $field->save;

    return {
        current_assessment  => $self->current_assessment,
        section_id          => $self->param( 'section_id' ),
        field               => eleMentalClinic::Client::AssessmentTemplate::Field->retrieve( $field->rec_id ),
        include_new_field_trigger   => 1,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# we need the id of the section in the view, so this AJAX stub creates
# a section and returns it
sub _section {
    my $self = shift;

    $self->ajax( 1 );
    my $section = eleMentalClinic::Client::AssessmentTemplate::Section->new({
        label           => $self->param( 'label' ),
        assessment_template_id => $self->param( 'assessment_id' ),
    });
    $section->save;

    #Create an initial field for the section
    eleMentalClinic::Client::AssessmentTemplate::Field->new({
        label    => "New Field", 
        assessment_template_section_id => $section->rec_id, 
    })->save;

    my %vars = (
        # We need to reload the section to get the correct 'position'
        section => eleMentalClinic::Client::AssessmentTemplate::Section->retrieve( $section->rec_id ),
        current_assessment => $self->current_assessment,
    );
    return JSON::to_json({
        section_id => $section->id,
        navigation => $self->template->process_page( 'admin/assessment_template/_section_navigation', \%vars ),
        content => $self->template->process_page( 'admin/assessment_template/_section_content', \%vars ),
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub current_assessment {
    my $self = shift;
    my ( $assessment_id ) = @_;
    $assessment_id ||= $self->param( 'assessment_id' );
    $assessment_id ||= eleMentalClinic::Client::AssessmentTemplate::Section->retrieve( 
        $self->param( 'section_id' )
    )->assessment_template_id;

    return eleMentalClinic::Client::AssessmentTemplate->retrieve( $assessment_id );
}



'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2008 OpenSourcery, LLC

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
