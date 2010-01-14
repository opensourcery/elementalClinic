# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More 'no_plan';
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, $c );
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Error';
    use_ok( q/eleMentalClinic::Controller::Base::Error/ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new, '$one = $CLASS->new' );
    ok( defined( $one ), '$one is defined' );
    ok( $one->isa( $CLASS ), '$one isa $CLASS' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runmodes
    can_ok( $CLASS, 'ops', );
    ok( my %ops = $CLASS->ops, 'assign %ops to $CLASS->ops' );
    is_deeply( [ sort keys %ops ], [ sort qw/ home retrieve send_report /], 'ops are correct');
    can_ok( $CLASS, $_, ) for qw/ home retrieve send_report /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my $path = eleMentalClinic::Log::ExceptionReport->report_path;
my $file = $path . "///some/file/name";
is( $one->strip_report_path( $file ), 'some/file/name', "report path stripped" );

is( $one->add_report_path( "$path//a/file/name" ), "$path//a/file/name", "Not added, already there" );
is( $one->add_report_path( "a/file/name" ), "$path/a/file/name", "added" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#{{{ Fake catalyst_c class
{
    package eleMentalClinic::Fake::Catalyst;

    sub new {
        my $class = shift;
        return bless( { stash => { @_ } }, $class );
    }

    sub stash {
        my $self = shift;
        return $self->{ stash };
    }
}
#}}}
# home
    ok( $one = $CLASS->new_with_cgi_params, '$one = $CLASS->new_with_cgi_params' );
    $one->catalyst_c( eleMentalClinic::Fake::Catalyst->new() );
    isa_ok( $one, $CLASS, '$one isa $CLASS' );
    ok( $tmp = $one->home, '$tmp = $one->home' );
    is_deeply(
        $tmp,
        {
            exceptions => [],
            cgi_params => {},
        },
        'Basic empty data needed for template'
    );

    #Fake a controller DB error.
    $c = eleMentalClinic::Fake::Catalyst->new();

    for ( 1 .. 3 ) {
        dies_ok { $one->db->do_sql( "select * from FAKE_TABLE_THAT_DOES_NOT_EXIST" ) };
        push @{ $c->stash->{ _cgi_exceptions }}, eleMentalClinic::Log::ExceptionReport->message_is_catchable( $@ );
    }
    is( @{ $c->stash->{ _cgi_exceptions }}, 3, "3 exceptions" );

    ok(
        $one = $CLASS->new_with_cgi_params(
            exception => $c->stash->{ _cgi_exceptions }->[0] 
        ),
        '$one = $CLASS->new_with_cgi_params'
    );
    $one->catalyst_c( $c );
    is_deeply(
        $one->exception,
        $one->read_report( $c->stash->{ _cgi_exceptions }->[0] ),
        "Got the correct exception"
    );

    ok( $one = $CLASS->new_with_cgi_params( 'a' .. 'z' ), '$one = $CLASS->new_with_cgi_params' );
    $one->catalyst_c( $c );
    isa_ok( $one, $CLASS, '$one isa $CLASS' );
    is_deeply(
        $one->exception( $c->stash->{ _cgi_exceptions }->[0] ),
        $one->read_report( $c->stash->{ _cgi_exceptions }->[0] ),
        "Got the correct exception"
    );
    is_deeply(
        $one->exceptions,
        [
            map { $one->strip_report_path( $_ ) } @{ $c->stash->{ _cgi_exceptions }}
        ],
        "Correct Exceptions"
    );
    ok( $tmp = $one->home, '$tmp = $one->home' );
    is_deeply(
        $tmp,
        {
            exceptions => $one->exceptions,
            cgi_params => { 'a' .. 'z' },
        },
        "Have params and exceptions"
    );
    is( @{ $one->exceptions }, 3, "3 exceptions" );

    is_deeply(
        $one->_obfuscate_string(
            'all Occurences of This and this and THIs should be obfuscated like pie and PIe',
            [ 'this', 'pie' ],
        ),
        'all Occurences of Xxxx and xxxx and XXXx should be obfuscated like xxx and XXx',
        "Obfuscated String"
    );
    is_deeply(
        $one->_obfuscate_string(
            'all Occurences of This and this and THIs should be obfuscated like pie and PIe',
            [ 'this', 'pie' ],
            1
        ),
        '<span class="obfuscatable">all Occurences of Xxxx and xxxx and XXXx should be obfuscated like xxx and XXx</span>',
        "Obfuscated String - HTML"
    );

    is_deeply(
        $one->_obfuscate_string(
            'This::Pie',
            [ 'this', 'pie' ],
        ),
        'This::Pie',
        "do not Obfuscated module names"
    );
    is_deeply(
        $one->_obfuscate_string(
            'This/Pie.pm',
            [ 'this', 'pie' ],
        ),
        'This/Pie.pm',
        "do not Obfuscated module paths"
    );

    is_deeply(
        $one->_obfuscate_string(
            '"This/Pie.pm"',
            [ 'this', 'pie' ],
        ),
        '"This/Pie.pm"',
        "do not Obfuscated module paths quoted"
    );


    my $raw = <<'EOT';
========
Obfuscate THis and PIe but not This::Pie or This/Pie.pm
Newline
========
something:
this-has-dashes
*pie*
*happy*
EOT

    my $obfu = <<'EOT';
========
Obfuscate XXxx and XXx but not This::Pie or This/Pie.pm
Newline
========
something:
xxxx-has-dashes
*xxx*
*happy*
EOT

    my $obfu_html = <<'EOT';
========
<+>Obfuscate</+> <->XXxx</-> <+>and</+> <->XXx</-> <+>but</+> <+>not</+> This::Pie <+>or</+> This/Pie.pm
<+>Newline</+>
========
<+>something:</+>
<+>xxxx-has-dashes</+>
<->*xxx*</->
<+>*happy*</+>
EOT
    $obfu_html =~ s/<\+>/<span class="obfuscatable">/g;
    $obfu_html =~ s/<\->/<span class="obfuscated">/g;
    $obfu_html =~ s/<\/\+>/<\/span>/g;
    $obfu_html =~ s/<\/\->/<\/span>/g;

    ok(
        $one = $CLASS->new_with_cgi_params( obfuscate => [ 'this', 'pie' ] ),
        '$one = $CLASS->new_with_cgi_params'
    );
    $one->catalyst_c( $c );

    is( $one->obfuscate( $raw ), $obfu, "Obfuscated" );
    is( $one->obfuscate( $raw, 1 ), $obfu_html, "Obfuscated + HTML" );

    # Now starting with space.
    $raw = " " . $raw;
    $obfu = " " . $obfu;
    $obfu_html = " " . $obfu_html;
    ok(
        $one = $CLASS->new_with_cgi_params( obfuscate => [ 'this', 'pie' ] ),
        '$one = $CLASS->new_with_cgi_params'
    );
    $one->catalyst_c( $c );

    is( $one->obfuscate( $raw ), $obfu, "Obfuscated" );
    is( $one->obfuscate( $raw, 1 ), $obfu_html, "Obfuscated + HTML" );

dbinit( );
