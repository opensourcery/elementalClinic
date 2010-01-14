# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::ServicesByClient;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'financial',
    label => 'Billed services and payments',
    admin => 0,
    result_isa => Any,
};

with 'eleMentalClinic::Report::HasClient' => { required => 1 };

=head2 services_by_client( $args )

Object method.

This report lists all I<billed> services for a client, in a specified date range.
The billings and payments are shown for each service.

We're doing this report with nested object methods in the view.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub build_result {
    my ($self) = @_;
    return $self->client_id;
}


__PACKAGE__->meta->make_immutable;
1;
