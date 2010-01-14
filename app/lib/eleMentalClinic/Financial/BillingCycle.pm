package eleMentalClinic::Financial::BillingCycle;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::BillingCycle

=head1 SYNOPSIS

Manages billing cycle workflow; deals with payer validation.  Child of L<eleMentalClinic::Financial::Validator>.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Financial::Validator /;
use Data::Dumper;
use Carp;
use eleMentalClinic::Financial::ValidationSet;
use eleMentalClinic::Financial::ValidationRule;
use eleMentalClinic::Financial::BillingPrognote;
use eleMentalClinic::Financial::BillingFile;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'billing_cycle' }
    sub fields { [ qw/ rec_id creation_date staff_id step status /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_prognotes_by_insurer {
    my $self = shift;
    return unless $self->validation_set;
    $self->SUPER::group_prognotes_by_insurer( $self->validation_set->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rule_ids {
    my $self = shift;
    return unless $self->validation_set;
    $self->SUPER::rule_ids( $self->validation_set->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub system_rules_used {
    my $self = shift;
    $self->SUPER::system_rules_used( $self->validation_set->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payer_rules_used {
    my $self = shift;
    my( $payer_id ) = @_;
    $self->SUPER::payer_rules_used( $self->validation_set->id, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub results {
    my $self = shift;
    my( $status, $payer_id ) = @_;

    return unless $self->validation_set;
    $self->SUPER::results( $self->validation_set->id, $status, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub result_count {
    my $self = shift;
    my( $status, $payer_id ) = @_;

    return unless $self->validation_set;
    $self->SUPER::result_count( $self->validation_set->id, $status, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognotes {
    my $self = shift;
    return unless $self->validation_set;
    $self->SUPER::prognotes( $self->validation_set->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognotes_not_selected {
    my $self = shift;
    return unless $self->validation_set;
    $self->SUPER::prognotes_not_selected( $self->validation_set->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognote_count {
    my $self = shift;
    return unless $self->validation_set;
    $self->SUPER::prognote_count( $self->validation_set->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub validation_set {
    my $self = shift;
    return unless $self->id;
    return eleMentalClinic::Financial::ValidationSet->get_by_billing_cycle( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub validation_query {
    my $self = shift;
    my( $type, $rule, $payer_id ) = @_;

    return unless $self->validation_set and $payer_id;
    $self->SUPER::validation_query( $self->validation_set->id, $type, $rule, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub test_validate_sql {
    my $self = shift;
    my( $rule, $payer_id ) = @_;

    return unless $self->validation_set and $payer_id;
    $self->SUPER::test_validate_sql( $self->validation_set->id, $rule, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub live_validate_sql {
    my $self = shift;
    my( $rule, $payer_id ) = @_;

    return unless $self->validation_set and $payer_id;
    $self->SUPER::live_validate_sql( $self->validation_set->id, $rule, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub validate {
    die 'deprecated';
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub system_validation {
    my $self = shift;
    my( $rule_ids ) = @_;

    return unless $self->validation_set;
    $self->SUPER::system_validation( $self->validation_set->id, $rule_ids );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payer_validation {
    my $self = shift;
    my( $rule_ids, $payer_id ) = @_;

    return unless $self->validation_set and $payer_id;
    $self->SUPER::payer_validation( $self->validation_set->id, $rule_ids, $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_note_billing_status {
    my $self = shift;

    return unless $self->validation_set;
    $self->SUPER::set_note_billing_status( $self->validation_set->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payer_is_validated {
    my $self = shift;

    return unless $self->validation_set;
    $self->SUPER::payer_is_validated( $self->validation_set->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub insurers {
    my $self = shift;
    return unless $self->validation_set;
    $self->SUPER::insurers( $self->validation_set->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub clients {
    my $self = shift;
    return unless $self->validation_set;
    $self->SUPER::clients( $self->validation_set->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub set_notes_which_fail_rule { 
    my $self = shift; 
    return unless $self->validation_set; 
    $self->SUPER::set_notes_which_fail_rule( $self->validation_set->id, @_ ); 
} 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 payer_has_billable_notes()

Object method.

Does this payer have billable notes in this billing cycle?  It's possible for
all a payer's notes to fail validation, in which case we have nothing to do.

Not a Validator method since we don't need it for ValidationSet.

NOTE: could be optimized for performance with this query, or something like it:

    select count(*) from validation_result, validation_prognote
    where validation_prognote.rolodex_id = 1015
    and validation_prognote.validation_set_id = 1001
    and validation_result.pass is true ;

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub payer_has_billable_notes {
    my $self = shift;
    my( $payer_id ) = @_;

    croak 'Must call on stored object'
        unless $self->id;
    croak 'Payer id is required'
        unless $payer_id;
    return $self->results( 1, $payer_id )
        ? 1
        : 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 payer_validation_complete()

Object method.

Returns C<1> if payer validation is complete for all payers in this billing
cycle.

Not a Validator method since we don't need it for ValidationSet.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub payer_validation_complete {
    my $self = shift;

    croak 'Must call on stored object'
        unless $self->id;
    return unless my $insurers = $self->insurers;
    for( @$insurers ) {
        return unless $self->payer_is_validated( $_->id );
    }
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# there's an argument to do much of this work in move_notes_to_billing().
# that way it really is moving notes, not copying them.
sub finish {
    my $self = shift;
    return unless $self->id;
    
    $self->db->transaction_begin;
    # first, reset the notes if necessary
    my $set_id = $self->validation_set->id;
    my $update = qq/
        UPDATE prognote
        SET billing_status = prognote.previous_billing_status,
        previous_billing_status = NULL
        FROM validation_prognote
        WHERE billing_status = 'Prebilling'
            AND validation_prognote.prognote_id = prognote.rec_id
            AND validation_prognote.validation_set_id = $set_id
    /;

    return $self->db->transaction_rollback
        unless $self->db->do_sql( $update, 'return' );

    # then, close the cycle
    $self->step( 0 );
    $self->status( 'Closed' );

    return $self->db->transaction_rollback
        unless $self->save;
    return $self->db->transaction_commit;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 valid_notes( $payer_id )

Object method.

Returns an array of all progress note objects which have passed validation.

=cut
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub valid_notes {
    my $self = shift;
    my( $payer_id ) = @_;

    return unless
        $payer_id
        and $self->validation_set
        and my $set_id = $self->validation_set->id
        # results() is called here just to get list of ids which passed
        # TODO could be optimized
        and my $results = $self->results( 1, $payer_id );

    my $include = join ',' => map{ $_->{ rec_id }} @$results;
    $include = "AND prognote.rec_id IN ( $include )";

    my $query = qq/
        SELECT prognote.*
        FROM validation_prognote, prognote
        WHERE validation_prognote.validation_set_id = $set_id
        AND validation_prognote.payer_validation = TRUE
        AND validation_prognote.rolodex_id = $payer_id
        AND prognote.rec_id = validation_prognote.prognote_id
        $include
    /;
    my $sth = $self->db->dbh->prepare( $query );
    $sth->execute;

    return [ map{ eleMentalClinic::ProgressNote->new( $_ ) } @{$sth->fetchall_arrayref({})} ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 move_notes_to_billing( $payer_id )

Object method.

$self->validation_set must be defined to use this method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub move_notes_to_billing {
    my $self = shift;
    my( $payer_id ) = @_;
    my $prognote_ids;

    return unless $self->validation_set and $payer_id;

    $self->db->transaction_begin;
    eval {
        my $prognotes = $self->valid_notes($payer_id);

        my $billing_file = $self->new_file($payer_id);
        $billing_file->add_claims($prognotes);

        my $set_id = $self->validation_set->id;
        my $update = qq/ 
            UPDATE prognote SET billing_status = 'Billing'
            FROM validation_prognote
            WHERE prognote.rec_id = validation_prognote.prognote_id
                AND validation_prognote.validation_set_id = $set_id
        /;
        return $self->db->transaction_rollback
            unless $self->db->do_sql( $update, 'return' );

# XXX This causes a problem in finish() unless we move some of that code here - see note there
#    $self->delete_validation_prognotes( $prognote_ids );
    };

    if( $@ ){
        # TODO warn at UI level
        #Log_defer( "Error moving notes to billing, payer " . $payer_id . ": $@" );
        warn $@;
        return $self->db->transaction_rollback;
    }

    return $self->db->transaction_commit;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 new_file( $payer_id )

Object method creates a new BillingFile related to this BillingCycle.

 * $payer_id : rolodex rec id for the payer being billed.

dies if unable to create BillingFile record.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub new_file {
    my $self = shift;
    my $payer_id = shift;
    return unless $payer_id;

    my $file = eleMentalClinic::Financial::BillingFile->new({
        billing_cycle_id => $self->rec_id,
        rolodex_id => $payer_id,
    }); 
    die 'Unable to save BillingFile' unless $file->save;

    return $file;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 bill_manual_combined_notes( $note_ids, $staff_id, $client_insurance_id )

This class method handles the creating of BillingCycle and related file,
claim and service objects for combined notes as returned from the
Manual Combined Note tool.

All parameters are required.

 * $note_ids : reference to an array of prognote rec ids (must contain at least 
   one id).
 * $staff_id : personnel rec id for the staff initiating the manual billing cycle
 * $client_insurance_id : client_insurance rec id for the payer being billed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub bill_manual_combined_notes {
    my $class = shift;
    my( $note_ids, $staff_id, $client_insurance_id ) = @_;

    die ('All parameters required') unless $note_ids and $staff_id and $client_insurance_id;
    # expect a non-zero array of note_ids
    die ('Note ids required') unless scalar(@$note_ids) > 0;
   
    # retrieve valid client_insurance 
    my $client_insurance = eleMentalClinic::Client::Insurance->retrieve( $client_insurance_id );
    # end in error if we did not retrieve a stored object from the database
    die "Unable to retrieve eleMentalClinic::Client::Insurance for id: $client_insurance_id." unless $client_insurance->id;

    # retrieve set of valid prognotes
    my @prognotes;
    for my $note_id (@$note_ids) {
        my $note =  eleMentalClinic::ProgressNote->get_byid($note_id);
        die "No eleMentalClinic::ProgressNote found for id: $note_id" unless $note;
        push @prognotes, eleMentalClinic::ProgressNote->new($note);
    }

    # The entire action of creating a manual billing cycle and 
    # adjusting previous prognote transactions must be done within
    # a single SQL Transaction.
    my $cycle;
    $class->db->transaction_do_eval(sub {
        # refund transactions on prognotes
        map{ $_->refund } @prognotes;        

        # create new billing cycle and populate it
        $cycle = eleMentalClinic::Financial::BillingCycle->new({
            staff_id => $staff_id,
            step => 0,
            status => 'Closed',
        });
        die 'Unable to save BillingCycle' unless $cycle->save;

        # create a billing file from the prognotes
        my $billing_file = $cycle->new_file($client_insurance->rolodex_id);
        $billing_file->add_claims(\@prognotes); 

        # FIXME - I'm calling save_as_billed for each billing_claim rather than 
        # BillingFile->save_as_billed to avoid nested transactions/Postgres 
        # version compatibility issues.
        map { $_->save_as_billed( 1 ) } @{ $billing_file->billing_claims };
    });

    if ($@) {
        warn $@;
        return;
    } else {
        return $cycle->retrieve( $cycle->id );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 delete_validation_prognotes( $prognote_ids )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub delete_validation_prognotes {
    my $self = shift;
    my( $prognote_ids ) = @_;

    return unless $prognote_ids and $self->validation_set->rec_id;

    my $validation_set_id = $self->validation_set->rec_id;
    my $prognote_list = join( ', ', @$prognote_ids );
    my $query = qq/
        DELETE FROM validation_prognote
        WHERE validation_set_id = $validation_set_id
        AND prognote_id IN ( $prognote_list )
    /;

    my $sth = $self->db->dbh->prepare( $query );
    return $sth->execute;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 write_837( $billing_file_id, $timestamp )

Object method. Wrapper for write_file.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub write_837 {
    my $self = shift;
    my( $billing_file_id, $timestamp ) = @_;
    
    die 'billing_file_id is required' unless $billing_file_id;

    return $self->write_file( $billing_file_id, '837', $timestamp );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 write_hcfas( $billing_file_id, $timestamp )

Object method. Wrapper for write_file.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub write_hcfas {
    my $self = shift;
    my( $billing_file_id, $timestamp ) = @_;
    
    die 'billing_file_id is required' unless $billing_file_id;

    return $self->write_file( $billing_file_id, 'hcfa', $timestamp );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 write_file( $billing_file_id, $type, $timestamp )

Object method.

Returns names of files created.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub write_file {
    my $self = shift;
    my( $billing_file_id, $type, $timestamp ) = @_;

    die 'billing_file_id and type are required' unless $billing_file_id and $type;
    die 'Can only write files of type 837 or hcfa' unless $type eq '837' or $type eq 'hcfa';

    my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $billing_file_id );

    # Only allow the EDI to be sent once
    die 'This file has already been sent' if $billing_file->date_edi_billed and $type eq '837';

    $timestamp ||= $self->timestamp;
    my( $date, $time ) = split ' ' => $timestamp; 
    $date =~ s/-//g;
    $time =~ s/^(\d{2}):(\d{2}).*/$1$2/;

    my $inithash = {
        billing_file => $billing_file,
        date_stamp   => $date,
        time_stamp   => $time,
    };

    my $writer;
    if( $type eq '837' ){
        $writer = eleMentalClinic::ECS::Write837->new( $inithash );
        # billing_file is not 'save_as_billed' here, but after sending to payer
    }
    elsif( $type eq 'hcfa' ){
        $writer = eleMentalClinic::Financial::HCFA->new( $inithash );
        die 'Unable to save this hcfa as billed'
            unless $billing_file->save_as_billed( $timestamp );
    }

    return $writer->write;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_billing_files( [$rolodex_id] )

Object method.

Returns list of all L<eleMentalClinic::Financial::BillingFile> objects associated with this object.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_billing_files {
    my $self = shift;
    my( $rolodex_id ) = @_;
    return unless $self->id;

    return eleMentalClinic::Financial::BillingFile->get_by_billing_cycle( $self->id, $rolodex_id );
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Partlow L<jpartlow@opensourcery.com>

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
