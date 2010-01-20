# vim: ts=4 sts=4 sw=4
use strict;
use warnings;
use Test::More 'no_plan';
use Class::MOP;
use eleMentalClinic::Test;
my $class = 'eleMentalClinic::Controller::Base::Schedule';
Class::MOP::load_class($class);
use Object::Quick 'obj';

sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

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


is( $controller->open_schedule, $controller->config->Theme->open_schedule, "Returns theme openness" );

my $scheduler = eleMentalClinic::Personnel->new({ fname => 'bob', lname => 'marley' });
my $treater = eleMentalClinic::Personnel->new({ fname => 'fred', lname => 'marley' });
my $user = eleMentalClinic::Personnel->new({ fname => 'ted', lname => 'marley' });
for( $scheduler, $treater, $user ) {
    $_->unit_id( 1001 );
    $_->dept_id( 1001 );
    $_->save;
}

for my $rname ( 'active', 'all clients', 'writer' ) {
    my $role = eleMentalClinic::Role->get_one_by_( name => $rname );
    $role->add_member( $_->primary_role ) for $scheduler, $treater, $user;
}

eleMentalClinic::Role->get_one_by_( 'name', 'scheduler' )->add_member( $scheduler->primary_role );
$treater->rolodex_treaters_id( 1002 );
$treater->password_set( '2008-10-10 00:00:00' );
$treater->save;

my @appointments = (
    '08:00a',
    obj( id => 1, client_id => 1001, schedule_availability => obj( rolodex_id => 1001 )),
    obj( id => 2, client_id => 1001, schedule_availability => obj( rolodex_id => 1002 )),
    obj( id => 3, client_id => 1002, schedule_availability => obj( rolodex_id => 1002 )),
    obj( id => 4, client_id => 1001, schedule_availability => obj( rolodex_id => 1001 )),
    obj( id => 5, client_id => 1002, schedule_availability => obj( rolodex_id => 1001 )),
    obj( id => 6, client_id => 1003, schedule_availability => obj( rolodex_id => 1001 )),
    obj( id => 7, client_id => 1004, schedule_availability => obj( rolodex_id => 1003 )),
    obj( id => 8, client_id => 1005, schedule_availability => obj( rolodex_id => 1001 )),
    '08:00p'
);

my $one = $class->new_with_cgi_params( client_id => 1001 );
$one->current_user( $scheduler );
is_deeply(
    $one->treaters,
    eleMentalClinic::Rolodex->new->get_byrole( 'treaters' ),
    "Treaters for scheduler"
);

my $appointments = [ @appointments ];
$one->filter_appointments( $appointments, { withclient => 'no' });
is_deeply(
    [ map { ref( $_ ) ? $_->id : $_ } @$appointments ],
    [ '08:00a', 1 .. 8, '08:00p' ],
    "Got all appointments for scheduler"
);
$appointments = [ @appointments ];
$one->filter_appointments( $appointments, { withclient => 'yes' });
is_deeply(
    [ map { ref( $_ ) ? $_->id : $_ } @$appointments ],
    [ '08:00a', 1, 2, 4, '08:00p' ],
    "Got only appointments for this client"
);


$one = $class->new_with_cgi_params( client_id => 1001 );
$one->current_user( $treater );
is_deeply(
    $one->treaters,
    $treater->treater->rolodex,
    "Treaters for treater"
);
$appointments = [ @appointments ];
$one->filter_appointments( $appointments, { withclient => 'no' });
is_deeply(
    [ map { ref( $_ ) ? $_->id : $_ } @$appointments ],
    [ '08:00a', 1, 4, 5, 6, 8, '08:00p' ],
    "Got only treater appointments"
);
$appointments = [ @appointments ];
$one->filter_appointments( $appointments, { withclient => 'yes' });
is_deeply(
    [ map { ref( $_ ) ? $_->id : $_ } @$appointments ],
    [ '08:00a', 1, 2, 4, '08:00p' ],
    "Got only appointments for this client"
);

$one = $class->new_with_cgi_params( client_id => 1001 );
$one->current_user( $user );
is_deeply(
    $one->treaters,
    [],
    "Treaters for user"
);
$appointments = [ @appointments ];
$one->filter_appointments( $appointments, { withclient => 'no' });
is_deeply(
    [ map { ref( $_ ) ? $_->id : $_ } @$appointments ],
    [  ],
    "Got no appointments"
);
$appointments = [ @appointments ];
$one->filter_appointments( $appointments, { withclient => 'yes' });
is_deeply(
    [ map { ref( $_ ) ? $_->id : $_ } @$appointments ],
    [ '08:00a', 1, 2, 4, '08:00p' ],
    "Got only appointments for this client"
);


$one = $class->new;
ok( !$one->override_template_name, "No override" );
is_deeply( $one->no_schedule, {}, "No params" );
is( $one->override_template_name, 'no_schedule', "Override template" );
