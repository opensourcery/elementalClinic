# vim: ts=4 sts=4 sw=4
# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 112;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::CGI';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# javascripts
    can_ok( $one, 'javascripts' );
    is( $one->{ javascripts }, undef );
    is( $one->javascripts, undef );
    is( $one->{ javascripts }, undef );

    is_deeply( $one->javascripts( qw/ foo /), [ qw/ foo /]);
    is_deeply( $one->javascripts([ qw/ bar baz /]), [ qw/ foo bar baz /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ajax
    can_ok( $one, 'ajax' );
    is( $one->ajax, undef );
    ok( $one->ajax( 1 ));
    ok( $one->ajax );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# uri

    $test->setup_cgi(
        foo => 1,
    );
    $one = $CLASS->new;
    is( $one->uri, 'http://localhost?foo=1', 'correct uri' );
    is(
        $one->uri_with({ foo => 2 }),
        'http://localhost?foo=2',
        'uri_with changing existing param',
    );
    is(
        $one->uri_with({ bar => 3 }),
        'http://localhost?bar=3;foo=1',
        'uri_with adding new param',
    );
    is(
        $one->uri_with({ foo => undef }),
        'http://localhost',
        'uri_with deleting param',
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# params
        # setup incoming query string
        $test->setup_cgi(
            comment     => 'Now is the time for all good men to come to the aid',
            crackme     => '$ENV{ meat_of_evil }',
            date        => '2004-09-29',
            item        => 'Cat food',
            op          => 'add',
        );

        $one = $CLASS->new;
    is( $one->op, 'home' ); # not 'add', since we haven't defined other ops
    is( $one->param( 'item' ), 'Cat food' );
    is( $one->param( 'date' ), '2004-09-29' );
    is( $one->template->vars->{op}, "home" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# redirect_to
    can_ok( $one, 'redirect_to' );

    # FIXME: I don't think these tests are necessary anymore
    #throws_ok{ $one->redirect_to } qr/\$ENV{ REQUEST_URI } is required for \'redirect_to\'/;

#        $ENV{ REQUEST_URI } = 'http://emc/';
#    throws_ok{ $one->redirect_to } qr/'gateway' missing in URI; should be impossible in correctly-configured app/;

#        $ENV{ REQUEST_URI } = 'http://emc/gateway/';
    is_deeply([ $one->redirect_to ], [ undef, { Location => '/' } ]);
    is_deeply([ $one->redirect_to( 'controller' ) ], [ undef, { Location => '/controller.cgi' } ]);
    is_deeply([ $one->redirect_to( 'controller', 666 ) ], [ undef, { Location => '/controller.cgi?client_id=666' } ]);

    throws_ok{ $one->redirect_to( 'controller', 'erroneous' )} qr/'client_id' must be an integer/;

    # bug fix FIXME don't think this one's required either.
#        $ENV{ REQUEST_URI } = '/gateway/user_prefs.cgi?op=save_one;return_to=roi.cgi;client_id=1002;pref=releases_show_expired;value=0';
#    is_deeply([ $one->redirect_to ], [ undef, '/gateway/' ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# extract a set of params by prefix
    can_ok($CLASS, 'extract_byprefix');

    my $params = {
        foo => 'foo',
        bar => 'bar',
        prefix_foo => 'dingo',
        prefix_bar => 'thing',
    };
    
        $one = $CLASS->new;
    
    is_deeply( sort $one->extract_byprefix($params, 'prefix_'), sort {
        foo => 'dingo',
        bar => 'thing',
    });
    is_deeply( $one->extract_byprefix($params, 'notthere'), {} );
    
    is_deeply( $one->Vars_byprefix('com'), { ment => 'Now is the time for all good men to come to the aid' } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Vars tests

    # Testing that each call to Vars() returns a new hash
    my $vars = $one->Vars;
    $vars->{comment} = 'foo';
    my $original_vars = $one->Vars;
    ok( $vars->{comment} ne $original_vars->{comment} );
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make sure we can change incoming params
        $test->setup_cgi(
            item        => 'barf',
        );

        $one = $CLASS->new;
    is( $one->op, 'home' ); # not 'add', since we haven't defined other ops
    is( $one->param( 'item' ), 'barf' );
    is( $one->param( 'date' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# template path
    can_ok( $one, 'create_template_path' );
    can_ok( $one, 'override_template_path' );
    can_ok( $one, 'override_template_name' );

    # no controller or op, so we get the last part of the calling object's name
    is( $one->create_template_path, 'cgi/' );

    ok( $one->override_template_path( 'testing' ));
    is( $one->create_template_path, 'testing/' );
    is( $one->create_template_path( 'one' ), 'testing/one' );

    ok( $one->override_template_name( 'three' ));
    is( $one->create_template_path, 'testing/three' );
    is( $one->create_template_path( 'one' ), 'testing/three' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# methods to provide select options data

        $test->db_refresh();
        $test->insert_data();
    
    # make an array of key value pairs suitable for consumption by select_new.html
    can_ok($CLASS, 'make_select_options');
    throws_ok {$one->make_select_options} qr/expects a hashref of parameters/;
    throws_ok {$one->make_select_options({ foo => 'bar' })} qr/Rows, id and label.*required/;
    my $rows = [
        $rolodex->{1001},
        $rolodex->{1011},
    ];
    is_deeply(
        $one->make_select_options( {
            rows => $rows, 
            id_column => 'rec_id', 
            label_column => 'name', } ) ,
        [
            { id => 1001, label => $rolodex->{1001}->{name} },
            { id => 1011, label => $rolodex->{1011}->{name} },
        ]);
    is_deeply(
        $one->make_select_options( {
            rows => $rows,
            id_column =>'rec_id',
            label_column => 'fname',
            id_key => 'foo',
            label_key => 'bar' } ),
        [
            { foo => 1001, bar => $rolodex->{1001}->{fname} },
            { foo => 1011, bar => $rolodex->{1011}->{fname} },
        ]);
    is_deeply(
        $one->make_select_options( {
            rows => $rows,
            id_column => 'rec_id',
            label_column => [ 'lname', 'fname' ], } ),
        [
            { id => 1001, 
              label => "$rolodex->{1001}->{lname}, $rolodex->{1001}->{fname}"
            },
            { id => 1011, 
              label => "$rolodex->{1011}->{lname}, $rolodex->{1011}->{fname}"
            },
        ]);
    is_deeply(
        $one->make_select_options( {
            rows => $rows,
            id_column => 'rec_id',
            label_column => [ 'lname', 'fname' ],
            label_separator => ' : ',
            id_key => 'foo',
            label_key => 'bar' } ),
        [
            { foo => 1001, 
              bar => "$rolodex->{1001}->{lname} : $rolodex->{1001}->{fname}"
            },
            { foo => 1011, 
              bar => "$rolodex->{1011}->{lname} : $rolodex->{1011}->{fname}"
            },
        ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# I've removed this method in this module, was identical to the method in Base
    can_ok( $one, 'timestamp' );

$test->db_refresh;
$test->insert_data;

for my $role (@{ eleMentalClinic::Personnel->security_fields }) {
    $one->security( $role );
    for my $person (@{ eleMentalClinic::Personnel->get_all }) {
        next if $person->admin; # admin can do everything
        $one->{current_user} = $person;
        my $id = $person->{staff_id};
        if ( $person->$role ) {
            ok( $one->security_check, "$id does $role" );
        } else {
            ok( !$one->security_check, "$id does not do $role" );
        }
    }
}
