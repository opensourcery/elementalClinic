# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::ClientTermination;

use Moose;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'client',
    label => 'Termination',
    admin => 0,
    result_isa => Moose::Meta::TypeConstraint->new(
        name => 'eleMentalClinic::Client::Discharge',
        constraint => sub {
            my ( $item ) = @_;
            return unless UNIVERSAL::isa( $item, 'UNIVERSAL' );
            return $item->isa( 'eleMentalClinic::Client::Discharge' );
        }
    )
};

with 'eleMentalClinic::Report::HasClient' => { required => 1 };

has event_date => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub build_result {
    my ($self) = @_;

    my $result = $self->client->placement( $self->event_date )->discharge;
    return $result;
}


__PACKAGE__->meta->make_immutable;
1;
