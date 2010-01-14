# vim: ts=4 sts=4 sw=4
use strict;
use warnings;
use Test::More 'no_plan';
use Class::MOP;
my $class = 'eleMentalClinic::Controller::Base::Schedule';
Class::MOP::load_class($class);

my $controller = $class->new_with_cgi_params(
    op   => 'calendar',
    date => '2009-03-29',
);

# should this be a public method?
my $calendar = $controller->_build_calendar;
is_deeply(
    $calendar->date_calc('-1m'),
    {
        year  => 2009,
        month => 2,
        date  => 28,
        day   => 28,
        Month => 'February',
    },
    'linking backwards to February',
);
