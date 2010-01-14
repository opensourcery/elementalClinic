# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::MonthlyStatus;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use POSIX qw(strftime);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type       => 'site',
    label      => 'Monthly Status Report',
    admin      => 0,
    result_isa => Dict [
        total_active_clients => Int,
        hospitalizations     => ArrayRef,
        terminations         => ArrayRef,
        intakes              => ArrayRef,
        program_totals       => ArrayRef [
            Dict [
                count => Int,
                name  => Str
            ],
        ],
    ],
};

has date => (
    is => 'ro',
    isa => Str,
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# takes an optional date
#   YYYY-MM, or
#   YYYY-MM-DD
# returns
#{
#  total_active_clients => '253',
#  program_totals => [
#    {
#      count => '66',
#      name => 'Beaverton CSS'
#    },
#    ...
#  ],
#}
#
sub build_result {
    my ($self) = @_;

    my $date = $self->date || strftime("%Y-%m", localtime);
    my %result = (
        hospitalizations => [],
        terminations => [],
        intakes => [],
    );
    my @client_ids;

    if( $date =~ m/\d\d\d\d-\d+-\d+/ ) {
        # date is passed with day
        # get rid of day
        $date =~ s/-\d+$//g;
    }

    # FIXME unbreak this nasty date.
    if( $date =~ m/(\d{4})-(\d)-*$/ ){
        $date = "$1-0$2";
    }

    # intakes this month
    my $intakes = $self->db->select_many(
        ['cpe.client_id', 'cpe.event_date', 'cpe.input_date', 'cpe.rec_id', 'ci.staff_id'], #'cpe.input_by_staff_id'],
        'client_placement_event cpe, client_intake ci, client c',
        "WHERE cpe.client_id = c.client_id AND cpe.event_date::text LIKE '$date%' AND cpe.intake_id = ci.rec_id",
        'ORDER BY cpe.event_date, lname, fname'
    );
    for( @$intakes ){
        my $intake = {
            client => eleMentalClinic::Client->new({ client_id => $_->{ client_id } })->retrieve,
            input_by => eleMentalClinic::Personnel->new({ staff_id => $_->{ staff_id } })->retrieve->eman,
            input_date => $_->{ input_date },
        };
        my $referral = eleMentalClinic::Client::Referral->get_by_placement_event_id( $_->{ rec_id } );
        my $episode = eleMentalClinic::Client::Placement::Episode->get_by_client( $_->{ client_id }, $_->{ event_date } );
        $intake->{ admit_date } = $episode->admit_date;
        $intake->{ referral } = $referral;
        $intake->{ referral_date } = $episode->referral_date;
        push @{$result{ intakes }} => $intake;
    }

    # terminations this month
    my $where = qq/ WHERE cd.client_id = c.client_id
                      AND cd.client_placement_event_id = cpe.rec_id
                      AND cpe.event_date::text LIKE '$date%'
                  /;
    my $terminations = $self->db->select_many(
        ['cd.client_id', 'cpe.event_date', 'cd.termination_reason'],
        'client_discharge cd, client_placement_event cpe, client c',
        $where,
        'ORDER BY cpe.event_date, lname, fname'
    );

    for( @$terminations ){
        # intake_date: first entered system. admit_date: placed in a program (non referral). input_date: data entry date.
        my $admit_date = eleMentalClinic::Client::Placement->new({ client_id => $_->{ client_id }, date => $_->{ event_date } })->admit_date;
        my $intake_date = eleMentalClinic::Client::Placement->new({ client_id => $_->{ client_id }, date => $_->{ event_date } })->intake_date;
        my $input_date = eleMentalClinic::Client::Placement->new({ client_id => $_->{ client_id }, date => $intake_date })->input_date;
        push @{$result{ terminations }} => {
            client => eleMentalClinic::Client->new({ client_id => $_->{ client_id } })->retrieve,
            event_date => $_->{ event_date },
            termination_reason => $_->{ termination_reason },
            input_date => $input_date,
            admit_date => $admit_date || '',
        };
    }

    # hospitalizations this month
    my $data_holder = ($self->db->select_many(
        ['c.client_id', 'ci.rec_id'],
        'client_inpatient ci, client c',
        "WHERE ci.start_date::text LIKE '$date%' and c.client_id = ci.client_id",
        'ORDER BY c.lname, c.fname'
    ));

    if( $data_holder ) {
        push @{$result{ hospitalizations }}, {
            client => eleMentalClinic::Client->new({ client_id => $_->{ client_id } })->retrieve,
            inpatient => eleMentalClinic::Client::Inpatient->new({ rec_id => $_->{ rec_id } })->retrieve,
        } for @$data_holder[0];
    }

    # total active clients this month
    # - cpe.event_date is either before the date chosen, or it's in the month chosen
    # NOTE: this is $self->date, which *must* be a day, not $date, which *must*
    # be a month
    my $specific_date = $self->db->dbh->quote( $self->date );
    $where = qq/
        cpe.program_id IS NOT NULL
        AND cpe.rec_id IN (
            SELECT DISTINCT ON ( client_id )
                rec_id
                FROM client_placement_event
                WHERE event_date <= $specific_date OR event_date::text LIKE '$date%'
                ORDER BY client_id ASC, event_date DESC, rec_id DESC
            )
    /;

    $result{ total_active_clients } = $self->db->select_one(
        ['count(*)'],
        'client_placement_event cpe',
        $where
    )->{ count };

    # program totals this month
    $where = qq/
        WHERE p.rec_id = cpe.program_id
          AND cpe.rec_id IN (
            SELECT DISTINCT ON ( client_id )
                rec_id
                FROM client_placement_event
                WHERE event_date <= $specific_date OR event_date::text LIKE '$date%'
                ORDER BY client_id ASC, event_date DESC, rec_id DESC
            )
    /;

    $result{ program_totals } = $self->db->select_many(
        ['p.name', 'count(*)'],
        'client_placement_event cpe, valid_data_program p',
        $where,
        'GROUP BY cpe.program_id, p.name ORDER BY p.name'
    ) || [];

    return \%result;
}


__PACKAGE__->meta->make_immutable;
1;
