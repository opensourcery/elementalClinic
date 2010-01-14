# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 33;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, $tmp_b, $tmp_c);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::PersonnelHome';
    use_ok( q/eleMentalClinic::Controller::Base::PersonnelHome/ );
}

{
    package jeBlah;

    sub new {
        my $proto = shift;
        my( $args, $options ) = @_;
        my $class = ref $proto || $proto;
        my $self = bless {}, $class;
    }

    sub discharge {
        return 'inexplicable';
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runmodes
    can_ok( $CLASS, 'ops' );
    ok( my %ops = $CLASS->ops );
    is_deeply( [ sort keys %ops ], [ sort qw/
        home save_home_page_type
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home save_home_page_type
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    # basic home
    ok( $one = $CLASS->new_with_cgi_params( op   =>  'home' ));

        # otherwise fails as there is no session
    ok( $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1 ));

    ok( $tmp = $one->home );
    is( ref $tmp->{ clients }, '' );
    is( $tmp->{ search }, '' );
    is( $tmp->{ reminders }, undef );

    # less basic home
    ok( $one = $CLASS->new_with_cgi_params(
        op      =>  'home',
        search  =>  'ajblah',
    ));

        # otherwise fails as there is no session
    ok( $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 ));

    ok( $tmp = $one->home );
    is( ref $tmp->{ clients }, 'ARRAY' );
    is( $tmp->{ search }, 'ajblah' );
    is( $tmp->{ reminders }, undef );

    # even less basic home
    ok( $one = $CLASS->new_with_cgi_params( op   =>  'home' ));

        # otherwise fails as there is no session
    ok( $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 ));
        $one->{ current_user }->pref->user_home_show_visit_frequency_reminders( 1 );

    ok( $tmp = $one->home );
    is( ref $tmp->{ clients }, 'ARRAY' );
    is( $tmp->{ search }, '' );
    is_deeply( $tmp->{ reminders }->{ assessments }, [] );
    is( ref( $tmp->{ reminders }->{ overdue_clients }->[0]->{ client } ), 'eleMentalClinic::Client' );
    is_deeply( $tmp->{ reminders }->{ overdue_clients }->[0]->{ overdue }, {
        client_id       =>  '1006',
        visit_frequency =>  '1',
        visit_interval  =>  'month',
    });

    # redirect home
    ok( $one = $CLASS->new_with_cgi_params( op   =>  'home' ));

        # otherwise fails as there is no session
    ok( $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1 ));
        $one->{ current_user }->{ home_page_type } = 'financial';

    ok( $tmp = $one->home );
    is_deeply( $tmp, { Location => '/financial.cgi' });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit( 1 );

