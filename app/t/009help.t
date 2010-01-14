# Copyright (C) 2004-2006 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 28;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::Help';
    $CLASSDATA = \%eleMentalClinic::Help::HELPERS;
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->insert_data;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# helpers
    can_ok( $one, 'helpers' );
    is_deeply( $one->helpers, [ qw/ default /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_helper
    can_ok( $CLASS, 'get_helper' );
    throws_ok{ $CLASS->get_helper( 'foo' )} qr/Unknown/;
    is_deeply( $CLASS->get_helper( 'default' ), { name => 'default', %{ $CLASSDATA->{ default }}});
    is_deeply( $CLASS->get_helper( 'clinic_schedule' ), { name => 'clinic_schedule', %{ $CLASSDATA->{ clinic_schedule }}});

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add
    can_ok( $one, 'add' );
    is( $one->add, undef );
    is_deeply( $one->helpers, [ qw/ default /]);

    throws_ok{ $one->add( 'foo' )} qr/Unknown helper 'foo'/;
    throws_ok{ $one->add( 'default_default' )} qr/Unknown helper 'default_default'/;

    is( $one->add( 'patient_verification' ), undef );
    is( $one->add( 'default' ), undef );

    is_deeply( $one->helpers, [ qw/ default patient_verification default /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# help
        $one = $CLASS->new;
    can_ok( $one, 'help' );

    is_deeply( $one->help, [ $CLASS->get_helper( 'default' )]);

    is( $one->add( 'clinic_schedule' ), undef );
    is_deeply( $one->help, [
        $CLASS->get_helper( 'default' ),
        $CLASS->get_helper( 'clinic_schedule' ),
    ]);

    is( $one->add( 'patient_verification' ), undef );
    is_deeply( $one->help, [
        $CLASS->get_helper( 'default' ),
        $CLASS->get_helper( 'patient_verification' ),
        $CLASS->get_helper( 'clinic_schedule' ),
    ]);

    is( $one->add( qw/ patient_appointment_new patient_lookup patient_verification patient_quick_intake / ), undef );
    is_deeply( $one->help, [
        $CLASS->get_helper( 'default' ),
        $CLASS->get_helper( 'patient_lookup' ),
        $CLASS->get_helper( 'patient_quick_intake' ),
        $CLASS->get_helper( 'patient_appointment_new' ),
        $CLASS->get_helper( 'patient_verification' ),
        $CLASS->get_helper( 'clinic_schedule' ),
    ]);

    is( $one->add( 'clinic_schedule' ), undef );
    is_deeply( $one->help, [
        $CLASS->get_helper( 'default' ),
        $CLASS->get_helper( 'patient_lookup' ),
        $CLASS->get_helper( 'patient_quick_intake' ),
        $CLASS->get_helper( 'patient_appointment_new' ),
        $CLASS->get_helper( 'patient_verification' ),
        $CLASS->get_helper( 'clinic_schedule' ),
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
