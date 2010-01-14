# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 114;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Admin';
    use_ok( q/eleMentalClinic::Controller::Base::Admin/ );
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
    is_deeply( [ sort keys %ops ], [ sort qw/
        home configuration save_configuration send_test
    /], 'ops are correct');
    can_ok( $CLASS, $_, ) for qw/
        home configuration save_configuration send_test
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    ok( $one = $CLASS->new_with_cgi_params, '$one = $CLASS->new_with_cgi_params' );
    isa_ok( $one, $CLASS, '$one isa $CLASS' );
    ok( $tmp = $one->home, '$tmp = $one->home' );
    is_deeply( $tmp, {}, '$tmp is empty hash' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# configuration
    ok( $one = $CLASS->new, "create plain new $CLASS" );
    ok( $tmp = $one->configuration, 'set $tmp equal to return of configuration()' );
    is( ref $_, 'eleMentalClinic::Rolodex', 'isa eleMentalClinic::Rolodex' ) for ( @{ $tmp->{ rolodexes } } );
    is( ref $_, 'eleMentalClinic::Mail::Template',
            'check type of return: mailtemplate' ) for ( @{ $tmp->{ mailtemplates } } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_rolodexes
    ok( $one = $CLASS->new, "create plain new $CLASS" );
    ok( $tmp = $one->get_rolodexes, '$tmp = $one->get_rolodexes' );
    is( ref $_, 'eleMentalClinic::Rolodex', 'isa eleMentalClinic::Rolodex' ) for @$tmp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_templates
    ok( $one = $CLASS->new, "create plain new $CLASS" );
    ok( $tmp = $one->get_templates, '$tmp = $one->get_templates' );
    is( ref $_, 'eleMentalClinic::Mail::Template',
            'check type of return: mailtemplate' ) for @$tmp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save_configuration
    # no params
    ok( $one = $CLASS->new_with_cgi_params( op => 'save_configuration' ),
            '$one = $CLASS->new_with_cgi_params( op => \'save_configuration\' )' );
    isa_ok( $one, $CLASS, '$one isa $CLASS' );

    ok( $tmp = $one->save_configuration, '$tmp = $one->save_configuration' );
    is_deeply( $one->errors, [
        '<strong>edit_prognote</strong> is required.',
        '<strong>form_method</strong> is required.',
        '<strong>logout_inactive</strong> is required.',
        '<strong>logout_time</strong> is required.',
        '<strong>org_name</strong> is required.',
        '<strong>prognote_max_duration_minutes</strong> is required.',
        '<strong>prognote_min_duration_minutes</strong> is required.',
    ], 'correct $one->errors' );
    is( ref $_, 'eleMentalClinic::Rolodex', 'isa eleMentalClinic::Rolodex' ) for ( @{ $tmp->{ rolodexes } } );

    # bad params
    ok( $one = $CLASS->new_with_cgi_params(
        op                              =>  'save_configuration',
        edit_prognote                   =>  'foo',
        form_method                     =>  7,
        logout_inactive                 =>  'bar',
        logout_time                     =>  'triangle',
        org_name                        =>  'purple',
        prognote_max_duration_minutes   =>  'mauve',
        prognote_min_duration_minutes   =>  'fake',
    ), '$one is new $CLASS->save_configuration w/bad data' );
    isa_ok( $one, $CLASS, '$one isa $CLASS' );

    ok( $tmp = $one->save_configuration, '$tmp = $one->save_configuration' );
    is_deeply( $one->errors, [
        '<strong>edit_prognote</strong> length must be exactly 1 characters long.',
        '<strong>logout_inactive</strong> must be an integer.',
        '<strong>logout_time</strong> must be an integer.',
        '<strong>prognote_max_duration_minutes</strong> must be an integer.',
        '<strong>prognote_min_duration_minutes</strong> must be an integer.'
    ], 'correct $one->errors' );
    is( ref $_, 'eleMentalClinic::Rolodex', 'isa eleMentalClinic::Rolodex' ) for ( @{ $tmp->{ rolodexes } } );

    # good params
    ok( $one = $CLASS->new_with_cgi_params(
        op                              =>  'save_configuration',
        edit_prognote                   =>  'a',
        form_method                     =>  'post',
        logout_inactive                 =>  0,
        logout_time                     =>  30,
        org_name                        =>  'purple',
        prognote_max_duration_minutes   =>  30,
        prognote_min_duration_minutes   =>  10,
    ), '$one is new $CLASS->save_configuration w/good data' );
    isa_ok( $one, $CLASS, '$one isa $CLASS' );

    ok( $tmp = $one->save_configuration, '$tmp = $one->save_configuration' );
    is( $one->errors, undef, '$one->errors is undef' );
    is( ref $_, 'eleMentalClinic::Rolodex', 'isa eleMentalClinic::Rolodex' ) for ( @{ $tmp->{ rolodexes } } );
    ok( $tmp->{ mailtemplates }, '$tmp->{ mailtemplates } is true' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# send_test
    my $message;
    {
        no warnings qw/redefine/;
        # We don't want stray emails actually sent out
        package eleMentalClinic::Mail;

        sub send {
            my $self = shift;
            # Each send should be it's own email object.
            if ( $self->send_date || $self->rec_id ) {
                my $new_self = eleMentalClinic::Mail->new({ %$self, rec_id => undef, send_date => undef });
                # Modify the object being referenced so that whatever called send has the proper object.
                %$self = %$new_self;
            }
            $self->recipients( [ @_ ] );
            $message = $self->message;
        }
    }

    # missing params
    ok( $one = $CLASS->new_with_cgi_params(
        op  =>  'send_test',
    ), '$one = $CLASS->new_with_cgi_params valid' );
    isa_ok( $one, $CLASS, '$one isa $CLASS' );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->send_test, '$tmp = $one->save_configuration' );
    is_deeply( $one->errors, [
        '<strong>Send As</strong> is required.',
        '<strong>Send Test</strong> is required.'
    ], 'correct $one->errors' );

    # bad params
    ok( $one = $CLASS->new_with_cgi_params(
        op              =>  'send_test',
        send_mail_as    =>  'blah',
        send_test_to    =>  'blah'
    ), '$one = $CLASS->new_with_cgi_params valid' );
    isa_ok( $one, $CLASS, '$one isa $CLASS' );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->send_test, '$tmp = $one->save_configuration' );
    is_deeply( $one->errors, [
        "<strong>Send As</strong>: 'blah' is not a valid email address.",
        "<strong>Send Test</strong>: 'blah' is not a valid email address."
    ], 'correct $one->errors' );

    # good params
    ok( $one = $CLASS->new_with_cgi_params(
        op              =>  'send_test',
        send_mail_as    =>  'foo@example.com',
        send_test_to    =>  'bar@example.com'
    ), '$one = $CLASS->new_with_cgi_params valid' );
    isa_ok( $one, $CLASS, '$one isa $CLASS' );

        # otherwise fails as there is no session
        $one->{ current_user } = eleMentalClinic::Personnel->retrieve( 1003 );

    ok( $tmp = $one->send_test, '$tmp = $one->save_configuration' );
    is( $one->errors, undef, '$one->errors is undef' );
is( $message,
'From: foo@example.com
Subject: Confidential Email. Test Message from EMC
To: bar@example.com

This is a test message from EMC. Thank you,
purple', 'message matches' );
    is( ref $_, 'eleMentalClinic::Rolodex', 'isa eleMentalClinic::Rolodex' ) for ( @{ $tmp->{ rolodexes } } );
    ok( $tmp->{ mailtemplates }, '$tmp->{ mailtemplates } is true' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit( );

