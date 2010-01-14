# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::SecurityLog;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Security',
    admin => 0,
    result_isa => ArrayRef,
};

with 'eleMentalClinic::Report::HasDateRange';

has sort => (is => 'ro', isa => Str, default => 'ASC');
has order => (is => 'ro', isa => Str, default => 'logged');
has access_user => (is => 'ro', isa => Str);

has actions => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [ qw(login logout) ] }
);

=head2 security_log()

Object method.

Parameters:
    {
        start_date  => DATE,
        end_date    => DATE,
        access_user => LOGIN,
        actions     => ACTIONS,
        sort        => ASC, DESC (by date)
        order       => FIELD,
    }

Returns:
    [
        {
            name => RESULT->{ ORDER_FIELD },
            list => [
                {
                    logged => 'YYYY-MM-DD HH:MM:SS',
                    login  => 'Login Username',
                    action => 'login'/'logout'/'failure',
                    rec_id => 'entry id',
                },
                {...},
            ]
        },
        {...},
    ]


=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub build_result {
    my ($self) = @_;

    my $sort = $self->sort;
    my $order = $self->order;
    my $start_date = $self->start_date;
    my $end_date = $self->end_date;
    my $user = $self->access_user;
    $user = undef if $user and $user eq 'All Users';
    my $actions = $self->actions;
    my $table = eleMentalClinic::Log::Security->table;

    my $where = [];
    my $params = [];
    if ( $start_date ) {
        push( @$where, "logged >= ?" );
        push( @$params, $start_date );
    }
    if ( $end_date ) {
        push( @$where, "logged <= ?" );
        push( @$params, $end_date );
    }
    if ( $user ) {
        push( @$where, "login = ?" );
        push( @$params, $user );
    }
    if ( $actions ) {
        $actions = [ $actions ] unless ref $actions;
        my $lwhere = [];
        for my $act ( @$actions ) {
            push( @$lwhere, "action = ?" );
            push( @$params, $act );
        }
        push( @$where, '( ' . join( ' OR ', @$lwhere ) . ' )' );
    }
    my $query = "SELECT * FROM $table";
    $query .= ' WHERE ' . join( ' AND ', @$where ) if ( @$where );
    $query .= "ORDER BY login $sort, logged $sort, action $sort";
    my $results = $self->db->do_sql( $query, undef, @$params );
    my $sets = {};
    for my $result ( @$results ) {
        $result->{ action } = 'Failed Login Attempt' if $result->{ action } eq 'failure';
        # We do not need milisecond precision.
        $result->{ logged } =~ s/\..*//g;
        my $set = $result->{ $order };
        # Divide date sets by date, not time!
        $set =~ s/\s.*//g if ( $order eq 'logged' );
        $sets->{ $set } ||= [];
        push( @{ $sets->{ $set }}, $result );
    }
    my $out = [];
    while ( my ( $key, $value ) = each %$sets ) {
        push( @$out, { name => $key, list => $value });
    }
    return [ sort { $a->{ name } cmp $b->{ name } } @$out ];
}



__PACKAGE__->meta->make_immutable;
1;
