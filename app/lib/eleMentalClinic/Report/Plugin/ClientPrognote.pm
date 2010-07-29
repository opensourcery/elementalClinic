# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::ClientPrognote;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;
BEGIN { *_time_unit_calc = eleMentalClinic::Report->can('_time_unit_calc') }

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'client',
    label => 'Progress Notes',
    admin => 0,
    result_isa => Dict[
        data => ArrayRef,
        client => Optional[Str],
        staff  => Optional[Str],
    ],
};

with qw/
    eleMentalClinic::Report::HasClient
    eleMentalClinic::Report::HasPersonnel
    eleMentalClinic::Report::HasDateRange
/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires a hashref with
#   start_date
#   end_date
#   client_id
sub build_result {
    my ($self) = @_;

    my $client_id  = $self->client_id;
    my $staff_id   = $self->staff_id;
    my $start_date = $self->start_date;
    my $end_date   = $self->end_date;

    my $result = { data => [] };

    # XXX return instead of require
    # XXX no good way to represent this for graceful error handling
    return $result unless $client_id or $staff_id or $start_date;
    return $result unless $end_date;

    my $query = qq/
        SELECT
            p.start_date AS date,
            p.data_entry_id AS writer_id,
            cc.name AS code,
            extract (epoch from p.end_date - p.start_date) AS duration,
            l.name AS location,
            g.goal_name AS goal,
            c.lname,
            c.fname,
            p.note_body AS note,
            p.staff_id,
            p.digital_signature,
            groups.name AS group
        FROM
            client c LEFT JOIN prognote p ON c.client_id = p.client_id
            LEFT JOIN valid_data_charge_code cc ON p.charge_code_id = cc.rec_id
            LEFT JOIN valid_data_prognote_location l ON p.note_location_id = l.rec_id
            LEFT JOIN tx_goals g ON p.goal_id = g.rec_id
            LEFT JOIN personnel s ON s.staff_id = p.staff_id
            LEFT JOIN groups ON groups.rec_id = p.group_id
        WHERE
            0 = 0
    /;

    $query .= "AND p.staff_id = $staff_id " if $staff_id;
    $query .= "AND p.client_id = $client_id " if $client_id;

    if( $start_date and $end_date) {
        if( $start_date eq $end_date ){
            $query .= "AND date(p.start_date) = '$start_date' ";
        }
        else {
            $query .= " AND date(p.start_date) >= '$start_date' AND (date(p.end_date) <= '$end_date' OR text(date(p.end_date)) LIKE '\%$end_date%')";
        }
    }
    elsif( $start_date ) {
        $query .= "AND date(p.start_date) >= '$start_date' ";
    }
    else {
        $query .= "AND date(p.start_date) <= '$end_date' ";
    }

    if( $client_id ){
        $query .= "ORDER BY p.start_date DESC";
    }
    else {
        $query .= "ORDER BY c.lname, c.fname, p.start_date DESC";
    }

    my $data_holder = $self->db->do_sql($query);
    return $result unless $data_holder->[0];

    if( $client_id ){
        # if we get a client_id, return an array of hashes
        for( @$data_holder ) {
            my $duration = _time_unit_calc(undef, $_->{duration});
            $_->{date} =~ s/ .*//g;
            push @{ $result->{data} }, {
                duration => $duration,
                date     => $_->{date},
                goal     => $_->{goal},
                location => $_->{location},
                code     => $_->{code},
                note     => $_->{note},
                staff    => eleMentalClinic::Personnel->new({ staff_id => $_->{staff_id} })->retrieve,
                writer   => eleMentalClinic::Personnel->new({ staff_id => $_->{writer_id} })->retrieve,
                client   => $_->{fname} .' '. $_->{lname},
                group    => $_->{group},
                signature => $_->{digital_signature},
            };
        }
    }
    else {
        # if we don't get a client_id, return array of
        # arrays of hashes grouped by client
        my $client = $data_holder->[0]->{fname}
            .' '
            . $data_holder->[0]->{lname};
        my $i = 0;
        for( @$data_holder ){
            my $curr_client = $_->{fname} .' '. $_->{lname};
            $i++ if $client and $client ne $curr_client;
            $client = $curr_client;

            my $duration = _time_unit_calc(undef, $_->{duration});
            $_->{date} =~ s/ .*//g;
            push @{ $result->{data}->[ $i ] }, {
                duration => $duration,
                date     => $_->{date},
                goal     => $_->{goal},
                location => $_->{location},
                code     => $_->{code},
                note     => $_->{note},
                staff    => eleMentalClinic::Personnel->retrieve( $_->{staff_id} ),
                writer   => eleMentalClinic::Personnel->retrieve( $_->{writer_id} ),
                client   => $curr_client,
                group    => $_->{group},
                signature => $_->{digital_signature},
            };
        }
    }

    $result->{staff} = $self->personnel->name
        if $self->staff_id;

    $result->{client} = $self->client->name
        if $self->client_id;

    return $result;
}


__PACKAGE__->meta->make_immutable;
1;
