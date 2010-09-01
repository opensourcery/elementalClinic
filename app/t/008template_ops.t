#!/usr/bin/perl

# Test our custom template vmethods

use strict;
use warnings;

use Test::More tests => 2;

use eleMentalClinic::Template;

eleMentalClinic::Template->init_custom_methods;

note "pad_right"; {
    my $code = $Template::Stash::SCALAR_OPS->{pad_right};
    is $code->("foo", "_", 10),  "foo_______";
    is $code->("foo", "xo", 10), "fooxoxoxo";
}
