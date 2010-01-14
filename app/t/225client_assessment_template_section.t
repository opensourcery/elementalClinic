# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Client::AssessmentTemplate::Section';
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
    is( $one->table, 'assessment_template_sections' );
    is( $one->primary_key, 'rec_id' );
    is_deeply( $one->fields, [ qw/
        rec_id label position assessment_template_id
    /]);
    is_deeply( [ sort @{ $CLASS->fields } ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Sanity checks fro coverage

ok( not $CLASS->get_one_by_position_in_template );
ok( not $CLASS->get_one_by_position_in_template( 1, undef ));
ok( not $CLASS->get_one_by_position_in_template( undef, 1 ));
ok( not $CLASS->get_one_by_position_in_template( 0, 1 ));
ok( not $CLASS->get_one_by_position_in_template( 100, 100 ));
ok( not $CLASS->get_alerts_by_template( 100 ));

dbinit();
