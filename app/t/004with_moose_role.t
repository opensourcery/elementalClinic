#!/usr/bin/perl

# Test eleMentalClinic::Util::with_moose_role()

use strict;
use warnings;

use Test::More 'no_plan';


# Basic with_moose_role
{
    {
        package Foo::Moose;
        use Moose::Role;
        requires "wibble";
        sub this { 42 }
    }

    {
        package Foo::NotMoose;
        use eleMentalClinic::Util;

        ::ok ! eval { with_moose_role("Foo::Moose"); },
          "with_moose_role() honors requires";

        *wibble = sub { 23 };
        ::ok eval { with_moose_role("Foo::Moose"); };

        ::is __PACKAGE__->this, 42, "  applies role methods";
    } 

}
