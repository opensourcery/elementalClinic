package eleMentalClinic::Controller::Base::Error;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Error

=head1 SYNOPSIS

Error Controller.

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
    $self->template->vars({
        styles => [ 'error_page' ],
        script => 'error.cgi',
        javascripts => [ 'jquery.js', 'error_page.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        retrieve => {
          exception => [ 'Exception', 'required' ],
        },
        send_report => {
          -alias => 'Submit Report'
        }
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub retrieve {
    my $self = shift;
    $self->ajax(1);
    my $data = $self->obfuscate( $self->exception, 1 );
    return $data;
}

sub home {
    my $self = shift;

    return {
        exceptions => $self->exceptions,
        cgi_params => $self->validop->Vars || {},
    };
}

sub send_report {
    my $self = shift;
    $self->override_template_name( 'sent' );

    my $recipient = $self->config->send_errors_to;
    unless ( $recipient ) {
        return {
            message => "Error reporting email address is not configured. Before you can send email reports you must configure this address on the Administration->Configuration page."
        }
    }

    my $sendable = $self->param( 'send' ) || [];
    $sendable = [ $sendable ] unless ref $sendable eq 'ARRAY';
    my $obfuscate = $self->param( 'obfuscate' ) || [];

    my $Vars = $self->validop->Vars;
    my $param_keys = [ grep {  m/^sent_var_/ } keys %{ $Vars } ];
    my $params = { map { m/^sent_var_(.*)$/; $1 => $Vars->{ $_ }} @$param_keys };

    my $body = "Clinic Info:\n";
    $body .= "Name: " . $self->config->org_name . "\n";
    $body .= "City: " . $self->config->org_city . "\n";
    $body .= "Address: " . $self->config->org_street1 . "\n";
    $body .= "Address: " . $self->config->org_street2 . "\n";
    $body .= "zip: " . $self->config->org_zip . "\n";
    $body .= "Clinician:\n";
    for my $field ( qw/ staff_id unit_id dept_id login fname mname lname name_suffix job_title / ) {
        $body .= "$field: " . $self->current_user->$field . "\n";
    }
    $body .= "\n";
    $body .= "=" x 80;
    $body .= "\nParams:\n" . Dumper( $params );
    for my $err ( @$sendable ) {
        $body .= "\n";
        $body .= "=" x 80;
        $body .= "\n";
        $body .= $self->exception( $err );
    }

    $body = $self->obfuscate( $body );

    my $mail = eleMentalClinic::Mail->new({
        subject => 'eleMentalClinic Error Report',
        body => $body,
    });

    $mail->sender_id( $self->current_user->staff_id );
    $mail->send( $recipient );

    return {
        body => $body,
    }
}

sub exceptions {
    my $self = shift;
    my $exception_list = $self->param( 'exceptions' )
                      || $self->catalyst_c->stash->{ _cgi_exceptions }
                      || [];
    $exception_list = [ $exception_list ] unless ref $exception_list eq 'ARRAY';
    return [ map { $self->strip_report_path( $_ ) } @$exception_list ];
}

sub exception {
    my $self = shift;
    my ( $file ) = @_;
    $file ||= $self->param( 'exception' );
    return unless $file;
    return $self->read_report( $file );
}

sub strip_report_path {
    my $self = shift;
    my ( $file ) = @_;
    my $path = eleMentalClinic::Log::ExceptionReport->report_path;
    $file =~ s/^\Q$path\E\/*//;
    return $file;
}

sub add_report_path {
    my $self = shift;
    my ( $file ) = @_;
    my $path = eleMentalClinic::Log::ExceptionReport->report_path;

    return $file if $file =~ m/^\Q$path\E/;

    $path .= "/" unless $path =~ m/\/$/;

    return $path . $file;
}

sub read_report {
    my $self = shift;
    my ( $file ) = @_;
    $file = $self->add_report_path( $file );
    open( my $fh, "<", $file ) || die( "Could not open report ($file) $!\n" );
    my @report = <$fh>;
    close( $fh );
    return join( '', @report );
}

sub obfuscate {
    my $self = shift;
    my ( $report, $html ) = @_;

    my $obfuscate = $self->param( 'obfuscate' ) || [];
    $obfuscate = [ $obfuscate ] unless ref $obfuscate eq 'ARRAY';

    #Shortest obfuscations first to catch instances where somethign was already
    #partially obfuscated.
    $obfuscate = [ sort { length($a) <=> length($b) } @$obfuscate ];

    my $out = $report;
    $out =~ s/(\S+)/$self->_obfuscate_string($1, $obfuscate, $html)/eg;
    return $out;
}

sub _obfuscate_string {
    my $self = shift;
    my ( $string, $obfuscate, $html ) = @_;
    return $string unless $string;
    return $string if $string =~ m/^[\s\n]+$/;


    #do not obfuscate module names or paths.
    return $string if $string =~ m/\:\:/ || ($string =~ m,/, && $string =~ m/\.pm\W*$/);

    if ( @$obfuscate ) {
        my @matches;
        for my $obfu ( @$obfuscate ) {
            push @matches => ($string =~ m/\Q$obfu\E/ig);
        }
        for my $match ( @matches ) {
            my $replace = $match;
            $replace =~ s/[A-Z]/X/g;
            $replace =~ s/[a-z]/x/g;
            $replace =~ s/\d/0/g;
            $string =~ s/$match/$replace/g;
        }
    }
    #       String contains alpha-numerics
    if ( $string =~ m/[A-WYZ1-9]/i && $html) {
        return '<span class="obfuscatable">' . $string . '</span>';
    }
    elsif ( $string =~ m/[X0]/i && $html ) {
        return '<span class="obfuscated">' . $string . '</span>';
    }
    return $string;
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

Copyright (C) 2004-2009 OpenSourcery, LLC

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
