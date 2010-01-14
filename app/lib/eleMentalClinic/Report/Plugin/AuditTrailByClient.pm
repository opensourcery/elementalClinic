# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::AuditTrailByClient;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);

use eleMentalClinic::Util qw(_check_date);

use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'financial',
    label => 'Client, audit trail',
    admin => 0,
    result_isa => ArrayRef,
};

has date => (is => 'ro', isa => Str, required => 1);

=head2 audit_trail_by_client( $args )

Object method.

Lists each client, the client's level of care, and billings, payments, write offs, and
remaining balance for the selected month.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub build_result {
    my ($self) = @_;

    die 'Date is invalid' unless _check_date( $self->date);

    my( $y, $m, undef ) = split '-' => $self->date;
    my $last_day = Date::Calc::Days_in_Month( $y, $m );
    my $this_month_first_day = "$y-$m-01";
    my $this_month_last_day = "$y-$m-$last_day";

    my $query = qq/
SELECT
    c.client_id,
    c.lname
    || ( CASE WHEN c.name_suffix IS NOT NULL THEN ' ' || c.name_suffix ELSE '' END )
    || ', ' || c.fname
    || ( CASE WHEN c.mname IS NOT NULL THEN ' ' || c.mname ELSE '' END )
    AS client_name,
    COALESCE( valid_data_level_of_care.name, 'Discharged' ) AS level_of_care,
    COALESCE( previous_billings.previous_billings_total, 0 )     AS previous_billings_total,
    COALESCE( previous_payments.previous_payments_total, 0 )     AS previous_payments_total,
    COALESCE( previous_writeoffs.previous_writeoffs_total, 0 )   AS previous_writeoffs_total,
    (
        COALESCE( previous_billings.previous_billings_total, 0 )
        - COALESCE( previous_payments.previous_payments_total, 0 )
        - COALESCE( previous_writeoffs.previous_writeoffs_total, 0 )
    ) AS previous_balance,

    COALESCE( this_month_billings.this_month_billings_total, 0 ) AS this_month_billings_total,
    COALESCE( this_month_payments.this_month_payments_total, 0 ) AS this_month_payments_total,
    COALESCE( this_month_writeoffs.this_month_writeoffs_total, 0 )   AS this_month_writeoffs_total,
    (
        ( COALESCE( previous_billings.previous_billings_total, 0 ) + COALESCE( this_month_billings.this_month_billings_total, 0 ))
        - ( COALESCE( previous_payments.previous_payments_total, 0 ) + COALESCE( this_month_payments.this_month_payments_total, 0 ))
        - ( COALESCE( previous_writeoffs.previous_writeoffs_total, 0 ) + COALESCE( this_month_writeoffs.this_month_writeoffs_total, 0 ))
    ) AS this_month_balance

FROM client c
    INNER JOIN client_placement_event ON c.client_id = client_placement_event.client_id
    LEFT OUTER JOIN valid_data_level_of_care ON client_placement_event.level_of_care_id = valid_data_level_of_care.rec_id

    LEFT OUTER JOIN (
        SELECT cb.client_id, SUM(cb.billed_amount) AS previous_billings_total
        FROM view_client_billings AS cb
        WHERE cb.billed_date < DATE( '$this_month_first_day' )
        GROUP BY cb.client_id
     ) AS previous_billings
    ON c.client_id = previous_billings.client_id

    LEFT OUTER JOIN (
        SELECT cb.client_id, sum(cb.billed_amount) AS this_month_billings_total
        FROM view_client_billings AS cb
        WHERE cb.billed_date >= DATE( '$this_month_first_day' ) AND cb.billed_date <= DATE( '$this_month_last_day' )
        GROUP BY cb.client_id
     ) AS this_month_billings
    ON c.client_id = this_month_billings.client_id

    LEFT OUTER JOIN (
        SELECT cp.client_id, sum(cp.paid_amount) AS previous_payments_total
        FROM view_client_payments AS cp
        WHERE cp.paid_date < DATE( '$this_month_first_day' )
        GROUP BY cp.client_id
     ) AS previous_payments
    ON c.client_id = previous_payments.client_id

    LEFT OUTER JOIN (
        SELECT cp.client_id, sum(cp.paid_amount) AS this_month_payments_total
        FROM view_client_payments AS cp
        WHERE cp.paid_date >= DATE( '$this_month_first_day' ) AND cp.paid_date <= DATE( '$this_month_last_day' )
        GROUP BY cp.client_id
     ) AS this_month_payments
    ON c.client_id = this_month_payments.client_id

    LEFT OUTER JOIN (
        SELECT cw.client_id, sum(cw.balance) AS previous_writeoffs_total
        FROM view_client_writeoffs AS cw
        WHERE cw.payment_date < DATE( '$this_month_first_day' )
        GROUP BY cw.client_id
     ) AS previous_writeoffs
    ON c.client_id = previous_writeoffs.client_id

    LEFT OUTER JOIN (
        SELECT cw.client_id, sum(cw.balance) AS this_month_writeoffs_total
        FROM view_client_writeoffs AS cw
        WHERE cw.payment_date >= DATE( '$this_month_first_day' ) AND cw.payment_date <= DATE( '$this_month_last_day' )
        GROUP BY cw.client_id
     ) AS this_month_writeoffs
    ON c.client_id = this_month_writeoffs.client_id

WHERE
    client_placement_event.rec_id IN (
        SELECT DISTINCT ON ( client_id )
            rec_id
            FROM client_placement_event
            WHERE DATE( event_date ) <= DATE( '$this_month_last_day' )
            ORDER BY client_id ASC, event_date DESC, rec_id DESC
        )
ORDER BY
    c.lname
    || ( CASE WHEN c.name_suffix IS NOT NULL THEN ' ' || c.name_suffix ELSE '' END )
    || ', ' || c.fname
    || ( CASE WHEN c.mname IS NOT NULL THEN ' ' || c.mname ELSE '' END )
    /;

    my $data = $self->db->do_sql( $query );
    return $data || [];
}

__PACKAGE__->meta->make_immutable;
1;
