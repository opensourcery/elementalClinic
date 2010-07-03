# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 12;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::PDF';
    use_ok( $CLASS );
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
        $test->insert_data;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write_pdf 
    can_ok( $one, 'write_pdf' );

    is( $one->write_pdf, undef );
    is( $one->write_pdf( 'wacoauth' ), undef );
    is( $one->write_pdf( 'wacoauth', 'test.pdf' ), undef );

        # all coordinate units are found using 72 dpi => 72 units per inch
        # y coordinates: zero starts at the bottom

        my $client = eleMentalClinic::Client->new({ client_id => 1001 })->retrieve;        

        my $fields = [
            { x =>  62, y => 637, value => 'X' }, # init auth
            { x => 293, y => 637, value => 'X' }, # continued treatment auth
            { x => 168, y => 617, value => 'Agency' },
            { x => 168, y => 598, value => 'Jan 05, 2006' },
            { x => 416, y => 617, value => 'Location' },
            { x => 416, y => 598, value => 'Apr 15, 2006' },
            { x => 145, y => 557, value => $client->{ lname } },
            { x => 392, y => 557, value => $client->{ fname } },
            { x => 145, y => 537, value => $client->{ dob } },
            { x => 392, y => 537, value => $client->{ ssn } },
            { x => 219, y => 521, value => 'first diagnosis' },
            { x => 224, y => 505, value => 'second diagnosis' },
            { x => 456, y => 506, value => 'locus_casII_score' },
        ];

        my $output = $one->config->pdf_out_root . '/wacoauth.pdf';
    ok( $one->start_pdf( $output, 'wacoauth' ) );
    ok( $one->write_pdf( $fields ) );
    is_pdf_file($safe_output);

    #cmp_pdf( $tmp, '/var/spool/elementalclinic/pdf_out/test.pdf' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

