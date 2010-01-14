package eleMentalClinic::Log::Security;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Log::Security

=head1 SYNOPSIS

Security Log Entry

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'security_log' }
    sub fields { [ qw/ rec_id logged login action /] }
    sub primary_key { 'rec_id' }
}

#    type => 'TYPE', # security, access
#    user => ... # Login username string, or a personnel object
#    action => 'ACTION', # load, reload, login, logout, failure
#    object => OBJECT, #The actual object if this is an access log.
sub update_from_log {
    my $self = shift;
    my ( $args ) = @_;
    my $user = $args->{ user };
    $user = $user->login if ref $user;
    $user ||= "(NO LOGIN)";
    $self->login( $user );
    $self->action( lc( $args->{ action }));
    $self->logged( $args->{ logged }) if $args->{ logged };
    $self->save;
    return $self;
}

'eleMental';
