# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Appointments;

use Moose;
use eleMentalClinic::Types qw(:all);
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Personnel;
use eleMentalClinic::Schedule::Appointments;
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Appointments',
    result_isa => ArrayRef[
        Dict[
            staff => HashRef | Personnel,
            list  => ArrayRef[HashRef],
        ]
    ],
};

has date => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has group => (
    is => 'ro',
    isa => Str,
    default => 'Date',
);

has location_id => (
    is => 'ro',
    isa => Int,
);

has rolodex_id => (
    is => 'ro',
    isa => Int
);

has _user_login => (
    is => 'ro',
    isa => Str,
    init_arg => 'user',
);

has user => (
    is => 'ro',
    isa => Personnel,
    init_arg => undef,
    writer => '_set_user',
);

sub BUILD {
    my ($self) = @_;
    # ugly special case
    if ($self->_user_login && $self->_user_login ne 'All Users') {
        my $user = eleMentalClinic::Personnel->get_one_by_(
            login => $self->_user_login
        );
        die "No user found for " . $self->_user_login
            unless $user && $user->staff_id;
        $self->_set_user($user);
    }
}


=head2 appointments()

Object method.

appointments report

params: {
    user => user_login
    date => DATE
    group => 'Staff' #Anything other than 'Staff' is ignored.
}

returns: [
    {
        staff => eleMentalClinic::Personnel *OR* { name => 'All Staff' },
        list => [ APPT, ... ],
    },
    {...}
]

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub build_result {
    my $self = shift;
 
    my $list = eleMentalClinic::Schedule::Appointments->list_byday(
        map {; $_ => $self->$_ } qw(date location_id rolodex_id)
    );
        
    my %MAP = (
        staff => 'eleMentalClinic::Personnel',
        client => 'eleMentalClinic::Client',
    );
    for my $appt ( @$list ) {
        while ( my ( $key, $object ) = each %MAP ) {
            $appt->{ $key } = $object->retrieve( $appt->{ $key . "_id" });
        }
    }

    if ( $self->user or $self->group eq 'Staff' ) {
        my $out = [];
        my $staff_list = $self->user
            ? [ $self->user ]
            : [ map { $_->{staff} } @$list ];

        my %seen;
        for my $staff ( @$staff_list ) {
            next if $seen{ $staff->staff_id }++;
            push @$out => {
                staff => $staff,
                list => [ grep { $_->{staff_id} == $staff->staff_id } @$list ],
            }
        }
        return $out;
    }

    return [{
        staff => { name => 'All Staff' },
        list => $list,
    }];
}

__PACKAGE__->meta->make_immutable;
1;
