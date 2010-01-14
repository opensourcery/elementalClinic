# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 118;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Demographics';
    use_ok( q/eleMentalClinic::Controller::Base::Demographics/ );
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
        home edit save
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home edit save
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    ok( $one = $CLASS->new_with_cgi_params());
    isa_ok( $one, $CLASS );
    is_deeply( $one->home, {});

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# edit
    ok( $one = $CLASS->new_with_cgi_params( op => 'edit' ));
    isa_ok( $one, $CLASS );
    is_deeply( $one->edit, { current => undef, op => 'edit' } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    my $client = eleMentalClinic::Client->retrieve( 1003 );

    # save missing all
    ok( $one = $CLASS->new_with_cgi_params( op => 'save' ));
    isa_ok( $one, $CLASS );
    ok( $one->save );
    is_deeply( $one->errors, [
        '<strong>Client</strong> is required.',
    ]);

    # save some bad data
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        addr_1_address1    => '123 Street',
        addr_1_city        => 'Portland',
        addr_1_state       => 'France',
        addr_1_post_code   => 'ableh',

        id_1_addr => $client->addresses->[0]->rec_id,
    ));
    isa_ok( $one, $CLASS );
    ok( $one->save );
    is_deeply( $one->errors, [
        '<strong>Client</strong> is required.',
        '<strong>Primary state</strong> must be the 2-letter abbreviation for a US state name.',
        '<strong>Primary zip code</strong> must be an integer.',
    ]);
    is_deeply(
        $one->bad_params,
        {
            input_addrs => [ map { $one->values_for_( 'addr', $_ ) } 1 .. 3 ],
            input_phns => [ map { $one->values_for_( 'phn', $_ ) } 1 .. 3 ],
        },
        "extra params on error"
    );

    # save missing some data
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        client_id   => 1003,
        addr_1_state       => 'OR',
        addr_1_post_code   => '97222',

        id_1_addr => $client->addresses->[0]->rec_id,
    ));
    isa_ok( $one, $CLASS );
    ok( $one->save );
    ok( !$one->errors );
    is_deeply( $one->bad_params, {}, "no extra params on success" );

    # save all req, no optional
    ok( $one = $CLASS->new_with_cgi_params(
        op          => 'save',
        client_id   => 1003,
        addr_1_address1    => '123 Street',
        addr_1_city        => 'Portland',
        addr_1_state       => 'OR',
        addr_1_post_code   => '97222',

        id_1_addr => $client->addresses->[0]->rec_id,
    ));
    isa_ok( $one, $CLASS );
    is_deeply( $one->save->{ current }, undef, 'saving works' );

    # Clearing address or phone fields
    ok( $one = $CLASS->new_with_cgi_params(
        op           => 'save',
        client_id    => 1003,
        addr_1_address2    => 'addr2',
        phn_1_phone_number => '555-555-5555',
        id_1_addr => $client->addresses->[0]->rec_id,
        id_1_phn  => $client->phones->[0]->rec_id,

        # Required
        addr_1_address1    => '123 Street',
        addr_1_city        => 'Portland',
        addr_1_state       => 'OR',
        addr_1_post_code   => '97222',
    ));
    isa_ok( $one, $CLASS );
    ok( $one->save, 'saving worked' );
    is( $client->addresses->[0]->address2, 'addr2', "Address2 saved" );
    is( $client->phones->[0]->phone_number, '555-555-5555', "phone number saved" );

    ok( $one = $CLASS->new_with_cgi_params(
        op           => 'save',
        client_id    => 1003,
        addr_1_address2     => '',
        phn_1_phone_number => '',
        id_1_addr => $client->addresses->[0]->rec_id,
        id_1_phn  => $client->phones->[0]->rec_id,

        # Required
        addr_1_address1    => '123 Street',
        addr_1_city        => 'Portland',
        addr_1_state       => 'OR',
        addr_1_post_code   => '97222',
    ));
    isa_ok( $one, $CLASS );
    ok( $one->save, 'saving worked' );
    $client = eleMentalClinic::Client->retrieve( 1003 );
    is( $client->addresses->[0]->address2, undef, "Address2 saved" );

    ok( $one = $CLASS->new_with_cgi_params(
        op           => 'save',
        client_id    => 1003,
        addr_1_address2     => 'addr2',
        phn_1_phone_number => '555-555-5555',
        id_1_addr => $client->addresses->[0]->rec_id,
        id_1_phn  => $client->phones->[0]->rec_id,

        # Required
        addr_1_address1    => '123 Street',
        addr_1_city        => 'Portland',
        addr_1_state       => 'OR',
        addr_1_post_code   => '97222',
    ));
    isa_ok( $one, $CLASS );
    ok( $one->save, 'saving worked' );
    $client = eleMentalClinic::Client->retrieve( 1003 );
    is( $client->phones->[0]->phone_number, '555-555-5555', "phone number saved" );
    ok( $one = $CLASS->new_with_cgi_params(
        op           => 'save',
        client_id    => 1003,
        addr_1_address2     => 'addr2',
        id_1_addr => $client->addresses->[0]->rec_id,
        id_1_phn  => $client->phones->[0]->rec_id,

        # Required
        addr_1_address1    => '123 Street',
        addr_1_city        => 'Portland',
        addr_1_state       => 'OR',
        addr_1_post_code   => '97222',
    ));
    isa_ok( $one, $CLASS );
    ok( $one->save, 'saving worked' );
    $client = eleMentalClinic::Client->retrieve( 1003 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    $client = eleMentalClinic::Client->retrieve( 1001 );

    #Clear any pre-existing
    $_->delete for (@{ $client->addresses }, @{ $client->phones });

    ok( $one = $CLASS->new_with_cgi_params(
        op           => 'save',
        client_id    => 1001,

        addr_1_address1    => '123 Street',
        addr_1_address2    => 'addr2',
        addr_1_city        => 'Portland',
        addr_1_state       => 'OR',
        addr_1_post_code   => '97222',

        addr_2_address1    => '124 Street',
        addr_2_address2    => '',
        addr_2_city        => 'Portland',
        addr_2_state       => 'OR',
        addr_2_post_code   => '97222',

        addr_3_address1    => '',
        addr_3_address2    => '',
        addr_3_city        => '',
        addr_3_state       => '',
        addr_3_post_code   => '',

        phn_1_phone_number => '555-5555',
        phn_1_phone_type   => 'Home',
        phn_1_call_ok      => 0,
        phn_1_message_ok   => 1,

        phn_2_phone_number => '555-5556',
        phn_2_phone_type   => 'Cell',
        phn_2_call_ok      => 1,
        phn_2_message_ok   => 0,

        phn_3_phone_number => '',
        phn_3_phone_type   => '',
        phn_3_call_ok      => '',
        phn_3_message_ok   => '',
    ));

    is_deeply(
        $one->values_for_( 'addr', 1 ),
        {
            address1    => '123 Street',
            address2    => 'addr2',
            city        => 'Portland',
            state       => 'OR',
            post_code   => '97222',
        },
        "Got values for address1"
    );
    ok( ! $one->values_empty_for_( 'addr', 1 ), "address 1 not empty" );

    is_deeply(
        $one->values_for_( 'addr', 2 ),
        {
            address1    => '124 Street',
            address2    => undef,
            city        => 'Portland',
            state       => 'OR',
            post_code   => '97222',
        },
        "Got values for address2"
    );
    ok( ! $one->values_empty_for_( 'addr', 2 ), "address 2 not empty" );

    is_deeply(
        $one->values_for_( 'addr', 3 ),
        {
            address1    => undef,
            address2    => undef,
            city        => undef,
            state       => undef,
            post_code   => undef,
        },
        "Got values for address3"
    );
    ok( $one->values_empty_for_( 'addr', 3 ), "address 3 is empty" );

    is_deeply(
        $one->values_for_( 'phn', 1 ),
        {
            phone_number => '555-5555',
            phone_type   => 'Home',
            call_ok      => 0,
            message_ok   => 1,
        },
        "Got values for phone1"
    );
    ok( ! $one->values_empty_for_( 'phn', 1 ), "phone 1 not empty" );

    is_deeply(
        $one->values_for_( 'phn', 2 ),
        {
            phone_number => '555-5556',
            phone_type   => 'Cell',
            call_ok      => 1,
            message_ok   => 0,
        },
        "Got values for phone2"
    );
    ok( ! $one->values_empty_for_( 'phn', 2 ), "phone 2 not empty" );

    is_deeply(
        $one->values_for_( 'phn', 3 ),
        {
            phone_number => undef,
            phone_type   => undef,
            call_ok      => 0,
            message_ok   => 0,
        },
        "Got values for phone3"
    );
    ok( $one->values_empty_for_( 'phn', 3 ), "phone 3 is empty" );

    my $obj = $one->save_ord_( 'addr', 1 );
    ok( $obj->rec_id, "Object stored" );
    is( $obj->rec_id, $client->addresses->[0]->rec_id, "Saved 1 w/ no pre-existing, should be primary" );
    ok( $obj->primary_entry, "primary_entry set." );
    is_deeply( $obj, $client->addresses->[0], "Built matches fetched" );
    ok( $obj->active, "New is active" );

    $obj = $one->save_ord_( 'addr', 2 );
    ok( $obj->rec_id, "Object stored" );
    is( $obj->rec_id, $client->addresses->[1]->rec_id, "Saved 2 w/ no pre-existing" );
    ok( !$obj->primary_entry, "primary_entry not set." );
    is_deeply( $obj, $client->addresses->[1], "Built matches fetched" );
    ok( $obj->active, "New is active" );

    ok( !$one->save_ord_( 'addr', 3 ), "No third address" );
    ok( !$client->addresses->[2], "No third address" );

    $obj = $one->save_ord_( 'phn', 1 );
    ok( $obj->rec_id, "Object stored" );
    is( $obj->rec_id, $client->phones->[0]->rec_id, "Saved 1 w/ no pre-existing, should be primary" );
    ok( $obj->primary_entry, "primary_entry set." );
    is_deeply( $obj, $client->phones->[0], "Built matches fetched" );
    ok( $obj->active, "New is active" );

    $obj = $one->save_ord_( 'phn', 2 );
    ok( $obj->rec_id, "Object stored" );
    is( $obj->rec_id, $client->phones->[1]->rec_id, "Saved 2 w/ no pre-existing" );
    ok( !$obj->primary_entry, "primary_entry not set." );
    is_deeply( $obj, $client->phones->[1], "Built matches fetched" );
    ok( $obj->active, "New is active" );

    ok( !$one->save_ord_( 'phn', 3 ), "No third phone" );
    ok( !$client->phones->[2], "No third phone" );

    my $ids = {
        phones => [
            map { $_->rec_id } @{ $client->phones }
        ],
        addresses => [
            map { $_->rec_id } @{ $client->addresses }
        ]
    };

    ok( $one = $CLASS->new_with_cgi_params(
        op           => 'save',
        client_id    => 1001,

        id_1_addr => eval { $client->addresses->[0]->rec_id } || undef,
        id_2_addr => eval { $client->addresses->[1]->rec_id } || undef,
        id_3_addr => eval { $client->addresses->[2]->rec_id } || undef,

        id_1_phn => eval { $client->phones->[0]->rec_id } || undef,
        id_2_phn => eval { $client->phones->[1]->rec_id } || undef,
        id_3_phn => eval { $client->phones->[2]->rec_id } || undef,

        addr_1_address1    => '123 Streetx',
        addr_1_address2    => 'addr2x',
        addr_1_city        => 'Portlandx',
        addr_1_state       => 'OR',
        addr_1_post_code   => '97222',

        addr_2_address1    => '',
        addr_2_address2    => '',
        addr_2_city        => '',
        addr_2_state       => '',
        addr_2_post_code   => '',

        addr_3_address1    => '',
        addr_3_address2    => '',
        addr_3_city        => '',
        addr_3_state       => '',
        addr_3_post_code   => '',

        phn_1_phone_number => '444-4444',
        phn_1_phone_type   => 'Homex',
        phn_1_call_ok      => 1,
        phn_1_message_ok   => 0,

        phn_2_phone_number => '',
        phn_2_phone_type   => '',
        phn_2_call_ok      => '',
        phn_2_message_ok   => '',

        phn_3_phone_number => '',
        phn_3_phone_type   => '',
        phn_3_call_ok      => '',
        phn_3_message_ok   => '',
    ));

    ok( $one->values_empty_for_( 'addr', 2 ), "address 2 is empty" );
    ok( $one->values_empty_for_( 'addr', 3 ), "address 3 is empty" );
    ok( $one->values_empty_for_( 'phn', 2 ), "phone 2 is empty" );
    ok( $one->values_empty_for_( 'phn', 3 ), "phone 3 is empty" );

    $obj = $one->save_ord_( 'addr', 1 );
    ok( $obj->rec_id, "Object stored" );
    is( $obj->rec_id, $client->addresses->[0]->rec_id, "Saved 1 w/ no pre-existing, should be primary" );
    ok( $obj->primary_entry, "primary_entry set." );
    is_deeply( $obj, $client->addresses->[0], "Built matches fetched" );
    ok( $obj->active, "is active" );
    is_deeply(
        { map { $_ => $obj->$_ } qw/address1 address2 city state post_code/ },
        $one->values_for_( 'addr', 1 ),
        "Updated address 1"
    );
    is( $obj->rec_id, $ids->{addresses}->[0], "Same id" );

    ok( !ref($one->save_ord_( 'addr', 2 )), "No second address" );
    ok( !$client->addresses->[1], "No second address" );
    ok( !$one->save_ord_( 'addr', 3 ), "No third address" );
    ok( !$client->addresses->[2], "No third address" );


    $obj = $one->save_ord_( 'phn', 1 );
    ok( $obj->rec_id, "Object stored" );
    is( $obj->rec_id, $client->phones->[0]->rec_id, "Saved 1 w/ no pre-existing, should be primary" );
    ok( $obj->primary_entry, "primary_entry set." );
    is_deeply( $obj, $client->phones->[0], "Built matches fetched" );
    ok( $obj->active, "is active" );
    is_deeply(
        { map { $_ => $obj->$_ || '0' } qw/phone_number phone_type call_ok message_ok/ },
        $one->values_for_( 'phn', 1 ),
        "Updated address 1"
    );
    is( $obj->rec_id, $ids->{phones}->[0], "Same id" );

    ok( !ref($one->save_ord_( 'phn', 2 )), "No second phone" );
    ok( !$client->phones->[1], "No second phone" );
    ok( !$one->save_ord_( 'phn', 3 ), "No third phone" );
    ok( !$client->phones->[2], "No third phone" );

    $ids = {
        phones => [
            map { $_->rec_id } @{ $client->phones }
        ],
        addresses => [
            map { $_->rec_id } @{ $client->addresses }
        ]
    };

    ok( $one = $CLASS->new_with_cgi_params(
        op           => 'save',
        client_id    => 1001,

        id_1_addr => eval { $client->addresses->[0]->rec_id } || undef,
        id_2_addr => eval { $client->addresses->[1]->rec_id } || undef,
        id_3_addr => eval { $client->addresses->[2]->rec_id } || undef,

        id_1_phn => eval { $client->phones->[0]->rec_id } || undef,
        id_2_phn => eval { $client->phones->[1]->rec_id } || undef,
        id_3_phn => eval { $client->phones->[2]->rec_id } || undef,

        addr_1_address1    => 'a',
        addr_1_address2    => 'a',
        addr_1_city        => 'a',
        addr_1_state       => 'ca',
        addr_1_post_code   => '11111',

        addr_2_address1    => 'b',
        addr_2_address2    => 'b',
        addr_2_city        => 'b',
        addr_2_state       => 'nv',
        addr_2_post_code   => '22222',

        addr_3_address1    => 'c',
        addr_3_address2    => 'c',
        addr_3_city        => 'c',
        addr_3_state       => 'ut',
        addr_3_post_code   => '33333',

        phn_1_phone_number => '111-1111',
        phn_1_phone_type   => 'a',
        phn_1_call_ok      => 1,
        phn_1_message_ok   => 0,

        phn_2_phone_number => '222-2222',
        phn_2_phone_type   => 'b',
        phn_2_call_ok      => 0,
        phn_2_message_ok   => 1,

        phn_3_phone_number => '333-3333',
        phn_3_phone_type   => 'c',
        phn_3_call_ok      => 1,
        phn_3_message_ok   => 1,
    ));

    $client = eleMentalClinic::Client->retrieve( $client->id );
    $one->save_values_for_( 'addr' );
    is_deeply(
        $client->addresses,
        [
            {
                primary_entry => 1,
                rec_id      => $ids->{ addresses }->[0],
                active      => 1,
                address1    => 'a',
                address2    => 'a',
                city        => 'a',
                state       => 'ca',
                post_code   => '11111',
                rolodex_id  => undef,
                client_id   => $client->id,
                county      => undef,
            },
            {
                primary_entry => 0,
                rec_id      => $client->addresses->[1]->rec_id,
                active      => 1,
                address1    => 'b',
                address2    => 'b',
                city        => 'b',
                state       => 'nv',
                post_code   => '22222',
                rolodex_id  => undef,
                client_id   => $client->id,
                county      => undef,
            },
            {
                primary_entry => 0,
                rec_id      => $client->addresses->[2]->rec_id,
                active      => 1,
                address1    => 'c',
                address2    => 'c',
                city        => 'c',
                state       => 'ut',
                post_code   => '33333',
                rolodex_id  => undef,
                client_id   => $client->id,
                county      => undef,
            }
        ],
        "addresses saved"
    );

    $one->save_values_for_( 'phn' );
    is_deeply(
        $client->phones,
        [
            {
                primary_entry => 1,
                active       => 1,
                client_id    => $client->id,
                rolodex_id  => undef,

                rec_id       => $ids->{ phones }->[0],
                phone_number => '111-1111',
                phone_type   => 'a',
                call_ok      => 1,
                message_ok   => 0,
            },
            {
                primary_entry => 0,
                rec_id       => $client->phones->[1]->rec_id,
                active       => 1,
                client_id    => $client->id,
                rolodex_id  => undef,

                phone_number => '222-2222',
                phone_type   => 'b',
                call_ok      => 0,
                message_ok   => 1,
            },
            {
                primary_entry => 0,
                rec_id       => $client->phones->[2]->rec_id,
                active       => 1,
                client_id    => $client->id,
                rolodex_id  => undef,

                phone_number => '333-3333',
                phone_type   => 'c',
                call_ok      => 1,
                message_ok   => 1,
            }
        ],
        "phones saved"
    );

    ok( $one = $CLASS->new_with_cgi_params(
        op           => 'save',
        client_id    => 1001,

        id_1_phn => eval { $client->phones->[0]->rec_id } || undef,

        phn_1_phone_number => '',
        phn_1_phone_type   => 'a',
        phn_1_call_ok      => 1,
        phn_1_message_ok   => 0,
    ));
    ok( $one->values_empty_for_( 'phn', 1 ), "phone 1 is empty because number is blank" );


dbinit();
