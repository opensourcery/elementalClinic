# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 31;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Letter';
    use_ok( q/eleMentalClinic::Controller::Base::Letter/ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new, 'basic constructor' );
    ok( defined( $one ), 'constructor working' );
    ok( $one->isa( $CLASS ), 'constructor working' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    # no data
    ok( $one = $CLASS->new_with_cgi_params(
        op  =>  'save',
    ), 'new $CLASS, op=>save, no data' );
    isa_ok( $one, $CLASS, '$one isa $CLASS' );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->save, '$tmp = $one->save' );
    is_deeply( $one->errors, [
        '<strong>Client</strong> is required.',
        '<strong>Relationship</strong> is required.'
    ], 'correct errors' );

#    # bad data
#    # FIXME dies if client_id is not integer, same problem in prescription test
#    ok( $one = $CLASS->new_with_cgi_params(
#        op  =>  'save',
#        client_id           =>  'flying monkeys',
#        relationship_info   =>  'yahyahyah-blargh'
#    ));
#    isa_ok( $one, $CLASS );
#
#        # otherwise fails as there is no session
#        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );
#
#    #ok( $tmp = $one->save );
#    dies_ok{ $tmp = $one->save };
#        #die Dumper $one->errors;

    # good data
    ok( $one = $CLASS->new_with_cgi_params(
        op  =>  'save',
        client_id   =>  1002,
        relationship_info   =>  'purple-1'
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

        ok( $tmp = $one->save );
    is( ref $tmp->{ current }, 'eleMentalClinic::Client::Letter' );
    is_deeply( $tmp->{ relationships }, [{
        'key' => 'mental_health_insurance-1012',
        'val' => 'XIX - Medicaid [Mental Health Insurance]'
    }]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    ok( $one = $CLASS->new_with_cgi_params );
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->home );
    is( ref $tmp->{ current }, 'eleMentalClinic::Client::Letter' );
    is_deeply( $tmp->{ relationships }, [] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# view
    ok( $one = $CLASS->new_with_cgi_params(
        op  =>  'view'
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    $tmp = $one->view;
    is( ref $tmp->{ current }, 'eleMentalClinic::Client::Letter' );
    is_deeply( $tmp->{ relationships }, [], 'no relationships' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex_create_letter
    ok( $one = $CLASS->new_with_cgi_params(
        op                      =>  'rolodex_create_letter',
        relationship_role       =>  '',
        rolodex_relationship_id =>  ''
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->rolodex_create_letter );
    is_deeply( $tmp, {
        current         =>  {
            relationship_role       =>  undef,
            rolodex_relationship_id =>  undef
        },
        relationships   =>  []
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# print
    ok( $one = $CLASS->new_with_cgi_params(
        op  =>  'edit'
    ));
    isa_ok( $one, $CLASS );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->edit );
    is( ref $tmp->{ current }, 'eleMentalClinic::Client::Letter' );
    is_deeply( $tmp->{ relationships }, [] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit( );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

