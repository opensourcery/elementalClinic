# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Renewals;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Renewals Report',
    admin => 0,
    result_isa => ArrayRef,
};

with 'eleMentalClinic::Report::HasDateRange';

has zip_code  => (is => 'ro', isa => Int);
has area_code => (is => 'ro', isa => Int);
has state     => (is => 'ro', isa => Str);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub build_result {
    my ($self) = @_;

    my $start_date = $self->start_date;
    my $end_date = $self->end_date;
    my $zip_code = $self->zip_code;
    my $area_code = $self->area_code;
    my $state = $self->state;

    my($data_holder, $sql, @where, @bindings);

    # main sql
    $sql = qq/
        select
            client.client_id,
            client.lname,
            client.fname,
            client.mname,
            client.sex,
            p.phone_number as phone,
            client.dont_call,
            addr.state as state,
            addr.post_code as post_code,
            client.email,
            client.renewal_date,
            max(verif_date) as last_verification,
            to_date((max(verif_date) + interval '1 year')::text,'YYYY-MM-dd') as verification_expires
        from
           client
           left outer join client_verification as v
                on client.client_id = v.client_id
           left outer join phone as p
                on client.client_id = p.client_id and p.primary_entry = true
           left outer join address as addr
                on client.client_id = addr.client_id and addr.primary_entry = true
                \n/;

    # where clause
    if ($start_date) {
        push @where, "client.renewal_date >= date(?)";
        push @bindings, $start_date;
    }
    if ($end_date) {
        push @where, "client.renewal_date <= date(?)";
        push @bindings, $end_date;
    }
    if ($zip_code) {
        push @where, "addr.post_code = ?";
        push @bindings, $zip_code;
    }
    if ($state) {
        push @where, "upper(addr.state) = upper(?)";
        push @bindings, $state;
    }
    if ($area_code) {
        push @where, "substring(p.phone_number from '\\([0-9]{1,3}\\)') = ?";
        push @bindings, $area_code
    }
    $sql .= "where " . (join " and ", @where) . "\n" if @where;

    # group by
    $sql .= qq/
        group by
            client.client_id,
            client.lname,
            client.fname,
            client.mname,
            client.sex,
            p.phone_number,
            client.dont_call,
            addr.state,
            addr.post_code,
            client.email,
            client.renewal_date\n/;

    # order by
    $sql .= " order by addr.state, addr.post_code, client.lname;";

#    print STDERR Dumper [$sql, @where, @bindings];

    if (@bindings) {
        $data_holder = $self->db->do_sql($sql, 0, @bindings);
    } else {
        $data_holder = $self->db->do_sql($sql);
    }

    return $data_holder || [];
}

__PACKAGE__->meta->make_immutable;
1;
