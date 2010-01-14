# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
# vim: ts=4 sts=4 sw=4
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 28;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use Encode;

our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::DB';
    use_ok( $CLASS );
}

#$eleMentalClinic::DB::TRACE_TRANSACTIONS = 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->insert_( 'eleMentalClinic::Client' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
# (Initializing through eleMentalClinic::Base to ensure that we get a DB connection.
#  No positive if this is necessary? )
    ok( $one = eleMentalClinic::Base->new->db );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# do_sql
    can_ok( $one, "do_sql");
    is_deeply($one->do_sql("select client_id from client"),
        [ { 'client_id' => '1001' },
          { 'client_id' => '1002' },
          { 'client_id' => '1003' },
          { 'client_id' => '1004' },
          { 'client_id' => '1005' },
          { 'client_id' => '1006' }, ]);        
    is( $one->do_sql("select client_id from client", 1), 6);
    is_deeply(
        $one->do_sql("select client_id from client where client_id = ?", 0, 1001),
        [ { 'client_id' => '1001' } ]);
    is( $one->do_sql("select client_id from client where client_id = ?", 1, 1001), 1);
    is_deeply(
        $one->do_sql("select client_id from client where client_id = ? or client_id = ?", 0, 1001, 1002),
        [ { 'client_id' => '1001' },
          { 'client_id' => '1002' }, ]);
    is( $one->do_sql("select client_id from client where client_id = ? or client_id = ?", 1, 1001, 1002), 2);
    
    # arrays
    my @bindings = (1001, 1002);
    is_deeply(
        $one->do_sql("select client_id from client where client_id = ? or client_id = ?", 0, @bindings),
        [ { 'client_id' => '1001' }, 
          { 'client_id' => '1002' } ], );
    is( $one->do_sql("select client_id from client where client_id = ? or client_id = ?", 1, @bindings), 2);

TODO: {
    local $TODO = "It would be nice if we could send array references as well...";
#    my $bindings_ref = [1001, 1002];
#    is_deeply(
#        $one->do_sql("select client_id from client where client_id = ? or client_id = ?", 0, $bindings_ref),
#        [ { 'client_id' => '1001' } ],
#        [ { 'client_id' => '1002' } ], );
#    is( $one->do_sql("select client_id from client where client_id = ? or client_id = ?", 1, $bindings_ref), 2);
}
    # This sort of situation requires eleMentalClinic::Util.dbquote
use eleMentalClinic::Util;
    my $limit = dbquote('1');
    is_deeply( $one->do_sql("select client_id from client limit $limit"),
        [ { 'client_id' => '1001' }, ]);

is_deeply(
    $one->select_one(
        [ 'client_id' ], 'client', [ 'client_id = ?', 1001 ], 'LIMIT 1'
    ),
    { client_id => 1001 },
);

is_deeply(
    $one->select_many(
        [ 'client_id' ], 'client', [ 'client_id = ?', 1001 ], 'LIMIT 1'
    ),
    [ { client_id => 1001 } ],
);
        
{
    my $str = decode("utf-8" => "I ♥ U");
    my $client = eleMentalClinic::Client->retrieve(1001);
    ok($client->update({ lname => $str }));
    $client = eleMentalClinic::Client->retrieve(1001);
    is(
        length($client->lname), 5, "length is calculated correctly",
    );
    is(
        $client->lname, $str,
        "roundtripped ok, got Perl native characters from DB layer",
    );
}

# transactions
$one->transaction_do(sub {
    $one->do_sql('delete from client where client_id = 1001', 1);
    is( $one->do_sql('select client_id from client', 1), '5',
        'client deleted in transaction');

    $one->transaction_do(sub {
        $one->do_sql('delete from client where client_id = 1002', 1);
        is( $one->do_sql('select client_id from client', 1), '4',
            'client deleted in sub-transaction');
        $one->transaction_do_rollback;
    });

    is( $one->do_sql('select client_id from client', 1), '5',
        'still 5 in outer transaction');

    $one->transaction_do(sub {
        $one->do_sql('delete from client where client_id = 1002', 1);
        is( $one->do_sql('select client_id from client', 1), '4',
            'client deleted in sub-transaction');
    });

    is( $one->do_sql('select client_id from client', 1), '4',
        'now 4 in outer transaction');

    $one->transaction_do_rollback;
});
is( $one->do_sql('select client_id from client', 1), 6,
    'clients not deleted outside of transaction' );

$one->transaction_do(sub {

    # make sure that a nested syntax error or invalid constraint has no effect
    $one->transaction_do_eval(sub {
        $one->do_sql('FNORD', 1);
    });
    isnt $@, "";

    $one->transaction_do_eval(sub {
        $one->do_sql('insert into client (select * from client)', 1);
    });
    isnt $@, "";

    $one->do_sql('delete from client', 1);
});
is( $one->do_sql('select client_id from client', 1), '0E0',
    'clients deleted after transaction');


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
