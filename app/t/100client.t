# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use warnings;
use strict;

use Test::More tests => 567;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use Carp qw(confess);
use Date::Calc qw/ Today Date_to_Text /;
use List::Util qw/ max /;

our ($CLASS, $one, $tmp, %tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client';
    use_ok( $CLASS );
}

# Turn off the warnings coming from validation during financial_setup.
$eleMentalClinic::Base::TESTMODE = 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
#    $test->financial_delete_data;
#    $test->delete_( 'client_intake', '*' );
#    $test->delete_( 'client_referral', '*' );
#    $test->delete_( 'client_discharge', '*' );
#    $test->delete_( 'client_placement_event', '*' );
#    $test->delete_( 'client_contacts', '*' );
    $test->db_refresh;
    #$test->delete_( $CLASS, '*' );
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# fields removed in placement refactor
    ok( not $one->can( $_ ))
        for qw/
            unit_id dept_id track_id active input_by
            bed_id staff_id start_date end_date input_on
            final_diagnosis initial_diagnosis
        /;

    ok( $one->can( 'addresses' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'client');
    is( $one->primary_key, 'client_id');
    is_deeply( $one->fields, [qw/
        client_id chart_id 
        dob ssn mname fname lname name_suffix
        aka living_arrangement 
        sex race marital_status substance_abuse
        alcohol_abuse gambling_abuse religion
        acct_id language_spoken sexual_identity
        state_specific_id 
        edu_level working section_eight comment_text
        has_declaration_of_mh_treatment
        declaration_of_mh_treatment_date 
        is_veteran is_citizen consent_to_treat
        email dont_call renewal_date
        birth_name household_annual_income household_population
        household_population_under18 dependents_count intake_step
        send_notifications nationality_id
    /]);
    is_deeply( [ sort @{ $CLASS->fields } ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# id
    can_ok( $one, 'id' );
    is( $one->id, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# role
    can_ok( $one, 'role' );
    is( $one->role, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Access
{
    local $one;
    use Data::Dumper;
    $one = $CLASS->retrieve( 1001 );
    ok( $tmp = $one->access, "Got access list" );
    for my $name ( keys %$tmp ) {
        ok( @{ $tmp->{ $name }}, "Access list for staff: $name" );
        for my $item ( @{ $tmp->{ $name }}) {
            is( $item->staff->lname . ', ' . $item->staff->fname, $name, "Correct name for item" )
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_all
    can_ok( $one, 'list_all' );

    is_deeply( $one->list_all, [
        $client->{ 1001 },
        $client->{ 1004 },
        $client->{ 1002 },
        $client->{ 1003 },
        $client->{ 1005 },
        $client->{ 1006 },
    ]);

    is( $one->list_all({ staff_id => 1, }), undef );
    is_deeply( $one->list_all({ staff_id => 1001, }), [
        $client->{ 1004 },
        $client->{ 1005 },
    ]);
    is_deeply( $one->list_all({ staff_id => 1002, }), [
        $client->{ 1003 },
    ]);
    is_deeply( $one->list_all({ staff_id => 1003, }), [
        $client->{ 1006 },
    ]);

    is_deeply( $one->list_all({ active => 1 }), [
        $client->{ 1004 },
        $client->{ 1003 },
        $client->{ 1005 },
        $client->{ 1006 },
    ]);
    is_deeply( $one->list_all({ active => 0 }), [
        $client->{ 1001 },
        $client->{ 1002 },
    ]);

    is_deeply( $one->list_all({ staff_id => 1001, active => 1, }), [
        $client->{ 1004 },
        $client->{ 1005 },
    ]);
    is_deeply( $one->list_all({ staff_id => 1002, active => 1, }), [
        $client->{ 1003 },
    ]);
    is_deeply( $one->list_all({ staff_id => 1003, active => 1, }), [
        $client->{ 1006 },
    ]);

    is_deeply( $one->list_all({ program_id => 1 }), [
        $client->{ 1005 },
    ]);
    is_deeply( $one->list_all({ program_id => 1001 }), [
        $client->{ 1004 },
        $client->{ 1003 },
    ]);
    is( $one->list_all({ program_id => 1002 }), undef );
    is( $one->list_all({ program_id => 1003 }), undef );
    is_deeply( $one->list_all({ program_id => 1004 }), [
        $client->{ 1006 },
    ]);

    # dob
    is_deeply( $one->list_all({ search => '1917-10-10' }), [ $client->{ 1003 }, ] );
    is( $one->list_all({ search => '1974-05-03' }), undef );

    # ssn
    is_deeply( $one->list_all({ search => '192882657' }), [ $client->{ 1001 }, ] );
    is( $one->list_all({ search => '555667777' }), undef );

    # state_specific_id
    is_deeply( $one->list_all({ search => '9876' }), [ $client->{ 1002 }, ] );
    is( $one->list_all({ search => '111111' }), undef );

    # insurance id
    is_deeply( $one->list_all({ search => 'WHITE KEYS' }), [ $client->{ 1003 }, ] );
    is( $one->list_all({ search => '999' }), undef );

    # lname
    is_deeply( $one->list_all({ search => 'fitzg' }), [ $client->{ 1004 }, ] );
    is( $one->list_all({ search => 'frog' }), undef );

    # intake, partial
    is( $one->list_all({ intake_incomplete => 1 }), undef );
        
        $CLASS->retrieve( 1001 )->update({ intake_step => 1 });
    is_deeply_except({ intake_step => undef }, $one->list_all({ intake_incomplete => 1 }), [
        $client->{ 1001 },
    ]);

        $CLASS->retrieve( 1004 )->update({ intake_step => 6 });
    is_deeply_except({ intake_step => undef }, $one->list_all({ intake_incomplete => 1 }), [
        $client->{ 1001 },
        $client->{ 1004 }
    ]);

        $CLASS->retrieve( 1001 )->update({ intake_step => undef });
        $CLASS->retrieve( 1004 )->update({ intake_step => undef });
    is( $one->list_all({ intake_incomplete => 1 }), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all
# wrapper
    can_ok( $one, 'get_all' );

    isa_ok( $_, $CLASS )
        for( @{ $one->get_all } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# renew
    can_ok( $one, 'renew' );
        
        $one = $CLASS->new;

    is( $one->renew, undef );

        # setup Auditor to use the given current_user rather
        # than having it try to get something out of the 
        # CGI session.
        my $current_user = eleMentalClinic::Personnel->new( $personnel->{1001} )->retrieve;
        $eleMentalClinic::Auditor::Test_Current_User = $current_user;

    # renew, with no previous renewal
    my $new_renewal = '2/2/2006';
    $one->renewal_date( $new_renewal );
    my $previous_renewal = undef;
    is( $one->renew($previous_renewal), undef, 'client not instantiated');
        $one->client_id( 1001 );
    my $note_id = $one->renew($previous_renewal);
    my $note = eleMentalClinic::ProgressNote->new( { rec_id => $note_id } )->retrieve;
    is( $note->id, $note_id);
    is( $note->note_header, 'RENEWAL');
    is( $note->note_body, ": renewal date - $new_renewal");
    is( $note->note_committed, 1 );
    my $today = $one->today;
    like( $note->start_date, qr/^$today/ );
    like( $note->created,    qr/^$today/ );

    # Testing with doctor set
    ok($one->save_primary_treater( { primary_treater_rolodex_id => 1001 } ));
    $previous_renewal = $new_renewal;
    $new_renewal = '3/3/2006';
    $one->renewal_date( $new_renewal );
    my $another_note_id = $one->renew( $previous_renewal );
    $note = eleMentalClinic::ProgressNote->new( { rec_id => $another_note_id } )->retrieve;
    is( $note->id, $another_note_id);
    is( $note->note_header, 'RENEWAL');
    is( $note->note_body, "$rolodex->{1001}->{name}: renewal date - $new_renewal");
    like( $note->start_date, qr/$today.*/);

    # Testing through call to update
    $new_renewal = '4/4/2006';
    use Data::Dumper;
    ok $one->update( { renewal_date => $new_renewal } );
    my $third_note_id = $another_note_id + 1;
    $note = eleMentalClinic::ProgressNote->retrieve( $third_note_id );
    is( $note->id, $third_note_id);
    is( $note->note_header, 'RENEWAL');
    is( $note->note_body, "$rolodex->{1001}->{name}: renewal date - $new_renewal");
    like( $note->start_date, qr/$today.*/);

    $test->db->transaction_do(sub {
        sleep 1; # change timestamp
        my $note = eleMentalClinic::ProgressNote->new({
            client_id => $one->client_id,
            note_header => 'STUFF',
            staff_id => 1001,
            goal_id => 0,
            note_body => 'this is a note',
        });
        $note->commit;
        $note->save;
        my $notes = $one->get_all_progress_notes;
        # we don't actually care about sorting by rec_id, we care about sorting
        # by created timestamp, but rec_id should indicate order of creation
        # just as well, and not have any sub-second resolution problems
        is_deeply(
            [ map { $_->rec_id } @$notes ],
            [ map { $_->rec_id }
                sort {
                    (!!$b->{ start_date } <=> !!$a->{ start_date })
                        or
                    ($b->created cmp $a->created)
                        or
                    $b->rec_id  <=> $a->rec_id
                } @$notes ],
            "notes are sorted correctly",
        );
        $test->db->transaction_do_rollback;
    });

    my $p_treater = $one->get_primary_treater;
    dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# last_called
    can_ok( $one, 'last_called');

        $one = $CLASS->new;

    is( $one->last_called, undef);
        $one->client_id( 1001 );
    is( $one->last_called, undef);        
        $one->client_id( 1002 );
    my ($last_called) = split qr/ /, $prognote->{1001}->{start_date}; 
    is( $one->last_called, $last_called);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# relationship_byrole
    can_ok( $one, 'relationship_byrole' );

        $one = $CLASS->new;

    throws_ok {$one->relationship_byrole} qr/Role is required/;
    throws_ok {$one->relationship_byrole('foo')} qr/Role.*is invalid/;
    is($one->relationship_byrole('contacts'), undef);

        $one->client_id( 1003 );
    # contacts are returned ordered by role
    is_deeply( $one->relationship_byrole('contacts'),  [
        $client_contacts->{ 1001 },
        $client_contacts->{ 1002 },
        $client_contacts->{ 1003 },
    ]);
    # active/inactive
    is_deeply( $one->relationship_byrole('contacts', undef, 1), [
        $client_contacts->{ 1001 },
        $client_contacts->{ 1002 },
    ]);
    is_deeply( $one->relationship_byrole('contacts', undef, 0),  [
        $client_contacts->{ 1003 },
    ]);
    # private/public
    is_deeply( $one->relationship_byrole('contacts', 1),  [
        $client_contacts->{ 1001 },
        $client_contacts->{ 1002 },
    ]);
    is_deeply( $one->relationship_byrole('contacts', 0),  [
        $client_contacts->{ 1003 },
    ]);
    # no relations
        $one->client_id( 1004 );
    is( $one->relationship_byrole('contacts',1,1), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# relationship_unique
        $one = $CLASS->new;

    can_ok( $CLASS, 'relationship_primary' );

    throws_ok { $one->relationship_primary } qr/Role is required/ ;
    throws_ok { $one->relationship_primary('foo') } qr/Role.*is not valid/ ;
    is($one->relationship_byrole('contacts'), undef);

        $one->client_id( 1004 );
    is($one->relationship_primary('contacts'), undef);
        $one->client_id( 1005 );
    is_deeply( $one->relationship_primary('treaters'), $client_treaters->{1001});
    is_deeply( $one->relationship_primary('treaters', 2), $client_treaters->{1002});

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Multiple emergency contacts
    $one = $CLASS->new({
        fname => 'Robert',
        mname => 'Bob',
        lname => 'Marley',
        birth_name => 'Same',
        sex => 'Male',
        ssn => '777-56-7777',
        dob => '1969-10-10',
    });
    $one->save;

    #save_emergency_contacts, plural, thus multiple must be acceptable, judgement call on my part.
    ok( $one->save_emergency_contacts([
        {
            fname  => 'Marey',
            lname  => 'Marley',
            comment_text => 'mother',
            phone_number  => '888-888-8888',
        },
        {
            fname  => 'BillyBob',
            lname  => 'Marley',
            comment_text => 'father',
            phone_number  => '999-999-9999',
        },
        {
            fname  => 'Jacob',
            lname  => 'Marley',
            comment_text => 'brother',
            phone_number  => '000-000-0000',
        },
    ]));

    #Make sure we have the correct number of contacts.
    is( @{$one->get_emergency_contacts}, 3 );


# Fields (note) 
# active client_id comment_text contact_type_id rec_id rolodex_contacts_id 

    is_deeply(
        $one->get_emergency_contacts,
        $one->db->select_many( 
            eleMentalClinic::Client::Contact->fields,
            eleMentalClinic::Client::Contact->table,
            "WHERE client_id = ". $one->client_id ." AND contact_type_id = 3",
            'order by rec_id ASC',
        ),
    );

    my $exclude = {
        claims_processor_id => undef, 
        credentials => undef, 
        dept_id => undef, 
        edi_id => undef, 
        edi_indicator_code => undef, 
        edi_name => undef, 
        generic => undef, 
        rec_id => undef, 
        name => undef, 
    };

    is_deeply_except(
        $exclude,
        eleMentalClinic::Rolodex->retrieve( 
            $one->get_emergency_contacts->[0]->rolodex->id, 
        ),
        {
            fname  => 'Marey',
            lname  => 'Marley',
            comment_text => 'mother',
            #phone_number  => '888-888-8888', Not stored here.
            client_id => $one->client_id,
        }
    );
    #Check the phone record
    is( 
        $one->get_emergency_contacts->[0]->rolodex->phones->[0]->phone_number,
        '888-888-8888'
    );

    is_deeply_except(
        $exclude,
        eleMentalClinic::Rolodex->retrieve( 
            $one->get_emergency_contacts->[1]->rolodex->id,
        ),
        {
            fname  => 'Billybob',
            lname  => 'Marley',
            comment_text => 'father',
            #phone_number  => '999-999-9999',
            client_id => $one->client_id,
        }
    );
    is( 
        $one->get_emergency_contacts->[1]->rolodex->phones->[0]->phone_number,
        '999-999-9999'
    );

    is_deeply_except(
        $exclude,
        eleMentalClinic::Rolodex->retrieve( 
            $one->get_emergency_contacts->[2]->rolodex->id,
        ),
        {
            fname  => 'Jacob',
            lname  => 'Marley',
            comment_text => 'brother',
            #phone_number  => '000-000-0000',
            client_id => $one->client_id,
        }
    );
    is(
        $one->get_emergency_contacts->[2]->rolodex->phones->[0]->phone_number,
        '000-000-0000'
    );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Update emergency contact

    $tmp = {
        phone_number => '565-656-5656',
        comment_text => 'updated today',
        rolodex_id   => $one->get_emergency_contacts->[0]->rolodex->id,
    };

    $one->save_an_emergency_contact( $tmp );
    is(
        $one->get_emergency_contacts->[0]->rolodex->comment_text,
        $tmp->{ comment_text },
    );
    is(
        $one->get_emergency_contacts->[0]->rolodex->phones->[0]->phone_number,
        $tmp->{ phone_number }
    );

    $tmp = {
        phone_number => '565-656-5657',
        comment_text => 'updated yesterday',
        rolodex_id   => $one->get_emergency_contacts->[2]->rolodex->id,
    };

    $one->save_an_emergency_contact( $tmp );
    is(
        $one->get_emergency_contacts->[2]->rolodex->comment_text,
        $tmp->{ comment_text },
    );
    is(
        $one->get_emergency_contacts->[2]->rolodex->phones->[0]->phone_number,
        $tmp->{ phone_number }
    );

    $tmp = {
        phone_number => '565-656-5658',
        comment_text => 'updated NEVER!',
        rolodex_id   => $one->get_emergency_contacts->[1]->rolodex->id,
    };

    # Make sure the old one passes to the new one when an id is provided.
    $one->save_emergency_contact( $tmp );
    is(
        $one->get_emergency_contacts->[1]->rolodex->comment_text,
        $tmp->{ comment_text },
    );
    is(
        $one->get_emergency_contacts->[1]->rolodex->phones->[0]->phone_number,
        $tmp->{ phone_number }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Update multiple emergency contacts
    $tmp = [
        {
            phone_number => '333-333-3333',
            comment_text => 'Lots of 3s',
            rolodex_id   => $one->get_emergency_contacts->[0]->rolodex->id
        },
        {
            phone_number => '444-444-4444',
            comment_text => 'Lots of 4s',
            rolodex_id   => $one->get_emergency_contacts->[1]->rolodex->id
        },
        {
            phone_number => '555-555-5555',
            comment_text => 'Lots of 5s',
            rolodex_id   => $one->get_emergency_contacts->[2]->rolodex->id
        },
        {
            phone_number => '777-777-7777',
            comment_text => 'Lucky 7s',
            lname        => 'ZNew',
            fname        => 'ZGuy',
            client_id => $one->client_id,
        },
    ];

    ok( $one->save_emergency_contacts( $tmp ));
    
    for ( my $i = 0; $i < 4; $i++ ){
        is(
            $one->get_emergency_contacts->[$i]->rolodex->comment_text,
            $tmp->[$i]->{ comment_text },
            'contact number: ' . $i . ' Comment',
        );
        is(
            $one->get_emergency_contacts->[$i]->rolodex->phones->[0]->phone_number,
            $tmp->[$i]->{ phone_number },
            'contact number: ' . $i . ' Phone',
        );
    }

    # Clean up after the tests.
    # dbinit does not clear the rolodex items we add, and I was unable to add it
    # because of key contraints, but this works.
    $tmp = [];
    push (@{ $tmp }, $_->rolodex->id ) foreach (@{ $one->get_emergency_contacts });
    dbinit( 1 );
    foreach (@{ $tmp }) {
        $one->db->do_sql( "delete from rolodex_contacts where rolodex_id = ?", 1, $_ );
        $one->db->do_sql( "delete from rolodex where rec_id = ?", 1, $_ );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# emergency contact
    $one = $CLASS->new;
    can_ok( $one, 'get_emergency_contact' );
   
    is( $one->get_emergency_contact, undef );

        $one->client_id( 1003 );
    is_deeply( $one->get_emergency_contact, $client_contacts->{ 1001 } );
        

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save_emergency_contact
    $one = $CLASS->new;
    can_ok( $one, 'save_emergency_contact' );

    is( $one->save_emergency_contact, undef );

    # update
        $one->client_id( 1003 );
        my $client_contact = $one->get_emergency_contact;
        my $rolodex_contact = $client_contact->rolodex;

        $tmp = {
            fname  => 'Barbara',
            lname  => 'Batty',
            comment_text => 'mother',
            phone_number => '555-444-7777',
        };
    ok( $one->save_emergency_contact( $tmp ));
        my $new_contact = $one->get_emergency_contact;
    is_deeply( $new_contact, $client_contact ); 
    is( $new_contact->rolodex->{ rec_id }, $client_contact->rolodex->{ rec_id } );
    is( $new_contact->rolodex->{ lname }, $tmp->{ lname } );
    isnt( $new_contact->rolodex->{ lname }, $rolodex_contact->{ lname } );
    is(
        $new_contact->rolodex->phones->[0]->phone_number,
        $tmp->{ phone_number },
    );

    # insert
        $one->client_id( 1001 );
        $client_contact = $one->get_emergency_contact;
    is( $client_contact, undef );    
    
        $tmp = {
            fname  => 'Count',
            lname  => 'Basie',
            comment_text => 'friend',
            phone_number  => '555-555-5555',
        };

    ok( $one->save_emergency_contact( $tmp ) );

        $new_contact = $one->get_emergency_contact;
    is( $new_contact->rolodex->{ fname }, $tmp->{ fname } );
    is( $new_contact->rolodex->{ lname }, $tmp->{ lname } );
    is( $new_contact->rolodex->{ comment_text }, $tmp->{ comment_text } );
    is(
        $new_contact->rolodex->phones->[0]->phone_number,
        $tmp->{ phone_number },
    );
        
        # delete the records we just created
        $rolodex_contact = $new_contact->rolodex;
        $test->delete_( 'client_contacts', [ $new_contact->{ rec_id } ] );
        $test->delete_( 'rolodex_contacts', [ $new_contact->{ rolodex_contacts_id } ] );
        $test->delete_( 'rolodex', [ $rolodex_contact->{ rec_id } ] );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# primary treater
    can_ok( $one, 'get_primary_treater' );
   
    is( $one->get_primary_treater, undef );

        $one->client_id( 1003 );
    is( $one->get_primary_treater, undef );
        $one->client_id( 1005 );
    is_deeply( $one->get_primary_treater, $client_treaters->{ 1002 } );
        
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save_primary_treater
    can_ok( $one, 'save_primary_treater' );

    dbinit( 1 );

    is( $one->save_primary_treater, undef );

    # update
        $one->client_id( 1005 );
    is_deeply($one->get_primary_treater, $client_treaters->{1002});
    is_deeply( $one->get_primary_treater->rolodex, $rolodex->{1001});

    $one->save_primary_treater( { primary_treater_rolodex_id => 1011 } );

    my $primary_treater = $one->get_primary_treater;
    isnt($primary_treater->{rolodex_treaters_id}, $client_treaters->{1002}->{rolodex_treaters_id});
    is($primary_treater->{rolodex_treaters_id}, 1001);
    is_deeply($one->get_primary_treater->rolodex, $rolodex->{1011});
    $one->save_primary_treater( { primary_treater_rolodex_id => 1001 } );
    is_deeply($one->get_primary_treater, $client_treaters->{1002});
    is_deeply( $one->get_primary_treater->rolodex, $rolodex->{1001});
   
    # insert
        $one->client_id( 1001 );
    is( $one->get_primary_treater, undef );    
    
    ok( $one->save_primary_treater( { primary_treater_rolodex_id => 1001 } ));

    $primary_treater = $one->get_primary_treater;
    isnt($primary_treater, undef);
    my $primary_treater_rolodex = $one->get_primary_treater->rolodex;
    is_deeply($primary_treater_rolodex, $rolodex->{1001});
        
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# placement basics

    dbinit( 1 );

    can_ok( $one, 'placement' );
    isa_ok( $one->placement, 'eleMentalClinic::Client::Placement' );

        $one->id( 1001 )->retrieve;
    isa_ok( $one->placement, 'eleMentalClinic::Client::Placement' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bug fix for lack of personnel
# bug is:  must call "staff_id" on placement or "personnel" method will not work
        $one->id( 1004 )->retrieve;
    ok( $one->placement->event );
    is( $one->placement->event->staff_id, $client_placement_event->{ 1015 }{ staff_id });
    ok( $one->placement->event->personnel );

    ok( $one->placement->personnel ); # fails with bug
    is_deeply( $one->placement->event->personnel, $one->placement->personnel ); # fails with bug

    is( $one->placement->staff_id, $client_placement_event->{ 1015 }{ staff_id });
    ok( $one->placement->personnel ); # succeeds with bug
    is_deeply( $one->placement->event->personnel, $one->placement->personnel ); # succeeds with bug

        $one->id( 1001 )->retrieve; # reset for next tests

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# placement methods return the same thing as placement event methods
    is_deeply( $one->placement->event, $client_placement_event->{ 1007 });
    # this code calls each Event method on the return value from client->placement
    is( $one->placement->$_, $client_placement_event->{ 1007 }->{ $_ })
        for @{ eleMentalClinic::Client::Placement::Event->fields };
    is( $one->placement->event->$_, $client_placement_event->{ 1007 }->{ $_ })
        for @{ eleMentalClinic::Client::Placement::Event->fields };

    is_deeply( $one->placement( '2005-05-04' )->event, $client_placement_event->{ 1001 });
    is( $one->placement( '2005-05-04' )->$_, $client_placement_event->{ 1001 }->{ $_ })
        for @{ eleMentalClinic::Client::Placement::Event->fields };
    is( $one->placement( '2005-05-04' )->event->$_, $client_placement_event->{ 1001 }->{ $_ })
        for @{ eleMentalClinic::Client::Placement::Event->fields };

    is( $one->placement->program, undef );
    is( $one->placement->active, 0 );
    is( $one->placement->is_admitted, 0 );
    is( $one->placement->is_referral, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# placement specifics
    is_deeply( $one->placement( '2005-05-04' )->program,
        $valid_data_program->{ $client_placement_event->{ 1001 }->{ program_id }}
    );
    is( $one->placement( '2005-05-04' )->active, 1 );
    is( $one->placement( '2005-05-04' )->is_admitted, 1 );
    is( $one->placement( '2005-05-04' )->is_referral, 0 );

    is(        $one->placement( '2000-01-01' )->event, undef );
    is(        $one->placement( '2005-05-03' )->event, undef );
    is_deeply( $one->placement( '2005-05-04' )->event, $client_placement_event->{ 1001 });
    is_deeply( $one->placement( '2006-01-01' )->event, $client_placement_event->{ 1001 });
    is_deeply( $one->placement( '2006-03-14' )->event, $client_placement_event->{ 1001 });
    is_deeply( $one->placement( '2006-03-15' )->event, $client_placement_event->{ 1007 });
    is_deeply( $one->placement( '2006-03-16' )->event, $client_placement_event->{ 1007 });

        $one->id( 1003 )->retrieve;
    is(        $one->placement( '2000-01-01' )->event, undef );
    is(        $one->placement( '2005-02-28' )->event, undef );
    is_deeply( $one->placement( '2005-03-01' )->event, $client_placement_event->{ 1003 });
    is_deeply( $one->placement( '2005-03-16' )->event, $client_placement_event->{ 1003 });
    is_deeply( $one->placement( '2005-03-17' )->event, $client_placement_event->{ 1009 });
    is_deeply( $one->placement( '2005-03-18' )->event, $client_placement_event->{ 1010 });
    is_deeply( $one->placement( '2005-03-24' )->event, $client_placement_event->{ 1010 });
    is_deeply( $one->placement( '2005-03-25' )->event, $client_placement_event->{ 1012 });
    is_deeply( $one->placement( '2005-04-01' )->event, $client_placement_event->{ 1013 });
    is_deeply( $one->placement( '2005-05-01' )->event, $client_placement_event->{ 1013 });

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_referral, tested in placement
# is_admitted, tested in placement
# was_referral, tested in placement

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# placement referral
        $one = $CLASS->new;

    is( $one->placement->referral, undef );

        $one->client_id( 1001 )->retrieve;
    is( $one->placement->referral, undef );
    is( $one->placement( '2005-04-01' )->referral, undef );

        $one->client_id( 1002 )->retrieve;
    is( $one->placement->referral, undef );

        $one->client_id( 1003 )->retrieve;
    is( $one->placement( '2000-04-01' )->referral, undef );
    isa_ok( $one->placement->referral, 'eleMentalClinic::Client::Referral' );
    is_deeply( $one->placement->referral, $client_referral->{ 1001 });

        $one->client_id( 1005 )->retrieve;
    is( $one->placement( '2000-04-01' )->referral, undef );
    isa_ok( $one->placement->referral, 'eleMentalClinic::Client::Referral' );
    is_deeply( $one->placement->referral, $client_referral->{ 1002 });

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# placement discharge
        $one = $CLASS->new;

    is( $one->placement->discharge, undef );

        $one->client_id( 1001 )->retrieve;
    is( $one->placement->discharge, undef );
    isa_ok( $one->placement( '2005-06-01' )->discharge, 'eleMentalClinic::Client::Discharge' );
    is_deeply( $one->placement( '2005-06-01' )->discharge, $client_discharge->{ 1001 });

        $one->client_id( 1002 )->retrieve;
    is( $one->placement->discharge, undef );
    isa_ok( $one->placement( '2005-04-01' )->discharge, 'eleMentalClinic::Client::Discharge' );
    is_deeply( $one->placement( '2005-04-01' )->discharge, $client_discharge->{ 1002 });

        $one->client_id( 1003 )->retrieve;
    is( $one->placement->discharge, undef );

        $one->client_id( 1004 )->retrieve;
    is( $one->placement->discharge, undef );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# placement changes
        $one->client_id( 1003 )->retrieve;
    ok( $one->placement->change(
        program_id          => 1002,
        level_of_care_id    => 1002,
        staff_id            => 1,
        event_date          => '2006-04-15',
    ));
    ok( $one->placement->rec_id                > max(keys %{ $client_placement_event }));
    is( $one->placement->client_id,            $client_placement_event->{ 1013 }->{ client_id });
    is( $one->placement->dept_id,              $client_placement_event->{ 1013 }->{ dept_id });
    is( $one->placement->program_id,           1002 );
    is( $one->placement->level_of_care_id,     1002 );
    is( $one->placement->staff_id,             1 );
    is( $one->placement->event_date,           '2006-04-15' );
    like( $one->placement->input_date,         qr/\d{4}-\d{2}-\d{2}/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    can_ok( $one, 'save' );
    # TODO blows chunks here because dept_id is undef
    #is( $one->save, undef );

    #insert
        $tmp = {
            fname    => 'Thera',
            lname    => 'Memory',
            intake_step => 1,
        };
        $one = $CLASS->new( $tmp );
    ok( $one->save );

    #defaults
    ok( $one->id );
    like( $one->id, qr/^\d+$/ );
    ok( $one->id > max(keys %{ $client }));
    is( $one->has_declaration_of_mh_treatment, 0 );
    is( $one->section_eight, 0 );

    # from constructor
    is( $one->fname,    $tmp->{ fname } );
    is( $one->lname,    $tmp->{ lname } );
    is( $one->intake_step, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make sure we can save all the data we have
# this is a bug-fix test for putting birth_name in fields() but not in the save() method
# the proper result is to remove the data from save() entirely

        %tmp = %{ $client->{ 1005 }};
        delete $tmp{ client_id };
    ok( $tmp = $CLASS->new( \%tmp ));
    ok( $tmp->save );
    is_deeply_except(
        { client_id => undef }, 
        $CLASS->retrieve( $tmp->id ),
        $client->{ 1005 }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# brief detour for intake_step
    ok( $one->intake_step( 2 ));
    ok( $one->save );
    is( $one->intake_step, 2 );
    ok( $one->intake_step( 3 ));
    ok( $one->retrieve );
    is( $one->intake_step, 2 );

        $tmp = $one;
    is_deeply( $one->retrieve, $tmp );

    # placement
    is( $one->placement->client_id, $one->id );
    is( $one->placement->dept_id, undef );
    is( $one->placement->program_id, undef );
    is( $one->placement->level_of_care_id, undef );
    is( $one->placement->staff_id, undef );
    is( $one->placement->event_date, undef );
    is( $one->placement->input_date, undef );

    is( $one->placement->change, undef );
    is( $one->placement->client_id, $one->id );
    is( $one->placement->dept_id, undef );
    is( $one->placement->program_id, undef );
    is( $one->placement->level_of_care_id, undef );
    is( $one->placement->staff_id, undef );
    is( $one->placement->event_date, undef );
    is( $one->placement->input_date, undef );

    ok( $one->placement->change(
        staff_id => 1,
    ));
    is( $one->placement->client_id, $one->id );
    is( $one->placement->dept_id, undef );
    is( $one->placement->program_id, undef );
    is( $one->placement->level_of_care_id, undef );
    is( $one->placement->staff_id, 1 );
    is( $one->placement->event_date, undef );
    like( $one->placement->input_date, qr/\d{4}-\d{2}-\d{2}/ );

        $tmp = {
            fname    => 'Gordon',
            lname    => 'Lee',
            has_declaration_of_mh_treatment => 6,
            section_eight => 7,
        };
        $one = $CLASS->new( $tmp );
    ok( $one->save );
        $tmp = $one;

    ok( $one->id );
    is( $one->has_declaration_of_mh_treatment, $tmp->{ has_declaration_of_mh_treatment } );
    is( $one->section_eight, $tmp->{ section_eight } );
    is( $one->language_spoken, $tmp->{ language_spoken } );

    ok( $one->placement->change(
        dept_id     => 1001,
        program_id  => 1002,
        staff_id    => 1003,
        level_of_care_id    => 1004,
        event_date  => '2006-04-14',
    ));
    is( $one->placement->client_id, $tmp->id );
    is( $one->placement->dept_id, 1001 );
    is( $one->placement->program_id, 1002 );
    is( $one->placement->level_of_care_id, 1004 );
    is( $one->placement->staff_id, 1003 );
    is( $one->placement->event_date, '2006-04-14' );
    like( $one->placement->input_date, qr/\d{4}-\d{2}-\d{2}/ );

    is_deeply( $one->retrieve, $tmp );

        $tmp->{ language_spoken } = 'piano';

    #update
    ok( $one->language_spoken( $tmp->{ language_spoken } ) );
    ok( $one->save );

    is( $one->language_spoken, $tmp->{ language_spoken } );
    is_deeply( $one->retrieve, $tmp );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save - Simple fields last_called, renewal_date, last_doctor_id
# (Testing of last_doctor_id complicated by circular dependency 
# between rolodex <-> client (client.last_doctor_id and rolodex.client_id))

    $tmp = {
        fname    => 'Thera',
        lname    => 'Memory',
        mname    => 'M',
    };
    $one = $CLASS->new( $tmp );
    is( $one->renewal_date, undef);
    $one->update( {
        renewal_date   => '1/1/2006',
    } );
    is( $one->renewal_date, '1/1/2006');
    $one->update( {
        renewal_date => '',
    } );
    is( $one->renewal_date, undef);
#TODO: {
#    local $TODO = q/Should be able to set a field to null.  This is really a base update() method issue./;
    $one->update( {
        renewal_date => '1/1/2006',
    } );
    is( $one->renewal_date, '1/1/2006');
    is( $one->mname, 'M');
    $one->update( {
        renewal_date   => undef,
        mname          => undef,
    } );
    is( $one->mname, undef);
    is( $one->renewal_date, undef);
#}
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# legal_past_issues
# wrapper
    can_ok( $one, 'legal_past_issues' );
    is( $one->legal_past_issues, undef );

        $tmp = $one->legal_past_issues( 1002 );
    is_deeply( $tmp->[0], $client_legal_history->{ 1001 } );
    is_deeply( $tmp->[1], $client_legal_history->{ 1002 } );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# legal_get_all
# wrapper
    can_ok( $one, 'legal_get_all' );
    is( $one->legal_get_all, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# legal_current_issues
# wrapper
    can_ok( $one, 'legal_current_issues' );
    is( $one->legal_current_issues, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# roi
# wrapper
    can_ok( $one, 'roi' );
        
        $one->client_id( 1001 );
        $tmp = $one->roi;
    isa_ok( $tmp, 'eleMentalClinic::Client::Release' );
    is( $tmp->{ client_id }, 1001 );
        
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# letter
# wrapper
    can_ok( $one, 'letter' );

        $one->client_id( 1001 );
        $tmp = $one->letter;
    isa_ok( $tmp, 'eleMentalClinic::Client::Letter' );
    is( $tmp->{ client_id }, 1001 );

        $one = $CLASS->new;

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## insurance_getone
## wrapper
#    can_ok( $one, 'insurance_getone' );
#    is( $one->insurance_getone, undef );
#
#    is( $one->insurance_getone({
#        carrier_type => 'mental health',
#    }), undef );
#
#    is( $one->insurance_getone({
#        rank => 3,
#    }), undef );
#
#    is( $one->insurance_getone({
#        date => '2002-05-02',
#    }), undef );
#
#    is( $one->insurance_getone({
#        carrier_type => 'mental health',
#        rank => 2,
#    }), undef );
#
#    is( $one->insurance_getone({
#        carrier_type => 'mental health',
#        date => '2002-05-02',
#    }), undef );
#
#    is( $one->insurance_getone({
#        rank => 2,
#        date => '2002-05-02',
#    }), undef );
#
#        $one->client_id( 1003 );
#    ok( $one->insurance_getone({
#        carrier_type => 'mental health',
#        rank => 2,
#        date => '2002-05-02',
#    }) );
#
#        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# insurance_bytype
# wrapper
    can_ok( $one, 'insurance_bytype' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# progress_notes
# wrapper
    can_ok( $one, 'progress_notes' );
    is( $one->progress_notes, undef );
    is( $one->progress_notes( '2004-01-01', '2005-05-31' ), undef );

        $one->client_id( 1001 );
    ok( $one->progress_notes( '2004-01-01', '2005-05-31' ) );
    
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_all_progress_notes
# wrapper
    can_ok( $one, 'get_all_progress_notes' );
    is( $one->get_all_progress_notes, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# roi_history
# wrapper
    can_ok( $one, 'roi_history' );
    is( $one->roi_history, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# treatment_plans
# wrapper
    can_ok( $one, 'treatment_plans' );
    is( $one->treatment_plans, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# allergies
# wrapper
    can_ok( $one, 'allergies' );
    is( $one->allergies, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# hospital_history
# wrapper
    can_ok( $one, 'hospital_history' );
    is( $one->hospital_history, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# medication_history
# wrapper
    can_ok( $one, 'medication_history' );
    is( $one->medication_history, undef );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex_byrole
    can_ok( $one, 'rolodex_byrole' );
    is( $one->rolodex_byrole, undef );
    is( $one->rolodex_byrole( 'referral' ), undef );

        $one->client_id( 999 );
    is( $one->rolodex_byrole( 'referral' ), undef );

        $one->client_id( 1003 );
    is( $one->rolodex_byrole( 'frog' ), undef );
        
    is_deeply( $one->rolodex_byrole( 'referral', 1 ), [ $rolodex->{ 1010  } ] );

    is_deeply( $one->rolodex_byrole( 'mental_health_insurance' ), [ 
        $rolodex->{ 1013 },
        $rolodex->{ 1014 },
        $rolodex->{ 1015 },
    ]);
    is_deeply( $one->rolodex_byrole( 'mental_health_insurance', 1 ), [ 
        $rolodex->{ 1013 },
        $rolodex->{ 1014 },
        $rolodex->{ 1015 },
    ]);

    is( $one->rolodex_byrole( 'treaters' ), undef );

    is_deeply( $one->rolodex_byrole( 'contacts' ), [
        $rolodex->{ 1001 },
        $rolodex->{ 1002 },
        $rolodex->{ 1010 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# relationship_byrole
        $one = $CLASS->new;
    can_ok( $one, 'relationship_byrole' );
    throws_ok{ $one->relationship_byrole } qr/Role is required/;

        $one->client_id( 1003 );
    throws_ok{ $one->relationship_byrole } qr/Role is required/;

    # contacts are returned ordered by role
    is_deeply( $one->relationship_byrole( 'contacts' ), [
        $client_contacts->{ 1001 },
        $client_contacts->{ 1002 },
        $client_contacts->{ 1003 },
    ]);

    # bug-fix for removing 'active' from client_insurance table
    is_deeply( $one->relationship_byrole( 'mental_health_insurance', undef, 1 ), [
        $client_insurance->{ 1003 },
        $client_insurance->{ 1004 },
        $client_insurance->{ 1005 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex_associate
        $one = $CLASS->new;
    can_ok( $one, 'rolodex_associate' );
    is( $one->rolodex_associate, undef );
    is( $one->rolodex_associate( 'referral' ), undef );
    is( $one->rolodex_associate( 'referral', 1001 ), undef );
    
        $one->client_id( 1003 );
    is( $one->rolodex_associate( 'contacts', 999 ), undef );
   
        # this will insert a record
        # so we need to delete it too.
        $tmp = $one->rolodex_associate( 'contacts', 1001 );
        my $max = max(keys %{$client_contacts});
    is( $tmp, $one->db->do_sql("select max(rec_id) from client_contacts where rec_id > $max")->[0]->{ max } );
        $test->delete_( 'client_contacts', [ $tmp ] );
   
        # update an existing record
        $one->client_id( 1003 );
        $tmp = $one->rolodex_associate( 'mental_health_insurance', 1006, 1003 );
    is( $tmp, 1003 );
    
        $one->client_id( 1003 );
        $tmp = $one->rolodex_associate( 'referral', 1010, 1001 );
    is( $tmp, 1001 );
    
        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rolodex_getone
    can_ok( $one, 'rolodex_getone' );
    is( $one->rolodex_getone, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ssn_f
# TODO test when ssn isn't in the correct format '
    can_ok( $one, 'ssn_f' );
    is( $one->ssn_f, undef );

        $one->ssn( '' );
    is( $one->ssn_f, undef );
    
        $one->ssn( '123456789' );
    is( $one->ssn_f, '123-45-6789' );

    is( $one->ssn_f( '987654321' ), '987654321' );
   
    is( $one->ssn_f( '987-65-4321' ), '987-65-4321' );
    is( $one->ssn, '987654321' );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# phone_f

        SKIP: {
            # TODO test when phone isn''t in the correct format
            skip "These tests will BREAK", 6;
            can_ok( $one, 'phone_f' );
            is( $one->phone_f, undef );

            $one->phone( '1234567890' );
            is( $one->phone_f, '123-456-7890' );
            is( $one->phone, '1234567890' );

            is( $one->phone_f( '098-765-4321' ), '098-765-4321' );
            is( $one->phone, '0987654321' );

        }

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prescribers
# wrapper, no tests needed
    can_ok( $one, 'prescribers' );
    is( $one->prescribers, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# assessment_getall
# wrapper
    can_ok( $one, 'assessment_getall' );
    is( $one->assessment_getall, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# assessment_listall
# wrapper
    can_ok( $one, 'assessment_listall' );
    is( $one->assessment_listall, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# assessment

        $one = $CLASS->new;
        $one->client_id( 1001 )->retrieve;
    can_ok( $one, 'assessment' );
    is_deeply( $one->assessment, $client_assessment->{ 1002 });

        $one->client_id( 1005 )->retrieve;
    is( $one->assessment, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# income_history
# wrapper
    can_ok( $one, 'income_history' );
    is( $one->income_history, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dup_check

    sub filter_dup {
        my $client = shift;
        my $dup = {};
        $dup->{ $_ } = $client->{ $_ } for @{ $CLASS->_dup_fields };
        return $dup;
    }

        $one = $CLASS->new;
    can_ok( $one, 'dup_check' );
    is_deeply( $one->dup_check, {
        ssn => undef,
        lname_dob => undef,
    });

    # no duplicates for this fake SSN
        $one->ssn( '6666' );
    is( $one->dup_check->{ ssn }, undef);

    # duplicate using an existing SSN
        $one->ssn( $client->{ 1002 }->{ ssn });
    is_deeply( $one->dup_check->{ ssn }, filter_dup( $client->{ 1002 }));

    # no duplicate using an existing SSN and the same client_id
    # bug-fix:  this used to fail
        $one->client_id( 1002 );
    is_deeply( $one->dup_check->{ ssn }, undef );

    # no duplicates with only the same last name
        $one = $CLASS->new;
        $one->lname( $client->{ 1002 }->{ lname } );
    is( $one->dup_check->{ lname_dob }, undef);

    # no duplicates with only the same DOB
        $one = $CLASS->new;
        $one->dob( $client->{ 1002 }->{ dob } );
    is( $one->dup_check->{ lname_dob }, undef);

    # no duplicates with last name and DOB both present, but with different clients
        $one = $CLASS->new;
        $one->lname( $client->{ 1001 }->{ lname } );
        $one->dob( $client->{ 1002 }->{ dob } );
    is( $one->dup_check->{ lname_dob }, undef);

    # duplicates with last name and DOB
        $one = $CLASS->new;
        $one->lname( $client->{ 1002 }->{ lname } );
        $one->dob( $client->{ 1002 }->{ dob } );
    is_deeply( $one->dup_check->{ lname_dob }, [ filter_dup( $client->{ 1002 })]);

    # duplicates with ( last name, DOB ) from one client and SSN from another
        $one = $CLASS->new;
        $one->lname( $client->{ 1001 }->{ lname } );
        $one->dob( $client->{ 1001 }->{ dob } );
        $one->ssn( $client->{ 1003 }->{ ssn } );
    is_deeply( $one->dup_check, {
        ssn => filter_dup( $client->{ 1003 }),
        lname_dob => [ filter_dup( $client->{ 1001 })],
    } );

    # duplicates with same first and last name
        $one = $CLASS->new;
        $one->lname( $client->{1001}->{lname} );
        $one->fname( $client->{1001}->{fname} );
    is_deeply( $one->dup_check, {
        lname_dob => undef,
        lname_fname => [ filter_dup( $client->{1001})],
        ssn => undef,
    } );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# income_metadata
# wrapper
    can_ok( $one, 'income_metadata' );
    is( $one->income_metadata, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diagnosis_history
# wrapper
    can_ok( $one, 'diagnosis_history' );
    is( $one->diagnosis_history, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# name
    can_ok( $one, 'name' );
    is( $one->name, undef );

    #f
        $one->fname( 'Mel' );
    is( $one->name, 'Mel' );

    #l
        $one = $CLASS->new;
        $one->lname( 'Brown' );
    is( $one->name, 'Brown' );

    #fl
        $one = $CLASS->new;
        $one->fname( 'Mel' );
        $one->lname( 'Brown' );
    is( $one->name, 'Mel Brown' );

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# eman
    can_ok( $one, 'eman' );
    is( $one->eman, undef );

    #f
        $one->fname( 'Dan' );
    is( $one->eman, 'Dan' );

    #l
        $one = $CLASS->new({
            lname => 'Balmer',
        });
    is( $one->eman, 'Balmer' );

    #m
        $one = $CLASS->new({
            mname => 'J',
        });
    is( $one->eman, undef );

    #fl
        $one = $CLASS->new({
            fname => 'Dan',
            lname => 'Balmer',
        });
    is( $one->eman, 'Balmer, Dan' );

    #fm
        $one = $CLASS->new({
            fname => 'Dan',
            mname => 'J',
        });
    is( $one->eman, 'Dan J' );

    #lm
        $one = $CLASS->new({
            mname => 'J',
            lname => 'Balmer',
        });
    is( $one->eman, 'Balmer, J' );

    #fml
        $one = $CLASS->new({
            fname => 'Dan',
            mname => 'J',
            lname => 'Balmer',
        });
    is( $one->eman, 'Balmer, Dan J' );

        $one = $CLASS->new;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# mental_health_provider
# wrapper
    can_ok( $one, 'mental_health_provider' );

    # doing the search for today, coming back with undef
        $one->client_id( 1001 );
    is( $one->mental_health_provider, undef );

    # passing in a date, getting back a record
    is_deeply( $one->mental_health_provider( $client_insurance->{ 1006 }{ start_date }),
        $client_insurance->{ 1006 }
    );

    # set an insurance record to cover today
        $test->db->update_one(
            'client_insurance',
            ['end_date'],
            [ join('-', Today ) ],
            'rec_id = 1006'
        );
        $one->client_id( $client_insurance->{ 1006 }->{ client_id } );
        $client_insurance->{ 1006 }{ end_date } = join('-', Today );
        $client_insurance->{ 1006 }{ end_date } =~ s/-(\d{1})-/-0$1-/g;
        $client_insurance->{ 1006 }{ end_date } =~ s/-(\d{1})$/-0$1/g;

    # doing the same search for today, coming back with something
    is_deeply( $one->mental_health_provider, $client_insurance->{ 1006 });

        $one = $CLASS->new;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# relationship_getone

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# release_agencies
    can_ok( $one, 'release_agencies' );
    is( $one->release_agencies, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# filter_by_show_inactive
    can_ok( $one, 'filter_by_show_inactive' );
    is( $one->filter_by_show_inactive( 'release_agencies', 0 ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_groups
# wrapper
    can_ok( $one, 'get_groups' );
    is( $one->get_groups, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# group_history
# wrapper
    can_ok( $one, 'group_history' );
    is( $one->group_history, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# uncommitted_attendees
# wrapper
    can_ok( $one, 'uncommitted_attendees' );
    is( $one->uncommitted_attendees, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# previous_note_writers
    can_ok( $one, 'previous_note_writers' );

        $one->client_id( 1003 );
    is_deeply( 
        $one->previous_note_writers,
        [
            $personnel->{ 1002 },
            $personnel->{ 1001 },
            $personnel->{ 1003 },
        ]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# verification_letters
    can_ok($one,'verification_letters');
    
    $one->client_id( 1001 );
    is_deeply( $one->verification_letters, [
        $client_verification->{ 1001 },
        $client_verification->{ 1002 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# locked level of care
        $one = $CLASS->retrieve( 1001 );
    is( $one->placement->level_of_care_locked, 0 );

    is( $one->placement->level_of_care_locked( 1 ), 1 );
    is( $one->placement->level_of_care_locked, 1 );
        $one = $CLASS->retrieve( 1001 );
    is( $one->placement->level_of_care_locked, 1 ); # retrieve from database

    is( $one->placement->level_of_care_locked( 0 ), 0 );
    is( $one->placement->level_of_care_locked, 0 );
        $one = $CLASS->retrieve( 1001 );
    is( $one->placement->level_of_care_locked, 0 ); # retrieve from database

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billed progress notes
        $one = $CLASS->new;
    can_ok( $one, 'prognotes_billed' );
    throws_ok{ $one->prognotes_billed } qr/Must be called on stored object/;

        $one = $CLASS->retrieve( 1003 );
    is( $one->prognotes_billed, undef );

    $test->financial_setup( 1 );
    is( scalar @{ $one->prognotes_billed }, 6 );
    is_deeply( ids( $one->prognotes_billed ), [
        qw/ 1048 1047 1046 1045 1044 1043 /
    ]);
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_partial_intake
    $one = $CLASS->retrieve(1001);

    can_ok ($one, 'is_partial_intake');

    $one->intake_step(undef);
    $one->save;

    ok(!$one->is_partial_intake);

    $one->intake_step(5);
    $one->save;

    ok($one->is_partial_intake);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# mimic an intake

    dbinit(1); 
    $one = $CLASS->new;
    ok $one->fname('moo');
    ok $one->lname('milky');
    ok $one->dob('1978-04-06');
    lives_ok { $one->save };

    $one = $CLASS->retrieve($one->client_id);
    is($one->fname, 'moo');
    is($one->lname, 'milky');
    is($one->dob, '1978-04-06');

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $one = $CLASS->retrieve( 1001 );

# readmit, is_discharged
    dbinit( 1 );
    $one = $CLASS->retrieve( 1001 ); # Davis
    ok( $one->is_discharged, 'client is discharged' );
    ok( ! $one->placement->episode, 'client is not in an episode' );
    lives_ok {
        $one->readmit(
            program_id          => 1002,
            level_of_care_id    => 1002,
            staff_id            => 1,
        )
    } 'client readmitted';
    my $e = eleMentalClinic::Client::Placement::Episode->new({
        client_id => $one->id,
    });
    ok( ! $one->is_discharged, 'client is no longer discharged' );
    ok( $one->placement->episode, 'client is in an episode again' );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
