# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::InsReauth;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Client::Insurance::Authorization;
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Insurance Reauthorization',
    admin => 0,
    result_isa => ArrayRef,
};

has start_date => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has rolodex_id => (
    is => 'ro',
    isa => Int,
    label => 'Insurance',
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires a hashref with
#   start_date, for which we only use year and month
#   rolodex_id, optional
sub build_result {
    my $self = shift;

    return eleMentalClinic::Client::Insurance::Authorization
        ->renewals_due_in_month(
            $self->start_date,
            $self->rolodex_id,
        ) || [];
}

__PACKAGE__->meta->make_immutable;
1;
