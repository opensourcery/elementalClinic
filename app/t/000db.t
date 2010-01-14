# vim: ts=4 sts=4 sw=4
# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 44;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Client::Allergy;
use eleMentalClinic::Log::ExceptionReport;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::DB';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# obj_insert, initial API
    can_ok( $one, 'obj_insert' );

        $tmp = eleMentalClinic::Client::Allergy->new({
            client_id   => 1001,
            allergy     => 'Plutonium;DROP DATABASE',
            created     => '2006-01-01',
            active      => 1,
            fake_field  => 'fake value',
        });
    is( $tmp->id, undef );

    is( $test->select_count( 'client_allergy' ), 5 );
    like( $one->obj_insert( $tmp ), qr/\d+/ );
    is( $test->select_count( 'client_allergy' ), 6 );
    is_deeply( eleMentalClinic::Client::Allergy->retrieve( $tmp->id ), $tmp );

    is_deeply(
        eleMentalClinic::Client::Allergy->get_many_where(
            [ 'rec_id = ? AND client_id = 1001', $tmp->id ],
        ),
        [ $tmp ],
    );
    is_deeply(
        eleMentalClinic::Client::Allergy->get_one_where(
            [ 'rec_id = ? AND client_id = 1001', $tmp->id ],
        ),
        $tmp,
    );

        $tmp->delete;
    is( $test->select_count( 'client_allergy' ), 5 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# obj_insert, allowing database to set default
        $tmp = eleMentalClinic::Client::Allergy->new({
            client_id   => 1001,
            allergy     => 'Peanuts',
            created     => '2001-01-01',
        });
    is( $tmp->id, undef );

    is( $test->select_count( 'client_allergy' ), 5 );
    like( $one->obj_insert( $tmp ), qr/\d+/ );
    is( $test->select_count( 'client_allergy' ), 6 );
    is_deeply( eleMentalClinic::Client::Allergy->retrieve( $tmp->id ), {
        %$tmp, active => 1,
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# obj_update, initial API
# TODO test quoting
    can_ok( $one, 'obj_update' );
        $tmp->active( 1 );
    is( $one->obj_update( $tmp ), 1 );

    # new code
    # this causes a DB error, so must remain commented
=for
    TODO: {
        local $TODO = 'Code for this can work, but has other bad effects.';

            delete $tmp->{ active };
        is( $one->obj_update( $tmp ), 1 );
        is_deeply( eleMentalClinic::Client::Allergy->retrieve( $tmp->id ), {
            %$tmp, active => 1,
        });
    }
=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    {
        package eleMentalClinic::FakeSpecial;
        use base 'eleMentalClinic::DB::Object';

        sub table{ 'fake' }
        sub primary_key{ 'rec_id' }

        sub fields {
            my $self = shift;
            my ( $insert_queries ) = @_;

            return [ qw/ rec_id number_in_set set arbitrary / ] unless $insert_queries;

            return {
                # Special instructions for the fields
                number_in_set => {
                    # Query to use on insert to calculate or find the value.
                    insert_query => 'SELECT (MAX(number_in_set) + 1) FROM '. 
                                    eleMentalClinic::FakeSpecial->table .
                                    ' WHERE set = ?',
                    # Default if the query does not return anything (used if the field cannot be null)
                    default => 0,
                    # If the subquery requires parameters specify them here, these must be
                    # methods for the object being saved. 
                    params => [ $self->set || '0' ], #FIXME, either we forbid using a param
                    # that needs a subquery withina subquery, or we find a way to capture the value
                    # This is beyond the scope of my current task though, so for now it is TODO
                },
                # Always add to the most recent set.
                set => {
                    insert_query => 'select max(set) from ' . eleMentalClinic::FakeSpecial->table,
                    default => 0,
                },
                # Another one just for thurough testing.
                arbitrary => {
                    insert_query => 'select fname from ' . eleMentalClinic::Client->table . ' where client_id = 1001',
                    default => 'Bob',
                }
            };
        }
    }

    ok( $one->do_sql( 'drop table if exists fake', 1 ) , 'drop table if exists' );

    ok( $one = $CLASS->new , "can create new $CLASS" );

    ok( $one->do_sql( q{
        create table fake(
            rec_id serial primary key not null,
            number_in_set integer not null,
            set integer not null,
            arbitrary varchar(32)
        )
    }, 1 ) , 'create table fake statement works' );

    #Should auto calculate the value since it is not specified
    $tmp = eleMentalClinic::FakeSpecial->new;
    $tmp->save;
    $tmp = eleMentalClinic::FakeSpecial->retrieve( $tmp->rec_id );
    is_deeply(
        $tmp,
        {
            rec_id => 1,
            number_in_set => 0,
            set => 0,
            arbitrary => 'Miles',
        }
    );

    $tmp = eleMentalClinic::FakeSpecial->new;
    $tmp->save;
    $tmp = eleMentalClinic::FakeSpecial->retrieve( $tmp->rec_id );
    is_deeply(
        $tmp,
        {
            rec_id => 2,
            number_in_set => 1,
            set => 0,
            arbitrary => 'Miles',
        }
    );

    $tmp = eleMentalClinic::FakeSpecial->new;
    $tmp->save;
    $tmp = eleMentalClinic::FakeSpecial->retrieve( $tmp->rec_id );
    is_deeply(
        $tmp,
        {
            rec_id => 3,
            number_in_set => 2,
            set => 0,
            arbitrary => 'Miles',
        }
    );

    #Should not change/recalc if it is already set.
    $tmp->save;
    $tmp = eleMentalClinic::FakeSpecial->retrieve( $tmp->rec_id );
    is_deeply(
        $tmp,
        {
            rec_id => 3,
            number_in_set => 2,
            set => 0,
            arbitrary => 'Miles',
        }
    );

    #Start a new set
    $tmp = eleMentalClinic::FakeSpecial->new;
    $tmp->set( 1 );
    $tmp->save;
    $tmp = eleMentalClinic::FakeSpecial->retrieve( $tmp->rec_id );
    is_deeply(
        $tmp,
        {
            rec_id => 4,
            number_in_set => 0,
            set => 1,
            arbitrary => 'Miles',
        }
    );


    TODO: {
    local $TODO = "Cannot yet use a parameter w/ an insert_query that needs data from another parameter with an insert query.";
    $tmp = eleMentalClinic::FakeSpecial->new;
    $tmp->save;
    $tmp = eleMentalClinic::FakeSpecial->retrieve( $tmp->rec_id );
    is_deeply(
        $tmp,
        {
            rec_id => 4,
            number_in_set => 1,
            set => 1,
            arbitrary => 'Miles',
        }
    );

    }

    ok( $one->do_sql( 'drop table if exists fake', 1 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my $sth;
my $dbh = $one->dbh;
dies_ok { 
    $sth = $dbh->do("CREATE TABLE fake( id int, name text, bob text, fake fake)");
};
my $error = get_exception_report( $@ );
ok( $error =~ m/CREATE TABLE fake\( id int, name text, bob text, fake fake\)/, "Check for statement" );
ok( $error =~ m/DBI::db::do/, "Check for function defenition" );
ok( $error =~ m/params/, "Check that parameters are listed" );

dies_ok { 
    my $dbh = $one->dbh;
    my $ref = $dbh->selectrow_hashref("select fake from client");
};
$error = get_exception_report( $@ );
ok( $error =~ m/select fake from client/, "Check for statement" );
ok( $error =~ m/DBI::db::selectrow_hashref/, "Check for function defenition" );
ok( $error =~ m/params/, "Check that parameters are listed" );

dies_ok { 
    my $dbh = $one->dbh;
    my $sth = $dbh->prepare("SELECT fake from client where client_id = ?");
    $sth->execute(1);
};
$error = get_exception_report( $@ );
ok( $error =~ m/SELECT fake from client where client_id = \?/, "Check for statement" );
ok( $error =~ m/DBI::st::execute/, "Check for function defenition" );
ok( $error =~ m/params/, "Check that parameters are listed" );

dies_ok {
    $one->transaction_rollback;
    $tmp = eleMentalClinic::Client::Allergy->new({
        client_id   => 1001,
        allergy     => 'Plutonium;DROP DATABASE',
        created     => '2006-01-01',
        active      => 1,
        fake_field  => 'fake value',
    });
    $one->obj_insert( $tmp );
};
like $@, qr/Query outside of a transaction on 'main':/,
    'correct error from _enforce_transaction';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
