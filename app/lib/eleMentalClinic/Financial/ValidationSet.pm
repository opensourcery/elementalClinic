package eleMentalClinic::Financial::ValidationSet;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::ValidationSet

=head1 SYNOPSIS

Manages validation set workflow; deals with system validation.  Child of L<eleMentalClinic::Financial::Validator>.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Financial::Validator /;
use eleMentalClinic::Financial::ValidationRule;
use eleMentalClinic::Financial::BillingCycle;
use Data::Dumper;
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'validation_set' }
    sub fields { [ qw/
        rec_id creation_date from_date to_date staff_id billing_cycle_id step status
    /]}
    sub fields_required { [ qw/ creation_date from_date to_date staff_id /]}
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub billing_cycle {
    my $self = shift;
    return unless $self->billing_cycle_id;
    return eleMentalClinic::Financial::BillingCycle->retrieve( $self->billing_cycle_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# selects all notes into new table
sub create {
    my $class = shift;
    my( $args ) = @_;

    for my $arg( qw/ staff_id creation_date type from_date to_date /) {
        croak "Missing required argument: $arg"
            unless grep /^$arg$/ => keys %$args;
    }

    # create new set object first and get its id
    my $set = $class->new({ status => 'Initialized', %$args });

    $set->db->transaction_begin;
    $set->save;

    # create billing cycle if necessary
    $set->create_billing_cycle( $args )
        if $args->{ type } eq 'billing';

    return $set->db->transaction_rollback
        unless $set->create_validation_prognotes( $args );
    $set->save;
    $set->db->transaction_commit;

    return $set;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create_billing_cycle {
    my $self = shift;
    my( $args ) = @_;

    my $cycle = eleMentalClinic::Financial::BillingCycle->new( $args )->save;
    $self->billing_cycle_id( $cycle->id );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 create_validation_prognotes( \%arguments )

Object method.

Creates entries in the C<validation_prognote> table corresponding to all
prognotes in the given date range that fulfill initial selection criteria, and
associates those entries with the current validation set.

Selection criteria are that each note must be committed, and must not be in an
open billing cycle, or fully paid.

Arguments are given in a hash reference:

=over 4

=item from_date

Required; ISO date.  Select notes from this date forward.

=item to_date

Required; ISO date.  Select notes up to and including this date.

=item type

Optional; scalar: 'billing' or undef.  If 'billing', create billing cycle as well.

This method must be wrapped in a transaction, or else failure may leave the database in a bad state.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub create_validation_prognotes {
    my $self = shift;
    my( $args ) = @_;

    die 'Must call on stored object'
        unless my $set_id = $self->id;

    # TODO select only notes that are not in bounce
    my( $from_date, $to_date ) = ( $self->from_date, $self->to_date );
    my $where = qq/
        WHERE prognote.start_date::date BETWEEN '$from_date'::date AND '$to_date'::date
        AND (
            prognote.note_committed = 1
            AND prognote.billing_status IS NULL
            OR prognote.billing_status NOT IN ( 'Unbillable', 'Prebilling', 'Billed', 'Paid' )
        )
        AND (
            prognote_bounced.response_date IS NOT NULL
            OR prognote_bounced.rec_id IS NULL
        )
    /;

    # $self->db->transaction_begin; XXX : uncomment for PG8
    my $query = qq/
        INSERT INTO validation_prognote( prognote_id, validation_set_id )
        SELECT DISTINCT prognote.rec_id, $set_id FROM prognote
            LEFT OUTER JOIN prognote_bounced
            ON prognote.rec_id = prognote_bounced.prognote_id
        $where
        ORDER BY prognote.rec_id
    /;

    my $insert_results = $self->db->do_sql( $query, 'return' );
    # return $self->db->transaction_rollback; XXX : uncomment for PG8
    return
        unless $insert_results > 0;

    # locking notes for billing
    # must do this after the select since it changes the data in a way that it can't
    # be selected.  the transaction should protect us from race conditions
    if( $args->{ type } and $args->{ type } eq 'billing' ) {
        my $query = qq/ 
            UPDATE prognote SET previous_billing_status = billing_status, billing_status = 'Prebilling'
            FROM validation_prognote
            WHERE prognote.rec_id = validation_prognote.prognote_id
                AND validation_prognote.validation_set_id = $set_id
        /;
        my $update_results = $self->db->do_sql( $query, 'return' );
        # return $self->db->transaction_rollback; XXX : uncomment for PG8

        # this should never happen
        # if it does happen, it means we've locked for billing different notes
        # than we inserted into validation_prognote
        warn "INSERT ($insert_results)/UPDATE ($update_results) mismatch"
            unless $update_results == $insert_results;
    }

    # XXX : when we upgrade to PG8, uncomment this nested transaction
    # $self->db->transaction_commit;
    return $insert_results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_by_billing_cycle {
    my $class = shift;
    my( $cycle_id ) = @_;

    return unless $cycle_id;
    return unless
        my $set = $class->db->select_one(
            $class->fields,
            $class->table,
            "billing_cycle_id = $cycle_id"
        );
    return $class->new( $set );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_prognotes_by_insurer {
    my $self = shift;
    return unless $self->id;
    $self->SUPER::group_prognotes_by_insurer( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rule_ids {
    my $self = shift;
    return unless $self->id;
    $self->SUPER::rule_ids( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub system_rules_used {
    my $self = shift;
    $self->SUPER::system_rules_used( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payer_rules_used {
    my $self = shift;
    my( $payer_id ) = @_;
    $self->SUPER::payer_rules_used( $self->id, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub results {
    my $self = shift;
    my( $status, $payer_id ) = @_;

    return unless $self->id;
    $self->SUPER::results( $self->id, $status, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub result_count {
    my $self = shift;
    my( $status, $payer_id ) = @_;

    return unless $self->id;
    $self->SUPER::result_count( $self->id, $status, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognotes {
    my $self = shift;
    return unless $self->id;
    $self->SUPER::prognotes( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognotes_not_selected {
    my $self = shift;
    return unless $self->id;
    $self->SUPER::prognotes_not_selected( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognote_count {
    my $self = shift;
    return unless $self->id;
    $self->SUPER::prognote_count( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub validation_query {
    my $self = shift;
    return unless $self->id;
    $self->SUPER::validation_query( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub test_validate_sql {
    my $self = shift;
    return unless $self->id;
    $self->SUPER::test_validate_sql( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub live_validate_sql {
    my $self = shift;
    return unless $self->id;
    $self->SUPER::live_validate_sql( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub validate {
    die 'deprecated';
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub system_validation {
    my $self = shift;
    my( $rule_ids ) = @_;

    return unless $self->id;
    $self->SUPER::system_validation( $self->id, $rule_ids );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payer_validation {
    my $self = shift;
    my( $rule_ids, $payer_id ) = @_;

    return unless $self->id and $payer_id;
    $self->SUPER::payer_validation( $self->id, $rule_ids, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_note_billing_status {
    my $self = shift;

    return unless $self->id;
    $self->SUPER::set_note_billing_status( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_active {
    my $class = shift;
    $class->SUPER::get_active( 'billing_cycle_id IS NULL' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rules_failed_by_prognote_id {
    my $self = shift;
    $self->SUPER::rules_failed_by_prognote_id( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payer_is_validated {
    my $self = shift;
    $self->SUPER::payer_is_validated( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub insurers {
    my $self = shift;
    return unless $self->id;
    $self->SUPER::insurers( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub clients {
    my $self = shift;
    return unless $self->id;
    $self->SUPER::clients( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub set_notes_which_fail_rule { 
    my $self = shift; 
    return unless $self->id; 
    $self->SUPER::set_notes_which_fail_rule( $self->id, @_ ); 
} 
 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 finish()

Object method.

Deletes a validation set and all associated validation data.  We don't need
this data beyond validation, so there's no reason to keep it.  If there is an
associated L<eleMentalClinic::Financial::BillingCycle>, also calls C<finish> on
that object.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub finish {
    my $self = shift;
    die 'Can only call on stored object'
        unless $self->id;
    
    $self->billing_cycle->finish
        if $self->billing_cycle;
    $self->delete;
    undef $self;
    return 1;
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

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
