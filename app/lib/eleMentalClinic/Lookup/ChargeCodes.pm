package eleMentalClinic::Lookup::ChargeCodes;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Lookup::ChargeCodes

=head1 SYNOPSIS

Assists in charge code lookup for charge code filtering.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base /;
use Data::Dumper;
use Date::Calc qw/ Date_to_Days /;
use eleMentalClinic::ValidData;
use eleMentalClinic::Group;
use eleMentalClinic::Personnel;
use eleMentalClinic::Util;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub methods {
        [ qw/
            client_id staff_id note_date program_id prognote_location_id
        /]
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns two arrays: all codes and sticky codes
sub writer_codes {
    my $self = shift;

    return unless $self->staff_id;
    # XXX dup?
    my $charge_code_table = eleMentalClinic::ValidData->new({ dept_id => 1001 })->get_table( '_charge_code' );

    # writer from $self->staff_id
    my $personnel = eleMentalClinic::Personnel->new({
        staff_id => $self->staff_id })->retrieve;

    # get writer's codes
    return unless
        my $writer_groups = $personnel->lookup_associations( $charge_code_table->{ rec_id } );
    my @codes = ();
    my @sticky = ();
    for( @$writer_groups ) {
        $_->{ sticky }
            ? push @sticky => @{ $_->members }
            : push @codes => @{ $_->members }
    }
    return unless @codes or @sticky;

    ([ sort $self->unique( @codes, @sticky )], \@sticky );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# codes associated with one item from one table
sub get_by_item_association {
    my $self = shift;
    my( $table_id, $item_id ) = @_;

    # return undef instead of dying 'cause in use we may not get all data
    return
        unless $table_id and $item_id;

    my $query = qq/
        SELECT DISTINCT item_id FROM lookup_group_entries
        WHERE group_id
        IN(
            SELECT lookup_group_id FROM lookup_associations
            WHERE lookup_table_id = $table_id
            AND lookup_item_id = $item_id
        )
        ORDER BY item_id
    /;

    my $results = $self->db->dbh->selectcol_arrayref($query);
    return @$results ? $results : undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# codes associated with one location
sub location_codes {
    my $self = shift;

    my $location_table = eleMentalClinic::ValidData->new({ dept_id => 1001 })->get_table( '_prognote_location' );
    my $table_id = $location_table->{ rec_id };
    $self->get_by_item_association( $table_id, $self->prognote_location_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_program_id {
    my $self = shift;

    return unless $self->note_date and $self->client_id;
    my $client = eleMentalClinic::Client->new({ client_id => $self->client_id })->retrieve;
    return $client->placement( $self->note_date )->program_id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub program_codes {
    my $self = shift;
    my( $program_id ) = @_;

    return unless $self->note_date and $self->client_id;
# print STDERR Dumper 'a';
    # if we don't have a program id at this point, the client was
    # not admitted on $note_date
    $program_id ||= $self->program_id || $self->get_program_id;
    return unless $program_id;

# print STDERR Dumper[ 'b ', $program_id ];

    # FIXME next two lines are duped from get_program_id
    my $program_table = eleMentalClinic::ValidData->new({ dept_id => 1001 })->get_table( '_program' );
    my $table_id = $program_table->{ rec_id };
    $self->get_by_item_association( $table_id, $program_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub all_charge_code_ids {
    my $self = shift;

    my $codes = eleMentalClinic::ValidData->new({ dept_id => 1001 })->list( '_charge_code' );
    my @ids;
    push @ids => $_->{ rec_id }
        for @$codes;
    \@ids;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns valid charge codes for the given context:
# - writer
# - location
# - program, on prognote date
# this is long and evil, but i want to keep it explicit so it's easy
# to understand and benchmark
sub valid_charge_code_ids {
    my $self = shift;
    my( $debug ) = @_;

    my $all_codes = $self->all_charge_code_ids;
    $self->program_id( $self->get_program_id );

    # the 'or all codes' below is because if a writer, location, or
    # program has no associations then it's allowed to use everything
    my( $writer_codes, $writer_sticky ) = $self->writer_codes;
    $writer_codes ||= $all_codes;

  $debug and print STDERR Dumper[ 'writer_codes: ', $self->writer_codes ];
  $debug and print STDERR Dumper[ 'writer normal: ', $writer_codes ];
  $debug and print STDERR Dumper[ 'writer sticky: ', $writer_sticky ];

    my $location_codes = $self->location_codes || $all_codes;
  $debug and print STDERR Dumper[ 'location codes: ', $location_codes ];

    my $program_codes = $self->program_codes || $all_codes;
    # but if there's no valid program, no program codes are possible
    # this should only happen if we don't have a note date
    $program_codes = [] unless $self->program_id;
  $debug and print STDERR Dumper[ 'program codes: ', $program_codes ];

    # find the codes that are common to writer, location, program
    my %union = ();
    my %intersection = ();
    # everything is added to union; only those already in union
    # are added to intersection
    $union{ $_ }++ && $intersection{ $_ }++
        for ( @$writer_codes, @$location_codes );
    my @common = keys %intersection;

    %union = %intersection = ();
    $union{ $_ }++ && $intersection{ $_ }++
        for ( @common, @$program_codes );
    my @valid = keys %intersection;

    # add the sticky codes
    push @valid => @$writer_sticky
        if $writer_sticky;

  $debug and print STDERR Dumper $writer_sticky;

    # add the global codes
    my $globals = eleMentalClinic::Lookup::Group->new->get_ids_by_group_name_and_parent(
        'Global',
        'valid_data_charge_code',
    );
    push @valid => @$globals
        if $globals;

    return unless @valid;
    [ sort $self->unique( @valid )];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO dept_id is hardcoded
sub valid_charge_codes {
    my $self = shift;
    my( $ids ) = @_;

    $ids ||= $self->valid_charge_code_ids;
    return unless $ids;

    $ids = join ', ' => @$ids;
    my $codes = $self->db->select_many(
        [ qw/
            rec_id dept_id name description active
            min_allowable_time max_allowable_time minutes_per_unit
            dollars_per_unit max_units_allowed_per_encounter
            max_units_allowed_per_day cost_calculation_method
        /],
        'valid_data_charge_code',
        'WHERE dept_id = 1001'
            .' AND active = 1'
            ." AND rec_id IN( $ids )",
        'ORDER BY name',
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# for each active charge code, returns the following data:
# (takes into account all data overridden in
# insurance_charge_code_association)
#   charge_code_id                  => ?
#   active                          => ?
#   dept_id                         => ?
#   name                            => ?
#   description                     => ?
#   min_allowable_time              => ?
#   max_allowable_time              => ?
#   acceptable                      => ?
#   minutes_per_unit                => ?
#   dollars_per_unit                => ?
#   max_units_allowed_per_day       => ?
#   max_units_allowed_per_encounter => ?
#   cost_calculation_method         => ?
sub charge_codes_by_insurer {
    my $self = shift;
    my( $rolodex_id, $only_associated_codes ) = @_;

    my $insurer_codes = [];
    my %insurer_codes = ();
    if( $rolodex_id ) {
        my $insurer_codes = $self->db->select_many(
            [ qw/
                valid_data_charge_code_id
                acceptable dollars_per_unit max_units_allowed_per_encounter
                max_units_allowed_per_day
            /],
            'insurance_charge_code_association',
            "WHERE rolodex_id = $rolodex_id",
            'ORDER BY valid_data_charge_code_id',
        );
        return
            if $only_associated_codes and not $insurer_codes;
        %insurer_codes = map{ $_->{ valid_data_charge_code_id } => $_ } @$insurer_codes;
        return \%insurer_codes
            if $only_associated_codes;
    }

    my @fields_to_override = qw/
        dollars_per_unit
        max_units_allowed_per_day
        max_units_allowed_per_encounter
    /;
    my %fields_to_add = (
        acceptable  => 1,
    );
    my @fields_to_delete = qw/
        rec_id
    /;

    my %codes_to_return;
    my $codes = eleMentalClinic::ValidData->new({ dept_id => 1001 })->list( '_charge_code' );
    for my $code( @$codes ) {
        my $id = $code->{ rec_id };
        $codes_to_return{ $id } = $code;
        $codes_to_return{ $id }{ charge_code_id } = $id;

        for my $field( @fields_to_override ) {
            $codes_to_return{ $id }{ $field } = $insurer_codes{ $id }{ $field }
                if $insurer_codes{ $id }{ $field };
        }
        for my $field( keys %fields_to_add ) {
            $codes_to_return{ $id }{ $field } = defined $insurer_codes{ $id }{ $field }
                ? $insurer_codes{ $id }{ $field }
                : $fields_to_add{ $field };
        }
        delete $codes_to_return{ $id }{ $_ }
            for @fields_to_delete;
    }
    return \%codes_to_return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 insurer_charge_code_save( $rolodex_id, $charge_code_id, [ \%charge_code ])

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub insurer_charge_code_save {
    my $class = shift;
    my( $rolodex_id, $charge_code_id, $charge_code ) = @_;

    die 'Rolodex id is required'
        unless $rolodex_id;
    die 'Charge code id is required'
        unless $charge_code_id;

    # delete it all to start with, then recreate if necessary
    my( $rid, $cid ) = dbquote( $rolodex_id, $charge_code_id );
    $class->db->delete_one(
        'insurance_charge_code_association',
        qq/rolodex_id = $rid AND valid_data_charge_code_id = $cid/
    );

    return 1 unless $charge_code;

    @$charge_code{ qw/ rolodex_id valid_data_charge_code_id / } = ( $rolodex_id, $charge_code_id );
    # unacceptable codes have other fields zeroed out
    unless( $charge_code->{ acceptable }) {
        undef $charge_code->{ $_ }
            for qw/ dollars_per_unit max_units_allowed_per_encounter max_units_allowed_per_day/;
    }

    return $class->db->insert_one(
        'insurance_charge_code_association',
        [ keys %$charge_code ],
        [ values %$charge_code ],
    );
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

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
