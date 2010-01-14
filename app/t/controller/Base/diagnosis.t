# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 79;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, $tmp2, $tmp3, %tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Diagnosis';
    use_ok( q/eleMentalClinic::Controller::Base::Diagnosis/ );
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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runmodes
    can_ok( $CLASS, 'ops' );
    ok( my %ops = $CLASS->ops );
    is_deeply( [ sort keys %ops ], [ sort qw/
        home view edit create display_edit save clone
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home view edit create display_edit save clone
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_diagnosis
    # good id
    can_ok( $one, 'get_diagnosis' );
    is( $one->get_diagnosis, undef );
    is_deeply( $one->get_diagnosis( 1001 ), $client_diagnosis->{ 1001 });
    is( $one->get_diagnosis( 666 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    # no param
    ok( $one = $CLASS->new_with_cgi_params() );
    isa_ok( $one, $CLASS );
    is_deeply( $one->home, {
        current_diagnosis   => undef,
        diagnoses           => undef,
        op                  => 'view',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# view
    # no parameters
    ok( $one = $CLASS->new_with_cgi_params( op => 'view' ) );
    isa_ok( $one, $CLASS );
    is_deeply( $one->view, {
        current_diagnosis   => undef,
        diagnoses           => undef,
        op                  => 'view',
    });

    # with a client
    ok( $one = $CLASS->new_with_cgi_params( op => 'view', client_id => 1002 ) );
    is_deeply( $one->view, {
        current_diagnosis   => $client_diagnosis->{ 1005 },
        diagnoses   => [ $client_diagnosis->{ 1005 }],
        op                  => 'view',
    });

    # client with multiple
    ok( $one = $CLASS->new_with_cgi_params( op => 'view', client_id => 1003 ) );
    is_deeply( $one->view, {
        current_diagnosis   => $client_diagnosis->{ 1002 },
        diagnoses   => [ $client_diagnosis->{ 1002 }, $client_diagnosis->{ 1001 }],
        op                  => 'view',
    });

    # diagnosis_id parameter
    # FIXME without a client_id, this should fail
    ok( $one = $CLASS->new_with_cgi_params( op => 'view', diagnosis_id => 1002 ) );
    isa_ok( $one, $CLASS );
    is_deeply( $one->view, {
        current_diagnosis   => $client_diagnosis->{ 1002 },
        diagnoses   => undef,
        op                  => 'view',
    });
    is_deeply( $one->get_diagnosis, $client_diagnosis->{ 1002 });

    # diagnosis_id parameter with client_id
    ok( $one = $CLASS->new_with_cgi_params( op => 'view', client_id => 1003, diagnosis_id => 1002 ) );
    isa_ok( $one, $CLASS );
    is_deeply( $one->view, {
        current_diagnosis   => $client_diagnosis->{ 1002 },
        diagnoses   => [ $client_diagnosis->{ 1002 }, $client_diagnosis->{ 1001 }],
        op                  => 'view',
    });
    is_deeply( $one->get_diagnosis, $client_diagnosis->{ 1002 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# edit
    # no parameters
    ok( $one = $CLASS->new_with_cgi_params( op => 'edit' ) );
    is_deeply( $one->view, {
        current_diagnosis   => undef,
        diagnoses   => undef,
        op                  => 'view',
    });

    # diagnosis_id parameter with client_id
    ok( $one = $CLASS->new_with_cgi_params( op => 'view', client_id => 1003, diagnosis_id => 1002 ) );
    isa_ok( $one, $CLASS );
    is_deeply( $one->edit, {
        current_diagnosis   => $client_diagnosis->{ 1002 },
        diagnoses   => [ $client_diagnosis->{ 1002 }, $client_diagnosis->{ 1001 }],
        op                  => 'edit',
    });
    is_deeply( $one->get_diagnosis, $client_diagnosis->{ 1002 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create
    # no param
    ok( $one = $CLASS->new_with_cgi_params() );
    isa_ok( $one, $CLASS ); # FIXME throws warning, don't want that
    is_deeply( $one->create, {
        current_diagnosis   => undef,
        diagnoses   => undef,
        op                  => 'create',
    });

    ok( $one = $CLASS->new_with_cgi_params( client_id => 1003 ) );
    is_deeply( $one->create, {
        current_diagnosis   => undef,
        diagnoses   => [ $client_diagnosis->{ 1002 }, $client_diagnosis->{ 1001 }],
        op                  => 'create',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clone
        %tmp = %{ $client_diagnosis->{ 1002 }};
        $tmp{ rec_id } = '';
        $tmp{ diagnosis_date } = '';

    # no parameters
    # FIXME this should error, diagnosis_id should be required by 'clone()'
    ok( $one = $CLASS->new_with_cgi_params( op => 'clone', client_id => 1003 ) );
    isa_ok( $one, $CLASS );
    is_deeply( $one->clone, {
        current_diagnosis   => undef,
        diagnoses   => [ $client_diagnosis->{ 1002 }, $client_diagnosis->{ 1001 }],
        op                  => 'clone',
    });

    # diagnosis_id parameter
    ok( $one = $CLASS->new_with_cgi_params( op => 'clone', client_id => 1003, diagnosis_id => 1002 ));
    isa_ok( $one, $CLASS );
    is_deeply( $one->clone, {
        current_diagnosis   => \%tmp,
        diagnoses   => [ $client_diagnosis->{ 1002 }, $client_diagnosis->{ 1001 }],
        op                  => 'clone',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    # missing diagnosis_date
    ok( $one = $CLASS->new_with_cgi_params( op => 'save' ));
    isa_ok( $one, $CLASS );
    is_deeply( $one->save, {
        current_diagnosis   => {
            diagnosis_date  => undef,
            client_id       => undef,
        },
        diagnoses   => undef,
        op => 'view',
    });

    is_deeply( $one->errors, [
        '<strong>Client</strong> is required.',
        '<strong>Diagnosis date</strong> is required.',
    ]);

    # have bad diagnosis_date
    ok( $one = $CLASS->new_with_cgi_params(
        op              => 'save',
        diagnosis_date  => 'yesterday',
    ));
    isa_ok( $one, $CLASS );
    is_deeply( $one->save, {
        current_diagnosis   => {
            client_id       => undef,
            diagnosis_date  => 'yesterday',
        },
        diagnoses   => undef,
        op => 'view',
    });

    is_deeply( $one->errors, [
        '<strong>Client</strong> is required.',
        '<strong>Diagnosis date</strong> must include year, month, and date as YYYY-MM-DD',
    ]);

    # have good diagnosis_date and client id
    ok( $one = $CLASS->new_with_cgi_params(
        op              => 'save',
        diagnosis_date  => '2008-01-03',
        client_id       => 1003,
        comment_text    => '',
        comment_text_manual => 'triangles',
    ));
    isa_ok( $one, $CLASS );
    ok( $tmp = $one->save );

        $tmp2 = $tmp->{ current_diagnosis };
    is_deeply([ keys %$tmp ], [ qw/ current_diagnosis diagnoses op /]);
    is_deeply_except({ rec_id => undef }, $tmp2, {
        client_id            => '1003',
        comment_text         => 'triangles',
        diagnosis_1a         => undef,
        diagnosis_1b         => undef,
        diagnosis_1c         => undef,
        diagnosis_2a         => undef,
        diagnosis_2b         => undef,
        diagnosis_3          => undef,
        diagnosis_4          => undef,
        diagnosis_5_current  => undef,
        diagnosis_5_highest  => undef,
        diagnosis_date       => '2008-01-03',
    });
    is( scalar @{ $tmp->{ diagnoses }}, 3 );
    is_deeply( $tmp->{ diagnoses }, [
        $tmp2,
        $client_diagnosis->{ 1002 },
        $client_diagnosis->{ 1001 },
    ]);

    # saving existing diagnosis
        $tmp = {
            op              => 'save',
            %{ $client_diagnosis->{ 1002 }},
            diagnosis_id   => 1002,
            diagnosis_date => '2008-07-04',
            diagnosis_3    => 'Wears a coat for no reason',
            diagnosis_4    => 'Refuses to wear a hat',
        };
        delete $tmp->{ rec_id }; # XXX this is the key to the test
    ok( $one = $CLASS->new_with_cgi_params( %$tmp ));
    isa_ok( $one, $CLASS );
    ok( $tmp = $one->save );

        $tmp3 = $tmp->{ current_diagnosis };
    is_deeply([ keys %$tmp ], [ qw/ current_diagnosis diagnoses op /]);
    is_deeply_except({ rec_id => undef }, $tmp3, {
        %{ $client_diagnosis->{ 1002 }},
        diagnosis_date => '2008-07-04',
        diagnosis_3    => 'Wears a coat for no reason',
        diagnosis_4    => 'Refuses to wear a hat',
    });
    is( scalar @{ $tmp->{ diagnoses }}, 3 );
    is_deeply( $tmp->{ diagnoses }, [
        $tmp3,
        $tmp2,
        $client_diagnosis->{ 1001 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();

