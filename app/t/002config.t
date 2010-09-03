# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 99;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Config';
    use_ok( $CLASS );
}

sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Transaction cannot be started until further into the tests.
# Do not modify/save until dbinit it called.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'config');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id dept_id name value
    /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ok( ! $one->stage1_complete );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# config path variables are set ok and accessor works
    can_ok( $one, 'config_path' );
    $one->config_path('./config.yaml');
    is( $one->config_path, './config.yaml' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# changing variables doesn't affect singleton unless we force a reload
        $one = $CLASS->new;
    is( $one->config_path, './config.yaml' );
    $one->config_path('foo');
    ok( $one = $CLASS->new );
    is( $one->config_path, 'foo');

    throws_ok{ $one = $CLASS->new->stage1 }
        qr/Cannot read /;
    ok( !$one->stage1_complete );

    $one->config_path('./config.yaml');
    ok( $one = $CLASS->new );
    is( $one->config_path, './config.yaml' );

    $one->config_path('etc/config.yaml');

    ok( $one = $CLASS->new->stage1 );
    ok( $one->stage1_complete );

    is( $one->config_path, 'etc/config.yaml' );
        $one->reset;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# checking default config in local distribution
# most of this is in 002config_defaults.t now

    can_ok( $one, 'stage1' );
    ok( $one->stage1 );
    ok( $one->stage1_complete );

    my $defaults = { $one->defaults->stage1 };


# template_path and friends
{
    is $one->template_path,
       $defaults->{themes_dir}->subdir('Default/templates');

    # default template path
    can_ok( $one, 'default_template_path' );
    is(
        $one->default_template_path,
        $defaults->{themes_dir}->subdir('Default/templates'),
    );

    $one->theme( 'foo' );
    is $one->theme, 'foo' , 'set the theme';

    is $one->template_path,
       $defaults->{themes_dir}->subdir('foo/templates'),
       'theme change reflected in template_path';

    is $one->default_template_path,
       $defaults->{themes_dir}->subdir('Default/templates'),
       '  default_template_path unchanged';

    is $one->local_template_path,
       $defaults->{themes_dir}->subdir('Local/templates'),
       '  and local_template_path';

    # Put the theme back
    $one->theme( 'Default' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make sure stage1 isn't redone unless we force it
        $one->theme( 'foo' );
        $one->stage1;
    is( $one->theme, 'foo' );

        $one->stage1({ force_reload => 1 });
    is( $one->theme, 'Default' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# see if there's a local config
    $one->config_path('./config.yaml');
    ok( $one = $CLASS->new->stage1({ force_reload => 1 }) );

    # we can only assume so many things about the local config
    ok( $one->theme );
    ok( $one->dbname );
    ok( $one->dbuser );

    isnt( $one->dbname, 'DATABASE' );
    isnt( $one->dbuser, 'USER' );
    isnt( $one->passwd, 'PASSWORD' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# now that the local config is loaded, we can connect to a database for real
# stage 2 config

    # Now that we have done the pre-config stuff we can load the real personnel object.
    dbinit( 1 );

    can_ok( $one, 'stage2' );
    ok( $one->stage2 );

    can_ok( $one, qw/
        form_method
        logout_time logout_inactive
        edit_prognote prognote_min_duration_minutes prognote_max_duration_minutes
        org_name
        send_mail_as
        appointment_template renewal_template
        default_mail_template
        renewal_notification_days appointment_notification_days
        password_expiration_days
        enable_role_reports
        quick_schedule_availability
    / );

    is( $one->form_method       , 'post' );
    is( $one->logout_time       , 240 );
    is( $one->logout_inactive   , 525600 );
    is( $one->edit_prognote     , 1 );
    is( $one->org_name          , 'Our Clinic' );
    is( $one->prognote_min_duration_minutes , 1 );
    is( $one->prognote_max_duration_minutes , 480 );
    is( $one->appointment_template , 1002 );
    is( $one->renewal_template  , 1001 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# checking the theme, reloading it
    can_ok( $one, 'Theme' );
    isa_ok( $one->Theme, 'eleMentalClinic::Theme' );
    throws_ok{ $one->Theme( 'foo' )}
        qr/Validation failed for 'eleMentalClinic::Theme'/;
    ok( $one->Theme( eleMentalClinic::Theme->new ));

    # is a singleton
        $tmp = $one->Theme;
    is( $tmp, $one->Theme );
    #isnt( $one->Theme( eleMentalClinic::Theme->_new_instance ), $one->Theme );

    is( $one->Theme->name, 'Default' );
    ok( $one->Theme->name( 'foo' ));
    is( $one->Theme->name, 'foo' );

    # can reload theme
    can_ok( $one, 'reload_theme' );

    ok( $one->reload_theme );
    #isnt( $tmp, $one->Theme );
    is( $one->Theme->name, 'Default' );

        $tmp = $one->Theme;
    ok( $one->reload_theme( 'Test' ));
    #isnt( $tmp, $one->Theme );
    is( $one->Theme->name, 'Test' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Transaction starts here, OK to save config below this point.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit( 1 );

    can_ok( $one, 'save' );
    is( $one->save, undef );
    
    throws_ok{ $one->save( 1 )} qr/Hashref required/;
    throws_ok{ $one->save([ 1 ])} qr/Hashref required/;

    ok( $one->save({
        form_method       => 'get',
        logout_time       => 120,
        logout_inactive   => 5,
        edit_prognote     => 0,
        org_name          => 'Our Clinic, LLC',
        prognote_min_duration_minutes => 2,
        prognote_max_duration_minutes => 420,
    }));

    is( $one->form_method       , 'get' );
    is( $one->logout_time       , 120 );
    is( $one->logout_inactive   , 5 );
    is( $one->edit_prognote     , 0 );
    is( $one->org_name          , 'Our Clinic, LLC' );
    is( $one->prognote_min_duration_minutes , 2 );
    is( $one->prognote_max_duration_minutes , 420 );
    is( $one->enable_role_reports, undef );
    is( $one->quick_schedule_availability, 1 );

    # test saving with a field that is empty, make sure the singleton gets updated
    ok( $one->save({
        org_name          => undef,
    }));

    ok( $one = $CLASS->new );
    is( $one->org_name, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ok( $one->save({
        form_method       => 'post',
        logout_time       => 240,
        logout_inactive   => 525600,
        edit_prognote     => 1,
        org_name          => 'Our Clinic',
        prognote_min_duration_minutes => 1,
        prognote_max_duration_minutes => 480,
    }));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# using accessors to change values
    ok( $one->theme( 'Foo' ));
    is( $one->theme, 'Foo' );

    ok( $one = $CLASS->new->stage2 );
    is( $one->theme, 'Foo' );

        require_ok( $CLASS );
    ok( $CLASS->new->stage2->theme, 'Foo' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# getting revision
    can_ok( $one, 'revision' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Initilizing a key
    is(
        $one->db->do_sql(
            "SELECT * FROM config WHERE name = 'form_method'"
        )->[0]->{ name },
        'form_method',
        "Row Created"
    );
    $one->db->do_sql( "DELETE FROM config WHERE name = 'form_method'", 1 );
    is(
        $one->db->do_sql(
            "SELECT * FROM config WHERE name = 'form_method'"
        )->[0],
        undef,
        "Row deleted"
    );
    ok( $one->stage2, "refresh" );
    is( $one->form_method, undef, "form_method row was deleted." );
    ok( $one->form_method( 'get' ), 'set ok' );
    $one->save({ form_method => 'get' });
    is( $one->form_method, 'get', 'correct value after set' );
    my $row = $one->db->do_sql(
        "SELECT * FROM config WHERE name = 'form_method'"
    )->[0];
    is( $row->{ name }, 'form_method', "Row Created" );
    is( $row->{ value }, 'get', "Row set" );
    ok( $one->stage2, "refresh" );
    is( $one->form_method, 'get', 'correct value after refresh' );

dbinit( 0 );
