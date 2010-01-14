package eleMentalClinic::Mail;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Mail

=head1 SYNOPSIS

Simple e-mail message object

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub fields {[ qw/ rec_id sender_id subject body send_date / ]}
sub methods {[ qw/ recipients / ]}
sub table { 'email' }
sub primary_key { 'rec_id' }
sub accessors_retrieve_many {
    {
        stored_recipients => { email_id => 'eleMentalClinic::Mail::Recipient' },
    };
}

our $NOSEND = 0;
sub disable_send {
    $NOSEND = 1;
}

sub enable_send {
    $NOSEND = 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 header()

Object method.

generate the e-mail header

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub header {
    my $self = shift;
    my $header;

    return unless $self->subject       #Need a subject
              and $self->recipients;   #Need at least one recipient

    $header = "From: " . $self->config->send_mail_as . "\n";
    $header .= "Subject: " . $self->subject . "\n";
    $header .= "To: " . join(', ', map { 
        ( $_ =~ m/\@/ ) ? $_ : eleMentalClinic::Client->retrieve( $_ )->email
    } @{ $self->recipients }) . "\n";
    
    return $header;
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 message()

Object method.

Generate an email message that can be passed to sendmail.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub message {
    my $self = shift;
    my $header = $self->header;
    my $body = $self->body;
    return unless $header and $body;
    return "$header\n$body"; #Header and body should be seperated by a newline.
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 send()

Object method.

Use the 'sendmail' program to send the email message.

All parameters will be considered recipients.
Recipients must be in the form of client_id

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub send {
    my $self = shift;
    # Each send should be it's own email object.
    if ( $self->send_date || $self->rec_id ) {
        my $new_self = eleMentalClinic::Mail->new({ %$self, rec_id => undef, send_date => undef });
        # Modify the object being referenced so that whatever called send has the proper object.
        %$self = %$new_self;
    }
    $self->recipients( [ @_ ] );

    my $message = $self->message;
    return unless $message;

    return $self->_save if ( $NOSEND );
    if ( open( MAIL, "|sendmail -t" ) ) {
        print MAIL $message;
        close( MAIL );
        return $self->_save;
    }
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub save {
    # Mail objects are a record of an outgoing email, as such only send should
    # save them. Thats the only way to guarentee a stored mail object is a
    # record of a SENT email.
    croak( "Save should never be called directly on a mail object!" );
}

sub _save {
    my $self = shift;
    return unless $self->SUPER::save( @_ );
    foreach my $recp ( @{ $self->recipients || [] }) {
        my $recipient = eleMentalClinic::Mail::Recipient->new({
            (($recp =~ m/\@/) ? 'email_address' : 'client_id' ) => $recp,
            email_id => $self->id,
        });
        return unless $recipient->save;
    }
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub date {
    my $self = shift;
    my ( $date ) = split( ' ', $self->send_date );
    return $date;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub htmlbody {
    my $self = shift;
    my $body = $self->body;
    $body =~ s/\n/<br \/>/g;
    return $body;
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2007 OpenSourcery, LLC

This file is part of eleMental Clinic.

eleMental Clinic is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option) any
later version.

eleMental Clinic is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

eleMental Clinic is packaged with a copy of the GNU General Public License.
Please see docs/COPYING in this distribution.
