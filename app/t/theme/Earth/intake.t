#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More 'no_plan';
use lib 't/lib';
use Earth::t::Mechanize::Intake;

eval { Earth::t::Mechanize::Intake->new->run };
is $@, '', 'no errors during test';
