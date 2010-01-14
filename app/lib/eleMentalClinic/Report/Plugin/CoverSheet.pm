# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::CoverSheet;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'client',
    label => 'Records Review Sheet',
    admin => 0,
    result_isa => ArrayRef,
};

with 'eleMentalClinic::Report::HasClient' => { required => 1 };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub build_result {
    my ($self) = @_;

    # FIXME : This could be better but I'm lazy.
    return [] unless my $data_holder = $self->db->do_sql(qq/
        SELECT cl.fname,cl.mname,cl.lname,cl.dob,
             phone.phone_number as phone, cl.declaration_of_mh_treatment_date as received_date
        FROM client cl, phone
        WHERE cl.client_id = ? and phone.client_id = cl.client_id and phone.primary_entry = true
        /, 0, $self->client_id);

    return $data_holder;
}

__PACKAGE__->meta->make_immutable;
1;
