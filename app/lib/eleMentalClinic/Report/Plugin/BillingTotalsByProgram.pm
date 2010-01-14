# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::BillingTotalsByProgram;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'financial',
    label => 'Program billing totals',
    admin => 0,
    result_isa => ArrayRef,
};

has billing_file_id => (is => 'ro', isa => Int, required => 1);

=head2 billing_totals_by_program( $args )

Object method.

This report lists each client's total billed amounts for one billing to one insurer,
grouped by program.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub build_result {
    my ($self) = @_;

    my $billing_file_id = $self->db->dbh->quote( $self->billing_file_id);

    my $query = qq/
SELECT
    client_placement_event.program_id,
    valid_data_program.name AS program_name,
    client.lname
    || ( CASE WHEN client.name_suffix IS NOT NULL THEN ' ' || client.name_suffix ELSE '' END )
    || ', ' || client.fname
    || ( CASE WHEN client.mname IS NOT NULL THEN ' ' || client.mname ELSE '' END )
    AS client_name,
    client.client_id,
    client.state_specific_id,
    SUM( billing_service.billed_amount ) AS total_billed
FROM billing_file
    INNER JOIN billing_claim ON billing_file.rec_id = billing_claim.billing_file_id
    INNER JOIN billing_service ON billing_claim.rec_id = billing_service.billing_claim_id
    INNER JOIN view_service_first_prognote AS first_prognote ON billing_service.rec_id = first_prognote.billing_service_id
    INNER JOIN client ON first_prognote.client_id = client.client_id
    INNER JOIN client_placement_event ON client.client_id = client_placement_event.client_id
    INNER JOIN valid_data_program ON client_placement_event.program_id = valid_data_program.rec_id
WHERE
    billing_file.rec_id = $billing_file_id
    AND client_placement_event.rec_id IN (
        SELECT DISTINCT ON ( client_id )
            rec_id
            FROM client_placement_event
            WHERE DATE( event_date ) <= DATE( first_prognote.start_date )
            ORDER BY client_id ASC, event_date DESC, rec_id DESC
        )
GROUP BY
    client_placement_event.program_id,
    client.lname
    || ( CASE WHEN client.name_suffix IS NOT NULL THEN ' ' || client.name_suffix ELSE '' END )
    || ', ' || client.fname
    || ( CASE WHEN client.mname IS NOT NULL THEN ' ' || client.mname ELSE '' END ),
    client.client_id,
    client.state_specific_id,
    valid_data_program.name
ORDER BY client_name
    /;
    my $data = $self->db->do_sql( $query );
    return $data || [];
}


__PACKAGE__->meta->make_immutable;
1;
