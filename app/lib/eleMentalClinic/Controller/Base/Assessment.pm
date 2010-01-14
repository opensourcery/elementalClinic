package eleMentalClinic::Controller::Base::Assessment;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Assessment

=head1 SYNOPSIS

Base Configurable Assessment Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use Data::Dumper;


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'assessment.cgi',
        styles => [ 'layout/6633', 'configurable_assessment', 'feature/selector', 'date_picker', 'gateway' ],
        javascripts  => [ 'configurable_assessment.js', 'jquery.js', 'date_picker.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            part => [ 'Part of assessment to display' ],
            part_id => [ 'Last section viewed' ],
        },
        create => {
            -alias => 'New assessment',
            part_id => [ 'Last section viewed' ],
        },
        edit => {
            part_id => [ 'Last section viewed' ],
        },
        clone => {},
        print => {},
        save  => {
            -alias => 'Save assessment',
            start_date => [ 'Start date', 'required' ],
            end_date => [ 'End date', 'required' ],
            field => {
                template_field_id  => [ 'Template Field ID' ],
                value        => [ 'Field Value' ],
            },
            part_id => [ 'Last section viewed' ],
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# assigns a current assessment, which is either based on incoming
# id or is most recent

sub home {
    my $self = shift;

    unless( eleMentalClinic::Client::AssessmentTemplate->get_active( 'assessment' ) ) {
        $self->override_template_name( 'no_template' );
        return {
            admin => $self->current_user->admin,
        };
    }

    return {
        %{ $self->_get_variables },
        action  => 'display',
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create new assessment - display a blank assessment
sub create {
    my $self = shift;

    my $assessment = eleMentalClinic::Client::Assessment->new({
        client_id => $self->get_client->id,
        template_id => eleMentalClinic::Client::AssessmentTemplate->get_active( 'assessment' )->id,
    });

    my $vars = $self->_get_variables;
    $vars->{ current_assessment } = $assessment;
    $vars->{ action } = 'edit';
    $vars->{ op } = 'create';

    $self->override_template_name( 'home' );
    return $vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get one assessment and display it for editing
sub edit {
    my $self = shift;

    $self->override_template_name( 'home' );
    return {
        action => 'edit',
        %{ $self->_get_variables },
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    my $assessment;

    my $proto = {
        start_date => $self->param( 'start_date' ),
        end_date => $self->param( 'end_date' ),
        client_id => $self->get_client->id,
        template_id => eleMentalClinic::Client::AssessmentTemplate->get_active( 'assessment' )->id,
        staff_id => $self->current_user->staff_id,
    };

    if ( $self->errors ) {
        $assessment = $self->_get_assessment ||
            eleMentalClinic::Client::Assessment->new( $proto );
    }
    else {
        $assessment = eleMentalClinic::Client::Assessment->create_or_update(
            %$proto,
            rec_id => $self->param( 'assessment_id' ),
            fields => $self->objects( 'field' ),
        );
    }

    my $vars = {
        %{ $self->_get_variables },
        action => 'display',
        current_assessment => $assessment,
    };
    $self->override_template_name( 'home' );

    if ( $self->errors ) {
        $vars->{ op } = 'create';
        $vars->{ action } = 'edit';
    }

    return $vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clone one assessment
# should only be allowed if the donor assessment uses the current assessment template
# XXX this needs more logic
sub clone {
    my $self = shift;
    my $assessment = $self->_get_assessment;

    $self->override_template_name( 'home' );
    return {
        assessments => $self->_get_variables->{ assessments },
        action => 'edit',
        fields => $assessment->all_fields,
        current_assessment => eleMentalClinic::Client::Assessment->new({
            client_id => $self->get_client->id,
            template_id => eleMentalClinic::Client::AssessmentTemplate->get_active( 'assessment' )->id,
        }),
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print {
    my $self = shift;
    return $self->_get_variables;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_client {
    my $self = shift;
    return eleMentalClinic::Client->retrieve( $self->param( 'client_id ' ));
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_assessment {
    my $self = shift;
    my $id = $self->param( 'assessment_id' );
    return $self->client->assessment unless $id;

    my $assessment = eleMentalClinic::Client::Assessment->retrieve( $id );
    return $assessment if $assessment && $assessment->id;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_variables {
    my $self = shift;

    my %vars;
    $vars{ part } = $self->param( 'part' ) if $self->param( 'part' );

    my $assessments = $self->get_client->assessment_getall;

    $assessments = [ sort{ $b->{ assessment_date } cmp $a->{ assessment_date }} @{ $assessments }] if $assessments;

    my $assessment = $self->_get_assessment;

    my $clonable = eleMentalClinic::Client::AssessmentTemplate->get_active( 'assessment' )->id;
    $clonable = $assessment ? $clonable == $assessment->template_id ? 1
                                                                    : 0
                            : 0;
    $vars{ clonable } = $clonable if $clonable;

    my $section_id = $self->param( 'part_id' );
    my $section = eleMentalClinic::Client::AssessmentTemplate::Section->retrieve( $section_id ) if $section_id;
    my $part = $section ? $section->label : $self->param( 'part' );

    return {
        current_assessment => $self->_get_assessment,
        assessments        => $assessments || [],
        part_id            => $section_id || '',
        part               => $part || '',
        %vars
    };
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
