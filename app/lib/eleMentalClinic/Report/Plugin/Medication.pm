# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Medication;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'client',
    label => 'Medication History',
    admin => 0,
    result_isa => ArrayRef,
};

with 'eleMentalClinic::Report::HasClient'    => { required => 1 };
with 'eleMentalClinic::Report::HasDateRange' => { required => 1 };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires
#   client_id
#   start_date
#   end_date
# returns
#   array of Client::Medication objects

sub build_result {
    my ($self) = @_;
    my $results = $self->client->medication_history( $self->report_args );
    return $results || [];
}

__PACKAGE__->meta->make_immutable;
1;
