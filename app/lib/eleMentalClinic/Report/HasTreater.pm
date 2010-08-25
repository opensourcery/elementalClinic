# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::HasTreater;

use MooseX::Role::Parameterized;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use namespace::autoclean;

parameter required => (
    isa => Bool,
    default => 0,
);

has treater => (
    is         => 'ro',
    isa        => Maybe[Treater],
    init_arg   => undef,
    lazy_build => 1,
);

sub _build_treater {
    my ($self) = @_;
    return unless $self->treater_id;

    require eleMentalClinic::Client::Treater;
    return eleMentalClinic::Client::Treater->retrieve( $self->treater_id );
}

role {
    my $p = shift;

    has treater_id => (
        is  => 'ro',
        isa => Int,
        label => 'Doctor',
        required => $p->required,
    );
};

1;
