# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::AuthorizationsOverBudget;

use Moose;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);

use eleMentalClinic::Client;
use eleMentalClinic::Base::Time qw(today);

use eleMentalClinic::Report::Labelled;
use namespace::autoclean;


with 'eleMentalClinic::Report::Plugin' => {
    type  => 'financial',
    label => 'Authorizations over budget',
    admin => 1,
    result_isa => ArrayRef[
        Dict[
            client => Client,
            insurers => ArrayRef[ClientInsurance],
        ]
    ],
};

with qw/
    eleMentalClinic::Report::HasPersonnel
    eleMentalClinic::Report::HasDateRange
/;

has [qw(program_id level_of_care_id)] => (is => 'ro', isa => Int);

=head2 authorizations_over_budget()

Object method.

A report to show all clients that are within a certain percentage of their
projected capitation limit. IOW, "Show me clients you think will run out of
money before their authorization expires."

Filter by: case manager, program, level of care.

NOTE that this would be dramatically faster if it were written as a single
query instead of chaining together a bunch of object methods.

The data structure is:

    [
        {
            client  => $client
            insurers  => [
                $insurer,
                $insurer,
            ]
        }
    ]

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub build_result {
    my ($self) = @_;

    my $date = $self->start_date || today();

    my @report;
    for my $client( @{ eleMentalClinic::Client->get_all }) {
        my %record;
        my $placement = $client->placement( $date );
        next if
            $self->staff_id and (
                not $placement->staff_id or
                $self->staff_id != $placement->staff_id
            );
        next if
            $self->program_id and (
                not $placement->program_id or
                $self->program_id != $placement->program_id
            );
        next if
            $self->level_of_care_id and (
                not $placement->level_of_care_id or
                $self->level_of_care_id != $placement->level_of_care_id
            );

        my $insurers = $client->authorized_insurers( 'mental health', $date );
        next unless $insurers;
        for my $insurer( @$insurers ) {
            next unless
                my $authorization = $insurer->authorization( $date );
            next unless $authorization->allowed_amount
                and $authorization->capitation_amount_percent
                and $authorization->capitation_time_percent;
            next unless
                    $authorization->capitation_amount_percent
                    > $authorization->capitation_time_percent;
            push @{ $record{ insurers }} => $insurer;
            # now we've eliminated every failure case, so we add data to the report
        }
        next unless %record;
        $record{ client } = $client;
        push @report => \%record;
    }
    return \@report;
}

__PACKAGE__->meta->make_immutable;
1;
