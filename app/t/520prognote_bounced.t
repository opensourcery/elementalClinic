# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 59;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::ProgressNote::Bounced';
    use_ok( $CLASS );
    $CLASSDATA = $prognote_bounced;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->empty );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'prognote_bounced' );
    is( $one->primary_key, 'rec_id' );
    is_deeply( $one->fields, [qw/
        rec_id prognote_id bounced_by_staff_id bounce_date bounce_message
        response_date response_message
    /]);
    is_deeply( $one->fields_required, [qw/
        prognote_id bounced_by_staff_id bounce_message
    /]);
    is_deeply( [ sort @{ $CLASS->fields } ], $test->db_fields( $CLASS->table ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get all active
    can_ok( $CLASS, 'get_active' );
    is( scalar @{ $CLASS->get_active }, 3 );
    is_deeply( $CLASS->get_active, [
        $prognote_bounced->{ 1003 },
        $prognote_bounced->{ 1004 },
        $prognote_bounced->{ 1006 },
    ]);
    isa_ok( $_, $CLASS ) for @{ $CLASS->get_active };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get by prognote
    can_ok( $CLASS, 'get_by_prognote_id' );
    is( $CLASS->get_by_prognote_id, undef );
    is( $CLASS->get_by_prognote_id( 666 ), undef );
    is( $CLASS->get_by_prognote_id( 1043 ), undef );

    ok( eleMentalClinic::ProgressNote->retrieve( 1043 )->bounce(
        eleMentalClinic::Personnel->retrieve( 1004 ),
        'Rules, rules, rules.'
    ));

    ok( $CLASS->get_by_prognote_id( 1043 ));
    isa_ok( $CLASS->get_by_prognote_id( 1043 ), $CLASS );

    is( $CLASS->get_by_prognote_id( 1043 )->prognote_id, 1043 );
    is( $CLASS->get_by_prognote_id( 1043 )->bounced_by_staff_id, 1004 );
    is( $CLASS->get_by_prognote_id( 1043 )->bounce_message, 'Rules, rules, rules.' );

    is( $CLASS->get_by_prognote_id( 1243 ), undef );
    is( $CLASS->get_by_prognote_id( 1244 ), undef );
    is_deeply( $CLASS->get_by_prognote_id( 1245 ), $CLASSDATA->{ 1003 });
    is_deeply( $CLASS->get_by_prognote_id( 1257 ), $CLASSDATA->{ 1004 });
    is( $CLASS->get_by_prognote_id( 1258 ), undef );
    is_deeply( $CLASS->get_by_prognote_id( 1259 ), $CLASSDATA->{ 1006 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prognote
        $one = $CLASS->empty;
    can_ok( $one, 'prognote' );
    throws_ok{ $one->prognote } qr/Must be called on a ProgressNote::Bounced object/;

        $one = $CLASS->get_by_prognote_id( 1043 );
    is_deeply( $one->prognote, $prognote->{ 1043 });
    isa_ok( $one->prognote, 'eleMentalClinic::ProgressNote' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get all active
    can_ok( $CLASS, 'get_active' );
    is( scalar @{ $CLASS->get_active }, 4 );
    is_deeply_except({ rec_id => qr/\d+/ },
        [ @{ $CLASS->get_active }[ -1 ]],
        [{
            rec_id              => 666,
            prognote_id         => 1043,
            bounced_by_staff_id => 1004,
            bounce_date         => $CLASS->today,
            bounce_message      => 'Rules, rules, rules.',
            response_date       => undef,
            response_message    => undef,
        }]
    );
    isa_ok( $_, $CLASS ) for @{ $CLASS->get_active };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get by staff
    can_ok( $CLASS, 'get_by_data_entry_id' );
    is( $CLASS->get_by_data_entry_id, undef );
    is( $CLASS->get_by_data_entry_id( 666 ), undef );

    # this note was bounced above in the test file, and so we don't know its ID 
    is( scalar @{ $CLASS->get_by_data_entry_id( 1001 )}, 1 ); 
    is_deeply( $CLASS->get_by_data_entry_id( 1002 ), [
        $prognote_bounced->{ 1003 },
        $prognote_bounced->{ 1004 },
        $prognote_bounced->{ 1006 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# overdue
        $one = $CLASS->empty;
    can_ok( $one, 'overdue' );
    throws_ok{ $one->overdue } qr/Must be called on a ProgressNote::Bounced object/;

    is( $CLASS->retrieve( 1001 )->overdue, 0 );
    is( $CLASS->retrieve( 1002 )->overdue, 0 );
    is( $CLASS->retrieve( 1003 )->overdue, 1 );
    is( $CLASS->retrieve( 1004 )->overdue, 1 );
    is( $CLASS->retrieve( 1005 )->overdue, 0 );
    is( $CLASS->retrieve( 1006 )->overdue, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# verification and cleanup
        $one = $CLASS->get_by_prognote_id( 1043 );
        $one->response_date( $one->today )->save;
    is( scalar @{ $CLASS->get_active }, 3 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
