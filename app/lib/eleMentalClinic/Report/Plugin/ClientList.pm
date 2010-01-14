# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::ClientList;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Client List by Caseload',
    admin => 0,
    result_isa => ArrayRef[HashRef],
};

with 'eleMentalClinic::Report::HasPersonnel' => { required => 1 };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires a staff_id
# returns
#   an array of Client hashes with an extra key 'mh_coverage'
sub build_result {
    my ($self) = @_;

    my $staff_id = $self->staff_id;

    # TODO I added active = 1,  8/30. Will we be revisiting this report for Milestone 3 of ECS-Billing anyway? KJC
    my $active_insurance_clause = eleMentalClinic::Client::Insurance->active_insurance_clause;
    my $clients = $self->db->select_many(
        ['c.*, r.rec_id'],
        'client c, client_placement_event cpe, client_insurance, rolodex r, rolodex_mental_health_insurance mhi',
        qq/ WHERE cpe.staff_id = $staff_id
            AND cpe.rec_id IN (
                SELECT DISTINCT ON ( client_id )
                    rec_id
                    FROM client_placement_event
                    ORDER BY client_id ASC, event_date DESC, rec_id DESC
                )
            AND cpe.client_id = c.client_id
            AND c.client_id = client_insurance.client_id
            AND client_insurance.carrier_type = 'mental health'
            AND client_insurance.rank::integer = 1
            AND client_insurance.rolodex_insurance_id = mhi.rec_id
            $active_insurance_clause
            AND mhi.rolodex_id = r.rec_id
        /,
        'ORDER BY c.lname, c.fname'
    );

    # also fetch the clients who don't have mental health insurance
    my $clients_noins = $self->db->select_many(
        ['c.*, NULL as rec_id'],
        'client c, client_placement_event cpe',
        qq/ WHERE cpe.staff_id = $staff_id
            AND cpe.rec_id IN (
                SELECT DISTINCT ON ( client_id )
                    rec_id
                    FROM client_placement_event
                    ORDER BY client_id ASC, event_date DESC, rec_id DESC
                )
            AND cpe.client_id = c.client_id
            AND (SELECT COUNT(*)
                FROM client_insurance
                WHERE client_insurance.client_id = c.client_id
                AND client_insurance.carrier_type = 'mental health'
                $active_insurance_clause
                AND client_insurance.rank::integer = 1 ) = 0
        /,
        'ORDER BY c.lname, c.fname'
    );

    my @all_clients;
    push( @all_clients, @$clients ) if $clients;
    push( @all_clients, @$clients_noins ) if $clients_noins;

    return [] unless scalar @all_clients > 0;

    for( @all_clients ) {
        $_->{ mh_coverage } = eleMentalClinic::Rolodex->new({
            rec_id => $_->{ rec_id },
        })->retrieve->name_f;
        delete $_->{ rec_id };
        $_->{ phone } =~ s/(\d{3})(\d{3})(\d{4})/$1-$2-$3/ if $_->{ phone };
        $_->{ ssn } =~ s/(\d{3})(\d{2})(\d{4})/$1-$2-$3/ if $_->{ ssn };
    }
    return \@all_clients;
}

__PACKAGE__->meta->make_immutable;
1;
