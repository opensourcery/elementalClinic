# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::HealthHistoryQuestionnaire;

use Moose;
use eleMentalClinic::Types qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'client',
    label => 'Health History Questionnaire',
    admin => 0,
    result_isa => Client,
    op    => 'run_report_pdf',
};

with 'eleMentalClinic::Report::HasClient' => { required => 1 };

sub build_result {
    my $self = shift;
    return $self->client;
}

1;
