package eleMentalClinic::Client::AssessmentTemplate::Field;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::AssessmentTemplate::Field

=head1 SYNOPSIS

A user-configurable template system

=head1 METHODS

=cut

use base qw(eleMentalClinic::DB::Object);
use eleMentalClinic::Util;

sub primary_key { 'rec_id' }
sub table { 'assessment_template_fields' }

# Documentation for this special 'fields' declaration is in 000db.t
# Essentially it acts as a normal 'fields' declaration except on initial object insert.
sub fields {
    my $self = shift;
    my ( $insert_queries ) = @_;
            
    return [qw/rec_id label position field_type assessment_template_section_id choices/]
        unless $insert_queries;

    return {
        position => {
            insert_query => 'SELECT (MAX(position) + 1) FROM '. 
                            eleMentalClinic::Client::AssessmentTemplate::Field->table .
                            ' WHERE assessment_template_section_id = ?',
            default => 0,
            params => [ $self->assessment_template_section_id ],
        }
    };
}

sub get_one_by_position_in_section {
    my $self = shift;
    my ( $position, $section ) = @_;

    $section = $section->rec_id if ref $section;
    return unless $section and defined $section;

    my $results = $self->db->select_one(
        [ $self->primary_key ],
        $self->table,
        [
            'position = ? AND assessment_template_section_id = ?',
            $position || 0, $section
        ]
    );
    return unless $results;
    return $self->retrieve( $results->{ $self->primary_key });
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 clone( section_id )

Object method.

Clone this field into the specified section

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub clone {
    my $self = shift;
    my $class = ref $self;
    my ( $id ) = @_;

    my $new = $class->new({
        label => $self->label,
        choices => $self->choices,
        position => $self->position,
        field_type => $self->field_type,
        assessment_template_section_id => $id,
    });
    $new->save;

    return $class->retrieve( $new->rec_id );
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 list_choices()

Object method.

List available choices.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub list_choices {
    my $self = shift;
    return ['', split(/\s*,\s*/, $self->choices || "" )];
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

