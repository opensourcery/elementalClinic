# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 574;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, $client, $result, $rdx);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Intake';
    use_ok( q/eleMentalClinic::Controller::Base::Intake/ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

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
        home 
        step1 step1_save
        step2 step2_save
        step3 step3_save
        step4 step4_save
        step5 step5_save
        _address
        _phone
        _emergency_contact
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home
        step1 step1_save
        step2 step2_save
        step3 step3_save
        step4 step4_save
        step5 step5_save
        _address
        _phone
        _emergency_contact
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step1
    # precedence for client:
    # 1. object or vars passed in to sub
    # 2. $self->client
    # 3. undef
    throws_ok{ $one->step1( 'foo' )} qr/Client must be a hashref or a ::Client object/;
    is_deeply( $one->step1( eleMentalClinic::Client->retrieve( 1001 )), {
        step        => 1,
        client      => eleMentalClinic::Client->retrieve( 1001 ),
        dupsok      => 0,
        duplicates  => 0,
    });
    is_deeply( $one->step1({ client_id => 666 }), {
        step        => 1,
        client      => { client_id => 666 },
        dupsok      => 0,
        duplicates  => 0,
    });

    is_deeply( $one->step1, {
        step        => 1,
        client      => { },
        dupsok      => 0,
        duplicates  => 0,
    });

    # now we need to inject variables into the controller
        $one = $CLASS->new_with_cgi_params(client_id => 1001);
    is_deeply( $one->step1, {
        step        => 1,
        client      => eleMentalClinic::Client->retrieve(1001),
        dupsok      => 0,
        duplicates  => 0,
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step1
    # this is the test new client, with good data
        $client = {
            fname => 'Johnny',
            mname => 'Allen',
            lname => 'Hendrix',
            birth_name => 'Same',
            sex => 'Male',
            ssn => '121-33-4554',
            dob => '1942-11-22',
            client_id => undef,
        };
        $one = $CLASS->new_with_cgi_params( op => 'step1_save', %$client );

    ok( $result = $one->step1_save );
        $client->{ client_id } = $result->{ forward_args }[ 0 ]{ client_id };
        $client->{ ssn } =~ s/-//g;

    is_deeply( $result, {
        forward => 'step2',
        forward_args => [{ client_id => $client->{ client_id }}],
    });
    is( eleMentalClinic::Client->retrieve( $client->{ client_id })->$_, $client->{ $_ })
        for qw/ fname mname lname birth_name sex ssn dob client_id /;

    # ok, let's try it again with a client id, and make sure we can update an existing record
        @$client{ qw/ fname mname dob /} = ( 'Jimi', 'Marshall', '1942-11-28' );
        # delete $client->{ birth_name }; # FIXME this is a special case -- it will ignore the undef value
        $one = $CLASS->new_with_cgi_params( op => 'step1_save', %$client );
    ok( $result = $one->step1_save );

    is_deeply( $result, {
        forward => 'step2',
        forward_args => [{ client_id => $client->{ client_id }}],
    });
    cmp_deeply( # de-reference & reference necessary to avoid checking "blessed"
        { %{ eleMentalClinic::Client->retrieve( $client->{ client_id })} },
        superhashof( $client )
    );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# duplicate detection, finding same SSN
        $one = $CLASS->new_with_cgi_params( op => 'step1_save',
            fname => 'Foo',
            lname => 'Foo',
            sex => 'Male',
            ssn => '121-33-4554',
        );
    ok( $result = $one->step1_save );

    # we have to manipulate this with tongs in some places, because the data's volatile
    # and Test::Deep is too twitchy about objects
    is( scalar keys %$result, 4 );
    is_deeply([ sort keys %$result ], [ qw/ client duplicates dupsok step /]);

    cmp_deeply(
        { %{ $result->{ client }}},
        superhashof({
            fname => 'Foo',
            lname => 'Foo',
            sex => 'Male',
            ssn => '121334554',
        })
    );
    is( $result->{ duplicates }{ lname_dob }, undef );
    isa_ok( $result->{ duplicates }{ ssn }, 'eleMentalClinic::Client' );
    is( $result->{ duplicates }{ ssn }->id, $client->{ client_id });
    is( $result->{ dupsok }, 'dups_ok' );
    is( $result->{ step }, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# duplicate detection, finding same last name/DOB
        $one = $CLASS->new_with_cgi_params( op => 'step1_save',
            fname => 'James',
            lname => 'Hendrix',
            sex => 'Male',
            dob => '1942-11-28',
        );
    ok( $result = $one->step1_save );

    is( scalar keys %$result, 4 );
    is_deeply([ sort keys %$result ], [ qw/ client duplicates dupsok step /]);

    cmp_deeply(
        { %{ $result->{ client }}},
        superhashof({
            fname => 'James',
            lname => 'Hendrix',
            sex => 'Male',
            dob => '1942-11-28',
        })
    );
    is( $result->{ duplicates }{ ssn }, undef );
    is( scalar @{ $result->{ duplicates }{ lname_dob }}, 1 );
    isa_ok( $result->{ duplicates }{ lname_dob }->[ 0 ], 'eleMentalClinic::Client' );
    is( $result->{ duplicates }{ lname_dob }->[ 0 ]->id, $client->{ client_id });
    is( $result->{ dupsok }, 'dups_ok' );
    is( $result->{ step }, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# duplicate detection, finding same last name/DOB, but forcing it through
        $one = $CLASS->new_with_cgi_params( op => 'step1_save',
            fname => 'James',
            lname => 'Hendrix',
            sex => 'Male',
            dob => '1942-11-28',
            dupsok => 1,
        );
    ok( $result = $one->step1_save );

    is( $result->{ forward }, 'step2' );
    like( $result->{ forward_args }[ 0 ]{ client_id }, qr/^\d+$/ );

=for DUPLICATE_DETECTION#{{{
        $tmp = eleMentalClinic::Client->retrieve(1001);
        $one = $CLASS->new_with_cgi_params(
            client_id => 1001,
            ssn       => $tmp->ssn
        );
    is_deeply( $one->step1_save, {
        client     => $tmp,
        duplicates => {
            lname_dob => undef,
            ssn       => eleMentalClinic::Client->retrieve(1001),
        },
        dupsok => 0,
        step   => 1,
    });

    $one = $CLASS->new_with_cgi_params(
        op => 'step1_save',
        client_id => 666,
        fname => 'Monkey',
        lname => $tmp->lname,
        dob => $tmp->dob,
        sex => 'male',
        dupsok => 0,
    );

    is_deeply(
        $one->step1_save,
        {
            'client' => bless(
                {
                    'acct_id'                          => undef,
                    'aka'                              => undef,
                    'alcohol_abuse'                    => undef,
                    'birth_name'                       => undef,
                    'chart_id'                         => undef,
                    'client_id'                        => undef,
                    'comment_text'                     => undef,
                    'consent_to_treat'                 => undef,
                    'declaration_of_mh_treatment_date' => undef,
                    'dependents_count'                 => undef,
                    'dob'                              => '1926-05-25',
                    'dont_call'                        => undef,
                    'edu_level'                        => undef,
                    'email'                            => undef,
                    'fname'                            => 'Monkey',
                    'gambling_abuse'                   => undef,
                    'has_declaration_of_mh_treatment'  => undef,
                    'household_annual_income'          => undef,
                    'household_population'             => undef,
                    'household_population_under18'     => undef,
                    'intake_step'                      => undef,
                    'is_citizen'                       => undef,
                    'is_veteran'                       => undef,
                    'language_spoken'                  => undef,
                    'living_arrangement'               => undef,
                    'lname'                            => 'Davis',
                    'marital_status'                   => undef,
                    'mname'                            => undef,
                    'name_suffix'                      => undef,
                    'nationality_id'                   => undef,
                    'race'                             => undef,
                    'religion'                         => undef,
                    'renewal_date'                     => undef,
                    'section_eight'                    => undef,
                    'send_notifications'               => undef,
                    'sex'                              => 'male',
                    'sexual_identity'                  => undef,
                    'ssn'                              => undef,
                    'state_specific_id'                => undef,
                    'substance_abuse'                  => undef,
                    'working'                          => undef
                },
                'eleMentalClinic::Client'
            ),
            'duplicates' => {
                'lname_dob' => [ eleMentalClinic::Client->retrieve(1001) ],
                'ssn' => undef
            },
            'dupsok' => 0,
            'step'   => 1
        }
    );
    
    dbinit(1);

    $one = $CLASS->new_with_cgi_params(
        op => 'step1_save',
        client_id => 666,
        lname => "Foobar" 
    );

    my $ret = [$one->step1_save];
    $tmp = [ undef, { forward => 'step2', forward_args => [{ client_id => 666 }] } ];

    is_deeply($ret, $tmp);
=cut#}}}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step2

        $one = $CLASS->new_with_cgi_params(client_id => $client->{ client_id });
    is_deeply( $one->step2,
        {
            client => eleMentalClinic::Client->retrieve( $client->{ client_id }),
            step => 2,
            client_addresses_count => 1,         
            client_phones_count => 1,   
            client_emergency_count => 1,
            no_address   => 0,
            no_phone     => 0,
            no_emergency => 0,
        }
    );

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->{ client_id },
        no_address => 1,
        no_phone => 1,
        no_emergency => 1,
    );
    is_deeply( $one->step2,
        {
            client => eleMentalClinic::Client->retrieve( $client->{ client_id }),
            step => 2,
            client_addresses_count => 1,         
            client_phones_count => 1,   
            client_emergency_count => 1,
            no_address   => 1,
            no_phone     => 1,
            no_emergency => 1,
        }
    );

    #Test getting the cliant through args instead of CGI
        $one = $CLASS->new;
    is_deeply( $one->step2({ client_id => $client->{ client_id }}),
        {
            client => eleMentalClinic::Client->retrieve( $client->{ client_id }),
            step => 2,
            client_addresses_count => 1,         
            client_phones_count => 1,   
            client_emergency_count => 1,
            no_address   => 0,
            no_phone     => 0,
            no_emergency => 0,
        }
    );

    # Test for ticket #76
    $one = $CLASS->new_with_cgi_params(
        op => 'step2_save',
        client_id => $client->{ client_id },
        email => 'jimi@hendrix.com',

        'client_address[0][address1]' => '123 Foobar Way',
        'client_address[0][address2]' => 'Apt. B',
        'client_address[0][city]'    => 'monkey',
        'client_address[0][state]'   => 'OR',
        'client_address[0][post_code]' => 97504,
        'client_address[0][county]' => 'Washatoga',
        'client_address[0][active]' => 'on',
        'client_address[1][address1]' => '223 Foobar Way',
        'client_address[1][address2]' => 'Apt. C',
        'client_address[1][city]'    => 'monkey',
        'client_address[1][state]'   => 'OR',
        'client_address[1][post_code]' => 97504,
        'client_address[1][county]' => 'Washatoga',
        'client_address[1][active]' => 'on',
        client_address_primary => 0,

        'client_phone[0][phone_number]' => '123-456-7890',
        'client_phone[0][phone_type]' => '123-456-7890',
        'client_phone[0][call_ok]' => 'on',
        'client_phone[0][message_ok]' => 'on',
        'client_phone[0][active]' => 'on',
        'client_phone[1][phone_number]' => '123-456-7891',
        'client_phone[1][phone_type]' => '123-456-7891',
        'client_phone[1][call_ok]' => 'on',
        'client_phone[1][message_ok]' => 'on',
        'client_phone[1][active]' => 'on',
        client_phone_primary => 0,

        'client_emergency_contact[0][fname]' => 'Foo',
        'client_emergency_contact[0][lname]' => 'Bar',
        'client_emergency_contact[0][phone_number]' => '223-456-7890',
        'client_emergency_contact[0][comment_text]' => 'Friend',
        'client_emergency_contact[1][fname]' => 'Foox',
        'client_emergency_contact[1][lname]' => 'Barx',
        'client_emergency_contact[1][phone_number]' => '223-456-7891',
        'client_emergency_contact[1][comment_text]' => 'Friendx',
    );
    is_deeply( $one->step2,
        {
            client => eleMentalClinic::Client->retrieve( $client->{ client_id }),
            step => 2,
            client_addresses_count => 2,         
            client_phones_count => 2,   
            client_emergency_count => 2,
            no_address   => 0,
            no_phone     => 0,
            no_emergency => 0,
        }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step2_save
        $one = $CLASS->new_with_cgi_params(
            op => 'step2_save',
            client_id => $client->{ client_id },
            email => 'jimi@hendrix.com',

            'client_address[0][address1]' => '123 Foobar Way',
            'client_address[0][address2]' => 'Apt. B',
            'client_address[0][city]'    => 'monkey',
            'client_address[0][state]'   => 'OR',
            'client_address[0][post_code]' => 97504,
            'client_address[0][county]' => 'Washatoga',
            'client_address[0][active]' => 'on',
            client_address_primary => 0,

            'client_phone[0][phone_number]' => '123-456-7890',
            'client_phone[0][phone_type]' => '123-456-7890',
            'client_phone[0][call_ok]' => 'on',
            'client_phone[0][message_ok]' => 'on',
            'client_phone[0][active]' => 'on',
            client_phone_primary => 0,

            'client_emergency_contact[0][fname]' => 'Foo',
            'client_emergency_contact[0][lname]' => 'Bar',
            'client_emergency_contact[0][phone_number]' => '223-456-7890',
            'client_emergency_contact[0][comment_text]' => 'Friend',

            'client_emergency_contact[1][fname]' => 'Second',
            'client_emergency_contact[1][lname]' => 'Contact',
            'client_emergency_contact[1][phone_number]' => '737-373-7373',
            'client_emergency_contact[1][comment_text]' => 'Mate',
        );

    is_deeply(
        [ $one->step2_save ],
        [ undef, { forward => 'step3', forward_args => [$one->client] }]
    );
    $tmp = eleMentalClinic::Client->retrieve( $client->{ client_id });

    #Make sure step2 no_XXX all return false.
    $one = $CLASS->new_with_cgi_params(client_id => $client->{ client_id });
    is_deeply_except(
        {
            client => undef,
            step   => undef,
        },
        $one->step2,
        {
            no_address   => 0,
            no_phone     => 0,
            no_emergency => 0,
            client_addresses_count => 1,
            client_phones_count => 1,
            client_emergency_count => 2,
        }
    );

    # now make sure everything got saved
    is( $tmp->email, 'jimi@hendrix.com' );

    # address
    ok( $tmp->addresses );
    is( scalar @{ $tmp->addresses }, 1 );
    is_deeply_except({ rec_id => qr/^\d+$/ }, $tmp->addresses, [{
            client_id => $client->{ client_id },
            rolodex_id => undef,
            address1 => '123 Foobar Way',
            address2 => 'Apt. B',
            city    => 'monkey',
            state   => 'OR',
            post_code => 97504,
            county => 'Washatoga',
            active => 1,
            primary_entry => 1,
        }]);

    # phone
    ok( $tmp->phones );
    is( scalar @{ $tmp->phones }, 1 );

    is_deeply_except({ rec_id => qr/^\d+$/ }, $tmp->phones, [{
            client_id => $client->{ client_id },
            rolodex_id => undef,
            phone_number => '123-456-7890',
            phone_type => '123-456-7890',
            call_ok => 1,
            message_ok => 1,
            active => 1,
            primary_entry => 1,
        }]);

    # emergency contact
    ok( $tmp->get_emergency_contact );
    ok( $tmp->get_emergency_contacts ); # FIXME test this later
    is_deeply_except({ rec_id => qr/^\d+$/, rolodex_contacts_id => qr/^\d+$/ }, $tmp->get_emergency_contact, {
        client_id           => $client->{ client_id },
        contact_type_id     => 3,
        comment_text        => undef, # FIXME : 'Friend' should be saved here, not in rolodex
        active              => 1,
    });

    $rdx = $tmp->get_emergency_contacts->[0]->rolodex;
    is( $rdx->{ comment_text }, 'Friend' );
    is( $rdx->{ fname }, 'Foo' );
    is( $rdx->{ lname }, 'Bar' );
    is( 
        $rdx->phones->[0]->phone_number,
        '223-456-7890',
    );

    $rdx = $tmp->get_emergency_contacts->[1]->rolodex;
    is( $rdx->{ comment_text }, 'Mate' );
    is( $rdx->{ fname }, 'Second' );
    is( $rdx->{ lname }, 'Contact' );
    is( 
        $rdx->phones->[0]->phone_number,
        '737-373-7373',
    );

    is_deeply_except({ rec_id => undef }, $tmp->get_emergency_contact->rolodex, {
        dept_id              => 1001,
        generic              => 0,
        name                 => undef,
        fname                => 'Foo',
        lname                => 'Bar',
        credentials          => undef,
        comment_text         => 'Friend', # FIXME: this should be saved in client_contacts, not rolodex
        client_id            => $client->{ client_id },
        claims_processor_id  => undef,
        edi_id               => undef,
        edi_name             => undef,
        edi_indicator_code   => undef,
    });

    #Make sure step2 returns the correct number of objects now
    is_deeply( $one->step2({ client_id => $client->{ client_id }}),
        {
            client => eleMentalClinic::Client->retrieve( $client->{ client_id }),
            step => 2,
            client_addresses_count => 1,         
            client_phones_count => 1,   
            client_emergency_count => 2,
            no_address   => 0,
            no_phone     => 0,
            no_emergency => 0,
        }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# now, let's do it again and make sure these records are updated
        $tmp = eleMentalClinic::Client->retrieve( $client->{ client_id });
        $one = $CLASS->new_with_cgi_params(
            op => 'step2_save',
            client_id => $client->{ client_id },
            email => 'jimi@hendrix.com',

            'client_address[0][rec_id]' => $one->client->addresses->[0]->id,
            'client_address[0][address1]' => '123 Foobar Street',
            'client_address[0][address2]' => 'Apt. C',
            'client_address[0][city]'    => 'Malarky',
            'client_address[0][state]'   => 'WA',
            'client_address[0][post_code]' => 12345,
            'client_address[0][county]' => 'Cuyahoga',
            'client_address[0][rec_id]' => $tmp->addresses->[ 0 ]->rec_id,
            'client_address[0][active]' => 'on',
            client_address_primary => 0,

            'client_phone[0][rec_id]' => $one->client->phones->[0]->id,
            'client_phone[0][phone_number]' => '623-456-7890',
            'client_phone[0][phone_type]' => '623-456-7890',
            'client_phone[0][call_ok]' => 'on',
            'client_phone[0][message_ok]' => 'on',
            'client_phone[0][active]' => 'on',
            'client_phone[0][rec_id]' => $tmp->phones->[ 0 ]->rec_id,
            client_phone_primary => 0,

            'client_emergency_contact[0][fname]'        => 'New',
            'client_emergency_contact[0][lname]'        => 'Emergency',
            'client_emergency_contact[0][phone_number]' => '000-000-0000',
            'client_emergency_contact[0][comment_text]' => 'Some Comment',
            'client_emergency_contact[0][rec_id]'       => $tmp->get_emergency_contacts->[0]->rolodex->id,
            client_emergency_contact_primary => 0,

            'client_emergency_contact[1][fname]'        => 'Second',
            'client_emergency_contact[1][lname]'        => 'Contact',
            'client_emergency_contact[1][phone_number]' => '001-001-0001',
            'client_emergency_contact[1][comment_text]' => 'Something else',
            'client_emergency_contact[1][rec_id]'       => $tmp->get_emergency_contacts->[1]->rolodex->id,
        );
    is_deeply(
        [ $one->step2_save ],
        [ undef, { forward => 'step3', forward_args => [$one->client] }]
    );

    # now make sure everything got saved
        $tmp = eleMentalClinic::Client->retrieve( $client->{ client_id });
    is( $tmp->email, 'jimi@hendrix.com' );

    # Emergency contact information.

    $rdx = $tmp->get_emergency_contacts->[0]->rolodex;
    is( $rdx->{ comment_text }, 'Some Comment' );
    is( $rdx->{ fname }, 'New' );
    is( $rdx->{ lname }, 'Emergency' );
    is( 
        $rdx->{ rec_id }, 
        $tmp->get_emergency_contacts->[0]->rolodex->id 
    );
    is( 
        $rdx->phones->[0]->phone_number,
        '000-000-0000',
    );

    $rdx = $tmp->get_emergency_contacts->[1]->rolodex;
    is( $rdx->{ comment_text }, 'Something else' );
    is( $rdx->{ fname }, 'Second' );
    is( $rdx->{ lname }, 'Contact' );
    is( 
        $rdx->{ rec_id }, 
        $tmp->get_emergency_contacts->[1]->rolodex->id 
    );
    is( 
        $rdx->phones->[0]->phone_number,
        '001-001-0001',
    );

    # address
    ok( $tmp->addresses );
    is( scalar @{ $tmp->addresses }, 1 );
    is_deeply_except({ rec_id => qr/^\d+$/ }, $tmp->addresses, [{
            client_id => $client->{ client_id },
            rolodex_id => undef,
            address1 => '123 Foobar Street',
            address2 => 'Apt. C',
            city    => 'Malarky',
            state   => 'WA',
            post_code => 12345,
            county => 'Cuyahoga',
            active => 1,
            primary_entry => 1,
        }]);

    # phone
    ok( $tmp->phones ); # XXX damn, just realized that this test, and all the ones like it, is useless

    is( scalar @{ $tmp->phones }, 1 );
    is_deeply_except({ rec_id => qr/^\d+$/ }, $tmp->phones, [{
            client_id => $client->{ client_id },
            rolodex_id => undef,
            phone_number => '623-456-7890',
            phone_type => '623-456-7890',
            call_ok => 1,
            message_ok => 1,
            active => 1,
            primary_entry => 1,
        }]);

    # saving multiple items
    $one = $CLASS->new_with_cgi_params(
        op => 'step2_save',
        client_id => $client->{ client_id },
        email => 'jimi@hendrix.com',

        'client_address[0][rec_id]' => $tmp->addresses->[0]->id,
        'client_address[0][address1]' => '123 Foobar Way',
        'client_address[0][address2]' => 'Apt. B',
        'client_address[0][city]'    => 'monkey',
        'client_address[0][state]'   => 'OR',
        'client_address[0][post_code]' => 97504,
        'client_address[0][county]' => 'Washatoga',
        'client_address[0][active]' => 'on',
        'client_address[1][address1]' => '223 Foobar Way',
        'client_address[1][address2]' => 'Apt. C',
        'client_address[1][city]'    => 'monkey',
        'client_address[1][state]'   => 'OR',
        'client_address[1][post_code]' => 97504,
        'client_address[1][county]' => 'Washatoga',
        'client_address[1][active]' => 'on',
        client_address_primary => 0,

        'client_phone[0][rec_id]' => $tmp->phones->[0]->id,
        'client_phone[0][phone_number]' => '123-456-7890',
        'client_phone[0][phone_type]' => '123-456-7890',
        'client_phone[0][call_ok]' => 'on',
        'client_phone[0][message_ok]' => 'on',
        'client_phone[0][active]' => 'on',
        'client_phone[1][phone_number]' => '123-456-7891',
        'client_phone[1][phone_type]' => '123-456-7891',
        'client_phone[1][call_ok]' => 'on',
        'client_phone[1][message_ok]' => 'on',
        'client_phone[1][active]' => 'on',
        client_phone_primary => 0,

        'client_emergency_contact[0][fname]' => 'Foo',
        'client_emergency_contact[0][lname]' => 'Bar',
        'client_emergency_contact[0][phone_number]' => '223-456-7890',
        'client_emergency_contact[0][comment_text]' => 'Friend',
    );

    lives_ok { $one->step2_save };

    ok ($tmp = eleMentalClinic::Client->retrieve($client->{client_id}));
    is (@{$tmp->phones}, 2);
    is (@{$tmp->addresses}, 2);
    ok ($tmp->phones->[0]->primary_entry);
    ok ($tmp->addresses->[0]->primary_entry);
    ok (!$tmp->phones->[1]->primary_entry);
    ok (!$tmp->addresses->[1]->primary_entry);
    is ($tmp->phones->[1]->phone_number, "123-456-7891");
    is ($tmp->addresses->[1]->address1, "223 Foobar Way");

#########################
# Tests for no_XXX

    #No information for step 2
    $client = eleMentalClinic::Client->new;
    $client->save;

    $one = $CLASS->new_with_cgi_params(
        op => 'step2_save',
        client_id => $client->{ client_id },
        email => 'newguy@newguy.com',

        'no_address' => 'on',
        'no_phone' => 'on',
        'no_emergency' => 'on'
    );

    is_deeply(
        [ $one->step2_save ],
        [ undef, { forward => 'step3', forward_args => [$one->client] }]
    );

    $tmp = eleMentalClinic::Client->retrieve( $client->client_id );

    is( $tmp->email, 'newguy@newguy.com' );
    is_deeply( $tmp->addresses, [] );
    is_deeply( $tmp->phones, [] );
    ok( not $tmp->get_emergency_contacts );

    $client = eleMentalClinic::Client->new();
    $client->intake_step( 3 );
    $client->save;

    #Make sure step2 no_XXX all return true.
    $one = $CLASS->new_with_cgi_params(client_id => $client->client_id);
    is_deeply_except(
        {
            client => undef,
            step   => undef,
            client_addresses_count => undef,
            client_phones_count => undef,
            client_emergency_count => undef,
        },
        $one->step2,
        {
            no_address   => 1,
            no_phone     => 1,
            no_emergency => 1,
        }
    );

    $client = eleMentalClinic::Client->new();
    $client->intake_step( 1 );
    $client->save;

    $one = $CLASS->new_with_cgi_params(
        op => 'step2_save',
        client_id => $client->client_id,

        'client_address[0][address1]' => '123 Foobar Way',
        'client_address[0][address2]' => 'Apt. B',
        'client_address[0][city]'    => 'monkey',
        'client_address[0][state]'   => 'OR',
        'client_address[0][post_code]' => 97504,
        'client_address[0][county]' => 'Washatoga',
        'client_address[0][active]' => 'on',
        'client_address[1][address1]' => '123 Foobar Wayx',
        'client_address[1][address2]' => 'Apt. Bx',
        'client_address[1][city]'    => 'monkeyx',
        'client_address[1][state]'   => 'NV',
        'client_address[1][post_code]' => 97505,
        'client_address[1][county]' => 'Washatogax',
        'client_address[1][active]' => 'on',
        client_address_primary => 0,

        no_address   => 0,
        no_phone     => 1,
        no_emergency => 1,

    );
    ok( $one->step2_save );
    $one = $CLASS->new_with_cgi_params(client_id => $client->client_id);
    is_deeply_except(
        {
            client => undef,
            step   => undef,
        },
        $one->step2,
        {
            no_address   => 0,
            no_phone     => 1,
            no_emergency => 1,
            client_addresses_count => 2,
            client_phones_count => 1,
            client_emergency_count => 1,
        }
    );

    $client = eleMentalClinic::Client->new();
    $client->intake_step( 1 );
    $client->save;

    $one = $CLASS->new_with_cgi_params(
        op => 'step2_save',
        client_id => $client->client_id,

        'client_phone[0][phone_number]' => '123-456-7890',
        'client_phone[0][phone_type]' => '123-456-7890',
        'client_phone[0][call_ok]' => 'on',
        'client_phone[0][message_ok]' => 'on',
        'client_phone[0][active]' => 'on',
        'client_phone[1][phone_number]' => '123-456-7891',
        'client_phone[1][phone_type]' => '123-456-7891',
        'client_phone[1][call_ok]' => 'on',
        'client_phone[1][message_ok]' => 'on',
        'client_phone[1][active]' => 'on',
        client_phone_primary => 0,

        no_address   => 1,
        no_phone   => 0,
        no_emergency => 1,
    );
    ok( $one->step2_save );

    $one = $CLASS->new_with_cgi_params(client_id => $client->client_id);
    is_deeply_except(
        {
            client => undef,
            step   => undef,
        },
        $one->step2,
        {
            no_address   => 1,
            no_phone     => 0,
            no_emergency => 1,
            client_addresses_count => 1,
            client_phones_count => 2,
            client_emergency_count => 1,
        }
    );

    $client = eleMentalClinic::Client->new();
    $client->intake_step( 1 );
    $client->save;

    $one = $CLASS->new_with_cgi_params(
        op => 'step2_save',
        client_id => $client->client_id,

        'client_emergency_contact[0][fname]' => 'Foo',
        'client_emergency_contact[0][lname]' => 'Bar',
        'client_emergency_contact[0][phone_number]' => '223-456-7890',
        'client_emergency_contact[0][comment_text]' => 'Friend',
        'client_emergency_contact[1][fname]' => 'Foox',
        'client_emergency_contact[1][lname]' => 'Barx',
        'client_emergency_contact[1][phone_number]' => '223-456-7891',
        'client_emergency_contact[1][comment_text]' => 'Friendx',

        no_address   => 1,
        no_phone => 1,
        no_emergency => 0,
    );
    ok( $one->step2_save );

    $one = $CLASS->new_with_cgi_params(client_id => $client->client_id);
    is_deeply_except(
        {
            client => undef,
            step   => undef,
        },
        $one->step2,
        {
            no_address   => 1,
            no_phone     => 1,
            no_emergency => 0,
            client_addresses_count => 1,
            client_phones_count => 1,
            client_emergency_count => 2,
        }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step3

    $one = $CLASS->new_with_cgi_params(client_id => 666);
    is_deeply(
        $one->step3,
        {
            client => eleMentalClinic::Client->retrieve(666),
            step => 3,
            no_employment => 0,
        }
    );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step3_save

    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step3_save',
        name => 'Reagae 4 me',
        'client_employer[0][job_title]' => 'Singer',
        'client_employer[0][supervisor]' => 'Erronious Maximus',
        'client_employer_phone[0][phone_number]' => '(656) 656-6565',
        'client_employer_phone[0][call_ok]' => 'on',
        'client_employer_phone[0][message_ok]' => 'on',
        'client_employer_address[0][address1]' => '555 Falldown ln.',
        'client_employer_address[0][address2]' => 'test',
        'client_employer_address[0][city]' => 'Hallapoose',
        'client_employer_address[0][state]' => 'UT',
        'client_employer_address[0][post_code]' => '66766',
        'client[0][edu_level]' => '3',
        'client[0][marital_status]' => 'Married',
        'client[0][race]' => 'Alaskan native',
        'client[0][religion]' => 'No preference',
        'client[0][language_spoken]' => 'English',
        'client[0][nationality_id]' => 84,
        'client[0][household_annual_income]' => 100000,
        'client[0][household_population]' => 1,
        'client[0][household_population_under18]' => 0,
        'client[0][dependents_count]' => 0,
    );

    is_deeply( 
        [ $one->step3_save ],
        [ undef, { forward => 'step4', forward_args => [{ client_id => 1001 }] }]
    );

    $client = eleMentalClinic::Client->retrieve(1001);
    my $employment = $client->relationship_primary('employment');

    is( $employment->rolodex->name, 'Reagae 4 Me' );
    is( $employment->job_title, 'Singer' );
    is( $employment->supervisor, 'Erronious Maximus' );
    ok( $employment->rolodex->phones->[0] );
    is( $employment->rolodex->phones->[0]->phone_number, '(656) 656-6565' );
    ok( $employment->rolodex->phones->[0]->call_ok );
    ok( $employment->rolodex->phones->[0]->message_ok );
    is( $employment->rolodex->addresses->[0]->address1, '555 Falldown ln.' );
    is( $employment->rolodex->addresses->[0]->address2, 'test' );
    is( $employment->rolodex->addresses->[0]->city, 'Hallapoose' );
    is( $employment->rolodex->addresses->[0]->state, 'UT' );
    is( $employment->rolodex->addresses->[0]->post_code, '66766' );

    is( $client->edu_level, 3 );
    is( $client->marital_status, 'Married' );
    is( $client->race, 'Alaskan native' );
    is( $client->religion, 'No preference' );
    is( $client->language_spoken, 'English' );
    is( $client->nationality_id, 84 );
    is( $client->household_annual_income, 100000 );
    is( $client->household_population, 1 );
    is( $client->household_population_under18, 0 );
    is( $client->dependents_count, 0 );

    #Make some changes
    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step3_save',
        'client_employer_phone[0][rec_id]' => $employment->rolodex->phones->[0]->id,
        'client_employer_address[0][rec_id]' => $employment->rolodex->addresses->[0]->id,
        'client_employer_phone[0][call_ok]' => undef,
        'client_employer_phone[0][message_ok]' => undef,
        'client[0][household_population]' => 0,
        'client[0][household_population_under18]' => 5,
        'client[0][dependents_count]' => 6,
        #End Changes
        'client_employer_phone[0][phone_number]' => '(656) 656-6565',
        'client_employer[0][job_title]' => 'Singer',
        'client_employer[0][supervisor]' => 'Erronious Maximus',
        'client_employer_address[0][address1]' => '555 Falldown ln.',
        'client_employer_address[0][address2]' => '',
        'client_employer_address[0][city]' => 'Hallapoose',
        'client_employer_address[0][state]' => 'UT',
        'client_employer_address[0][post_code]' => '66766',
        'client[0][edu_level]' => '3',
        'client[0][marital_status]' => 'Married',
        'client[0][race]' => 'Alaskan native',
        'client[0][religion]' => 'No preference',
        'client[0][language_spoken]' => 'English',
        'client[0][nationality_id]' => 84,
        'client[0][household_annual_income]' => 100000,
    );

    is_deeply( 
        [ $one->step3_save ],
        [ undef, { forward => 'step4', forward_args => [{ client_id => 1001 }] }]
    );

    $client = eleMentalClinic::Client->retrieve(1001);
    $employment = $client->relationship_primary('employment');

    ok( not $employment->rolodex->phones->[0]->call_ok );
    ok( not $employment->rolodex->phones->[0]->message_ok );
    is( $client->household_population, 0 );
    is( $client->household_population_under18, 5 );
    is( $client->dependents_count, 6 );

    #Everything Changes
    $one = $CLASS->new_with_cgi_params(
        name => 'Reagae 4 mex',
        client_id => 1001,
        op => 'step3_save',
        'client_employer_phone[0][rec_id]' => $employment->rolodex->phones->[0]->id,
        'client_employer_address[0][rec_id]' => $employment->rolodex->addresses->[0]->id,
        'client_employer_phone[0][phone_number]' => '999-999-9999',
        'client_employer_phone[0][call_ok]' => 'on',
        'client_employer_phone[0][message_ok]' => 'on',
        'client[0][household_population]' => 7,
        'client[0][household_population_under18]' => 8,
        'client[0][dependents_count]' => 3,
        'client[0][edu_level]' => '6',
        'client[0][marital_status]' => 'Single',
        'client[0][race]' => 'African American',
        'client[0][religion]' => 'Monotheist',
        'client[0][language_spoken]' => 'Russian',
        'client[0][nationality_id]' => 80,
        'client[0][household_annual_income]' => 999,
        'client_employer[0][job_title]' => 'Musician',
        'client_employer[0][supervisor]' => 'Gludious',
        'client_employer_address[0][address1]' => '77 Elsware',
        'client_employer_address[0][address2]' => 'Another Place',
        'client_employer_address[0][city]' => 'Zenata',
        'client_employer_address[0][state]' => 'OR',
        'client_employer_address[0][post_code]' => '22222',
    );

    is_deeply( 
        [ $one->step3_save ],
        [ undef, { forward => 'step4', forward_args => [{ client_id => 1001 }] }]
    );

    $client = eleMentalClinic::Client->retrieve(1001);
    $employment = $client->relationship_primary('employment');

    is( $employment->rolodex->name, 'Reagae 4 Mex' );
    ok( $employment->rolodex->phones->[0] );
    is( $employment->rolodex->phones->[0]->phone_number, '999-999-9999' );
    ok( $employment->rolodex->phones->[0]->call_ok );
    ok( $employment->rolodex->phones->[0]->message_ok );
    is( $client->household_population, 7 );
    is( $client->household_population_under18, 8 );
    is( $client->dependents_count, 3 );
    is( $client->edu_level, 6 );
    is( $client->marital_status, 'Single' );
    is( $client->race, 'African American' );
    is( $client->religion, 'Monotheist' );
    is( $client->language_spoken, 'Russian' );
    is( $client->nationality_id, 80 );
    is( $client->household_annual_income, 999 );
    is( $employment->job_title, 'Musician' );
    is( $employment->supervisor, 'Gludious' );
    is( $employment->rolodex->addresses->[0]->address1, '77 Elsware' );
    is( $employment->rolodex->addresses->[0]->address2, 'Another Place' );
    is( $employment->rolodex->addresses->[0]->city, 'Zenata' );
    is( $employment->rolodex->addresses->[0]->state, 'OR' );
    is( $employment->rolodex->addresses->[0]->post_code, '22222' );

    is_deeply(
        $one->step3,
        {
            client => $client,
            step => 3,
            no_employment => 0,
        }
    );

    # make sure excluding a phone number does not crash the app.
    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step3_save',
        'client_employer_address[0][rec_id]' => $employment->rolodex->addresses->[0]->id,
        'client_employer_phone[0][phone_number]' => '',
        'client_employer_phone[0][call_ok]' => undef,
        'client_employer_phone[0][message_ok]' => undef,
        'client[0][household_population]' => 0,
        'client[0][household_population_under18]' => 5,
        'client[0][dependents_count]' => 6,
        #End Changes
        'client_employer[0][job_title]' => 'Singer',
        'client_employer[0][supervisor]' => 'Erronious Maximus',
        'client_employer_address[0][address1]' => '555 Falldown ln.',
        'client_employer_address[0][address2]' => '',
        'client_employer_address[0][city]' => 'Hallapoose',
        'client_employer_address[0][state]' => 'UT',
        'client_employer_address[0][post_code]' => '66766',
        'client[0][edu_level]' => '3',
        'client[0][marital_status]' => 'Married',
        'client[0][race]' => 'Alaskan native',
        'client[0][religion]' => 'No preference',
        'client[0][language_spoken]' => 'English',
        'client[0][nationality_id]' => 84,
        'client[0][household_annual_income]' => 100000,
    );

    lives_ok { $one->step3_save };

    # nix the employer and watch it disappear (ideally) 
    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step3_save',
        name => 'Reagae 4 me',
        'no_employment' => 'on', # XXX THIS IS THE WHOLE POINT OF THIS TEST.
        'client[0][household_population]' => 0,
        'client[0][household_population_under18]' => 5,
        'client[0][dependents_count]' => 6,
        'client[0][edu_level]' => '3',
        'client[0][marital_status]' => 'Married',
        'client[0][race]' => 'Alaskan native',
        'client[0][religion]' => 'No preference',
        'client[0][language_spoken]' => 'English',
        'client[0][nationality_id]' => 84,
        'client[0][household_annual_income]' => 100000,
    );

    is_deeply( 
        [ $one->step3_save ],
        [ undef, { forward => 'step4', forward_args => [{ client_id => 1001 }] }]
    );

    $client = eleMentalClinic::Client->retrieve(1001);
    $employment = $client->relationship_primary('employment');

    is ($client->id, 1001);
    is ($client->edu_level, 3);
    ok (!$employment);

    is_deeply(
        $one->step3,
        {
            client => $client,
            step => 3,
            no_employment => 1,
        }
    );

    # Do it again after the relationship has already been removed, make sure there
    # is no error from trying to remove it again.
    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step3_save',
        name => 'Reagae 4 me',
        'no_employment' => 'on',
        'client[0][household_population]' => 0,
        'client[0][household_population_under18]' => 5,
        'client[0][dependents_count]' => 6,
        'client[0][edu_level]' => '3',
        'client[0][marital_status]' => 'Married',
        'client[0][race]' => 'Alaskan native',
        'client[0][religion]' => 'No preference',
        'client[0][language_spoken]' => 'English',
        'client[0][nationality_id]' => 84,
        'client[0][household_annual_income]' => 100000,
    );
    is_deeply( 
        [ $one->step3_save ],
        [ undef, { forward => 'step4', forward_args => [{ client_id => 1001 }] }]
    );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step4

    $one = $CLASS->new_with_cgi_params(client_id => 666);
    my $assessment = $one->client->assessment ||
        eleMentalClinic::Client::Assessment->new({
            client_id => $one->get_client->id, 
            template_id => eleMentalClinic::Client::AssessmentTemplate->get_intake()->id,
        });

    is_deeply($one->step4,
        {
            client => eleMentalClinic::Client->retrieve(666),
            step => 4,
            current_assessment => $assessment,
            fields => $assessment->all_fields,
            no_treater => 0,
        }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step4_save

    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step4_save',
        'client_primary_treater[0][name]' => 'Whole Clinic',
        'client_primary_treater[0][fname]' => 'Harry',
        'client_primary_treater[0][lname]' => 'Truman',
        'client_primary_treater_phone[0][phone_number]' => '(444) 444-4444',
        'client_primary_treater_address[0][address1]' => '1600 Pennsylvania Ave.',
        'client_primary_treater_address[0][address2]' => '',
        'client_primary_treater_address[0][city]' => 'Washington',
        'client_primary_treater_address[0][state]' => 'DC',
        'client_primary_treater_address[0][post_code]' => 99977,
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));

    is_deeply( 
        [ $one->step4_save ],
        [ undef, { forward => 'step5', forward_args => [{ client_id => 1001 }] }]
    );

    $client = eleMentalClinic::Client->retrieve(1001);
    my $treaters = $client->relationship_primary('treaters');

    is( $treaters->rolodex->name, 'Whole Clinic' );
    is( $treaters->rolodex->fname, 'Harry' );
    is( $treaters->rolodex->lname, 'Truman' );
    is( $treaters->rolodex->phones->[0]->phone_number, '(444) 444-4444' );
    is( $treaters->rolodex->addresses->[0]->address1, '1600 Pennsylvania Ave.' );
    is( $treaters->rolodex->addresses->[0]->address2, undef );
    is( $treaters->rolodex->addresses->[0]->city, 'Washington' );
    is( $treaters->rolodex->addresses->[0]->state, 'DC' );
    is( $treaters->rolodex->addresses->[0]->post_code, '99977' );

    #Keep the rec_id of the previous rolodex, phone, and address records to ensure we re-write the same ones, not new ones.
    $tmp = {
        rolodex_id => $treaters->rolodex->id,
        phone_id   => $treaters->rolodex->phones->[0]->rec_id,
        address_id => $treaters->rolodex->addresses->[0]->rec_id,
    };

    #Make some changes
    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step4_save',
        'rolodex_id' => $treaters->rolodex->id,
        'client_primary_treater[0][name]' => 'New Place',
        'client_primary_treater[0][fname]' => 'Fred',
        'client_primary_treater[0][lname]' => 'Cutter',
        'client_primary_treater_phone[0][rec_id]' => $treaters->rolodex->phones->[0]->id,
        'client_primary_treater_phone[0][phone_number]' => '(444) 444-4554',
        'client_primary_treater_address[0][rec_id]' => $treaters->rolodex->addresses->[0]->id,
        'client_primary_treater_address[0][address1]' => '1605 Pennsylvania Ave.',
        #End Changes
        'client_primary_treater_address[0][address2]' => '',
        'client_primary_treater_address[0][city]' => 'Washington',
        'client_primary_treater_address[0][state]' => 'DC',
        'client_primary_treater_address[0][post_code]' => 99977,
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply( 
        [ $one->step4_save ],
        [ undef, { forward => 'step5', forward_args => [{ client_id => 1001 }] }]
    );

    $client = eleMentalClinic::Client->retrieve(1001);
    $treaters = $client->relationship_primary('treaters');

    is( $treaters->rolodex->name, 'New Place' );
    is( $treaters->rolodex->fname, 'Fred' );
    is( $treaters->rolodex->lname, 'Cutter' );
    is( $treaters->rolodex->phones->[0]->phone_number, '(444) 444-4554' );
    is( $treaters->rolodex->addresses->[0]->address1, '1605 Pennsylvania Ave.' );

    #Make sure we overrode the records instead of creating new ones.
    is( $treaters->rolodex->id, $tmp->{ rolodex_id } );
    is( $treaters->rolodex->phones->[0]->rec_id, $tmp->{ phone_id } );
    is( $treaters->rolodex->addresses->[0]->rec_id, $tmp->{ address_id } );
   
    # test that it lives ok without a phone number
    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step4_save',
        'rolodex_id' => $treaters->rolodex->id,
        'client_primary_treater[0][name]' => 'New Place',
        'client_primary_treater[0][fname]' => 'Fred',
        'client_primary_treater[0][lname]' => 'Cutter',
        'client_primary_treater_address[0][rec_id]' => $treaters->rolodex->addresses->[0]->id,
        'client_primary_treater_address[0][address1]' => '1605 Pennsylvania Ave.',
        'client_primary_treater_phone[0][phone_number]' => '',
        #End Changes
        'client_primary_treater_address[0][address2]' => '',
        'client_primary_treater_address[0][city]' => 'Washington',
        'client_primary_treater_address[0][state]' => 'DC',
        'client_primary_treater_address[0][post_code]' => 99977,
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));

    lives_ok { $one->step4_save };
    diag $@ if $@;


    #Tests for ticket #46, make sure client_treater and rolodex records are not created with empty data.

    $client = eleMentalClinic::Client->new;
    $client->save;

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->client_id,
        op => 'step4_save',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));

    is_deeply( 
        [ $one->step4_save ],
        [ undef, { forward => 'step5', forward_args => [{ client_id => $client->client_id }] }]
    );

    ok( not $client->relationship_primary( 'treaters' ));

    # Make sure no data is lost if we enter some, that means creating the minimum records necessary 
    # to retain and retrieve the provided data, but not more.

    # Only treater info
    $client = eleMentalClinic::Client->new;
    $client->save;

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->client_id,
        op => 'step4_save',
        'client_primary_treater[0][name]' => 'New Place',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));

    is_deeply( 
        [ $one->step4_save ],
        [ undef, { forward => 'step5', forward_args => [{ client_id => $client->client_id }] }]
    );

    ok( $client->relationship_primary( 'treaters' ));
    $treaters = $client->relationship_primary( 'treaters' );
    is( $treaters->rolodex->name, 'New Place' );
    is( $treaters->rolodex->addresses->[0], undef );
    is( $treaters->rolodex->phones->[0], undef );

    # Only address info, should create the treater and the address, but not the phone
    $client = eleMentalClinic::Client->new;
    $client->save;

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->client_id,
        op => 'step4_save',
        'client_primary_treater[0][fname]' => 'Doctor',
        'client_primary_treater_address[0][address1]' => '1605 Pennsylvania Ave.',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));

    is_deeply( 
        [ $one->step4_save ],
        [ undef, { forward => 'step5', forward_args => [{ client_id => $client->client_id }] }]
    );

    ok( $client->relationship_primary( 'treaters' ));
    $treaters = $client->relationship_primary( 'treaters' );
    is( $treaters->rolodex->addresses->[0]->address1, '1605 Pennsylvania Ave.' );
    is( $treaters->rolodex->phones->[0], undef );

    # Only address info, should create the treater and the address, but not the phone
    $client = eleMentalClinic::Client->new;
    $client->save;

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->client_id,
        op => 'step4_save',
        'client_primary_treater[0][fname]' => 'Doctor',
        'client_primary_treater_phone[0][phone_number]' => '(444) 444-4554',
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    is_deeply( 
        [ $one->step4_save ],
        [ undef, { forward => 'step5', forward_args => [{ client_id => $client->client_id }] }]
    );

    ok( $client->relationship_primary( 'treaters' ));
    $treaters = $client->relationship_primary( 'treaters' );
    is( $treaters->rolodex->addresses->[0], undef);
    is( $treaters->rolodex->phones->[0]->phone_number, '(444) 444-4554' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step5

    $one = $CLASS->new_with_cgi_params(client_id => 666);
    is_deeply($one->step5,
        {
            referrals_list  => eleMentalClinic::Rolodex->new->get_byrole( 'referral' ),
            step => 5,
        }
    );

    # Make sure referrals_list is an empty array when there are no referrals to list.
    dbinit( );
    $one = $CLASS->new_with_cgi_params(client_id => 666);
    is_deeply($one->step5,
        {
            referrals_list  => [],
            step => 5,
        }
    );
    dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# step5_save
    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        program_id => 1001,
        event_date => '2008-01-23',
        staff_id => 1002,
        level_of_care_id => 1002,
        is_referral => 0,
    );

    is_deeply( 
        [ $one->step5_save ],
        [ '', { Location => '/demographics.cgi?client_id=1001' } ],
    );

    $client = eleMentalClinic::Client->retrieve(1001);
   
    is( $client->placement->program_id, 1001 );
    is( $client->placement->staff_id, 1002 );
    is( $client->placement->level_of_care_id, 1002 );
    is( $client->placement->referral, undef );

    $client = eleMentalClinic::Client->new;
    $client->save;

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->client_id,
        program_id => 1001,
        event_date => '2008-01-23',
        staff_id => 1002,
        level_of_care_id => 1002,
        is_referral => 1,
        rolodex_id => 1010,
        agency_type => 'Something',
        agency_contact => 'Somebody',
    );

    is_deeply( 
        [ $one->step5_save ],
        [ '', { Location => '/demographics.cgi?client_id=' . $client->client_id } ],
    );

    $client = eleMentalClinic::Client->retrieve( $client->client_id );

    ok( not $client->intake_step );

    ok( $client->placement->referral );

    is_deeply_except(
        {
            rec_id => qr/^\d+$/,
        },
        $client->placement->referral,
        {
            client_id                 => $client->client_id,
            rolodex_referral_id       => 1010,
            agency_contact            => 'Somebody',
            agency_type               => 'Something',
            active                    => 1,
            client_placement_event_id => $client->placement->event->rec_id,
        },
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home()
# This can only be tested so far... it returns html, all I can test for now is
# w/ params and w/o params, and making sure there are no errors.
    $one = $CLASS->new;
    ok( $one->home ); #Can this be tested further?
    ok( not $one->errors );

    $one = $CLASS->new;
    ok( $one->home( {}, 0, 0 ));
    ok( not $one->errors );

    $one = $CLASS->new;
    ok( $one->home( {}, 1, 1 ));
    ok( not $one->errors );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# program_id

    $one = $CLASS->new_with_cgi_params(
        admission_program_id => 1,
        intake_type => 'Admission',
    );
    is( $one->program_id, 1 );

    $one = $CLASS->new_with_cgi_params(
        referral_program_id => 1,
        intake_type => 'Referral',
    );
    is( $one->program_id, 1 );

    $one = $CLASS->new_with_cgi_params(
        referral_program_id => 1,
        intake_type => 'Fake',
    );
    is( $one->program_id, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# _address
# _phone
# _emergency_contact
# I am not sure how to completely test these, however I have created the following tests
# in order to ensure future changes do not modify the current behavior.

    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step2',
        add_new => 'address',
        ordinal => 1,
    );

    is_deeply(
        $one->_address,
        {
            prefix           => 'client_address',
            ordinal          => 1,
            locally_required => 1,
        }
    );


    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step2',
        add_new => 'phone',
        ordinal => 1,
    );

    is_deeply(
        $one->_phone,
        {
            prefix           => 'client_phone',
            ordinal          => 1,
            locally_required => 1,
        }
    );


    $one = $CLASS->new_with_cgi_params(
        client_id => 1001,
        op => 'step2',
        add_new => 'emergency_contact',
        ordinal => 1,
    );

    is_deeply(
        $one->_emergency_contact,
        {
            prefix           => 'client_emergency_contact',
            ordinal          => 1,
            locally_required => 1,
        }
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Complete Intake
dbinit( 1 );

# This function will be called after each step of the intake. It has tests
# for the data that should be in the object after each step. The function 
# also runs the previous step tests on the object again each time it is called
# this will help ensure data is not accidently changed by a later step.
# This is done in responce to JetCat Ticket #78.
# Currently this function only tests the intake in the section of the test.
# I think it may be beneficial to change this to be a more generic function
# that can be used elsware.
#
# param1: last completed step number (will test up through that number)
#   Should be explicitly stated and not pulled from client in case that is incorrect
# param2: client ID to check.
sub test_intake {
    my ( $step, $client_id ) = @_;
    my $client = eleMentalClinic::Client->retrieve( $client_id );

    #Step 1
    is( $client->lname, 'Marley' );
    is( $client->mname, 'Zebadaya');
    is( $client->fname, 'Bob');
    is( $client->ssn, '777777777');
    is( $client->dob, '1958-10-10');
    is( $client->sex, 'Male'); 

    return if $step < 2;

    is( $client->email, 'bob@bobmarley.com' );

    my $addresses = $client->addresses;
    is( @{ $addresses },  2 );

    ok( $addresses->[0]->primary_entry );
    ok( $addresses->[0]->active );
    is( $addresses->[0]->address1, 'C Addr 1 addr1' );

    ok( not $addresses->[1]->primary_entry );
    ok( $addresses->[1]->active );
    is( $addresses->[1]->address1, 'C Addr 0 addr1' );

    my $phones = $client->phones;
    is( @{ $phones }, 2 );

    ok( $phones->[0]->primary_entry );
    ok( $phones->[0]->active );
    is( $phones->[0]->phone_number, 'C Ph 1 num' );

    ok( not $phones->[1]->primary_entry );
    ok( $phones->[1]->active );
    is( $phones->[1]->phone_number, 'C Ph 0 num' );

    my $emergencies = $client->get_emergency_contacts;
    is( @{ $emergencies }, 2 );

    is( $emergencies->[0]->rolodex->fname, 'Emrg 0 Fname' );
    is( $emergencies->[0]->rolodex->lname, 'Emrg 0 Lname' );
    is( $emergencies->[0]->rolodex->comment_text, 'Emrg 0 txt' );
    is( $emergencies->[0]->rolodex->phones->[0]->phone_number, 'Emrg 0 ph' );

    is( $emergencies->[1]->rolodex->fname, 'Emrg 1 Fname' );
    is( $emergencies->[1]->rolodex->lname, 'Emrg 1 Lname' );
    is( $emergencies->[1]->rolodex->comment_text, 'Emrg 1 txt' );
    is( $emergencies->[1]->rolodex->phones->[0]->phone_number, 'Emrg 1 ph' );

    return if $step < 3;

    my $employment = $client->relationship_primary('employment');

    is( $employment->rolodex->name, 'Employer' );
    is( $employment->job_title, 'Job' );
    is( $employment->supervisor, 'Super' );
    ok( $employment->rolodex->phones->[0] );
    is( $employment->rolodex->phones->[0]->phone_number, 'Emp Ph' );
    ok( $employment->rolodex->phones->[0]->call_ok );
    ok( $employment->rolodex->phones->[0]->message_ok );
    is( $employment->rolodex->addresses->[0]->address1, 'Emp Addr1' );
    is( $employment->rolodex->addresses->[0]->address2, 'Emp Addr2' );
    is( $employment->rolodex->addresses->[0]->city, 'Emp City' );
    is( $employment->rolodex->addresses->[0]->state, 'or' );
    is( $employment->rolodex->addresses->[0]->post_code, 22222 );

    is( $client->edu_level, 1 );
    is( $client->marital_status, 'Married' );
    is( $client->race, 'Alaskan native' );
    is( $client->religion, 'No preference' );
    is( $client->language_spoken, 'English' );
    is( $client->nationality_id, 1 );
    is( $client->household_annual_income, 1 );
    is( $client->household_population, 1 );
    is( $client->household_population_under18, 1 );
    is( $client->dependents_count, 1 );

    return if $step < 4;

    my $treaters = $client->relationship_primary('treaters');

    is( $treaters->rolodex->name, 'Pri Trt Name' );
    is( $treaters->rolodex->fname, 'Pri Trt Fname' );
    is( $treaters->rolodex->lname, 'Pri Trt Lname' );
    is( $treaters->rolodex->phones->[0]->phone_number, 'Pri Trt Ph' );
    is( $treaters->rolodex->addresses->[0]->address1, 'Pri Trt Addr1' );
    is( $treaters->rolodex->addresses->[0]->address2, 'Pri Trt Addr2' );
    is( $treaters->rolodex->addresses->[0]->city, 'Pri Trt City' );
    is( $treaters->rolodex->addresses->[0]->state, 'or' );
    is( $treaters->rolodex->addresses->[0]->post_code, 33333 );

    return if $step < 5;

    ok( $client->intake );

    is( $client->intake_step, undef, 'no intake_step' );
    ok( $client->placement->referral, 'found a referral' );
    is( $client->placement->program_id, 1001,
        '... with correct program_id' );
    is( $client->placement->staff_id, 1002,
        '... and staff_id' );
    is( $client->placement->level_of_care_id, 1002,
        '... and level_of_care_id' );
    is_deeply_except(
        {
            rec_id => qr/^\d+$/,
        },
        $client->placement->referral,
        {
            client_id                 => $client->client_id,
            rolodex_referral_id       => 1010,
            agency_contact            => 'Agency Contact',
            agency_type               => 'Agency Type',
            active                    => 1,
            client_placement_event_id => $client->placement->event->rec_id,
        },
    );
}

    $one = $CLASS->new_with_cgi_params(
        step => 1,
        op   => 'step1',
    );

    is_deeply( $one->step1, {
        step        => 1,
        client      => { step => 1 },
        dupsok      => 0,
        duplicates  => 0,
    });

    $one = $CLASS->new_with_cgi_params(
        op      => 'step1_save',
        lname   => 'Marley',
        mname   => 'Zebadaya',
        fname   => 'Bob',
        ssn     => '777777777',
        dob     => '1958-10-10',
        sex     => 'Male',
    );

    ok( $result = $one->step1_save );
    $client = eleMentalClinic::Client->retrieve( $result->{ forward_args }->[0]->{ client_id } );
    test_intake( 1, $client->client_id );

    $one = $CLASS->new_with_cgi_params(client_id => $client->client_id);
    is_deeply( $one->step2,
        {
            client => $client,
            step => 2,
            client_addresses_count => 1,         
            client_phones_count => 1,   
            client_emergency_count => 1,
            no_address   => 0,
            no_phone     => 0,
            no_emergency => 0,
        }
    );

    $one = $CLASS->new_with_cgi_params(
        op => 'step2_save',
        client_id => $client->client_id,
        email => 'bob@bobmarley.com',

        # Originally I used very clear data, but it was too long, I had to shorten it
        # but keep it useful: 
        'client_address[0][address1]' => 'C Addr 0 addr1',
        'client_address[0][address2]' => 'C Addr 0 addr2',
        'client_address[0][city]'    => 'C Addr 0 city',
        'client_address[0][state]'   => 'or',
        'client_address[0][post_code]' => 00000,
        'client_address[0][county]' => 'C Addr 0 county',
        'client_address[0][active]' => 'on',
        'client_address[1][address1]' => 'C Addr 1 addr1',
        'client_address[1][address2]' => 'C Addr 1 addr2',
        'client_address[1][city]'    => 'C Addr 1 city',
        'client_address[1][state]'   => 'or',
        'client_address[1][post_code]' => 11111,
        'client_address[1][county]' => 'C Addr 1 county',
        'client_address[1][active]' => 'on',
        client_address_primary => 1,

        'client_phone[0][phone_number]' => 'C Ph 0 num',
        'client_phone[0][phone_type]' => 'C Ph 0 type',
        'client_phone[0][call_ok]' => 'on',
        'client_phone[0][message_ok]' => 'on',
        'client_phone[0][active]' => 'on',
        'client_phone[1][phone_number]' => 'C Ph 1 num',
        'client_phone[1][phone_type]' => 'C Ph 1 type',
        'client_phone[1][call_ok]' => 'on',
        'client_phone[1][message_ok]' => 'on',
        'client_phone[1][active]' => 'on',
        client_phone_primary => 1,

        'client_emergency_contact[0][fname]' => 'Emrg 0 fname',
        'client_emergency_contact[0][lname]' => 'Emrg 0 lname',
        'client_emergency_contact[0][phone_number]' => 'Emrg 0 ph',
        'client_emergency_contact[0][comment_text]' => 'Emrg 0 txt',
        'client_emergency_contact[1][fname]' => 'Emrg 1 fname',
        'client_emergency_contact[1][lname]' => 'Emrg 1 lname',
        'client_emergency_contact[1][phone_number]' => 'Emrg 1 ph',
        'client_emergency_contact[1][comment_text]' => 'Emrg 1 txt',
        client_emergency_contact_primary => 1,
    );
    ok( $result = $one->step2_save );
    test_intake( 2, $client->client_id );
            
    $client = eleMentalClinic::Client->retrieve( $result->{ forward_args }->[0]->{ client_id } );

    $one = $CLASS->new_with_cgi_params(client_id => $client->client_id);
    is_deeply(
        $one->step3,
        {
            client => $client,
            step => 3,
            no_employment => 0,
        }
    );

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->client_id,
        op => 'step3_save',
        name => 'Employer',
        'client_employer[0][job_title]' => 'Job',
        'client_employer[0][supervisor]' => 'Super',
        'client_employer_phone[0][phone_number]' => 'Emp Ph',
        'client_employer_phone[0][call_ok]' => 'on',
        'client_employer_phone[0][message_ok]' => 'on',
        'client_employer_address[0][address1]' => 'Emp Addr1',
        'client_employer_address[0][address2]' => 'Emp Addr2',
        'client_employer_address[0][city]' => 'Emp City',
        'client_employer_address[0][state]' => 'or',
        'client_employer_address[0][post_code]' => 22222,
        'client[0][edu_level]' => '1',
        'client[0][marital_status]' => 'Married',
        'client[0][race]' => 'Alaskan native',
        'client[0][religion]' => 'No preference',
        'client[0][language_spoken]' => 'English',
        'client[0][nationality_id]' => 1,
        'client[0][household_annual_income]' => 1,
        'client[0][household_population]' => 1,
        'client[0][household_population_under18]' => 1,
        'client[0][dependents_count]' => 1,
    );
    ok( $result = $one->step3_save );
    test_intake( 3, $client->client_id );
            
    $client = eleMentalClinic::Client->retrieve( $result->{ forward_args }->[0]->{ client_id } );

    $one = $CLASS->new_with_cgi_params(client_id => $client->client_id);
    $assessment = $one->client->assessment ||
        eleMentalClinic::Client::Assessment->new({
            client_id => $one->get_client->id, 
            template_id => eleMentalClinic::Client::AssessmentTemplate->get_intake->id,
        });

    is_deeply($one->step4,
        {
            client => eleMentalClinic::Client->retrieve($client->client_id),
            step => 4,
            current_assessment => $assessment,
            fields => $assessment->all_fields,
            no_treater => 0,
        }
    );

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->client_id,
        op => 'step4_save',
        'client_primary_treater[0][name]' => 'Pri Trt Name',
        'client_primary_treater[0][fname]' => 'Pri Trt Fname',
        'client_primary_treater[0][lname]' => 'Pri Trt Lname',
        'client_primary_treater_phone[0][phone_number]' => 'Pri Trt Ph',
        'client_primary_treater_address[0][address1]' => 'Pri Trt Addr1',
        'client_primary_treater_address[0][address2]' => 'Pri Trt Addr2',
        'client_primary_treater_address[0][city]' => 'Pri Trt City',
        'client_primary_treater_address[0][state]' => 'or',
        'client_primary_treater_address[0][post_code]' => 33333,
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    ok( $result = $one->step4_save );
    test_intake( 4, $client->client_id );

### Inserted for JC #78, changing pcp overrides emergency contact

    $one = $CLASS->new_with_cgi_params(client_id => $client->client_id);
    $assessment = $one->client->assessment;
    is_deeply($one->step4,
        {
            client => eleMentalClinic::Client->retrieve($client->client_id),
            step => 4,
            current_assessment => $assessment,
            fields => $assessment->all_fields,
            no_treater => 0,
        }
    );

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->client_id,
        op => 'step4_save',
        'client_primary_treater[0][name]' => 'Pri Mod',
        'client_primary_treater[0][fname]' => 'Pri Mod Fname',
        'client_primary_treater[0][lname]' => 'Pri Mod Lname',
        'client_primary_treater_phone[0][phone_number]' => 'Pri Mod Ph',
        'client_primary_treater_address[0][address1]' => 'Pri Mod Addr1',
        'client_primary_treater_address[0][address2]' => 'Pri Mod Addr2',
        'client_primary_treater_address[0][city]' => 'Pri Mod City',
        'client_primary_treater_address[0][state]' => 'ca',
        'client_primary_treater_address[0][post_code]' => 33334,
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    ok( $result = $one->step4_save );
    
    #now change it back so the test data should match the function
    $one = $CLASS->new_with_cgi_params(
        client_id => $client->client_id,
        op => 'step4_save',
        'client_primary_treater[0][name]' => 'Pri Trt Name',
        'client_primary_treater[0][fname]' => 'Pri Trt Fname',
        'client_primary_treater[0][lname]' => 'Pri Trt Lname',
        'client_primary_treater_phone[0][phone_number]' => 'Pri Trt Ph',
        'client_primary_treater_address[0][address1]' => 'Pri Trt Addr1',
        'client_primary_treater_address[0][address2]' => 'Pri Trt Addr2',
        'client_primary_treater_address[0][city]' => 'Pri Trt City',
        'client_primary_treater_address[0][state]' => 'or',
        'client_primary_treater_address[0][post_code]' => 33333,
    );
    $one->current_user( eleMentalClinic::Personnel->retrieve( 1001 ));
    ok( $result = $one->step4_save );
    test_intake( 4, $client->client_id );

    $client = eleMentalClinic::Client->retrieve( $result->{ forward_args }->[0]->{ client_id } );

    $one = $CLASS->new_with_cgi_params(
        client_id => $client->client_id,
        program_id => 1001,
        event_date => '2222-2-2',
        staff_id => 1002,
        level_of_care_id => 1002,
        is_referral => 1,
        rolodex_id => 1010,
        agency_type => 'Agency Type',
        agency_contact => 'Agency Contact',
    );

    ok( $result = $one->step5_save );
    test_intake( 5, $client->client_id );

    #Make sure the params are not used anymore .
    ok( not $one->session->param( 'presenting_problem-' . $one->client->id ));
    ok( not $one->session->param( 'medications-' . $one->client->id ));
    ok( not $one->session->param( 'special_needs-' . $one->client->id ));

dbinit();
