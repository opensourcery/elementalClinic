# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::EMC;
plan 'no_plan';

use POSIX qw(strftime);

sub schedule_availability_ok {
    my ( $mech, $text ) = @_;
    $text = join ' : ', @$text if ref $text eq 'ARRAY';
    my $select = $mech->tree->look_down(
        _tag => 'select',
        id => 'schedule_availability_id',
    );
    ok(
        grep (
            { $_->as_trimmed_text eq $text }
            $select->look_down(_tag => 'option'),
        ),
        "schedule availability: $text",
    ) or diag join (
        "\n",
        map { $_->as_trimmed_text } $select->look_down(_tag => 'option')
    );
}

sub appointment_ok {
    my ( $mech, $time, $client ) = @_;
    my $name = "$client->{lname}, $client->{fname} $client->{mname}";
    my $tr = $mech->tree->look_down(
        _tag => 'tr', class => "appointment_client_$client->{KEY}",
    );
    ok(
        # exists
        $tr &&
        # correct time
        $tr->look_down(
            _tag => 'td',
            class => 'time',
            sub { shift->as_trimmed_text eq "$time:" },
        ) &&
        # correct name
        $tr->look_down(
            _tag => 'td',
            class => 'client',
            sub { shift->as_trimmed_text eq $name }
        ),
        "appointment for $name at $time",
    );
}

test sub {
    my $self = shift;

    args [
       $self->fixture->find_one(client => { lname => 'Davis' }),
       $self->fixture->find_one(rolodex => { lname => 'Batts' }),
       $self->fixture->find_one(
            valid_data_prognote_location => { name => 'Client Home' },
       ),
    ];

    run sub {
        my ( $client, $doctor, $location ) = @_;

        my $mech = $self->mech;

        my $date = strftime('%Y-%m-%d', localtime);
        my $display_date = strftime('%m/%d/%Y', localtime);

        $mech->admin_login_ok;
        $mech->set_configuration({ quick_schedule_availability => 'off' });

        $mech->post_ok(
            $mech->uri_for(
                '/clientoverview.cgi',
            ),
            {
                op => 'home',
                client_id => $client->{KEY},
                view_client => 'View Client',
            },
            'client overview',
        );

        $mech->follow_link_ok({ text => 'Schedule', n => 2 });

        $mech->submit_form_ok(
            {
                form_name => 'schedule_creation_form',
                # these values aren't magical, they're just "pick something"
                fields => {
                    rolodex_id => $doctor->{KEY},
                    location_id => $location->{KEY},
                    date => $date,
                }
            },
            'create doctor schedule',
        );

        schedule_availability_ok(
            $mech,
            [
                $display_date, 
                $location->{name},
                $doctor->{name},
                0
            ],
        );
        TODO: {
            local $TODO = 'Problem with Test::WWW::Mechanize?';
            eval {
                $mech->follow_link_ok(
                    {
                        url_regex => qr/
                            op        = appointment_save .+
                            appt_time = 8:00 .+
                            client_id = $client->{KEY}
                        /x
                    },
                    'save appointment link',
                );
            } || ok( undef, "save appointment link" );
            diag( $@ ) if $@;

            schedule_availability_ok(
                $mech,
                [
                    $display_date, 
                    $location->{name},
                    $doctor->{name},
                    1
                ],
            );

            appointment_ok(
                $mech,
                '8:00 a',
                $client,
            );
        }

    };
};
