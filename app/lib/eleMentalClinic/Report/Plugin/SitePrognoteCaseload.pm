# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::SitePrognoteCaseload;

use Moose;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Personnel;
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Progress Notes by caseload',
    admin => 0,
    result_isa => ArrayRef[Personnel],
};

has staff_id => (
    is => 'ro',
    isa => Int,
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# all prognotes by caseload
# this method just returns staff
sub build_result {
    my ($self) = @_;

    return [ eleMentalClinic::Personnel->retrieve( $self->staff_id ) ]
        if $self->staff_id;

    return eleMentalClinic::Department->new->get_writers;
}

__PACKAGE__->meta->make_immutable;
1;
