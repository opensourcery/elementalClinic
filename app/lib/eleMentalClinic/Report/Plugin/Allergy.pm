# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Allergy;

use Moose;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'client',
    label => 'Allergy',
    admin => 0,
    result_isa => Maybe[Dict[
        name => Str,
        physicians => ArrayRef[Str],
        allergies  => ArrayRef[ClientAllergy],
    ]],
};

with 'eleMentalClinic::Report::HasClient' => { required => 1 };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires
#   client_id
# returns
# {
#    physicians => [
#        'Kathy Parrett, PMHNP',
#        ...
#    ],
#    name => 'Hanif, Mayyadah',
#    allergies => [
#        eleMentalClinic::Client::Allergy objects
#    ],
# }
sub build_result {
    my ($self) = @_;
    my $client_id = $self->client_id;

    my $result;
    my $client = $self->client;
    $result->{allergies} = $client->allergies;
    $result->{name} = $client->lname . ", " . $client->fname;
    $result->{name} .= " " . $client->mname if $client->mname;

    my $data_holder = $self->db->do_sql( qq/
        SELECT ro.rec_id
        FROM rolodex ro,
             rolodex_treaters rt,
             client_treaters ct
        WHERE ro.rec_id = rt.rolodex_id
        AND rt.rec_id = ct.rolodex_treaters_id
        AND ct.client_id = $client_id
    /);


    for (@$data_holder) {
        push @{$result->{physicians}},
            eleMentalClinic::Rolodex->new({
                rec_id => $_->{ rec_id },
            })->retrieve->name_f;
    }

    $result->{physicians} ||= [ 'None listed' ];

    return $result;
}

__PACKAGE__->meta->make_immutable;
1;
