package eleMentalClinic::Report::Meta::Attribute;

use Moose::Role;
use MooseX::Types::Moose -all;
use namespace::autoclean;

has label => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_label',
    default   => sub {
        my @words = split /_/, $_[0]->name;
        join " ", map { ucfirst } @words;
    },
);

1;
