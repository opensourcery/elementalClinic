# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::UncommittedPrognotes;

use Moose;
use MooseX::Types;
use MooseX::Types::Moose ':all';
use MooseX::Types::Structured ':all';
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    label => 'Uncommitted Progress Notes',
    type  => 'site',
    result_isa => ArrayRef[
        Dict[
            writer => class_type('eleMentalClinic::Personnel'),
            uncommitted_prognotes => ArrayRef[
                class_type('eleMentalClinic::ProgressNote')
            ],
        ],
    ],
};

sub build_result {
    my $self = shift;
    my $writers = eleMentalClinic::Department->new->get_writers;
    my @data;
    for( @$writers ) {
        next unless my $notes = $_->uncommitted_prognotes;
        push @data => { 
            writer  => $_,
            uncommitted_prognotes => $notes,
        };
    }
    return \@data;
}

__PACKAGE__->meta->make_immutable;
1;
