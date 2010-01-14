package eleMentalClinic::Financial::Validator;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::Validator

=head1 SYNOPSIS

Main methods for progress note validation.  Parent of:

=over 4

=item eleMentalClinic::Financial::BillingCycle

=item eleMentalClinic::Financial::ValidationSet

=back

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::ProgressNote;
use eleMentalClinic::Financial::ValidationRule;
use eleMentalClinic::Rolodex;
use eleMentalClinic::Util;
use Data::Dumper;
use Carp;

our %SELECT_ = (
    prognote                => q/ SELECT prognote.rec_id/,
    validation_prognotes    => q/ SELECT validation_prognote.rec_id/,
);
our $FROM = q/ FROM validation_prognote, prognote/;
our $WHERE = q/ WHERE validation_prognote.prognote_id = prognote.rec_id
 AND validation_prognote.validation_set_id =/;
our %ORDER_ = (
    prognote                => q/ ORDER BY prognote.rec_id/,
    validation_prognotes    => q/ ORDER BY validation_prognote.rec_id/,
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    my( $args ) = @_;

    $self->step( 1 )
        unless defined $self->step or defined $args->{ step };
    return $self->SUPER::save( $args );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prognotes {
    my $self = shift;
    my( $set_id, $payer_id ) = @_;
    return unless $set_id;

    my $payer_clause = $payer_id
        ? qq/ AND validation_prognote.rolodex_id = $payer_id /
        : '';
    my $client_name_clause = eleMentalClinic::Client->name_clause;
    # similar query in prognotes_not_selected()
    my $query = qq|
        SELECT 
            prognote.rec_id AS id,
            prognote.client_id,
            prognote.writer,
            prognote.note_body,
            prognote.billing_status,
            prognote.previous_billing_status,
            prognote.start_date,
            DATE( prognote.start_date ) AS note_date,
            EXTRACT( EPOCH FROM CAST ( end_date AS TIME ) - CAST( start_date AS TIME )) / 60 AS note_duration,
            $client_name_clause AS client_name,
            valid_data_charge_code.name AS charge_code_name,
            valid_data_prognote_location.name AS location_name
        FROM validation_prognote
            LEFT JOIN prognote ON prognote.rec_id = validation_prognote.prognote_id
            LEFT JOIN client ON client.client_id = prognote.client_id
            LEFT JOIN valid_data_charge_code ON valid_data_charge_code.rec_id = prognote.charge_code_id
            LEFT JOIN valid_data_prognote_location ON valid_data_prognote_location.rec_id = prognote.note_location_id
        WHERE validation_set_id = ?
        $payer_clause
        ORDER BY
            prognote.start_date, prognote.end_date, prognote.rec_id 
    |;
#             -- $client_name_clause,
    return unless my $results = $self->db->fetch_hashref( $query, $set_id );

    return $self->add_note_units($results);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 prognote_count( $set_id, [ $payer_id ])

Object method.

Returns the count of notes in the current set.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub prognote_count {
    my $self = shift;
    my( $set_id, $payer_id ) = @_;
    return unless $set_id;

    my $where = "WHERE validation_set_id = $set_id";
    $where .= $payer_id
        ? ' AND rolodex_id = '. dbquote( $payer_id )
        : '';
    my $query = qq/
        SELECT count( rec_id )
        FROM validation_prognote
        $where
    /;
    return $self->db->do_sql( $query )->[ 0 ]->{ count };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 result_count( $set_id, [ $pass, $payer_id ])

Object method.

Returns the count of result in the current set.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub result_count {
    my $self = shift;
    my( $set_id, $pass, $payer_id ) = @_;
    return unless $set_id;

    dbquoteme( \$set_id );
    my $payer_filter = $payer_id
        ? 'AND validation_prognote.rolodex_id = '. dbquote( $payer_id )
        : '';

    my $query;
    my $join = q/
        INNER JOIN validation_result ON validation_result.validation_prognote_id = validation_prognote.rec_id
    /;
    my $filter = qq/
        FROM validation_prognote $join
        WHERE validation_set_id = $set_id 
    /;
    $filter .= q/AND validation_result.pass IS FALSE/
        if defined $pass and ( $pass eq 1 or $pass eq 0 );

    $query = ( defined $pass and $pass eq 1 )
        ? qq/
            SELECT COUNT( DISTINCT validation_prognote.rec_id )
            FROM validation_prognote $join
            WHERE validation_prognote.rec_id NOT IN (
                SELECT DISTINCT validation_prognote.rec_id
                $filter
            )
            $payer_filter
        /
        : qq/
            SELECT COUNT( DISTINCT validation_prognote.rec_id )
            $filter
            $payer_filter
        /;
    return $self->db->do_sql( $query )->[ 0 ]->{ count };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rule_ids {
    my $self = shift;
    my( $set_id, $payer_id, $scope ) = @_;
    return unless $set_id;

    my @args = ($set_id);
    my $where = 'validation_prognote.validation_set_id = ?';

    if ( $payer_id ) {
        $where .= ' AND validation_prognote.rolodex_id = ?';
        push @args, $payer_id;
    }
    if ( $scope ) {
        $where .= ' AND validation_rule.scope = ?';
        push @args, $scope;
    }

    my $query = qq/
        SELECT DISTINCT validation_rule_id, scope
        FROM validation_rule
            INNER JOIN (
                validation_result
                    INNER JOIN validation_prognote
                    ON validation_prognote.rec_id = validation_result.validation_prognote_id
            )
            ON validation_rule.rec_id = validation_result.validation_rule_id
        WHERE $where
        ORDER BY validation_rule_id
    /;

    my $rules = $self->db->dbh->selectcol_arrayref( $query, {}, @args );
    return unless @$rules;
    return $rules;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO not very efficient, uses a new query for every result
sub rules {
    my $self = shift;
    my( $payer_id ) = @_;

    return unless $self->id;
    return unless my $ids = $self->rule_ids( $payer_id );
    return [ map{ eleMentalClinic::Financial::ValidationRule->new({ rec_id => $_ })->retrieve } @$ids ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub system_rules_used {
    my $self = shift;
    my( $set_id ) = @_;

    return unless $set_id;
    return unless my $ids = $self->rule_ids( undef, 'system' );
    return [ map{ eleMentalClinic::Financial::ValidationRule->new({ rec_id => $_ })->retrieve } @$ids ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 payer_rules_used( $validation_set_id[, $payer_id ])

Object method.

Returns a list of L<eleMentalClinic::Financial::ValidationRule> objects.  With
no C<$payer_id>, returns all rules used by the current validation set (that is,
all rules for which there are results).  With a C<$payer_id>, returns only
rules for which there are results associated with the given payer.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub payer_rules_used {
    my $self = shift;
    my( $set_id, $payer_id ) = @_;

    return unless $set_id and $payer_id;
    return unless my $ids = $self->rule_ids( $payer_id, 'payer' );
    return [ map{ eleMentalClinic::Financial::ValidationRule->new({ rec_id => $_ })->retrieve } @$ids ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# it'd be nice to break this up, but it's all just to create one query
# need to add these fields:
#   note.note_date
#   note.client.eman
#   note.bounced
sub results {
    my $self = shift;
    my( $set_id, $status, $payer_id ) = @_;
    return unless $set_id;

    return unless my $rule_ids = $self->rule_ids( $payer_id );
    my $rule_columns = '';
    my $pass_columns = '';
    for( @$rule_ids ) {
        $rule_columns .=
        qq/ COUNT( CASE WHEN pass = TRUE AND validation_rule_id = $_ THEN TRUE ELSE NULL END ) AS rule_$_, / ."\n";
        $pass_columns .=
        qq/ COUNT( CASE WHEN pass = TRUE AND validation_rule_id = $_ THEN TRUE ELSE NULL END ) */ ."\n";
    }
    chomp $pass_columns; # remove line end
    chop $pass_columns; # remove last multiply sign (*)
    my $pass_clause = qq/
        CASE WHEN force_valid IS NULL THEN
            $pass_columns
        ELSE
            CASE WHEN force_valid IS TRUE THEN 1 ELSE 0 END
        END
    /;

    my $payer_clause = $payer_id
        ? q/ AND validation_prognote.rolodex_id = ? AND payer_validation IS TRUE /
        : '';

    my $having = '';
    my $where_exclude_bounced = q/ AND prognote.rec_id IN/;
    if( defined $status and $status eq 1 ) {
        $having = qq/ HAVING $pass_clause = 1 /;
    }
    elsif( defined $status and $status eq 0 ) {
        $having = qq/ HAVING $pass_clause = 0 /;
        $where_exclude_bounced = q/ AND prognote.rec_id NOT IN/;
    }

    my $prognote_fields = eleMentalClinic::ProgressNote->fields_qualified;
    my $client_name_clause = eleMentalClinic::Client->name_clause;
    my $prognote_bounced = q/CASE WHEN prognote_bounced.bounce_date IS NOT NULL THEN TRUE ELSE FALSE END/;
    my $query = qq|
        SELECT
            $prognote_fields,
            prognote.rec_id AS id,
            DATE( prognote.start_date ) AS note_date,
            EXTRACT( EPOCH FROM CAST ( end_date AS TIME ) - CAST( start_date AS TIME )) / 60 AS note_duration,
            validation_prognote_id, payer_validation, rolodex_id, force_valid,
            $rule_columns
            $pass_clause AS pass,
            $client_name_clause AS client_name,
            $prognote_bounced AS bounced,
            valid_data_charge_code.name AS charge_code_name,
            valid_data_prognote_location.name AS location_name
        FROM prognote
            LEFT JOIN validation_prognote ON validation_prognote.prognote_id = prognote.rec_id
            LEFT JOIN validation_result ON validation_result.validation_prognote_id = validation_prognote.rec_id
            LEFT JOIN client ON client.client_id = prognote.client_id
            LEFT JOIN prognote_bounced ON prognote_bounced.prognote_id = prognote.rec_id
            LEFT JOIN valid_data_charge_code ON valid_data_charge_code.rec_id = prognote.charge_code_id
            LEFT JOIN valid_data_prognote_location ON valid_data_prognote_location.rec_id = prognote.note_location_id
        WHERE validation_set_id = $set_id $payer_clause
        GROUP BY $prognote_fields, validation_prognote_id, payer_validation, rolodex_id, force_valid, $client_name_clause, $prognote_bounced, valid_data_charge_code.name, valid_data_prognote_location.name
            $having
        ORDER BY prognote.rec_id
    |;

    my $results = $payer_id
        ? $self->db->fetch_hashref( $query, $payer_id )
        : $self->db->fetch_hashref( $query );

    return unless $results->[0]; #Do not return an empty array.

    return $self->add_note_units($results);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub validation_query {
    my $self = shift;
    my( $set_id, $type, $rule, $payer_id ) = @_;

    return unless $set_id;
    return unless $type and $SELECT_{ $type };

    # payer_id always means filter by payer, and that's always the placeholder
    my $payer_clause = $payer_id
        ? " AND validation_prognote.rolodex_id = ?\n"
        : '';
    # difficult to conditionally add this space anywhere else
    my $rule_where = ' '. $rule->{ rule_where }
        if $rule->{ rule_where };
    my $query = $SELECT_{ $type } . ( $rule->{ rule_select } || '' ) ."\n"
        . $FROM                   . ( $rule->{ rule_from }   || '' ) ."\n"
        . $WHERE . $set_id        . ( $rule_where            || '' ) ."\n"
        . $payer_clause
        . $ORDER_{ $type }        . ( $rule->{ rule_order }  || '' )
        ;

    # substitute payer_id for placeholders.  we used to use bind values for
    # this, but the only reliable way to do that is count the number of
    # placeholders.  as long as we're counting, we may as well replace instead.

    $payer_id and $query =~ s/\?/$payer_id/g;
    return $query;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub test_validate_sql {
    my $self = shift;
    my( $set_id, $rule, $payer_id ) = @_;
    return unless $set_id;

    my $query = $self->validation_query( 'prognote', $rule, $payer_id );
    my $results = $self->db->dbh->selectcol_arrayref( $query );

    # if the rule is inclusive then we're done, and we return
    unless( defined $rule->{ selects_pass } and not $rule->{ selects_pass }) {
        return unless @$results;
        return $results;
    }

    # if the rule is exclusive we subtract the results from progress notes
    my @clean;
    for my $note_id( map $_->{ id } => @{ $self->prognotes( $payer_id )}) {
        next if grep /^$note_id$/ => @$results;
        push @clean => $note_id;
    }
    return unless @clean;
    return \@clean;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub live_validate_sql {
    my $self = shift;
    my( $set_id, $rule, $payer_id ) = @_;
    return unless $set_id;

    my( $pass, $fail ) = $rule->{ selects_pass }
        ? ( 'TRUE', 'FALSE' )
        : ( 'FALSE', 'TRUE' );
    # insert all the results with "pass" = $fail condition
    my( $sth, $results );
    my $insert = qq/
        INSERT INTO validation_result( validation_prognote_id, validation_rule_id, pass )
        SELECT rec_id, $$rule{ rec_id }, $fail FROM validation_prognote
        WHERE validation_set_id = $set_id
    /;
    $payer_id and $insert .= qq/ AND rolodex_id = $payer_id /;
    $sth = $self->db->dbh->prepare( $insert );
    $results = $sth->execute;
    return unless $results;

    # update the "pass" = $pass condition for notes which pass the validation
    my $query = $self->validation_query( 'validation_prognotes', $rule, $payer_id );
    my $update = qq/
        UPDATE validation_result
        SET pass = $pass
        WHERE validation_rule_id = $$rule{ rec_id }
        AND validation_prognote_id IN ( $query )
    /;
    $sth = $self->db->dbh->prepare( $update );
    $results = $sth->execute;

    return unless $results;
    $self->status( 'Validating' );
    $self->save;
    return $results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# wrapper for _validate()
sub system_validation {
    my $self = shift;
    my( $set_id, $rule_ids ) = @_;

    return unless $set_id and $rule_ids;

    $self->db->transaction_begin;
#     die 'like a dog'
    return $self->db->transaction_rollback
        unless $self->_validate( $set_id, $rule_ids );

    $self->status( 'Validated' );
    return $self->db->transaction_rollback
        unless $self->save;

    $self->db->transaction_commit;
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# wrapper for _validate()
sub payer_validation {
    my $self = shift;
    my( $set_id, $rule_ids, $payer_id ) = @_;

    return unless $set_id and $rule_ids and @$rule_ids and $payer_id;

    $self->db->transaction_begin;
    return $self->db->transaction_rollback
        unless $self->_validate( $set_id, $rule_ids, $payer_id );

    my $update = qq/
        UPDATE validation_prognote
        SET payer_validation = TRUE
        WHERE validation_set_id = $set_id
        AND rolodex_id = $payer_id
    /;
    my $updated = $self->db->do_sql( $update, 'return' );
    return $self->db->transaction_rollback
        unless $updated;
    $self->db->transaction_commit;
    return $updated;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate against all incoming rules
sub _validate {
    my $self = shift;
    my( $set_id, $rule_ids, $payer_id ) = @_;

    return unless $set_id and $rule_ids and @$rule_ids;

    # run all validation rules
    for my $rule_id( @$rule_ids ) {
        return unless
            $self->live_validate_sql(
                eleMentalClinic::Financial::ValidationRule->new->id( $rule_id )->retrieve,
                $payer_id
            );
    }
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_active {
    my $class = shift;
    my( $where ) = @_;

    $where = q/ WHERE step > 0 / . ( $where
        ? "AND $where"
        : '' );
    return unless my $objects = $class->db->select_many(
        $class->fields,
        $class->table,
        $where,
        'ORDER BY creation_date',
    );
    return[ map { $class->new( $_ )} @$objects ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub system_rules {
    my $class = shift;
    eleMentalClinic::Financial::ValidationRule->system_rules;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub payer_rules {
    my $class = shift;
    my( $payer_id ) = @_;
    eleMentalClinic::Financial::ValidationRule->payer_rules( $payer_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 set_note_billing_status( $status )

Object method.

Sets the billing_status field of every progress note in the current validation
set or billing cycle to C<$status>.  If C<$status> is undefined, sets status
column to NULL.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub set_note_billing_status {
    my $self = shift;
    my( $set_id, $status, $ids ) = @_;

    return unless $set_id;
    my $status_clause = $status
        ? qq/SET billing_status = '$status'/
        : q/SET billing_status = NULL/;

    $ids ||= [];
    my $subselect = @$ids
        ? join ',' => @$ids
        : qq/
            SELECT prognote_id
            FROM validation_prognote
            WHERE validation_set_id = $set_id
        /;
    my $update = qq/
        UPDATE prognote
        $status_clause
        WHERE prognote.rec_id IN ( $subselect )
    /;
    my $sth = $self->db->dbh->prepare( $update );
    my $results = $sth->execute;
    return unless $results;
    return $results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 rules_failed_by_prognote_id( $set_id, $prognote_id )

Class method; should be subclassed.

Returns list of L<eleMentalClinic::ValidationRule> objects representing which
rules the C<$prognote_id> progress note, in the C<$set_id> validation set, has
failed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub rules_failed_by_prognote_id {
    my $self = shift;
    my( $set_id, $prognote_id ) = @_;

    die 'Progress note id is required'
        unless $set_id and $prognote_id;

    dbquoteme( \$set_id, \$prognote_id );
    my $fields = eleMentalClinic::Financial::ValidationRule->fields_qualified;
    my $query = qq/
        SELECT $fields
        FROM validation_rule, validation_result, validation_prognote
        WHERE validation_result.validation_rule_id = validation_rule.rec_id
            AND validation_result.validation_prognote_id = validation_prognote.rec_id
            AND validation_prognote.prognote_id = $prognote_id
            AND validation_prognote.validation_set_id = $set_id
            AND validation_result.pass IS FALSE
        ORDER BY validation_rule.name, validation_rule.rec_id
    /;
    my $results = $self->db->do_sql( $query );
    return unless $results and @$results;
    return [ map{ eleMentalClinic::Financial::ValidationRule->new( $_ )} @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 insurers()

Object method.

Returns a list of L<eleMentalClinic::Rolodex> objects associated with the
current set.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub insurers {
    my $self = shift;
    my( $set_id ) = @_;

    my $query = qq/
        SELECT DISTINCT rolodex_id
        FROM validation_prognote
        WHERE validation_prognote.validation_set_id = $set_id
        AND rolodex_id IS NOT NULL
        ORDER BY rolodex_id
    /;
    my $results = $self->db->do_sql( $query );
    return unless $results and @$results and $results->[ 0 ]{ rolodex_id };
    return [ map{ eleMentalClinic::Rolodex->retrieve( $_->{ rolodex_id })} @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 payer_is_validated( $set_id, $payer_id )

Object method.

Has payer validation been run?  Examines one row from C<validation_prognote>
table with current C<$set_id> and C<$payer_id>, returns true/false value of
C<payer_validation> column.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub payer_is_validated {
    my $self = shift;
    my( $set_id, $payer_id ) = @_;

    croak 'Validation set id is required'
        unless $set_id;
    croak 'Payer id is required'
        unless $payer_id;

    dbquoteme( \$set_id, \$payer_id );
    my $validated = $self->db->select_one(
        [ 'payer_validation' ],
        'validation_prognote',
        qq/ validation_prognote.validation_set_id = $set_id
            AND rolodex_id = $payer_id/,
        'LIMIT 1',
    );
    return 0 unless $validated;
    return $validated->{ payer_validation };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 validation_prognote_force_valid( $validation_prognote_id, [ $force ])

Class method.

Updates the C<validation_prognote> record by changing its C<force_valid> flag.
If C<$force> is defined, C<force_valid> is set to C<TRUE> or C<FALSE> depending
on the truthiness of C<$force>.  If C<$force> is not defined, C<force_valid> is
set to NULL.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub validation_prognote_force_valid {
    my $class = shift;
    my( $validation_prognote_id, $force ) = @_;

    die 'Validation prognote id is required'
        unless $validation_prognote_id;

    my $force_valid = defined $force
        ? $force ? 'TRUE' : 'FALSE'
        : 'NULL';

    my $update = qq/
        UPDATE validation_prognote
        SET force_valid = $force_valid
        WHERE rec_id = $validation_prognote_id
    /;
    my $sth = $class->db->dbh->prepare( $update );
    return $sth->execute;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 validation_prognotes_by_insurer

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub validation_prognotes_by_insurer {
    my $self = shift;
    my %by_insurer = ();

    # get the list of prognotes that passed validation
    # XXX the results method needs to be called here using the API of the 
    # child class (BillingCycle or ValidationSet) instead of the parent (Validator) class.
    # TODO could be optimized
    my $results = $self->results( 1 );
    my @prognotes = map { eleMentalClinic::ProgressNote->new( $_ ) } @$results;
    return unless $prognotes[0];

    PROGNOTE:
    for my $prognote ( @prognotes ){

        # this will get the insurances in order by rank
        my $insurances = $prognote->get_mental_health_insurers;

        INSURANCE: 
        for my $client_insurance ( @$insurances ){

            # TODO if there's a refunded txn, potentially we want to ignore this billing, and rebill this insurance. See also #562.

            my $billing_service = eleMentalClinic::Financial::BillingService->get_by_insurance( $prognote->rec_id, $client_insurance->rec_id );
            unless ( $billing_service and $billing_service->billed_amount ){
            
                # If it's never been billed by this insurance, use it
                my $rolodex_id = $client_insurance->rolodex_id;
                push @{ $by_insurer{ $rolodex_id } } => $prognote->rec_id;

                next PROGNOTE;
            }
      
            # Find if there was a transaction recorded for this billing_service
            my $transaction = $billing_service->valid_transaction; # refunded ones are invalid; ok for now, see TODO above
        
            # It's been billed, but not paid yet - do not bill this prognote
            next PROGNOTE
                unless $transaction;
        
            # This prognote is all paid off, do not bill
            next PROGNOTE
                if $billing_service->is_fully_paid;

            # This insurance partially paid the note, send it to the next insurance
            next INSURANCE;
        }
    }

    return \%by_insurer;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_prognotes_by_insurer {
    my $self = shift;
    my( $set_id ) = @_;

    return unless $set_id;

    $self->db->transaction_begin;
    my $by_insurer = $self->validation_prognotes_by_insurer;
    for( keys %$by_insurer ) {
        my $notes = join ',' => @{ $by_insurer->{ $_ }};
        my $update = qq/
            UPDATE validation_prognote
            SET rolodex_id = $_
            WHERE validation_set_id = $set_id
            AND prognote_id IN ( $notes )
        /;
        my $return = $self->db->do_sql( $update, 'return' );
        return $self->db->transaction_rollback
            unless $return and $return = scalar @{ $by_insurer->{ $_ }};
    }

    return $self->db->transaction_commit;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 prognotes_not_selected()

Object method.

Returns prognotes in date range B<not> selected for this set.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub prognotes_not_selected {
    my $self = shift;
    my( $set_id ) = @_;

    die 'Validation set id is required'
        unless $set_id;
    my $client_name_clause = eleMentalClinic::Client->name_clause;
    # similar query in prognotes()
    my $query = qq|
        SELECT 
            prognote.rec_id AS id,
            prognote.client_id,
            prognote.writer,
            prognote.note_body,
            prognote.billing_status,
            prognote.start_date,
            DATE( prognote.start_date ) AS note_date,
            EXTRACT( EPOCH FROM CAST ( end_date AS TIME ) - CAST( start_date AS TIME )) / 60 AS note_duration,
            $client_name_clause AS client_name,
            valid_data_charge_code.name AS charge_code_name,
            valid_data_prognote_location.name AS location_name
        FROM prognote
            LEFT JOIN client ON client.client_id = prognote.client_id
            LEFT JOIN valid_data_charge_code ON valid_data_charge_code.rec_id = prognote.charge_code_id
            LEFT JOIN valid_data_prognote_location ON valid_data_prognote_location.rec_id = prognote.note_location_id
        WHERE
            DATE( prognote.start_date ) BETWEEN DATE( ? ) AND DATE( ? )
            AND prognote.rec_id NOT IN (
                SELECT prognote.rec_id
                FROM prognote
                LEFT JOIN validation_prognote ON prognote.rec_id = validation_prognote.prognote_id
                WHERE validation_prognote.validation_set_id = ?
            )
            AND( prognote.billing_status NOT IN ( 'Paid' ) OR prognote.billing_status IS NULL )
        ORDER BY prognote.start_date, prognote.end_date, prognote.rec_id 
    |;
    return unless my $results = $self->db->fetch_hashref( $query, $self->from_date, $self->to_date, $set_id );

    return $self->add_note_units( $results );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 clients()

Object method.

Returns a data structure of all clients who have progress notes in this set,
with client id as a hash key and the client object as the hash value.  IOW:

    {
        666  => eleMentalClinic::Client->retrieve( 666 ),
        1001 => eleMentalClinic::Client->retrieve( 1001 ),
    }

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub clients {
    my $self = shift;
    my( $set_id ) = @_;

    my $query = qq|
        SELECT DISTINCT client_id
        FROM prognote
        WHERE rec_id IN
            ( SELECT prognote_id FROM validation_prognote WHERE validation_set_id = ? )
    |;

    my $sth = $self->db->dbh->prepare( $query );
    $sth->execute( $set_id );
    my $results = $sth->fetchall_arrayref;
    return unless @$results;
    return{ map{ @$_ => eleMentalClinic::Client->retrieve( @$_ )} @$results };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
 
=head2 set_notes_which_fail_rule( $set_id, $rule_id, $status ) 
 
Object method. All notes in the set which fail rule C<$rule_id> have their 
billing_status set to C<$status>. 
 
=cut 
 
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
sub set_notes_which_fail_rule { 
    my $self = shift; 
    my( $set_id, $rule_id, $status, $payer_id ) = @_; 
 
    die 'rule_id and status are required'
    unless $set_id and $rule_id and $status; 
 
    my $payer_clause = $payer_id 
        ? q/ AND validation_prognote.rolodex_id = ? / 
        : ''; 

    my $query = qq| 
        UPDATE prognote 
        SET billing_status = ? 
        WHERE prognote.rec_id IN ( 
            SELECT 
                prognote.rec_id 
            FROM prognote 
                LEFT JOIN validation_prognote ON validation_prognote.prognote_id = prognote.rec_id 
                LEFT JOIN validation_result ON validation_result.validation_prognote_id = validation_prognote.rec_id 
            WHERE 
                validation_set_id = ? 
                AND validation_result.validation_rule_id = ? 
                AND validation_result.pass = FALSE 
                $payer_clause
        ) 
    |; 
 
    my $sth = $self->db->dbh->prepare( $query ); 
    return $payer_id 
        ? $sth->execute( $status, $set_id, $rule_id, $payer_id ) 
        : $sth->execute( $status, $set_id, $rule_id ); 
} 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 add_note_units()

Object method.
Add units key/value to prognote hashes

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub add_note_units {
    my $self = shift;
    my ( $notes ) = @_;
    return unless $notes;
    
    # The units function in ProgressNote.pm is tested there, instead of  
    # re-implimenting the logic and tests a second time I decided to 
    # call that units function. 
    $_->{ 'note_units' } = eleMentalClinic::ProgressNote->retrieve( $_->{ 'id' })->units
        foreach( @$notes );

    return $notes;
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
