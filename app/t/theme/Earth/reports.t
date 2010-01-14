#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More tests => 67;

use lib 't/lib';
use Earth::Mechanize;
use t::Mechanize::Report;

t::Mechanize::Report->run(
    Earth::Mechanize->new_with_server
);
