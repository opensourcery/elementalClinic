package eleMentalClinic::Client::AssessmentTemplate::Section;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::AssessmentTemplate::Section

=head1 SYNOPSIS

A user-configurable template system

=head1 METHODS

=cut

use base qw(eleMentalClinic::DB::Object);
use eleMentalClinic::Util;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub primary_key { 'rec_id' }
sub table { 'assessment_template_sections' }

# Documentation for this special 'fields' declaration is in 000db.t
# Essentially it acts as a normal 'fields' declaration except on initial object insert.
sub fields {
    my $self = shift;
    my ( $insert_queries ) = @_;
            
    return [qw/rec_id label position assessment_template_id/] 
        unless $insert_queries;

    return {
        position => {
            insert_query => 'SELECT (MAX(position) + 1) FROM '. 
                            eleMentalClinic::Client::AssessmentTemplate::Section->table .
                            ' WHERE assessment_template_id = ?',
            default => 0,
            params => [ $self->assessment_template_id ],
        }
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub accessors_retrieve_many {
    {
        section_fields => { assessment_template_section_id => 'eleMentalClinic::Client::AssessmentTemplate::Field' },
    };
}

sub get_one_by_position_in_template {
    my $self = shift;
    my ( $position, $template ) = @_;

    $template = $template->rec_id if ref $template;
    return unless $template and defined $position;

    my $results = $self->db->select_one(
        [ $self->primary_key ],
        $self->table,
        [
            'position = ? AND assessment_template_id = ?',
            $position || 0, $template
        ]
    );
    return unless $results;
    return $self->retrieve( $results->{ $self->primary_key });
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 clone( template_id )

Object method.

Clone this section into the specified template

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub clone {
    my $self = shift;
    my $class = ref $self;
    my ( $id ) = @_;

    my $new = $class->new({
        label => $self->label,
        position => $self->position,
        assessment_template_id => $id,
    });
    $new->save;

    #Clone each field.
    my $fields = $self->section_fields || [];
    $_->clone( $new->rec_id ) foreach (@{ $fields });

    return $class->retrieve( $new->rec_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_alerts_by_template()

Object or Class method.

Takes a Template or template ID

returns the alerts section for the given template

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_alerts_by_template {
    my $self = shift;
    my $class = ref $self || $self;
    my ( $template ) = @_;
    $template = $template->rec_id if ref $template;

    my $alert_section = $class->db->select_one(
        [qw/rec_id/],
        $class->table,
        [
            q{assessment_template_id = ?
                AND ( label = 'alerts' or label = 'Alerts' )},
            $template,
        ],
    );
    return $class->retrieve( $alert_section->{ rec_id } ) if $alert_section->{ rec_id };
    return undef;
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Erik Hollensbe L<erikh@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see
L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for
known bugs.

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

=cut

