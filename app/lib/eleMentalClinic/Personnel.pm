# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Personnel;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Personnel

=head1 SYNOPSIS

Personnel object; clinic staff.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Util;
use eleMentalClinic::Personnel::Prefs;
use eleMentalClinic::Client;
use eleMentalClinic::Rolodex;
use eleMentalClinic::ValidData;
use eleMentalClinic::Lookup::Group;
use eleMentalClinic::ProgressNote::Bounced;
use eleMentalClinic::Group::Note;
use eleMentalClinic::Role;
use Date::Calc qw/ Today /;
use Digest::SHA qw/ sha512_hex /;
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'personnel' }
    sub fields { [ qw/
        staff_id unit_id dept_id
        login password prefs home_page_type
        fname mname lname name_suffix ssn dob
        addr city state zip_code home_phone work_phone work_phone_ext work_fax
        job_title date_employ super_visor super_visor_2 over_time with_hold
        work_hours rolodex_treaters_id hours_week
        marital_status race sex next_kin
        us_citizen cdl credentials
        admin_id
        supervisor_id
        productivity_week productivity_month productivity_year productivity_last_update
        taxonomy_code medicaid_provider_number medicare_provider_number national_provider_id
        password_set password_expired
    /] }
    sub primary_key { 'staff_id' }

    # One per system role.
    sub security_fields {[ map { role_security_field( $_ ) }
        @{ shift(@_)->security_roles }]}

    sub role_security_field {
        my $role = shift;
        my $name = $role->name;
        $name =~ s/[^a-z0-9]/_/ig;
        return $name;
    }

    sub security_roles {
        return eleMentalClinic::Role->get_by_( 'system_role', 1 );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->set_prefs( $self->prefs );
    refresh_security_fields();

    return $self;
}

sub retrieve {
    my $proto = shift;
    my $self = $proto->SUPER::retrieve( @_ );
    return $self;
}

# XXX FIXME: This is here for legacy support, this should be removed, anything
# that breaks should be fixed to use roles, not this garbage.
sub refresh_security_fields {
    for my $role (@{ __PACKAGE__->security_roles }) {
        no strict 'refs';

        my $f = role_security_field( $role );

        next if defined( &{$f} );

        die( "Unable to find role: $f" ) unless $role and $role->id;
        *$f = sub {
            my $self = shift;
            if ( @_ ) {
                my ($add) = @_;
                $add ? $role->add_personnel( $self )
                     : $role->del_personnel( $self );
            }
            return $role->has_member( $self->primary_role );
        };
    }
}
eleMentalClinic::Config::add_callback( \&refresh_security_fields );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub name {
    my $self = shift;
    #TODO accept an arg here that is
    # fl, lf
    return $self->fname .' '. $self->lname;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns "Last, First (Credentials)"
sub eman {
    my $self = shift;

    my $creds = '('. $self->credentials .')'
        if $self->credentials;
    $self->SUPER::eman( $self->fname, $self->lname, $creds, $self->name_suffix );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my $self = shift;
    my $class = ref $self || $self;

    my $order_by = "ORDER BY lname, fname, staff_id";
    my $personnel = $class->db->select_many(
        $class->fields,
        $class->table,
        '',
        $order_by,
    );
    return unless $personnel;
    return[ map { $class->new( $_ )} @$personnel ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_byrole()

Class method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_byrole {
    my $class = shift;
    my ( $role ) = @_;

    return unless $role;

    unless ( ref $role ) {
        $role = $role =~ m/^\d+$/ ? eleMentalClinic::Role->retrieve( $role )
                                  : eleMentalClinic::Role->get_one_by_( 'name', $role );
    }

    return unless $role and $role->id;

    my $personnel = $role->all_personnel;
    return unless $personnel and @$personnel;

    #Order in old system was apparently important, here we preserve it :-(
    return [
        sort {
            ($a->lname || '') cmp ($b->lname || '') ||
            ($a->fname || '') cmp ($b->fname || '') ||
            ($a->id <=> $b->id)
        } @$personnel
    ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# used in global/client_head.html: current_user.valid_data
sub valid_data {
    my $self = shift;
    $self->{ valid_data } and return $self->{ valid_data };

    $self->{ valid_data } = eleMentalClinic::ValidData->new({
        dept_id => $self->dept_id,
    });
    return $self->{ valid_data };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub filter_clients {
    my $self = shift;

    my $filter = $self->pref->client_list_filter;
    my $program = $self->pref->client_program_list_filter;

    my %args;
    $args{ active } = 1 if $filter eq 'active';
    $args{ active } = 0 if $filter eq 'inactive';
    $args{ program_id } = $program if $program;
    if( $filter eq 'caseload' ) {
        $args{ staff_id } = $self->staff_id;
        $args{ active } = 1;
    }

    my $clients = [ grep { $self->primary_role->has_client_permissions( $_->{ client_id })}
        @{ eleMentalClinic::Client->new->list_all( \%args ) || [] }];
    return unless $clients and @$clients;
    return $clients;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_clients {
    my $self = shift;
    my( $args ) = @_ || {};

    return unless $self->id;

    return eleMentalClinic::Client->new->get_all({
        staff_id => $self->id,
        active   => 1,
        %$args,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_overdue_clients {
    my $self = shift;
    my( $date ) = @_;
    return unless $self->id;

    my $id = $self->id;
    $date ||= join '-' => Today;
    $date = $self->db->dbh->quote( $date );

    my( %clients, @overdue, %numbers );

    my $results = $self->db->do_sql( qq/
        SELECT cpe.client_id, valid_data_level_of_care.visit_frequency, valid_data_level_of_care.visit_interval
          FROM client_placement_event cpe, valid_data_level_of_care
         WHERE cpe.rec_id IN (
               SELECT DISTINCT ON ( client_id )
                   rec_id
                   FROM client_placement_event
                   ORDER BY client_id ASC, event_date DESC, rec_id DESC
               )
           AND cpe.staff_id = $id
           AND cpe.level_of_care_id = valid_data_level_of_care.rec_id
    /);

    for( @$results ){
        if( $_->{ visit_frequency } and $_->{ visit_interval } ){
            $clients{ $_->{ client_id } }{ frequency } = $_->{ visit_frequency };
            $clients{ $_->{ client_id } }{ interval } = $_->{ visit_interval };
        }
    }

    if( keys %clients <= 0 ){
        return \@overdue;
    }

    my $client_list = join ', ' => keys %clients;

    my $daycount = $self->db->do_sql( qq/
        SELECT client_id, COUNT(*) FROM prognote
         WHERE prognote.end_date = $date
           AND client_id IN ( $client_list )
      GROUP BY client_id
    / );
    my $weekcount = $self->db->do_sql( qq/
        SELECT client_id, COUNT(*) FROM prognote
         WHERE EXTRACT('WEEK' FROM prognote.end_date) = EXTRACT('WEEK' FROM DATE $date)
           AND EXTRACT('YEAR' FROM prognote.end_date) = EXTRACT('YEAR' FROM DATE $date)
           AND client_id IN ( $client_list )
      GROUP BY client_id
    /);
    my $monthcount = $self->db->do_sql( qq/
        SELECT client_id, COUNT(*) FROM prognote
         WHERE EXTRACT('MONTH' FROM prognote.end_date) = EXTRACT('MONTH' FROM DATE $date)
           AND EXTRACT('YEAR' FROM prognote.end_date) = EXTRACT('YEAR' FROM DATE $date)
           AND client_id IN ( $client_list )
      GROUP BY client_id
    / );
    my $yearcount = $self->db->do_sql( qq/
        SELECT client_id, COUNT(*) FROM prognote
         WHERE EXTRACT('YEAR' FROM prognote.end_date) = EXTRACT('YEAR' FROM DATE $date)
           AND client_id IN ( $client_list )
      GROUP BY client_id
    / );

    $numbers{ $_->{ client_id } }{ day } = $_->{ count } for @$daycount;
    $numbers{ $_->{ client_id } }{ week } = $_->{ count } for @$weekcount;
    $numbers{ $_->{ client_id } }{ month } = $_->{ count } for @$monthcount;
    $numbers{ $_->{ client_id } }{ year } = $_->{ count } for @$yearcount;

    for( sort keys %clients ){
        my $freq = $clients{ $_ }{ frequency } || 0;
        my $interval = $clients{ $_ }{ interval };

        my $overdue = { client_id => $_,
                        visit_frequency => $freq,
                        visit_interval => $interval };

        if( ! defined $numbers{ $_ }{ $interval } and $freq > 0 ){
            # they had zero progress notes in this time interval
            push @overdue => $overdue;
        }
        elsif( $numbers{ $_ }{ $interval } < $freq ){
            push @overdue => $overdue;
        }
    }

    return \@overdue;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_treatmentplans {
    my $self = shift;
    my $args = shift;

    my $id = $self->id;

    if( $id ) {
       return eleMentalClinic::TreatmentPlan->new->get_staff_all({
            staff_id => $id,
            year_old => $args->{ year_old } || '',
        });
    }

    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_assessments {
    my $self = shift;
    my $args = shift;

    my $id = $self->id;

    if( $id ) {
       return eleMentalClinic::Client::Assessment->new->get_staff_all({
            staff_id => $id,
            year_old => $args->{ year_old } || '',
        });
    }

    return;
}

sub save {
    my $self = shift;
    $self->db->transaction_do(sub {
        $self->SUPER::save;
        $self->primary_role;
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub lookup_associations {
    my $self = shift;
    my( $table_id ) = @_;

    return unless $self->staff_id;
    die 'Lookup table id is required by Personnel::lookup_associations.'
        unless $table_id;

    eleMentalClinic::Lookup::Group->new->get_by_personnel_association( $table_id, $self->staff_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns a hashref of group objects with which this person is associated,
# for $table_id.  the key is the group id, the value is:
# - 1 for a simple association,
# - 'sticky' for a sticky one
sub lookup_associations_hash {
    my $self = shift;
    my( $table_id ) = @_;

    my %hash = ();
    return unless
        my $associations = $self->lookup_associations( $table_id );
    $hash{ $_->{ rec_id }} = $_->{ sticky } ? 'sticky' : 1
        for @$associations;
    \%hash;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set_lookup_associations {
    my $self = shift;
    my( $table_id, $items, $sticky ) = @_;

    die 'Lookup table id is required by Personnel::set_lookup_associations.'
        unless $table_id;
    return unless $items or $sticky;
    die 'Items and sticky items must be arrayrefs.'
        if( defined $items and ref $items ne 'ARRAY' )
        or( defined $sticky and ref $sticky ne 'ARRAY' );

    my $staff_id = $self->id;
    # 1. delete all groups for this table
    $self->db->do_sql( qq/
        DELETE FROM personnel_lookup_associations
        WHERE personnel_lookup_associations.lookup_group_id IN (
            SELECT rec_id FROM lookup_groups
            WHERE lookup_groups.parent_id = $table_id
        )
        AND personnel_lookup_associations.staff_id = $staff_id
        /, 'return' # avoid extra work
    );

    # 2. set all incoming groups, accounting for sticky
    for( $self->unique( $items, $sticky )) {
        my $group_id = $_;
        my $sticky = ( grep /^$group_id$/ => @$sticky )
            ? 1
            : 0;
        $self->db->insert_one(
            'personnel_lookup_associations',
            [ qw/ staff_id lookup_group_id sticky /],
            [ $staff_id, $group_id, $sticky ],
        );
    }
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_relationships_by_pref {
    my $self = shift;
    my( $client_id, $role_name ) = @_;

    return unless $role_name;
    my $client = eleMentalClinic::Client->new({ client_id => $client_id })->retrieve;

    my $active = 1 unless $self->pref->rolodex_show_inactive;
    my $private = 0 unless $self->pref->rolodex_show_private;

    $client->relationship_byrole( $role_name, $private, $active );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_all_relationships_by_pref {
    my $self = shift;
    my( $client_id ) = @_;

    my $client = eleMentalClinic::Client->new({ client_id => $client_id })->retrieve;

    my $active = 1 unless $self->pref->rolodex_show_inactive;
    my $private = 0 unless $self->pref->rolodex_show_private;

    my %relationships;
    my %lookups = %$eleMentalClinic::Client::lookups;
#     for( @{ eleMentalClinic::Rolodex->role_names }) {
    for( sort keys %lookups ) {
        next if $_ eq 'prescribers';
        next if $_ eq 'release';
        my $rels = $client->relationship_byrole( $_, $private, $active );

        if( $rels ) {
            $relationships{ $_ }->{ relationships } = $rels;
            $relationships{ $_ }->{ description } = $lookups{ $_ }->{ description };
        }
    }
    return unless %relationships;
    \%relationships;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get total number of hours in prognotes,
# as a hash of hours per current week, month, year
sub productivity_update {
    my $self = shift;
    my( $date ) = @_;

    return unless $self->hours_week;
    my $time = eleMentalClinic::ProgressNote->total_duration({
        staff_id        => $self->id,
        current_date    => $date,
    });
    my %units = (
        week    => 1,
        month   => 4.38,
        year    => 52.17,
    );
    while( my( $unit, $multiple ) = each %units ) {
        my $result = sprintf( "%.2f" =>
            ( 100 * $time->{ $unit })
          / ( $self->hours_week * $multiple )
        );
        my $method = "productivity_$unit";
        $self->$method( $result );
    }
    $self->save;

    $date = $date
        ? "'$date'"
        : 'now()';
    my $staff_id = $self->staff_id;
    my $query = qq/
        UPDATE personnel
        SET productivity_last_update = date( $date )
        WHERE staff_id = $staff_id
    /;

    my $return = $self->db->do_sql( $query, 'return' );
    $self = $self->retrieve;
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Supervisor
# XXX this is a bit of a hack, the right solution is to use 'supervisor'
# and then rename the current supervisor role method to 'is_supervisor'
# this will wreak havok with the upcoming merge, though, so for now ...
sub Supervisor {
    my $self = shift;
    return unless $self->supervisor_id;

    return eleMentalClinic::Personnel->new({ staff_id => $self->supervisor_id })->retrieve;
}

# authentication {{{
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 crypt_password( $login, $password )

Class method.

Creates a hash from C<$login> and C<$password>.  This hash is either stored in
the database, or compared against the value that is stored in the database.

Uses this algorithm:

    $system_salt = ...
    $user_salt = SHA512( $login, $system_salt )
    $hash = SHA512( $password, $user_salt )
    for( 1..999 ) {
        $hash = SHA512( $hash )
    }

This makes for very expensive attacks on the resulting hash values.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub crypt_password {
    my $class = shift;
    my( $login, $password ) = @_;

    croak 'Login and password are required.'
        unless $login and $password;

    # XXX this would be better stored in a config file, but
    # one goal of this refactor is to change only this method.
    # Later, we should make this a config option.
    my $system_salt = '6aaa7f562e401a7221965873be493351e5483d7f846741467208a39e584a9dbc9d1a0020665e801e110a83f3e5b50f0c53f3c131b9188ff6ee140ce8dc42e6b5';
    my $user_salt = sha512_hex( $login, $system_salt );
    my $encrypted = sha512_hex( $password, $user_salt );
    $encrypted = sha512_hex( $encrypted )
        for 1..999;
    return $encrypted;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests object's login and password; returns undef or the staff_id
sub authenticate {
    my $class = shift;
    my( $login, $password ) = @_;
    return unless $login and $password;

    my $crypted = $class->crypt_password( $login, $password );

    my $self = $class->get_one_where(
        [
            q(login = ? AND password = ?),
            $login, $crypted
        ],
    );

    return unless $self and $self->active;
    return $self;
}
#}}}
# preferences {{{
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# this takes the { prefs } key and turns it into a Prefs object
sub set_prefs {
    my $self = shift;
    my( $prefs ) = @_;

    return unless $prefs;

    $self->{ Prefs } = eleMentalClinic::Personnel::Prefs->new({
        staff_id => $self->id,
        prefs   => $prefs,
    });
    return $self->{ Prefs };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub pref {
    my $self = shift;
    my( $prefs ) = @_;

    if( $prefs ) {
        $self->{ Prefs } = eleMentalClinic::Personnel::Prefs->new({
            staff_id => $self->id,
            prefs   => $prefs,
        });
    }
    unless( $self->{ Prefs }) {
        $self->{ Prefs } = eleMentalClinic::Personnel::Prefs->new({
            staff_id => $self->id,
        });
    }
    return $self->{ Prefs };
}
# }}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 bounced_prognotes()

Object method.

Returns all L<eleMentalClinic::ProgressNote::Bounced> objects associated with
L<eleMentalClinic::ProgressNote> records written by this person.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub bounced_prognotes {
    my $self = shift;
    return eleMentalClinic::ProgressNote::Bounced->get_by_data_entry_id( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 uncommitted_prognotes()

Object method.

Returns all L<eleMentalClinic::ProgressNote> objects associated with
this personnel object which are not committed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub uncommitted_prognotes {
    my $self = shift;
    my $pnotes = eleMentalClinic::ProgressNote->get_uncommitted_by_writer( $self->id );
    my $gnotes = eleMentalClinic::Group::Note->get_uncommitted_by_writer( $self->id );

    # Return if no data
    return unless ($pnotes && @$pnotes) || ($gnotes && @$gnotes);

    # Return one or the other if only one (faster, no need to sort)
    return $pnotes unless $gnotes and @$gnotes;
    return $gnotes unless $pnotes and @$pnotes;

    return [ sort { $a->start_date cmp $b->start_date } @$gnotes, @$pnotes ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 reporters()

Object method.

Returns list of L<eleMentalClinic::Personnel> objects who have this object
listed as supervisor.

Returns C<undef> if the calling object is not a supervisor, or if no reporters.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub reporters {
    my $self = shift;

    my $id = dbquote( $self->id );
    my $results = $self->db->select_many(
        $self->fields,
        $self->table,
        "WHERE supervisor_id = $id",
        'ORDER BY personnel.lname, personnel.fname, personnel.staff_id',
    );
    return unless $results;
    return[ map { $self->new( $_ )} @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 reporters_with_bounced_prognotes()

Object method.

Returns list of L<eleMentalClinic::Personnel> objects who have this object
listed as supervisor, and who have outstanding bounced progress notes.

Returns C<undef> if the calling object is not a supervisor, or if no reporters
have outstanding bounced notes.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub reporters_with_bounced_prognotes {
    my $self = shift;

    my $id = dbquote( $self->id );
    my $fields_qualified = $self->fields_qualified;
    my $query = qq/
        SELECT DISTINCT $fields_qualified
        FROM personnel, prognote, prognote_bounced
        WHERE personnel.staff_id = prognote.staff_id
            AND prognote.rec_id = prognote_bounced.prognote_id
            AND prognote_bounced.response_date IS NULL
            AND personnel.supervisor_id = $id
        ORDER BY personnel.lname, personnel.fname, personnel.staff_id
    /;
    my $results = $self->db->do_sql( $query );
    return unless $results and @$results;
    return[ map { $self->new( $_ )} @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 reporters_with_uncommitted_prognotes()

Object method.

Returns list of L<eleMentalClinic::Personnel> objects who have this object
listed as supervisor, and who have uncommitted progress notes.

Returns C<undef> if the calling object is not a supervisor, or if no reporters
have uncommitted notes.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub reporters_with_uncommitted_prognotes {
    my $self = shift;

    my $id = dbquote( $self->id );
    my $fields_qualified = $self->fields_qualified;
    my $query = qq/
        SELECT DISTINCT $fields_qualified
        FROM personnel, prognote
        WHERE personnel.staff_id = prognote.data_entry_id
            AND personnel.supervisor_id = $id
            AND(
                prognote.note_committed = 0
                OR prognote.note_committed IS NULL
            )
        ORDER BY personnel.lname, personnel.fname, personnel.staff_id
    /;
    my $results = $self->db->do_sql( $query );
    return unless $results and @$results;
    return[ map { $self->new( $_ )} @$results ];
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 clients_intake_incomplete()

Object method.  Returns all clients for whom intake is not complete.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub clients_intake_incomplete {
    my $self = shift;

    return unless my $clients = eleMentalClinic::Client->new->get_all({
        intake_incomplete => 1,
    });
    return $clients;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# legacy
sub personnel { die "redundant" }


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 update_password()

Object method.

This updates the password for this user. As well it records when the password
was set, and resets the expired flag.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub update_password {
    my $self = shift;
    my ( $password ) = @_;
    $self->password( $password );
    $self->password_expired( 0 );
    $self->password_set( 'NOW()' );
    $self->save;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 pass_has_expired()

Object method.

Returns true of the password has been expired.

Password can be expired for 2 reasons:
 * password_expired is true
 * password_set date is older than the value for password_expiration_days in
   the config.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub pass_has_expired {
    my $self = shift;
    return 1 if $self->password_expired;
    my $days = $self->config->password_expiration_days;
    return 0 unless $days;

    my $query = 'SELECT staff_id FROM personnel WHERE '
               ."password_set < (NOW() - INTERVAL '$days days')"
               .' AND staff_id = ?';

    my $results = $self->db->do_sql( $query, undef, $self->staff_id );

    return 1 if $results and $results->[0] and $results->[0]->{ staff_id } == $self->staff_id;

    return 0;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

=item primary_role()

Return the primary eleMentalClinic::Role object associated with this personnel

=cut

sub primary_role {
    my $self = shift;
    my $role = eleMentalClinic::Role->get_one_by_( 'staff_id', $self->staff_id );
    if ( !$role || !$role->id ) {
        $role = eleMentalClinic::Role->new({
            name => $self->staff_id,
            staff_id => $self->staff_id,
            system_role => 0,
        });
        $role->save;
    }
    return $role;
}

=item has_role( $role || $role_id || $role_name )

Returns true if this personnel is a direct member of the specified role.

Note: It is possible for this personnel object to only be an indirect member of
this role. In this case this method returns false.

=cut

sub has_role {
    my $self = shift;
    my ( $role ) = @_;
    unless ( eval { $role->isa( 'eleMentalClinic::Role' )}) {
        $role = ( $role =~ m/^\d+$/ ) ? eleMentalClinic::Role->retrieve( $role )
                                      : eleMentalClinic::Role->get_one_by_( name => $role );
    }
    return unless $role;
    return $role->has_direct_member( $self->primary_role );
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
