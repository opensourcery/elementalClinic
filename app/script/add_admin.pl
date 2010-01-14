#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';

use eleMentalClinic::Fixtures;
use eleMentalClinic::DB;
use eleMentalClinic::Role;
use eleMentalClinic::Personnel;

my $config = eleMentalClinic::Config->new;

use YAML::Syck;

my $personnel = YAML::Syck::LoadFile(
  'fixtures/base-sys/personnel.yaml'
);

my $admin = $personnel->{1};
delete $admin->{ staff_id };

$config->db->dbh->do(
  'INSERT INTO personnel (' .
  join(',', keys %$admin) .
  ') VALUES( ' .
  join(',', map { $config->db->dbh->quote($admin->{$_}) }
    keys %$admin
  ) .
  ')'
);

my $id = $config->db->dbh->last_insert_id(undef, undef, 'personnel', undef);
print "ID: $id\n";

my $user = eleMentalClinic::Personnel->retrieve( $id );

my $admin_role = eleMentalClinic::Role->admin_role();
$admin_role->add_member( $user->primary_role );
my $active_role = eleMentalClinic::Role->get_one_by_( name => 'active' );
$active_role->add_member( $user->primary_role );


