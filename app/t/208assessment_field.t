# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 31;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $two, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::Assessment::Field';
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
    is( $one->table, 'client_assessment_field' );
    is( $one->primary_key, 'rec_id' );
    is_deeply( $one->fields, [ qw/
        rec_id client_assessment_id template_field_id value
    /]);
    is_deeply( [ sort @{ $CLASS->fields } ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    for ( 1001 .. 1010 ) {
        is_deeply(
            $CLASS->retrieve( $_ ),
            $client_assessment_field->{ $_ },
        );
    };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# label

    for ( 1001 .. 1010 ) {
        is(
            $CLASS->retrieve( $_ )->label,
            $assessment_template_fields->{ 
                $client_assessment_field->{ $_ }->{ template_field_id }
            }->{ label }
        );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Sanity checks (for coverage)

    ok( not $CLASS->get_one_by_assessment_and_template_field );
    ok( not $CLASS->get_one_by_assessment_and_template_field( 1 ));
    ok( not $CLASS->get_one_by_assessment_and_template_field( undef, 1 ));

dbinit();
