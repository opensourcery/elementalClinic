# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 38;
use Data::Dumper;
use eleMentalClinic::Test;
use Date::Calc qw/ Add_Delta_Days Today /;

our ($CLASS, $DATA, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Financial::ClaimsProcessor';
    use_ok( $CLASS );
    $DATA = $claims_processor;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->insert_data;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'claims_processor');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id interchange_id_qualifier interchange_id
        code name primary_id clinic_trading_partner_id
        clinic_submitter_id
        requires_rendering_provider_ids template_837 
        password_active_days password_expires password_min_char 
        username password sftp_host sftp_port
        dialup_number get_directory put_directory send_personnel_id
        send_production_files
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bump password expiration when saving new password
        $one = $CLASS->new({
            name                 => 'Test',
            username             => 'treebeard',
            password             => 'draught',
            password_expires     => '2006-01-01',
        })->save;

    # shouldn't update date automatically if we don't have an increment
        $one->update({
            password    => 'Meriadoc',
        });
    is( $one->password_expires, '2006-01-01' );

    # ditto, and should save any incoming date, even if it doesn't make sense
        $one->update({
            password    => 'M3r14d0c',
            password_expires    => '2006-02-01',
        });
    is( $one->password_expires, '2006-02-01' );

    # if we don't have an increment, don't bump the expiration date, and allow it to be inserted
        $one->password_active_days( 10 )->save;

        $tmp = join '-' => Add_Delta_Days( Today, $one->password_active_days );
    ok( $one->password( 'Pippin' )->save );
    is( $one->password, 'Pippin' );
    is( $one->password_expires, $tmp );

    # change increment, but don't change password
    ok( $one->password_active_days( 60 )->save );
    ok( $one->password( 'Pippin' )->save );
    is( $one->password_expires, $tmp );

    # now we change the password, and the date bumps
        $tmp = join '-' => Add_Delta_Days( Today, $one->password_active_days );
    ok( $one->password( 'P1pp1n' )->save );
    is( $one->password_expires, $tmp );

        $one->delete;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# has password expired?
        $one = $CLASS->new;
    can_ok( $one, 'password_expired' );
    ok( $CLASS->retrieve( 1001 )->password_expired );
    ok( $CLASS->retrieve( 1002 )->password_expired );
    ok( $CLASS->retrieve( 1003 )->password_expired );

    like( $CLASS->retrieve( 1001 )->password_expired, qr/\d+/ );
    like( $CLASS->retrieve( 1002 )->password_expired, qr/\d+/ );
    like( $CLASS->retrieve( 1003 )->password_expired, qr/\d+/ );

    is( $CLASS->retrieve( 1001 )->password_expired( '2006-01-01' ), 0 );
    is( $CLASS->retrieve( 1002 )->password_expired( '2006-01-01' ), 0 );
    is( $CLASS->retrieve( 1003 )->password_expired( '2006-01-01' ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# by password expiration
        $one = $CLASS->new;
    can_ok( $CLASS, 'get_by_password_expiration' );
    is_deeply( $CLASS->get_by_password_expiration, [
        $DATA->{ 1003 },
        $DATA->{ 1001 },
        $DATA->{ 1002 },
    ]);
    isa_ok( $_, $CLASS )
        for @{ $CLASS->get_by_password_expiration };

    is( $CLASS->get_by_password_expiration( '2005-12-31' ), undef );
    is_deeply( $CLASS->get_by_password_expiration( '2006-03-15' ), [
        $DATA->{ 1003 },
    ]);
    isa_ok( $_, $CLASS )
        for @{ $CLASS->get_by_password_expiration( '2006-03-15' ) };

        $one->id( 1001 )->retrieve->password_expires( '2100-01-01' )->save;
        $one->id( 1003 )->retrieve->password_expires( '2100-01-01' )->save;
    is_deeply( $CLASS->get_by_password_expiration, [
        $DATA->{ 1002 },
    ]);
    isa_ok( $_, $CLASS )
        for @{ $CLASS->get_by_password_expiration };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
