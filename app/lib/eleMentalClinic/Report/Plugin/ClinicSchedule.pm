# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::ClinicSchedule;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Clinic Schedule',
    admin => 0,
    result_isa => Dict[
        schedule_details => ArrayRef,
        schedule_appointments => ArrayRef,
    ],
};

has schedule_id => (is => 'ro', isa => Int, required => 1);

sub build_result {
    my ($self) = @_;
    my %data_holder;

    my $schedule_id = $self->schedule_id;

    my $empty = {
        schedule_details => [],
        schedule_appointments => [],
    };

    return $empty unless my $schedule_details = $self->db->do_sql(qq%
            SELECT to_char(sa.date,'Day')as dow, to_char(date,'MM/DD/YY') as sa_date,
                lname,description as location
            FROM schedule_availability sa, rolodex, valid_data_prognote_location
            WHERE rolodex.rec_id = sa.rolodex_id
                AND valid_data_prognote_location.rec_id = sa.location_id
                AND sa.rec_id = ?
            %, 0, $schedule_id);

    return $empty unless my $schedule_appointments = $self->db->do_sql(qq/
            SELECT appt_time,noshow,vdcc.name as confirm,client.fname as c_fname,
                client.lname as c_lname, cast(client.mname as char(1)) as c_mname,
                CASE WHEN fax = TRUE THEN 'Y' ELSE 'N' END AS fax,
                CASE WHEN chart = TRUE THEN 'Y' ELSE 'N' END AS chart,
                notes,phone.phone_number as phone,
                vdpc.name as payment,personnel.fname as p_fname
            FROM personnel, client, phone, schedule_appointments as sa
                LEFT OUTER JOIN valid_data_payment_codes as vdpc ON sa.payment_code_id = vdpc.rec_id
                LEFT OUTER JOIN valid_data_confirmation_codes as vdcc ON sa.confirm_code_id = vdcc.rec_id
            WHERE client.client_id = sa.client_id
                AND client.client_id = phone.client_id
                AND phone.primary_entry = true
                AND personnel.staff_id = sa.staff_id
                AND client.client_id = sa.client_id
                AND sa.schedule_availability_id = ?
            ORDER BY appt_time
                /, 0, $schedule_id);
    $data_holder{schedule_details} = $schedule_details;
    $data_holder{schedule_appointments} = $schedule_appointments;

    return \%data_holder;
}

__PACKAGE__->meta->make_immutable;
1;
