# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 13;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Theme;

our ($CLASS, $one, $tmp);
BEGIN {
    $CLASS = 'eleMentalClinic::Controller::Base::Report';

    use_ok( q/eleMentalClinic::Controller::Base::Report/ );
}

my $THEME = eleMentalClinic::Theme->new;

sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}


dbinit( 1 );

$one = $CLASS->new_with_cgi_params(
    client_id => 1001,
    report_track => 'client',
);

isa_ok( $one, $CLASS );

is( $one->report_track, 'client' );

is(
    $one->security,
    undef,
    'no security without config',
);

is( $THEME->name, 'Default' );
ok( $THEME->available_reports( 'client' ));

is_deeply( 
   [ sort map { $_->{name} } @{ $one->report_list } ],
   $THEME->available_reports('client'),
);

isnt( @{ $one->report_list }, 0, "there are *some* reports available" );

# XXX end the transaction and don't insert data; making a new object here turns
# AutoCommit on for the dbh, because CGI::Session's DBI driver's DESTROY method
# tries to commit.
# tests below here don't need special test data.  if they do, this test will
# require attention again.
$test->db->transaction_rollback;

$one = $CLASS->new;

isa_ok( $one, $CLASS );

is( $one->report_track, 'site' );

is_deeply(
   [ sort map { $_->{name} } @{ $one->report_list } ],
   $THEME->available_reports('site'),
);

isnt( @{ $one->report_list }, 0, "there are *some* reports available" );

my %available = (
    zip_count => 1,
);

# XXX inappropriate knowledge of the theme's guts, but only for testing
$THEME->_report_config( [ keys %available ] );
delete $THEME->{available_reports};

$one = $CLASS->new;
is_deeply(
    [ map { $_->{name} } @{ $one->report_list } ],
    [ 'zip_count' ],
);

dbinit( );
