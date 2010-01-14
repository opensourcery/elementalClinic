# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::ZipCount;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Zip Code Count',
    admin => 0,
    result_isa => ArrayRef[
        Dict[
            post_code => Maybe[Int],
            count     => Int,
        ],
    ],
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires
#   nothing
# returns
#[
#    {
#        'post_code' => '97062'
#        'count' => '163',
#    },
#    ...
#]
sub build_result {
    my ($self) = @_;

    my $data = $self->db->do_sql(qq/
        SELECT address.post_code, count(*)
        FROM client, client_placement_event cpe, address
        WHERE client.client_id = cpe.client_id
        AND client.client_id = address.client_id
        AND cpe.program_id IS NOT NULL
        AND cpe.rec_id IN (
            SELECT DISTINCT ON ( client_id )
                rec_id
                FROM client_placement_event
                ORDER BY client_id ASC, event_date DESC, rec_id DESC
            )
        GROUP BY post_code
        ORDER BY post_code
    /);
    return $data || [];
}


__PACKAGE__->meta->make_immutable;
1;
