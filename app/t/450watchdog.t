# vim: ts=4 sts=4 sw=4
# Copyright (C) 2004-2009 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 14;
use Test::Exception;
use eleMentalClinic::Test;
use Data::Dumper;

our ($CLASS, $one, $tmp);

BEGIN {
    *CLASS = \'eleMentalClinic::Watchdog';
    use_ok( $CLASS );
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
    #{{{ Fake Controller for testing
    {
        package Fake::Controller;
        use strict;
        use warnings;
        use base qw/ eleMentalClinic::CGI /;

        sub home {
            my $self = shift;
            return { 'home' => 'home' };
        }

        sub retrieve_client {
            my $self = shift;

            my $client = eleMentalClinic::Client->retrieve( 1001 );

            return $self->home;
        }

        sub access_client {
            my $self = shift;

            my $client = eleMentalClinic::Client->retrieve( 1001 );
            $client->ssn;

            return $self->home;
        }

        sub get_many {
            my $self = shift;
            my $clients = eleMentalClinic::Client->get_all;
        }
    }
    #}}}

    sub start_wd {
        my $x = $CLASS->new();
        $x->controller_class( 'Fake::Controller' );
        $x->start();
        return $x;
    }


    $one = start_wd;
    my $c = Fake::Controller->new();
    lives_ok { $c->home } "home is completely innocent";

    $one = start_wd;
    $c = Fake::Controller->new();
    dies_ok { $c->retrieve_client } "retrieve client w/o a user";

    $one = start_wd;
    $c = Fake::Controller->new();
    dies_ok { $c->access_client } "access client w/o a user";

    $tmp = eleMentalClinic::Personnel->new({
        (map { $_ => 'test' } qw/fname lname mname login/),
        (map { $_ => 1001 } qw/unit_id dept_id/),
    });
    $tmp->save;

    $one = start_wd;
    $c = Fake::Controller->new();
    $c->current_user( $tmp );
    dies_ok { $c->retrieve_client } "client w/ a bad user";

    $one = start_wd;
    $c = Fake::Controller->new();
    $c->current_user( $tmp );
    dies_ok { $c->access_client } "client w/ a bad user";

    $one = start_wd;
    $c = Fake::Controller->new();
    $c->current_user( $tmp );
    dies_ok { $c->get_many } "accessing all clients w/o perms to all";

    $one = start_wd;
    $c = Fake::Controller->new();
    $c->current_user( $tmp );
    eleMentalClinic::Role->retrieve( 2 )->add_personnel( $tmp );
    lives_ok { $c->retrieve_client } "client w/ an 'all' user";

    $one = start_wd;
    $c = Fake::Controller->new();
    $c->current_user( $tmp );
    lives_ok { $c->access_client } "client w/ an 'all' user";

    eleMentalClinic::Role->retrieve( 2 )->del_personnel( $tmp );
    $tmp->primary_role->grant_client_permissions( 1001 );

    $one = start_wd;
    $c = Fake::Controller->new();
    $c->current_user( $tmp );
    lives_ok { $c->retrieve_client } "user w/ access to client";

    $one = start_wd;
    $c = Fake::Controller->new();
    $c->current_user( $tmp );
    lives_ok { $c->access_client } "user w/ access client";
