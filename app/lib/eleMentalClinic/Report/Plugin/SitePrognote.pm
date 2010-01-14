# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::SitePrognote;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Plugin::ClientPrognote;
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Progress Notes by writer',
    admin => 0,
    result_isa => ArrayRef,
};

with qw/
    eleMentalClinic::Report::HasClient
    eleMentalClinic::Report::HasPersonnel
    eleMentalClinic::Report::HasDateRange
/;

sub _prognote {
    my ($self, $arg) = @_;
    %$arg = (%{ $self->report_args }, %{ $arg || {} });
    delete $arg->{$_} for grep { ! defined $arg->{$_} } keys %$arg;
    return eleMentalClinic::Report::Plugin::ClientPrognote
        ->new($arg)->result;
}

sub build_result {
    my ($self) = @_;
    return [ $self->_prognote ] if $self->staff_id;

    return [
        map { $self->_prognote({ staff_id => $_->staff_id }) }
        @{ eleMentalClinic::Department->new->get_writers }
    ];
}

__PACKAGE__->meta->make_immutable;
1;
