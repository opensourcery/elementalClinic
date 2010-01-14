# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Legal;

use Moose;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type       => 'client',
    label      => 'Legal History',
    admin      => 0,
    result_isa => Dict[
        name          => Str,
        legal_history => Maybe[ArrayRef[
            Dict[
                comment    => Str,
                location   => Str,
                start_date => Str,
                end_date   => Str,
                status     => Str,
                reason     => Str,
            ],
        ]],
    ],
};

with 'eleMentalClinic::Report::HasClient' => { required => 1 };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns
#{
#    name => 'Hanif, Mayyadah',
#    legal_history => [
#        {
#            comment => undef,
#            location => 'CCC',
#            end_date => '2002-12-01',
#            status => 'None',
#            reason => 'Forery, drug possession, theft, robbery, probation violation',
#            start_date => undef,
#        },
#       ...
#    ]
#}

sub build_result {
    my ($self) = @_;

    my $client = $self->client;

    my $past = $client->legal_past_issues;
    my $current = $client->legal_current_issues;

    my $result;

    $result->{name} = $client->lname . ", " . $client->fname;
    $result->{name} .= " " . $client->mname if $client->mname;

    my $vd = eleMentalClinic::ValidData->new({ dept_id => 1001 });

    for (@$past, @$current) {
        my $location = $vd->get('_legal_location', $_->location_id)->{ name };
        my $status = $vd->get('_legal_status', $_->status_id)->{ name };
        push @{ $result->{ legal_history } }, {
            reason => $_->reason || undef,
            location => $location,
            status => $status,
            start_date => $_->start_date || undef,
            end_date => $_->end_date || undef,
            comment => $_->comment_text || undef,
        };
    }
    return $result;
}

__PACKAGE__->meta->make_immutable;
1;
