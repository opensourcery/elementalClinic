# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 139;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Department;

our ($CLASS, $CLASSDATA, $one, $count, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Insurance';
    use_ok( $CLASS );
    $CLASSDATA = $client_insurance;
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
# table info
    is( $one->table, 'client_insurance');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id client_id rolodex_insurance_id rank
        carrier_type carrier_contact
        insurance_name insurance_id patient_insurance_id
        insured_name insured_fname insured_lname
        insured_mname insured_name_suffix
        insured_relationship_id insured_addr
        insured_addr2 insured_city insured_state insured_postcode
        insured_phone insured_group insured_group_id insured_dob
        insured_sex insured_employer insurance_type_id
        other_plan other_name other_group other_dob
        other_sex other_employer other_plan_name
        co_pay_amount
        deductible_amount license_required
        comment_text start_date end_date
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# role_name
    can_ok( $one, 'role_name' );
    is( $one->role_name, undef );

        $one->carrier_type( 'dental' );
    is( $one->role_name, 'dental_insurance' );

        $one->carrier_type( 'medical' );
    is( $one->role_name, 'medical_insurance' );

        $one->carrier_type( 'mental health' );
    is( $one->role_name, 'mental_health_insurance' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# contact
    can_ok( $one, 'contact' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_active
    can_ok( $one, 'is_active' );
    is( $CLASS->retrieve( 1001 )->is_active, 0 );
    is( $CLASS->retrieve( 1002 )->is_active, 0 );
    is( $CLASS->retrieve( 1003 )->is_active, 1 );
    is( $CLASS->retrieve( 1004 )->is_active, 1 );
    is( $CLASS->retrieve( 1005 )->is_active, 0 );
    is( $CLASS->retrieve( 1006 )->is_active, 0 );
    is( $CLASS->retrieve( 1007 )->is_active, 1 );
    is( $CLASS->retrieve( 1008 )->is_active, 0 );
    is( $CLASS->retrieve( 1009 )->is_active, 0 );
    is( $CLASS->retrieve( 1010 )->is_active, 1 );
    is( $CLASS->retrieve( 1011 )->is_active, 1 );
    is( $CLASS->retrieve( 1012 )->is_active, 0 );
    is( $CLASS->retrieve( 1013 )->is_active, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_active:  bug-fix, shouldn't depend on date format
        $one = $CLASS->retrieve( 1003 );
    is( $one->is_active, 1 );
    is( $one->is_active( '2006-10-01' ), 1 );

        $one->end_date( '2006-07-04' );
    is( $one->is_active( '2006-10-01' ), 0 );
        $one->end_date( '2006-7-4' );
    is( $one->is_active( '2006-10-01' ), 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# active_insurance_clause 
        $tmp = $one->today;
    can_ok( $CLASS, 'active_insurance_clause' );

    # no active specified
    is( $CLASS->active_insurance_clause,
        qq/ AND date( '$tmp' ) >= client_insurance.start_date
        AND( client_insurance.end_date IS NULL OR date( '$tmp' ) <= client_insurance.end_date )/
    );
    is( $CLASS->active_insurance_clause( '2006-01-01' ),
        q/ AND date( '2006-01-01' ) >= client_insurance.start_date
        AND( client_insurance.end_date IS NULL OR date( '2006-01-01' ) <= client_insurance.end_date )/
    );

    # active is true -- same result
    is( $CLASS->active_insurance_clause,
        qq/ AND date( '$tmp' ) >= client_insurance.start_date
        AND( client_insurance.end_date IS NULL OR date( '$tmp' ) <= client_insurance.end_date )/
    );
    is( $CLASS->active_insurance_clause( '2006-01-01' ),
        q/ AND date( '2006-01-01' ) >= client_insurance.start_date
        AND( client_insurance.end_date IS NULL OR date( '2006-01-01' ) <= client_insurance.end_date )/
    );

    # active is zero, use NOT
    is( $CLASS->active_insurance_clause( undef, 0 ),
        qq/ AND NOT( date( '$tmp' ) >= client_insurance.start_date
        AND( client_insurance.end_date IS NULL OR date( '$tmp' ) <= client_insurance.end_date ) )/
    );
    is( $CLASS->active_insurance_clause( '2006-01-01', 0 ),
        q/ AND NOT( date( '2006-01-01' ) >= client_insurance.start_date
        AND( client_insurance.end_date IS NULL OR date( '2006-01-01' ) <= client_insurance.end_date ) )/
    );

    # active is undef, is ignored
    is( $CLASS->active_insurance_clause( undef, undef ),
        qq/ AND date( '$tmp' ) >= client_insurance.start_date
        AND( client_insurance.end_date IS NULL OR date( '$tmp' ) <= client_insurance.end_date )/
    );
    is( $CLASS->active_insurance_clause( '2006-01-01', undef ),
        q/ AND date( '2006-01-01' ) >= client_insurance.start_date
        AND( client_insurance.end_date IS NULL OR date( '2006-01-01' ) <= client_insurance.end_date )/
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# mh_provider
    can_ok( $CLASS, 'mh_provider' );

    is( $CLASS->mh_provider, undef );
    is( $CLASS->mh_provider( 1001 ), undef );
    is( $CLASS->mh_provider( undef, '1985-05-30' ), undef );

    is( $CLASS->mh_provider( 6666, '1985-05-30' ), undef );

    # one result
        $tmp = $CLASS->mh_provider( 1001, '1985-05-30' );
    is_deeply( $tmp, $CLASSDATA->{ 1006 } );
    isa_ok( $tmp, $CLASS );

    # multiple results
        $tmp = $CLASS->mh_provider( 1003, '2003-02-15' );
    is_deeply( $CLASS->mh_provider( 1003, '2003-02-15' ), $CLASSDATA->{ 1003 } );
    isa_ok( $CLASS->mh_provider( 1003, '2003-02-15' ), $CLASS );

    # single result, date = start_date
        $tmp = $CLASS->mh_provider( 1003, $CLASSDATA->{ 1004 }{ start_date } );
    is_deeply( $tmp, $CLASSDATA->{ 1004 } );
    isa_ok( $tmp, $CLASS );

    # single result, date = end_date
        $tmp = $CLASS->mh_provider( 1001, $CLASSDATA->{ 1006 }{ end_date } );
    is_deeply( $tmp, $CLASSDATA->{ 1006 } );
    isa_ok( $tmp, $CLASS );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# getall_bytype
    can_ok( $CLASS, 'getall_bytype' );
    throws_ok{ $CLASS->getall_bytype } qr/Client id and type are required/;
    
    throws_ok{ $CLASS->getall_bytype( 666 )} qr/Client id and type are required/;
    is( $CLASS->getall_bytype( 666, 'foo' ), undef );

    # 1001, mental health
    is_deeply( $one->getall_bytype( 1001, 'mental health' ), [
        $CLASSDATA->{ 1006 },
    ]);
    isa_ok( $_, $CLASS ) for @{ $one->getall_bytype( 1001, 'mental health' )};

    # 1001, medical
    is( $one->getall_bytype( 1001, 'medical' ), undef );

    # 1003, mental health
    is_deeply( $one->getall_bytype( 1003, 'mental health' ), [
        $CLASSDATA->{ 1003 },
        $CLASSDATA->{ 1004 },
        $CLASSDATA->{ 1005 },
    ] );
    isa_ok( $_, $CLASS ) for @{ $one->getall_bytype( 1003, 'mental health' )};

    # passing 'active' flag
    # 1001, mental health
    is( $one->getall_bytype( 1001, 'mental health', 1 ), undef );
    is_deeply( $one->getall_bytype( 1001, 'mental health', 0 ), [
        $CLASSDATA->{ 1006 },
    ]);

    # 1003, mental health
    is_deeply( $one->getall_bytype( 1003, 'mental health', 1 ), [
        $CLASSDATA->{ 1003 },
        $CLASSDATA->{ 1004 },
    ]);
    is_deeply( $one->getall_bytype( 1003, 'mental health', 0 ), [
        $CLASSDATA->{ 1005 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex_id
        $one = $CLASS->new;
    can_ok( $one, 'rolodex_id' );

    is( $one->rolodex_id, undef );

        $one = $CLASS->new({ carrier_type => 'mental health' });
    is( $one->rolodex_id, undef );

        $one = $CLASS->new({ rolodex_insurance_id => 1001 });
    is( $one->rolodex_id, undef );

        $one = $CLASS->new({
            carrier_type => 'mental health',
            rolodex_insurance_id => 6666,
        });
    is( $one->rolodex_id, undef );

        $one = $CLASS->new({
            carrier_type => 'mental health',
            rolodex_insurance_id => 1001,
        });

    is_deeply(
        $one->rolodex_id,
        $rolodex_mental_health_insurance->{ 1001 }->{ rolodex_id }
    );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# authorization
    can_ok( $one, 'authorization' );
    is( $one->authorization, undef );

    # this little client has none
        $one->id( 1001 )->retrieve;
    is( $one->authorization, undef );

        $one->id( 1003 )->retrieve;

    # XXX: these are time-dependent tests. You will be forced to change these
    #      every year.
    # by default, gets only active
    is_deeply( $one->authorization,
        $client_insurance_authorization->{ 1017 },
    );
    
    # when asked, gets all in reverse order
    is_deeply( $one->authorization('2007-01-01'),
        $client_insurance_authorization->{ 1004 },
    );
    is_deeply( $one->authorization( '2006-07-01' ), 
        $client_insurance_authorization->{ 1004 },
    );
    is_deeply( $one->authorization( '2005-07-01' ), 
        $client_insurance_authorization->{ 1003 },
    );
    # legacy: "all" flag should be ignored
    is_deeply( $one->authorization( '2005-07-01', 'all' ), 
        $client_insurance_authorization->{ 1003 },
    );

    # too far in past -- none
    is( $one->authorization( '2000-01-01' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# all_authorizations
        $one = $CLASS->new;
    can_ok( $one, 'all_authorizations' );
    is( $one->all_authorizations, undef );

        $one->id( 1001 )->retrieve;
    is( $one->all_authorizations, undef );

        $one->id( 1003 )->retrieve;
    # when asked, gets all in reverse order
    is_deeply( $one->all_authorizations, [
        $client_insurance_authorization->{ 1017 },
        $client_insurance_authorization->{ 1004 },
        $client_insurance_authorization->{ 1003 },
        $client_insurance_authorization->{ 1002 },
        $client_insurance_authorization->{ 1001 },
    ]);
    # ignores data
    is_deeply( $one->all_authorizations( '2005-07-01' ), [
        $client_insurance_authorization->{ 1017 },
        $client_insurance_authorization->{ 1004 },
        $client_insurance_authorization->{ 1003 },
        $client_insurance_authorization->{ 1002 },
        $client_insurance_authorization->{ 1001 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    can_ok( $one, 'save' );

        $count = scalar keys %{ $CLASSDATA };
    is( $test->select_count( $CLASS->table ), $count );

    # save with no carrier_type or rank
        $one = $CLASS->new({
            client_id            => 1002,
            rolodex_insurance_id => 1001,
        });
    ok( $one->save );

        $count++;
    is( $test->select_count( $CLASS->table ), $count );

    # save with carrier_type and rank of Other
        $one = $CLASS->new({
            client_id            => 1002,
            rolodex_insurance_id => 1001,
            carrier_type         => 'mental health',
            rank                 => 3,
        });
    ok( $one->save );
        $count++;
    is( $test->select_count( $CLASS->table ), $count );

    # save a dental as Primary, it's the first
        my %ids;
        $one = $CLASS->new({
            client_id            => 1001,
            rolodex_insurance_id => 1001,
            carrier_type         => 'dental',
            rank                 => 1,
        });
    ok( $one->save );
        $count++;
    is( $test->select_count( $CLASS->table ), $count );

        $ids{ primary_1 } = $one->id;
    # current one is Primary
    is( $CLASS->new({ rec_id => $one->id })->retrieve->rank, 1 );

    # save a dental as Primary, moves previous one to Other
        $one->rec_id( '' );
    ok( $one->save );
        $count++;
    is( $test->select_count( $CLASS->table ), $count );

        $ids{ primary_2 } = $one->id;
    # current one is Primary
    is( $CLASS->new({ rec_id => $one->id })->retrieve->rank, 1 );
    # previous one is Other
    is( $CLASS->new({ rec_id => $ids{ primary_1} })->retrieve->rank, 1 );

    # save a dental as Secondary, it's the first
        $one = $CLASS->new({
            client_id            => 1001,
            rolodex_insurance_id => 1001,
            carrier_type         => 'dental',
            rank                 => 2,
        });
    ok( $one->save );
        $count++;
    is( $test->select_count( $CLASS->table ), $count );

        $ids{ secondary_1 } = $one->id;
    # current one is Secondary
    is( $CLASS->new({ rec_id => $one->id })->retrieve->rank, 2 );

    # save a dental as Secondary, moves previous one to Other
        $one->rec_id( '' );
    ok( $one->save );
        $count++;
    is( $test->select_count( $CLASS->table ), $count );

        $ids{ secondary_2 } = $one->id;
    # current one is Secondary
    is( $CLASS->new({ rec_id => $one->id })->retrieve->rank, 2 );
    # previous one is Other
    is( $CLASS->new({ rec_id => $ids{ secondary_1} })->retrieve->rank, 2 );
    # primary one isn't changed
    is( $CLASS->new({ rec_id => $ids{ primary_2} })->retrieve->rank, 1 );
    # neither is other Other
    is( $CLASS->new({ rec_id => $ids{ primary_1} })->retrieve->rank, 1 );

    # save a dental as Other, no effect on others
        $one = $CLASS->new({
            client_id            => 1001,
            rolodex_insurance_id => 1001,
            carrier_type         => 'dental',
            rank                 => 3,
        });
    ok( $one->save );
        $count++;
    is( $test->select_count( $CLASS->table ), $count );

    # all others as before
    is( $CLASS->new({ rec_id => $ids{ secondary_2 } })->retrieve->rank, 2 );
    is( $CLASS->new({ rec_id => $ids{ secondary_1 } })->retrieve->rank, 2 );
    is( $CLASS->new({ rec_id => $ids{ primary_2 } })->retrieve->rank, 1 );
    is( $CLASS->new({ rec_id => $ids{ primary_1 } })->retrieve->rank, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_authorized_insurers
    can_ok( $CLASS, 'get_authorized_insurers' );
    throws_ok{ $CLASS->get_authorized_insurers } qr/required/;

    is( $CLASS->get_authorized_insurers( 666 ), undef );
    is( $CLASS->get_authorized_insurers( 666, 'mental health' ), undef );
    is( $CLASS->get_authorized_insurers( 666, 'mental health', '2006-01-01' ), undef );

    is( $CLASS->get_authorized_insurers( 1001 ), undef );
    is( $CLASS->get_authorized_insurers( 1001, undef, '2006-01-01' ), undef );

    is( $CLASS->get_authorized_insurers( 1003, 'mental_health', '2006-01-01' ), undef );
    is( $CLASS->get_authorized_insurers( 1003, undef, '2100-01-01' ), undef );
    is_deeply( $CLASS->get_authorized_insurers( 1003, undef, '2006-01-01' ), [
        $CLASSDATA->{ 1003 },
        $CLASSDATA->{ 1004 },
    ]);
    is_deeply( $CLASS->get_authorized_insurers( 1003, 'mental health', '2006-01-01' ), [
        $CLASSDATA->{ 1003 },
        $CLASSDATA->{ 1004 },
    ]);
    # check that the client_insurance is still found when the date = client_insurance.start_date
    is_deeply( $CLASS->get_authorized_insurers( 1003, 'mental health', '2003-01-01' ), [
        $CLASSDATA->{ 1003 },
    ]);

    # insurance 1013 has an active auth for this date, but the insurance dates
    # are out of range, so it's not included
    is_deeply( $CLASS->get_authorized_insurers( 1004, 'mental health', '2006-02-01' ), [
        $CLASSDATA->{ 1007 },
        $CLASSDATA->{ 1008 },
    ]);
    isa_ok( $_, $CLASS )
        for @{ $CLASS->get_authorized_insurers( 1004, 'mental health', '2006-02-01' )};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# other_authorized_insurers
    can_ok( $one, 'other_authorized_insurers' );
    is( $one->other_authorized_insurers, undef );

        $one = $CLASS->retrieve( 1003 );
    # test with no date
    is( $one->other_authorized_insurers, undef );
    # test with a date out of any authorization range
    is( $one->other_authorized_insurers( '2008-05-01' ), undef );

    # test with a date that should pick up 1 record (2nd insurance is self, 3rd insurance has no auth)
    is_deeply( $one->other_authorized_insurers( '2006-05-01' ), [
        $CLASSDATA->{ 1004 },
    ]);

        # test with a date that is only in one insurance's auth range
    is_deeply( $one->other_authorized_insurers( '2007-02-01' ), [
        $CLASSDATA->{ 1004 },
    ]);

        # test that we don't pick up inactive insurances, even if they have an auth
        $one = $CLASS->retrieve( 1007 );
    is_deeply( $one->other_authorized_insurers( '2005-03-01' ), [
        $CLASSDATA->{ 1008 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

