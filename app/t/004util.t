# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 134;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::DB;
use eleMentalClinic::Client::Allergy;

our ($CLASS, $one, $tmp, $a, $b, $c, $crackme);
BEGIN {
    *CLASS = \'eleMentalClinic::Util';
    use_ok( $CLASS );
}
use eleMentalClinic::Util qw/ _quote /;

sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub initvars { # for the dbquote tests
    ( $a, $b, $c ) = ( 666, 'foo', "select crackme; drop table; 'quoted'" );
    $crackme = '1; DELETE FROM client_allergy';
}
initvars();

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# date_month_name
    is( date_month_name, undef );
    throws_ok{ date_month_name( 666 )} qr/Date must be in ISO format./;
    throws_ok{ date_month_name( '2000-01' )} qr/Date must be in ISO format./;
    throws_ok{ date_month_name( '2000-13-01' )} qr/Date must be in ISO format./;
    is( date_month_name( '2000-01-01' ), 'January' );
    is( date_month_name( '2000-12-01' ), 'December' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# date_year
    is( date_year, undef );
    throws_ok{ date_year( 666 )} qr/Date must be in ISO format./;
    throws_ok{ date_year( '2000-01' )} qr/Date must be in ISO format./;
    throws_ok{ date_year( '2000-13-01' )} qr/Date must be in ISO format./;
    is( date_year( '2000-01-01' ), 2000 );
    is( date_year( '1901-12-01' ), 1901 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# _check_date
    is( _check_date(), undef );
    throws_ok{ _check_date( 666 )}
        qr/Date must be in ISO format./;
    throws_ok{ _check_date( '1-1' )}
        qr/Date must be in ISO format./;
    throws_ok{ _check_date( '2006-13-01' )}
        qr/Date must be in ISO format./;
    throws_ok{ _check_date( '2006-01-35' )}
        qr/Date must be in ISO format./;
    throws_ok{ _check_date( '2006-02-31' )}
        qr/Date must be in ISO format./;
    throws_ok{ _check_date( '2006-02-01 12:13:14' )}
        qr/Date must be in ISO format./;
    is( _check_date( '2006-01-01' ), '2006-01-01' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# date formatting
    throws_ok{ format_date()}
        qr/Date is required./;

    is( format_date( '2006-01-01' ), '1/1/2006' );
    is( format_date( '2006-02-01' ), '2/1/2006' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# date formatting
    throws_ok{ format_date_time()}
        qr/Timestamp is required./;
    throws_ok{ format_date_time( '2006-02-01' )}
        qr/Timestamp must be in YYYY-MM-DD hh:mm:ss format./;

    is( format_date_time( '2006-02-01 12:13:14' ), '2/1/2006 @ 12:13' );
    is( format_date_time( '2006-02-01 00:00:00' ), '2/1/2006 @ 00:00' );
    is( format_date_time( '2006-02-01 00:13:14' ), '2/1/2006 @ 00:13' );
    is( format_date_time( '2006-02-01 12:00:14' ), '2/1/2006 @ 12:00' );
    is( format_date_time( '2006-02-01 12:13:00' ), '2/1/2006 @ 12:13' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# format_date_remove_time
    throws_ok{ format_date_remove_time() }
        qr/Timestamp is required/;
    throws_ok{ format_date_remove_time( '2006-02-01' )}
        qr/Timestamp must be in YYYY-MM-DD hh:mm:ss format./;
    is( format_date_remove_time( '2006-02-01 12:13:14' ), '2/1/2006' );
    is( format_date_remove_time( '2006-12-12 00:00:00' ), '12/12/2006' );
    is( format_date_remove_time( '1995-05-10 00:13:14' ), '5/10/1995' );
    is( format_date_remove_time( '2006-11-01 12:00:14' ), '11/1/2006' );
    is( format_date_remove_time( '2009-03-31 12:13:00' ), '3/31/2009' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# date calculating
    # check date API
    throws_ok{ date_calc()}
        qr/Date is required./;
    throws_ok{ date_calc( 666 )}
        qr/Date must be in ISO format./;
    throws_ok{ date_calc( '1-1' )}
        qr/Date must be in ISO format./;
    throws_ok{ date_calc( '2006-13-01' )}
        qr/Date must be in ISO format./;
    throws_ok{ date_calc( '2006-01-35' )}
        qr/Date must be in ISO format./;
    throws_ok{ date_calc( '2006-02-31' )}
        qr/Date must be in ISO format./;

    is( date_calc( '2006-01-01' ), '2006-01-01' );
    is( date_calc( '2006-11-01' ), '2006-11-01' );
    is( date_calc( '2006-01-13' ), '2006-01-13' );

    # check delta API
    throws_ok{ date_calc( '2006-12-31', '(1m' )} qr/Invalid sign:.*  See POD/;
    throws_ok{ date_calc( '2006-12-31', '_1m' )} qr/Invalid sign:.*  See POD/;
    throws_ok{ date_calc( '2006-12-31', '=1m' )} qr/Invalid sign:.*  See POD/;

    throws_ok{ date_calc( '2006-12-31', 0 )}  qr/Missing or invalid unit:.*  See POD/;
    throws_ok{ date_calc( '2006-12-31', 1 )}  qr/Missing or invalid unit:.*  See POD/;
    throws_ok{ date_calc( '2006-12-31', '+1' )}  qr/Missing or invalid unit:.*  See POD/;
    throws_ok{ date_calc( '2006-12-31', '-1' )} qr/Missing or invalid unit:.*  See POD/;

    throws_ok{ date_calc( '2006-12-31', '1M' )} qr/Missing or invalid unit:.*  See POD/;
    throws_ok{ date_calc( '2006-12-31', '1Y' )} qr/Missing or invalid unit:.*  See POD/;
    throws_ok{ date_calc( '2006-12-31', '1D' )} qr/Missing or invalid unit:.*  See POD/;
    throws_ok{ date_calc( '2006-12-31', '1n' )} qr/Missing or invalid unit:.*  See POD/;
    throws_ok{ date_calc( '2006-12-31', '1x' )} qr/Missing or invalid unit:.*  See POD/;

    # zeros are ok

    is( date_calc( '2006-12-31', '0y' ), '2006-12-31' );
    is( date_calc( '2006-12-31', '0m' ), '2006-12-31' );
    is( date_calc( '2006-12-31', '0d' ), '2006-12-31' );

    is( date_calc( '2006-12-31', '+0y' ), '2006-12-31' );
    is( date_calc( '2006-12-31', '+0m' ), '2006-12-31' );
    is( date_calc( '2006-12-31', '+0d' ), '2006-12-31' );

    is( date_calc( '2006-12-31', '-0y' ), '2006-12-31' );
    is( date_calc( '2006-12-31', '-0m' ), '2006-12-31' );
    is( date_calc( '2006-12-31', '-0d' ), '2006-12-31' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    is( date_calc( '2006-12-31', '1y' ), '2007-12-31' );
    is( date_calc( '2006-12-31', '1m' ), '2007-01-31' );
    is( date_calc( '2006-12-31', '1d' ), '2007-01-01' );

    is( date_calc( '2006-12-31', '+1y' ), '2007-12-31' );
    is( date_calc( '2006-12-31', '+1m' ), '2007-01-31' );
    is( date_calc( '2006-12-31', '+1d' ), '2007-01-01' );

    is( date_calc( '2006-12-31', '-1y' ), '2005-12-31' );
    is( date_calc( '2006-12-31', '-1d' ), '2006-12-30' );
    is( date_calc( '2006-12-30', '-1m' ), '2006-11-30' );

    # edge cases for which we use different logic
    is( date_calc( '2006-12-31', '-1m' ), '2006-11-30' );
    is( date_calc( '2006-03-31', '-1m' ), '2006-02-28' );

    is( date_calc( '2006-12-31', '+2m' ), '2007-02-28' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dbquote fails if DB is not initialized
    # At some point personnel is pulled in, its compiilation requires DB init,
    # as such we now need to undef the DBH unlike before.
    $eleMentalClinic::DB::one_true_DBH = undef;

    throws_ok{ _quote()}
        qr/eleMentalClinic::DB must be initialized./;
    throws_ok{ _quote( 'foo' )}
        qr/eleMentalClinic::DB must be initialized./;

    throws_ok{ dbquote()}
        qr/eleMentalClinic::DB must be initialized./;
    throws_ok{ dbquote( 'foo' )}
        qr/eleMentalClinic::DB must be initialized./;
    throws_ok{ dbquote( qw/ foo bar baz /)}
        qr/eleMentalClinic::DB must be initialized./;

    # same failures for dbquoteme
    throws_ok{ dbquoteme()}
        qr/eleMentalClinic::DB must be initialized./;
    throws_ok{ dbquoteme( 'foo' )}
        qr/eleMentalClinic::DB must be initialized./;
    throws_ok{ dbquoteme( qw/ foo bar baz /)}
        qr/eleMentalClinic::DB must be initialized./;

        dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# _quote
    throws_ok{ _quote( 'foo', 'bar' )}
        qr/It is an error to use _quote\(\) without checking its return value.  See the POD./;
    throws_ok{ $tmp = _quote( 'foo', 'bar' )}
        qr/\$data_type as a second parameter is not yet supported/;

    throws_ok{ $tmp = _quote( \'foo' )}
        qr/The value passed to _quote\(\) must a scalar.  See the POD./;
    throws_ok{ $tmp = _quote( \$a )}
        qr/The value passed to _quote\(\) must a scalar.  See the POD./;

    is( _quote(), undef );
    is( _quote( undef ), undef );
    is( _quote( 6 ), "'6'" );
    is( _quote( 'foo' ), "'foo'" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dbquote success after DB init
    # in scalar context, returns first element
        $tmp = dbquote();
    is( $tmp, undef );

        $tmp = dbquote( 5 );
    is( $tmp, "'5'" );

        $tmp = dbquote( 7, 8, 9 );
    is( $tmp, "'7'" );

    # in list context, returns list
    is( dbquote(), undef );
    is_deeply( [ dbquote( 1 )], [ "'1'" ]);
    is_deeply( [ dbquote( 666 )], [ "'666'" ]);
    is_deeply( [ dbquote( 1, 2, 3 )], [ "'1'", "'2'", "'3'" ]);
    is_deeply( [ dbquote( 1, undef, 3 )], [ "'1'", undef, "'3'" ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# catch misuse when we really mean dbquoteme()
    throws_ok{ dbquote( 5 )}
        qr/It is an error to use dbquote\(\) without checking its return value.  See the POD./;
    throws_ok{ dbquote( 5, 6, 7 )}
        qr/It is an error to use dbquote\(\) without checking its return value.  See the POD./;
    throws_ok{ $tmp = dbquote( \$crackme )}
        qr/Values passed to dbquote\(\) must be scalars./;
    throws_ok{ $tmp = dbquote( \$a, \$b, \$c )}
        qr/Values passed to dbquote\(\) must be scalars./;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# must pass references
    throws_ok{ dbquoteme( 'foo' )}
        qr/Each value passed to dbquoteme\(\) must be a REFERENCE to a scalar/;
    throws_ok{ dbquoteme( $a )}
        qr/Each value passed to dbquoteme\(\) must be a REFERENCE to a scalar/;
    throws_ok{ dbquoteme( 'foo', 'bar' )}
        qr/Each value passed to dbquoteme\(\) must be a REFERENCE to a scalar/;
    throws_ok{ dbquoteme([ 'foo', 'bar' ])}
        qr/Each value passed to dbquoteme\(\) must be a REFERENCE to a scalar/;
    throws_ok{ dbquoteme( \$a, \$b, $c )}
        qr/Each value passed to dbquoteme\(\) must be a REFERENCE to a scalar/;

    # cannot pass reference to lvalue
    throws_ok{ dbquoteme( \'foo' )}
        qr/Modification of a read-only value attempted at /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# successes
    ok( dbquoteme( undef, undef ));

        initvars();
    ok( dbquoteme( \$a ));
    is( $a, "'666'" );

        initvars();
    ok( dbquoteme( \$a, \$b, \$c ));
    is( $a, "'666'" );
    is( $b, "'foo'" );
    is( $c, "'select crackme; drop table; ''quoted'''" );

        initvars();
        undef $b;
    ok( dbquoteme( \$a, \$b, \$c ));
    is( $a, "'666'" );
    is( $b, undef );
    is( $c, "'select crackme; drop table; ''quoted'''" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# real life test
    is( $test->select_count( 'client_allergy' ), keys %$client_allergy );
    ok( $test->select_count( 'client_allergy' ) > 4 ); # make sure it's not zero already

    # this nukes the table
        initvars();
        $test->db->transaction_do(sub {
            throws_ok{ eleMentalClinic::Client::Allergy->new->db->select_many(
                    eleMentalClinic::Client::Allergy->fields,
                    eleMentalClinic::Client::Allergy->table,
                    '',
                    "LIMIT $crackme"
                )}
                qr/cannot insert multiple commands into a prepared statement/;
                $test->db->transaction_do_rollback;
        });

    # using dbquote prevents problem
        dbinit( 1 );
        initvars();
        $crackme = dbquote( $crackme );
    $test->db->transaction_do(sub {
    dies_ok{ eleMentalClinic::Client::Allergy->new->db->select_many(
            eleMentalClinic::Client::Allergy->fields,
            eleMentalClinic::Client::Allergy->table,
            '',
            "LIMIT $crackme"
        )};

        like( $@, qr/ERROR:  invalid input syntax for integer/ );
        $test->db->transaction_do_rollback;
    });

    is( $test->select_count( 'client_allergy' ), 5 );

    # using dbquoteme prevents problem
        dbinit( 1 );
        initvars();
        dbquoteme( \$crackme );
    $test->db->transaction_do(sub {
    dies_ok{ eleMentalClinic::Client::Allergy->new->db->select_many(
            eleMentalClinic::Client::Allergy->fields,
            eleMentalClinic::Client::Allergy->table,
            '',
            "LIMIT $crackme"
        )};
        like( $@, qr/ERROR:  invalid input syntax for integer/);
        $test->db->transaction_do_rollback;
    });
    is( $test->select_count( 'client_allergy' ), 5 );

    dbinit();
