# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin;

use MooseX::Role::Parameterized;
use eleMentalClinic::DB;
use namespace::autoclean;

requires 'build_result';

parameter result_isa => (
    required => 1,
    isa      => 'Moose::Meta::TypeConstraint',
);

parameter type => (
    required => 1,
    isa      => 'Str',
);

parameter label => (
    required => 1,
    isa      => 'Str',
);

parameter admin => (
    isa      => 'Bool',
    default  => 0,
);

sub db { eleMentalClinic::DB->new }

sub name {
    my ($self_or_class) = @_;
    my $class = blessed $self_or_class || $self_or_class;
    my $tail = (split /::/, $class)[-1];
    return join(
        '_', map { lc }
        split /(?<=\p{IsLower})(?=\p{IsUpper})/, $tail
    );
}

sub as_hash_for_list {
    my ($self) = @_;
    return { map {; $_ => $self->$_ } qw(name label admin) };
}

sub report_args {
    my ($self) = @_;
    my %args;
    for my $attr ($self->meta->get_all_attributes) {
        next if $attr->name eq 'result';
        next unless $attr->init_arg;
        $args{$attr->name} = $attr->get_value($self);
    }
    return \%args;
}

role {
    my $p = shift;
    has result => (
        is      => 'ro',
        isa     => $p->result_isa,
        lazy    => 1,
        builder => 'build_result',
    );

    for my $method (qw( label admin type )) {
        my $value = $p->$method;
        method $method => sub { $value };
    }
};

1;
