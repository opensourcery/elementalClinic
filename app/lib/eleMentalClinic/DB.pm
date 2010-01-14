# vim: ts=4 sts=4 sw=4
package eleMentalClinic::DB;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::DB

=head1 SYNOPSIS

Database object.  Abstracts as much SQL as possible; provides methods to better deal with the rest.

=head1 METHODS

=cut

use eleMentalClinic::Config;
use eleMentalClinic::Log;
use eleMentalClinic::Util;
use eleMentalClinic::Log::ExceptionReport;
use DBI;
use Data::Dumper;
use Carp;

our $one_true_DBH;
our $TRACE_TRANSACTIONS = $ENV{EMC_DB_TRACE} || 0;
our $DEBUG              = $ENV{EMC_DB_DEBUG} || 0;
our $RUN_TESTS; # set by testing code
our $ENFORCE_TRANSACTIONS;

# These functions will be torn out of the DBH, and replaced with new
# functions that essentially wrap the old ones in an eval.
# As a bonus we get a useful error report.
our $DB_OVERRIDES = {
    'DBI::db' => [ qw/ do prepare selectrow_hashref / ],
    'DBI::st' => [ qw/ execute / ],
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
    my $proto = shift;
    my( $args ) = @_;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;

    $self->init( $args );
}

=head2 connect

    my $dbh = eleMentalClinic::DB->connect;

    my $dbh = eleMentalClinic::DB->connect($handle_name);

Create a new DBI handle.  Reads the DSN from eleMentalClinic::Config.

You should not normally have to use this; call L</new> to get a new
eleMentalClinic::DB object and let it deal with DBI.

The optional C<$handle_name> parameter will cache the handle for later
retrieval, e.g.

    my $dbh = eleMentalClinic::DB->connect('cgi_session');

    # later ...
    
    # gets the same DBH back
    $dbh = eleMentalClinic::DB->connect('cgi_session');

=cut

my %DBH;
sub connect {
    my $self = shift;
    my ( $handle_name ) = @_;

    if ( $handle_name ) {
        $self->{name} = $handle_name;
        return $DBH{ $handle_name } if
            $DBH{ $handle_name } &&
            $DBH{ $handle_name }->ping;
    }
    my $config = eleMentalClinic::Config->new->stage1;
    my $dbtype = $config->dbtype;

    die 'No database'
        unless $dbtype eq 'postgres';

    my( $ds, $un, $pd );
    $ds = 'dbi:Pg:dbname='. $config->dbname .';';
    if ($config->host) { $ds .= 'host=' . $config->host . ';'; }
    if ($config->port) { $ds .= 'port=' . $config->port . ';'; }
    $un = $config->dbuser;
    $pd = $config->passwd;
    
    my $dbh = DBI->connect( $ds, $un, $pd, { 
        AutoCommit => 1,
        RaiseError => 1,
        ChopBlanks => 1,
        PrintError => 0,
        PrintWarn  => 0,
        # Using a HandleError has limitations
        # Cannot show statement on a 'do'
        #ShowErrorStatement => 0,
        #HandleError => sub {
        #    my ( $error, $dbh ) = @_;
        #    print $dbh->{ Statement } . "\n";
        #    confess( $error ); 
        #}
    }) or die 'Database error connecting: ' . DBI->errstr;

    $dbh->{pg_enable_utf8} = 1;

    $dbh->do("ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'")
        if $dbtype eq 'oracle';

    $DBH{ $handle_name } = $dbh if $handle_name;

    return $dbh;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $DONE_DB_OVERRIDES;
sub init {
    my $self = shift;
    my( $args ) = @_;

    unless ( $DONE_DB_OVERRIDES++ ) {
        # Override the DBI class functions.
        for my $class ( keys %$DB_OVERRIDES ) {
            for my $function ( @{ $DB_OVERRIDES->{ $class }}) {
                override_db_call( $class, $function );
            }
        }
    }

    # several things use the presence of $one_true_DBH to see whether or not
    # this module is initialized (ugh)
    $self->dbh( $one_true_DBH = $self->connect('main') );

    # XXX this is quite a hack; feel free to replace it with something better
    # if you can think of it.
    if ($RUN_TESTS) {
        $RUN_TESTS = 0;
        $self->transaction_begin;
        require eleMentalClinic::Test;
        eleMentalClinic::Test->new->insert_data;
    }
    return $self;
}

sub override_db_call {
    my ( $object, $function, $audit ) = @_;
    my $def = $object . '::' . $function;
    no strict 'refs';
    no warnings 'redefine';
    my $oldsub = \&{ $def };
    *{ $def } = sub {
        my $params = [ @_ ];
        my $Obj = shift( @$params );
        my ($package, $filename, $line, $subroutine, $hasargs ) = caller;

        my $out = eval { $oldsub->(@_) };
        if ( my $error = $@ ) {
            eleMentalClinic::Log::ExceptionReport->new({
                catchable => 1,
                name => 'Database Error',
                message => $error,
                params => {
                    object => 'eleMentalClinic::DB',
                    params => $params,
                    function => $def,
                    'return' => $out,
                    statement => $Obj->{ Statement },
                    'caller' => { package => $package, filename => $filename, line => $line, 'sub' => $subroutine, args => $hasargs },
                    trace => Carp::longmess(),
                },
            })->throw;
        }
        return $out;
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 debug()

Object method.

Set true to enable error log printing of (almost) all queries.  Some true
values are more significant than others:

=over 4

=item 1: Print queries as they appear in the source.

=item 2: Strip all extra whitespace, including carriage returns (sometimes handy for Apache logs)

=item 3: As (2), but with full stack trace.

=back

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set $eleMentalClinic::DB::DEBUG = 1; to debug...
sub debug {
    my( $query ) = @_;
    return unless $DEBUG;

    $query =~ s/\s+/ /g
        if $DEBUG >= 2;
    #my $message = '# '. '~'x48 ."\neleMentalClinic::DB: ". join( ' :: ' => map { defined($_) ? $_ : '' } caller ) ."\n$query\n";
    my $message = "DEBUG: $query\n";
    return Carp::cluck( $message )
        if $DEBUG >= 3;
    return print STDERR $message
        if $DEBUG >= 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbh {
    my $self = shift;
    my( $value ) = @_;
    if( defined $value ) {
        $self->{ dbh } = shift;
    }
    else {
        return unless defined $self->{ dbh };
        return if( $self->{ dbh } eq '' );
        return $self->{ dbh };
    }
}

# we index these by $self->dbh because the DB object may change, but the DBI
# dbh remains the same
my %TRANSACTION_DEPTH;
sub _inc_depth {
    my $self = shift;
    ($TRANSACTION_DEPTH{ $self->dbh } ||= 0)++;
}

sub _dec_depth {
    my $self = shift;
    Carp::confess "invalid transaction depth: $TRANSACTION_DEPTH{ $self->dbh }"
        if $self->transaction_depth < 1;
    $TRANSACTION_DEPTH{ $self->dbh}--;
}

sub _txn_trace {
    my $self = shift;
    my ( $label ) = @_;
    return unless $TRACE_TRANSACTIONS;
    local $Carp::CarpLevel = 1;
    Carp::cluck sprintf(
        "%s TRANSACTION %s %s",
        $self->dbh, $self->transaction_depth, $label,
    );
}

sub _savepoint_name {
    my $self = shift;
    return 'emc_save_' . $self->transaction_depth;
}

=head2 transaction_begin

    $db->transaction_begin;

Start a new transaction.

=cut
    
sub transaction_begin {
    my $self = shift;

    $self->_inc_depth;
    $self->_txn_trace('begin');
    Carp::confess 'DB transaction_begin error: ', $self->dbh->errstr unless (
        ($self->transaction_depth == 1)
        ? $self->dbh->begin_work
        : $self->dbh->pg_savepoint($self->_savepoint_name)
    );
    return 1;
}

=head2 transaction_rollback

    $db->transaction_rollback;

Roll back the current transaction.

See L<DBI> for C<rollback> behavior when no transaction is active.

=cut

sub transaction_rollback {
    my $self = shift;

    $self->_txn_trace('rollback');
    Carp::confess 'DB transaction_rollback error: ', $self->dbh->errstr unless (
        ($self->transaction_depth == 1)
        ? $self->dbh->rollback
        : $self->dbh->pg_rollback_to($self->_savepoint_name)
    );
    $self->_dec_depth;
    return;
}

=head2 transaction_commit

    $db->transaction_commit;

Commit the current transaction.

See L<DBI> for C<commit> behavior when no transaction is active.

=cut

sub transaction_commit {
    my $self = shift;

    $self->_txn_trace('commit');
    Carp::confess 'DB transaction_commit error: ', $self->dbh->errstr unless (
        ($self->transaction_depth == 1)
        ? $self->dbh->commit
        : $self->dbh->pg_release($self->_savepoint_name)
    );
    $self->_dec_depth;
    return 1;
}

=head2 transaction_do

    my $return_value = $db->transaction_do(sub { ... });

Automatically start a transaction and run the passed-in code inside of it.
Exceptions thrown by the coderef will cause a rollback; if no exceptions are
thrown, the transaction is committed.

Returns the return value of the coderef in scalar context.

=cut

my $ROLLBACK = "ROLLBACK\n";
sub transaction_do {
    my $self = shift;
    my ( $code ) = @_;
    $self->transaction_begin;
    my $rv = eval {
        $code->();
        $self->transaction_commit;
    };
    if (my $err = $@) {
        $self->transaction_rollback;
        return if $err eq $ROLLBACK;
        die $err;
    }
    return $rv;
}

=head2 transaction_do_eval

    my $return_value = $db->transaction_do_eval(sub { ... });

As L<transaction_do>, but wraps an extra C<eval> around the sub; instead of
dying on error, an exception will be placed in C<$@>.  In other words, it
replaces this:

    my $return_value = eval {
        $db->transaction_do(sub { ... });
    };
    if ($@) { ... }

with this:

    my $return_value = $db->transaction_do_eval(sub { ... });
    if ($@) { ... }

(saving an indent level and some punctuation)

=cut

sub transaction_do_eval {
    my $self = shift;
    return eval { $self->transaction_do(@_) };
}

=head2 transaction_do_rollback

    $db->transaction_do(sub {
        ...
        $db->transaction_do_rollback;
    });

Inside the coderef passed to L</transaction_do>, this throws an exception that
aborts the transaction but otherwise does not affect program flow.

Use this when you want to handle rollback yourself sometimes but usually want
the automatic handling done by transaction_do.

=cut

sub transaction_do_rollback {
    die $ROLLBACK;
}

=head2 transaction_depth

    my $depth = $db->transaction_depth;

Returns the number of transactions currently nested.

=cut

sub transaction_depth {
    my $self = shift;
    $TRANSACTION_DEPTH{ $self->dbh} ||= 0;
}

sub _enforce_transaction {
    my $self = shift;
    my ( $sql, $bind ) = @_;
    return unless $ENFORCE_TRANSACTIONS->{ $self->{name} };
    return if $self->transaction_depth > 0;
    local $Carp::CarpLevel = 1;
    Carp::confess
        "Query outside of a transaction on '$self->{name}': $sql (@$bind)";
}

=head2 select_one

=head2 select_many

=head2 select_many_arrayref

    my $hashref = $db->select_one(
        \@columns, $table, \@conditions, $rest
    );

    # or ...

    my $arrayref = $db->select_many(
        \@columns, $table, \@conditions, $rest
    );

    for my $hashref ( @$arrayref ) {
        # do something
    }

    # or ...

    my $arrayref = $db->select_many(
        [ $column ], $table, \@conditions, $rest
    );

    for my $value ( @$arrayref ) {
        print $value;
    }

Select some columns (C<*> is valid) from a table and return either a single
hashref, an arrayref of hashrefs, or an arrayref of single columns.

Note that C<select_many> will always return only one column, regardless of how
many you pass in.

Conditions may be specified as:

=over

=item * "some-conditions"

a single string

=item * [ "some-conditions and foo = ?", $foo ]

an arrayref, with SQL followed by any number of bind values

=back

C<$rest> is anything trailing the WHERE clause: ORDER BY, LIMIT, etc.

=cut

sub _where {
    my $self = shift;
    my ( $arg ) = @_;

    unless ( ref $arg ) {
        return ( '' ) unless defined $arg and length $arg;
        # make transition easier; in the future, this should stop
        $arg =~ s/^\s*WHERE\s+//i;
        return ( $arg );
    }

    if ( ref $arg eq 'ARRAY' ) {
        # $where, @bind
        my ( $where, @bind ) = @$arg;
        $where =~ s/^\s*WHERE\s+//i;
        return ( $where, @bind );
    }

    die "unhandled where argument: $arg";
}

sub _select {
    my $self = shift;
    my ( $what, $table, $conditions, $other ) = @_;

    # stupid special case; remove when no more code uses this 'feature'
    if ( @_ < 4 and $conditions =~ /^(order by|limit)\s/i ) {
        $other      = $conditions;
        $conditions = '';
    }

    $what = join ', ', @$what;
    my ( $where, @bind ) = $self->_where( $conditions );
    $other ||= '';

    if ( defined $where and length $where ) {
        $where = "WHERE $where";
    }

    my $query = qq/
        SELECT $what FROM $table $where $other
    /;

    debug( $query );
    my $sth = $self->dbh->prepare( $query );
    $sth->execute( @bind );
    return $sth;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub select_one {
    my $self = shift;

    my $sth = $self->_select( @_ );

    return $sth->fetchrow_hashref;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub select_many {
    my $self = shift;

    # {} = like calling fetchrow_hashref() repeatedly
    my $results = $self->_select( @_ )->fetchall_arrayref( {} );
    return @$results ? $results : undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub select_many_arrayref {
    my $self = shift;

    # [ 0 ] = first column of each row (see DBI)
    my $results = [
        map { $_->[0] } @{ $self->_select( @_ )->fetchall_arrayref( [ 0 ] ) }
    ];
    return @$results ? $results : undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub insert_one {
    my $self = shift;
    my( $table, $fields, $values, $primary_key, $no_currval, $insert_queries ) = @_;
    return unless $table and $fields and $values;
    $primary_key ||= 'rec_id';
    
    my $placeholders = join( ', ', ( '?' ) x @$fields );
    my @values = @$values;
    my $field_list = join ', ', @$fields;

    if( keys %$insert_queries ) {
        #I am doing it this way to make sure they line up.
        for my $field ( keys %$insert_queries ) {
            next unless $insert_queries->{ $field }->{ insert_query };
            # Skip if the field is already defined.
            next if grep /^$field$/ => @$fields;

            # If there are already fields in the list we need a comma when appending this field.
            $field_list .= $field_list ? ', '. $field
                                       : $field;
            
            # We need to test the query first and make sure a value is returned
            # If none is returned we will use the default on insert.
            my $query_success = 0;
            my $sth = $self->dbh->prepare( $insert_queries->{ $field }->{ insert_query });
            if ( $sth->execute( @{ $insert_queries->{ $field }->{ params } || [] })) {
                # The query is a success if we get a value back.
                $query_success = defined( $sth->fetchrow_arrayref->[0] ) ? 1 : 0; 
            }
            
            # In most cases a field is one that gets a value from a subquery
            # as such this cannot be done w/ a placeholder and value in execute.
            if( $query_success ) {
                $placeholders .= $placeholders ? ', ('. $insert_queries->{ $field }->{ insert_query } . ')'
                                               : '('. $insert_queries->{ $field }->{ insert_query } . ')';
                # The subquery may have placeholders for values.
                push( @values, @{ $insert_queries->{ $field }->{ params }})
                    if defined $insert_queries->{ $field }->{ params };
            }
            else {
                $placeholders .= $placeholders ? ', ?' : '?';
                push( @values, $insert_queries->{ $field }->{ default } );
            }
        }
    }

    my $query = qq/INSERT INTO $table ($field_list) VALUES ($placeholders)/;
    debug( $query );
    $self->_enforce_transaction( $query, \@values );
    my $sth = $self->dbh->prepare( $query );
    $sth->execute( @values );

    unless( $no_currval
        and ref $no_currval eq 'HASH'
        and $no_currval->{ no_currval } == 1
    ){
        # XXX FIXME - This makes assumptions about seq name that are not always correct!
        my $seq = $table .'_'. $primary_key .'_seq';
        $sth = $self->dbh->prepare( "SELECT currval( '$seq' )" );
        $sth->execute;
        my @row = $sth->fetchrow_array;
        return $row[ 0 ];
    }
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 update_or_insert_one()

Object method.

This will update a row if the row exists (based on condition).
If the row does not exist it will be created.

Parameters:
$self->update_or_insert_one(
    table         => TABLE,
    conditions    => qq/name = bob/,
    # Fields to be updated on the row(s) where the condition exists.
    update_fields => [ 'field_a', 'field_b', ... ],
    update_values => [ 'value_a', 'value_b', ... ],
    # If the condition is not true for any rows then create one using these
    # additional fields and values
    insert_fields => [ 'field_c', 'field_d', ... ],
    insert_values => [ 'value_c', 'value_d', ... ],
);

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub update_or_insert_one {
    my $self = shift;
    my $params = { @_ };

    my $existing = $self->select_one(
        [ '*' ],
        $params->{ table },
        $params->{ conditions },
    );
    if ( $existing ) {
        $self->update_one(
            $params->{ table },
            $params->{ update_fields },
            $params->{ update_values },
            $params->{ conditions },
        );
    }
    else {
        $self->insert_one(
            $params->{ table },
            [ @{ $params->{ update_fields }}, @{ $params->{ insert_fields }}],
            [ @{ $params->{ update_values }}, @{ $params->{ insert_values }}]
        );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub update_one {
    my $self = shift;
    my( $table, $fields, $values, $conditions ) = @_;
    return unless $table and $fields and $values and $conditions;

    my ( $where, @bind ) = $self->_where( $conditions );

    my $query = "UPDATE $table SET " . join( ', ', map { "$_ = ?" } @$fields );
    unshift @bind, @$values;
    $query .= " WHERE $where";

    debug( $query );
    $self->_enforce_transaction( $query, \@bind );
    my $sth = $self->dbh->prepare( $query );
    $sth->execute( @bind );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub delete_one {
    my $self = shift;
    my( $table, $conditions ) = @_;
    return unless $table and $conditions;

    my ( $where, @bind ) = $self->_where( $conditions );

    my $query = qq/DELETE FROM $table WHERE $where/;
    debug( $query );
    $self->_enforce_transaction( $query, \@bind );
    my $sth = $self->dbh->prepare( $query );
    $sth->execute( @bind );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 obj_insert( $object )

Object method.

Inserts C<$object> into the database.  Ignores field names which have C<undef>
values, which allows the database to set DEFAULT values.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub obj_insert {
    my $self = shift;
    my( $object ) = @_;

    my @values;
    my @fields;
    my $insert_queries = $object->fields( 1 );
    $insert_queries = undef 
        unless ref( $insert_queries ) eq 'HASH';

    for my $field( @{ $object->fields }) {
        # this is the line that prevents undef values being inserted
        # explicitly as NULL
        next unless defined $object->$field;
        next if $field eq $object->primary_key;
        push @fields => $field;
        push @values => $object->$field;
    }
    my $id = $self->insert_one(
        $object->table,
        \@fields,
        \@values,
        $object->primary_key,
        undef,
        $insert_queries,
    );
    $object->id( $id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 obj_update( $object )
      
Object method.

Updates C<$object> in the database by its primary key.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub obj_update {
    my $self = shift;
    my( $object ) = @_;
    
    my @fields = @{ $object->fields };
    my @values = map { $object->$_ } @fields;

    return $self->update_one(
        $object->table,
        \@fields,
        \@values,
        [ $object->primary_key . ' = ?', $object->id ],
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 do_sql( $sql [, $return_execution ])

Object method.

Runs a simple query.  Useful when none of the other query methods fit.

The first parameter must be a SQL query.  By default, the query is assumed to
be a C<SELECT> query, and results are returned as an arrayref of hashrefs.  The
second optional parameter tells the method to return the results of
C<execute()>, and should be used for non-C<SELECT> queries.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Executes arbitrary SQL
# do_sql( $sql, $return = 0, @parameters)
#
#  * $sql - the SQL statement to execute
#  * $return - if true, will return the return value, if false
#    will return an array of the row hashrefs
#  * @parameters - this should be a list of any binding parameters required
#    for the SQL
#
# If you are executing SQL that includes variable data, use DBH's quoting
# facilities:
#
#  my $return = 0;
#  my $bar = 1;
#  my $baz = 2;
#  do_sql( "select * from foo where bar = ? and baz = ?", $return, $bar, $baz);
#
# NOTE: Please note that parameters are passed as a simple list, not as an Array which
# will not be de-referenced properly.
#
# TODO arguments are a bit confusing for this and could be refactored into a 
# couple of methods?
sub do_sql {
    my $self = shift;
    my( $sql, $return, @parameters ) = @_;

    debug( "$sql\n" );
    $self->_enforce_transaction( $sql, \@parameters );
    my $sth = $self->dbh->prepare( $sql );

    my $return_value;
    $return_value = $sth->execute(@parameters);

    unless( $return ){
        return $sth->fetchall_arrayref( {} );
    }
    else {
        return $return_value; 
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub fetch_hashref {
    my $self = shift;
    my( $query, @bind_values ) = @_;

    debug( $query, \@bind_values );
    my $sth = $self->dbh->prepare( $query );
    $sth->execute( @bind_values );
    my( $row, @results );
    push @results => $row while( $row = $sth->fetchrow_hashref );
    return @results ? \@results : undef;
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
