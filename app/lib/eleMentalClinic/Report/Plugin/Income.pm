# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Income;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'client',
    label => 'Income',
    admin => 0,
    result_isa => ArrayRef,
};

sub build_result {
    my ($self) = @_;
}

__PACKAGE__->meta->make_immutable;
1;
