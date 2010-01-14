# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 47;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Financial::BillingPrognote';
    use_ok( $CLASS );
}

# Turn off the warnings coming from validation during financial setup.
$eleMentalClinic::Base::TESTMODE = 1;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
    financial_reset_sequences();
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table info
    is( $one->table, 'billing_prognote');
    is( $one->primary_key, 'rec_id');
    is_deeply( $one->fields, [qw/
        rec_id billing_service_id prognote_id
    /]);
    is_deeply( [ sort @{$CLASS->fields} ], $test->db_fields( $CLASS->table ) );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# run the billing cycles 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
        $test->financial_setup( 1 );
        $test->financial_setup( 2 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prognote, auto-generated
        my %exceptions = ( previous_billing_status => undef, billing_status => undef, modified => undef );
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1001 )->prognote, $prognote->{ 1065 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1002 )->prognote, $prognote->{ 1066 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1003 )->prognote, $prognote->{ 1043 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1004 )->prognote, $prognote->{ 1044 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1005 )->prognote, $prognote->{ 1045 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1006 )->prognote, $prognote->{ 1046 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1007 )->prognote, $prognote->{ 1047 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1008 )->prognote, $prognote->{ 1048 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1009 )->prognote, $prognote->{ 1056 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1010 )->prognote, $prognote->{ 1057 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1011 )->prognote, $prognote->{ 1058 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1012 )->prognote, $prognote->{ 1059 });
    is_deeply_except( \%exceptions, $CLASS->retrieve( 1013 )->prognote, $prognote->{ 1043 });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

