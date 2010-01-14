# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::PaymentTotalsByProgram;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'financial',
    label => 'Program payment totals',
    admin => 0,
    result_isa => ArrayRef,
};

has [qw(billing_payment_id payment_number)] => (
    is => 'ro',
    isa => Int,
);

=head2 payment_totals_by_program( $args )

Object method.

Returns billed, paid, unpaid totals for one payment for one insurer, grouped by
program.

Expects C<< $args->{ billing_payment_id } >> or C<< $args->{ payment_number } >>.

XXX Note that the correlated sub-query may be very slow.  One solution may be
to create a view of prognotes and programs, and join to that instead.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub build_result {
    my ($self) = @_;

    # XXX no way to represent this for graceful error handling
    die 'Payment OR payment number is required'
        unless $self->billing_payment_id or $self->payment_number;

    my $where =
          $self->billing_payment_id ? 'billing_payment.rec_id = '. $self->db->dbh->quote( $self->billing_payment_id)
        : $self->payment_number     ? 'billing_payment.payment_number = '. $self->db->dbh->quote( $self->payment_number)
        : '1 = 0'; # should never happen, but at least we'll cleanly return no results

    my $query = qq/
SELECT
    client_placement_event.program_id,
    valid_data_program.name AS program_name,
    SUM( transaction.paid_amount ) AS total_paid,
    SUM( billing_service.billed_amount ) AS total_billed,
    COALESCE( SUM( view_transaction_deductions.deductions ), 0 ) AS total_deductions
FROM billing_payment
    INNER JOIN transaction ON billing_payment.rec_id = transaction.billing_payment_id
        AND (transaction.entered_in_error != TRUE OR transaction.entered_in_error IS NULL)
        AND (transaction.refunded != TRUE OR transaction.refunded IS NULL)
    INNER JOIN billing_service ON transaction.billing_service_id = billing_service.rec_id
    INNER JOIN view_service_first_prognote first_prognote ON first_prognote.billing_service_id = billing_service.rec_id
    INNER JOIN client_placement_event ON first_prognote.client_id = client_placement_event.client_id
    LEFT OUTER JOIN view_transaction_deductions ON transaction.rec_id = view_transaction_deductions.transaction_id
    INNER JOIN valid_data_program ON client_placement_event.program_id = valid_data_program.rec_id
WHERE
    $where
    AND client_placement_event.rec_id IN (
        SELECT DISTINCT ON ( client_id )
            rec_id
            FROM client_placement_event
            WHERE DATE( event_date ) <= DATE( first_prognote.start_date )
            ORDER BY client_id ASC, event_date DESC, rec_id DESC
        )
GROUP BY
    client_placement_event.program_id,
    valid_data_program.name
    /;

    my $data = $self->db->do_sql( $query );
    return $data || [];
}


__PACKAGE__->meta->make_immutable;
1;
