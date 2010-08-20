# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Access;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type       => 'site',
    label      => 'Confidential Data Access',
    admin      => 0,
    result_isa => ArrayRef,
};

with 'eleMentalClinic::Report::HasDateRange';

has access_by   => (is => 'ro', isa => Str, label => 'Access By');
has access_user => (is => 'ro', isa => Int, label => 'Access User');
has access_type => (is => 'ro', isa => Str, label => 'Access Type');

=head2 access()

Object method.

Parameters:
    {
        access_by   => 'Day'/'Range',
        access_user => 1001,
        access_type => CLASS,
        start_date  => DATE,
        end_date    => DATE,
    }

Returns:
    [
        {
            date => DATE or Range
            items => [
                {
                    staff => STAFF,
                    objects => [
                        {
                            object => OBJECT,
                            name => name, #Human readable 'type: id/name'
                            count => #,
                            session_count => #,
                        },
                        {...}
                    ]
                },
                {...},
            ]
        }
    ]

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub build_result {
    my ($self) = @_;

    # global WHERE stuff.
    my $where_params = [];
    my $where = [];
    my ( $start_date, $end_date ) = ( $self->start_date, $self->end_date);
    my $type = $self->access_type;
    my $user = $self->access_user;
    if ( $start_date ) {
        push( @$where, "logged >= ?" );
        push( @$where_params, $start_date );
    }
    if ( $end_date ) {
        push( @$where, "logged <= ?" );
        push( @$where_params, $end_date );
    }
    if ( $user ) {
        push( @$where, "staff_id = ?" );
        push( @$where_params, $user );
    }
    if ( $type ) {
        push( @$where, "object_type = ?" );
        push( @$where_params, $type );
    }
    # end global WHERE

    my $access_by = $self->access_by || 'None';
    my $date_list = ( $access_by eq 'Day' )
        ? $self->access_list_from_field( 'DATE(logged)', $where, $where_params )
        : [ '_NONE_' ];
    my $staff_list = $self->access_list_from_field( 'staff_id', $where, $where_params );

    my $out = [];
    for my $date ( @$date_list ) {
        $date = undef if $date eq '_NONE_';
        my $items = [];
        for my $staff ( @$staff_list ) {
            next unless $staff; #we do not care when the staff is empty, from tests.
            my $objects = $self->access_get_objects( $staff, $date, $where, $where_params, $type );
            push( @$items, {
                staff => eleMentalClinic::Personnel->retrieve( $staff ),
                objects => $objects,
            }) if @$objects;
        }
        my $date_label = $date;
        unless ( $date_label ) {
            $date_label = "$start_date through $end_date" if ( $start_date and $end_date );
            $date_label ||= "Everything up to $end_date" if $end_date;
            $date_label ||= "Everything after $start_date" if $start_date;
            $date_label ||= "All History";
        }
        push( @$out, {
            date => $date_label,
            items => $items,
        });
    }
    return $out;
}

sub access_get_objects {
    my $self = shift;
    my ( $staff, $date, $orig_where, $orig_params, $only_type ) = @_;
    $orig_where ||= [];
    $orig_params ||= [];
    my $table = eleMentalClinic::Log::Access->table;
    my $out = [];

    my $where = [ @$orig_where, 'staff_id = ?' ];
    my $params = [ @$orig_params, $staff ];
    if ( $date ) {
        push( @$where, "DATE(logged) = ?" );
        push( @$params, $date );
    }

    my $type_list = $only_type
        ? [ $only_type ]
        : $self->access_list_from_field( 'object_type', $where, $params );

    for my $type ( @$type_list ) {
        my $ids = $self->access_list_from_field(
            'object_id',
            [ @$where, 'object_type = ?' ],
            [ @$params, $type ]
        );
        for my $id ( @$ids ) {
            my $results = $self->db->do_sql(
                "SELECT COUNT(rec_id) AS total, COUNT(from_session) AS session FROM $table WHERE "
                  . join( ' AND ', @$where, 'object_type = ?', 'object_id = ?' ),
                undef,
                @$params, $type, $id
            )->[0];
            my $object = $type->retrieve( $id );
            my $name = $type;
            $name =~ s/^.*::([^:]*)$/$1: /g;
            $name .= ($object->can( 'name' )) ? $object->name : $object->id;
            push( @$out, {
                object        => $object,
                name          => $name,
                count         => $results->{ total },
                session_count => $results->{ session },
            });
        }
    }
    return $out;
}

sub access_list_from_field {
    my $self = shift;
    my ( $field, $where, $params ) = @_;
    $where ||= [];
    $params ||= [];
    my $table = eleMentalClinic::Log::Access->table;

    my $query = "SELECT DISTINCT $field FROM $table";
    $query .= " WHERE " . join( ' AND ', @$where ) if ( @$where );
    $query .= " ORDER BY $field";

    my $results = $self->db->do_sql(
        $query,
        undef,
        @$params
    );

    return [ map { values %$_ } @$results ];
}


__PACKAGE__->meta->make_immutable;
1;
