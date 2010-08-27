# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::ClientIntakeForms;


=head1 NAME

eleMentalClinic::Report::Plugin::ClientIntakeForms - All client intake forms

=head1 DESCRIPTION

This concatenates together all the reports which generate forms having
to do with taking in new clients, with page breaks between them, so
they can be printed out with one click.  This is the "magic button".

The template data in this report must be a superset of all its sub forms.

=cut

use Moose;

use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);

use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'client',
    label => 'All Client Intake Forms',
    admin => 0,

    # Superset of all the sub-templates
    result_isa => Dict[
        treater => Treater,
        client  => Client,
        state   => Str
    ],
};

with 'eleMentalClinic::Report::HasClient'     => { required => 1 };
with 'eleMentalClinic::Report::HasTreater',   => { required => 1 };

has state => (
    is          => 'ro',
    isa         => Str,
    required    => 1,
);

sub build_result {
    my $self = shift;
    return {
        treater  => $self->treater,
        client   => $self->client,
        state    => uc $self->state,
    }
}

1;
