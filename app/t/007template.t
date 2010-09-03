# Copyright (C) 2004-2006 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

=pod

Unit tests for eleMentalClinic::Template object.

=cut

use Test::More tests => 57;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Template';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# include path
    is_deeply( $one->template->service->context->config->{ INCLUDE_PATH }, [
        $one->config->themes_dir .'/Local/templates',
        $one->config->themes_dir .'/Default/templates',
    ]);

    $one->config->reload_theme( 'Earth' );

    $one->init_template;
    is_deeply( $one->template->service->context->config->{ INCLUDE_PATH }, [
        $one->config->themes_dir .'/Local/templates',
        $one->config->themes_dir .'/Earth/templates',
        $one->config->themes_dir .'/Default/templates',
    ]);

    ok(
      $one->template->service->context->template( 'Default:global/header.html' ),
      'fetch from Default',
    );

    ok(
      $one->template->service->context->template( 'Base:global/header.html' ),
      'fetch from Base',
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# template toolkit dynamic_date_format_factory
my $date_format = &eleMentalClinic::Template::dynamic_date_format_factory(undef, 'mdy');

    is(&$date_format('2006-01-02'),'01/02/2006');
    is(&$date_format('1993-12-15'),'12/15/1993');
    is(&$date_format('1993-1-1'),'01/01/1993');
    is(&$date_format('foo'),'foo');

$date_format = &eleMentalClinic::Template::dynamic_date_format_factory(undef, 'sql');

    is(&$date_format('2006-01-02'),'2006-01-02');

$date_format = &eleMentalClinic::Template::dynamic_date_format_factory(undef, undef);

    is(&$date_format('2006-01-02'),'2006-01-02');
    is(&$date_format('2006-1-2'), '2006-01-02');


# Time formatting

    is( eleMentalClinic::Template::to_24, undef);
    is( eleMentalClinic::Template::to_24(1, 'a'), 1);
    is( eleMentalClinic::Template::to_24(12, 'a'), 0);
    is( eleMentalClinic::Template::to_24(1, 'p'), 13);
    is( eleMentalClinic::Template::to_24(12, 'p'), 12);
    is( eleMentalClinic::Template::to_24(11, 'p'), 23);
    is( eleMentalClinic::Template::to_24(1, 'am'), 1);
    is( eleMentalClinic::Template::to_24(12, 'am'), 0);
    is( eleMentalClinic::Template::to_24(1, 'pm'), 13);
    is( eleMentalClinic::Template::to_24(12, 'pm'), 12);
    is( eleMentalClinic::Template::to_24(11, 'pm'), 23);

    is( eleMentalClinic::Template::to_12, undef);
    is_deeply( [ eleMentalClinic::Template::to_12(1) ], [ 1, 'a' ]);
    is_deeply( [ eleMentalClinic::Template::to_12(12) ], [ 12, 'p' ]);
    is_deeply( [ eleMentalClinic::Template::to_12(11) ], [ 11, 'a' ]);
    is_deeply( [ eleMentalClinic::Template::to_12(0) ], [ 12, 'a' ]);
    is_deeply( [ eleMentalClinic::Template::to_12(13) ], [ 1, 'p' ]);
    is_deeply( [ eleMentalClinic::Template::to_12(23) ], [ 11, 'p' ]);

    my $time_formatter = &eleMentalClinic::Template::dynamic_time_format_factory;
    is( &$time_formatter, undef);
    is( &$time_formatter('3:44'), '03:44:00' );
    is( &$time_formatter('03:44'), '03:44:00' );
    is( &$time_formatter('03:44:33'), '03:44:33' );
    is( &$time_formatter('3:44:33'), '03:44:33' );
    is( &$time_formatter('3:44 a'), '03:44:00' );
    is( &$time_formatter('3:44 am'), '03:44:00' );
    is( &$time_formatter('3:44 pm'), '15:44:00' );
    is( &$time_formatter('3:44 p'), '15:44:00' );
    is( &$time_formatter('12:00 a'), '00:00:00' );
    is( &$time_formatter('12:00 p'), '12:00:00' );
    is( &$time_formatter('12:00 am'), '00:00:00' );
    is( &$time_formatter('12:00 pm'), '12:00:00' );
    is( &$time_formatter('11:59:59 pm'), '23:59:59' );
    is( &$time_formatter('11:59 am'), '11:59:00' );
    is( &$time_formatter('11:59:59 p'), '23:59:59' );
    is( &$time_formatter('11:59 a'), '11:59:00' );

    $time_formatter = &eleMentalClinic::Template::dynamic_time_format_factory(undef, '12');
    is( &$time_formatter, undef);
    is( &$time_formatter('03:44:00'), '3:44 a');
    is( &$time_formatter('3:44'), '3:44 a');
    is( &$time_formatter('00:59'), '12:59 a');
    is( &$time_formatter('13:00'), '1:00 p');
    is( &$time_formatter('12:15'), '12:15 p');
    is( &$time_formatter('23:59'), '11:59 p'); 
