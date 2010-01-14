# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::HasClient;

use MooseX::Role::Parameterized;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use namespace::autoclean;

parameter required => (
    isa => Bool,
    default => 0,
);

has client => (
    is         => 'ro',
    isa        => Maybe[Client],
    init_arg   => undef,
    lazy_build => 1,
);

sub _build_client {
    my ($self) = @_;
    return unless $self->client_id;
    return eleMentalClinic::Client->retrieve( $self->client_id );
}

role {
    my $p = shift;

    has client_id => (
        is  => 'ro',
        isa => Int,
        required => $p->required,
        label => 'Client',
    );
};

1;
