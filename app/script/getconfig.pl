#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';

use eleMentalClinic::DB;
use eleMentalClinic::Config;

my $config = eleMentalClinic::Config->new;

for my $var ( @ARGV ) {
    eval { print "$var: " . ($config->$var || "(NO VALUE)") . "\n" };
    print "$var is not valid\n" if $@;
}
