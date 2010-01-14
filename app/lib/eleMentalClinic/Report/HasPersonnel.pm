# vim: ts=4 sts=4 sw=4
# XXX much copy and paste from HasClient -- refactor them
package eleMentalClinic::Report::HasPersonnel;

use MooseX::Role::Parameterized;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use namespace::autoclean;

parameter required => (
    isa => Bool,
    default => 0,
);

has personnel => (
    is         => 'ro',
    isa        => Maybe[Personnel],
    init_arg   => undef,
    lazy_build => 1,
);

sub _build_personnel {
    my ($self) = @_;
    return unless $self->staff_id;
    return eleMentalClinic::Personnel->retrieve( $self->staff_id );
}

role {
    my $p = shift;

    has staff_id => (
        is  => 'ro',
        isa => Int,
        label => 'Staff Member',
        required => $p->required,
    );
};

1;
