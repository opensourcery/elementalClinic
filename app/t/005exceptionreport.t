# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 30;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Log::ExceptionReport';
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
    can_ok( $one, @{$one->methods} );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ok( $one->stack, "got stack trace" );
    is_deeply( $one->params, {}, "Default params is empty hash" );
    is( $one->catchable, 0, "Not catchable by default." );
    is( $one->message, "An error has occured", "Default message" );
    is( $one->name, 'unnamed', "Default name" );

    my $proto = {
        name => "Error Name",
        message => 'Error Name is a bad name for an error!',
        catchable => 1,
        params => {
            a => 'b',
            c => 'd',
            e => 'f',
        }
    };
    $one = $CLASS->new( $proto );

    is( $one->name, "Error Name", "Specified error name" );
    is( $one->message, "Error Name is a bad name for an error!", "Specified error message" );
    is( $one->catchable, 1, "Made catchable" );
    is_deeply( $one->params, { 'a' .. 'f' }, "Specified params" );
    ok( $one->stack, "got stack trace" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->new( $proto );
    ok( $one->save, "Save ran" );
    ok( $one->file, "Have filename" );
    ok( -e $one->file, "File exists" );
    like( $one->file, qr/Error Name-\d+-\d+-\d+-\d+-\d+-\d+-.{6}/, "File named properly" );
    $tmp = $one->file;
    is( $one->save, $tmp, "Second save returns file name" );

    open( my $file, '<', $one->file ) || die( "$!" );
    my @data = <$file>;
    is( join( '', @data ), $one->report, "Saved report matches current" );
    close( $file );

    unlink( $one->file );

    $one = $CLASS->new( { %$proto, no_save => 1 } );
    ok( !$one->save, "No Save" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->new( $proto );
    dies_ok { $one->throw } "Throw dies";
    $tmp = $one->file;
    like( $@, qr/Catchable Exception \($tmp\) Error Name: Error Name is a bad name for an error!/, "Catchable exception" );
    unlink( $file );

    $one = $CLASS->new({ %$proto, catchable => 0 });
    dies_ok { $one->throw } "Throw dies";
    $tmp = $one->file;
    like( $@, qr/Unhandled Exception \($tmp\) Error Name: Error Name is a bad name for an error!/, "Unhandled exception" );
    unlink( $file );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->new( $proto );

    is(
        $one->report,
          "Error Name"
        . "\n----------------------------------\n"
        . "Error Name is a bad name for an error!\n\n"
        . Dumper({ 'a' .. 'f' })
        . "\n----------------------------------\n"
        . "Stack Trace:\n" . $one->stack->as_string,
        "Correct report"
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    is(
        $CLASS->message_is_catchable( "XXX Catchable Exception (a/file/name) XXX" ),
        "a/file/name",
        "Message was catchable"
    );

    is(
        $CLASS->message_is_catchable( "XXX Catchable Exception (a/file/name) XXX)" ),
        "a/file/name",
        "Correct paren handling"
    );

    ok(
        !$CLASS->message_is_catchable( "XXX Unhandled Exception (a/file/name) XXX" ),
        "Not catchable"
    );
