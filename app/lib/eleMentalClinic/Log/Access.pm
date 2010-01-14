package eleMentalClinic::Log::Access;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Log::Access

=head1 SYNOPSIS

Access Log Entry

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'access_log' }
    sub fields { [ qw/ rec_id logged from_session object_id object_type staff_id /] }
    sub primary_key { 'rec_id' }
}

#    type => 'TYPE', # security, access
#    user => ... # Login username string, or a personnel object
#    action => 'ACTION', # load, reload, login, logout, failure
#    object => OBJECT, #The actual object if this is an access log.
sub update_from_log {
    my $self = shift;
    my ( $args ) = @_;

    $self->from_session( 1 ) if $args->{ action } eq 'reload';
    $self->logged( $args->{ logged }) if $args->{ logged };

    my $user = $args->{ user };
    $self->staff_id( $user->id ) if $user;

    # id and type can be used as well ass just object
    my $object = $args->{ object };
    $self->object_id( $object->id );
    $self->object_type( ref $object );

    $self->save;
    return $self;
}

'eleMental';
