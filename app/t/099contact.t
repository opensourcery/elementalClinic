#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 110;

use eleMentalClinic::Test;

our (@CLASSES, $one, $tmp);
BEGIN {
    use_ok( $_ ) for (
        'eleMentalClinic::Contact::Address',
        'eleMentalClinic::Contact::Phone',
        'eleMentalClinic::Contact',
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit();

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~                              
# check to make sure what we're getting back can be dereferenced :)
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~                              

is_deeply(eleMentalClinic::Client->retrieve(1001)->addresses, []);
is_deeply(eleMentalClinic::Rolodex->retrieve(1001)->addresses, []);

is_deeply(eleMentalClinic::Client->retrieve(1001)->phones, []);
is_deeply(eleMentalClinic::Rolodex->retrieve(1001)->phones, []);

dbinit( 1 );

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~                              
# Address tests
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~                              

# construction test
ok ($one = eleMentalClinic::Client->retrieve(1001)->addresses->[0]);

# can test
foreach my $method (
    qw(
        rec_id client_id rolodex_id address1 address2 city state post_code county
        active primary_entry
    )
  )
{
    ok( $one->can($method) );
}

# read data test (some of these are defaults)
is($one->rec_id, 1020);
is($one->client_id, 1001);
is($one->rolodex_id, undef);
is($one->address1, '827 Broadway');
is($one->address2, undef);
is($one->city, 'New York');
is($one->state, 'NY');
is($one->post_code, 10003);
is($one->county, undef); 
is($one->active, 1);
is($one->primary_entry, 1); 

# read same data test, but for rolodex
ok ($one = eleMentalClinic::Rolodex->retrieve(1001)->addresses->[0]);
is($one->rec_id, 1001);
is($one->client_id, undef);
is($one->rolodex_id, 1001);
is($one->address1, '123 Jazz St');
is($one->address2, undef);
is($one->city, 'New Orleans');
is($one->state, 'LA');
is($one->post_code, 12345);
is($one->county, undef); 
is($one->active, 1);
is($one->primary_entry, 1); 

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~                              
# Save tests for Address
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~                              


ok($tmp = eleMentalClinic::Contact::Address->new({ client_id => 1001 }));
ok($tmp->address1('123 Foobar Way'));
ok($tmp->city('Funkytown'));
ok($tmp->state('PA'));
ok($tmp->post_code(12345));
ok($tmp->primary_entry(1));

ok($tmp->save);

ok($tmp = eleMentalClinic::Client->retrieve(1001)->addresses); # changing type: Address to Array of Address
is($tmp->[0]->address1, '123 Foobar Way');
is($tmp->[0]->city, 'Funkytown');
is($tmp->[0]->state, 'PA');
is($tmp->[0]->post_code, 12345);
is($tmp->[0]->primary_entry, 1);

# primary entry should set all of the other entries to false.
ok($one = eleMentalClinic::Client->retrieve(1001)->addresses->[0]);
ok($one->primary_entry(1));
ok($one->save);

ok($tmp->[1]->retrieve);
is($tmp->[1]->primary_entry, 0);

ok(eleMentalClinic::Contact::Address->save_from_form('client_id', 
    {
        'client_id' => 1001,
        'address_id' => $one->rec_id,
        'address1' => '123 foobar way',
        'blah' => 'foo',
    }
));

ok ($one = eleMentalClinic::Client->retrieve(1001)->addresses->[0]);
is ($one->address1, '123 foobar way');
is ($one->primary_entry, 1);
is ($one->active, 1);

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~                              
# Phone tests
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~                              

$test->db_refresh;
$test->insert_data;

ok ($one = eleMentalClinic::Client->retrieve(1001)->phones->[0]);

is ($one->rec_id, 1001);
is ($one->client_id, 1001);
is ($one->rolodex_id, undef);
is ($one->phone_number, '(212) 254-6436');
is ($one->message_ok, 1);
is ($one->call_ok, 1);
is ($one->active, 1);
is ($one->primary_entry, 1);
is ($one->phone_type, undef);

ok ($one = eleMentalClinic::Rolodex->retrieve(1001)->phones->[0]);

is ($one->rec_id, 1013);
is ($one->client_id, undef);
is ($one->rolodex_id, 1001);
is ($one->phone_number, '111-222-3333');
is ($one->message_ok, 1);
is ($one->call_ok, 1);
is ($one->active, 1);
is ($one->primary_entry, 1);
is ($one->phone_type, undef);

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~                              
# Save tests for Phone
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~                              
$test->db_refresh;
$test->insert_data;

ok($tmp = eleMentalClinic::Contact::Phone->new( { client_id => 1001 } ));
ok($tmp->phone_number('619-239-KING'));
ok($tmp->active(1));
ok($tmp->primary_entry(1));
ok($tmp->message_ok(0));
ok($tmp->call_ok(0));
ok($tmp->phone_type("Radio Advertisement from San Diego"));

ok($tmp->save);

ok($tmp = eleMentalClinic::Client->retrieve(1001)->phones); # changing type. Phone to Array of Phone
is($tmp->[0]->phone_number, '619-239-KING');
is($tmp->[0]->active, 1);
is($tmp->[0]->primary_entry, 1);
is($tmp->[0]->message_ok, 0);
is($tmp->[0]->call_ok, 0);
is($tmp->[0]->phone_type, "Radio Advertisement from San Diego");

# primary entry should set all of the other entries to false.
ok($one = eleMentalClinic::Client->retrieve(1001)->phones->[1]);
ok($one->primary_entry(1));
ok($one->save);

ok($tmp->[0]->retrieve);
is($tmp->[0]->primary_entry, 0);

$test->db_refresh;
$test->insert_data;

ok(eleMentalClinic::Contact::Phone->save_from_form('client_id', 
    {
        'client_id' => 1001,
        'phone_id' => $one->id,
        'phone_number' => '1234567890',
        'monkey' => 'shakespeare',
    }
));

# ordering has changed here since rec_id is the ordering agent -- our inserts start at one,
# fixtures start at 1001, etc.
# Orderinghas been fixed, sorted so that primary comes first, followed by rec_id ordering.
ok ($one = eleMentalClinic::Client->retrieve(1001)->phones->[0]);
is ($one->phone_number, '1234567890');
is ($one->primary_entry, 1);
is ($one->active, 1);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
