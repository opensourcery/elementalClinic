#!/usr/bin/env perl
use strict;
use warnings;
$|++;

use lib 'lib';
use eleMentalClinic::Test qw/ $test /;

print "Importing test data...";
$test->insert_data;
print "done.\n";
