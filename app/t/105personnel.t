# vim: ts=4 sts=4 sw=4
# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 256;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::Role;

our ($CLASS, $one, $tmp );
BEGIN {
    *CLASS = \'eleMentalClinic::Personnel';
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
# table info
    is( $one->table, 'personnel');
    is( $one->primary_key, 'staff_id');
    is_deeply( $one->fields, [qw/
        staff_id unit_id dept_id
        login password prefs home_page_type
        fname mname lname name_suffix ssn dob
        addr city state zip_code home_phone work_phone work_phone_ext work_fax
        job_title date_employ super_visor super_visor_2 over_time with_hold
        work_hours rolodex_treaters_id hours_week
        marital_status race sex next_kin 
        us_citizen cdl credentials
        admin_id
        supervisor_id
        productivity_week productivity_month productivity_year productivity_last_update
        taxonomy_code medicaid_provider_number medicare_provider_number national_provider_id
        password_set password_expired
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# roles
    can_ok( $one, map { $a = $_; $a =~ s/\s+/_/; $a } @{ $CLASS->security_fields } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# partial intakes
    can_ok( $one, 'clients_intake_incomplete' );
    is( $one->clients_intake_incomplete, undef );

        eleMentalClinic::Client->retrieve( 1001 )->update({ intake_step => 1 });
    is_deeply_except({ intake_step => undef }, $one->clients_intake_incomplete, [
        $client->{ 1001 },
    ]);

        eleMentalClinic::Client->retrieve( 1004 )->update({ intake_step => 1 });
    is_deeply_except({ intake_step => undef }, $one->clients_intake_incomplete, [
        $client->{ 1001 },
        $client->{ 1004 },
    ]);

        eleMentalClinic::Client->retrieve( 1001 )->update({ intake_step => undef });
        eleMentalClinic::Client->retrieve( 1004 )->update({ intake_step => undef });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# trying it with a new client
        $tmp = eleMentalClinic::Client->new({
            fname => 'Joe',
            lname => 'Test',
        });
        $tmp->save;
    is( $one->clients_intake_incomplete, undef );
        $tmp->update({ intake_step => 2 });

    ok( $one->clients_intake_incomplete );
    is_deeply_except({ intake_step => undef }, $one->clients_intake_incomplete, [
        $tmp
    ]);

        eleMentalClinic::Client->retrieve( 1004 )->update({ intake_step => 1 });
    is_deeply_except({ intake_step => undef }, $one->clients_intake_incomplete, [
        $client->{ 1004 },
        $tmp,
    ]);

        eleMentalClinic::Client->retrieve( 1004 )->update({ intake_step => undef });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bounced_notes
    can_ok( $one, 'bounced_prognotes' );
    is( $CLASS->retrieve( 1001 )->bounced_prognotes, undef );
    is_deeply( $CLASS->retrieve( 1002 )->bounced_prognotes, [
        $prognote_bounced->{ 1003 },
        $prognote_bounced->{ 1004 },
        $prognote_bounced->{ 1006 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Supervisor
    can_ok( $one, 'Supervisor' );
    is( $one->staff_id( 1 )->retrieve->Supervisor, undef );

    isa_ok( $one->staff_id( $_ )->retrieve->Supervisor, $CLASS )
        for 1001..1005;

    is( $one->staff_id( 1001 )->retrieve->Supervisor->staff_id, $personnel->{ 1001 }->{ supervisor_id } );
    is( $one->staff_id( 1002 )->retrieve->Supervisor->staff_id, $personnel->{ 1002 }->{ supervisor_id } );
    is( $one->staff_id( 1003 )->retrieve->Supervisor->staff_id, $personnel->{ 1003 }->{ supervisor_id } );

    is( $one->staff_id( 1001 )->retrieve->Supervisor->staff_id, 1005 );
    is( $one->staff_id( 1002 )->retrieve->Supervisor->staff_id, 1005 );
    is( $one->staff_id( 1003 )->retrieve->Supervisor->staff_id, 1005 );

    is( $one->staff_id( 1004 )->retrieve->Supervisor->staff_id, 1 );
    is( $one->staff_id( 1005 )->retrieve->Supervisor->staff_id, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# crypt_password
    can_ok( $one, 'crypt_password' );

    throws_ok{ $one->crypt_password } qr/Login and password are required./;
    throws_ok{ $one->crypt_password( 'foo' )} qr/Login and password are required./;
    throws_ok{ $one->crypt_password( 'foo', 0 )} qr/Login and password are required./;
    throws_ok{ $one->crypt_password( 0, 'foo' )} qr/Login and password are required./;
    ok( $one->crypt_password( 'foo', 'foo' ));

    isnt(
        $one->crypt_password( 'login', '1234567' ),
        $one->crypt_password( 'login', '12345678' ),
    );
    # leftover TODO tests from before crypt refactor
    isnt(
        $one->crypt_password( 'login', '12345678' ),
        $one->crypt_password( 'login', '123456789' ),
    );
    isnt(
        $one->crypt_password( 'login', '12345678901' ),
        $one->crypt_password( 'login', '123456789012' ),
    );

    # testing different logins
    isnt(
        $one->crypt_password( 'apples', 'password' ),
        $one->crypt_password( 'oranges', 'password' ),
    );
    # leftover TODO tests from before crypt refactor
    isnt(
        $one->crypt_password( '123', 'password' ),
        $one->crypt_password( '1234', 'password' ),
    );
    isnt(
        $one->crypt_password( 'orange', 'password' ),
        $one->crypt_password( 'oranges', 'password' ),
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# auth
    can_ok( $CLASS, 'authenticate' );

    is( $CLASS->authenticate, undef );
    is( $CLASS->authenticate( 1 ), undef );
    is( $CLASS->authenticate( 1, 1 ), undef );
    is( $CLASS->authenticate( 'ima', 1 ), undef );
    is( $CLASS->authenticate( 'ima', 'IMA' ), undef );

    is( $CLASS->authenticate( 'ima', 'imaima' )->id, 1001 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# eman
    can_ok( $one, 'eman' );

        $one->staff_id( 1001 )->retrieve;
    is( $one->eman, 'Therapist, Ima (PhD)' );
        $one->staff_id( 1002 )->retrieve;
    is( $one->eman, 'Clinician, Betty (MSW)' );
        $one->staff_id( 1003 )->retrieve;
    is( $one->eman, 'Writer, Willy (BA)' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# lookup_associations
    can_ok( $one, 'lookup_associations' );

        delete $one->{ staff_id };
    is( $one->lookup_associations, undef );
    is( $one->lookup_associations( 12 ), undef );

        $one->staff_id( 1001 );
        $one->retrieve;
    is_deeply( $one->lookup_associations( 3 ), [
        { %{ $lookup_groups->{ 1001 }}, sticky => 1 },
        { %{ $lookup_groups->{ 1002 }}, sticky => 0 },
    ]);

        $one->staff_id( 1002 );
    is_deeply( $one->lookup_associations( 3 ), [
        { %{ $lookup_groups->{ 1003 }}, sticky => 0 },
        { %{ $lookup_groups->{ 1001 }}, sticky => 1 },
    ]);

        $one->staff_id( 1003 );
    is_deeply( $one->lookup_associations( 3 ), [
        { %{ $lookup_groups->{ 1001 }}, sticky => 1 },
    ]);

        $one->staff_id( 1 );
    is( $one->lookup_associations( 3 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# lookup_associations_hash
    can_ok( $one, 'lookup_associations_hash' );

        $one->staff_id( 1 );
    is( $one->lookup_associations_hash( 3 ), undef );

        $one->staff_id( 1001 );
    is_deeply( $one->lookup_associations_hash( 3 ), {
        1001 => 'sticky',
        1002 => 1,
    });

        $one->staff_id( 1002 );
    is_deeply( $one->lookup_associations_hash( 3 ), {
        1003 => 1,
        1001 => 'sticky',
    });

        $one->staff_id( 1003 );
    is_deeply( $one->lookup_associations_hash( 3 ), {
        1001 => 'sticky',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set_lookup_associations
        $one->staff_id( 1001 );
    can_ok( $one, 'set_lookup_associations' );
    throws_ok{ $one->set_lookup_associations }
        qr/Lookup table id is required by Personnel::set_lookup_associations./;
    throws_ok{ $one->set_lookup_associations( 3, 1 )}
        qr/Items and sticky items must be arrayrefs./;
    throws_ok{ $one->set_lookup_associations( 3, 1, [] )}
        qr/Items and sticky items must be arrayrefs./;

    ok( ! $one->set_lookup_associations( 3 ));

    ok( $one->set_lookup_associations( 3, [ 1001 ]));
    is_deeply( $one->lookup_associations( 3 ), [
        { %{ $lookup_groups->{ 1001 }}, sticky => 0 },
    ]);

    ok( $one->set_lookup_associations( 3, [ 1002 ], [ 1002 ]));
    is_deeply( $one->lookup_associations( 3 ), [
        { %{ $lookup_groups->{ 1002 }}, sticky => 1 },
    ]);

    ok( $one->set_lookup_associations( 3, [ 1001, 1002 ], [ 1003 ]));
    is_deeply( $one->lookup_associations( 3 ), [
        { %{ $lookup_groups->{ 1003 }}, sticky => 1 },
        { %{ $lookup_groups->{ 1001 }}, sticky => 0 },
        { %{ $lookup_groups->{ 1002 }}, sticky => 0 },
    ]);

    ok( $one->set_lookup_associations( 3, [], [ 1001, 1002, 1003 ]));
    is_deeply( $one->lookup_associations( 3 ), [
        { %{ $lookup_groups->{ 1003 }}, sticky => 1 },
        { %{ $lookup_groups->{ 1001 }}, sticky => 1 },
        { %{ $lookup_groups->{ 1002 }}, sticky => 1 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clients by preference

    can_ok( $one, 'filter_clients' );

        $one->staff_id( 1 )->retrieve;
        $one->pref->client_list_filter( 'caseload' );
        $one->pref->client_program_list_filter( 0 );
    is( $one->filter_clients, undef );

        $one->pref->client_list_filter( 'active' );
    is_deeply( $one->filter_clients, [
        $client->{ 1004 },
        $client->{ 1003 },
        $client->{ 1005 },
        $client->{ 1006 },
    ]);

        $one->pref->client_list_filter( 'inactive' );
    is_deeply( $one->filter_clients, [
        $client->{ 1001 },
        $client->{ 1002 },
    ]);

    # program 1
        $one->pref->client_program_list_filter( 1 );
        $one->pref->client_list_filter( 'caseload' );
    is( $one->filter_clients, undef );

        $one->pref->client_list_filter( 'active' );
    is_deeply( $one->filter_clients, [
        $client->{ 1005 },
    ]);

        $one->pref->client_list_filter( 'inactive' );
    is( $one->filter_clients, undef );

    # program 1001
        $one->pref->client_program_list_filter( 1001 );
        $one->pref->client_list_filter( 'caseload' );
    is( $one->filter_clients, undef );

        $one->pref->client_list_filter( 'active' );
    is_deeply( $one->filter_clients, [
        $client->{ 1004 },
        $client->{ 1003 },
    ]);

        $one->pref->client_list_filter( 'inactive' );
    is( $one->filter_clients, undef );

        $one->pref->client_program_list_filter( 0 );
        $one->pref->client_list_filter( 'caseload' );

    # new staff member, 1001
        $one->staff_id( 1001 )->retrieve;
        $one->pref->client_program_list_filter( 0 );
        $one->pref->client_list_filter( 'caseload' );
    is_deeply( $one->filter_clients, [
        $client->{ 1004 },
        $client->{ 1005 },
    ]);

        $one->pref->client_list_filter( 'active' );
    is_deeply( $one->filter_clients, [
        $client->{ 1004 },
        $client->{ 1003 },
        $client->{ 1005 },
        $client->{ 1006 },
    ]);

        $one->pref->client_list_filter( 'inactive' );
    is_deeply( $one->filter_clients, [
        $client->{ 1001 },
        $client->{ 1002 },
    ]);

    # program 1002
        $one->pref->client_program_list_filter( 1002 );
        $one->pref->client_list_filter( 'caseload' );
    is( $one->filter_clients, undef );

        $one->pref->client_list_filter( 'active' );
    is( $one->filter_clients, undef );

        $one->pref->client_list_filter( 'inactive' );
    is( $one->filter_clients, undef );

    # staff 1003, program 1002
        $one->staff_id( 1003 )->retrieve;
        $one->pref->client_program_list_filter( 1004 );
        $one->pref->client_list_filter( 'caseload' );
    is_deeply( $one->filter_clients, [
        $client->{ 1006 },
    ]);

        $one->pref->client_list_filter( 'active' );
    is_deeply( $one->filter_clients, [
        $client->{ 1006 },
    ]);

        $one->pref->client_list_filter( 'inactive' );
    is( $one->filter_clients, undef );

        $one->pref->client_list_filter( 'caseload' );
        $one->pref->client_program_list_filter( 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clients by caseload, special case of above
#     can_ok( $one, 'get_caseload' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client relationships by preference
        $one->staff_id( 1001 );
        $one->retrieve;
        $one->pref->rolodex_show_inactive( 0 );
        $one->pref->rolodex_show_private( 0 );

    can_ok( $one, 'client_relationships_by_pref' );

    is( $one->client_relationships_by_pref( 1001, 'contacts' ), undef );
    is( $one->client_relationships_by_pref( 1003, 'contacts' ), undef );

        $one->pref->rolodex_show_private( 1 );
        $one->pref->save;
    is_deeply( $one->client_relationships_by_pref( 1003, 'contacts' ), [
        $client_contacts->{ 1001 },
        $client_contacts->{ 1002 },
    ]);

        $one->pref->rolodex_show_inactive( 1 );
        $one->pref->save;
    is_deeply( $one->client_relationships_by_pref( 1003, 'contacts' ), [
        $client_contacts->{ 1001 },
        $client_contacts->{ 1002 },
        $client_contacts->{ 1003 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# all client relationships by preference
    can_ok( $one, 'client_all_relationships_by_pref' );
        $one->staff_id( 1001 );
        $one->retrieve;

    is( $one->client_all_relationships_by_pref( 1006 ), undef );
    is_deeply( $one->client_all_relationships_by_pref( 1003 ), {
        contacts  => {
            description => 'Contact',
            relationships   => [
                $client_contacts->{ 1001 },
                $client_contacts->{ 1002 },
                $client_contacts->{ 1003 },
            ],
        },
        dental_insurance  => {
            description => 'Dental Insurance',
            relationships   => [
                $client_insurance->{ 1001 },
            ],
        },
        employment    => {
            description => 'Employer',
            relationships   => [
                $client_employment->{ 1001 },
            ],
        },
        medical_insurance => {
            description => 'Medical Insurance',
            relationships   => [
                $client_insurance->{ 1002 },
            ],
        },
        mental_health_insurance   => {
            description => 'Mental Health Insurance',
            relationships   => [
                $client_insurance->{ 1003 },
                $client_insurance->{ 1004 },
                $client_insurance->{ 1005 },
            ],
        },
        referral  => {
            description => 'Referral Source',
            relationships   => [
                $client_referral->{ 1001 },
            ],
        },
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# productivity: no default data
        $one->staff_id( 1 )->retrieve;
    is( $one->productivity_week, undef );
    is( $one->productivity_month, undef );
    is( $one->productivity_year, undef );
    is( $one->productivity_last_update, undef );

        $one->staff_id( 1001 )->retrieve;
    is( $one->productivity_week, undef );
    is( $one->productivity_month, undef );
    is( $one->productivity_year, undef );
    is( $one->productivity_last_update, undef );

        $one->staff_id( 1002 )->retrieve;
    is( $one->productivity_week, undef );
    is( $one->productivity_month, undef );
    is( $one->productivity_year, undef );
    is( $one->productivity_last_update, undef );

        $one->staff_id( 1003 )->retrieve;
    is( $one->productivity_week, undef );
    is( $one->productivity_month, undef );
    is( $one->productivity_year, undef );
    is( $one->productivity_last_update, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# productivity_update
    can_ok( $one, 'productivity_update' );
    
        $one->staff_id( 1 )->retrieve;
    is( $one->productivity_update( '11-07-05' ), undef );
    is( $one->productivity_week, undef );
    is( $one->productivity_month, undef );
    is( $one->productivity_year, undef );
    is( $one->productivity_last_update, undef );

        $one->staff_id( 1001 )->retrieve;
    ok( $one->productivity_update( '11-07-05' ));
    is( $one->productivity_week, 2.5 );
    is( $one->productivity_month, 1.71 );
    is( $one->productivity_year, 1.16 );
    is( $one->productivity_last_update, '2005-11-07 00:00:00' );

        $one->staff_id( 1002 )->retrieve;
    ok( $one->productivity_update( '11-07-05' ));
    is( $one->productivity_week, 0 );
    is( $one->productivity_month, 0 );
    is( $one->productivity_year, 0.35 );
    is( $one->productivity_last_update, '2005-11-07 00:00:00' );

        $one->staff_id( 1003 )->retrieve;
    ok( $one->productivity_update( '11-07-05' ));
    is( $one->productivity_week, 0 );
    is( $one->productivity_month, 0 );
    is( $one->productivity_year, 0.19 );
    is( $one->productivity_last_update, '2005-11-07 00:00:00' );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_overdue_clients
    can_ok( $one, 'get_overdue_clients' );
    is( $one->get_overdue_clients, undef );
   
        $one->staff_id( 1001 )->retrieve;
    ok( $one->get_overdue_clients );
    is_deeply( $one->get_overdue_clients( '2007-01-01' ), [
        {
            client_id => 1004, 
            visit_frequency => 2,
            visit_interval => 'year',
        },
        {
            client_id => 1005,
            visit_frequency => 1,
            visit_interval => 'month',
        },
    ]);
        $one->staff_id( 1 )->retrieve;
    is_deeply( $one->get_overdue_clients, [] );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
    can_ok( $one, 'get_all' );

    isa_ok( $_, $CLASS )
        for( @{ $one->get_all } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_byrole
    can_ok( $one, 'get_byrole' );
    is( $one->get_byrole, undef );
    is( $one->get_byrole( 'jazz_musician' ), undef );

    is_deeply( $one->get_byrole( 'active' ), $one->get_all );

    is( @{ $one->get_byrole( 'admin' ) }, 2, 'two admins found' );
    is_deeply(
        [ map { $_->staff_id } @{ $one->get_byrole( 'admin' ) } ],
        [ 1000, 1 ],
        'correct admins in correct order',
    );

    $test->db->transaction_do(sub {
        # reset security bit and make sure than we get 'undef' with no results

        for (@{ $one->get_byrole('admin') }) {
            $_->admin(0);
            $_->save;
        }

        is( $one->get_byrole( 'admin' ), undef );

        $test->db->transaction_do_rollback;
    });

sub get_byrole_ok {
    my ( $role ) = @_;
    is_deeply(
        [
            map { $_->staff_id }
            @{ $CLASS->get_byrole( $role->name ) || [] }
        ],
        [
            map { $_->staff_id }
            sort {
                $a->{lname} cmp $b->{lname} ||
                $a->{fname} cmp $b->{fname} ||
                $a->{staff_id} <=> $b->{staff_id}
            }
            @{ $role->all_personnel }
        ],
        "get_byrole: $role",
    );
}
    get_byrole_ok( $_ ) for @{ $CLASS->security_roles };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid_data
    can_ok( $one, 'valid_data' );

        $one->staff_id( 1001 )->retrieve;
        $tmp = $one->valid_data;
    isa_ok( $tmp, 'eleMentalClinic::ValidData' );
    is( $tmp->{ dept_id }, 1001 );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_clients
    can_ok( $one, 'get_clients' );
    is( $one->get_clients, undef );

        $one->staff_id( 1001 )->retrieve;
    is_deeply( $one->get_clients, [    
        $client->{ 1004 },
        $client->{ 1005 },
    ]);

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_treatmentplans
    can_ok( $one, 'get_treatmentplans' );
    
    is( $one->get_treatmentplans, undef );

        $one->staff_id( 1001 )->retrieve;
    is_deeply( $one->get_treatmentplans, [
        eleMentalClinic::TreatmentPlan->new( $tx_plan->{ 1001 } )
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_assessments
    can_ok( $one, 'get_assessments' );
    
        $one->staff_id( 1 )->retrieve;
    is( $one->get_assessments, undef );

        $one->staff_id( 1001 )->retrieve;
    is_deeply( 
        sort_objects( $one->get_assessments ), 
        [
            $client_assessment->{ 1002 },
            $client_assessment->{ 1003 },
            $client_assessment->{ 1004 },
            $client_assessment->{ 1005 },
            $client_assessment->{ 1006 },
            $client_assessment->{ 1007 },
            $client_assessment->{ 1008 },
        ]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# reporters
    can_ok( $one, 'reporters' );
    is( $CLASS->retrieve( 1001 )->reporters, undef );
    is( $CLASS->retrieve( 1002 )->reporters, undef );
    is( $CLASS->retrieve( 1003 )->reporters, undef );
    is( $CLASS->retrieve( 1004 )->reporters, undef );

    is( scalar @{ $CLASS->retrieve( 1005 )->reporters }, 3 );
    is( $CLASS->retrieve( 1005 )->reporters->[ 0 ]->staff_id, 1002 );
    is( $CLASS->retrieve( 1005 )->reporters->[ 1 ]->staff_id, 1001 );
    is( $CLASS->retrieve( 1005 )->reporters->[ 2 ]->staff_id, 1003 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# reporters with bounced prognotes
        $one = $CLASS->new;
    can_ok( $one, 'reporters_with_bounced_prognotes' );
    is( $CLASS->retrieve( 1001 )->reporters_with_bounced_prognotes, undef );
    is( $CLASS->retrieve( 1002 )->reporters_with_bounced_prognotes, undef );
    is( $CLASS->retrieve( 1003 )->reporters_with_bounced_prognotes, undef );
    is( $CLASS->retrieve( 1004 )->reporters_with_bounced_prognotes, undef );

    isa_ok( $_, $CLASS ) for @{ $CLASS->retrieve( 1005 )->reporters_with_bounced_prognotes };
    is( scalar @{ $CLASS->retrieve( 1005 )->reporters_with_bounced_prognotes }, 2 );
    is( @{ $CLASS->retrieve( 1005 )->reporters_with_bounced_prognotes }[ 0 ]->staff_id, 1002 );
    is( @{ $CLASS->retrieve( 1005 )->reporters_with_bounced_prognotes }[ 1 ]->staff_id, 1001 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# uncommitted_notes
        $one = $CLASS->new;
    can_ok( $one, 'uncommitted_prognotes' );
    is( $CLASS->retrieve( 1001 )->uncommitted_prognotes, undef );
    is( $CLASS->retrieve( 1002 )->uncommitted_prognotes, undef );
    is( $CLASS->retrieve( 1003 )->uncommitted_prognotes, undef );
        
    # reporters with uncommitted prognotes
    can_ok( $one, 'reporters_with_uncommitted_prognotes' );
    is( $CLASS->retrieve( 1001 )->reporters_with_uncommitted_prognotes, undef );
    is( $CLASS->retrieve( 1002 )->reporters_with_uncommitted_prognotes, undef );
    is( $CLASS->retrieve( 1003 )->reporters_with_uncommitted_prognotes, undef );
    is( $CLASS->retrieve( 1004 )->reporters_with_uncommitted_prognotes, undef );
    is( $CLASS->retrieve( 1005 )->reporters_with_uncommitted_prognotes, undef );

        eleMentalClinic::ProgressNote->retrieve( 1003 )->note_committed( 0 )->save;
        eleMentalClinic::ProgressNote->retrieve( 1004 )->note_committed( 0 )->save;
        eleMentalClinic::ProgressNote->retrieve( 1005 )->note_committed( 0 )->save;

    # reporters with uncommitted prognotes
    is( $CLASS->retrieve( 1001 )->reporters_with_uncommitted_prognotes, undef );
    is( $CLASS->retrieve( 1002 )->reporters_with_uncommitted_prognotes, undef );
    is( $CLASS->retrieve( 1003 )->reporters_with_uncommitted_prognotes, undef );
    is( $CLASS->retrieve( 1004 )->reporters_with_uncommitted_prognotes, undef );

    isa_ok( $_, $CLASS ) for @{ $CLASS->retrieve( 1005 )->reporters_with_uncommitted_prognotes };
    is( scalar @{ $CLASS->retrieve( 1005 )->reporters_with_uncommitted_prognotes }, 2 );
    is( @{ $CLASS->retrieve( 1005 )->reporters_with_uncommitted_prognotes }[ 0 ]->staff_id, 1002 );
    is( @{ $CLASS->retrieve( 1005 )->reporters_with_uncommitted_prognotes }[ 1 ]->staff_id, 1001 );

    is_deeply_except({ modified => undef },
        $CLASS->retrieve( 1001 )->uncommitted_prognotes,
        [
            { %{ $prognote->{ 1005 }}, note_committed => 0 },
        ]
    );
    is_deeply_except({ modified => undef },
        $CLASS->retrieve( 1002 )->uncommitted_prognotes,
        [
            { %{ $prognote->{ 1004 }}, note_committed => 0 },
            { %{ $prognote->{ 1003 }}, note_committed => 0 },
        ]
    );
    is( $CLASS->retrieve( 1003 )->uncommitted_prognotes, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    $one = $CLASS->retrieve( 1001 );
    ok( not $one->pass_has_expired );
    $one->password_expired( 1 );
    ok( $one->pass_has_expired );
    ok( $one->update_password( 'fake' ));
    ok( not $one->password_expired );
    ok( not $one->pass_has_expired );

    $one->password_set( "2001-01-01" ); #something old
    $one->save;
    $one = $CLASS->retrieve( 1001 );
    $CLASS->config->save({ password_expiration_days => 5 });
    is( $CLASS->config->password_expiration_days, 5 );
    ok( not $one->password_expired );
    ok( $one->pass_has_expired );
    ok( $one->update_password( 'fake' ));
    ok( not $one->password_expired );
    ok( not $one->pass_has_expired );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->retrieve( 1001 );
    is_deeply(
        $one->primary_role,
        eleMentalClinic::Role->get_one_by_( 'staff_id', 1001 ),
        "Correct Primary Role"
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
