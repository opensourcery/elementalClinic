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

__END__

sub no_schedule {
    my $self = shift;
    $self->override_template_name( 'no_schedule' );
    return { }
}

sub home {
    my $self = shift;

    my $current = $self->current;
    $current->{withclient} ||= 'yes' if $current->{client_id};
    $self->_update_from_session( @calendar_controls, 'schedule_availability_id', 'withclient' );

    # If we are not a treater, and do not have the scheduler role then we have
    # no schedule to show, except when viewing a client schedule.
    return $self->no_schedule
        if !$self->open_schedule
           && !$self->current_user->has_schedule
           && (!$current->{withclient} || $current->{withclient} eq 'no');

    # For viewing the schedule without an associated client
    $self->template->vars({ client => eleMentalClinic::Client->new })
        if $current->{withclient} && $current->{withclient} eq 'no';

    unless ( $self->quick ) {
        if ( $self->_changed( 'schedule_availability_id' ) ) {
            # schedule_availability_id has changed since last call
            # so reset calendar controls to match
            $self->_set_calendar_controls;
        } elsif ( $self->_changed( @calendar_controls ) ) {
            # otherwise, if calendar controls have changed since 
            # last call, then reset the schedule_availability_id
            $self->_set_schedule_availability_control;
        }
    }

    my $schedule_date = $self->quick ? $self->current_date : $self->availability_date;
    # this schedule is only used for building appointments
    my $Schedule = eleMentalClinic::Schedule->new({
        year        => $schedule_date->{year},
        month       => $schedule_date->{month},
        rolodex_id  => $self->quick ? 0 : $current->{rolodex_id}  || 0,
        location_id => $self->quick ? 0 : $current->{location_id} || 0,
    });

    my $scheduled_days = $Schedule->days;

    # XXX guessing that 15 minute schedules will always be OK; this should
    # probably be configurable somehow, but we don't yet know how.
    my $default_quick_slots = $Schedule->build_appointment_slots( 15 );

    # Only generate an appointments list if this day is available for scheduling
    my $appointments = $Schedule->appointment_slots_filled(
        $schedule_date->{day},
        $self->quick && $default_quick_slots,
    ) if $scheduled_days->{ $schedule_date->{day} * 1 };

    $appointments ||= $default_quick_slots if $self->quick;

    # Save control data to session
    $self->_save_to_session(
        @calendar_controls,
        'schedule_availability_id',
        'withclient',
    );

    $self->filter_appointments( $appointments, $current );


    $self->template->process_page( 'schedule/home', {
        %$current,        
        rolodex         => $self->_get_rolodex || 0,
        treaters        => $self->treaters,
        available_schedules => eleMentalClinic::Schedule->available_schedules(
            $self->open_schedule ? ()
                                 : $self->current_user
        ) || 0,
        appointments    => $appointments || 0,
        schedule_availability   => $Schedule->schedule_availability( $schedule_date->{day} ) || 0,
        # date is the date of the current availability OR the
        # currently selected calendar date, whichever is appropriate given
        # $self->quick; it's the date to schedule a new appointment for
        date            => $self->format_date( $schedule_date ),
        # current_date is ALWAYS the currently selected calendar date, regardless of
        # whether or not there is quick scheduling enabled/an availability
        # selected
        current_date    => $self->format_date( $self->current_date ),
        navpage => 'calendar',
        current_user => $self->current_user,
        open_schedule => $self->open_schedule,
    });
}

sub _appointment_edit {
    my $self = shift;
    my( $return_script ) = @_;
    
    $self->ajax( 1 );
    return 'Appointment not found'
        unless my $appointment = $self->_get_appointment;

    my $schedule_availability = $appointment->schedule_availability;

    $self->template->process_page( 'schedule/popup/appointment', {
        available_schedules => eleMentalClinic::Schedule->available_schedules(
            $self->open_schedule ? ()
                                 : $self->current_user
        ) || 0,
        appointment_times   => $schedule_availability->get_appointment_slots_tallied || 0,
        $return_script ? ( return_script => $return_script ) : (),
        ajax        => 1,
        appointment => $appointment,
        prefix      => "edit_",
        treaters    => $self->treaters,
        # default to 'no' because it will have been set to 'yes' by loading the
        # schedule page, just previously, if there was a client selected
        withclient  => $self->session->param('withclient') || 'no',
        open_schedule => $self->open_schedule,
    });
}
