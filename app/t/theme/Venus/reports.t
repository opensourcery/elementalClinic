#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More tests => 96;

use lib 't/lib';
use Venus::Mechanize;
use t::Mechanize::Report;

t::Mechanize::Report->run(
    Venus::Mechanize->new_with_server,
);
