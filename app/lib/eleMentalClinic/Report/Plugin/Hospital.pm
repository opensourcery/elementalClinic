# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Hospital;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Rolodex;
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Hospitalization History',
    admin => 0,
    result_isa => ArrayRef,
};

with 'eleMentalClinic::Report::HasDateRange' => { required => 1 };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires
#   start_date
#   end_date
# returns
#[
#  {
#    name => Carrier1,
#    data => [
#      {
#         location => undef,
#         admit => undef,
#         reason => undef,
#         name => 'Christina Shami',
#         discharge => undef,
#         voluntary => 0
#      },
#      ...
#    ],
#  },
#  {
#    name => Carrier2,
#    data => [
#      ...
#    ],
#  },
#  ...
#]
#TODO this should return an array so the order can be alphabetic
sub build_result {
    my ($self) = @_;

    my $start_date = $self->start_date;
    my $end_date   = $self->end_date;

    my $data_holder = $self->db->do_sql(qq/
        SELECT
            c.client_id,
            ro.rec_id,
            c.fname, c.lname,
            ci.start_date AS admit,
            ci.end_date AS discharge,
            ci.hospital AS location,
            ci.reason, ci.voluntary
        FROM
            client c, client_inpatient ci,
            client_insurance cn, rolodex ro,
            rolodex_mental_health_insurance rmh
        WHERE
            c.client_id = ci.client_id
            AND c.client_id = cn.client_id
            AND cn.carrier_type = 'mental health'
            AND cn.rolodex_insurance_id = rmh.rec_id
            AND rmh.rolodex_id = ro.rec_id
            AND (
                ci.start_date BETWEEN '$start_date' AND '$end_date'
                OR '$start_date' BETWEEN ci.start_date AND ci.end_date
            )
        ORDER BY
            ro.name, c.lname, c.fname, admit, discharge
    /);

# This is what we have:
#[
#    {
#        'location' => 'Emmanuel Hosp.',
#        'mh_coverage' => 'None/PBHC Case Rate',
#        'admit' => '2003-08-18',
#        'reason' => 'Reports being suicidal, hospital hold',
#        'name' => 'Beatrice Barkauskas',
#        'discharge' => '2003-08-20',
#        'voluntary' => '0'
#    }
#]

    my $result = [];

    my $mhc = '';
    my $count = -1;
    for( @$data_holder ) {
        $_->{ mh_coverage } = eleMentalClinic::Rolodex->new({
            rec_id => $_->{ rec_id },
        })->retrieve->name_f;
        if( $mhc ne $_->{ mh_coverage } ){
            $mhc = $_->{ mh_coverage };
            push @$result, {
                name => $mhc,
            };
            $count++;
        }
        push @{ $result->[$count]->{ data }}, $_;
    }
    return $result;
}


__PACKAGE__->meta->make_immutable;
1;
