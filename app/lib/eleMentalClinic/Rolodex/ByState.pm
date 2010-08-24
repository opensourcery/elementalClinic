package eleMentalClinic::Rolodex::ByState;

use Moose;
extends 'eleMentalClinic::DB::Object';


=head1 NAME

eleMentalClinic::Rolodex::ByState - Store per state information for rolodex entries

=cut

# emc::DB::Object configuration
sub table { 'by_state' }
sub fields {
    return [qw{
        rec_id
        state
        rolodex_id
        license
    }];
}
sub primary_key { 'rec_id' }
sub min_schema_required { 443 }

sub save {
    my $self = shift;

    # Force state abbreviations to upper case
    my $state = $self->state;
    $self->state(uc $state) if $state;

    return $self->SUPER::save;
}


=head1 FIELDS

=head3 rec_id

The primary key

=head3 rolodex_id

The rolodex entry this is associated with

=head3 state

The abreviation of the state, usually two letters, all caps.

=head3 license

The license number of the practitioner in a given state.

=cut

1;
