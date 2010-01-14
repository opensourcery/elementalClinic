#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 191;
use Test::Exception;
use Data::Dumper;

our ($CLASS, $CLEAR_CLASS, $one, $tmp);
*CLASS = \'eleMentalClinic::Role::Cache';
*CLEAR_CLASS = \'eleMentalClinic::Role::Cache::_Clear';

use_ok( $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# eleMentalClinic::Role::Cache::_Clear

    my $cleared = 'not cleared';
    my $sub = sub {
        my $x = $CLEAR_CLASS->new( sub { $cleared = 'cleared' } );
        return $cleared; 
    };
    is( $cleared, 'not cleared', "not cleared yet" );
    is( $sub->(), 'not cleared' , "Object still existed, not cleared before return." );
    is( $cleared, 'cleared', "Object destroyed, cleared after return" );

    $cleared = 'not cleared';
    $sub = sub {
        my $x = $CLEAR_CLASS->new( sub { $cleared = 'cleared' } );
        die( 'Ooops' );
    };
    is( $cleared, 'not cleared', "not cleared yet" );
    dies_ok { $sub->() } 'destruction caused by death';
    is( $cleared, 'cleared', "Object destroyed, set after death" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Class Data

    is( $CLASS->DATA, \%eleMentalClinic::Role::Cache::DATA, "DATA returns reference to DATA variable" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Class Methods

    dies_ok { $one = $CLASS->new() } "Must provide params";
    like( $@, qr/Must provide both a role id and a method name/, "Correct Message" );

    dies_ok { $one = $CLASS->new( 1 ) } "Must provide params";
    like( $@, qr/Must provide both a role id and a method name/, "Correct Message" );

    lives_ok { $one = $CLASS->new( 1, 1 ) } "works with params";

    ok( $one = $CLASS->new( 1, 'a' ), "Construction" );
    isa_ok( $one, $CLASS );

    $eleMentalClinic::Role::Cache::DATA{ 'a' } = 1;
    $tmp = $CLASS->clear;
    is_deeply(
        $CLASS->DATA,
        { 'a' => 1 },
        "Data not cleared yet."
    );
    undef( $tmp );
    is_deeply(
        $CLASS->DATA,
        {  },
        "Data cleared now."
    );


    $eleMentalClinic::Role::Cache::DATA{ 'a' } = 1;
    $CLASS->clear;
    is_deeply(
        $CLASS->DATA,
        {},
        "Data cleared immedietly."
    );

    is( $one->data, $CLASS->DATA, "Cleared, not replaced" );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Object Methods

    $one = $CLASS->new( 1, 'a' );
    is( $one->role_id, 1, "Got role id" );
    is( $one->method, 'a', "Got method name" );
    is( $one->data, $CLASS->DATA, "Got Data" );

    is( $one->role_data, $CLASS->DATA->{ 1 }, "role_data() gets from data" );
    is_deeply( $one->role_data, {  }, "role_data() inits a hashref" );
    $tmp = $one->role_data;
    is( $tmp, $one->role_data, "Not reset each time" );

    is( $one->method_data, $CLASS->DATA->{ 1 }->{ a }, "method_data() gets from data" );
    is_deeply( $one->method_data, {  }, "method_data() inits a hashref" );
    $tmp = $one->method_data;
    is( $tmp, $one->method_data, "Not reset each time" );

    ok( ! $one->has_result, "No result yet" );
    is_deeply( [ $one->get_result ], [], "Nothing (not even undef) from get_result" );
    ok( $one->set_result( 'a' ), "Set the result" );
    ok( $one->has_result, "result now" );
    is( $one->get_result, 'a', "get_result" );
    is( $one->has_result, 'scalar', "correct result type" );
    ok( $one->clear_result, "Clear the result" );
    ok( ! $one->has_result, "No result now" );

    ok( $one->set_result(), "Set the result to nothing" );
    ok( $one->has_result, "result now" );
    is_deeply( [ $one->get_result ], [], "Nothing (not even undef) from get_result" );
    is( $one->has_result, 'empty', 'correct result now' );
    ok( $one->clear_result, "Clear the result" );
    ok( ! $one->has_result, "No result now" );

    ok( $one->set_result( undef ), "Set the result to undef" );
    ok( $one->has_result, "result now" );
    is_deeply( [ $one->get_result ], [ undef ], "got undef from get_result" );
    is( $one->has_result, 'scalar', 'correct result now' );
    ok( $one->clear_result, "Clear the result" );
    ok( ! $one->has_result, "No result now" );

    ok( $one->set_result( undef, undef ), "Set the result to undef" );
    ok( $one->has_result, "result now" );
    is_deeply( [ $one->get_result ], [ undef, undef ], "got array w/ 2 undefs from get_result" );
    is( $one->has_result, 'array', 'correct result now' );
    ok( $one->clear_result, "Clear the result" );
    ok( ! $one->has_result, "No result now" );

    ok( $one->set_result( 'a', undef ), "Set the result to undef" );
    ok( $one->has_result, "result now" );
    is_deeply( [ $one->get_result ], [ 'a', undef ], "got array from get_result" );
    is( $one->has_result, 'array', 'correct result now' );
    ok( $one->clear_result, "Clear the result" );
    ok( ! $one->has_result, "No result now" );

    ok( $one->set_result( 'a' .. 'z' ), "Set the result to undef" );
    ok( $one->has_result, "result now" );
    is_deeply( [ $one->get_result ], [ 'a' .. 'z' ], "got array from get_result" );
    is( $one->has_result, 'array', 'correct result now' );
    ok( $one->clear_result, "Clear the result" );
    ok( ! $one->has_result, "No result now" );

    ok( $one->set_result( undef, 'a' .. 'z' ), "Set the result to undef" );
    ok( $one->has_result, "result now" );
    is_deeply( [ $one->get_result ], [ undef, 'a' .. 'z' ], "got array from get_result" );
    is( $one->has_result, 'array', 'correct result now' );
    ok( $one->clear_result, "Clear the result" );
    ok( ! $one->has_result, "No result now" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Helper Functions

    {
        no strict 'refs';
        no warnings 'redefine';

        for my $package ( qw/ Test::Package eleMentalClinic::Role / ) {
            undef( *{ $package . '::' . $_ }) for grep { $package->can( $_ )} keys %{ $package . '::' };
            *{ $package . '::new' } = sub { bless( { rec_id => $_[1]}, $_[0] )};
            *{ $package . '::id' } = sub { shift->{ rec_id }};
            *{ $package . '::array' } = sub { return ('a' .. 'z') };
            *{ $package . '::undef' } = sub { return undef };
            *{ $package . '::nada' } = sub { return };

            for my $sub ( 'a' .. 'z' ) {
                *{$package . '::' . $sub} = sub { $sub };
            }
            can_ok( $package, 'new', 'a' .. 'z' );
        }
    }

    my $original = Test::Package->can( 'a' );
    is( $original->(), 'a', "Original sub" );

    ok( eleMentalClinic::Role::Cache::_replace_sub(
        'Test::Package',
        'a',
        sub { 'new a' },
    ), "replace ran" );

    ok( \&Test::Package::a != $original, "Not old sub" );
    is( Test::Package::a(), 'new a', "Sub replaced" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Helper Functions - _cache_method

    ok( eleMentalClinic::Role::Cache::_cache_method(
        'eleMentalClinic::Role',
        'a'
    ), "Made method caching" );
    $CLASS->clear;
    is_deeply( $CLASS->DATA, {}, "Nothing in data yet." );
    my $role = eleMentalClinic::Role->new( 1 );
    is( $role->id, 1, "Got the id" );
    is( $role->a, 'a', "Correct Return" );
    is_deeply(
        $CLASS->DATA,
        {
            1 => {
                a => {
                    results => [ 'a' ],
                    result_type => 'scalar',
                },
            },
        },
        "Correct Data"
    );
    is( $role->a, 'a', "Correct Return" );

    ok( eleMentalClinic::Role::Cache::_cache_method(
        'eleMentalClinic::Role',
        'array'
    ), "Made method caching" );
    $CLASS->clear;
    is_deeply( $CLASS->DATA, {}, "Nothing in data yet." );
    is_deeply( [ $role->array ], [ 'a' .. 'z' ], "Correct Return" );
    is_deeply(
        $CLASS->DATA,
        {
            1 => {
                array => {
                    results => [ 'a' .. 'z' ],
                    result_type => 'array',
                },
            },
        },
        "Correct Data"
    );
    is_deeply( [ $role->array ], [ 'a' .. 'z' ], "Correct Return" );

    $tmp = $CLASS->DATA->{ 1 }->{ array };
    $tmp->{ results } = [ 'replaced' ];
    $tmp->{ result_type } = 'scalar';
    is_deeply( [ $role->array ], [ 'replaced' ], "Got from data" );

    ok( eleMentalClinic::Role::Cache::_cache_method(
        'eleMentalClinic::Role',
        'undef'
    ), "Made method caching" );
    $CLASS->clear;
    is_deeply( $CLASS->DATA, {}, "Nothing in data yet." );
    is_deeply( [ $role->undef ], [ undef ], "Correct Return" );
    is_deeply(
        $CLASS->DATA,
        {
            1 => {
                'undef' => {
                    results => [ undef ],
                    result_type => 'scalar',
                },
            },
        },
        "Correct Data"
    );
    is_deeply( [ $role->undef ], [ undef ], "Correct Return" );

    ok( eleMentalClinic::Role::Cache::_cache_method(
        'eleMentalClinic::Role',
        'nada'
    ), "Made method caching" );
    $CLASS->clear;
    is_deeply( $CLASS->DATA, {}, "Nothing in data yet." );
    is_deeply( [ $role->nada ], [  ], "Correct Return" );
    is_deeply(
        $CLASS->DATA,
        {
            1 => {
                'nada' => {
                    result_type => 'empty',
                },
            },
        },
        "Correct Data"
    );
    is_deeply( [ $role->nada ], [ ], "Correct Return" );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Helper Functions - _make_reset

    ok( eleMentalClinic::Role::Cache::_make_reset(
        'Test::Package',
        'array'
    ), "Made method clear" );

    $CLASS->clear;
    $CLASS->DATA->{ test } = 1;
    is( $CLASS->DATA->{ test }, 1, "Data set" );
    is_deeply( [ Test::Package::array() ], [ 'a' .. 'z' ], "Got correct return" );
    is_deeply(
        $CLASS->DATA,
        {},
        "Data Cleared"
    );

    ok( eleMentalClinic::Role::Cache::_make_reset(
        'Test::Package',
        'g'
    ), "Made method clear" );

    $CLASS->clear;
    $CLASS->DATA->{ test } = 1;
    is( $CLASS->DATA->{ test }, 1, "Data set" );
    is_deeply( Test::Package::g(), 'g', "Got correct return" );
    is_deeply(
        $CLASS->DATA,
        {},
        "Data Cleared"
    );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Exported Functions

    {
        package Test::Package::B;
        use eleMentalClinic::Role::Cache qw/ cache_methods resets_role_cache /;
        use Test::More;
        use Test::Exception;

        our %ORIGINALS;

        for my $sub ( 'a' .. 'z' ) {
            my $new = sub { $sub };
            $ORIGINALS{ $sub } = $new;
            no strict 'refs';
            *$sub = $new;
        }

        is( \&$_, $ORIGINALS{$_}, "Original in place: $_" ) for 'a' .. 'z';

        cache_methods 'a' .. 'g';
        resets_role_cache 'g' .. 'z';

        ok( \&$_ != $ORIGINALS{$_}, "Original replaced: $_" ) for 'a' .. 'z';

        {
            no strict 'refs';
            is( &$_, $_, "Correct Return $_" ) for 'a' .. 'z';
        }

        dies_ok { cache_methods 'fake' } 'Cannot replace non-existant sub';
        like( $@, qr/Test::Package::B has no method fake\./, "Correct error" );
        dies_ok { resets_role_cache 'fake' } 'Cannot replace non-existant sub';
        like( $@, qr/Test::Package::B has no sub fake\./, "Correct error" );
    }

    can_ok( 'Test::Package::B', qw/cache_methods resets_role_cache/ );
