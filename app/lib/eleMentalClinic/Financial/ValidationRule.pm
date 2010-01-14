# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Financial::ValidationRule;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::ValidationRule

=head1 SYNOPSIS

Single validation rule for a group of progress notes.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::ProgressNote;
use eleMentalClinic::Util;
use eleMentalClinic::Financial::Validator;
use Data::Dumper;
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
our $SELECT = q/SELECT prognote.rec_id/;
our $FROM   = q/FROM prognote/;
our $WHERE  = q/WHERE DATE( prognote.start_date ) BETWEEN DATE( $from ) AND DATE( $to )/;
our $ORDER  = q/ORDER BY prognote.rec_id/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'validation_rule' }
    sub fields { [ qw/
        rec_id name rule_select rule_from rule_where rule_order
        selects_pass error_message scope
    /]}
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub sanitize {
    my $class = shift;
    my( $type, $query ) = @_;

    return unless $type;
    return unless $class->new->can( "rule_$type" );
    return 0
        unless $query;

    return if $query =~ /;/;
    return if $query =~ /--/;
    return if $query =~ /select/i and $type !~ /where/i;
    return if $query =~ /delete/i;
    return if $query =~ /drop/i;
    return if $query =~ /update/i;
    return if $query =~ /into/i;

    return $query;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns system rules
# adds "last_used" column for rules last used by the system
sub system_rules {
    my $class = shift;
    my( $set_id ) = @_;

    # prepend table name to avoid ambiguity
    my $class_fields = join ',' => map{ $class->table .'.'. $_ } @{ $class->fields };

    my $query = qq/
        SELECT $class_fields,
            CASE WHEN validation_rule_id IS NOT NULL THEN TRUE ELSE NULL END AS last_used
        FROM validation_rule
            LEFT OUTER JOIN validation_rule_last_used
            ON validation_rule.rec_id = validation_rule_last_used.validation_rule_id
        WHERE scope = 'system'
        ORDER BY validation_rule.rec_id
    /;
    my $sth = $class->new->db->dbh->prepare( $query );
    $sth->execute;

    my( $row, @results );
    push @results => $row while( $row = $sth->fetchrow_hashref );
    return @results ? \@results : undef;
}

# returns system rules used when no system rules were chosen
sub system_default_rules {
    my $class = shift;
    return $class->get_many_where(
        q/ scope = 'system:default' /
    );
}

# likewise, for payer
sub payer_default_rules {
    my $class = shift;
    return $class->get_many_where(
        q/ scope = 'payer:default' /
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns all payer rules
# adds "last_used" column for rules last used by $payer_id
sub payer_rules {
    my $class = shift;
    my( $payer_id, $set_id ) = @_;

    unless( $payer_id ) {
        return $class->new->db->select_many(
            $class->fields,
            $class->table,
            q/ WHERE scope = 'payer' /,
            'ORDER BY validation_rule.rec_id',
        );
    }

    # prepend table name to avoid ambiguity
    my $class_fields = join ',' => map{ $class->table .'.'. $_ } @{ $class->fields };
    my $query = qq/
        SELECT DISTINCT ON ( validation_rule.rec_id ) $class_fields,
            CASE WHEN validation_rule_last_used.rolodex_id = $payer_id THEN TRUE ELSE NULL END AS last_used
        FROM validation_rule
            LEFT OUTER JOIN validation_rule_last_used
            ON validation_rule.rec_id = validation_rule_last_used.validation_rule_id
        WHERE scope = 'payer'
        ORDER BY validation_rule.rec_id, last_used
    /;
#     print STDERR Dumper $query;
    my $sth = $class->new->db->dbh->prepare( $query );
    $sth->execute;

    my( $row, @results );
    push @results => $row while( $row = $sth->fetchrow_hashref );
    return @results ? \@results : undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 save_rules( \@rule_ids, [ $rolodex_id ])

Class method.

Associates a list of rules with the system validation process (or with payer
validation for C<$rolodex_id>, if supplied).  Uses the
C<validation_rule_last_used> table.

C<\@rule_ids> may be empty arrayref.  In this case, all rule records associated
system validation (or with payer validation for C<$rolodex_id>) are removed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub save_rules {
    my $class = shift;
    my( $rule_ids, $rolodex_id ) = @_;

    die 'At least one rule id, or a payer id, is required'
        unless $rule_ids or $rolodex_id;
    die qq/Payer id '$rolodex_id' does not exist./
        if $rolodex_id and not eleMentalClinic::Rolodex->new->get_one( $rolodex_id );

    my $one = $class->new;
    $one->db->transaction_begin;

    # first, clean previous rules
    my $query = $rolodex_id
        ? qq/ DELETE FROM validation_rule_last_used WHERE rolodex_id = $rolodex_id /
        : q/ DELETE FROM validation_rule_last_used WHERE rolodex_id IS NULL /;
    my $results = $one->db->do_sql( $query, 'return' );
    return $one->db->transaction_rollback
        unless $results;

    # return here if we got an empty arrayref for rule_ids
    # that means: "don't use any rules this time"
    return $one->db->transaction_commit
        unless @$rule_ids;

    # next, insert new rules
    $rule_ids = join ',' => @$rule_ids;
    $query = $rolodex_id
        ? qq/ INSERT INTO validation_rule_last_used( validation_rule_id, rolodex_id )
                SELECT rec_id, $rolodex_id FROM validation_rule WHERE rec_id IN ( $rule_ids ) /
        : qq/ INSERT INTO validation_rule_last_used( validation_rule_id )
                SELECT rec_id FROM validation_rule WHERE rec_id IN ( $rule_ids ) /;
    $results = $one->db->do_sql( $query, 'return' );
    return $one->db->transaction_rollback
        unless $results;

    $one->db->transaction_commit;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 validation_query( $from_date, $to_date [, $payer_id ])

Object method.

Returns the query used to calculate results.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub validation_query {
    my $self = shift;
    my( $from, $to, $payer_id ) = @_;

    croak 'Start date and end date are required.'
        unless $from and $to;

    my $query =
          $SELECT . ( $self->rule_select || '' ) ."\n"
        . $FROM   . ( $self->rule_from   || '' ) ."\n"
        . $WHERE  . ( $self->rule_where  || '' ) ."\n"
        . $ORDER  . ( $self->rule_order  || '' ) ."\n"
    ;

    dbquoteme( \$to, \$from );
    $query =~ s/\$from/$from/;
    $query =~ s/\$to/$to/;
    $query =~ s/\?/$payer_id/g
        if $payer_id;
    return $query;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 results( $from_date, $to_date [, $payer_id ])

Object method.

Returns a list hashes, each of which represents one L<eleMentalClinic::ProgressNote> (B<but> is in fact B<not> a progress note object).  
Each hash will have one additional key: C<rule_666>, where "666" is the rule id.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# FIXME - This function POD says it returns hashes, not objects, however
# it does return objects, but hash values have been added. This causes 
# problems when the objects are used in template toolkit. I would
# imagine that this can lead to other bad things as well.
sub results {
    my $self = shift;
    my( $from, $to, $payer_id ) = @_;

    die 'Must be called on a ValidationRule object.'
        unless $self->id;
    die 'Start date and end date are required.'
        unless $from and $to;
    die 'Payer id is required for payer rules.'
        if $self->scope eq 'payer' and not $payer_id;

    my $payer;
    if( $payer_id ) {
        $payer = eleMentalClinic::Rolodex->retrieve( $payer_id );
        die 'Nonexistent payer id.'
            if $payer_id and not $payer->id;
    }

    my $notes = eleMentalClinic::ProgressNote->new->get_all( undef, $from, $to );
    return unless $notes;
    my $results = $self->db->dbh->selectcol_arrayref( $self->validation_query( $from, $to, $payer_id ));

    for my $note( @$notes ) {
        my $note_id = $note->id;
        my $key = 'rule_'. $self->id;
        $note->{ $key } = ( grep /^$note_id$/ => @$results )
            ? 1
            : 0;
        $note->{ $key } = ( $note->{ $key } * -1 + 1 ) # bit-flip
            unless $self->selects_pass;
        $note->{ pass } = $note->{ $key };
    }

    return [ reverse @$notes ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 results_preview( $from_date, $to_date [, $payer_id ])

Object method.

Wrapper for results(), returns a similar data structure with the necessary fields for
the rule preview tool. This is necessary because of the way Template Toolkit handles
variables that have both an object data structure and hash fields that are accessed
eithout an accessor function. The new data structure is an array of pure hashes.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub results_preview {
    my $self = shift;
    my $results = $self->results( @_ );
    return unless $results;

    my $out = [];

    foreach my $note ( @$results ) {
        my $newnote = {};
        $newnote->{ id } = $note->{ rec_id };
        $newnote->{ pass } = $note->{ pass };
        $newnote->{ client_name } = $note->client->eman;
        $newnote->{ charge_code_name } = $note->charge_code->{ name };
        $newnote->{ location_name } = $note->location->{ name };
        $newnote->{ note_units } = $note->units;
        $newnote->{ note_duration } = $note->note_duration_minutes;
        $newnote->{ billing_status } = $note->billing_status;
        $newnote->{ client_id } = $note->client_id;
        $newnote->{ start_date } = $note->start_date;
        $newnote->{ bill_manually } = $note->bill_manually;
        $newnote->{ writer } = $note->writer;
        $newnote->{ note_body } = $note->note_body || '';
        push( @$out, $newnote );
    }

    return $out;
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
