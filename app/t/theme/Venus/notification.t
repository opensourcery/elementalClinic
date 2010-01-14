#!/usr/bin/perl
# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
use warnings;
use strict;

use Test::EMC;
plan tests => 86;

use Test::Exception;
use eleMentalClinic::Test;
use Data::Dumper;

our ($CLASS, $one, $tmp);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}

sub end_trans {
    eleMentalClinic::DB->new->transaction_rollback if eleMentalClinic::DB->new->transaction_depth > 0;
}

dbinit( 1 );

# NOTE: the chooser uses javascript, WWW::Mechanize does not.

#{{{ run these once.
    *CLASS = \'eleMentalClinic::Controller::Base::Notification';
    use_ok( 'eleMentalClinic::Controller::Base::Notification' );

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
        home save edit new_template
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home save edit new_template
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    is_deeply(
        $one->home,
        $one->gen_vars,
        "Home returns a list of vars"
    );

    is_deeply(
        $one->edit,
        {
            %{ $one->gen_vars },
            action => 'edit'
        },
        "edit overrides action"
    );
    is( $one->override_template_name, 'home', "Template path was overriden by 'edit'" );

    is_deeply(
        $one->new_template,
        {
            %{ $one->gen_vars },
            action => 'edit',
            template_id => undef,
            current => undef,
        },
        "new_template sets proper vars"
    );
#}}}

#{{{ Parameter Normalization
test 'Parameter Normalization' => sub {
    args attach_before => [
        comment => "save hash normalization, attach components before",
        params => {
            subject_attach => 'Before',
            message_attach => 'Before',
            clinic_attach  => 'Yes',
        },
        result => {
            subject_attach => -1,
            message_attach => -1,
            clinic_attach  => 1,
        },
    ];

    args attach_after => [
        comment => "save hash normalization, attach components after",
        params => {
            subject_attach => 'After',
            message_attach => 'After',
            clinic_attach  => 'Yes',
        },
        result => {
            subject_attach => 1,
            message_attach => 1,
            clinic_attach  => 1,
        },
    ];
    args no_attach => [
        params => {
            subject_attach => 'No',
            message_attach => 'No',
            clinic_attach  => 'No',
        },
        result => {
            subject_attach => 0,
            message_attach => 0,
            clinic_attach  => 0,
        },
        comment => "save hash normalization, do not attach components",
    ];

    run parameter_normalization => sub {
        my $args = { @_ };
        my $cgi = $CLASS->new_with_cgi_params(
            %{ $args->{ params }}
        );

        for my $param ( qw/ subject message clinic / ) {
            is(
                $cgi->normalized_save_value( $param ),
                $args->{ result }->{ $param },
                $args->{ comment } . ": $param",
            );
        }

        filtered_is_deeply(
            $cgi->normalized_save_hash,
            $args->{ result },
            $args->{ comment },
        );
    }
};
#}}}

#{{{ save (new and edit)
test save => sub {
    my $self = shift;

    args create_and_modify => [
        comment => "Save a new template",
        new_params => {
            message => 'This is the message',
            subject => 'This is the subject',
            name => 'A New Template',
            subject_attach => 'Before',
            message_attach => 'After',
            clinic_attach => 'Yes',
        },
        created_template => {
            message => 'This is the message',
            subject => 'This is the subject',
            name => 'A New Template',
            subject_attach => -1,
            message_attach => 1,
            clinic_attach => 1,
        },
        edit_params => {
            message => 'This is the modified message',
            subject => 'This is the modified subject',
            name => 'A Modified Template',
            subject_attach => 'After',
            message_attach => 'Before',
            clinic_attach => 'No',
        },
        modified_template => {
            message => 'This is the modified message',
            subject => 'This is the modified subject',
            name => 'A Modified Template',
            subject_attach => 1,
            message_attach => -1,
            clinic_attach => 0,
        }
    ];

    run controller => sub {
        my $args = { @_ };

        my $cgi = $CLASS->new_with_cgi_params(
            %{ $args->{ new_params }}
        );

        ok( my $results = $cgi->save, "Template saved" );
        ok( $results->{ template_id }, "New Template has an ID, and it was returned" );
        ok( my $template = eleMentalClinic::Mail::Template->retrieve( $results->{ template_id }), "Found new template");
        filtered_is_deeply(
            $template,
            $args->{ created_template },
            $args->{ comment },
        );

        $cgi = $CLASS->new_with_cgi_params(
            template_id => $template->id,
            %{ $args->{ edit_params }},
        );

        ok( $results = $cgi->save, "Template edited" );
        is( $results->{ template_id }, $template->id, "Template ID matches" );
        ok( $template = eleMentalClinic::Mail::Template->retrieve( $results->{ template_id }), "Load template");
        filtered_is_deeply(
            $template,
            $args->{ modified_template },
            "Template Modifications have been saved",
        );
    };

    run mechanized => sub {
        my $args = { @_ };
        end_trans();
        my $mech = $self->mech;

        $mech->admin_login_ok;

        $mech->get_ok( $mech->uri_for( '/notification.cgi' ));
        ok( $mech->form_name( 'chooser' ), 'find the chooser form');
        ok( $mech->click_button( value => 'New Template'), "Click on 'New Template'" );

        # Save for create, then go back and edit.
        for my $params ( $args->{ new_params }, $args->{ edit_params } ) {
            ok( $mech->form_name('template_edit'), "Find the edit form");
            $mech->set_fields( %$params );
            ok( $mech->click_button( value => 'Save' ), "Click Save" );
            for my $value ( values %$params ) {
                $mech->content_contains( $value, "Field value present" );
            }
            ok( $mech->form_name('template_edit'), "Find the edit form");
            ok( $mech->click_button( value => 'Edit' ), "Click Save" );
            ok( $mech->form_name('template_edit'), "Find the edit form");
            while ( my ( $param, $value ) = each %$params ) {
                is( $mech->value( $param ), $value, "Value for '$param' is set on edit page" );
            }
        }
    };
};
#}}}
dbinit(1);

#{{{ get_current_template
test current_template => sub {
    my $self = shift;

    args template_1001 => [
        template_id => 1001,
        template_obj => eleMentalClinic::Mail::Template->retrieve( 1001 ),
        comment => 'Working with 1001, default mail template',
    ];

    args template_1002 => [
        template_id => 1002,
        template_obj => eleMentalClinic::Mail::Template->retrieve( 1002 ),
        comment => 'Working with 1002, default appointment mail template',
    ];

    args template_1003 => [
        template_id => 1003,
        template_obj => eleMentalClinic::Mail::Template->retrieve( 1003 ),
        comment => 'Working with 1003, default renewal mail template',
    ];

    run get_current_template => sub {
        my $args = { @_ };

        my $cgi = $CLASS->new_with_cgi_params( %$args );

        is_deeply(
            $cgi->get_current_template,
            $args->{ template_obj },
            $args->{ comment } . ": get current from cgi",
        );

        is_deeply(
            $cgi->get_current_template( %$args ),
            $args->{ template_obj },
            $args->{ comment } . ": get current from function params",
        );
    };
};
#}}}

#{{{ gen_vars
test gen_vars => sub {
    my $self = shift;

    sub common_results {
        action => 'display',
        templates => eleMentalClinic::Mail::Template->get_all,
    }

    args selected => sub {
        my $fields = {
            name => 'Test Template',
            message => "Test\nTemplate\nMessage",
            subject => 'Test Template Subject',
            subject_attach => -1,
            message_attach => 1,
            clinic_attach => 0,
        };
        my $template = eleMentalClinic::Mail::Template->new($fields);
        $template->save;
        template_id => $template->id,
        results => {
            %$fields, #Some of these are overriden intentionally below.
            template_id => $template->id,
            htmlmessage => 'Test<br />Template<br />Message',
            subject_attach => 'Before',
            message_attach => 'After',
            clinic_attach => 'No',
            common_results,
        },
    };

    args 'new' => [
        'new' => 1,
        results => { common_results },
    ];

    args empty => [
        results => { common_results },
    ];

    run check_gen_vars => sub {
        my $args = { @_ };
        my $results = delete $args->{ results };
        my $cgi = $CLASS->new_with_cgi_params( %$args );

        is_deeply(
            $cgi->gen_vars,
            $results,
            "Results match when using cgi params only",
        );

        is_deeply(
            $cgi->gen_vars( %$args ),
            $results,
            "Results match when using args",
        );
    };
};
#}}}

dbinit();
