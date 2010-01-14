# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 23;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::AssessmentTemplate::Field';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'assessment_template_fields' );
    is( $one->primary_key, 'rec_id' );
    is_deeply( $one->fields, [ qw/
        rec_id label position field_type assessment_template_section_id choices
    /]);
    is_deeply( [ sort @{ $CLASS->fields } ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_one_by_position_in_section

    is_deeply( 
        $CLASS->get_one_by_position_in_section( 0, 1001 ),
        $CLASS->retrieve( 1001 ), 
    );
    is_deeply( 
        $CLASS->get_one_by_position_in_section( 1, 1001 ),
        $CLASS->retrieve( 1002 ), 
    );
    is_deeply( 
        $CLASS->get_one_by_position_in_section( 2, 1001 ),
        $CLASS->retrieve( 1003 ), 
    );

    # Passing a section object instead of ID
    $tmp = eleMentalClinic::Client::AssessmentTemplate::Section->retrieve( 1002 );
    is_deeply( 
        $CLASS->get_one_by_position_in_section( 0, $tmp ),
        $CLASS->retrieve( 1004 ), 
    );
    is_deeply( 
        $CLASS->get_one_by_position_in_section( 1, $tmp ),
        $CLASS->retrieve( 1005 ), 
    );
    is_deeply( 
        $CLASS->get_one_by_position_in_section( 2, $tmp ),
        $CLASS->retrieve( 1006 ), 
    );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    foreach ( 1101 .. 1105 ) {
        is_deeply(
            $CLASS->retrieve( $_ )->list_choices,
            [ '', split(/\s*,\s*/, $CLASS->retrieve( $_ )->choices || "" ) ]
        );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Sanity checks for coverage

    ok( not $CLASS->get_one_by_position_in_section );
    ok( not $CLASS->get_one_by_position_in_section( undef, 1));
    ok( not $CLASS->get_one_by_position_in_section( 1, undef ));
    ok( not $CLASS->get_one_by_position_in_section( 100, 100 ));



dbinit();
