package eleMentalClinic::Rolodex::HasByState;

use Moose::Role;

requires("id");

use eleMentalClinic::Rolodex::ByState;
my $By_State_Class = 'eleMentalClinic::Rolodex::ByState';

use Carp;


=head1 NAME

eleMentalClinic::Rolodex::HasByState - Access per state information for rolodex entries

=head1 SYNOPSIS

    package Rolodex::Thing;

    use eleMentalClinic::Util;
    with_moose_role("eleMentalClinic::Rolodex::HasByState");

=head1 DESCRIPTION

This role provides a rolodex object with the means to get and add per state information.

=head1 REQUIRES

A user of this role must implement...

=head3 rec_id

Return the primary key of the rolodex item

=head1 METHODS

=head3 by_state

    my $info = $rolodex->by_state($state);

Get per-state information for the $rolodex.

Returns it as an eleMentalClinic::Rolodex::ByState object.

=cut

sub by_state {
    my $self = shift;
    my $state = shift || croak "by_state() requires a state";

    my $data = $self->db->select_one(
        $By_State_Class->fields,
        $By_State_Class->table,
        [ "rolodex_id = ? AND state = ?" => $self->id, $state ],
    );

    return undef unless $data;
    return $By_State_Class->new($data);
}


=head3 add_by_state

    $rolodex->add_by_state($state, $data);

Add per state information.  $data is a hash of information to be stored by state.

Returns the new eleMentalClinic::Rolodex::ByState object.

=cut

sub add_by_state {
    my $self = shift;
    my($state, $data) = @_;

    my $by_state = $By_State_Class->empty({
        rolodex_id => $self->id,
        state      => $state,
        %$data
    });

    $by_state->save;
    return $by_state;
}


=head3 all_by_state

    my $all_states = $rolodex->by_state_all;

Return all information for the $rolodex as a hash, keyed by state,
values are eleMentalClinic::Rolodex::ByState objects.

=cut

sub all_by_state {
    my $self = shift;

    my $states = $self->db->select_many(
        $By_State_Class->fields,
        $By_State_Class->table,
        [ "rolodex_id = ?" => $self->id ]
    );

    my $all = {};
    for my $state (@$states) {
        $all->{$state->{state}} = $By_State_Class->new($state);
    }

    return $all;
}


=head1 EXAMPLES

=head2 Removing per state information

Retrieve and delete the offending ByState object.

    $rolodex->by_state($state)->delete;

=head2 Changing per state information

Retrieve, alter, and save the ByState object.

    my $by_state = $rolodex->by_state($state);
    $by_state->license(12345);
    $by_state->save;


=head1 SEE ALSO

L<eleMentalClinic::Rolodex::ByState>

=cut

1;
