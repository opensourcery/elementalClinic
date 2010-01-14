# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 159;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;
use eleMentalClinic::ValidData;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Lookup::ChargeCodes';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# methods
    can_ok( $one, qw/ client_id staff_id note_date program_id prognote_location_id / );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# lookup up charge codes by insurer
        $one = $CLASS->new;
        my $codes = eleMentalClinic::ValidData->new({ dept_id => 1001 })->list( '_charge_code' );
    can_ok( $CLASS, 'charge_codes_by_insurer' );
    ok( $CLASS->charge_codes_by_insurer );

    is( $CLASS->charge_codes_by_insurer( 1003, 1 ), undef );

    # same number of codes
    is( scalar keys %{ $CLASS->charge_codes_by_insurer }, 39 );
    is( scalar keys %{ $CLASS->charge_codes_by_insurer( 1003 )}, 39 );

    is( scalar keys %{ $CLASS->charge_codes_by_insurer( 1013 )}, 39 );
    is( scalar keys %{ $CLASS->charge_codes_by_insurer( 1013 )}, scalar @$codes );
    # same code ids
    is_deeply( [ sort keys %{ $CLASS->charge_codes_by_insurer( 1013 )}], [ sort map{ $_->{ rec_id }} @$codes ]);

    is_deeply( $CLASS->charge_codes_by_insurer( 1013 )->{ 1001 }, {
        charge_code_id                  => 1001,
        active                          => 1,
        dept_id                         => 1001,
        name                            => 90801,
        description                     => 'Psychiatric diagnostic interview',
        min_allowable_time              => 15,
        max_allowable_time              => 60,
        acceptable                      => 1,
        minutes_per_unit                => 60,
        dollars_per_unit                => '100.00',
        max_units_allowed_per_encounter => 1,
        max_units_allowed_per_day       => 2,
        cost_calculation_method         => 'Pro Rated Dollars per Unit',
    });
    is_deeply( $CLASS->charge_codes_by_insurer( 1013 )->{ 1003 }, {
        charge_code_id                  => 1003,
        active                          => 1,
        dept_id                         => 1001,
        name                            => 90805,
        description                     => 'Indiv therapy, insight, w/med mgt',
        min_allowable_time              => 15,
        max_allowable_time              => 60,
        acceptable                      => 1,
        minutes_per_unit                => 30,
        dollars_per_unit                => '65.72',
        max_units_allowed_per_encounter => 2,
        max_units_allowed_per_day       => 4,
        cost_calculation_method         => 'Pro Rated Dollars per Unit',
    });
    is_deeply( $CLASS->charge_codes_by_insurer( 1013 )->{ 1023 }, {
        charge_code_id                  => 1023,
        active                          => 1,
        dept_id                         => 1001,
        name                            => 'G0176',
        description                     => 'Activity therapy, individual or group',
        min_allowable_time              => 15,
        max_allowable_time              => 60,
        acceptable                      => 0,
        minutes_per_unit                => 45,
        dollars_per_unit                => '16.95',
        max_units_allowed_per_encounter => 4,
        max_units_allowed_per_day       => 12,
        cost_calculation_method         => 'Pro Rated Dollars per Unit',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# lookup up charge codes by insurer, only showing codes with data
    is( scalar keys %{ $CLASS->charge_codes_by_insurer( 1013, 'only' )}, 15 );
    is_deeply_except({ rec_id => undef, rolodex_id => undef },
        [ $CLASS->charge_codes_by_insurer( 1013, 'only' )->{ 1001 }],
        [ $insurance_charge_code_association->{ 1001 }],
    );
    is_deeply( $CLASS->charge_codes_by_insurer( 1013, 'only' )->{ 1003 }, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save charge code by insurer
    can_ok( $CLASS, 'insurer_charge_code_save' );
    throws_ok{ $CLASS->insurer_charge_code_save } qr/Rolodex id is required/;
    throws_ok{ $CLASS->insurer_charge_code_save( 1013 )} qr/Charge code id is required/;

    # with no charge code, should nuke the association
    ok( $CLASS->insurer_charge_code_save( 1013, 1001 ));
    is( scalar keys %{ $CLASS->charge_codes_by_insurer( 1013, 'only' )}, 14 );
    is( $CLASS->charge_codes_by_insurer( 1013, 'only' )->{ 1001 }, undef );

    # save one with same data, check it
    ok( $CLASS->insurer_charge_code_save( 1013, 1001, {
        acceptable                          => 1,
        dollars_per_unit                    => 123.45,
        max_units_allowed_per_encounter     => 2,
        max_units_allowed_per_day           => 3,
    }));
    is_deeply_except({ rec_id => undef, rolodex_id => undef },
        [ $CLASS->charge_codes_by_insurer( 1013, 'only' )->{ 1001 }],
        [{
            valid_data_charge_code_id           => 1001,
            acceptable                          => 1,
            dollars_per_unit                    => 123.45,
            max_units_allowed_per_encounter     => 2,
            max_units_allowed_per_day           => 3,
        }],
    );
    is( scalar keys %{ $CLASS->charge_codes_by_insurer( 1013, 'only' )}, 15 );

    # save existing record
    ok( $CLASS->insurer_charge_code_save( 1013, 1001, {
        acceptable                          => 1,
        dollars_per_unit                    => 678.90,
        max_units_allowed_per_encounter     => 7,
        max_units_allowed_per_day           => 8,
    }));
    is_deeply_except({ rec_id => undef, rolodex_id => undef },
        [ $CLASS->charge_codes_by_insurer( 1013, 'only' )->{ 1001 }],
        [{
            valid_data_charge_code_id           => 1001,
            acceptable                          => 1,
            dollars_per_unit                    => '678.90',
            max_units_allowed_per_encounter     => 7,
            max_units_allowed_per_day           => 8,
        }],
    );
    is( scalar keys %{ $CLASS->charge_codes_by_insurer( 1013, 'only' )}, 15 );

    # make it 'unnacceptable'
    ok( $CLASS->insurer_charge_code_save( 1013, 1001, {
        acceptable                          => 0,
        dollars_per_unit                    => 678.90,
        max_units_allowed_per_encounter     => 7,
        max_units_allowed_per_day           => 8,
    }));
    is_deeply_except({ rec_id => undef, rolodex_id => undef },
        [ $CLASS->charge_codes_by_insurer( 1013, 'only' )->{ 1001 }],
        [{
            valid_data_charge_code_id           => 1001,
            acceptable                          => 0,
            dollars_per_unit                    => undef,
            max_units_allowed_per_encounter     => undef,
            max_units_allowed_per_day           => undef,
        }],
    );
    is( scalar keys %{ $CLASS->charge_codes_by_insurer( 1013, 'only' )}, 15 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# writer codes
    can_ok( $one, qw/ writer_codes / );

        delete $one->{ staff_id };
    is( $one->writer_codes, undef );

        $one->staff_id( 1 );
    is( $one->writer_codes, undef );

        $one->staff_id( 1001 );
    is_deeply([ $one->writer_codes ], [ [ sort $one->unique(
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1002 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
        )],
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
    ]);
    is_deeply([ $one->writer_codes ], [
        [ qw/
            1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
        /],
        [ qw/
            1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
        /]
    ]);

        $one->staff_id( 1002 );
    is_deeply([ $one->writer_codes ], [ [ sort $one->unique(
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1003 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
        )],
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
    ]);
    is_deeply([ $one->writer_codes ], [
        [ qw/
            1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1022 1023 1025 1026 1027 1028 1029 1030 1033 1034
        /],
        [ qw/
            1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
        /]
    ]);

        $one->staff_id( 1003 );
    is_deeply([ $one->writer_codes ], [
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
    ]);
    is_deeply([ $one->writer_codes ], [
        [ qw/
            1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
        /],
        [ qw/
            1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
        /]
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# location codes
    can_ok( $one, qw/ location_codes / );

        $one->prognote_location_id( 1001 );
    is( $one->location_codes, undef );

        $one->prognote_location_id( 1002 );
    is_deeply( $one->location_codes, [ sort $one->unique(
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1003 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1005 })->members,
    )]);
    is_deeply( $one->location_codes, [ qw/
        1007 1008 1009 1010 1011 1012 1013 1014 1022 1023 1024 1029 1030 1031 1032 1033 1034
    /]);

        $one->prognote_location_id( 1003 );
    is_deeply( $one->location_codes, [ sort $one->unique(
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1004 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1005 })->members,
    )]);
    is_deeply( $one->location_codes, [ qw/
        1001 1002 1003 1004 1005 1006 1015 1016 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
    /]);

        $one->prognote_location_id( 1004 );
    is_deeply( $one->location_codes, [ sort $one->unique(
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1004 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1006 })->members,
    )]);
    is_deeply( $one->location_codes, [ qw/
        1001 1002 1017 1018 1019 1020 1021 1022 1027 1028
    /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# program codes failures
    can_ok( $one, qw/ program_codes / );
        undef $one->{ client_id };
        undef $one->{ note_date };
    is( $one->program_codes, undef );

        $one->note_date( '2005-05-01' );
    is( $one->program_codes, undef );

        $one->client_id( 1001 );
        undef $one->{ note_date };
    is( $one->program_codes, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# program codes successes, per program
        $one->note_date( '2005-05-01' );
        $one->client_id( 1001 );
    is_deeply( $one->program_codes( 1 ), [ qw/
        1001 1002 1003 1004 1005 1006 1015 1016 1017 1018 1019 1020 1021 1022 1025 1026 1027 1028 1029 1030 1033 1034
    /]);

    is( $one->program_codes( 1001 ), undef );

    is_deeply( $one->program_codes( 1002 ), [ qw/
        1001 1002 1003 1004 1005 1006 1015 1016 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
    /]);

    is_deeply( $one->program_codes( 1003 ), [ qw/
        1001 1002 1003 1004 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1017 1018 1019 1020 1021 1022 1023 1024 1027 1028 1029 1030 1031 1032 1033 1034
    /]);

    is_deeply( $one->program_codes( 1004 ), [ qw/
        1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
    /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# program id
        $one = $CLASS->new;
    is( $one->get_program_id, undef );

        $one->client_id( 1001 );
    is( $one->get_program_id, undef );
        $one->client_id( 1002 );
    is( $one->get_program_id, undef );
        $one->client_id( 1003 );
    is( $one->get_program_id, undef );
        $one->client_id( 1004 );
    is( $one->get_program_id, undef );
        $one->client_id( 1005 );
    is( $one->get_program_id, undef );
        $one->client_id( 1006 );
    is( $one->get_program_id, undef );

        $one->note_date( '2006-04-15' );
        $one->client_id( 1001 );
    is( $one->get_program_id, undef );
        $one->client_id( 1002 );
    is( $one->get_program_id, undef );
        $one->client_id( 1003 );
    is( $one->get_program_id, 1001 );
        $one->client_id( 1004 );
    is( $one->get_program_id, 1001 );
        $one->client_id( 1005 );
    is( $one->get_program_id, 1 );
        $one->client_id( 1006 );
    is( $one->get_program_id, 1004 );

    my @dates = ( '2000-01-01', '2005-05-03', '2005-05-04', '2006-01-01', '2006-03-14', '2006-03-15', '2006-03-16' );
    for( @dates ) {
            $one->client_id( 1001 );
            $one->note_date( $_ );
            my $event = eleMentalClinic::Client::Placement::Event->get_by_client( $one->client_id, $one->note_date ) || {};
        is( $event->{ program_id }, $one->get_program_id );
    }

    @dates = ( '2000-01-01', '2005-02-28', '2005-03-01', '2005-03-16', '2005-03-17', '2005-03-18', '2005-03-24', '2005-03-25', '2005-04-01', '2005-05-01' );
    for( @dates ) {
            $one->client_id( 1003 );
            $one->note_date( $_ );
            my $event = eleMentalClinic::Client::Placement::Event->get_by_client( $one->client_id, $one->note_date ) || {};
        is( $event->{ program_id }, $one->get_program_id );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# program codes successes, program from internal data
        $one->note_date( '2006-04-15' );

        $one->client_id( 1001 );
    is( $one->get_program_id, undef );
    is( $one->program_codes, undef );

        $one->client_id( 1002 );
    is( $one->get_program_id, undef );
    is( $one->program_codes, undef );

        $one->client_id( 1003 );
    is( $one->get_program_id, 1001 );
    is( $one->program_codes, undef );

        $one->client_id( 1004 );
    is( $one->get_program_id, 1001 );
    is( $one->program_codes, undef );

        $one->client_id( 1005 );
    is( $one->get_program_id, 1 );
    is_deeply( $one->program_codes, [ sort $one->unique(
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1004 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1006 })->members,
    )]);

        $one->client_id( 1006 );
    is( $one->get_program_id, 1004 );
    is_deeply( $one->program_codes, [ sort $one->unique(
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1002 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1003 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1004 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1005 })->members,
    )]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# program codes successes, program potentially in the past
        $one->client_id( 1003 );

        $one->note_date( '2005-03-17' );
    is( $one->get_program_id, 1002 );
    is_deeply( $one->program_codes, [ sort $one->unique(
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1004 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1005 })->members,
    )]);

        $one->note_date( '2005-03-31' );
    is( $one->get_program_id, 1001 );
    is_deeply( $one->program_codes, undef );

        $one->note_date( '2005-04-01' );
    is( $one->get_program_id, 1001 );
    is_deeply( $one->program_codes, undef );

    # program id 1
        $one->client_id( 1005 );
        $one->note_date( '2005-05-25' );
    is( $one->get_program_id, 1 );
    is_deeply( $one->program_codes, [ sort $one->unique(
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1001 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1004 })->members,
        eleMentalClinic::Lookup::Group->new( $lookup_groups->{ 1006 })->members,
    )]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# all code ids
    can_ok( $one, qw/ all_charge_code_ids / );
    is_deeply([ sort @{ $one->all_charge_code_ids }],
        [ 1, ( sort keys %{ $valid_data_charge_code }), 2, 3 ]
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# actual codes
    can_ok( $one, qw/ valid_charge_codes /);

    is_deeply( $one->valid_charge_codes([ 1001 ]), [
        $valid_data_charge_code->{ 1001 },
    ]);
    is_deeply( $one->valid_charge_codes([ 1001, 1002, 1003, 1004, 1005 ]), [
        $valid_data_charge_code->{ 1001 },
        $valid_data_charge_code->{ 1002 },
        $valid_data_charge_code->{ 1003 },
        $valid_data_charge_code->{ 1004 },
        $valid_data_charge_code->{ 1005 },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test data serialized for reference for next tests

=begin

test data for reference:
groups
    1001:
        1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
    1002:
        1001 1002 1003 1004 1015 1016 1029 1030 1031 1032
    1003:
        1007 1008 1009 1010 1011 1012 1013 1014 1022 1023 1033 1034
    1004:
        1001 1002 1021 1022 1027 1028
    1005:
        1023 1024 1029 1030 1031 1032 1033 1034
    1006:
        1017 1018 1019 1020

staff
    1   : x
    1001: ( 1001, 1002 ), 1001
        1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
        , 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
    1002: ( 1001, 1003 ), 1001
        1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1022 1023 1025 1026 1027 1028 1029 1030 1033 1034
        , 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
    1003: 1001, 1001
        1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
        , 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034

locations
    1   : x
    1001: x
    1002: 1003 1005
        1007 1008 1009 1010 1011 1012 1013 1014 1022 1023 1024 1029 1030 1031 1032 1033 1034
    1003: 1001 1004 1005
        1001 1002 1003 1004 1005 1006 1015 1016 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
    1004: 1004 1006
        1001 1002 1017 1018 1019 1020 1021 1022 1027 1028

programs
    1   : 1001 1004 1006
        1001 1002 1003 1004 1005 1006 1015 1016 1017 1018 1019 1020 1021 1022 1025 1026 1027 1028 1029 1030 1033 1034
    1001: x
    1002: 1001 1004 1005
        1001 1002 1003 1004 1005 1006 1015 1016 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
    1003: 1002 1003 1004 1005 1006
        1001 1002 1003 1004 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1017 1018 1019 1020 1021 1022 1023 1024 1027 1028 1029 1030 1031 1032 1033 1034
    1004: 1001 1002 1003 1004 1005
        1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tests current object with all prognote locations
sub test_locations {
    my $cc = shift;
    my( $expect, $debug ) = @_;

    for( sort keys %$expect ) {
        $cc->prognote_location_id( $_ );
        my $codes = $cc->valid_charge_code_ids( $debug );
        is_deeply( $codes, $expect->{ $_ } );
        if( $debug ) {
            diag( '.'x50 );
            print Dumper[ "ID: $_", $codes, $expect->{ $_ } ];
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments which follow accessors which change or test filters
# (i.e. program, staff, location) are codes allowed
# the second line of codes are sticky
# globals are always ( 1, 2 )
    can_ok( $one, qw/ valid_charge_code_ids / );

        $one->note_date( '2005-05-01' );
        $one->client_id( 1001 );
    is( $one->get_program_id, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diag( "program undef, staff 1" );
        $one->staff_id( 1 );
        # x
    test_locations( $one, {
        1001 => [ qw/
            1 2
        /],
        1002 => [ qw/
            1 2
        /],
        1003 => [ qw/
            1 2
        /],
        1004 => [ qw/
            1 2
        /],
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diag( "program undef, staff 1001" );
        $one->staff_id( 1001 );
        # 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
        # , 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
    test_locations( $one, {
        1001 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],   
        1002   => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],   
        1003   => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],   
        1004   => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diag( "program undef, staff 1002" );
        $one->staff_id( 1002 );
        # 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
        # , 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
    test_locations( $one, {
        1001 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],   
        1002   => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],   
        1003   => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],   
        1004   => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diag( "program undef, staff 1003" );
        $one->staff_id( 1003 );
        # 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
        # , 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
        $one->prognote_location_id( 1001 );
        # x
    test_locations( $one, {
        1001 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],   
        1002   => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],   
        1003   => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],   
        1004   => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
    });


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $one->note_date( '2005-05-30' );
        $one->client_id( 1005 );
    is( $one->get_program_id, 1 );
    # 1001 1002 1003 1004 1005 1006 1015 1016 1017 1018 1019 1020 1021 1022 1025 1026 1027 1028 1029 1030 1033 1034

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diag( "program 1, staff 1" );
        $one->staff_id( 1 );
        # x
    test_locations( $one, {
        1001 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1017 1018 1019 1020 1021 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1002 => [ qw/
            1 1022 1029 1030 1033 1034 2
        /],
        1003 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1021 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1004 => [ qw/
            1 1001 1002 1017 1018 1019 1020 1021 1022 1027 1028 2
        /],
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diag( "program 1, staff 1001" );
        $one->staff_id( 1001 );
        # 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
        # , 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
    test_locations( $one, {
        1001 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1002 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1003 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1004 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
    }, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diag( "program 1, staff 1002" );
        $one->staff_id( 1002 );
        # 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034
        # , 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
    test_locations( $one, {
        1001 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1002 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1003 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1004 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# diag( "program 1, staff 1003" );
        $one->staff_id( 1003 );
        # 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
        # , 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034
    test_locations( $one, {
        1001 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1002 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1003 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
        1004 => [ qw/
            1 1001 1002 1003 1004 1005 1006 1015 1016 1022 1025 1026 1027 1028 1029 1030 1033 1034 2
        /],
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# what if we don't have any insurer codes?
        $test->delete_( 'insurance_charge_code_association', '*' );
    is( scalar keys %{ $CLASS->charge_codes_by_insurer( 1003 )}, 39 );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbinit();
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

