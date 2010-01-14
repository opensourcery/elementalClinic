# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::MonthlySummaryByInsurer;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'financial',
    label => 'Insurer, monthly summary',
    admin => 0,
    result_isa => ArrayRef,
};

has rolodex_id => (is => 'ro', isa => Int, required => 1);
has date       => (is => 'ro', isa => Str, required => 1);

=head2 monthly_summary_by_insurer( $args )

Object method.

This report lists the unpaid claims that were billed to the chosen insurer
before the chosen date.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub build_result {
    my ($self) = @_;

    my $rolodex_id = $self->db->dbh->quote( $self->rolodex_id);
    my $date = $self->db->dbh->quote( $self->date);

    my $query = qq/
SELECT
    client.lname
    || ( CASE WHEN client.name_suffix IS NOT NULL THEN ' ' || client.name_suffix ELSE '' END )
    || ', ' || client.fname
    || ( CASE WHEN client.mname IS NOT NULL THEN ' ' || client.mname ELSE '' END )
    AS client_name,
    client.state_specific_id,
    billing_claim.client_id,
    billing_service.billed_units,
    billing_service.billed_amount,
    DATE( billing_file.submission_date ) AS billing_date,
    DATE( first_prognote.start_date ) AS prognote_date
FROM billing_file
    INNER JOIN billing_claim
        ON billing_claim.billing_file_id = billing_file.rec_id
    INNER JOIN billing_service
        ON billing_service.billing_claim_id = billing_claim.rec_id
    INNER JOIN view_service_first_prognote AS first_prognote
        ON first_prognote.billing_service_id = billing_service.rec_id
    INNER JOIN client
        ON client.client_id = first_prognote.client_id
WHERE
    billing_file.rolodex_id = $rolodex_id
    AND DATE( billing_file.submission_date ) <= DATE( $date )
    AND billing_service.rec_id IN ( SELECT rec_id FROM view_unpaid_billed_services )
ORDER BY
    billing_file.submission_date ASC,
    prognote_date ASC,
    client_id
    /;
    my $data = $self->db->do_sql( $query );
    return $data || [];
}

__PACKAGE__->meta->make_immutable;
1;
