package eleMentalClinic::Controller::Base::Admin;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Admin

=head1 SYNOPSIS

Base Admin Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Config;
use eleMentalClinic::Mail::Template;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->security( 'admin' );
    $self->template->vars({
        styles => [ 'admin' ],
        script => 'admin.cgi',
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        configuration => {},
        save_configuration => {
            -alias  => [ 'Save configuration' ],
            edit_prognote       => [ 'edit_prognote', 'required', 'length(1)' ],
            form_method         => [ 'form_method', 'required', 'text::word' ],
            logout_inactive     => [ 'logout_inactive', 'required', 'number::integer' ],
            logout_time         => [ 'logout_time', 'required', 'number::integer' ],
            org_name            => [ 'org_name', 'required' ],
            org_zip             => [ 'Zip code', 'number::integer' ],
            org_state           => [ 'State', 'demographics::us_state2' ],
            prognote_max_duration_minutes   => [ 'prognote_max_duration_minutes', 'required', 'number::integer' ],
            prognote_min_duration_minutes   => [ 'prognote_min_duration_minutes', 'required', 'number::integer' ],
            org_national_provider_id => [ 'National Provider ID', 'text', 'length(2,80)' ],
            org_tax_id => [ 'Tax ID', 'text', 'length(2,30)' ],
            org_medicaid_provider_number => [ 'Medicaid Provider ID', 'text', 'length(2,30)' ],
            org_medicare_provider_number => [ 'Medicare Provider ID', 'text', 'length(2,30)' ],
            silent_modem => [ 'Silent Modem', 'checkbox::boolean' ],
            send_mail_as => [ "Send As", 'email' ],
            send_errors_to => [ "Send errors to", 'email' ],
            password_expiration_days => [ "Password Expiration Days", 'number::integer' ],
            appointment_notification_days => [ 'Appointment Notification Interval', 'number::positive_list' ],
            renewal_notification_days => [ 'Renewal Notification Interval', 'number::positive_list' ],
            enable_role_reports => [ 'Reports Security', 'checkbox::boolean' ],
            quick_schedule_availability =>
                [ 'Quick Schedule Availability', 'checkbox::boolean' ],
       },
       send_test => {
           -alias => [ 'Send Test' ],
           -on_error => 'save_configuration',
           send_mail_as => [ "Send As", 'email', 'required' ],
           send_test_to => [ "Send Test", 'email', 'required' ],
       },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    return {};
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub send_test {
    my $self = shift;

    if( $self->_save ) {
        my $testmsg = eleMentalClinic::Mail::Template->retrieve(
            eleMentalClinic::Config->new->default_mail_template
        );
        my $msg_mail = $testmsg->mail({
            subject => 'Test Message from EMC',
            message => 'This is a test message from EMC.',
        });
        $msg_mail->sender_id( $self->current_user->staff_id );
        $msg_mail->config->send_mail_as( $self->param( 'send_mail_as' ));
        $msg_mail->send( $self->param( 'send_test_to' ));
    }

    return $self->configuration;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub configuration {
    my $self = shift;

    my %vars;
    $vars{ rolodexes } = $self->get_rolodexes;
    $vars{ mailtemplates } = $self->get_templates;
    $self->override_template_name( 'config' );
    return { %vars };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_configuration {
    my $self = shift;

    $self->_save;

    return $self->configuration;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _save {
    my $self = shift;

    return eleMentalClinic::Config->new->save({ $self->Vars })
        unless $self->errors;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_rolodexes {
    my $self = shift;
    return eleMentalClinic::Rolodex->new->get_byrole( 'mental_health_insurance' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_templates {
    my $self = shift;
    my ( $type ) = @_;
    return eleMentalClinic::Mail::Template->get_all;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

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
