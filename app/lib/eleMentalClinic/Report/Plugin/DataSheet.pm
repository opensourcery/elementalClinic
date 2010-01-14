# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::DataSheet;

use Moose;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::ValidData;
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'client',
    label => 'Data Sheet',
    admin => 0,
    result_isa => Client,
};

with 'eleMentalClinic::Report::HasClient' => { required => 1 };

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# requires
#   client_id
# returns client object with extra hash keys
#   medical_provider
#   pbhc_auth_num
#   pbhc_reauth_date
#   dental_provider
#   mhp
#   third_party_provider
#   third_party_id
#   axis_1_primary
#   axis_1_secondary
#   axis_2
#   axis_3
#   axis_4
#   axis_5
#   diagnosis_comments
#   medication_monitor
#   healthcare_notes
#   medical_professionals
#   contacts (array)
#   subsidized_housing
#   employment
#   employer
#   soc_sec_payee
#   money_manager
#   acct_number
#   income (array)

sub build_result {
    my ($self) = @_;
    my $client_id = $self->client_id;

    # identifying information section
    my $client = $self->client;
    $client->ssn( $client->ssn_f ); # XXX wtf?

    my( $data_holder, $rolodex );

    # insurance information for all active providers
    for my $carrier_type ( 'Medical', 'Dental', 'Mental Health' ) {
        next unless
            my $insurers = $client->insurance_bytype( $carrier_type );
        push @{ $client->{ insurances }} => @$insurers;

        my $rolodex_table = lc "rolodex_${carrier_type}_insurance";
        $rolodex_table =~ s/ /_/;

        $data_holder = $self->db->do_sql(qq/
            SELECT
                ro.rec_id,
                ci.authorization_code,
                ci.auth_end_date,
                ci.rank,
                ci.insurance_id
            FROM
                rolodex ro, client_insurance ci, $rolodex_table ri
            WHERE
                ci.client_id = ?
                AND ci.carrier_type = lower( '$carrier_type' )
                AND ci.active = 1
                AND ci.rolodex_insurance_id = ri.rec_id
                AND ri.rolodex_id = ro.rec_id
            ORDER BY
                ci.rec_id
            /, 0, $client_id);

        for( @$data_holder ){

            $rolodex = eleMentalClinic::Rolodex->new({
                rec_id => $_->{ rec_id },
            })->retrieve;
            my $insurance = { type => $carrier_type,
                              provider => $rolodex->name_f,
                              rank => $_->{ rank },
                              id => $_->{ insurance_id },
                              auth_num => $_->{ authorization_code },
                              auth_date => $_->{ auth_end_date },
                            };
            push @{$client->{ insurances }} => $insurance;
        }
    }

    # diagnosis information section
    $data_holder = $self->db->do_sql(qq/
        SELECT
            cd.diagnosis_1a AS axis_1_primary,
            cd.diagnosis_1b AS axis_1_secondary,
            cd.diagnosis_2a AS axis_2,
            cd.diagnosis_3 AS axis_3,
            cd.diagnosis_4 AS axis_4,
            cd.diagnosis_5_current AS axis_5,
            cd.comment_text AS diagnosis_comments
        FROM
            client_diagnosis cd
        WHERE
            cd.client_id = ?
        ORDER BY cd.diagnosis_date DESC
    /, 0, $client_id);

    for (qw/
        axis_1_primary axis_1_secondary axis_2 axis_3
        axis_4 axis_5 diagnosis_comments
    /) {
        $client->{$_} = $data_holder->[0]->{$_};
    }

    # medical information section
    $data_holder = $self->db->do_sql(qq/
        SELECT
            ro.rec_id ,
            cc.comment_text AS healthcare_notes
        FROM
            rolodex ro, client_contacts cc, rolodex_contacts rc
        WHERE
            cc.client_id = ?
            AND cc.contact_type_id = 2
            AND cc.rolodex_contacts_id = rc.rec_id
            AND rc.rolodex_id = ro.rec_id
            AND cc.comment_text IS NOT NULL
        ORDER BY
            cc.rec_id
    /, 0, $client_id);
    $rolodex = eleMentalClinic::Rolodex->new({
        rec_id => $data_holder->[0]->{ rec_id },
    })->retrieve;
    $client->{ medication_monitor } = $rolodex->name_f;

    $client->{ healthcare_notes } = $data_holder->[0]->{ healthcare_notes };

    $client->{allergies} = $client->allergies;

    # medical information section, cont
    $data_holder = $self->db->do_sql(qq/
        SELECT
            ro.rec_id,
            ro.credentials AS profession,
            addr.address1 as addr, addr.address2 as addr_2, addr.city, addr.state as state, addr.post_code as post_code,
            phone.phone_number AS phone
        FROM
            rolodex ro, client_treaters ct, rolodex_treaters rt, address addr, phone
        WHERE
            ct.client_id = ?
            AND addr.rolodex_id = ro.rec_id
            AND phone.rolodex_id = ro.rec_id
            AND addr.primary_entry = true
            AND phone.primary_entry = true
            AND ct.treater_type_id = 3
            AND ct.rolodex_treaters_id = rt.rec_id
            AND rt.rolodex_id = ro.rec_id
    /, 0, $client_id);
    for( @$data_holder ){
        $_->{ name } = eleMentalClinic::Rolodex->new({
            rec_id => $_->{ rec_id },
        })->retrieve->eman;
    }

    $client->{medical_professionals} = $data_holder;

    # rolodex contact information section
    $data_holder = $client->relationship_byrole('contacts');
    push @{$client->{rolodex_entries}}, @{$self->rolodex_entries( 'contacts', $data_holder )};

    $data_holder = $client->relationship_byrole('treaters');
    push @{$client->{rolodex_entries}}, @{$self->rolodex_entries( 'Treater', $data_holder )};

    $data_holder = $client->relationship_byrole('employment');
    push @{$client->{rolodex_entries}}, @{$self->rolodex_entries( 'Employer', $data_holder )};

    # financial information section
    $client->{subsidized_housing} = $client->section_eight;
    # TODO working is F,P or U (or null)
    #   could be Full, Part, Unemp, or Unknown
    #   maybe in the template
    $client->{employment} = $client->working;
    $data_holder = $client->rolodex_byrole('employment');
    $client->{employer} = $data_holder->[0]->{name};

    #social security
    $data_holder = $self->db->do_sql(qq/
        SELECT
            ro.rec_id
        FROM
            rolodex ro, client_contacts cc, rolodex_contacts rc
        WHERE
            cc.client_id = ?
            AND cc.contact_type_id = 5
            AND cc.rolodex_contacts_id = rc.rec_id
            AND rc.rolodex_id = ro.rec_id
    /, 0, $client_id);

    $rolodex = eleMentalClinic::Rolodex->new({
        rec_id => $data_holder->[0]->{ rec_id },
    })->retrieve;
    $client->{ soc_sec_payee } = $rolodex->name_f;

    # money manager
    $data_holder = $self->db->do_sql(qq/
        SELECT
            ro.rec_id
        FROM
            rolodex ro, client_contacts cc, rolodex_contacts rc
        WHERE
            cc.client_id = ?
            AND cc.contact_type_id = 3
            AND cc.rolodex_contacts_id = rc.rec_id
            AND rc.rolodex_id = ro.rec_id
    /, 0, $client_id);

    $rolodex = eleMentalClinic::Rolodex->new({
        rec_id => $data_holder->[0]->{ rec_id },
    })->retrieve;
    $client->{ money_manager } = $rolodex->name_f;

    # account number is easy
    $client->{acct_number} = $client->acct_id;

    # income list
    $data_holder = $self->db->do_sql(qq/
        SELECT
            vdis.name AS income_source_type,
            ci.income_amount AS amount
        FROM
            valid_data_income_sources vdis, client_income ci
        WHERE
            ci.client_id = ?
            AND ci.source_type_id = vdis.rec_id
    /, 0, $client_id);

    for (@$data_holder) {
        push @{$client->{income}},
            {
                income_source_type => $_->{income_source_type},
                amount => $_->{amount},
            };
    }
    return $client;
}

sub rolodex_entries {
    my $self = shift;
    my $type = shift;
    my $data_holder = shift;
    my @entries;
    my $contact_type = $type;

    for (@$data_holder) {
        my $rolodex = $_->rolodex;
        my $addr = undef;
        if ($rolodex->{addr} or $rolodex->{addr_2} or $rolodex->{city} or $rolodex->{state} or $rolodex->{post_code}) {
            for my $item ( qw/ addr addr_2 city state post_code /){
                $addr .= "$rolodex->{$item} " if $rolodex->{$item};
            }
        }
        $rolodex->{ phone } =~ s/(\d{3})(\d{3})(\d{4})/$1-$2-$3/ if $rolodex->{ phone };

        if( $type eq 'contacts' ){
            $contact_type = eleMentalClinic::ValidData->new({ dept_id => 1001 })->get_name( '_contact_type', $_->contact_type_id );
        }
        push @entries, {
            name => $rolodex->eman,
            type => $contact_type,
            phone => $rolodex->{phone},
            address => $addr,
        };
    }

    return \@entries;
}

__PACKAGE__->meta->make_immutable;
1;
