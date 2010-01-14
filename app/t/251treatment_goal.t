# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 12;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $CLASSDATA, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::TreatmentGoal';
    use_ok( $CLASS );
    $CLASSDATA = $tx_goals;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->empty );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'tx_goals');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        client_id staff_id problem_description
        plan_id rec_id medicaid start_date end_date 
        goal goal_stat goal_header eval comment_text
        goal_code rstat serv audit_trail goal_name active
    /]);
    is_deeply( $one->fields_required, [
         qw/ client_id staff_id plan_id
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    ok( $one = $CLASS->new({
        client_id   => $tx_plan->{ 1001 }{ client_id },
        staff_id    => $tx_plan->{ 1001 }{ staff_id },
        plan_id     => $tx_plan->{ 1001 }{ rec_id },
        active      => 1,
    }));
    ok( $one->save );
        
        $tmp = $one->id;
    is_deeply( $one, $CLASS->retrieve( $tmp ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
