package eleMentalClinic::Mail::Template;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Mail::Template

=head1 SYNOPSIS

Template for e-mail.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Mail;
use Data::Dumper;
use Template;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'email_templates' }
    sub fields {[ qw/ rec_id name subject message subject_attach message_attach clinic_attach / ]}
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 mail()
Optional Parameter:
{
    subject => 'This will be attached to the subject if subject_attach is set',
    message => 'This will be attached to the message is message_attach is set',
}

Object method.

Returns a mail object built from this template

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub mail {
    my $self = shift;
    my ( $params ) = @_;

    my $subject = $self->subject;
    if ( $params->{ subject } and $self->subject_attach ) {
        $subject = "$subject " . $params->{ subject } if ( $self->subject_attach > 0 );
        $subject = $params->{ subject } . " $subject" if ( $self->subject_attach < 0 );
    }

    my $message = $self->message;
    if ( $params->{ message } and $self->message_attach ) {
        $message = "$message " . $params->{ message } if ( $self->message_attach > 0 );
        $message = $params->{ message } . " $message" if ( $self->message_attach < 0 );
    }

    $message .= "\n" . $self->config->org_name if $self->clinic_attach;

    return eleMentalClinic::Mail->new({
        subject => $subject,
        body => $message,
    });
}

'eleMental';

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

Copyright (C) 2004-2008 OpenSourcery, LLC

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

=cut

