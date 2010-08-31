# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 629;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

use eleMentalClinic::Client::Treater;
use eleMentalClinic::Client::Insurance;
use eleMentalClinic::Client::Employment;
use eleMentalClinic::Client::Contact;
use eleMentalClinic::Client::Referral;
use eleMentalClinic::Client::Release;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Rolodex';
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
    is( $one->table, 'rolodex');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id dept_id generic name fname lname
        credentials 
        comment_text client_id
        claims_processor_id edi_id edi_name
        edi_indicator_code
    /]);
    is_deeply( [ sort @{ $CLASS->fields } ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# charge code associations
    can_ok( $one, 'charge_code_associations' );
    throws_ok{ $one->charge_code_associations } qr/Must call on stored object/;

        $one = $CLASS->retrieve( 1001 );
    ok( $one->charge_code_associations );

        $one = $CLASS->retrieve( 1013 );
    is_deeply( $one->charge_code_associations->{ 1001 }, {
        charge_code_id                  => 1001,
        active                          => 1,
        dept_id                         => 1001,
        name                            => 90801,
        description                     => 'Psychiatric diagnostic interview',
        min_allowable_time              => 15,
        max_allowable_time              => 60,
        acceptable                      => 1,
        minutes_per_unit                => 60,
        dollars_per_unit                => '100.00',
        max_units_allowed_per_encounter => 1,
        max_units_allowed_per_day       => 2,
        cost_calculation_method         => 'Pro Rated Dollars per Unit',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in_treaters
    can_ok( $one, 'in_treaters' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in_release
    can_ok( $one, 'in_release' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in_referral
    can_ok( $one, 'in_referral' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in_prescribers
    can_ok( $one, 'in_prescribers' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in_mental_health_insurance
    can_ok( $one, 'in_mental_health_insurance' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in_medical_insurance
    can_ok( $one, 'in_medical_insurance' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in_employment
    can_ok( $one, 'in_employment' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in_dental_insurance
    can_ok( $one, 'in_dental_insurance' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in_contacts
    can_ok( $one, 'in_contacts' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# init
    can_ok( $one, 'init' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# _in
    can_ok( $one, '_in' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# in
    can_ok( $one, 'in' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    can_ok( $one, 'save' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_one
    can_ok( $one, 'get_one' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_all
    can_ok( $one, 'list_all' );
    is_deeply( $one->list_all, [
        $rolodex->{ 1016 },
        $rolodex->{ 1001 },
        $rolodex->{ 1018 },
        $rolodex->{ 1011 },
        $rolodex->{ 1002 },
        $rolodex->{ 1005 },
        $rolodex->{ 1004 },
        $rolodex->{ 1003 },
        $rolodex->{ 1010 },
        $rolodex->{ 1017 },
        $rolodex->{ 1019 },
        $rolodex->{ 1012 },
        $rolodex->{ 1008 },
        $rolodex->{ 1015 },
        $rolodex->{ 1007 },
        $rolodex->{ 1009 },
        $rolodex->{ 1006 },
        $rolodex->{ 1014 },
        $rolodex->{ 1013 },
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
    can_ok( $one, 'get_all' );
        my @tmpget = sort { $a->{rec_id} <=> $b->{rec_id} } @{$one->get_all};
        my @tmplist = sort { $a->{rec_id} <=> $b->{rec_id} } @{$one->list_all};
    is_deeply( \@tmpget, \@tmplist );
    isa_ok( $_, $CLASS ) for @{ $one->get_all };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_byrole
    can_ok( $one, 'list_byrole' );
    is( $one->list_byrole, undef );
    is( $one->list_byrole( 'foo' ), undef );
    is( $one->list_byrole( 'foo', 6666 ), undef );
    is( $one->list_byrole( 'foo', 1001 ), undef );

    is_deeply( $one->list_byrole( 'prescribers' ), undef );

    is_deeply( $one->list_byrole( 'contacts' ), [
        $rolodex->{ 1001 },
        $rolodex->{ 1002 },
        $rolodex->{ 1010 },
    ] );

    is_deeply( $one->list_byrole( 'contacts', 1003 ), [
        $rolodex->{ 1001 },
        $rolodex->{ 1002 },
        $rolodex->{ 1010 },
    ] );

    is_deeply( $one->list_byrole( 'contacts', 1001 ), [
        $rolodex->{ 1010 },
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_byrole
    can_ok( $one, 'get_byrole' );
    
    is_deeply(
        $one->get_byrole( 'contacts', 1003 ),
        $one->list_byrole( 'contacts', 1003 )
    );
    isa_ok( $_, $CLASS ) for @{ $one->get_byrole( 'contacts' ) };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_edi_rolodexes
    can_ok( $CLASS, 'list_edi_rolodexes' );

    is_deeply( $CLASS->list_edi_rolodexes, [
        $rolodex->{ 1015 },
        $rolodex->{ 1014 },
        $rolodex->{ 1013 },
    ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_edi_rolodexes
    can_ok( $CLASS, 'get_edi_rolodexes' );

    is_deeply(
        $CLASS->get_edi_rolodexes,
        $CLASS->list_edi_rolodexes
    );
    isa_ok( $_, $CLASS ) for @{ $CLASS->get_edi_rolodexes };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# last_received_edi
# wrapper
    can_ok( $one, 'last_received_edi' );
    is( $one->last_received_edi, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# role_names
    can_ok( $one, 'role_names' );
    is_deeply( $one->role_names, [qw/
         contacts
         dental_insurance
         employment
         medical_insurance
         mental_health_insurance
         prescribers
         referral
         release
         treaters
    /] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# roles
    can_ok( $one, 'roles' );

    is_deeply( $one->roles( 'foo' ), undef );

        $tmp = [ sort keys %$eleMentalClinic::Client::lookups ];
        @$tmp = @$eleMentalClinic::Client::lookups{ @$tmp };
    is_deeply( $one->roles, $tmp );
    
    is_deeply( $one->roles( 'contacts' ), $eleMentalClinic::Client::lookups->{ contacts } );
    is_deeply( $one->roles( 'employment' ), $eleMentalClinic::Client::lookups->{ employment } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add_role
    can_ok( $one, 'add_role' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# remove_role
    can_ok( $one, 'remove_role' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid_role
    can_ok( $one, 'valid_role' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client_roles
        $one = $CLASS->new;
    can_ok( $one, 'client_roles' );

    is( $one->client_roles, undef );
    is( $one->client_roles( 6666 ), undef );
    is( $one->client_roles( 1003 ), undef );

        $one->rec_id( 1008 );
    is_deeply( $one->client_roles( 6666 ), {
        contacts => 0,
        dental_insurance => 0,
        employment => 0,
        medical_insurance => 0,
        mental_health_insurance => 0,
        referral => 0,
        treaters => 0
    } );

    is_deeply( $one->client_roles( 1003 ), {
        contacts => 0,
        dental_insurance => 1,
        employment => 0,
        medical_insurance => 1,
        mental_health_insurance => 0,
        referral => 0,
        treaters => 0
    } );

        $one->rec_id( 1006 );
    is_deeply( $one->client_roles( 1003 ), {
        contacts => 0,
        dental_insurance => 0,
        employment => 0,
        medical_insurance => 0,
        mental_health_insurance => 0,
        referral => 0,
        treaters => 0
    } );

        $one->rec_id( 1001 );
    is_deeply( $one->client_roles( 1001 ), {
        contacts => 0,
        dental_insurance => 0,
        employment => 0,
        medical_insurance => 0,
        mental_health_insurance => 0,
        referral => 0,
        treaters => 0
    } );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# phone_f
    can_ok( $one, 'phone_f' );

# name_f and full_name
{
    my $r = $CLASS->retrieve( 1001 );

    ok $r->name;
    is $r->name_f, $r->name,            "name_f matches name";
    is $r->full_name, "Barbara Batts",  "full_name ignores name";

    $r->name("");
    ok !$r->name,                       "unset name";
    is $r->name_f, "Barbara Batts";
    is $r->full_name, $r->name_f;

    $r->credentials("Esq");
    is $r->full_name, "Barbara Batts, Esq",     "full_name with credentials";
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# eman
    can_ok( $one, 'eman' );
        $one->rec_id( 1001 )->retrieve;
    is( $one->eman, 'Batts, Barbara' );
        $one->rec_id( 1002 )->retrieve;
    is( $one->eman, 'Monk, Thelonious (Sr.)' );
        $one->rec_id( 1003 )->retrieve;
    is( $one->eman, 'Producer, Slimy' );
        $one->rec_id( 1004 )->retrieve;
    is( $one->eman, 'Producer, Scummy' );
        $one->rec_id( 1005 )->retrieve;
    is( $one->eman, 'Producer, Mephisto' );
        $one->rec_id( 1006 )->retrieve;
    is( $one->eman, 'Regence BlueCross BlueShield' );
        $one->rec_id( 1007 )->retrieve;
    is( $one->eman, 'Oregon Dental Service (ODS)' );
        $one->rec_id( 1008 )->retrieve;
    is( $one->eman, 'HealthNet' );
        $one->rec_id( 1009 )->retrieve;
    is( $one->eman, 'Providence Health Plans' );
        $one->rec_id( 1010 )->retrieve;
    is( $one->eman, 'Rheinhart, Django' );
        $one->rec_id( 1011 )->retrieve;
    is( $one->eman, 'Clinician, Betty (MSW)' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# eman_company
    can_ok( $one, 'eman_company' );
        $one->rec_id( 1001 )->retrieve;
    is( $one->eman_company, 'Batts, Barbara (Batts)' );
        $one->rec_id( 1002 )->retrieve;
    is( $one->eman_company, 'Monk, Thelonious' );
        $one->rec_id( 1003 )->retrieve;
    is( $one->eman_company, 'Producer, Slimy (Blue Note)' );
        $one->rec_id( 1004 )->retrieve;
    is( $one->eman_company, 'Producer, Scummy (Atlantic Records)' );
        $one->rec_id( 1005 )->retrieve;
    is( $one->eman_company, 'Producer, Mephisto (Chess Records)' );
        $one->rec_id( 1006 )->retrieve;
    is( $one->eman_company, 'Regence BlueCross BlueShield' );
        $one->rec_id( 1007 )->retrieve;
    is( $one->eman_company, 'Oregon Dental Service (ODS)' );
        $one->rec_id( 1008 )->retrieve;
    is( $one->eman_company, 'HealthNet' );
        $one->rec_id( 1009 )->retrieve;
    is( $one->eman_company, 'Providence Health Plans' );
        $one->rec_id( 1010 )->retrieve;
    is( $one->eman_company, 'Rheinhart, Django (Django Records)' );
        $one->rec_id( 1011 )->retrieve;
    is( $one->eman_company, 'Clinician, Betty (Clinician)' );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make_private
    can_ok( $one, 'make_private' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_private
    can_ok( $one, 'is_private' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dup_check 
    can_ok( $one, 'dup_check' );
        $one = $CLASS->new;
    is_deeply( $one->dup_check, {
        name => undef,
        fname_lname_cred => undef,
    } );

        $one->name( 'Frog' );
    is( $one->dup_check->{ name }, undef);
    is( $one->dup_check->{ fname_lname_cred }, undef);

        $one->name( $rolodex->{ 1003 }->{ name } );
    is_deeply( $one->dup_check->{ name }, $rolodex->{ 1003 } );
    is( $one->dup_check->{ fname_lname_cred }, undef);
        $one->rec_id( 1003 );
    is( $one->dup_check->{ name }, undef);
    is( $one->dup_check->{ fname_lname_cred }, undef);

        # check that we don't complain about a duplicate of itself '
        $one = $CLASS->new;
        $one->rec_id( 1003 )->retrieve;
    is( $one->dup_check->{ name }, undef );
        
        $one = $CLASS->new;
        $one->fname( $rolodex->{ 1003 }->{ fname } );
    is( $one->dup_check->{ name }, undef);
    is( $one->dup_check->{ fname_lname_cred }, undef);

        $one = $CLASS->new;
        $one->lname( $rolodex->{ 1003 }->{ lname } );
    is( $one->dup_check->{ name }, undef);
    is( $one->dup_check->{ fname_lname_cred }, undef);

        $one = $CLASS->new;
        $one->fname( $rolodex->{ 1001 }->{ fname } );
        $one->lname( $rolodex->{ 1002 }->{ lname } );
    is( $one->dup_check->{ name }, undef);
    is( $one->dup_check->{ fname_lname_cred }, undef);

        $one = $CLASS->new;
        $one->fname( $rolodex->{ 1002 }->{ fname } );
        $one->lname( $rolodex->{ 1002 }->{ lname } );
    is( $one->dup_check->{ name }, undef);
    is( $one->dup_check->{ fname_lname_cred }, undef);

        $one = $CLASS->new;
        $one->fname( $rolodex->{ 1004 }->{ fname } );
        $one->lname( $rolodex->{ 1004 }->{ lname } );
    is_deeply( $one->dup_check->{ fname_lname_cred }, [ $rolodex->{ 1004 } ] );
    is( $one->dup_check->{ name }, undef);
    is_deeply( $one->dup_check->{ fname_lname_cred }, [
        $rolodex->{ 1004 },
    ]);
        $one->rec_id( 1004 );
    is( $one->dup_check->{ name }, undef);
    is( $one->dup_check->{ fname_lname_cred }, undef );

        $one = $CLASS->new;
        $one->fname( $rolodex->{ 1002 }->{ fname } );
        $one->lname( $rolodex->{ 1002 }->{ lname } );
        $one->credentials( $rolodex->{ 1002 }->{ credentials } );
    is_deeply( $one->dup_check->{ fname_lname_cred }, [ $rolodex->{ 1002 } ] );
    is( $one->dup_check->{ name }, undef);
    is_deeply( $one->dup_check->{ fname_lname_cred }, [
        $rolodex->{ 1002 },
    ]);
        $one->rec_id( 1002 );
    is( $one->dup_check->{ name }, undef);
    is( $one->dup_check->{ fname_lname_cred }, undef );

        $one = $CLASS->new;
        $one->name( $rolodex->{ 1003 }->{ name } );
        $one->fname( $rolodex->{ 1002 }->{ fname } );
        $one->lname( $rolodex->{ 1002 }->{ lname } );
        $one->credentials( $rolodex->{ 1002 }->{ credentials } );
    is_deeply( $one->dup_check, {
        name => $rolodex->{ 1003 },
        fname_lname_cred => [ $rolodex->{ 1002 } ],
    });

    # data sanitization checks
        $one = $CLASS->new;
        $one->name( "O'Ren Ishi" );
    is_deeply( $one->dup_check, {
        name => undef,
        fname_lname_cred => undef,
    });

        $one = $CLASS->new;
        $one->fname( "Boris" );
        $one->lname( "Spider" );
        $one->credentials( "Apo'strophe" );
    is_deeply( $one->dup_check, {
        name => undef,
        fname_lname_cred => undef,
    });

        $one = $CLASS->new;
        $one->fname( "O'Ren" );
        $one->lname( "O'Neil" );
    is_deeply( $one->dup_check, {
        name => undef,
        fname_lname_cred => undef,
    });

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# role
    can_ok( $one, 'role' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_by_role_id
    can_ok( $one, 'get_by_role_id' );

    is( $one->get_by_role_id, undef );
    is( $one->get_by_role_id( 'mental_health_insurance' ), undef );
    is( $one->get_by_role_id( 'mental_heath_insurance', 1006 ), undef );

        $tmp = eleMentalClinic::Rolodex->new( { rec_id => 1015 } )->retrieve;
    is_deeply( $one->get_by_role_id( 'mental_health_insurance', 1006 ), $tmp );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# find_similar
    can_ok( $one, 'find_similar' );

        dbinit();

        $test->insert_rolodex_dirty_data([
            'eleMentalClinic::Client',
            'client_insurance',
            'client_contacts',
            'client_release',
            'client_placement_event',
            'client_referral',
            'client_employment',
            'client_treaters',
            'claims_processor',
            $CLASS->table,
            'rolodex_medical_insurance',
            'rolodex_mental_health_insurance',
            'rolodex_dental_insurance',
            'rolodex_employment',
            'rolodex_contacts',
            'rolodex_treaters',
            'rolodex_referral',
            'phone',
            'address',
        ]);
       
        # set up all the duplicates
        # TODO: uncomment values when find_similar really gets 
        # similar values instead of exact
        my %duplicates = ( 1001 => [ 1101, 1201, 1301 ],
                           1002 => [ 1302 ], # 1102, 1202
                           1003 => [ 1103, 1203, 1303 ],
                           1004 => [ 1204, 1304 ], # 1104
                           1005 => [ 1105, 1205, 1305 ],
                           1006 => [ 1206, 1306 ], # 1106 [Note: 1306 removed from medical_ins and mental_health_ins roles]
                           1007 => [ 1307 ], # 1107, 1207
                           1008 => [ 1208, 1308 ], # 1108
                           1009 => [ 1209, 1309 ], # 1109
                           1010 => [ 1110, 1210, 1310 ],
                           1011 => [ 1211, 1311 ], # 1111
                         #  1401 => [ 1402 .. 1420 ],
                           1404 => [ 1406 ],
                           1501 => [ 1507, 1511, 1512, 1519 ],
                         #  1501 => [ 1502 .. 1520 ],
                           1502 => [ 1505, 1515 ],
                           1503 => [ 1508, 1517, 1520 ],
                           1513 => [ 1514 ],
        );

    is_deeply( $one->rec_id( $_ )->retrieve->find_similar, $duplicates{ $_ } )
        for( keys %duplicates );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# cache_similar
    can_ok( $one, 'cache_similar');

    $one->cache_similar;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# similar_entries
    can_ok( $one, 'similar_entries');

    my %entries;
    for( keys %duplicates ){
        $entries{ $_ } = scalar @{ $duplicates{ $_ } };
    }

    is_deeply( $one->similar_entries, \%entries );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# matching_ids
    can_ok( $one, 'matching_ids');

    is_deeply( $one->matching_ids( 1005 ), [ 1105, 1205, 1305 ] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# similar_modified
    can_ok( $one, 'similar_modified');

    my $today = $one->today;
    like( $one->similar_modified, qr/$today \d\d:\d\d/ );
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# merge
    can_ok( $one, 'merge' );

        for( keys %duplicates ){
            $tmp = $one->rec_id( $_ )->retrieve->find_similar;   
            # this should recreate exactly the same numbers as above
            $duplicates{ $_ } = join( ', ' => @$tmp ); 
        }

        &test_related_tables;
        
        for( keys %duplicates ){
            $one->merge( $one->rec_id( $_ )->retrieve->find_similar );
        }

        &test_related_tables( 'new' );

    is_deeply( $one->find_similar, [] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# merge two records not matched with find_similar

    is( eleMentalClinic::Client::Release->new({ rec_id => 1101 })->retrieve->rolodex->{ rec_id }, 1109 );
      $one->rec_id( 1009 )->retrieve;
      $one->merge( [ 1109 ] );
    is( eleMentalClinic::Client::Release->new({ rec_id => 1101 })->retrieve->rolodex->{ rec_id }, 1009 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# schedule
    isa_ok( $one->schedule, 'eleMentalClinic::Schedule' );
    is($one->schedule->rolodex_id,$one->id);
    
# {{{ sub test_related_tables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub test_related_tables {
    my $test_new = shift;

    my @relationships = (
        { object => eleMentalClinic::Client::Treater->new({ rec_id => 1101 })->retrieve,
          old_id => 1211,
          new_id => 1011,
        },
        # medical
        { object => eleMentalClinic::Client::Insurance->new({ rec_id => 1307 })->retrieve,
          old_id => 1307,
          new_id => 1007,
        },
        # mental health
        { object => eleMentalClinic::Client::Insurance->new({ rec_id => 1403 })->retrieve,
          old_id => 1206,
          new_id => 1006,
        },
        # dental
        { object => eleMentalClinic::Client::Insurance->new({ rec_id => 1307 })->retrieve,
          old_id => 1307,
          new_id => 1007,
        },
        { object => eleMentalClinic::Client::Employment->new({ rec_id => 1101 })->retrieve,
          old_id => 1103,
          new_id => 1003,
        },
        { object => eleMentalClinic::Client::Contact->new({ rec_id => 1101 })->retrieve,
          old_id => 1101,
          new_id => 1001,
        },
        { object => eleMentalClinic::Client::Referral->new({ rec_id => 1101 })->retrieve,
          old_id => 1110,
          new_id => 1010,
        },
        { object => eleMentalClinic::Client::Release->new({ rec_id => 1105 })->retrieve,
          old_id => 1105,
          new_id => 1005,
        }
    );

    if ( $test_new ){
        
        is( $_->{ object }->rolodex->{ rec_id }, $_->{ new_id } )
            for( @relationships );
    }
    else {
    
        is( $_->{ object }->rolodex->{ rec_id }, $_->{ old_id } )
            for( @relationships );
    }

    &test_role_tables( $test_new );
}
# }}}

# {{{ sub test_role_tables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub test_role_tables {
        my $test_new = shift;

        if( $test_new ){
	    # Test merging of rolodex role tables
            my @tables = qw/ rolodex_contacts rolodex_treaters rolodex_employment
                             rolodex_medical_insurance rolodex_mental_health_insurance
                             rolodex_dental_insurance rolodex_referral /;

            # Test that all of these tables have been merged as well as the rolodex tables.
            # The test data has several places where 2 or more of these tables will merge.
            # Run this with the code for merging rolodex role tables commented out to see.
            for( @{ $one->get_all } ){
                my $rolodex_id = $_->{ rec_id };
            
                for my $table ( @tables ){
                    $tmp = $one->db->do_sql(qq/
                        SELECT count(*)
                        FROM $table
                        WHERE rolodex_id = $rolodex_id;
                    /)->[0];

                    cmp_ok( $tmp->{ count }, '<=', 1 );
                }
            }
        }

        # There are also tables pointing to these role tables 
        # that we should make sure are updated.
        # (Before the merge, test that they are pointing to different tables;
        # after the merge, they should point to the same merged table.)
        $tmp =  $one->db->do_sql(qq/
            SELECT rolodex_employment_id
              FROM client_employment
             WHERE rec_id IN (1001, 1101);
         /);
    
        if( $test_new ){
            is( $tmp->[0]->{ rolodex_employment_id }, $tmp->[1]->{ rolodex_employment_id } )
        }
        else {
            isnt( $tmp->[0]->{ rolodex_employment_id }, $tmp->[1]->{ rolodex_employment_id } );
        }

        $tmp =  $one->db->do_sql(qq/
            SELECT rolodex_contacts_id
              FROM client_contacts
             WHERE rec_id IN (1001, 1101);
         /);
        if( $test_new ){
            is( $tmp->[0]->{ rolodex_contacts_id }, $tmp->[1]->{ rolodex_contacts_id } );
        }
        else {
            isnt( $tmp->[0]->{ rolodex_contacts_id }, $tmp->[1]->{ rolodex_contacts_id } );
        }

        $tmp =  $one->db->do_sql(qq/
            SELECT rolodex_insurance_id
              FROM client_insurance
             WHERE rec_id IN (1009, 1403);
         /);
        if( $test_new ){
            is( $tmp->[0]->{ rolodex_insurance_id }, $tmp->[1]->{ rolodex_insurance_id } );
        }
        else {
            isnt( $tmp->[0]->{ rolodex_insurance_id }, $tmp->[1]->{ rolodex_insurance_id } );
        }

        $tmp =  $one->db->do_sql(qq/
            SELECT rolodex_referral_id
              FROM client_referral
             WHERE rec_id IN (1001, 1101);
         /);
        if( $test_new ){
            is( $tmp->[0]->{ rolodex_referral_id }, $tmp->[1]->{ rolodex_referral_id } );
        }
        else {
            isnt( $tmp->[0]->{ rolodex_referral_id }, $tmp->[1]->{ rolodex_referral_id } );
        }
        
        $tmp =  $one->db->do_sql(qq/
            SELECT rolodex_treaters_id
              FROM client_treaters
             WHERE rec_id IN (1001, 1101);
         /);
        if( $test_new ){
            is( $tmp->[0]->{ rolodex_treaters_id }, $tmp->[1]->{ rolodex_treaters_id } );
        }
        else {
            isnt( $tmp->[0]->{ rolodex_treaters_id }, $tmp->[1]->{ rolodex_treaters_id } );
        }
}
# }}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# phones and addresses ordering tests, primary first, then by rec_id

    $tmp = eleMentalClinic::Client->new;
    $tmp->save;
    $one = $CLASS->new({ client_id => $tmp->client_id, dept_id => 1001 })->save;
    eleMentalClinic::Contact::Phone->new({ 
        rolodex_id => $one->rec_id, 
        phone_number => '555-555-5555',
    })->save;
    eleMentalClinic::Contact::Phone->new({ 
        rolodex_id => $one->rec_id, 
        phone_number => '555-555-5556',
        primary_entry => 1, 
    })->save;
    eleMentalClinic::Contact::Phone->new({ 
        rolodex_id => $one->rec_id, 
        phone_number => '555-555-5557',
    })->save;
    eleMentalClinic::Contact::Phone->new({ 
        rolodex_id => $one->rec_id, 
        phone_number => '555-555-5558',
    })->save;

    my $phones = $one->phones;
    #Primary should be first
    is( $phones->[0]->phone_number, '555-555-5556' );
    is( $phones->[0]->primary_entry, 1 );
    #Others should be consistent, by record ID
    is( $phones->[1]->phone_number, '555-555-5555' );
    ok( not $phones->[1]->primary_entry );
    is( $phones->[2]->phone_number, '555-555-5557' );
    ok( not $phones->[2]->primary_entry );
    is( $phones->[3]->phone_number, '555-555-5558' );
    ok( not $phones->[3]->primary_entry );

    eleMentalClinic::Contact::Address->new({ 
        rolodex_id => $one->rec_id, 
        address1 => '1 a',
        address2 => 'a',
        city => 'a',
        state => 'aa',
        post_code => '11111',
        county => 'a',
        active => 1,
    })->save;
    eleMentalClinic::Contact::Address->new({ 
        rolodex_id => $one->rec_id, 
        address1 => '2 b',
        address2 => 'b',
        city => 'b',
        state => 'bb',
        post_code => '22222',
        county => 'b',
        active => 1,
    })->save;
    eleMentalClinic::Contact::Address->new({ 
        rolodex_id => $one->rec_id, 
        address1 => '3 c',
        address2 => 'c',
        city => 'c',
        state => 'cc',
        post_code => '33333', 
        county => 'c',
        active => 1,
        primary_entry => 1, # **** Primary ****
    })->save;
    eleMentalClinic::Contact::Address->new({ 
        rolodex_id => $one->rec_id, 
        address1 => '4 d',
        address2 => 'd',
        city => 'd',
        state => 'dd',
        post_code => '44444',
        county => 'd',
        active => 1,
    })->save;

    my $addresses = $one->addresses;
    #Primary should be first
    is( $addresses->[0]->primary_entry, 1 );
    is( $addresses->[0]->address1, '3 c' );
    #Others should be consistent, by record ID
    is( $addresses->[1]->address1, '1 a' );
    is( $addresses->[2]->address1, '2 b' );
    is( $addresses->[3]->address1, '4 d' );

    # The following is necessary to clean up after these tests.
    # Without this the next time the test is run the test count
    # will be inaccurate, unless you run db-dev-clean first.
    $one->db->do_sql( 'delete from phone', 1 );
    $one->db->do_sql( 'delete from address', 1 );
    $one->delete;
    $tmp->delete;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
