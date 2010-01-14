package eleMentalClinic::Client::AssessmentTemplate;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::AssessmentTemplate

=head1 SYNOPSIS

Admin-configurable client assessment.

=head1 METHODS

=cut

use base qw(eleMentalClinic::DB::Object);
use Data::Dumper;
use POSIX qw(strftime);
use Date::Calc qw(Today_and_Now Today Delta_Days);
use Date::Manip qw(UnixDate ParseDate);

use eleMentalClinic::Client::AssessmentTemplate::Section;
use eleMentalClinic::Client::AssessmentTemplate::Field;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub primary_key { 'rec_id' }
sub table  { 'assessment_templates' }
sub fields { [ qw/rec_id name created_date staff_id active_start active_end intake_start intake_end is_intake/ ] }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub accessors_retrieve_many {
    {
        sections => { assessment_template_id => 'eleMentalClinic::Client::AssessmentTemplate::Section' },
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 sections_view()

Object method.

returns a list of all sections that have fields, but not empty ones.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub sections_view {
    my $self = shift;
    my $out = [];
    for my $section ( @{ $self->sections || [] }) {
        push( @$out, $section ) if $section->section_fields;
    }
    return $out;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub activate {
    my $self = shift;
    return $self->set_intake if $self->is_intake;
    return $self->set_active;
}

sub set_active {
    my $self = shift;
    croak( "Cannot activate intake template" )
        if $self->is_intake;
    $self->active_end(undef);

    my $stamp = $self->create_timestamp;
    my $item = $self->get_active;

    # If there is not current active assessment then this would cause an error
    if ( $item ) {
        $item->active_end($stamp);
        $item->save;
    }

    $self->active_start($stamp);
    $self->save;
}

sub set_intake {
    my $self = shift;
    croak( "Cannot use non-intake template as intake default" )
        unless $self->is_intake;
    $self->intake_end(undef);

    my $stamp = $self->create_timestamp;
    my $item = $self->get_intake;

    # If there is not current active assessment then this would cause an error
    if ( $item ) {
        $item->intake_end($stamp);
        $item->save;
    }

    $self->intake_start($stamp);
    $self->save;
}

sub active {
    my $self = shift;

    if ($self->active_start) {
        if ($self->active_end) {
            if (
                Delta_Days(
                    $self->parse_date( $self->active_start ),
                    $self->parse_date( $self->active_end )
                ) > 0
                && 
                Delta_Days( Today(), $self->parse_date( $self->active_end ) ) > 0
              )
            {
                return 1;
            }

            return undef;
        }

        return 1;
    }

    return undef;
}

sub intake {
    my $self = shift;

    if ($self->intake_start) {
        if ($self->intake_end) {
            if (
                Delta_Days(
                    $self->parse_date( $self->intake_start ),
                    $self->parse_date( $self->intake_end )
                ) > 0
                && 
                Delta_Days( Today(), $self->parse_date( $self->intake_end ) ) > 0
              )
            {
                return 1;
            }

            return undef;
        }

        return 1;
    }

    return undef;
}

sub editable {
    my $self = shift;

    return (
        !$self->active &&
        !$self->active_start &&
        !$self->active_end &&
        !$self->intake &&
        !$self->intake_start &&
        !$self->intake_end
    );
}

# class method
sub create_timestamp {
    my $class = shift;
    my (@date) = @_;

    @date = Today_and_Now unless (scalar(@date));

    return strftime("%Y-%m-%d %H:%M:%S", @date);
}

# class method
sub parse_date {
    my $class = shift;
    my ($date) = @_;

    split(/-/, UnixDate(ParseDate( $date ), "%Y-%m-%d"))
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_where()

Object or class method.

Used as a base function to simplify the other get_XXX functions.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# This is in responce to a bug that killed all 3 functions, this simplifies the fix to 1 location.
sub get_where {
    my $class = shift;
    my ( $where, $order ) = @_;
    return unless $where;
    $order ||= 'order by rec_id';

    my $list = $class->db->select_many(
        [ $class->primary_key ],
        $class->table,
        $where,
        $order,
    ) || [];

    return [ map { eleMentalClinic::Client::AssessmentTemplate->retrieve( $_->{rec_id} ) } @$list ];
}

# return all objects that are active at the present time.
# class method.
sub get_active {
    my $class = shift;
    my $results = $class->get_where( 
        'where active_start is not null and active_end is null or active_end > current_timestamp',
    ); 
    return $results->[0] if $results;
}

sub get_intake {
    my $class = shift;
    my $results = $class->get_where( 
        'where intake_start is not null and intake_end is null or active_end > current_timestamp',
    );
    return $results->[0] if $results;
}

sub get_archived { 
    return shift->get_where(
        'WHERE ( active_end IS NOT NULL AND active_end < current_timestamp )'
        .  'OR ( intake_end IS NOT NULL AND intake_end < current_timestamp )'
    );
}

sub get_in_progress { 
    return shift->get_where( 
        'WHERE active_end IS NULL AND intake_end IS NULL AND active_start IS NULL AND intake_start IS NULL'
    );
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 clone()

Object or class method.

Creates a copy of the template including all sections and fields.
Can be called in 3 ways:

$new = $template->clone;
$new = $class->clone( 1001 );

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub clone {
    my $self = shift;
    my ( $id, $staff_id ) = @_;
    my $class = ref $self || $self;

    # If ID was passed as an object convert it
    $id = $id->rec_id if (ref $id eq $class);
    
    # If ID was not passed in check if 'self' is an object, and get it from there.
    $id ||= $self->rec_id if (ref $self eq $class);

    return unless $id; #We need and ID in order to clone.

    # Get the original
    my $old = $class->retrieve( $id );

    my $name = "Copy of " . $old->name;
    if ( $self->name_used( $name )) {
        my $i = 1;
        $i++ while ( $self->name_used( $name . "-$i" ));
        $name .= "-$i";
    }

    # Create a new object 
    my $new = $class->new({
        name => $name,
        staff_id => $staff_id || $old->staff_id,
    });
    $new->save;

    #Clone each section.
    my $sections = $old->sections || []; #This will prevent a failure when there are no sections.
    $_->clone( $new->rec_id ) foreach (@{ $sections });

    return $class->retrieve( $new->rec_id );
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 name_used()

Class or Object method.

Returns true if a name has already been used.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub name_used {
    my $class = shift;
    my ( $name ) = @_;

    $class = ref $class || $class;

    my $results = $class->db->new->do_sql( 
        'select name from '. 
            $class->table .
        ' where name = ?',
        undef,
        $name
    );

    return $results->[0] ? 1 : undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 delete()

Object method.

overrides the delete() function.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub delete {
    my $self = shift;

    die( "Cannot delete a template that is active or archived!\n" ) if $self->active_start;

    for ( @{ $self->sections || [] }) {
        $_->delete for ( @{ $_->section_fields || [] });
        $_->delete;
    }
    return $self->SUPER::delete; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_alerts_section()

Object method.

Get the 'Alerts' or 'alerts' section for this template.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_alerts_section {
    my $self = shift;
    return eleMentalClinic::Client::AssessmentTemplate::Section->get_alerts_by_template( $self );
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

=cut
