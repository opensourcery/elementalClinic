# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::EMC;
plan 'no_plan';

use POSIX qw(strftime);

test sub {
    my $self = shift;

    run sub {
        my $mech = $self->mech;

        $mech->admin_login_ok;
        $mech->get_script_ok('clientoverview.cgi' => (client_id => 1001));

        my $date = strftime('%Y-%m-%d', localtime);
        $mech->submit_form_ok(
            {
                form_name => 'client_form',
                fields => {
                    renewal_date => $date,
                    primary_treater_rolodex_id => '1001',
                },
                button => 'op',
            },
        );

        ok(
            $mech->tree->look_down( id => 'notes' )->look_down(
                _tag => 'td',
                sub { shift->as_trimmed_text eq "Batts: renewal date - $date" },
            ),
            'found renewal audit note',
        );

        $mech->submit_form_ok(
            {
                form_name => 'notes_form',
                fields => {
                    note_body => 'no progress has been made',
                },
                button => 'op',
            },
        );

        ok(
            $mech->tree->look_down( id => 'notes' )->look_down(
                _tag => 'tr',
                sub {
                    join(' ',
                        map { $_->as_trimmed_text }
                        shift->look_down(_tag => 'td')
                    ) =~ /
                        Other \s+
                        no \s progress \s has \s been \s made \s+
                        clinic $
                    /x;
                },
            ),
            'found manual prognote',
        );


        # Try deleting a 2nd phone number
        {
            $mech->get_script_ok('clientoverview.cgi' => (client_id => 1001));

            # Give the client a 2nd phone number
            $mech->submit_form_ok({
                form_name => 'client_form',
                fields => {
                    phone_2     => '123-456-7890',
                },
                button => 'op',
            });

            $mech->id_match_ok({ phone_2 => "123-456-7890" });

            # Now take it away
            $mech->submit_form_ok({
                form_name => 'client_form',
                fields => {
                    phone_2       => '',
                },
                button => 'op',
            });

            $mech->id_match_ok({ phone_2 => "" }, "2nd phone can be removed");
        }
    }
};

1;
