package eleMentalClinic::ProgressNote;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::ProgressNote

=head1 SYNOPSIS

Progress note.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base::Note /;
use Carp;
use Date::Calc qw/ Delta_DHMS Today Now /;
use List::Util qw/ first /;
use eleMentalClinic::Util;
use eleMentalClinic::ValidData;
use eleMentalClinic::TreatmentGoal;
use eleMentalClinic::Group;
use eleMentalClinic::ProgressNote::Bounced;
use eleMentalClinic::Financial::ValidationSet;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Note: staff_id is the id for writer; data_entry_id is the
# id for the person creating/modifying the record
{
    sub table  { 'prognote' }
    sub fields { [ qw/
        rec_id client_id billing_status staff_id goal_id start_date end_date
        note_header note_body audit_trail charge_code_id outcome_rating writer
        note_committed note_location_id data_entry_id group_id created modified
        unbillable_per_writer bill_manually previous_billing_status
        digital_signature digital_signer
    /] }
    sub primary_key { 'rec_id' }
    sub accessors_retrieve_many {
        {
            billing_prognotes   => { prognote_id => 'eleMentalClinic::Financial::BillingPrognote' }
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;
    $self->SUPER::init( $args );

    # handle volatile fields passed to new.
    if($args->{'note_date'}) {
        if($args->{'start_time'}) {
            $self->start_date($args->{'note_date'} .' '. $args->{'start_time'});
        } 

        if($args->{'end_time'}) {
            my $note_date = $args->{'note_date'};

            # if end time less than start time, then we've wrapped a day.
            { no warnings qw/ uninitialized /;
                (my $start = $args->{start_time}) =~ s/://g;
                (my $end = $args->{end_time}) =~ s/://g;
                if($end < $start) {
                    my ($year,$month,$day) = ($note_date =~ m/^(\d{4}).(\d+).(\d+)/);
                    ($year,$month,$day) = Date::Calc::Add_Delta_Days($year,$month,$day,1);
                    $note_date = sprintf('%4d-%02d-%02d',$year,$month,$day);
                }
            }
            $self->end_date($note_date .' '. $args->{'end_time'});
        }
    }

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub units {
    my $self = shift;

    my $min = $self->note_duration_minutes;
    my $cc  = $self->charge_code();

    # this is to prevent div by zero
    return 0 unless ($cc->{minutes_per_unit});
    # this is to prevent general insanity (e.g., the user has no insurance or
    # that insurance is basically a write-off)
    return 0 unless (defined($min) && defined($cc->{minutes_per_unit}));

    return 0 + sprintf( '%.2f', $min / $cc->{minutes_per_unit} );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_all {
    my $self = shift;
    my( $client_id, $from, $to, $writer_id ) = @_;
    $client_id ||= $self->client_id;

    my $where = "WHERE NOT ( group_id IS NOT NULL AND note_committed = 0 )";
    $where .= " AND client_id = $client_id"
        if $client_id;
    $where .= ' AND '. $self->date_range_sql( "start_date", "end_date", $from, $to )
        if $self->date_range_sql( "start_date", "end_date", $from, $to );
    $where .= " AND staff_id = $writer_id"
        if $writer_id;

    return $self->db->select_many(
        $self->fields,
        $self->table,
        $where,
        "ORDER BY start_date DESC, created DESC, rec_id"
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_recent {
    my $class = shift;
    my( $client_id, $limit ) = @_;
    return unless $limit;

    my $where = "WHERE NOT ( group_id IS NOT NULL AND note_committed = 0 )";
    $where .= " AND client_id = $client_id" if $client_id;

    return unless my $results = $class->db->select_many(
        $class->fields,
        $class->table,
        $where,
        "ORDER BY start_date DESC, end_date DESC, rec_id DESC LIMIT $limit",
    );
    return $results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 list_recent_byheader()

Most recent prognotes, filtered by note_header field and ordered by date
descending.  A limit parameter sets how many records to return.

TODO - this could simply be a class method?

=over 4

=item client_id (required)

Client to pull prognotes for.

=item limit (required)

Max records to pull.

=item header (required)

Filter for the note_header field.

=back

=cut

sub list_recent_byheader {
    my $self = shift;
    my( $client_id, $limit, $header) = @_;
    
    return unless $client_id && $limit && $header;

    # XXX MERGE
#    my $where = "WHERE active = 1 AND NOT ( group_id IS NOT NULL AND note_committed = 0 )";
    my $where = "WHERE NOT ( group_id IS NOT NULL AND note_committed = 0 )";
    $where .= " AND client_id = $client_id";
    $where .= " AND note_header = '$header'";

    return unless my $results = $self->db->select_many( $self->fields, $self->table, $where, "ORDER BY start_date DESC LIMIT $limit" );

    return $results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_recent {
    my $class = shift;

    return unless
        my $recent = $class->list_recent( @_ );
    return[ map{ $class->new( $_ )} @$recent ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub commit {
    my $self = shift;
    $self->note_committed(1);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub sign_and_commit {
    my $self = shift;
    my ( $user ) = @_;
    return unless $user;

    my $date = sprintf( '%04d-%02d-%02d', Today());
    my $time = sprintf( '%02d:%02d', Now());

    $self->digital_signature( join( ' ',
        "Digitally signed by",
        $user->fname,
        $user->lname,
        "on",
        $date,
        $time,
    ));
    $self->digital_signer( $user->staff_id );
    $self->commit();
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_billed {
    my $self = shift;
    $self->billing_status eq "Billed" or $self->billing_status eq "BilledManually";
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub location {
    my $self = shift;

    return unless $self->note_location_id;
    eleMentalClinic::ValidData->new({ dept_id => 1001 })->get( '_prognote_location', $self->note_location_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO this doesn't belong here
sub charge_codes {
    my $self = shift;
    my( $dept_id ) = @_;
    return unless $dept_id;

    eleMentalClinic::ValidData->new({
        dept_id => $dept_id,
    })->list( '_charge_code' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 charge_code( $rolodex_id )

Object method.

Returns the L<eleMentalClinic::ValidData> object corresponding to this
prognote's charge code.  Accounts for any insurer-specific charge code
customizations at time of note.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub charge_code {
    my $self = shift;
    my( $rolodex_id ) = @_;

    croak 'Must call on stored object'
        unless $self->id;

    unless( $rolodex_id ) {
        my $insurer = $self->client->mental_health_provider( $self->start_date );
        $rolodex_id = $insurer->rolodex->id
            if $insurer;
    }
    my $codes = eleMentalClinic::Lookup::ChargeCodes->charge_codes_by_insurer( $rolodex_id );
    return $codes->{ $self->charge_code_id };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub editable {
    my $self = shift;
    my $client_id = $self->client_id;
    my $staff_id = $self->staff_id;
    return unless $self->rec_id and $client_id and $staff_id;
    return 0 if $self->note_committed;

    my $fields = [ 'note_committed' ];
    my $table = $self->table;
    my $where = "WHERE client_id = $client_id AND staff_id = $staff_id";
    my $order = "ORDER BY note_committed DESC";
    
    my $commit_flags = $self->db->select_many_arrayref($fields, $table, $where, $order);
    
    return 1 if grep {$_} @$commit_flags; # FIXME: wtf is this?
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub note_date {
    my $self = shift;
    return unless $self->start_date;

    my ($date,$time) = split ' ',$self->start_date;
    return unless $date;
    return $date;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub start_time {
    my $self = shift;
    return unless $self->start_date;

    #$self->start_date =~ /.* 0?(.*)/;
    $self->start_date =~ /.* (\d+:\d\d).*/;
    (my $start_time = $1) =~ s/^00/0/g;
    $start_time =~ s/^0([1-9])/$1/;
    return $start_time or undef;
#    return $1 or undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub end_time {
    my $self = shift;
    return unless $self->end_date;

    $self->end_date =~ /.* (\d+:\d\d).*/;
    (my $end_time = $1) =~ s/^00/0/g;
    $end_time =~ s/^0([1-9])/$1/;
    return $end_time or undef;
#    return $1 or undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    # XXX MERGE
#    $self->active(1) unless defined $self->active;

# XXX MERGE all until the next MERGE was commented in Simple
# Counter productive for simple, where we want control of
# the note_header.
#    if( defined $self->goal_id and $self->goal_id eq 0 ){
#        $self->note_header('Case Note');
#    }
#    else {
#        $self->note_header('Core Services');
#    }
# XXX MERGE all from the last MERGE was commented in Simple

    unless ( $self->created ) {
        $self->created( $self->timestamp ) if $self->note_committed;
    }
    $self->modified( $self->timestamp );
    
#    unless( $self->id ) {
#        # a quick-and-dirty approach to the date
#        my @now = localtime(time);
#        $now[4] += 1;
#        $now[4] = "0".$now[4] if $now[4] < 10;
#        $now[3] = "0".$now[3] if $now[3] < 10;
#        my $date = $now[5]+1900 . "-" . $now[4] . "-" . $now[3];
#        my $audit = $date;
#        $audit .= " " . $self->writer if $self->writer;
#        $self->audit_trail($audit);
#        $self->start_date($date);
#    }
    $self->SUPER::save;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub goal {
    my $self = shift;

    return unless $self->goal_id;
    my $goal = eleMentalClinic::TreatmentGoal->retrieve( $self->goal_id );
    return unless $goal->client_id;
    $goal;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_group {
    my $self = shift;
    return unless $self->group_id;
    my $group = eleMentalClinic::Group->new({
        rec_id => $self->group_id
    })->retrieve;
    return unless $group->id;
    return $group;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_attendee {
    my $self = shift;
    return unless $self->id;
    eleMentalClinic::Group::Attendee->get_byprognote( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_group_uncommitted {
    my $self = shift;
    my( $client_id ) = @_;
    return unless $client_id;

    return unless my $prognotes = $self->db->select_many(
        $self->fields,
        $self->table,
        "WHERE client_id = $client_id AND note_committed = 0",
        'ORDER BY start_date DESC'
    );
    my $class = ref $self;
    my @prognotes;
    push @prognotes, $class->new( $_ ) for @$prognotes;
    return \@prognotes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# accepts minutes
# returns 1 on success, 0 on failure, undef on error
sub note_duration_ok {
    my $self = shift;
    my( $min, $max ) = @_;

    # if we get no params, use the config variables
    if( !defined $min and !defined $max ) {
        $min = $self->config->prognote_min_duration_minutes;
        $max = $self->config->prognote_max_duration_minutes;
    }
    # return as an error if we get only one
    else {
        return if !defined $min or !defined $max;
    }

    # return as error if we still don't have both
    return unless defined $min and defined $max;

    # return as an error if we get a negative range
    return unless $min <= $max;

    my( $d, $h, $m ) = @{ $self->note_duration };
    my $duration = $d * 24 * 60 + $h * 60 + $m;

    return 0 if $duration < $min;
    return 0 if $duration > $max;
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns the duration in minutes
sub note_duration_minutes {
    my $self = shift;

    my( $d, $h, $m ) = @{ $self->note_duration };
    return $d * 24 * 60 + $h * 60 + $m;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns ( days, hours, minutes ) as an arrayref
# tested, but lightly, since we trust date::calc
sub note_duration {
    my $self = shift;
    my( $start, $end ) = @_;

    $start ||= $self->start_date;
    $end ||= $self->end_date;

    return[ 0, 0, 0 ] unless $start and $end;

    my( $start_date, $start_time ) = split( / / => $start );
    my( $end_date, $end_time ) = split( / / => $end );

    # data::calc soils itself if it doesn't get trailing 0 seconds, so we add
    # them here and discard potential extras below
    $start_time .= ':0';
    $end_time .= ':0';

    my( $days, $hours, $min ) = Delta_DHMS(
        split( /-/ => $start_date ), ( split( /:/ => $start_time ))[ 0..2 ],
        split( /-/ => $end_date ), ( split( /:/ => $end_time ))[ 0..2 ]);
    [ $days, $hours, $min ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns undef unless duration is ok
# returns duration as string: "0d 0:00"
# only includes days if duration is over 24 hours
sub note_duration_pretty {
    my $self = shift;

    my( $days, $hours, $min ) = @{ $self->note_duration };
    return '0:00' if( $days < 0 or $hours < 0 or $min < 0 );

    $days = $days
        ? "${ days }d "
        : '';
    $hours = sprintf( "%01d", $hours );
    $min = sprintf( "%02d", $min );
    "$days$hours:$min";
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get total number of hours in prognotes, 
# as a hash of hours per current week, month, year
sub total_duration {
    my $self = shift;
    my( $args ) = @_;
    
    return unless $args->{ staff_id };
    my $date = $args->{ current_date } ? "DATE '$args->{ current_date }'" : 'current_date';
    
    my @fields = ('EXTRACT(EPOCH FROM SUM(end_date - start_date))/3600 as hours');  # total number of hours
    my $table = 'prognote';
    my $where = qq/ staff_id = $args->{ staff_id } AND note_committed = 1 /;
    
    my $week = $self->db->select_one( \@fields, $table,
        $where . qq/ AND EXTRACT(WEEK FROM end_date) = EXTRACT(WEEK FROM $date) 
                     AND EXTRACT(YEAR FROM end_date) = EXTRACT(YEAR FROM $date) /, "" );
    
    my $month = $self->db->select_one( \@fields, $table,
        $where . qq/ AND EXTRACT(MONTH FROM end_date) = EXTRACT(MONTH FROM $date) 
                     AND EXTRACT(YEAR FROM end_date) = EXTRACT(YEAR FROM $date) /, "" );
    
    my $year = $self->db->select_one( \@fields, $table,
        $where . qq/ AND EXTRACT(YEAR FROM end_date) = EXTRACT(YEAR FROM $date) /, "" );
   
    return { 'week'  => $week->{ hours } || 0,
             'month' => $month->{ hours } || 0,
             'year'  => $year->{ hours } || 0, 
           };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_duplicate {
    my $self = shift;
    return unless $self->id;

    my( $start_date, $end_date ) = ( $self->start_date, $self->end_date );

    my $where = ' WHERE client_id ='. $self->client_id;
    $where .= ' AND rec_id !='. $self->id;
    $where .= qq/
        AND (
            (
                start_date >= '$start_date'
                AND start_date <= '$end_date'
            )
            OR (
                end_date >= '$start_date'
                AND end_date <= '$end_date'
            )
            OR (
                start_date <= '$start_date'
                AND end_date >= '$end_date'
            )
        )
    /;

    $self->db->select_many_arrayref(
        [ qw/ rec_id /],
        $self->table,
        $where,
        'ORDER BY start_date DESC, rec_id',
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_do_not_bill {
    my $class = shift;

    $class->new->db->select_many(
        $class->fields,
        $class->table,
        q/WHERE billing_status = 'do_not_bill'/,
        'ORDER BY start_date DESC, rec_id',
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_do_not_bill {
    my $class = shift;
    return unless my $results = $class->list_do_not_bill( @_ );
    return [ map{ $class->new( $_ )} @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub locked {
    my $self = shift;

    return $self->billing_status
        if $self->billing_status
        and grep /^${ \$self->billing_status }$/ => qw/
        Billed
        BilledManually
        Billing
        Paid
        Prebilling
        Unbillable
    /;
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_earliest()

Class method.

Returns the oldest C<eleMentalClinic::ProgressNote> object; i.e. the one with
the earliest C<start_date> field.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_earliest {
    my $class = shift;

    return unless
        my $note = $class->db->select_one(
            $class->fields,
            $class->table,
            undef,
            'ORDER BY start_date ASC LIMIT 1'
        );
    return $class->new( $note );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 bounce( $staff, $message )

Object method.

Inserts a record into prognote_bounced table.  Fails if an active bounce record
already exists.

C<$staff> must be an L<eleMentalClinic::Personnel> object, and is the person
doing the bouncing.  C<$message> is what the note's writer will read to help
them deal with the note.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub bounce {
    my $self = shift;
    my( $staff, $message ) = @_;

    die 'Must call on existing progress note object.'
        unless $self->id;
    die 'Staff and message are required.'
        unless $staff and $message;
    die $self->billing_status .' notes cannot be bounced'
        if $self->billing_status
        and grep /^${ \$self->billing_status }$/
            => qw/ Billed Billing Paid Unbillable BilledManually /;

    # TODO fail if already bounced
    # 'Note has an existing and active bounce record.'

    my $bounced = eleMentalClinic::ProgressNote::Bounced->new({
        prognote_id         => $self->id,
        bounced_by_staff_id => $staff->id,
        bounce_message      => $message,
    })->save;
    return $bounced;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 bounced()

Object method.

Returns the active L<eleMentalClinic::ProgressNote::Bounced> object associated
with the progress note, or undef.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub bounced {
    my $self = shift;
    return eleMentalClinic::ProgressNote::Bounced->get_by_prognote_id( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 validation_rules_failed( $validation_set_id )

Object method.

Returns list of L<eleMentalClinic::ValidationRule> objects representing which
rules the current progress note, in the validation set represented by
C<$validation_set_id>, has failed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub validation_rules_failed {
    my $self = shift;
    my( $validation_set_id ) = @_;

    die 'Validation set id is required'
        unless $validation_set_id;
    return eleMentalClinic::Financial::ValidationSet->
        retrieve( $validation_set_id )->
        rules_failed_by_prognote_id( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 split_charge_code

Object method. Wrapper around eleMentalClinic::ECS::Write837->split_charge_code.
Returns { charge_code => '', modifiers => 'HK' }.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
#FIXME Probably should refactor this and pull the logic into here, from Write837.
sub split_charge_code { 
    my $self = shift;

    return unless $self->charge_code->{ name };

    my( $charge_code, $modifiers ) = eleMentalClinic::ECS::Write837->split_charge_code( $self->charge_code->{ name } );
    $modifiers = join '' => @$modifiers if $modifiers;

    return {
        charge_code => $charge_code,
        modifiers => $modifiers,
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_billed_by_client( $client_id [, $from, $to ])

Return all progress notes for C<$client_id> which have been billed.  That is, we join
to the C<billing_prognote> table. Must also check that the associated billing_file
has actually been billed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_billed_by_client { 
    my $class = shift;
    my( $client_id, $from, $to ) = @_;

    die 'Client id is required'
        unless $client_id;

    dbquoteme( \$client_id, \$from, \$to );
    my $date_filter = ( $from and $to )
        ? qq/ AND DATE( prognote.start_date ) BETWEEN DATE( $from ) AND DATE( $to ) /
        : '';
    my $fields = $class->fields_qualified;
    my $query = qq/
        SELECT DISTINCT $fields
        FROM prognote 
        INNER JOIN billing_prognote ON billing_prognote.prognote_id = prognote.rec_id
        INNER JOIN billing_service ON billing_service.rec_id = billing_prognote.billing_service_id
        INNER JOIN billing_claim ON billing_claim.rec_id = billing_service.billing_claim_id
        INNER JOIN billing_file ON billing_file.rec_id = billing_claim.billing_file_id
        WHERE prognote.client_id = $client_id $date_filter
        AND billing_file.submission_date > DATE('0001-01-01')
        ORDER BY prognote.start_date DESC, prognote.rec_id
    /;
    my $results = $class->db->do_sql( $query );
    return unless $results and @$results;
    return [ map{ $class->new( $_ )} @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 billings()

Object method.

Returns billing data associated with this note.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# XXX Refactoring idea: services_by_client report (which uses this method) is very similar to payments/2.html
sub billings {
    my $self = shift;

    die 'Must call on stored object'
        unless $self->id;

    my $id = dbquote( $self->id );
    my $query = qq/
        SELECT vbp.*
        FROM view_billings_by_prognote AS vbp
        WHERE vbp.prognote_id = $id
        ORDER BY vbp.billed_date ASC, vbp.prognote_id
    /;
    my $results = $self->db->do_sql( $query );
    return [] unless $results and @$results;

    # Add the field "combined" which says that this note is part of a combined note
    # and it's not the first note in the list of notes that are combined.
    for my $result ( @$results ){
        my $billing_service = eleMentalClinic::Financial::BillingService->retrieve( $result->{ billing_service_id } );
        $result->{ combined } = 1
            if @{$billing_service->get_prognotes} > 1
    }

    return $results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_client_insurance( $rolodex_id )

Object method. Returns the client_insurance record for the client's 
mental health insurance at the time of this progress note, for the rolodex_id
passed in.

=cut
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_client_insurance {
    my $self = shift;
    my( $rolodex_id ) = @_;

    die 'Must call on stored object' unless $self->id;
    die 'Rolodex id is required' unless $rolodex_id;

    # NOTE Assuming here that there aren't multiple client_insurances 
    # (for the same rolodex and date) with different ranks!! 
    # So just use the first client_insurance we find. 
    
    my $possible_insurances = $self->get_mental_health_insurers;
    return first { $_->rolodex_id == $rolodex_id } @$possible_insurances;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 combine_identical( $prognotes[, $ignore_staff_id] )

Class method. Takes a list of prognotes and groups together the notes
that are on the same day, by the same staff, for the same charge code,
and at the same location. Returns a hash:

{
    staff_id => { 
        key => L<eleMentalClinic::ProgressNote> object
    }
}

where key is: 'note_date|charge_code_id|note_location_id'

IF $ignore_staff_id is sent, prognotes are grouped by the key, and then the first prognote's
staff_id is used for all notes with that key. In other words, two notes that are otherwise
'identical' but with different staff ids, are combined.

NOTE Once the system is always sending an ID for the clinician (staff) in the 837, we
should never combine notes that have different staff ids.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub combine_identical {
    my $self = shift;
    my( $prognotes, $ignore_staff_id ) = @_;
    my %grouped_notes;

    return undef 
        unless $prognotes and ref $prognotes eq 'ARRAY';

    my @sorted_prognotes = sort { $a->rec_id <=> $b->rec_id } @$prognotes;

    if( $ignore_staff_id ){

        # first put into groups based on date/charge_code/location
        my %grouped_nostaff;
        for my $prognote ( @sorted_prognotes ){
            my $unique_key = $prognote->note_date . '|' 
                        . $prognote->charge_code_id . '|' 
                        . $prognote->note_location_id;
            push @{ $grouped_nostaff{ $unique_key } } => $prognote;
        }

        # then look at each group and assign a staff id to them
        for my $unique_key ( sort keys %grouped_nostaff ){
            # choose the staff from the lowest rec_id prognote
            my $first_prognote = $grouped_nostaff{ $unique_key }[0];
            next unless $first_prognote;
            my $chosen_staff = $first_prognote->staff_id;
            $grouped_notes{ $chosen_staff }{ $unique_key } = $grouped_nostaff{ $unique_key };
        }
    }
    else {

        for my $prognote ( @sorted_prognotes ){
            my $unique_key = $prognote->note_date . '|' 
                        . $prognote->charge_code_id . '|' 
                        . $prognote->note_location_id;
            push @{ $grouped_notes{ $prognote->staff_id }{ $unique_key } } => $prognote;
        }
    }

    return \%grouped_notes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 billing_services( [$rolodex_ids] )

Object method. Returns an array of all billing_service records ever created for
this prognote. If rolodex_ids are sent, only returns billing_services that happened
for payers in the rolodex list.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub billing_services {
    my $self = shift;
    my( $rolodex_ids ) = @_;
    
    die 'Must call on stored object' unless $self->id;
    die 'rolodex_ids must be an array' if $rolodex_ids and ref $rolodex_ids ne 'ARRAY';

    my( $from, $where ) = ( '', '' );
    if( $rolodex_ids ){

        # filter by $rolodex_ids if they exist
        $from = ', billing_claim, billing_file';
        
        $where = qq/ 
            AND billing_service.billing_claim_id = billing_claim.rec_id
            AND billing_claim.billing_file_id = billing_file.rec_id
            AND billing_file.rolodex_id IN ( 
        /;
        $where .= join ', ' => @$rolodex_ids;
        $where .= ' )';
    }

    my $query = qq/
        SELECT billing_service.*
        FROM billing_service, billing_prognote 
        $from
        WHERE billing_service.rec_id = billing_prognote.billing_service_id
        AND billing_prognote.prognote_id = ?
        $where
        ORDER by billing_service.rec_id
    /;

    my $billing_services = $self->db->fetch_hashref( $query, $self->id );

    return [ map {
        eleMentalClinic::Financial::BillingService->new( $_ )
    } @$billing_services ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 billing_services_by_auth( $auth_id )

Object method. Returns an array of all billing_service records ever created for
this prognote, if they happened for this authorization. 
    
=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub billing_services_by_auth {
    my $self = shift;
    my( $auth_id ) = @_;
    
    die 'Must call on stored object' unless $self->id;
    die 'auth_id is required' unless $auth_id;

    my $query = qq/
        SELECT billing_service.*
        FROM billing_service, billing_prognote, billing_claim, client_insurance, client_insurance_authorization
        WHERE billing_service.rec_id = billing_prognote.billing_service_id
        AND billing_prognote.prognote_id = ?
        AND billing_service.billing_claim_id = billing_claim.rec_id
        AND billing_claim.client_insurance_id = client_insurance.rec_id
        AND client_insurance.rec_id = client_insurance_authorization.client_insurance_id
        AND client_insurance_authorization.rec_id = ?
        ORDER by billing_service.rec_id
    /;

    my $billing_services = $self->db->fetch_hashref( $query, $self->id, $auth_id );

    return [ map {
        eleMentalClinic::Financial::BillingService->new( $_ )
    } @$billing_services ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_manual_to_bill

Class method. Search for all notes marked "bill manually"
where billing_status != "billed manually".  Match them with the notes 
they need to be combined with. 

The resulting data is grouped by client and date and returned in 
the following hash structure:

{ 
    client_id => {
        date => {
            'notes' => [ matching notes for that client and date ],
            'deferred' => true | false 
                (if any of the matching notes is deferred due to non-payment)
            'deferred_ids' => [ prognote.rec_id's of any of the deferred matching notes ] | [] (if deferred => false)
        },
        date => { ... (next note group) },
        ...
    },
    client_id => {
        date => { ... },
        ...
    },
    ...    
}

At this time manual billing is intended only for combined notes.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_manual_to_bill {
    my $class = shift;

    # find notes marked bill_manually, that haven't been yet;
    # find any matching notes that should be combined with them;
    # and find which ones are waiting for transactions
    my $query = qq/
        SELECT
            identical.rec_id,
            date(identical.start_date) AS note_date,
            identical.client_id,
            case
                when unpaid.unpaid_services is null then 0
                else unpaid.unpaid_services
            end as unpaid_services
        FROM view_identical_prognotes as identical left outer join view_unpaid_billed_prognotes as unpaid
            on identical.rec_id = unpaid.prognote_id
        WHERE identical.source_rec_id IN ( select rec_id from view_bill_manually_prognotes)
        GROUP BY date(identical.start_date), identical.client_id, identical.rec_id, unpaid.unpaid_services
        ORDER BY identical.client_id, date(identical.start_date), identical.rec_id;
    /;
   
    # NOTE
    # We don't know whether a note will be combined with other notes w/ different staff ids
    # because we don't know who the notes will be billed to in the future
    # So we need to pull out any notes that will potentially combine with these notes.
    # For example:
    # Note 1 was billed, NPI required; Note 2 comes along, should not have been combined;
    # Note 1 gets billed to 2nd insurance where NPIs not required, should be combined with 2; but 2 hasn't been billed to first payer yet.

    my $prognotes = $class->db->fetch_hashref( $query );

    my (%manual_notes, $current);
    for my $note ( @$prognotes ){
       
        # initialize current structure, divide them up into buckets by client and date
        unless ($manual_notes{ $note->{ client_id } }{ $note->{ note_date } }) {
            $current = { notes => [], deferred => 0, deferred_ids => [] };
            $manual_notes{ $note->{ client_id } }{ $note->{ note_date } } = $current;
        }

        # get the full object for each note
        # TODO rather than retrieving each note individually, we could try to 
        # rework the above query to return all the data for a note and call
        # $class->new{ $note }
        push @{ $current->{ notes } } => $class->retrieve( $note->{ rec_id } );

        # marked as deferred and record key if note has unpaid billed services
        if ($note->{ unpaid_services } > 0) { 
            $current->{ deferred } = 1;
            push @{ $current->{ deferred_ids } } => $note->{ rec_id };
        }
    }
 
    return \%manual_notes;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_mental_health_insurers()

Object method. A wrapper for Client::Insurance::get_authorized_insurers,
gets a list of payers for the client & date of this prognote. Orders them by rank.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_mental_health_insurers {
    my $self = shift;

    my $client_insurances = eleMentalClinic::Client::Insurance->get_authorized_insurers( $self->client_id, 'mental health', $self->start_date );
    return unless $client_insurances;
    return [ sort { $a->rank <=> $b->rank } @$client_insurances ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 valid_transactions()

Object method. Returns all valid L<eleMentalClinic::Financial::Transaction> objects 
created for this prognote (ones not entered_in_error or refunded).

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub valid_transactions {
    my $self = shift;

    return [ map { $_->valid_transaction } @{ $self->billing_services } ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 refund()

Object method marks all transactions for this prognote as refunded.

dies if unable to update database;

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub refund {
    my $self = shift;
    return unless $self->id;

    my $transactions = $self->valid_transactions;
    return unless $transactions and scalar @$transactions > 0;

    map{ $_->refund } @$transactions;

    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 billed_billing_prognotes()

Object method. Returns all billing_prognotes created for this note,
that are in files that have actually been billed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub billed_billing_prognotes {
    my $self = shift;
   
    die 'Must call on stored object' unless $self->id;

    my $query = qq/
        SELECT billing_prognote.*
        FROM billing_prognote 
            INNER JOIN billing_service ON billing_prognote.billing_service_id = billing_service.rec_id
            INNER JOIN billing_claim ON billing_service.billing_claim_id = billing_claim.rec_id
            INNER JOIN billing_file ON billing_claim.billing_file_id = billing_file.rec_id
        WHERE billing_prognote.prognote_id = ?
        AND billing_file.submission_date > DATE('0001-01-01')
        AND billing_service.billed_amount > 0
        ORDER by billing_service.rec_id
    /;

    my $billing_prognotes = $self->db->fetch_hashref( $query, $self->id );
    return unless $billing_prognotes;

    return [ map {
        eleMentalClinic::Financial::BillingPrognote->new( $_ )
    } @$billing_prognotes ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub locations { die 'DEPRECATED' }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 get_client_name()

This method will return the name of the client this progress note is
for.

Name is returned in 'Last, First' format.

Object method.

=cut
#
# This function was added specifically so that progress notes can be sorted
# by client name when viewing in the billing lists. I was unable to determine
# a better way at the time of writing this.
#
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_client_name {
    my $self = shift;

    my $client = eleMentalClinic::Client->retrieve( $self->client_id );

    return $client->lname . ', ' . $client->fname;
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Partlow L<jpartlow@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

=item Martin Chase

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
