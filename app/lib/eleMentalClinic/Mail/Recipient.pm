package eleMentalClinic::Mail::Recipient;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Mail::Recipient

=head1 SYNOPSIS

Email Recipient

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::Client;
use eleMentalClinic::Mail;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub fields { [ qw/ rec_id email_id client_id email_address / ] }
sub table { 'email_recipients' }
sub primary_key { 'rec_id' }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 client()

Object method.

Returns the recipient client object.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub client {
    my $self = shift;
    return unless $self->client_id;
    return eleMentalClinic::Client->retrieve( $self->client_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 mail()

Object method.

Returns the Mail object.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub mail {
    my $self = shift;
    return eleMentalClinic::Mail->retrieve( $self->email_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 address()

Object method.

returns the recipients e-mail address.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub address {
    my $self = shift;
    return $self->email_address || $self->client->email;
}

'eleMental';
