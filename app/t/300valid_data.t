# Copyright (C) 2005-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 336;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, @table_list, $table_names, $count);
BEGIN {
    *CLASS = \'eleMentalClinic::ValidData';
    use_ok( $CLASS );
}

$test->db_refresh;

$test->insert_data;

# for some reason, putting this in the begin block
# triggers a warning in Config.pm
push @table_list, $_->{ name }
    for @{ $test->db->do_sql( 'SELECT name FROM valid_data_valid_data ORDER BY name' ) };

$table_names = undef;
for( @table_list ){
    $_ =~ m/^valid_data(.*)$/ ;
    push @$table_names, {
        abbr => $1,
        full => $_,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
     ok( $one = $CLASS->new({ dept_id => 1001 }) );
     ok( defined( $one ));
     ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 'table' info
    is( $one->table, '');
    is( $one->primary_key, 'rec_id');
    is( $one->fields, undef );
    is_deeply( $one->methods, [qw/ dept_id tables /] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# methods that were being overwritten for no discernable reason
    can_ok( $one, 'db' );
    can_ok( $one, 'config' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# init
    can_ok( $one, 'init' );

        #new calls init
        eval{ $one->new }; 
    like( $@, qr/Department ID \(dept_id\) is required/ );

    ok( $one->new({ dept_id => 6666 }) );
    is_deeply( $one->tables, $one->list( 'valid_data_valid_data' ) );

    ok( $one->new({ dept_id => 1001 }) );
    is_deeply( $one->tables, $one->list( 'valid_data_valid_data' ) );

        $one->new({ dept_id => 1001 });
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# table_names
    can_ok( $one, 'table_names' );

    is_deeply( $one->table_names, \@table_list );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list
    can_ok( $one, 'list' );

    is( $one->list, undef );
    is( $one->list( 'foo' ), undef );

        $tmp = $test->db->do_sql(qq/
            SELECT rec_id, dept_id, name, description, active FROM valid_data_valid_data ORDER BY name
        /);
    is_deeply( $one->list( 'valid_data_valid_data' ), $tmp );

    is_deeply( $one->list( $_->{ abbr } ), $test->db->select_many( 
                $one->column_names( $_->{ full } ),
                $_->{ full },
                '',
                'ORDER BY name',
             ) )
        for( @$table_names );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# list_names
    can_ok( $one, 'list_names' );

    is( $one->list_names, undef );
    is( $one->list_names( 'foo' ), undef );

        
    is_deeply( $one->list_names( 'valid_data_valid_data' ), \@table_list );

    is_deeply( $one->list_names( $_->{ abbr } ), $test->db->select_many_arrayref(
            [ 'name' ],
            $_->{ full },
            '',
            'ORDER BY name',
           ) )
        for( @$table_names );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get
    can_ok( $one, 'get' );

    is( $one->get, undef );
    is( $one->get( '_sex' ), undef );
    is( $one->get( undef, 1001 ), undef );

    is( $one->get( '_foo', 6666 ), undef );
    is( $one->get( '_foo', 1001 ), undef );

    is_deeply( $one->get( '_program', 1001 ), $valid_data_program->{ 1001 } );
    is_deeply( $one->get( 'valid_data_program', 1001 ), $valid_data_program->{ 1001 } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_name
# wrapper
    can_ok( $one, 'get_name' );

    is( $one->get_name( '_program', 1001 ), $valid_data_program->{ 1001 }->{ name } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_desc
# wrapper
    can_ok( $one, 'get_desc' );

    is( $one->get_desc( '_program', 1001 ), $valid_data_program->{ 1001 }->{ description } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# save
    can_ok( $one, 'save' );

        $tmp = {
            name => 'foo',
            visit_frequency => 5,
            visit_interval => 'month',
        };
    is( $one->save, undef );
    is( $one->save( '_sex' ), undef );
    is( $one->save( undef, $tmp ), undef );

    # insert
        $count = $test->select_count( 'valid_data_level_of_care' );
    is_deeply( $tmp, $one->save( '_level_of_care', $tmp ) );
        $count++;
    is( $test->select_count( 'valid_data_level_of_care' ), $count );
    ok( $tmp->{ rec_id } );

    # update without active
        $tmp->{ description } = "this contains\na newline\r";
        delete $tmp->{ active };
    is_deeply( $tmp, $one->save( '_level_of_care', $tmp ) );
    is( $test->select_count( 'valid_data_level_of_care' ), $count );
    is( $tmp->{ description }, "this contains\\na newline" );
    is( $tmp->{ active }, 0 );

    # update with active
        $tmp->{ active } = 1;
    is_deeply( $tmp, $one->save( '_level_of_care', $tmp ) );
    is( $test->select_count( 'valid_data_level_of_care' ), $count );
    is( $tmp->{ description }, "this contains\\na newline" );
    is( $tmp->{ active }, 1 );

    # update without extra columns
        $tmp->{ visit_frequency } = undef;
        $tmp->{ visit_interval } = undef;
    is_deeply( $tmp, $one->save( '_level_of_care', $tmp ) );
    is( $test->select_count( 'valid_data_level_of_care' ), $count );
    is( $tmp->{ visit_frequency }, undef );

    # clean up
        $test->db->do_sql(qq/
            DELETE FROM valid_data_level_of_care WHERE rec_id BETWEEN 2 and 1000
        /, 1);
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# is_table
    can_ok( $one, 'is_table' );

    is( $one->is_table, undef );

    is( $one->is_table( 'foo' ), undef );
    is( $one->is_table( '_foo' ), undef );
    is( $one->is_table( 'valid_data_foo' ), undef );

    is( $one->is_table( $_ ), $_ )
        for @table_list;

    is( $one->is_table( $_->{ abbr } ), $_->{ full } )
        for @$table_names;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_table
    can_ok( $one, 'get_table' );

    is( $one->get_table, undef );

    is( $one->get_table( 'foo' ), undef );

        $one->dept_id( 6666 );
    is( $one->get_table( '_sex' ), undef );

        $one->dept_id( 1001 );
    
    is_deeply( $one->get_table( $_->{ abbr } ), $test->db->do_sql(qq/
                SELECT rec_id, dept_id, name, description, readonly, extra_columns 
                FROM valid_data_valid_data WHERE name = '$_->{ full }'
                /)->[0] )
        for @$table_names;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_byname
    can_ok( $one, 'get_byname' );

    is( $one->get_byname, undef );
    is( $one->get_byname( '_program' ), undef );
    is( $one->get_byname( undef, $valid_data_program->{ 1001 }->{ name } ), undef );

    is( $one->get_byname( '_foo', $valid_data_program->{ 1001 }->{ name } ), undef );

    is( $one->get_byname( '_program', 'foo' ), undef );

    is_deeply( $one->get_byname( '_program', $valid_data_program->{ 1001 }->{ name } ), $valid_data_program->{ 1001 } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_name_desc_list
    can_ok( $one, 'get_name_desc_list' );

    is( $one->get_name_desc_list, undef );
    is( $one->get_name_desc_list( '_claim_adjustment_codes' )->[0]->{ name_desc }, '1: Deductible Amount' );
    is( $one->get_name_desc_list( '_claim_adjustment_codes' )->[1]->{ name_desc }, '2: Coinsurance Amount' );
    is( $one->get_name_desc_list( '_claim_adjustment_codes' )->[2]->{ name_desc }, '3: Co-payment Amount' );
 
        my %exceptions = ( name_desc => undef );
        $tmp = $one->list( '_claim_adjustment_codes' );
        @$tmp = sort { $a->{ rec_id } <=> $b->{ rec_id } } @$tmp;
    is_deeply_except( \%exceptions, $one->get_name_desc_list( '_claim_adjustment_codes' ), $tmp );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        $test->db_refresh;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#has_default

ok( $one->has_default( 'valid_data_race' ), "Race has default functionality");
ok( $one->has_default( 'valid_data_nationality' ), "nationality has default functionality");
is( $one->has_default( 'valid_data_valid_data' ), undef, "No default for valid_data_valid_data");
is( $one->has_default( 'valid_data_sex' ), undef, 'No default functionality for sex');

#get_default
is( $one->get_default( '_nationality' ), 'United States of America', "Can obtain default by name" );
is( $one->get_default( '_nationality', 1 ), 184, "Can obtain default by id" );

#column_names on default columns
is_deeply( 
    [ grep { m/is_default/ } @{ $one->column_names( 'valid_data_nationality' )} ],
    [ 'is_default' ],
    "is_default shows up in column list",
);

$test->db_refresh;
$test->insert_( 'valid_data_race' );

# copy_and_save
my $item = { %{$valid_data_race->{1}} };
my $s = sub { $one->copy_and_save( '_race', @_ ) };
is_deeply(
    $s->($item),
    $item,
    "no change means no change",
);

is_deeply(
    $s->({ %$item, active => 0 }),
    { %$item, active => 0 },
    "change to active (only) does not change rec_id",
);

my $new = $s->({ %$item, description => "A gingerbread house" });
isnt( $new->{rec_id}, $item->{rec_id},
    "changing something other than 'active' causes a rec_id change" );

is(
    $one->get( '_race', $item->{rec_id} )->{active},
    0,
    "old rec_id is now inactive",
);

# 
