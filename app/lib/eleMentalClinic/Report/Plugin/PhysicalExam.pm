# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::PhysicalExam;

use Moose;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'client',
    label => 'Physical Exam Form',
    admin => 0,
    result_isa => Dict[
        treater => Treater,
        client  => Client,
    ],
};

with 'eleMentalClinic::Report::HasClient' => { required => 1 };
with 'eleMentalClinic::Report::HasTreater',   => { required => 1 };

sub build_result {
    my $self = shift;
    return {
        treater  => $self->treater,
        client   => $self->client,
    }
}

1;
