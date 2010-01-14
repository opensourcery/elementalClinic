# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 38;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Client;

our ($CLASS, $one, $tmp, $LOG_PATH, $LOG_NAME);
$LOG_PATH = 't/resource';
$LOG_NAME = 'elementalclinic';

BEGIN {
    *CLASS = \'eleMentalClinic::Log';
    use_ok( $CLASS );
}

# utility ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ {{{
sub _remove_logs {
    `rm -f $LOG_PATH/$LOG_NAME.log`;
}

sub _log_exists {
    my $path = "$LOG_PATH/$LOG_NAME.log";
    return -f $path;
}

sub _log_entries {
    my $path = "$LOG_PATH/$LOG_NAME.log";
    my $lines = `wc -l < $path`;
    $lines =~ s/\s//g;
    return $lines;
}

sub _log_contains {
    my( $what ) = @_;
    my $path = "$LOG_PATH/$LOG_NAME.log";
    my $result = `grep '$what' $path`;
    return unless $result;
    return 1;
}
#}}}
_remove_logs();

$test->db->transaction_begin;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new( 't/resource/log.conf' ));
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

    ok( _log_exists( $LOG_NAME ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# log, failures
    can_ok( $one, 'write_log' );
    is( $CLASS->write_log, undef );
    is( $CLASS->write_log( 'Foo' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# log, working
    ok( $CLASS->write_log( 'info', 'a message' ));
    is( _log_contains( 'Foo' ), undef );
    is( _log_entries, 1 );
    ok( _log_contains( '\[INFO] a message' ));

    ok( $CLASS->write_log( 'exhort', 'Now is the time' ));
    is( _log_entries, 2 );
    ok( _log_contains( '\[EXHORT] Now is the time' ));

    ok( $CLASS->write_log( 'wb', 'Fiery the angels' ));
    is( _log_entries, 3 );
    ok( _log_contains( '\[WB] Fiery' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Log
    can_ok( $one, 'Log' );
    ok( Log({
        type => 'security',
        action => 'failure',
        user => 'bob'
    }), "Bob login failure");
    is( _log_entries, 4 );
    ok( _log_contains( '\[SECURITY]' ));
    ok( _log_contains( 'Login failure' ));

    ok( Log({
        type => 'access', 
        action => 'load', 
        object => eleMentalClinic::Client->retrieve( 1001 )
    }), "Access");
    is( _log_entries, 5 );
    ok( _log_contains( '\[CLIENT]' ));
    ok( _log_contains( '[client_id: 1001]' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Log_defer and Retrieve_deferred
    can_ok( $one, 'Log_defer' );
    can_ok( $one, 'Retrieve_deferred' );

    is( Log_defer, undef );
    is_deeply( Retrieve_deferred, [] );
    
    ok( Log_defer( 'Save this error for a later time' ) );
    is_deeply( Retrieve_deferred, [ 'Save this error for a later time'] );
    
    ok( Log_defer( 'And this one' ) );
    is_deeply( Retrieve_deferred, [
        'Save this error for a later time',
        'And this one',
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Log_tee
    can_ok( $one, 'Log_tee' );
    is( Log_tee, undef );
    is( Log_tee( 'Test Log_tee' ), 'Test Log_tee' );
    # TODO use Test::Warn here

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$test->db->transaction_rollback;
_remove_logs();
