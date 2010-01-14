# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More 'no_plan';

use eleMentalClinic::Test;
use eleMentalClinic::DB::Migration;

our $test;

SKIP: {
    my $m = eleMentalClinic::DB::Migration->new;
    skip "your database has no version", 1
        if $m->get_version == 0;
    skip "your database version is already >= 429", 1
        if $m->get_version >= 429;

    $test->db_refresh;
    $test->insert_data;

    my %security;
    for my $person (@{ $test->db->select_many(
        [ '*' ],
        eleMentalClinic::Personnel->table,
        '',
        '',
    ) }) {
        my %s;
        @s{ @{eleMentalClinic::Personnel->security_fields} } = (
            map { $_ ? 1 : 0 } split /\s*/, $person->{security}
        );
        $security{ $person->{staff_id} } = \%s;
    }
    
    eval { $m->migrate(from_version => $m->get_version, to_version => 429) };
    is $@, '', 'no errors during migration';

    for my $person (@{ eleMentalClinic::Personnel->get_all }) {
        is_deeply(
            $person->_build_security,
            $security{$person->staff_id},
            "correctly converted security for " . $person->staff_id,
        );
    }

    $test->db_refresh;
}
