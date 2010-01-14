#!/usr/bin/perl
# Copyright (C) 2006-2007 OpenSourcery, LLC.
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
use strict;
use warnings;

use Data::Dumper;
use lib qw/ lib /;

use eleMentalClinic::Personnel;
use eleMentalClinic::Client;

my $date = shift;
if( my $config_path = shift ) {
    $eleMentalClinic::Config::CONFIG_PATH = $config_path;
}

# update productivity numbers
for my $personnel( @{ eleMentalClinic::Personnel->new->get_all }) {
    $personnel->productivity_update( $date );
}

# update capitation
for my $client( @{ eleMentalClinic::Client->get_all }) {
    my $insurers = $client->insurance_bytype( 'mental health', 1 );
    next unless $insurers;
    for( @$insurers ) {
        next unless $_->authorization;
        $_->authorization->update_capitation
    }
}
