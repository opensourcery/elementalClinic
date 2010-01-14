# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::VerificationExpirations;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Verification Expirations Report',
    admin => 0,
    result_isa => ArrayRef,
};

has expires_in_days => ( is => 'ro', isa => Int );
has start_date      => ( is => 'ro', isa => Str );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub build_result {
    my ($self) = @_;
    my( $args ) = $self->report_args;

    return $self->_verifications_by_index_date(
        {
            index_date      => scalar localtime,
            expires_in_days => $args->{expires_in_days},
            start_date      => $args->{start_date}
        }
    );
}

# Internal method provides a list of all clients whose verifications letters have
# expired or will expire in 60 days from a passed index date.  This allows us
# to test the core function without worrying about 'now' shifting.
#
sub _verifications_by_index_date {
    my $self = shift;
    my ($args) = @_;

    my $index_date      = $args->{index_date};
    my $expires_in_days = $args->{expires_in_days} || 0;
    my $start_date      = $args->{start_date} || '1900-01-01';
    my $expires         = $self->db->dbh->quote("$expires_in_days days");
#    print STDERR Dumper $expires;

    my $data_holder = $self->db->do_sql(qq/
        select
            client.client_id,
            client.lname,
            client.fname,
            client.mname,
            client.sex,
            phone.phone_number as phone,
            client.dont_call,
            addr.state,
            client.email,
            max(verif_date) as last_verification,
            to_date((max(verif_date) + interval '1 year')::text,'YYYY-MM-dd') as verification_expires
        from
            address addr, phone, client, client_verification as v
        where addr.client_id = client.client_id
                and client.client_id = v.client_id
                and addr.primary_entry = true
                and phone.client_id = client.client_id
                and phone.primary_entry = true
        group by
            client.client_id,
            client.lname,
            client.fname,
            client.mname,
            client.sex,
            phone.phone_number,
            client.dont_call,
            addr.state,
            client.email
        having date(?) + interval $expires > max(verif_date) + interval '1 year' and
            max(verif_date) + interval '1 year' > ?
        order by addr.state, substring(phone.phone_number from '\\([0-9]{1,3}\\)'), lname;/, 0, $index_date, $start_date);
    return $data_holder || [];
}


__PACKAGE__->meta->make_immutable;
1;
