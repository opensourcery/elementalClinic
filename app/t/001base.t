# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 216;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::ProgressNote;
use eleMentalClinic::Personnel;
use eleMentalClinic::Client;
use Date::Calc qw/ Today /;

our ($CLASS, $DB_CLASS, $one, $tmp);
BEGIN {
    $CLASS = 'eleMentalClinic::Base';
    $DB_CLASS = 'eleMentalClinic::DB::Object';
    use_ok( $CLASS );
    use_ok( $DB_CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# accessor/mutator functionality
{
    package eleMentalClinic::BaseTest;
    our @ISA = $main::DB_CLASS;
    sub fields { [ qw/ foo / ] };
}

    $one = eleMentalClinic::BaseTest->new;
    isa_ok($one, 'eleMentalClinic::BaseTest');
    isa_ok( $one, $DB_CLASS );
    isa_ok( $one, $CLASS );
    can_ok($one, 'foo');
    is($one->foo, undef);
    is($one->foo('bar'), $one);
    is($one->foo, 'bar');
    is($one->foo(undef), $one);
    is($one->foo, undef);

        $one = $DB_CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, '' );
    is( $one->primary_key, '' );
    is_deeply( $one->fields, [ ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# qualified fields
    can_ok( $one, 'fields_qualified' );
    is( $DB_CLASS->fields_qualified, undef );
    is( $one->fields_qualified, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# config
    can_ok( $one, 'config' );
    ok( $one->config );
    isa_ok( $one->config, 'eleMentalClinic::Config' );

    is( $one->config, $one->config ); # same instance

        $one->config->config_path('etc/config.yaml');
        $one->config->stage1({ force_reload => 1 });
        $tmp = $one->config->theme;
    is( $one->config->theme, 'Default' );
    is( $one->config->theme, $tmp );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex failures
    throws_ok{ eleMentalClinic::Rolodex->retrieve( 1001 )->rolodex }
        qr/Cannot find a Rolodex relationship field/;
    throws_ok{ eleMentalClinic::ValidData->rolodex }
        qr/This object is not persistent/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex successes
    # contacts
    is_rolodex( eleMentalClinic::Client::Contact->retrieve( 1001 )->rolodex, 1001 );
    is_rolodex( eleMentalClinic::Client::Contact->retrieve( 1002 )->rolodex, 1002 );
    is_rolodex( eleMentalClinic::Client::Contact->retrieve( 1003 )->rolodex, 1010 );

    # employment
    is_rolodex( eleMentalClinic::Client::Employment->retrieve( 1001 )->rolodex, 1003 );

    # insurance
    is_rolodex( eleMentalClinic::Client::Insurance->retrieve( 1001 )->rolodex, 1008 );
    is_rolodex( eleMentalClinic::Client::Insurance->retrieve( 1002 )->rolodex, 1008 );
    is_rolodex( eleMentalClinic::Client::Insurance->retrieve( 1003 )->rolodex, 1015 );
    is_rolodex( eleMentalClinic::Client::Insurance->retrieve( 1004 )->rolodex, 1014 );
    is_rolodex( eleMentalClinic::Client::Insurance->retrieve( 1005 )->rolodex, 1013 );
    is_rolodex( eleMentalClinic::Client::Insurance->retrieve( 1006 )->rolodex, 1009 );
    is_rolodex( eleMentalClinic::Client::Insurance->retrieve( 1008 )->rolodex, 1016 );
    is_rolodex( eleMentalClinic::Client::Insurance->retrieve( 1009 )->rolodex, 1007 );
    is_rolodex( eleMentalClinic::Client::Insurance->retrieve( 1012 )->rolodex, 1013 );
    is_rolodex( eleMentalClinic::Client::Insurance->retrieve( 1013 )->rolodex, 1013 );

    # medication
    is_rolodex( eleMentalClinic::Client::Medication->retrieve( 1001 )->rolodex, 1011 );
    is_rolodex( eleMentalClinic::Client::Medication->retrieve( 1002 )->rolodex, 1011 );

    # referral
    is_rolodex( eleMentalClinic::Client::Referral->retrieve( 1001 )->rolodex, 1010 );
    is_rolodex( eleMentalClinic::Client::Referral->retrieve( 1002 )->rolodex, 1012 );

    # treater
    is_rolodex( eleMentalClinic::Client::Treater->retrieve( 1001 )->rolodex, 1011 );

    # release
    is_rolodex( eleMentalClinic::Client::Release->retrieve( 1001 )->rolodex, 1009 );
    is_rolodex( eleMentalClinic::Client::Release->retrieve( 1002 )->rolodex, 1009 );
    is_rolodex( eleMentalClinic::Client::Release->retrieve( 1003 )->rolodex, 1008 );
    is_rolodex( eleMentalClinic::Client::Release->retrieve( 1004 )->rolodex, 1008 );
    is_rolodex( eleMentalClinic::Client::Release->retrieve( 1005 )->rolodex, 1008 );

    # personnel
    is( eleMentalClinic::Personnel->retrieve( 1001 )->rolodex, undef );
    is_rolodex( eleMentalClinic::Personnel->retrieve( 1002 )->rolodex, 1011 );

    # billing file
    is( eleMentalClinic::Financial::BillingFile->empty->rolodex, undef );
    is_rolodex( eleMentalClinic::Financial::BillingFile->empty({ rolodex_id => 1001 })->rolodex, 1001 );

    # billing payment
    is( eleMentalClinic::Financial::BillingPayment->empty->rolodex, undef );
    is_rolodex( eleMentalClinic::Financial::BillingPayment->empty({ rolodex_id => 1001 })->rolodex, 1001 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
    can_ok( $one, 'get_all' );
    is( $one->get_all, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get by, generic
    can_ok( $one, 'get_by_' );
    throws_ok{ eleMentalClinic::Client::Allergy->get_by_ } qr/required/;
    throws_ok{ eleMentalClinic::Client::Allergy->get_by_( 'client_id' )} qr/required/;
    throws_ok{ eleMentalClinic::Client::Allergy->get_by_( 'client id', 666 )} qr/Invalid/;
    throws_ok{ eleMentalClinic::Client::Allergy->get_by_( 'client_id', 666, 'client id' )} qr/Invalid/;

    is_deeply( eleMentalClinic::Client::Allergy->get_by_( 'client_id', 1002 ), [
        $client_allergy->{ 1003 },
    ]);
    is_deeply( eleMentalClinic::Client::Allergy->get_by_( 'client_id', 1001 ), [
        $client_allergy->{ 1001 },
        $client_allergy->{ 1002 },
    ]);
    is_deeply( eleMentalClinic::Client::Allergy->get_by_( 'client_id', 1001 ), [
        $client_allergy->{ 1001 },
        $client_allergy->{ 1002 },
    ]);
    is_deeply( eleMentalClinic::Client::Allergy->get_by_( 'client_id', 1001, 'created' ), [
        $client_allergy->{ 1002 },
        $client_allergy->{ 1001 },
    ]);

    # direction
    is_deeply( eleMentalClinic::Client::Allergy->get_by_( 'client_id', 1001, 'created', 'ASC' ), [
        $client_allergy->{ 1002 },
        $client_allergy->{ 1001 },
    ]);
    is_deeply( eleMentalClinic::Client::Allergy->get_by_( 'client_id', 1001, 'created', 'DESC' ), [
        $client_allergy->{ 1001 },
        $client_allergy->{ 1002 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get one by, generic
    can_ok( $one, 'get_one_by_' );
    is_deeply( eleMentalClinic::Client::Allergy->get_one_by_( 'client_id', 1002 ), $client_allergy->{ 1003 });
    is_deeply( eleMentalClinic::Client::Allergy->get_one_by_( 'client_id', 1001 ), $client_allergy->{ 1001 });
    is_deeply( eleMentalClinic::Client::Allergy->get_one_by_( 'client_id', 1001 ), $client_allergy->{ 1001 });
    is_deeply( eleMentalClinic::Client::Allergy->get_one_by_( 'client_id', 1001, 'created' ), $client_allergy->{ 1002 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# today
    can_ok( $CLASS, 'today' );
    ok( $CLASS->today, $CLASS->today );
    is( $CLASS->today, sprintf( "%4d-%02d-%02d", Today ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# deprecated in favor of $CLASS->today
    throws_ok{ $CLASS->today_ymd } qr/Can't locate object method/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# date_range_sql
    can_ok( $one, 'date_range_sql' );
    is( $one->date_range_sql, undef );
    is( $one->date_range_sql( 'start_date' ), undef );
    is( $one->date_range_sql( 'start_date', 'end_date' ), '' );

    is( $one->date_range_sql( 'start_date', 'end_date', '2006-03-01' ),
        " CAST (start_date AS date) = CAST ('2006-03-01' AS date)" );
    is( $one->date_range_sql( 'start_date', 'end_date', undef, '2006-09-05' ),
        " CAST (end_date AS date) = CAST ('2006-09-05' AS date)" );

    is( $one->date_range_sql( 'start_date', 'end_date', '2006-03-01', '2006-03-01' ),
        qq/ ( CAST (start_date AS date) = CAST ('2006-03-01' AS date) OR CAST (end_date AS date) = CAST ('2006-03-01' AS date) )/ );
    is( $one->date_range_sql( 'start_date', 'end_date', '2006-03-01', '2006-09-05' ),
        qq/ ( CAST (start_date AS date) >= CAST ('2006-03-01' AS date) ) AND ( CAST (end_date AS date) <= CAST ('2006-09-05' AS date) )/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# role
    can_ok( $one, 'role' );
    is( $one->role, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# eman
    can_ok( $one, 'eman' );
    is( $one->eman, undef );

    is( $one->eman( 'Dan' ), 'Dan' );
    is( $one->eman( undef, 'Balmer' ), 'Balmer' );
    is( $one->eman( undef, undef, 'J' ), undef );
    is( $one->eman( 'Dan', 'Balmer' ), 'Balmer, Dan' );
    is( $one->eman( 'Dan', undef, 'J' ), 'Dan J' );
    is( $one->eman( undef, 'Balmer', 'J' ), 'Balmer, J' );
    is( $one->eman( 'Dan', 'Balmer', 'J' ), 'Balmer, Dan J' );

    is( $one->eman( undef, undef, undef, 'Jr.' ), undef );
    is( $one->eman( 'Dan', undef, undef, 'Jr.' ), 'Dan Jr.' );
    is( $one->eman( 'Dan', 'Balmer', undef, 'Jr.' ), 'Balmer Jr., Dan' );
    is( $one->eman( 'Dan', undef, 'J', 'Jr.' ), 'Dan J Jr.' );
    is( $one->eman( 'Dan', 'Balmer', 'J', 'Jr.' ), 'Balmer Jr., Dan J' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make lookup hash
    can_ok( $one, qw/ make_lookup_hash / );
    throws_ok{ $one->make_lookup_hash( 1, 2, 3 )}
        qr/Arrayref is required by Base::make_lookup_hash./;
    throws_ok{ $one->make_lookup_hash({ 1 => 2 })}
        qr/Arrayref is required by Base::make_lookup_hash./;

    is( $one->make_lookup_hash, undef );
    is_deeply( $one->make_lookup_hash([ 'foo' ]), {
        'foo' => 1,
    });
    is_deeply( $one->make_lookup_hash([ 101, 102, 103 ]), {
        101   => 1,
        102   => 1,
        103   => 1,
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# unique
    can_ok( $one, qw/ unique /);
    is( $one->unique, undef );
    is( $one->unique( undef ), undef );
    is( $one->unique( undef, undef, undef ), undef );

    is( $one->unique( [] ), undef );
    is( $one->unique( [], [], [] ), undef );

    is_deeply([ $one->unique( 0 )], [ 0 ]);
    is_deeply([ $one->unique( 0, 0, 0 )], [ 0 ]);

    is_deeply([ $one->unique( 0, 1, 2 )], [ 0, 1, 2 ]);
    is_deeply([ $one->unique( 1, 2, 3 )], [ 1, 2, 3 ]);
    is_deeply([ $one->unique( 1, 2, 3 )], [ 1, 2, 3 ]);
    is_deeply([ $one->unique( 1, 2, 1, 0, 1, 2, 0 )], [ 1, 2, 0 ]);

    is_deeply([ $one->unique( [0] )], [ 0 ]);
    is_deeply([ $one->unique( [0], [0], [0] )], [ 0 ]);

    is_deeply([ $one->unique( [0], [1], [2] )], [ 0, 1, 2 ]);
    is_deeply([ $one->unique( [1], [2], [3] )], [ 1, 2, 3 ]);
    is_deeply([ $one->unique( [1], [2], [3] )], [ 1, 2, 3 ]);
    is_deeply([ $one->unique( [1], [2], [1], 0, 1, 2, 0 )], [ 1, 2, 0 ]);

    is_deeply([ $one->unique( [0,1,2,3], [1,2,3,4], [2,3,4,0] )], [ 0, 1, 2, 3, 4 ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid date
    can_ok( $one, 'valid_date' );
    is( $one->valid_date, undef );
    is( $one->valid_date( 666 ), undef );
    is( $one->valid_date( '66-66-66' ), undef );
    is( $one->valid_date( '2006-06-31' ), undef );
    is( $one->valid_date( '2006-06-30' ), 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# retrieve
    can_ok( $DB_CLASS, 'retrieve' );
    can_ok( 'eleMentalClinic::ProgressNote', 'retrieve' );
    is_deeply( eleMentalClinic::ProgressNote->new({ rec_id => 1001 })->retrieve, $prognote->{ 1001 });
    is_deeply( eleMentalClinic::ProgressNote->new->id( 1001 )->retrieve, $prognote->{ 1001 });

    is_deeply( eleMentalClinic::Client->new->id( 1001 )->retrieve, $client->{ 1001 });
    is_deeply( eleMentalClinic::Client->new->id( 1002 )->retrieve, $client->{ 1002 });
    is_deeply( eleMentalClinic::Client->new->id( 1003 )->retrieve, $client->{ 1003 });

    # is the object retrieved and set?
        $one = eleMentalClinic::ProgressNote->new;
        $one->id( 1001 );
        $one->retrieve;
    is_deeply( $one, $prognote->{ 1001 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# new retrieve
    throws_ok{ eleMentalClinic::ProgressNote->retrieve }
        qr/ID is required if calling retrieve as a class method/;

    is_deeply( eleMentalClinic::ProgressNote->retrieve( 1001 ), $prognote->{ 1001 });
    isa_ok( eleMentalClinic::ProgressNote->retrieve( 1001 ), 'eleMentalClinic::ProgressNote' );

    isa_ok( eleMentalClinic::Client->retrieve( 1001 ), 'eleMentalClinic::Client' );
    isa_ok( eleMentalClinic::Client->retrieve( 1002 ), 'eleMentalClinic::Client' );
    isa_ok( eleMentalClinic::Client->retrieve( 1003 ), 'eleMentalClinic::Client' );

    ok( eleMentalClinic::ProgressNote->retrieve( 0 ));
    isa_ok( eleMentalClinic::ProgressNote->retrieve( 666 ), 'eleMentalClinic::ProgressNote' );
    isa_ok( eleMentalClinic::ProgressNote->retrieve( 1001 ), 'eleMentalClinic::ProgressNote' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# update
    can_ok( $one, 'update' );
    is( $one->update, undef );

        $tmp = eleMentalClinic::ProgressNote->retrieve( 1001 );
    is_deeply( $tmp, $prognote->{ 1001 });

    # no update
    is( $tmp->update, undef );
    is_deeply( $tmp, $prognote->{ 1001 });

    # nonexistent field
    is( $tmp->update({ foobar => 666 }), undef );
    is_deeply( $tmp, $prognote->{ 1001 });

    # one good field updated
    ok( $tmp->update({ note_header => 'Use yer noggin!' }));
    is_deeply_except( { modified => undef }, [ $tmp ], [{
        %{ $prognote->{ 1001 }},
        note_header => 'Use yer noggin!',
    }]);

    # two fields
    ok( $tmp->update({ note_header => 'Use your head!', note_body => 'Ouch' }));
    is_deeply_except( { modified => undef }, [ $tmp ], [{
        %{ $prognote->{ 1001 }},
        note_header => 'Use your head!',
        note_body   => 'Ouch',
    }]);

    # undef both fields
    ok( $tmp->update({ note_header => undef, note_body => undef }));
    is_deeply_except( { modified => undef }, [ $tmp ], [{
        %{ $prognote->{ 1001 }},
        note_header => undef,
        note_body   => undef,
    }]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test that we can now require fields in an object's init() method
# redefine prognote's init method
    no warnings qw/ redefine /;
    *eleMentalClinic::ProgressNote::init = sub {
        my $self = shift;
        my( $args ) = @_;
        die 'goal_id required', caller
            unless defined $args->{ goal_id };

        return 1;
    };

    # calling with original method syntax, just to watch it die
    throws_ok{ eleMentalClinic::ProgressNote->new({ rec_id => 1001 })->retrieve }
        qr/goal_id required/;
    throws_ok{ eleMentalClinic::ProgressNote->new->id( 1001 )->retrieve }
        qr/goal_id required/;

    # new syntax should work fine
    ok( eleMentalClinic::ProgressNote->retrieve( 1001 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# try with personnel, different primary key may cause trouble

    can_ok( 'eleMentalClinic::Personnel', 'retrieve' );

        my %security = (
                active              => 1,
                admin               => 0,
                service_coordinator => 1,
                writer              => 1,
                financial           => 0,
                supervisor          => 0,
                scanner             => 0,
                reports             => 0,
            );

    sub test_security {
        my ( $p ) = @_;
        my $out = 1;
        for my $sec ( keys %security ) {
            $out &&= $security{ $sec } ? $p->$sec()
                                       : ! $p->$sec()
        }
        ok( $out, "All security fields are correct" );
    }

    test_security( eleMentalClinic::Personnel->new({ staff_id => 1001 })->retrieve );
    test_security( eleMentalClinic::Personnel->new->id( 1001 )->retrieve );
    test_security( eleMentalClinic::Personnel->retrieve( 1001 ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# empty
    package EmptyTest;
    use strict;
    use warnings;

    use base qw/ eleMentalClinic::DB::Object /;
    sub fields {[ qw/ fiery the angels rose /]}
    sub fields_required {[ qw/ fiery angels /]}

package main;
    *CLASS = \'EmptyTest';

    is_deeply( $CLASS->fields, [ qw/ fiery the angels rose /]);
    is_deeply( $CLASS->fields_required, [ qw/ fiery angels /]);

    # failuers due to missing arguments
    throws_ok{ EmptyTest->new }
        qr/Missing required field/;
    throws_ok{ $CLASS->new({
        fiery   => undef,
        angels  => undef,
    })}
        qr/Missing required field/;

    # success
    ok( $one = $CLASS->new({
        fiery   => 0,
        angels  => 0,
    }));
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

    # empty
    ok( $one = $CLASS->empty );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# update takes an undef and turns it into a null

dbinit(1);

    $one = eleMentalClinic::Client->retrieve(1001);
    $one->intake_step(3);
    $one->save;

    $one->update( { intake_step => undef } );

    is($one->intake_step, undef);

dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
