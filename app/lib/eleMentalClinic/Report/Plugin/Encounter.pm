# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Encounter;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Encounter Hours',
    admin => 0,
    result_isa => Dict[
        total => Maybe[Str],
        data  => ArrayRef[
            Dict[
                code => Maybe[Str],
                data => ArrayRef[
                    Dict[
                        start_date => Maybe[Str],
                        duration   => Maybe[Str],
                        writer     => Maybe[Str],
                    ],
                ],
                total => Maybe[Str],
            ],
        ],
    ],
};

with 'eleMentalClinic::Report::HasDateRange' => { required => 1 };

has writer => (is => 'ro', isa => Str, required => 1);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires a hashref with keys
#   start_date
#   end_date
# returns
# {
#    data => [
#        {
#            code => 90802,
#            data => [
#                {
#                    start_date => '2004-02-02',
#                    duration => '04:15',
#                    writer => 'Jacki Lenox',
#                },
#            ],
#            total => '04:15',
#        },
#        {
#            code => '90847-HK',
#            data => [
#                {
#                    start_date => '2004-02-03',
#                    duration => '00:45',
#                    writer => 'Jacki Lenox',
#                },
#                {
#                    start_date => '2004-02-04',
#                    duration => '01:15',
#                    writer => 'Jacki Lenox',
#                },
#            ],
#            total => '02:00',
#        },
#    ],
#    total => '06:15'
#  }
#}
sub build_result {
    my ($self) = @_;

    my $empty = { data => [], total => '0:00' };

    my $start_date = $self->start_date;
    my $end_date   = $self->end_date;
    my $writer     = $self->writer;

    return $empty unless my $data_holder = $self->db->do_sql(qq/
        SELECT
            vdcc.name AS billing_code,
            extract (epoch from p.end_date - p.start_date) AS duration,
            p.start_date,
            p.end_date,
            p.writer,
            p.rec_id
        FROM
        valid_data_charge_code vdcc, prognote p
        WHERE
            vdcc.rec_id = p.charge_code_id
            AND (
                date(p.start_date) BETWEEN '$start_date' AND '$end_date'
                OR date(p.start_date) = '$start_date' )
            AND p.writer = '$writer'
        ORDER BY
            writer, billing_code, start_date
    /);

    my( $result, $grand_total, $last_code, $code_total );
    my $place = 0;

    $result->{data} = [];

    for( @$data_holder ){
        my $code = $_->{ billing_code };
        my $duration = $_->{ duration };

        $result->{data}->[$place] ||= { data => [] };

        if( $last_code and $last_code ne $code ){
            $result->{ data }->[$place]->{total} = $code_total;
            undef $code_total;
            $place++;
        }

        $result->{ data }->[$place]->{ code } = $code;

        push @{$result->{ data }->[$place]->{ data }}, {
            start_date => ($_->{ start_date } =~ m/^(\S+)/)[0],
            duration => _time_unit_calc( undef, $duration ),
            writer => $_->{ writer },
        };

        $code_total = _time_unit_calc( $code_total, $duration );
        $grand_total = _time_unit_calc( $grand_total, $duration );

        $last_code = $code;
    }
    if (@$data_holder) {
        $result->{ data }->[$place]->{total} = $code_total;
    }
    $result->{ total } = $grand_total;

    return $result;
}

__PACKAGE__->meta->make_immutable;
1;
