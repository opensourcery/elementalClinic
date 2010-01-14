# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Verifications;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Verifications Report',
    admin => 0,
    result_isa => ArrayRef,
};

with 'eleMentalClinic::Report::HasDateRange';

sub build_result {
    my ($self) = @_;

    my $start_date = $self->start_date;
    my $end_date = $self->end_date;

	my $data_holder = $self->db->do_sql(qq/
        SELECT cv.apid_num,client.fname,client.mname,client.lname,client.dob,
            cv.verif_date, r.lname as doctor, cv.client_id
        FROM client_verification cv, client, rolodex_treaters rt, rolodex r
        WHERE cv.client_id = client.client_id
            AND cv.rolodex_treaters_id = rt.rec_id
            AND rt.rolodex_id = r.rec_id
            AND date(cv.created) BETWEEN ? and ?
        ORDER BY client.lname, client.fname, client.mname, cv.apid_num /, 0, $start_date, $end_date);

	return $data_holder || [];
}

__PACKAGE__->meta->make_immutable;
1;
