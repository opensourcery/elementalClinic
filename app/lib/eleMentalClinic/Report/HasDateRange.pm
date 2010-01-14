# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::HasDateRange;

use MooseX::Role::Parameterized;
use MooseX::Types::Moose qw(:all);
use namespace::autoclean;

parameter required => (
    isa     => Bool,
    default => 0,
);

role {
    my $p = shift;

    has start_date => (
        is       => 'ro',
        isa      => Str,
        label    => 'Start Date',
        required => $p->required,
    );

    has end_date => (
        is       => 'ro',
        isa      => Str,
        label    => 'End Date',
        required => $p->required,
    );
};

1;
