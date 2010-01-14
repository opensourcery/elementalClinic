# Copyright (C) 2004-2008 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Test::More tests => 6;
use Test::Exception;
use Test::Warn;
our ($CLASS, $one);
BEGIN {
    *CLASS = \'eleMentalClinic::DB::Initialization';
    use_ok( $CLASS );
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
#
    ok( $one = $CLASS->new, '$CLASS->new' );
    ok( defined( $one ), 'is defined $one' );
    ok( $one->isa( $CLASS ), 'isa $CLASS' );
    ok( defined( $one->{db} ), 'is defined $one->db' );
    ok( $one->{db}->isa( 'eleMentalClinic::DB' ), '$one->db isa eMC::DB' );
