# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

# Note: Adding or removing tables from the database will change this number, as one test is run for every element of %tables
use Test::More tests => 345;
use Test::Exception;
our ($CLASS, $one, %tables, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Test';
    use_ok( $CLASS );
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# basics
    ok( $one = $CLASS->new );
    ok( defined $one );
    isa_ok( $one, $CLASS );
    ok ( $test->recompile_fixtures );

    # commented out.  this causes a deeper failure in Test.pm that we cannot avoid.
    # the point of this code is to check that Test.pm's 'is_deeply_except' gives us
    # a useful error message when a test fails.
    # TODO: {
    #     local $TODO = 'NOT a real TODO; leave this in place, so we can manually check this return result.';
    #     ok( is_deeply_except(
    #         { a => undef },
    #         [ { id => 1001 }, ],
    #         [ { id => 'foo' }, ],
    #     ));
    # }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is deeply except
    throws_ok{ is_deeply_except() } qr/is_deeply_except: no 'exceptions' \(missing an argument\)/;
    ok( is_deeply_except(
        { id => qr/^\d+$/ },
        [ { id => 1001 }, ],
        [ { id => 'foo' }, ],
    ));
    ok( is_deeply_except(
        { id => qr/^\d+$/ },
        [ { id => 666 }, ],
        [ {}, ],
    ));

    ok( is_deeply_except(
        { id => qr/^\d+$/ },
        [
            { foo => 1, id => 666 },
        ],
        [
            { foo => 1, id => 333 },
        ],
    ));
    # using hashrefs
    ok( is_deeply_except(
        { id => qr/^\d+$/ },
        { foo => 1, id => 666 },
        { foo => 1, id => 333 },
    ));

    ok( is_deeply_except(
        { id => qr/^\d+$/ },
        [
            { foo => 1, id => 666, bar => 123, baz => 656  },
            { foo => 2, id => 666, bar => 133, baz => 856  },
            { foo => 3, id => 666, bar => 163, baz => 1456 },
            { foo => 4, id => 666, bar => 153, baz => 1256 },
            { foo => 5, id => 666, bar => 143, baz => 1056 },
        ],
        [
            { foo => 1, bar => 123, baz => 656, id => 3.14 },
            { foo => 2, bar => 133, baz => 856, id => 2.7 },
            { foo => 3, bar => 163, baz => 1456 },
            { foo => 4, bar => 153, baz => 1256 },
            { foo => 5, bar => 143, baz => 1056 },
        ],
    ));
    ok( is_deeply_except(
        { id => undef, baz => undef },
        [
            { foo => 1, id => 666, bar => 123, baz => 731  },
            { foo => 2, id => 666, bar => 133, baz => 931  },
            { foo => 3, id => 666, bar => 163, baz => 1531 },
            { foo => 4, id => 666, bar => 153, baz => 1331 },
            { foo => 5, id => 666, bar => 143, baz => 1131 },
        ],
        [
            { foo => 1, bar => 123, baz => 656, id => 3.14 },
            { foo => 2, bar => 133, baz => 856, id => 2.7 },
            { foo => 3, bar => 163, baz => 1456 },
            { foo => 4, bar => 153, baz => 1256 },
            { foo => 5, bar => 143, baz => 1056 },
        ],
    ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_test_info
    can_ok( $one, 'get_test_info' );
    is( $one->get_test_info, undef );
		is( $one->get_test_info( 'client', 'client' ),  undef );
		is( $one->get_test_info( 'client, fake', 'client' ),  undef );
		is( $one->get_test_info( 'client', 'fake' ), undef );
		is( $one->get_test_info( 'client, fake', 'fake' ), undef );

    is_deeply( $one->get_test_info( 'client_allergy' ), [
        $fixtures->{client_allergy}->{ 1001 },
        $fixtures->{client_allergy}->{ 1002 },
        $fixtures->{client_allergy}->{ 1003 },
        $fixtures->{client_allergy}->{ 1004 },
        $fixtures->{client_allergy}->{ 1005 },
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table_exists, failures
    can_ok( $one, 'table_exists' );
    is( $eleMentalClinic::Test::STRICT, 1 );

        $eleMentalClinic::Test::STRICT = 0;
    is( $one->table_exists, undef );
    is( $one->table_exists( 'bad name' ), undef );
    is( $one->table_exists( 'bad.name' ), undef );

        $eleMentalClinic::Test::STRICT = 1;
        eval{ $one->table_exists, undef };
    like( $@, qr/Must provide a valid table name/ );
        eval{ $one->table_exists( 'bad name' ) };
    like( $@, qr/Must provide a valid table name/ );
        eval{ $one->table_exists( 'bad.name' ) };
    like( $@, qr/Must provide a valid table name/ );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table_exists, successes
        $eleMentalClinic::Test::STRICT = 0;
    is( $one->table_exists( 'non_existent' ), 0 );
    is( $one->table_exists( 'client' ), 1 );
    is( $one->table_exists( 'personnel' ), 1 );
    is( $one->table_exists( 'valid_data_prognote_location' ), 1 );

        $eleMentalClinic::Test::STRICT = 1;
        eval{ $one->table_exists( 'non_existent' )};
    like( $@, qr/Must provide a valid table name/ );

    is( $one->table_exists( 'client' ), 1 );
    is( $one->table_exists( 'personnel' ), 1 );
    is( $one->table_exists( 'valid_data_prognote_location' ), 1 );

        $eleMentalClinic::Test::STRICT = 0;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# select_count
    can_ok( $one, 'select_count' );
    is( $one->select_count, undef );
    is( $one->select_count( 'this:that' ), undef );
    is( $one->select_count( 'foo' ), undef );

    is( $one->select_count( 'client_allergy' ), 0 );
    is( $one->select_count( 'valid_data_valid_data' ), 49 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# insert_table
    can_ok( $one, 'insert_table' );
    is( $one->insert_table, undef );
    is( $one->insert_table( undef, [qw/ 1001 1002 1003 /] ), undef );

    is( $one->select_count( 'valid_data_prognote_location' ), 1 );
    ok( $one->insert_( 'valid_data_prognote_location' ));
    is( $one->select_count( 'valid_data_prognote_location' ), 4 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# insert_
# TODO take a range of ids in addition to a list
    can_ok( $one, 'insert_' );
    is( $one->insert_, undef );
    is( $one->insert_( undef, [qw/ 1001 1002 1003 /] ), undef );

    ok( $one->insert_( 'eleMentalClinic::Client', [qw/ 1001 1002 1005 /] ) );
    ok( $one->insert_( 'eleMentalClinic::Client::Allergy' ));
    ok( $one->insert_( 'eleMentalClinic::Client::Placement::Event', [qw/ 1001 1002 1005 1007 1008 /] ) );

    is( $one->select_count( 'client_allergy' ), 5 );
    is( $one->select_count( 'client' ), 3 );
    is( $one->select_count( 'client_placement_event' ), 5 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# delete_table
    can_ok( $one, 'delete_table' );
    is( $one->delete_table, undef );
    is( $one->delete_table( undef, [qw/ 1001 1002 1003 /] ), undef );

    is( $one->select_count( 'valid_data_prognote_location' ), 4 );
    ok( $one->delete_table( 'valid_data_prognote_location', [ 1001, 1002, 1003, 1004 ], 'rec_id' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# delete_
# TODO check that package can table and primary_key
    can_ok( $one, 'delete_' );
    is( $one->delete_, undef );

    is( $one->select_count( 'client_allergy' ), 5 );
    ok( $one->delete_( 'eleMentalClinic::Client::Allergy', [qw/ 1002 1003 /] ) );
    is( $one->select_count( 'client_allergy' ), 3 );

    ok( $one->delete_( 'eleMentalClinic::Client::Allergy', [qw/ 1001 1004 1005 /] ) );
    is( $one->select_count( 'client_allergy' ), 0 );

    is( $one->select_count( 'client' ),           3 );
    is( $one->select_count( 'client_placement_event' ), 5 );
    ok( $one->delete_( 'eleMentalClinic::Client::Placement::Event' ) );
    ok( $one->delete_( 'eleMentalClinic::Client' ) );
    is( $one->select_count( 'client' ),           0 );
    is( $one->select_count( 'client_placement_event' ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test
    ok( $test );
    isa_ok( $test, $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# db_fields
# TODO check that package can table
# TODO check that pkg->table exists in the db
    can_ok( $one, 'db_fields' );
    is( $one->db_fields, undef );

    is( $one->db_fields( 'eleMentalClinic::Department'->table ), undef );

    is_deeply( $one->db_fields( 'eleMentalClinic::Client::Allergy'->table ), [qw/
        active allergy client_id created rec_id 
    /] );

    #print STDERR Dumper $one->db_fields(eleMentalClinic::Client->table);
    is_deeply( $one->db_fields( 'eleMentalClinic::Client'->table ), [qw/
            acct_id aka alcohol_abuse birth_name chart_id client_id comment_text
            consent_to_treat declaration_of_mh_treatment_date dependents_count dob
            dont_call edu_level email fname gambling_abuse has_declaration_of_mh_treatment
            household_annual_income household_population household_population_under18
            intake_step is_citizen is_veteran language_spoken living_arrangement lname
            marital_status mname name_suffix nationality_id race religion renewal_date section_eight send_notifications
            sex sexual_identity ssn state_specific_id substance_abuse working 
    /] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clear_client_rolodex_references
# (clear_references may no longer be an issue now that I'm not linking to rolodex
# tables from client...)

# XXX MERGE this fails
#    can_ok( $one, 'clear_references');
#    ok( $one->insert_( 'eleMentalClinic::Client' ) );
#    ok( $one->insert_table( 'rolodex' ) );
#    throws_ok 
#        { $one->db->do_sql("DELETE FROM client; DELETE FROM tracker WHERE client_id = 1003;", 'return') }
#        qr/violates foreign key constraint "rolodex_client_id_fkey"/, 
#        "unable to delete because of foreign key constraint";
#    ok( $one->clear_references('rolodex','client_id') );
#    ok( $one->db_refresh );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# import_data
    can_ok( $one, 'import_data' );

    # it must be possible to get a list of tables
    # and their row count from the db in one query.
        push( @$tmp, $_->{ tablename } ) for @{$one->db->do_sql(qq/
            SELECT  tablename
            FROM    pg_tables
            WHERE   schemaname = 'public'
            ORDER BY tablename
        /)};

        $tables{ $_ } = $one->db->do_sql(qq/
            SELECT count(*) FROM $_
        /)->[0]->{count} for @$tmp;
    is( $one->select_count( $_ ), $tables{ $_ }, $_ )
        for( keys %tables );

    ok( $one->import_data );

    #clean up
    ok( $one->delete_( 'eleMentalClinic::Client::Release' ) );
    ok( $one->delete_( 'eleMentalClinic::Client::Allergy' ) );
    ok( $one->delete_( 'eleMentalClinic::Client::Allergy' ) );
    ok( $one->delete_( 'eleMentalClinic::ProgressNote' ) );
    ok( $one->delete_( 'eleMentalClinic::Client::Insurance' ) );
    ok( $one->delete_table( 'client_placement_event' ));
    ok( $one->delete_table( 'rolodex_medical_insurance' ) );
    ok( $one->delete_table( 'rolodex_mental_health_insurance' ) );
    ok( $one->delete_table( 'rolodex_dental_insurance' ) );
    ok( $one->delete_table( 'rolodex_employment' ) );
    ok( $one->delete_table( 'rolodex_contacts' ) );
    ok( $one->delete_( 'eleMentalClinic::Rolodex' ) );
    ok( $one->delete_( 'eleMentalClinic::Client::Placement::Event' ) );
    ok( $one->delete_( 'eleMentalClinic::Client' ) );
    ok( $one->delete_( 'eleMentalClinic::Personnel', [ 1001, 1002, 1003 ] ) );
    ok( $one->delete_table( 'valid_data_prognote_location', [ 1001, 1002, 1003, 1004 ], 'rec_id' ));
    ok( $one->delete_table( 'valid_data_program', [ 1001, 1002 ], 'rec_id' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# insert_data and delete_data
    can_ok( $one, 'insert_data' );
    can_ok( $one, 'delete_data' );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# insert_data and delete_data
    # one as arrayref
    is( $one->select_count( 'valid_data_prognote_location' ), 1 );
        $one->insert_data([ qw/ valid_data_prognote_location /]);
    is( $one->select_count( 'valid_data_prognote_location' ), 4 );
        $one->db_refresh;
    is( $one->select_count( 'valid_data_prognote_location' ), 1 );

    # two as arrayref
    is( $one->select_count( 'valid_data_prognote_location' ), 1 );
    is( $one->select_count( 'valid_data_program' ), 2 );
        $one->insert_data([ qw/ valid_data_prognote_location valid_data_program /]);
    is( $one->select_count( 'valid_data_prognote_location' ), 4 );
    is( $one->select_count( 'valid_data_program' ), 6 );
        $one->db_refresh;
    is( $one->select_count( 'valid_data_prognote_location' ), 1 );
    is( $one->select_count( 'valid_data_program' ), 2 );

    # client data
    is( $one->select_count( 'client_allergy' ), 0 );
    is( $one->select_count( 'client' ), 0 );
    is( $one->select_count( 'client_placement_event' ), 0 );

        $one->insert_data([
            'eleMentalClinic::Client',
            'eleMentalClinic::Client::Placement::Event',
            'eleMentalClinic::Client::Allergy',
        ]);

    is( $one->select_count( 'client' ), 6 );
    is( $one->select_count( 'client_placement_event' ), 15 );
    is( $one->select_count( 'client_allergy' ), 5 );

        $one->db_refresh;

    is( $one->select_count( 'client_allergy' ), 0 );
    is( $one->select_count( 'client' ), 0 );
    is( $one->select_count( 'client_placement_event' ), 0 );

    # insert as table or object
    is( $one->select_count( 'client_allergy' ), 0 );
    is( $one->select_count( 'client' ), 0 );
    is( $one->select_count( 'client_placement_event' ), 0 );

        $one->insert_data([
            'eleMentalClinic::Client',
            'client_placement_event',
            'client_allergy',
        ]);

    is( $one->select_count( 'client' ), 6 );
    is( $one->select_count( 'client_placement_event' ), 15 );
    is( $one->select_count( 'client_allergy' ), 5 );

        $one->db_refresh;

    is( $one->select_count( 'client_allergy' ), 0 );
    is( $one->select_count( 'client' ), 0 );
    is( $one->select_count( 'client_placement_event' ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# insert and delete all at once
    is( $one->select_count( eleMentalClinic::Personnel->table ), 1 );
    ok( ! $one->select_count( 'client' ));
    ok( ! $one->select_count( 'client_placement_event' ));
    ok( ! $one->select_count( eleMentalClinic::Client::Allergy->table ));
    ok( ! $one->select_count( eleMentalClinic::Client::Release->table ));
    ok( ! $one->select_count( eleMentalClinic::Rolodex->table ));
    ok( ! $one->select_count( eleMentalClinic::Client::Insurance->table ));
    ok( ! $one->select_count( eleMentalClinic::ProgressNote->table ));
    ok( ! $one->select_count( 'rolodex_medical_insurance' ));
    ok( ! $one->select_count( 'rolodex_mental_health_insurance' ));
    ok( ! $one->select_count( 'rolodex_dental_insurance' ));
    ok( ! $one->select_count( 'rolodex_employment' ));
    ok( ! $one->select_count( 'rolodex_contacts' ));
    is( $one->select_count( 'valid_data_prognote_location' ), 1 );
    is( $one->select_count( 'valid_data_program' ), 2 );

        $one->insert_data;

    is( $one->select_count( eleMentalClinic::Personnel->table ), 7 );
    ok( $one->select_count( 'client' ));
    ok( $one->select_count( 'client_placement_event' ));
    ok( $one->select_count( eleMentalClinic::Client::Allergy->table ));
    ok( $one->select_count( eleMentalClinic::Client::Release->table ));
    ok( $one->select_count( eleMentalClinic::Rolodex->table ));
    ok( $one->select_count( eleMentalClinic::Client::Insurance->table ));
    ok( $one->select_count( eleMentalClinic::ProgressNote->table ));
    ok( $one->select_count( 'rolodex_medical_insurance' ));
    ok( $one->select_count( 'rolodex_mental_health_insurance' ));
    ok( $one->select_count( 'rolodex_dental_insurance' ));
    ok( $one->select_count( 'rolodex_employment' ));
    ok( $one->select_count( 'rolodex_contacts' ));
    is( $one->select_count( 'valid_data_prognote_location' ), 4 );
    is( $one->select_count( 'valid_data_program' ), 6 );

        $one->db_refresh;

    is( $one->select_count( eleMentalClinic::Personnel->table ), 1 );
    ok( ! $one->select_count( 'client' ));
    ok( ! $one->select_count( 'client_placement_event' ));
    ok( ! $one->select_count( eleMentalClinic::Client::Allergy->table ));
    ok( ! $one->select_count( eleMentalClinic::Client::Release->table ));
    ok( ! $one->select_count( eleMentalClinic::Rolodex->table ));
    ok( ! $one->select_count( eleMentalClinic::Client::Insurance->table ));
    ok( ! $one->select_count( eleMentalClinic::ProgressNote->table ));
    ok( ! $one->select_count( 'rolodex_medical_insurance' ));
    ok( ! $one->select_count( 'rolodex_mental_health_insurance' ));
    ok( ! $one->select_count( 'rolodex_dental_insurance' ));
    ok( ! $one->select_count( 'rolodex_employment' ));
    ok( ! $one->select_count( 'rolodex_contacts' ));
    is( $one->select_count( 'valid_data_prognote_location' ), 1 );
    is( $one->select_count( 'valid_data_program' ), 2 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();

