# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::LastVisitBystaff;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Last Visits by Caseload',
    admin => 0,
    result_isa => ArrayRef[
        Dict[
            client => Str,
            charge_code => Maybe[Str],
            date => Str,
            duration => Str,
            writer => Maybe[Str],
        ],
    ],
};
with 'eleMentalClinic::Report::HasPersonnel' => { required => 1 };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires
#   staff_id
# returns
# [
#  {
#    client => 'Pedron Bergasa',
#    charge_code => undef,
#    date => '2004-09-07',
#    duration => '00:00',
#    writer => undef
#  },
#  ...
#]
sub build_result {
    my ($self) = @_;

    my $staff_id = $self->staff_id;
    my @result;

    # get client_ids for this staff member
    return [] unless my $client_ids = $self->db->do_sql(qq/
        SELECT client_id
        FROM client
        WHERE client_id IN (
            SELECT DISTINCT prognote.client_id
                FROM prognote, client_placement_event cpe
                WHERE cpe.staff_id = $staff_id
                    AND cpe.client_id = prognote.client_id
                    AND cpe.rec_id IN (
                    SELECT DISTINCT ON ( client_id )
                        rec_id
                        FROM client_placement_event
                        ORDER BY client_id ASC, event_date DESC, rec_id DESC
                    )
            )
        ORDER BY lname, fname
    /);

    my $data;
    for( @$client_ids ){
        push @$data, $self->db->do_sql(qq/
            SELECT c.fname, c.lname, date(p.start_date),
                extract (epoch from p.end_date - p.start_date) AS duration,
                cc.name AS charge_code, p.writer
            FROM client c, prognote p
            LEFT JOIN valid_data_charge_code cc
                ON cc.rec_id = p.charge_code_id
            WHERE c.client_id = $_->{ client_id }
                AND c.client_id = p.client_id
            ORDER BY p.start_date DESC, p.rec_id DESC
            LIMIT 1
        /)->[0];
    }

    my $temp;
    for( @$data ){
        $_->{ client } = join(', ', $_->{ lname }, $_->{ fname });
        delete $_->{ fname };
        delete $_->{ lname };
        $_->{ duration } = eleMentalClinic::Report::_time_unit_calc( undef, $_-> {duration} );
        push @result, $_;
    }

    return \@result;
}


__PACKAGE__->meta->make_immutable;
1;
