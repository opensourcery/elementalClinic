package eleMentalClinic::Test;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Test

=head1 SYNOPSIS

Parent of test system; contains all test data.

=head1 METHODS

=cut

use Test::More;
use Data::Dumper;
use CGI;
use YAML::Syck;
use Carp;
use eleMentalClinic::Fixtures;
$Data::Dumper::Sortkeys = 1;

$eleMentalClinic::DB::ENFORCE_TRANSACTIONS = { main => 1 };
use eleMentalClinic::DB;

use eleMentalClinic::Client::Allergy;
use eleMentalClinic::Mail;
use eleMentalClinic::Mail::Template;
use eleMentalClinic::Mail::Recipient;
use eleMentalClinic::Client::Notification;
use eleMentalClinic::Client::Release;
use eleMentalClinic::Client;
use eleMentalClinic::Department;
use eleMentalClinic::Schedule::Availability;
use eleMentalClinic::Schedule::Appointments;
use eleMentalClinic::Financial::ClaimsProcessor;
use eleMentalClinic::Financial::BillingCycle;
use eleMentalClinic::Financial::ValidationSet;
use eleMentalClinic::Financial::BillingFile;
use eleMentalClinic::Client::Insurance::Authorization;
use eleMentalClinic::Client::Insurance::Authorization::Request;
use eleMentalClinic::Client::AssessmentTemplate;

use base qw/ Exporter /;
our @EXPORT = qw/ $test $STRICT @DATA
        is_file_type
        is_pdf_file
        is_deeply_except
        filtered_is_deeply
        ids
        financial_reset_sequences
        is_rolodex
        pn_result
        $fixtures
        compare_scalar_file
        sort_objects
        check_exception_report
        get_exception_report
/;
our $STRICT = 1;
our @DATA;
our $FIXTURE_PATH ||= 'fixtures/testdata-jazz';

our $test = eleMentalClinic::Test->new;
our $fixtures = $test->load_fixtures;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
    my $proto = shift;
    my( $args ) = @_;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    return $self;
}

sub db_refresh {
    my $self = shift;
    $self->db->transaction_rollback if $self->db->transaction_depth > 0;
    $self->db->transaction_begin;
    $self->reset_sequences;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub config {
    return eleMentalClinic::Config->new;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# recompile the fixtures. Ideally, this should only be used once
# in the whole test run.
sub recompile_fixtures {
    my $self = shift;
    $fixtures = $self->load_fixtures(1);
    return $fixtures;
}

sub load_fixtures {
    my $self = shift;

    my ($recompile) = @_;

    my $fixtures = eleMentalClinic::Fixtures->load_fixtures( $FIXTURE_PATH, $recompile );

    # special cases
    # XXX this is a stupid hack; only look for fixtures_dir if the config is
    # loaded.  this makes things work properly under apache and in tests.
    my $fixtures_dir = $self->config->stage1_complete
        ? $self->config->stage1->fixtures_dir
        : 'fixtures';
    my %export = (
        %$fixtures,
        map {
            $_ => eleMentalClinic::Fixtures::load_fixture(
                $fixtures_dir . "/base-sys/$_.yaml"
            )
        } qw(claims_processor valid_data_race)
    );

    # FIXME Eventually the test files will need to be cleaned up
    #       to use some form of the fixtures hash.

    foreach my $name (keys %export) {
        no strict 'refs';
        no warnings qw/ once /;
        ${'eleMentalClinic::Test::'.$name} = $export{$name};
        push @EXPORT, "\$$name";
    }

    return $fixtures;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 is_deeply_except( \%exceptions, \@test_me, \@expected )

Function.

Tests the two data structures, expecting them to be identical except for the
items in C<\%exceptions>.  Those items are tested to exist in C<\@test_me> and
then deleted from both C<\@test_me> and from C<\@expected>.  Then C<\@test_me>
and <\@expected> are tested using C<is_deeply>.

C<\%exceptions> must be a hash reference.  Keys must be keys which you expect
in each C<\@test_me> item; values are optional.  If provided, the value must be
a quoted regular expression against which to match the value in each
C<\@test_me> item.

For example:

    is_deeply_except(
        { foo => qr/^\d+$/ },
        [{ foo => 123, bar => 'Belly up to the' }],
        [{ bar => 'Belly up to the' }],
    );

The two data structures are expected to be arrays of hash references.  Behavior
of any other type of data structures is undetermined.

This function is tested in t/000_test.t

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub is_deeply_except {
    my( $exceptions, $test_me, $expected ) = @_;

    my $caller = join ' : ' => ( caller() )[ 1, 2 ];
    croak "is_deeply_except: no 'exceptions' (missing an argument)"
        unless $exceptions and %$exceptions;
    croak "is_deeply_except: no 'test_me' (missing an argument)"
        unless $test_me;
    croak "is_deeply_except: no 'expected' (missing an argument)"
        unless $expected;

    # allow for single hashrefs
    $test_me = [ $test_me ]
        if ref $test_me ne 'ARRAY';
    $expected = [ $expected ]
        if ref $expected ne 'ARRAY';

    # avoid changing the data we pass in
    my( @test_me, @expected );
    push @test_me => { %$_ } for @$test_me;
    push @expected => { %$_ } for @$expected;

    is_deeply( \@test_me, $test_me, 'Verify copy' );
    is_deeply( \@expected, $expected, 'Verify copy' );

    while( my( $e_name, $e_regex ) = each %$exceptions ) {
        for my $datum( @test_me ) {
            like( $datum->{ $e_name }, qr/$e_regex/, $caller  )
                if $e_regex;
            delete $datum->{ $e_name };
        }
        # remove $exception from \@expected 
        delete $_->{ $e_name }
            for @expected;
    }

    is_deeply( \@test_me, \@expected )
        or diag "Failure of 'is_deeply_except' above was called from $caller\n";
    return 1;
}


=head2 is_pdf_file

  my $ok = is_pdf_file($file);
  my $ok = is_pdf_file($file, $name);

Tests if the $file is a PDF document.

=cut

sub is_pdf_file {
    my $file = shift;
    my $name = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is_file_type($file, "PDF", $name);
}


=head2 is_file_type

  my $ok = is_file_type($file, $type);
  my $ok = is_file_type($file, $type, $name);

Tests if the $file is the $type of file.

=cut

sub is_file_type {
    my($file, $type, $name) = @_;

    croak "is_file_type was not given a file" unless $file;
    croak "is_file_type was not given a type" unless $type;

    my $builder = Test::More->builder;

    $name ||= "$file is a $type file";

    $builder->ok( -f $file, "$file exists" );

    my $safe_file = quotemeta $file;
    return $builder->like(`file $safe_file`, qr/$type/, $name);
}


sub filtered_is_deeply {
    my ( $got, $want, $comment ) = @_;
    # copy $got so that we can do as we please.
    my $copy = { %$got };
    for ( keys %$copy ) {
        delete $copy->{ $_ } unless defined $want->{ $_ };
    }
    return is_deeply( $copy, $want, $comment );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub setup_cgi {
    my $self = shift;
    my( %vars ) = @_;

    return unless %vars;
    undef @CGI::QUERY_PARAM; # reset query string cache
    $ENV{ REQUEST_METHOD } = 'GET';
    $ENV{ QUERY_STRING } = '';
    while( my( $key, $val ) = each %vars ) {
        $ENV{ QUERY_STRING } .= "$key=$val;"
    }
    chop $ENV{ QUERY_STRING };
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Checks if a given scalar matches a given file 
#

sub compare_scalar_file {
    my ( $scalar, $fn ) = @_;
    my $file;
    
    open( FILE, '<', $fn );
    while ( my $line = <FILE> ) {
        $file .= $line;
    }
    close( FILE );

    is( $scalar, $file );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub db {
    eleMentalClinic::DB->new;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns undef on error
# 1 if table exists, 0 if it does not
# with strict, dies on any error
sub table_exists {
    my $self = shift;
    my( $table ) = @_;

    my $errmsg = 'Must provide a valid table name';
    if( $STRICT ) {
        die $errmsg unless $table and $table =~ /^\w+$/;
    }
    else {
        return unless $table and $table =~ /^\w+$/;
    }

    # the count of tables with this name, which can only be 1 or 0
    my $count = $self->db->do_sql(qq/
        SELECT count(*) FROM pg_tables WHERE tablename = '$table'
    /)->[0]->{ count };

    die $errmsg if $STRICT and !$count;
    $count;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# expects $table, $ids
# selects all if ids is undef
#sub insert_table {
#    my $self = shift;
#    my( $table, $ids ) = @_;
#    return unless $table;
#
#    unless( $table =~ m/,/ ){
#        my $data = $self->get_test_info( $table, $ids );
#        $self->db->insert_one( $table, [ keys %$_ ], [ values %$_ ], undef, { no_currval => 1, }, )
#            for @$data;
#    }
#    else {
#        # special case for client, sigh.
#        my $data = $self->get_test_info( 'client', $ids );
#        for my $datum ( @$data ){
#            for( split( /, /, $table ) ){
#                my $fields = $self->db_fields( $_ );
#                my @values = @$datum{ @$fields };
#                return unless $self->db->insert_one(
#                    $_,
#                    $fields,
#                    \@values,
#                    undef,
#                    {
#                        no_currval => 1,
#                    },
#                );
#            }
#        }
#    }
#    return 1;
#}
sub insert_table {
    my $self = shift;
    my( $table, $ids ) = @_;
    return eleMentalClinic::Fixtures->insert_table( $table, $FIXTURE_PATH, 1, $ids );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# expects $data, $ids
# decides if $data is an object or a table
# inserts all records if given no ids
#sub insert_ {
#    my $self = shift;
#    my( $data, $ids ) = @_;
#    return unless $data;
#
#    $data =~ /^eleMentalClinic::/
#        ? $self->insert_table( $data->table, $ids )
#        : $self->insert_table( $data, $ids );
#}
sub insert_ {
    my $self = shift;
    my( $table, $ids ) = @_;
    return eleMentalClinic::Fixtures->insert_( $table, $FIXTURE_PATH, 1, $ids );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# expects $table, $ids
sub delete_table {
    my $self = shift;
    my( $table, $ids, $primary_key ) = @_;
    return unless $table;

    my $where;
    if( $ids and $primary_key ){
        $primary_key =~ s/.*\.//;
        $where = "$primary_key IN (". join( ',', @$ids ) .")";
    }
    else {
        $where = '1=1'
    }

    unless( $table =~ /,/ ){
        $self->clear_references('rolodex', 'client_id');
        $self->db->delete_one( $table, $where );
    }
    else {
        $self->db->delete_one( $_, $where )
            for(qw/ client /);
    }
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1

Clear foreign key references.

=cut

sub clear_references {
    my $self = shift;
    my ($table, $field) = @_;
    
    $self->db->do_sql("UPDATE $table SET $field = null;", 'return');
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# expects $data, $ids
# decides if $data is an object or a table
sub delete_ {
    my $self = shift;
    my( $data, $ids, $primary_key ) = @_;
    return unless $data;

    $primary_key ||= 'rec_id';
    if( $ids and $ids eq '*' ) { # delete everything
        undef $ids;
    }
    elsif( not defined $ids ) { # delete all test data
        $ids = [ 1000..1700 ];
    }
   
    $data =~ /^eleMentalClinic::/
        ? $self->delete_table( $data->table, $ids, $data->primary_key )
        : $self->delete_table( $data, $ids, $primary_key );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# does a count of the table it gets and returns the number of rows
sub select_count {
    my $self = shift;
    my( $table ) = @_;

    return unless $self->table_exists( $table );
    $self->db->do_sql(qq/
        SELECT count(*) FROM $table
    /)->[0]->{ count };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns array of tables and data
#sub get_test_info {
#    my $self = shift;
#    my( $table, $ids ) = @_;
#    return unless $table;
#        return unless !( $ids ) || ref $ids eq 'ARRAY';
#
#    $table =~ s/(\w*), .*/$1/;  # for client
#
#    my $data = $fixtures->{$table};
#    @$ids = sort keys %$data
#        unless $ids;
#    my @result = @{$data}{ @$ids };
#    return \@result;
#}
# XXX ugly ugly
sub get_test_info {
    my $self = shift;
    my( $table, $ids ) = @_;
    return eleMentalClinic::Fixtures->get_test_info( $table, $FIXTURE_PATH, $ids );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub db_fields {
    my $self = shift;
    my( $table ) = @_;
    return unless $table;

    $table = "'$table'";
    if( $table =~ /, / ){
        $table =~ s/, /', '/g;
    }

    # this is postgres-specific.  for other dbs, see
    # http://sqlzoo.net/howto/source/z.dir/tip043395
    # the pg.dropped madness comes from:
    # - http://lists.ee.ethz.ch/gedafe-dev/msg00096.html
    # and is more or less documented:
    # - http://beta.linuxports.com/pgsql-admin/2006-04/msg00360.php
    my $tmp = $self->db->do_sql(qq/
        SELECT  DISTINCT attname
        FROM    pg_class, pg_attribute
        WHERE   relname IN ( $table )
            AND pg_class.oid = attrelid
            AND attnum > 0
            AND attname != ('........pg.dropped.' || attnum || '........')
    / );
    return unless $tmp->[0];

    my @result = sort map { $_->{attname} } @$tmp;
    return \@result;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# accept arrayref or hashref
# insert each one, record what was inserted
# XXX extend functionality to Fixtures or eliminate entirely
sub insert_data {
    my $self = shift;
    my( $data ) = @_;

    die 'Parameter to insert_data must be arrayref'
        if $data and ref $data ne 'ARRAY';

    # just insert what we're asked
    if( $data ) {
        my @INSERT_ORDER_COPY;
        for( eleMentalClinic::Fixtures->insert_order ){
            push @INSERT_ORDER_COPY, $_;
            push @INSERT_ORDER_COPY, $_->table
                if $_ =~ /^eleMentalClinic::/;
            # XXX hack for insert_rolodex_dirty
            push @INSERT_ORDER_COPY, "$_\_dirty";
            push @INSERT_ORDER_COPY, $_->table . "_dirty"
                if $_ =~ /^eleMentalClinic::/;
        }

        for my $ord( @INSERT_ORDER_COPY ) {
            if( grep /^$ord$/ => @$data ) {
                $self->insert_( $ord );
            }
        }
    }
    # otherwise, insert everything
    else {
        for( eleMentalClinic::Fixtures->insert_order ) {
            $self->insert_( $_ );
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# accept arrayref or hashref
# delete everything in @INSERT_ORDER, in reverse order
sub delete_data {
    my $self = shift;
    my( $args ) = @_;

    warn 'Dropping all test data with "*" is lazy, and deprecated'
        if $args and $args eq '*';
    for( reverse( eleMentalClinic::Fixtures->insert_order )) {
        $self->delete_( $_, $args );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub import_data {
    my $self = shift;
    
    $self->insert_( 'eleMentalClinic::Personnel' );
    $self->insert_( 'eleMentalClinic::Client' );
    $self->insert_( 'eleMentalClinic::Client::Placement::Event' );
    $self->insert_( 'eleMentalClinic::Client::Allergy' );
    $self->insert_( 'eleMentalClinic::Client::Release' );
    $self->insert_( 'eleMentalClinic::Financial::ClaimsProcessor' );
    $self->insert_( 'eleMentalClinic::Rolodex' );
    $self->insert_( 'eleMentalClinic::Client::Insurance' );
    $self->insert_( 'eleMentalClinic::ProgressNote' );

    $self->insert_table( 'rolodex_medical_insurance' );
    $self->insert_table( 'rolodex_mental_health_insurance' );
    $self->insert_table( 'rolodex_dental_insurance' );
    $self->insert_table( 'rolodex_employment' );
    $self->insert_table( 'rolodex_contacts' );
    $self->insert_table( 'valid_data_prognote_location' );
    $self->insert_table( 'valid_data_program' );
    $self->insert_table( 'valid_data_level_of_care' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub insert_rolodex_dirty_data {
    my $self = shift;
    my( $data ) = @_;

    die 'Parameter to insert_data must be arrayref'
        if $data and ref $data ne 'ARRAY';

    # should this list be generated by looking at $FIXTURE_PATH instead?
    my %has_dirty = map {; $_ => 1 } qw(
        rolodex 
        rolodex_medical_insurance 
        rolodex_mental_health_insurance
        rolodex_dental_insurance
        rolodex_employment
        rolodex_contacts
        rolodex_treaters
        rolodex_referral
        client_contacts
        client_release
        client_insurance
        client_employment
        client_treaters
        client_referral
        phone
        address
    );

    @$data = map { $_, $has_dirty{$_} ? ("$_\_dirty") : () } @$data;

    $self->insert_data( $data );
}

sub reset_sequences {
    my $self = shift;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub financial_reset_sequences {
    $test->db->do_sql(qq/ SELECT setval( 'billing_file_rec_id_seq', 1001, false ) /);
    $test->db->do_sql(qq/ SELECT setval( 'billing_claim_rec_id_seq', 1001, false ) /);
    $test->db->do_sql(qq/ SELECT setval( 'billing_service_rec_id_seq', 1001, false ) /);
    $test->db->do_sql(qq/ SELECT setval( 'billing_prognote_rec_id_seq', 1001, false ) /);
    $test->db->do_sql(qq/ SELECT setval( 'transaction_deduction_rec_id_seq', 1001, false ) /);
    $test->db->do_sql(qq/ SELECT setval( 'billing_payment_rec_id_seq', 1001, false ) /);
    $test->db->do_sql(qq/ SELECT setval( 'transaction_rec_id_seq', 1001, false ) /);
    $test->db->do_sql(qq/ SELECT setval( 'billing_cycle_rec_id_seq', 1001, false ) /);
    $test->db->do_sql(qq/ SELECT setval( 'validation_prognote_rec_id_seq', 1001, false ) /);
    $test->db->do_sql(qq/ SELECT setval( 'validation_set_rec_id_seq', 1001, false ) /);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub financial_delete_data {
    $test->delete_( 'validation_set', '*' );
    $test->delete_( 'validation_prognote', '*' );
    $test->delete_( 'prognote_bounced', '*' );
    $test->delete_( 'transaction_deduction', '*' );
    $test->delete_( 'transaction', '*' );
    $test->delete_( 'billing_prognote', '*' );
    $test->delete_( 'billing_service', '*' );
    $test->delete_( 'billing_claim', '*' );
    $test->delete_( 'billing_file', '*' );
    $test->delete_( 'billing_cycle', '*' );
    $test->delete_( 'prognote', '*' );
    $test->delete_( 'billing_payment', '*' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 ids( \@hashrefs [, $field ])

Function.

Returns an arrayref composed of each C<$field> in each element of C<\@hashrefs>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub ids {
    my( $data, $field ) = @_;
    $field ||= 'rec_id';
    $field = 'id'
        unless exists $data->[ 0 ]{ $field };
    return [ map{ $_->{ $field }} @$data ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 add_prognotes([ $count ])

Object method.

Add C<$count>, or 100, progress notes.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub add_prognotes {
    my $test = shift;
    my( $count ) = @_;

    $count ||= 100;

    $test->delete_( 'prognote_bounced', '*' );
    $test->delete_( 'billing_cycle', '*' );
    $test->delete_( 'validation_set', '*' );
    $test->delete_( 'validation_prognote', '*' );
    $test->delete_( 'prognote', '*' );
    $test->delete_( 'validation_result', '*' );
    $test->delete_data;
    $test->insert_data;
    $test->delete_( 'prognote_bounced', '*' );
    $test->delete_( 'prognote', '*' );

    my @ids = keys %{$fixtures->{prognote}};
    my @notes = map{ $_ } values %{$fixtures->{prognote}};
    delete $_->{ rec_id }
        for @notes;

    print "Creating $count progress notes\n";
    for( 1..$count ) {
        print '.';
        eleMentalClinic::ProgressNote->new( $notes[ int rand length @ids ])->save;
    }
    print "\n";
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 is_rolodex( $to_test, $rolodex_id )

Function, exported by default.

Shorthand for two tests:

    is_deeply( $to_test, $rolodex->{ $rolodex_id });
    isa_ok( $to_test, 'eleMentalClinic::Rolodex' );

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub is_rolodex {
    my( $to_test, $rolodex_id ) = @_;

    croak 'RTFP: $to_test required'
        unless $to_test;
    croak 'RTFP: $rolodex_id required'
        unless $rolodex_id;

    my $caller = join ' : ' => ( caller() )[ 1, 2 ];
    is_deeply( $to_test, $fixtures->{rolodex}->{ $rolodex_id }, $caller );
    isa_ok( $to_test, 'eleMentalClinic::Rolodex', $caller );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 financial_setup( [$cyclenum, $leading_path, $options] )

Object method. Creates the billing cycle, and depending on options,
does system validation, does payer validation, bills a claim,
processes payment, creates a 2nd billing cycle and bills and pays it.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub financial_setup {
    my $test = shift;
    my( $cyclenum, $leading_path, $options ) = @_;
    my $billing_cycle;

    if( $cyclenum == 1 ){
        $billing_cycle = $test->financial_setup_billingcycle( reset_sequences => 1 );
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );
        $test->financial_setup_bill( $billing_cycle );
    }
    elsif( $cyclenum == 2 ){

        $billing_cycle = $test->financial_setup_billingcycle;
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1005 ], [ 1014 ] ); 
        $test->financial_setup_bill( $billing_cycle, [ 1003 ], [], '2006-08-31 18:04:25' );
    }
    elsif( $cyclenum == 3 ){

        $billing_cycle = $test->financial_setup_billingcycle( creation_date => '2006-07-31', from_date => '2006-07-16', to_date => '2006-07-31' );
        $test->financial_setup_system_validation( $billing_cycle, [ qw/ 1001 1003 1004 / ] );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1006 ], [ 1015 ] ); 
        $test->financial_setup_bill( $billing_cycle, [ 1004 ], [], '2006-08-15 18:04:25' );
    }
    elsif( $cyclenum == 4 ){

        $billing_cycle = $test->financial_setup_billingcycle( creation_date => '2006-07-31', from_date => '2006-07-16', to_date => '2006-07-31' );
        $test->financial_setup_system_validation( $billing_cycle, [ qw/ 1001 1003 1004 / ] );
        $test->financial_setup_payer_validation( $billing_cycle, [ 1006 ], [ 1014 ] ); 
        $test->financial_setup_bill( $billing_cycle, [ 1005 ], [], '2006-09-06 18:04:25' );
    }

    $billing_cycle->validation_set->finish;
    
    return if
        $options and $options->{ no_payment };

    $test->financial_setup_payment( $cyclenum, $leading_path );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 financial_setup_billingcycle( [%args]  )

Object method. Creates the billing cycle.

Default args values: {   
    reset_sequences => 0, 
    staff_id => 1005, 
    creation_date => '2006-07-15', 
    from_date => '2006-07-01',
    to_date => '2006-07-15',
}

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub financial_setup_billingcycle {
    my $test = shift;
    my( %args ) = @_;

    # do the database setup
    financial_reset_sequences()
        if $args{ reset_sequences };

    my $validation_set = eleMentalClinic::Financial::ValidationSet->create({
        creation_date   => $args{ creation_date } || '2006-07-15',
        staff_id        => $args{ staff_id } || 1005,
        type            => 'billing',
        from_date       => $args{ from_date } || '2006-07-01',
        to_date         => $args{ to_date } || '2006-07-15',
        step            => 2,
    });

    die "Unable to create a validation set. There may be one like this already started."
        unless $validation_set;

    return $validation_set->billing_cycle;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 financial_setup_system_validation( $billing_cycle, [$rule_ids] )

Object method. Runs system validation on the billing cycle. Assumes the
billing cycle is already set up

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub financial_setup_system_validation {
    my $test = shift;
    my( $billing_cycle, $rule_ids ) = @_;

    return unless $billing_cycle;
    $rule_ids ||= [ qw/ 1001 1003 1004 1010 /];

    $billing_cycle->validation_set->system_validation( $rule_ids );
    $billing_cycle->group_prognotes_by_insurer;
    $billing_cycle->step( 4 );
    $billing_cycle->status( 'Begun' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 financial_setup_payer_validation( $billing_cycle, [$rule_ids, $rolodex_ids] )

Object method. Runs payer validation on the billing cycle. Assumes system
validation has already been run.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub financial_setup_payer_validation {
    my $test = shift;
    my( $billing_cycle, $rule_ids, $rolodex_ids ) = @_;

    return unless $billing_cycle;
    $rule_ids ||= [ 1006 ];
    $rolodex_ids ||= [ qw/ 1009 1015 / ];

    for( @$rolodex_ids ){

        $billing_cycle->payer_validation( $rule_ids, $_ );
        $billing_cycle->move_notes_to_billing( $_ );
    }
    $billing_cycle->status( 'Validating' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 financial_setup_bill( $billing_cycle, [$write_837, $write_hcfa, $date] )

Object method. Sets up the database as if the billing cycle has been
billed. Assumes that both validations have been run.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub financial_setup_bill {
    my $test = shift;
    my( $billing_cycle, $write_837, $write_hcfa, $date ) = @_;

    return unless $billing_cycle;
    $write_837 ||= [ 1002 ];
    $write_hcfa ||= [ 1001 ];
    $date ||= '2006-07-15 18:04:25';

    for( @$write_837 ){ 

        my( $file837, $edi_data ) = eval { $billing_cycle->write_837( $_, $date ); };

        # ECS files need to be marked as submitted separately from file generation
        my $billing_file = eleMentalClinic::Financial::BillingFile->retrieve( $_ );
        $billing_file->save_as_billed( $date, $edi_data );

        if( $@ ){
            $billing_cycle->finish;
            die $@;
        }
    }

    for( @$write_hcfa ){

        eval { 
            $billing_cycle->write_hcfas( $_, $date ); 
        };
        if( my $error = $@ ){
            $billing_cycle->finish;
            die "Billing cycle error in 'write_hcfas': $error";
        }
    }

    # TODO set $billing_cycle->status( '??' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 financial_setup_payment( $filenum, [$leading_path] )

Object method. Processes payment using sample_835.1.txt or 
sample_835.2.txt depending on the $filenum.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub financial_setup_payment {
    my $test = shift;
    my( $filenum, $leading_path ) = @_;

    $leading_path ||= '';
    my $filename = "${ leading_path }t/resource/sample_835.$filenum.txt";

    my $billing_payment = eleMentalClinic::Financial::BillingPayment->new;
    $billing_payment->process_remittance_advice( $filename, '2006-09-05' );

    die "Unable to process sample remittance advice"
        unless $billing_payment->payment_method eq 'CHK';
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 compare_837s_byline( $samplefilename, $generatedfilename )

Class method. 

Helper method for tests. Compares two files by line, rather than as a whole,
so that errors are easier to spot.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub compare_837s_byline {
    my $class = shift;
    my( $samplefilename, $generatedfilename ) = @_;
    my( $samplefile, $generatedfile );
        
    # setup golden data for testing comparison
    my( $samplelines, undef ) = $class->split_file( $samplefilename );
    
    # now open the file to check 
    my( $resultlines, undef ) = $class->split_file( $generatedfilename );

    is_deeply( $resultlines, $samplelines );
}   

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 split_file( $filename )

Class method.

Helper method for tests. Read in a file and split it into an array.
Returns the arrayref and block of text.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub split_file {
    my $class = shift;
    my( $filename ) = @_;
    my( $filetext );
    
    open EDI, "< $filename";
    while( my $line = <EDI> ){
        $filetext .= $line;     
    }   
    close EDI;
    
    # generally, sample files are separated by newlines, generated files separated by ~
    my @lines = split( /\n|\~/ => $filetext );
    return ( \@lines, $filetext );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 pn_result( $prognote_id )

Object method.

Helper method for tests.  Looks up and returns a few progress note fields.
Helps make the tests shorter and easier to refactor.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub pn_result {
    my( $prognote_id ) = @_;

    my $note = eleMentalClinic::ProgressNote->retrieve( $prognote_id );
    die 'Invalid id'
        unless $note;
    my $duration = $note->note_duration;

    my %locations_damnit = (
        %{$fixtures->{valid_data_prognote_location}},
        1 => {
            rec_id          => 1,
            dept_id         => 1001,
            name            => 'Office',
            facility_code   => 11,
            active          => 1,
            description     => undef,
        },
    );
    my %codes_damnit = (
        %{$fixtures->{valid_data_charge_code}},
        1 => {
            rec_id          => 1,
            dept_id         => 1001,
            name            => 'N/A',
            active          => 1,
        },
        2 => {
            rec_id          => 2,
            dept_id         => 1001,
            name            => 'No Show',
            active          => 1,
        },
        3 => {
            rec_id          => 3,
            dept_id         => 1001,
            name            => 'Default Charge Code',
            active          => 1,
        },
    );

    return(
        %$note,
        id          => $note->id,
        note_date   => $note->note_date,
        bounced     => $note->bounced ? 1 : 0,
        client_name => $note->client->eman,
        location_name   => $locations_damnit{ $note->note_location_id }->{ name },
        charge_code_name   => $codes_damnit{ $note->charge_code_id }->{ name },
        note_duration   => ( $duration->[ 0 ] || 0 ) * 3600 + ( $duration->[ 1 ] || 0 ) * 60 + ( $duration->[ 2 ] || 0 ),
        note_units => $note->units,
    );
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
# Starts the server, takes an optional httpd.conf template
#

sub start_server {
    my ($httpd_conf, $emc_config) = @_;

    $emc_config ||= {};

    my $port = find_free_port();

    if (!$port) {
        die "Couldn't find a free port and EMC_TEST_USE_PORT is not set in the environment";
    }

    my $cmdline = "--test -n";
    $cmdline   .= " --template $httpd_conf" if ($httpd_conf);

    my $filename = "/tmp/emc.$port.config.yaml";
    open my $fh, '>', $filename or die "Can't write to $filename: $!";
    YAML::Syck::DumpFile(
        $filename,
        {
            %{ YAML::Syck::LoadFile('./config.yaml') },
            %$emc_config,
        },
    );
    $cmdline   .= " -c $filename";

    $cmdline    = "$^X bin/start_httpd --port $port $cmdline $ENV{PWD}";
    if (!system($cmdline)) {
        warn "Setup apache server on port $port" if ($port);
        sleep 5;
        return $port;
    } 
     
    Carp::croak "could not start apache:\n  $cmdline\nsee error log for details";
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
# Kill an existing server. Takes a port as an argument.
#

sub stop_server {
    my $port = shift;

    return !system(qq(sh bin/kill_httpd --quiet $port));
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
# Find a free port using a bind() mechansm over a static set of possible ports.
#

sub find_free_port { 
    return $ENV{EMC_TEST_USE_PORT} if $ENV{EMC_TEST_USE_PORT};

    #
    # Otherwise, we're going to bind to a specific set of ports until we find one that works for us.
    #
  
    use Socket;
    foreach my $port (qw(8000 8080 8100 8200 8300 8400 8500 8600 8700 8800 8900)) {

        socket(SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
        if(bind(SOCK, sockaddr_in($port, inet_aton("localhost")))) {
            close(SOCK);
            return $port;
        }
    }

    return undef;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
# Sort a list of object by ID, this is an incredibly common sort, so it should not need to be typed every time.
# Takes an array reference, returns a new array reference
#
sub sort_objects {
    my $unsorted = shift;
    return [ sort { $a->id <=> $b->id } @{ $unsorted } ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#sub check_exception_report {
#    my ( $report_a, $report_b, $message ) = @_;
#    # Stack trace probably won't match
#    ok( $report_a =~ s/Stack Trace:.*//is, "Removed a stack trace" );
#    ok( $report_b =~ s/Stack Trace:.*//is, "Removed a stack trace" );
#    ok( $report_a =~ s/Revision:.*//is, "Removed a Revision" );
#    ok( $report_b =~ s/Revision:.*//is, "Removed a Revision" );
#    is( $report_a, $report_b, $message );
#}

sub get_exception_report {
    my ( $msg ) = @_;
    my $file = eleMentalClinic::Log::ExceptionReport->message_is_catchable( $msg );
    return unless $file;
    open( my $fh, "<", $file ) || die("$!");
    my @file = <$fh>;
    close( $fh );
    return join( '', @file );
}

'eleMental';

