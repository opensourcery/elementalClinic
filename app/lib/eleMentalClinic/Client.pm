# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Client;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client

=head1 SYNOPSIS

The client.

=head1 METHODS

=cut

use Carp qw(confess);
use Date::Calc qw/ Today Date_to_Days /;
use Data::Dumper;
use eleMentalClinic::Auditor;
use eleMentalClinic::Client::Assessment;
use eleMentalClinic::Client::Contact;
use eleMentalClinic::Client::Diagnosis;
use eleMentalClinic::Client::Employment;
use eleMentalClinic::Client::Income;
use eleMentalClinic::Client::Intake;
use eleMentalClinic::Client::IncomeMetadata;
use eleMentalClinic::Client::Inpatient;
use eleMentalClinic::Client::Insurance;
use eleMentalClinic::Client::Medication;
use eleMentalClinic::Client::Letter;
use eleMentalClinic::Client::Referral;
use eleMentalClinic::Client::Release;
use eleMentalClinic::Client::Treater;
use eleMentalClinic::Client::Allergy;
use eleMentalClinic::Client::Verification;
use eleMentalClinic::Legal;
use eleMentalClinic::Personnel;
use eleMentalClinic::ProgressNote;
use eleMentalClinic::TreatmentPlan;
use eleMentalClinic::Rolodex;
use eleMentalClinic::Group;
use eleMentalClinic::Group::Attendee;
use eleMentalClinic::Client::Placement;
use eleMentalClinic::Financial::Transaction;
use eleMentalClinic::ValidData;
use eleMentalClinic::Contact::Phone;
use eleMentalClinic::Contact::Address;
use eleMentalClinic::Util;
use eleMentalClinic::Mail::Recipient;
use eleMentalClinic::Role::Access;
use eleMentalClinic::Role;

use base qw/ eleMentalClinic::DB::Object /;

with_moose_role "eleMentalClinic::Contact::HasContacts";

{
    # removed in placement refactor
    #   unit_id dept_id track_id active input_by
    #   bed_id staff_id start_date end_date input_on

    sub table { 'client' }
    sub fields {
        [ qw/
            client_id chart_id
            dob ssn mname fname lname name_suffix
            aka living_arrangement
            sex race marital_status substance_abuse
            alcohol_abuse gambling_abuse religion
            acct_id language_spoken sexual_identity
            state_specific_id
            edu_level working section_eight comment_text
            has_declaration_of_mh_treatment
            declaration_of_mh_treatment_date
            is_veteran is_citizen consent_to_treat
            email dont_call renewal_date
            birth_name household_annual_income household_population
            household_population_under18 dependents_count intake_step
            send_notifications nationality_id
            /]
    }
    sub primary_key { 'client_id' }
    sub accessors_retrieve_many {
        {
            prognotes => { client_id => 'eleMentalClinic::ProgressNote' },
            mailings => { client_id => 'eleMentalClinic::Mail::Recipient' },
        };
    }

}

# {{{ lookups
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
our $lookups = {
    contacts => {
        name => 'contacts',
        role_table => 'rolodex_contacts',
        client_table => 'client_contacts',
        role_id => 'rolodex_contacts_id',
        class => 'eleMentalClinic::Client::Contact',
        description => 'Contact',
        role_type_field => 'contact_type_id',
    },
    dental_insurance => {
        name => 'dental_insurance',
        role_table => 'rolodex_dental_insurance',
        client_table => 'client_insurance',
        role_id => 'rolodex_insurance_id',
        carrier_type => 'dental',
        class => 'eleMentalClinic::Client::Insurance',
        description => 'Dental Insurance',
        active_determined_by_date   => 1,
    },
    employment => {
        name => 'employment',
        role_table => 'rolodex_employment',
        client_table => 'client_employment',
        role_id => 'rolodex_employment_id',
        class => 'eleMentalClinic::Client::Employment',
        description => 'Employer',
    },
    medical_insurance => {
        name => 'medical_insurance',
        role_table => 'rolodex_medical_insurance',
        client_table => 'client_insurance',
        role_id => 'rolodex_insurance_id',
        carrier_type => 'medical',
        class => 'eleMentalClinic::Client::Insurance',
        description => 'Medical Insurance',
        active_determined_by_date   => 1,
    },
    mental_health_insurance => {
        name => 'mental_health_insurance',
        role_table => 'rolodex_mental_health_insurance',
        client_table => 'client_insurance',
        carrier_type => 'mental health',
        role_id => 'rolodex_insurance_id',
        class => 'eleMentalClinic::Client::Insurance',
        description => 'Mental Health Insurance',
        active_determined_by_date   => 1,
    },
    referral => {
        name => 'referral',
        role_table => 'rolodex_referral',
        client_table => 'client_referral',
        role_id => 'rolodex_referral_id',
        class => 'eleMentalClinic::Client::Referral',
        description => 'Referral Source',
    },
    release => {
        name => 'release',
        role_table => 'rolodex_release',
        client_table => 'client_release',
        role_id => 'rolodex_release_id',
        class => 'eleMentalClinic::Client::Release',
        description => 'Release Agency',
    },
    treaters => {
        name => 'treaters',
        role_table => 'rolodex_treaters',
        client_table => 'client_treaters',
        role_id => 'rolodex_treaters_id',
        class => 'eleMentalClinic::Client::Treater',
        description => 'Treater',
        role_type_field => 'treater_type_id',
    },
};
# }}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_partial_intake {
    my $self = shift;

    # the intake controller (currently only in Earth) sets this to NULL when
    # it's complete, and the default is 0.
    return defined $self->intake_step;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 intake()

Object method.

Returns the most recent intake object associated with this client.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub intake {
    my $self = shift;
    my $intakes = eleMentalClinic::Client::Intake->get_all_by_client( $self->id );
    return unless $intakes;
    $intakes = [ sort { $a->rec_id <=> $b->rec_id } @$intakes ];
    return $intakes->[-1];
}

=head2 is_discharged()

    if ( $client->is_discharged ) { ... }

Return true if the client is discharged (has an intake, but is not currently
inside an episode).

Returns false if there is no intake, or if there is no discharge event
corresponding to the most recent intake.

=cut

sub is_discharged {
    my $self = shift;
    my $episode = eleMentalClinic::Client::Placement::Episode->new({
        client_id => $self->id,
    });
    return $episode->discharge_date ? 1 : 0;
}

=head2 readmit()

    $client->readmit( %placement_arguments );

Create a new intake object for this client, copied from the most recent one.

Dies if the client has no intake object or if the client is currently admitted
to a program (has not been discharged).

C<%placement_arguments> are passed to C<< $client->placement->change >>.

=cut

sub readmit {
    my $self = shift;
    my %args = @_;
    my $intake = $self->intake
        or die "Can't find an intake for client " . $self->id;
    die "Client " . $self->id . " is not discharged, cannot readmit"
        unless $self->is_discharged;
    $args{event_date} ||= $self->today;

    $self->db->transaction_do(sub {
        my $event = $self->placement->change(
            # XXX hardcoding dept_id -- it never actually changes, and it
            # makes this trivially not a discharge event
            dept_id => 1001,
            %args,
        );

        my $new_intake = eleMentalClinic::Client::Intake->new({
            client_id => $self->id,
            client_placement_event_id => $event->rec_id,
            # get staff_id from the placement event instead of whatever the
            # original intake was; it's likely to have changed, unlike the
            # other client_intake fields
            staff_id => $event->staff_id,
            assessment_id => $intake->assessment_id,
        });

        $new_intake->save;
        $event->update({
            intake_id => $new_intake->rec_id,
            # since we're preparing for a new intake, we always want to wipe
            # this out
            discharge_id => undef,
        });
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub placement {
    my $self = shift;
    my( $date ) = @_;

    return eleMentalClinic::Client::Placement->new({
        client_id   => $self->id,
        date        => $date,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_all {
    my $self = shift;
    my( $args ) = @_;

    # if we're looking for incomplete intakes, they may not have placement records yet
    my $tables = $args && $args->{ intake_incomplete }
        ? q/ client /
        : q/ client LEFT JOIN client_placement_event USING ( client_id ) /;

    # fields
    my $client_fields = $self->fields;

    # these are here because we're joining with personnel
    my %dup_fields = (
        fname           => 'client',
        lname           => 'client',
        dob             => 'client',
        ssn             => 'client',
        client_id       => 'client',
        chart_id        => 'client',
        sex             => 'client',
        race            => 'client',
        marital_status  => 'client',
    );

    #prepending the duplicates with a table name
    @$client_fields = map {
        $dup_fields{ $_ } ? $dup_fields{ $_ } .".$_" : $_
    } @$client_fields;

    my $fields = $client_fields;

    my $order_by = q/ORDER BY client.lname, client.fname, client.mname/;
    my $where = 'WHERE 1=1';
    if( not( $args and $args->{ intake_incomplete })) {
        $where .= q/
            AND client_placement_event.rec_id IN (
                SELECT DISTINCT ON ( client_id )
                    rec_id
                    FROM client_placement_event
                    ORDER BY client_id ASC, event_date DESC
                )
        /;
    }
    if( $args->{ staff_id }) {
        $where .= " AND client_placement_event.staff_id = $$args{ staff_id }";
    }
    if( defined $args->{ active }) {
        $args->{ active }
            ? ( $where .= ' AND client_placement_event.program_id IS NOT NULL' )
            : ( $where .= ' AND client_placement_event.program_id IS NULL' );
    }
    if( $args->{ program_id }) {
        $where .= " AND client_placement_event.program_id = $$args{ program_id }";
    }
    if( $args->{ search } ){
        $where .= $self->search_query( $args->{ search } )->{ where };
    }
    if( $args->{ intake_incomplete }) {
        $where .= ' AND client.intake_step IS NOT NULL';
    }

    $self->db->select_many( $fields, $tables, $where, $order_by );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub search_query {
    my $self = shift;
    my $search_term = shift;
    my %search_add;

    $search_add{ where }  = qq/ AND (

           client.dob::text LIKE '\%$search_term%'
        OR client.ssn LIKE '\%$search_term%'
        OR client.state_specific_id::text LIKE '\%$search_term%'
        OR LOWER(client.lname) LIKE LOWER('\%$search_term%')
        OR LOWER(client.fname) LIKE LOWER('\%$search_term%')

        OR client.client_id IN
            ( SELECT ci.client_id FROM client_insurance ci
            WHERE LOWER(ci.insurance_id) LIKE LOWER('\%$search_term%') )
     ) /;

    return \%search_add;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# removed in placement refactor
#   unit_id dept_id track_id active input_by
#   bed_id staff_id start_date end_date input_on
sub save {
    my $self = shift;

    $self->has_declaration_of_mh_treatment(0) unless $self->has_declaration_of_mh_treatment;
    $self->section_eight(0) unless $self->section_eight;

    $self->SUPER::save( @_ );

    # Almost put logic in DB.pm to handle cases like this, but it is a special
    # case for client. intake_step defaults to 0, undef is skipped over by the
    # db.pm object on save. This means undef is saved as 0 on an insert. This
    # is not desired behavior since 0 means no intake steps, undef means
    # completed.
    unless ( defined $self->intake_step ) {
        $self->db->do_sql(
            "UPDATE " . $self->table . " set intake_step = null WHERE client_id = " . $self->client_id,
            1
        );
    }

    return $self;
}

sub update {
    my $self = shift;
    my $old_renew = $self->renewal_date;
    # Preserve updates usual return value to return after the update.
    my $out = $self->SUPER::update( @_ );
    $self->renew( $old_renew );
    return $out;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 renew()

Enters a progress note logging the renewal, if renewal_date has
changed from the previous_renwal date passed in.

Must be passed a staff_id as well.

=cut

sub renew {
    my $self = shift;
    my( $previous_renewal ) = @_;

#    print STDERR "Beginning renew(); previous_renewal: $previous_renewal\n";

    return unless $self->id;
    $previous_renewal ||= '';

    my $renewal_date = $self->renewal_date;
#    print STDERR "Testing renewal for $renewal_date\n";
    if ($renewal_date && $renewal_date ne $previous_renewal) {
        my $treater = $self->get_primary_treater;
        my $doctor = $treater ? $treater->rolodex->lname : '';

        my $note_id = eleMentalClinic::Auditor->new->audit(
            $self->id,
            'RENEWAL',
            "$doctor: renewal date - $renewal_date",
        );

#        print STDERR "Saved renewal note $note_id\n";

        return $note_id;
    }
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub legal_past_issues {
    my $self = shift;
    my( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    eleMentalClinic::Legal->new->past_issues( $client_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub legal_get_all {
    my $self = shift;
    my( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    eleMentalClinic::Legal->new({ client_id => $self->id })->get_all;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub legal_current_issues {
    my $self = shift;
    my( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    eleMentalClinic::Legal->new->current_issues( $client_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub roi {
    my $self = shift;

    eleMentalClinic::Client::Release->new({
        client_id   => $self->id,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub letter {
    my $self = shift;

    eleMentalClinic::Client::Letter->new({
        client_id   => $self->id,
    });
}

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#sub insurance_getone {
#    my $self = shift;
#    my( $args ) = @_;
#
#    eleMentalClinic::Client::Insurance->new({
#        client_id => $self->client_id,
#        carrier_type => $args->{carrier_type},
#        rank => $args->{rank},
#    })->get_specific($args->{date});
#}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub insurance_bytype {
    my $self = shift;
    my( $type, $active ) = @_;

    eleMentalClinic::Client::Insurance->getall_bytype( $self->client_id, $type, $active );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub authorized_insurers {
    my $self = shift;
    return eleMentalClinic::Client::Insurance->get_authorized_insurers( $self->id, @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub progress_notes {
    my $self = shift;
    my( $from, $to ) = @_;
    return unless $self->client_id;

    eleMentalClinic::ProgressNote->new->list_all( $self->client_id, $from, $to );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all_progress_notes {
    my $self = shift;
    my( $from, $to ) = @_;
    return unless $self->client_id;

    my $notes = 'eleMentalClinic::ProgressNote';

    # XXX reports use this; note that $notes->list_all only adds date_range_sql if
    # both $from and $to exist
    return $notes->get_all( $self->client_id, $from, $to ) if ( $from and $to );

    # XXX this is almost the same as what the above produces, but the sort
    # order is different.  this fixes thcf:#213.  yes, this is horrible.  there
    # isn't a better way right now.
    my $results = $notes->get_many_where(
        [
            'WHERE NOT ( group_id IS NOT NULL AND note_committed = 0 )' .
            'AND client_id = ?',
            $self->client_id,
        ],
        'ORDER BY start_date DESC, created DESC, rec_id DESC',
    );

    # Move invalid records to the bottom. THFC#456
    my $start = [];
    my $end = [];
    for my $result ( @$results ) {
        push @{ $result->{ start_date } ? $start : $end }, $result;
    }
    return [ @$start, @$end ];

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub roi_history {
    my $self = shift;
    my( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    eleMentalClinic::Client::Release->new({
        client_id => $client_id,
    })->get_all;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub treatment_plans {
    my $self = shift;
    my( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    eleMentalClinic::TreatmentPlan->new({
        client_id => $client_id,
    })->get_all;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub allergies {
    my $self = shift;
    my( $active)  = @_;

    return unless my $client_id = $self->client_id;
    eleMentalClinic::Client::Allergy->get_byclient( $client_id, $active );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub verifications {
    my $self = shift;
    #my( $active)  = @_;

    return unless my $client_id = $self->client_id;
    eleMentalClinic::Client::Verification->get_byclient( $client_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub hospital_history {
    my $self = shift;
    my( $client_id)  = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    eleMentalClinic::Client::Inpatient->new({
        client_id => $client_id,
    })->get_all;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub medication_history {
    my $self = shift;
    my( $args )  = @_;
    my $client_id = $args->{ client_id } || $self->client_id;
    return unless $client_id;

    eleMentalClinic::Client::Medication->new({
        client_id => $client_id,
    })->get_all( $args );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex_byrole {
    my $self = shift;
    my( $role, $active )  = @_;

    my $client_id = $self->client_id;
    return unless $role and $client_id;
    return unless eleMentalClinic::Rolodex->valid_role( $role );

    my $r_info = $lookups->{$role};
    my $fields = ['rolodex.*'];
    my $tables = "rolodex, $r_info->{role_table}, $r_info->{client_table} ";
    my $where = qq/
        WHERE $$r_info{client_table}.client_id = $client_id
        AND $r_info->{client_table}.$$r_info{role_id} = $$r_info{role_table}.rec_id
        AND $$r_info{role_table}.rolodex_id = rolodex.rec_id
    /;

    if( $r_info->{ carrier_type } ) {
        $where .= " AND client_insurance.carrier_type = '$r_info->{carrier_type}'";
    }
    if( $role =~ m/treaters/ ) {
        $tables .= ", valid_data_treater_types";
        $where .= ' AND client_treaters.treater_type_id = valid_data_treater_types.rec_id';
    }
    if( $role =~ m/contacts/ ) {
        $tables .= ", valid_data_contact_type";
        $where .= ' AND client_contacts.contact_type_id = valid_data_contact_type.rec_id';
    }
    $where .= " AND $$r_info{client_table}.active = $active"
        if defined $active and not $r_info->{ active_determined_by_date };

    my $other = " ORDER BY rec_id ";

    return eleMentalClinic::Rolodex->get_many_where(
        $where,
        $other,
        [ $tables ],
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex_associate {
    my $self = shift;
    my( $role, $rolodex_id, $role_id ) = @_;
    return unless $role and $rolodex_id and $self->id;

    # return an error if the rolodex_id isn't in_$role
    my $in = "in_$role";
    return unless eleMentalClinic::Rolodex->new({rec_id => $rolodex_id})->retrieve->$in;

    my $rolodex_field;
    $rolodex_field = $role =~ m/insurance/
        ? "rolodex_insurance_id"
        : "rolodex_${role}_id";

    my $fields = [ $rolodex_field,
                   'client_id' ];
    # FIXME $rolodex_id should be translated to the corresponding role table's id
    my $rec_id = $self->db->select_one( ['rec_id'], "rolodex_$role", "rolodex_id = $rolodex_id" )->{rec_id};

    my $values = [ $rec_id,
                   $self->id ];

    if( $role =~ m/insurance/ ) {
        my $ins_role = $role;
        $ins_role =~ s/_insurance//g;
        $ins_role =~ s/_/ /g;  # so we can pass in 'mental_health' FIXME : test this
        push @$values, $ins_role;
        push @$fields, 'carrier_type';
    }

    my $table;
    $table = $role =~ m/insurance/
        ? "client_insurance"
        : "client_$role";

    unless( $role_id ) {
        # insert a record into client_$role
        $role_id = return $self->db->insert_one( $table, $fields, $values );
    }
    else {
        # update a record in client_$role
        $self->db->update_one( $table, $fields, $values, "rec_id = $role_id");
    }

    return $role_id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex_getone {
    my $self = shift;
    my( $role, $rolodex_id ) = @_;
    return unless $role and $rolodex_id and $self->client_id;
    return unless eleMentalClinic::Rolodex->valid_role( $role );
    return if $role eq 'release'; # TODO remove release

    my $r_info = $lookups->{$role};
    my $where = qq/
        $$r_info{role_table}.rolodex_id = $rolodex_id
        AND $$r_info{role_table}.rec_id = $$r_info{client_table}.$$r_info{role_id}
        AND $$r_info{client_table}.client_id = $$self{client_id}
    /;
    if( $r_info->{carrier_type} ) {
        $where .= " AND client_insurance.carrier_type = '$r_info->{carrier_type}'";
    }

    my $hashref = $self->db->select_one(
        ["$r_info->{client_table}.*"],
        "$r_info->{client_table}, $r_info->{role_table}",
        $where
    );
    return unless $hashref;
    $r_info->{class}->new($hashref);
}


=head3 age

    my $age = $client->age;

Client's age, in years.

=cut

sub age {
    my $self = shift;

    my $dob = $self->dob;
    my($year, $month, $day) = split /-/, $dob;
    require DateTime;
    $dob = DateTime->new(
        year    => $year,
        month   => $month,
        day     => $day
    );
    my $delta = DateTime->now - $dob;

    return $delta->years;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ssn_f {
    my $self = shift;
    my( $ssn_f ) = @_;
    my $ssn;

    if( defined $ssn_f ) {
        $ssn = $ssn_f;
        $ssn_f =~ s/\-//g;
        $self->ssn($ssn_f);
    }
    else {
        return unless defined $self->ssn;
        $ssn = $self->ssn;
        $ssn =~ s/(\d{3})(\d{2})(\d{4})/$1-$2-$3/;
    }

    return $ssn;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prescribers {
    eleMentalClinic::Rolodex->new->get_byrole('prescribers');
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub assessment_getall {
    my $self = shift;
    return unless my $client_id = $self->client_id;

    return eleMentalClinic::Client::Assessment->new->get_all_by_client($client_id);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub assessment_listall {
    my $self = shift;
    return unless my $client_id = $self->client_id;

    return eleMentalClinic::Client::Assessment->new->list_all_by_client($client_id);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns most recent assessment
sub assessment {
    my $self = shift;

    return unless my $client_id = $self->client_id;
    return unless $self->assessment_getall;
    return $self->assessment_getall->[ 0 ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub income_history {
    my $self = shift;
    my( $client_id ) = @_;
    $client_id ||= $self->client_id;
    eleMentalClinic::Client::Income->new({
        client_id => $client_id,
    })->get_all;
}

# List of fields which a duplicate should contain
sub _dup_fields {
    return ['client_id', 'lname', 'dob', 'fname', 'mname'];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# [Harry is dressed as an alien for Halloween]
# Mamie Dubcek: Oh, Harry. You're an alien.
# [Harry screams]
# Harry Solomon: NO, I'M NOT! I mean, yes I am.
#
# Why is this method not just returning client objects?
# Chad sez: To view a client object you need permissions. Returning
# dups means returning a client you may not have access too, thus
# access exception. So the dup returns the minimum you need to know
# w/o sensitive data
sub dup_check {
    my $self = shift;
    my $class = ref $self;

    my $client_id = $self->client_id;
    my $ssn = $self->ssn;
    my $lname = $self->lname;
    my $fname = $self->fname;
    my $dob = $self->dob;

    my $dup_fields = $self->_dup_fields;

    my $duplicates = {
        ssn => undef,
        lname_dob => undef,
    };

    return $duplicates
        unless $ssn
        or $lname && $dob
        or $lname && $fname;

    if( $ssn ) {
        my $where = qq|ssn = '$ssn'|;
        $where .= qq| AND client_id != $client_id|
            if $client_id;
        my $result = $self->db->select_one(
            $dup_fields,
            'client',
            $where
        );
        $duplicates->{ ssn } = $result if $result->{ client_id };
    }

    if( $lname and $dob ) {
        my $data_holder = $self->db->select_many(
            $dup_fields,
            'client',
            [ "WHERE lname = ? AND dob = ?", $lname, $dob ]
        );

        if( $data_holder and scalar @$data_holder > 0 ) {
            for( @$data_holder ) {
                push @{ $duplicates->{ lname_dob } } => $_
                    unless $duplicates->{ ssn } and $_->{ client_id } eq $duplicates->{ ssn };
            }
        }
    }

    if ( $fname and $lname ) {
        my $data_holder = $self->db->select_many(
            $dup_fields,
            'client',
            [ "WHERE lname = ? AND fname = ?", $lname, $fname ]
        );

        if( $data_holder and scalar @$data_holder > 0 ) {
            foreach my $row ( @$data_holder ) {
                push @{ $duplicates->{ lname_fname } } => $row unless
                    ($duplicates->{ ssn } and $row->{ client_id } eq $duplicates->{ ssn }) or
                    ($duplicates->{lname_dob} and grep { $row->{client_id} eq $_ } @{$duplicates->{lname_dob}});
            }
        }
    }

    return $duplicates;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub was_referral {
    my $self = shift;
    return unless my $client_id = $self->client_id;

    return 1 if $self->db->select_one(
        ['client_id'],
        'client_referral',
        "client_id = $client_id"
    );
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub income_metadata {
    my $self = shift;
    return unless my $client_id = $self->client_id;

    eleMentalClinic::Client::IncomeMetadata->new->get_byclient($client_id);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub diagnosis_history {
    my $self = shift;
    return unless my $client_id = $self->client_id;

    eleMentalClinic::Client::Diagnosis->new->get_byclient($client_id);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO
# this should wrap other client methods: client->relationships_$role
# the relationships_$role methods should call class methods on the $role
# object
#   e.g.
#   $client->relationships_( 'contacts', active => 1 )
#   $client->relationships_contacts( active => 1 )
#
# Talked with Randall - it looks like work has been begun for an abstract
# Client/Relationship object which the Client/Foo relations could subclass.
# This method could then wander off into Relationship as a general factory method
# and be broken up as needed.
#
# For now, I'm going to add a parameter for obtaining 'singular' records by
# lookup subtype for client_contact, client_treater.
#
# $active
#   1     = active only
#   0     = inactive only
#   undef = active & inactive
#
# $private
#   1     = private only
#   0     = public only
#   undef = private & public
sub relationship_byrole {
    my $self = shift;
    my( $role, $private, $active, $subtype ) = @_;

    die "Role is required" unless $role;
    die "Role '$role' is invalid" unless eleMentalClinic::Rolodex->valid_role( $role );

    my $r_info = $lookups->{$role};
    my $where = $self->_relationship_where($r_info, $private, $active, $subtype);
    return unless defined $where;

    return unless my $hashrefs = $self->db->select_many(
        ["$r_info->{client_table}.*"],
        "$r_info->{client_table}, $r_info->{role_table}, rolodex",
        $where,
        "ORDER BY rolodex.name, $$r_info{client_table}.rec_id"
    );

    my $class = $r_info->{ class };
    $_ = $class->new( $_ ) for @$hashrefs;
    return [ sort( { $a->{rec_id} <=> $b->{rec_id} } @$hashrefs ) ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 relationship_primary

Returns the first relation of passed role and subtype.
Orders by id so that the same relation is always returned.
This method can be used to provide a primary 'emergency contact'
or 'doctor' for a client.

Returns the appropriate Client::<Role> object or undef if there is none.

=over 4

=item role

First parameter must be the relationship role (contact, treater, etc.) or
method dies.  Caller might otherwise be decieved into thinking that no relation
records exist (by an undef return) when in fact they never asked for a relation
of given role...

=item type

Second parameter may be a subtype (contact_type_id, treater_type_id, etc.);

=back

=cut

sub relationship_primary {
    my $self = shift;
    my( $role, $type ) = @_;

    die "Role is required" unless $role;
    die "Role '$role' is not valid" unless eleMentalClinic::Rolodex->valid_role( $role );

    my $r_info = $lookups->{$role};
    my $where = $self->_relationship_where($r_info, undef, 1, $type);
    return unless defined $where;

    my $class = $r_info->{class};
    return +($class->get_many_where(
        $where,
        'ORDER BY ' . $class->fields_qualified('rec_id') . ' ASC LIMIT 1',
        [ "$r_info->{client_table}, $r_info->{role_table}, rolodex" ],
    ) || [])->[0];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 _relationship_where

Builds the sql where string needed by other relationship accessors.

=over 4

=item r_info
   role_info from $lookup

=item active
   1     = active only
   0     = inactive only
   undef = active & inactive

=item private
   1     = private only
   0     = public only
   undef = private & public

=item type
   <relationship>_type_id

=cut

sub _relationship_where {
    my $self = shift;
    my( $r_info, $private, $active, $type) = @_;

    return unless ref $r_info eq 'HASH';
    return unless my $client_id = $self->client_id;

    my $where = qq/
        WHERE $$r_info{role_table}.rec_id = $$r_info{client_table}.$$r_info{role_id}
        AND $$r_info{client_table}.client_id = $client_id
        AND $$r_info{role_table}.rolodex_id = rolodex.rec_id
    /;
    if( $r_info->{carrier_type} ) {
        $where .= " AND client_insurance.carrier_type = '$r_info->{carrier_type}'";
    }
    $where .= " AND $$r_info{client_table}.active = $active"
        if defined $active and not $r_info->{ active_determined_by_date };
    if( defined $private ) {
        $where .= $private
            ? " AND rolodex.client_id = $client_id"
            : " AND( rolodex.client_id IS NULL OR rolodex.client_id = 0 )";
    }

    return unless my $hashrefs = $self->db->select_many(
        ["$r_info->{client_table}.*"],
        "$r_info->{client_table}, $r_info->{role_table}, rolodex",
        $where,
        "ORDER BY rolodex.name, $$r_info{client_table}.rec_id"
    );

    # XXX MERGE wtf?  maybe we need this?
    $where .= " AND $$r_info{client_table}.$$r_info{role_type_field} = $type"
        if defined $type && defined $r_info->{role_type_field};

    # my $class = $r_info->{ class };
    # $_ = $class->new( $_ ) for @$hashrefs;

    return $where;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_emergency_contact {
    my $self = shift;

    # get associated contact of contact_type_id 3
    return $self->relationship_primary( 'contacts', 3 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_emergency_contacts {
    my $self = shift;

    return $self->relationship_byrole('contacts', undef, undef, 3);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_emergency_contacts {
    my $self = shift;
    my ($contacts) = @_;

    return unless $contacts;

    my $rolodex_objects = [];

    foreach my $rolodex_entry (@{$contacts}) {
        push @$rolodex_objects, $self->save_an_emergency_contact($rolodex_entry);
    }

    return $rolodex_objects;
}

# FIXME - Chad 4-30-08
# This functionality should really be inside the rolodex object. However
# at the time I am writing this there are no tests or example usage that
# I could find regarding how the changes would effect other parts of the
# app. I specifically wrote this here to solve the problems with emergency
# contacts, and it is better than what was here.
# Currently this only allows for a single phone number for emergency contacts
# at least using this interface. There is nothing that prevents additional
# numbers being created through some other means - This is BAD.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_emergency_contact_phone {
    my $self = shift;
    my ( $rolodex, $phone_number ) = @_;

    my $phones = $rolodex->phones;
    my $phone = ($phones and $phones->[0]) ? $phones->[0]
                                           : undef;

    if ( $phone ) {
        $phone->phone_number( $phone_number );
    }
    else {
        $phone = eleMentalClinic::Contact::Phone->new(
            {
                phone_number => $phone_number,
                rolodex_id   => $rolodex->id,
                primary_entry => 1,
            }
        );
    }

    return $phone->save;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 save_an_emergency_contact()

Object method.

Save an emergency contact. This function specifically adds a new emergency contact unless
an ID was provided in whcih case it updates the contact information.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_an_emergency_contact {
    my $self = shift;
    my ( $vars ) = @_;
    return unless $vars;

    my $rolodex;
    if ($vars->{rolodex_id}) {
        # just apply the settings to an existing rolodex entry.
        $rolodex = eleMentalClinic::Rolodex->retrieve($vars->{rolodex_id});
        $rolodex->update( $vars );
        $self->save_emergency_contact_phone( $rolodex, $vars->{phone_number} );
        return $rolodex
    }

    # initialize a new contact and rolodex entry for
    # emergency contact.
    $rolodex = eleMentalClinic::Rolodex->new({
        dept_id => 1001,
        %$vars
    });
    $rolodex->save;
    $self->save_emergency_contact_phone( $rolodex, $vars->{phone_number} );

    # creates rolodex_contacts record if needed
    $rolodex->add_role( 'contacts' );

    $rolodex->make_private( $self->client_id );

    my $rel_id = $self->rolodex_associate(
        'contacts',
        $rolodex->id,
    );

    my $relationship = $self->relationship_getone(
        {
            role            => 'contacts',
            relationship_id => $rel_id,
        }
    );

    # updates client_contacts record,
    # makes it an Emergency Contact
    $relationship->update({
         contact_type_id => 3,
    });

    return $rolodex;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 save_emergency_contact()

Object method (Depricated)

Update the emergency contact if it exists, otherwise create it.
If there are multiple emergency contacts this will update the
primary contact as returned by get_emergency_contact. This behavior
is preserved for legacy reasons. save_an_emergency_contact() should be
used instead.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_emergency_contact {
    my $self = shift;
    my( $vars ) = @_;
    return unless $vars;

    my $relationship = $self->get_emergency_contact;

    if (!$vars->{rolodex_id} && defined $relationship) {
        $relationship->rolodex->update($vars);
        $self->save_emergency_contact_phone( $relationship->rolodex, $vars->{phone_number} );
        return $relationship->rolodex;
    }

    return $self->save_an_emergency_contact( $vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub name {
    my $self = shift;
    return unless $self->fname or $self->lname;
    my $name;
    $name = $self->fname if $self->fname;
    $name .= ' '. $self->lname if $self->lname;
    $name =~ s/^ //;
    return $name;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns "Last, First MI"
sub eman {
    my $self = shift;
    $self->SUPER::eman( $self->fname, $self->lname, $self->mname, $self->name_suffix );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 name_clause()

Class method.

Returns a SQL part which returns a correctly-formatted client name.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub name_clause {
    my $class = shift;
    return q/
        client.lname
        || ( CASE WHEN client.name_suffix IS NOT NULL THEN ' ' || client.name_suffix ELSE '' END )
        || ', ' || client.fname
        || ( CASE WHEN client.mname IS NOT NULL THEN ' ' || client.mname ELSE '' END )
    /;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub mental_health_provider {
    my $self = shift;
    my( $date ) = @_;
    $date ||= join( '-', Today );
    eleMentalClinic::Client::Insurance->mh_provider( $self->client_id, $date );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub relationship_getone {
    my $self = shift;
    my ( $args ) = @_;

    die 'Expected hash.' unless ref($args) eq 'HASH';

    my ($role, $relationship_id) = ($args->{role}, $args->{relationship_id});
    return unless $role && $relationship_id;

    return unless eleMentalClinic::Rolodex->valid_role( $role );

    my $r_class = $lookups->{ $role }->{ class };
    return $r_class->new({ rec_id => $relationship_id })->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub release_agencies {
    my $self = shift;
    my( $active ) = @_;

    return unless $self->client_id;
    my @agencies;
    my @roles = keys %$lookups;

    #TODO take out this line when release goes away as a role
    @roles = grep !/release/, @roles;

    for( @roles ){
        my $rolodexes = $self->rolodex_byrole( $_, $active );
        @agencies = (@agencies, @$rolodexes) if $rolodexes;
    }

    #add relationships to release back in for backwards compatibility
    my $rolodexes = $self->db->select_many(
        ['DISTINCT rolodex_id'],
        'client_release',
        "WHERE client_id = " . $self->client_id
    );
    $_ = eleMentalClinic::Rolodex->new({ rec_id => $_->{ rolodex_id } })->retrieve for @$rolodexes;
    @agencies = ( @agencies, @$rolodexes ) if $rolodexes;

    # constructing the following:
    # $blah = {
    #   rec_id => {
    #       name_id => {
    #           object
    #       }
    #   }
    # }
    # gets rid of duplicate rec_ids.
    # sort on values of $blah sorts by name
    # return the array of objects

    my %agencies;
    for( @agencies ){
        # sometimes there is no name. TODO refactor to not use Rolodex's property. possibly use Base::unique
        my $name = $_->{ name } || '';
        my $id = $_->{ rec_id };
        $agencies{ $id } = {
            "$name\_$id" => $_,
        };
    }

    my @no_dups = values %agencies;
    my %no_dups;
    for( @no_dups ){
        my( $key, $value ) = each %$_;
        $no_dups{ $key } = $value;
    }

    my @results;
    for( sort keys %no_dups ){
        push @results, eleMentalClinic::Rolodex->new( $no_dups{ $_ });
    }
    return \@results if @results;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# if we get show_inactive passed, it means we care about the results
# show_inactive == 1 : show all
# show_inactive == 0 : show only active
# show_inactive == undef : die loudly
sub filter_by_show_inactive {
    my $self = shift;
    my( $method, $show_inactive, @params ) = @_;

    die "You must pass the method name as the first parameter and the user's 'rolodex_show_inactive' preference as the second parameter"
        unless $method and defined $show_inactive;

    my $active = 1 unless $show_inactive;
    $self->$method( @params, $active );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_groups {
    my $self = shift;
    return unless $self->id;
    eleMentalClinic::Group->get_byclient( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_history {
    my $self = shift;
    return unless $self->id;
    my( $group_id ) = @_;
    return unless $group_id;
    eleMentalClinic::Group::Attendee->get_byclient_group( $self->id, $group_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub uncommitted_attendees {
    my $self = shift;
    return unless my $client_id = $self->id;
    # return value should contain attendee objs for client
    # whose group_notes are uncommitted
    # whose group_prognotes are uncommitted

    my $attendees = $self->db->do_sql(qq/
        SELECT  group_attendance.*
        FROM    group_attendance, group_notes
        WHERE   group_attendance.rec_id IN (
            SELECT  a.rec_id
            FROM    group_attendance a, group_notes n
            WHERE   a.group_note_id = n.rec_id
            AND   (
                n.note_committed != 1
                OR n.note_committed IS NULL
            )
            AND   a.client_id = $client_id
            UNION ALL
            SELECT  a.rec_id
            FROM    group_attendance a, prognote p
            WHERE   a.prognote_id = p.rec_id
            AND   (
                p.note_committed != 1
                OR p.note_committed IS NULL
            )
            AND   p.group_id IS NOT NULL
            AND   p.client_id = $client_id
        )
        AND   group_notes.rec_id = group_attendance.group_note_id
        ORDER BY group_notes.start_date DESC
    /);

    my @attendees;
    push @attendees, eleMentalClinic::Group::Attendee->new( $_ )
        for( @$attendees );
    return unless $attendees[0];
    return \@attendees;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns personnel objects for people who have written
# progress notes for this client
sub previous_note_writers {
    my $self = shift;

    my $id = $self->id;
    my $writers = $self->db->do_sql( qq/
        SELECT DISTINCT p.staff_id, l.lname
        FROM prognote AS p, personnel AS l
        WHERE p.staff_id = l.staff_id AND p.client_id = $id
        ORDER BY l.lname ASC
    /);
    return unless $writers;
    my @writers;
    push @writers => eleMentalClinic::Personnel->new({ staff_id => $_->{ staff_id }})->retrieve
        for @$writers;
    \@writers;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 get_primary_treater()

Accessor to the primary physician associated with this patient.
Returns a Client::Treater object or undef if no association.

=cut

sub get_primary_treater {
    my $self = shift;

    # get associated treater of treater_type_id 2
    return $self->relationship_primary('treaters', 2);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 save_primary_treater()

Handles initialization and updates to a primary treater associated
with this client record.  (As returned by get_primary_treater() )

=cut

sub save_primary_treater {
    my $self = shift;
    my( $vars ) = @_;
    return unless $vars;

    my $relationship = $self->get_primary_treater;
    my $primary_treater_rolodex_id = $vars->{primary_treater_rolodex_id};
    my $rolodex = new eleMentalClinic::Rolodex( { rec_id => $primary_treater_rolodex_id });
    my $new_rolodex_treaters_id = $rolodex->in_treaters;
    return unless $new_rolodex_treaters_id;

    if (defined $relationship) {
        # we just need to adjust the rolodex_treaters_id arg
        if ($new_rolodex_treaters_id > 0) {
            $relationship->update({ rolodex_treaters_id => $new_rolodex_treaters_id });
        } else {
            # TODO this would be rolodex_disassociate, but it doesn't exist yet.
        }
    } else {
        # initialize a new client_treater relationship

        my $rel_id = $self->rolodex_associate(
                'treaters',
                $rolodex->id,
        );
        $relationship = $self->relationship_getone({
            role    => 'treaters',
            relationship_id => $rel_id,
        });

        # updates client_treaters record,
        # makes it a Primary Physician treater contact
        $relationship->update({
             treater_type_id => 2,
        });
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get the set of verification letter data associated with a client
#  inputs - client_id
#  returns - verification letter(s) associated with client
sub verification_letters {
    my $self = shift;

    my $client_id = $self->id;

    return eleMentalClinic::Client::Verification->get_all_by_client( $client_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 insurance_authorization_requests()

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub insurance_authorization_requests {
    my $self = shift;
    eleMentalClinic::Client::Insurance::Authorization::Request->get_by_( 'client_id', $self->id, 'date_requested', 'DESC' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 prognotes_billed([ $from, $to ])

Object method.

Returns a list of progress notes, associated with the current object, that have
been billed.  Wrapper for ProgressNote method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub prognotes_billed {
    my $self = shift;
    my( $from, $to ) = @_;

    die 'Must be called on stored object'
        unless $self->id;
    return eleMentalClinic::ProgressNote->get_billed_by_client( $self->id, $from, $to );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 last_called()

Simply prints the date of this patient's most recent ProgressNote where
the note_header field is 'CALLED'.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub last_called {
    my $self = shift;

    my $prognote_rows = eleMentalClinic::ProgressNote->new->list_recent_byheader(
        $self->client_id,
        1,
        'CALLED'
    );
    my $prognote_row_hash = @$prognote_rows[0];
    my ($last_called) = split qr/ /, $prognote_row_hash->{start_date}
        if $prognote_row_hash->{start_date};

    return $last_called;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub access {
    my $self = shift;
    my $data = eleMentalClinic::Role::Access->get_by_( client_id => $self->client_id );

    my $order = {
        direct => -15,
        membership => -10,
        coordinator => -5,
        #Limited goes here.
        group => 5,
    };

    for my $role ( @{ eleMentalClinic::Role->limited_all_access_roles }) {
        my $members = $role->all_members;
        next unless $members;
        for my $member ( @$members ) {
            push @$data => eleMentalClinic::Role::Access->new({
                staff_id => $member->member->staff_id,
                reason => "Limited Access (" . $role->name . ")"
            });
        }
    }

    my $out = {};
    push @{ $out->{ $_->staff->lname . ', ' . $_->staff->fname }} => $_ for sort {
        ($order->{ $a->reason } || 0) <=> ($order->{ $b->reason } || 0)
    } @$data;

    return $out;
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

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
