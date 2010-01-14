# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::MhTotals;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type       => 'site',
    label      => 'Count of Active Clients By Mental Health Coverage',
    admin      => 0,
    result_isa => ArrayRef [
        Dict [
            count       => Int,
            mh_coverage => Str,
        ],
    ],
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires
#   nothing
# returns
#[
#  {
#    count => '11',
#    mh_coverage => 'Bridges'
#  },
#  ...
#]
sub build_result {
    my ($self) = @_;

    my $where = qq/
        WHERE c.carrier_type = 'mental health'
        AND c.rolodex_insurance_id = mhi.rec_id
        AND mhi.rolodex_id = r.rec_id
        AND cl.client_id = c.client_id
        AND cl.client_id = cpe.client_id
        AND cpe.program_id IS NOT NULL
        AND cpe.rec_id IN (
            SELECT DISTINCT ON ( client_id )
                rec_id
                FROM client_placement_event
                ORDER BY client_id ASC, event_date DESC, rec_id DESC
            )
    /;

    my $result = $self->db->select_many(
        ['r.rec_id', 'count(*) AS count'],
        'rolodex r, rolodex_mental_health_insurance mhi, client_insurance c, client cl, client_placement_event cpe',
        $where,
        'GROUP BY r.rec_id, r.name ORDER BY count DESC, r.name'
    );
    for( @$result ){
        $_->{ mh_coverage } = eleMentalClinic::Rolodex->new({
            rec_id => $_->{ rec_id },
        })->retrieve->name_f;
        delete $_->{ rec_id };
    }
    return $result;
}


__PACKAGE__->meta->make_immutable;
1;
