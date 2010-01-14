package eleMentalClinic::ECS::DialUp;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::ECS::DialUp

=head1 SYNOPSIS

Handles sending and receiving files for EDI over dial-up.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::ECS::Connection /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub methods {
        [ qw/ baud_rate serial_port init_string 
              dial_wait_seconds at_eol modem log / ]
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 defaults

Sets core object properties, unless they have already been set.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub defaults {
    {
        baud_rate           => "38400",
        init_string         => "AT S7=45 S0=0 L1 V1 X4 &c1 E1 Q0",
        dial_wait_seconds   => 60,
        at_eol              => "\r",
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 init( $args[, $options] )

Object method.

Initializes the object, sets properties based on passed parameters and sets
defaults for unset properties.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub init {
    my $self = shift;
    my( $args, $options ) = @_;

    $self->SUPER::init( $args, $options );

    $self->serial_port( $self->config->modem_port );

    my %defaults = %{ &defaults };
    while( my( $key, $value ) = each %defaults ) {
        defined $args->{ $key }
            ? $self->$key( $args->{ $key })
            : $self->$key( $value );
    }

    eval { require Device::Modem; import Device::Modem; };
    if( $@ =~ /Can't locate Device\/Modem.pm in \@INC/ ){
        $self->append_log( "Unable to connect to modem: missing Perl library Device/Modem.pm.\n" );
        warn q/Can't locate Device\/Modem.pm in @INC - running ECS::Dialup with stub methods/
            unless $eleMentalClinic::Base::TESTMODE > 0;
    }
    else {
        $self->modem( new Device::Modem( port => $self->serial_port ) );
    }

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 connect

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub connect {
    my $self = shift;
    my( $ok, $answer );

    die 'Must have a ClaimsProcessor object' unless $self->claims_processor;

    unless( $self->modem ){
        warn 'connect method stub' unless $eleMentalClinic::Base::TESTMODE > 0;
        return;
    }

    unless( $self->claims_processor->username 
            and $self->claims_processor->password 
            and $self->claims_processor->dialup_number )
    {
        $self->append_log( 'Missing connection details for Dial Up: username, password and/or dialup_number' ); 
        return;
    }
    
    if( $self->modem->connect( baudrate => $self->baud_rate, init_string => $self->init_string ) ) {
        $self->append_log( "Initialized modem\n" );
    } else {
        $self->append_log( "Init modem: Sorry, no connection with serial port (" . $self->serial_port .")! $!\n" ); 
        return;
    }

    # make sure the modem doesn't echo our commands
    $self->modem->echo(0);

    # silence the modem
    $self->modem->atsend( 'ATM0\r' ) # XXX Why doesn't Device::Modem::CR work? Bareword not allowed
        if $self->config->silent_modem;

    my $count = 1;
    do {
        $self->append_log( "Dialing modem, attempt $count\n" );
        ( $ok, $answer ) = $self->modem->dial( $self->claims_processor->dialup_number, $self->dial_wait_seconds );
        $self->append_log( "$answer\n" ) if $answer;
        $count++;
    } while( !$ok and $answer and $answer =~ qr/ERROR/ and $count < 6 );

    unless( $ok ){
        $self->append_log( "Unable to dial modem.  Answer: $answer. Err: $!\n" );
        return;
    }
    $self->append_log( "Modem dialed\n" );
    
    $answer = $self->modem->answer( qr/Logon:/, 20000 );
    unless( $answer =~ qr/Logon:/ ){
        $self->append_log( "Timed out without Logon: response. Response:\n" );
        $self->append_log( "$answer" ) if $answer;
        return;
    }
    $self->append_log( "$answer\n" );

    $self->append_log( "Logging in\n" );
    $self->modem->atsend( $self->claims_processor->username . $self->at_eol );

    $answer = $self->modem->answer( qr/Password:/, 5000 );
    unless( $answer =~ qr/Password:/ ){
        $self->append_log( "Timed out without Password: response. Response: $answer" );
        return;
    }
    $self->append_log( "$answer\n" );

    $self->modem->atsend( $self->claims_processor->password . $self->at_eol );

    # Check that the login succeeded   
    $answer = $self->modem->answer( qr/Last Successful Login Date:/, 5000 );
    unless( $answer =~ qr/Last Successful Login Date:/ ){
        $self->append_log( "Unsuccessful Login. Response: $answer" );
        return;
    }
    $self->append_log( "$answer\n" );

    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 disconnect

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub disconnect {
    my $self = shift;

    unless( $self->modem ){
        warn 'disconnect method stub' unless $eleMentalClinic::Base::TESTMODE > 0;
        return;
    }

    $self->append_log( "Disconnecting modem\n" );
    $self->modem->atsend( 'lo' . $self->at_eol ); # lo = Logoff in EDISS BBS menu
    $self->modem->hangup;
    return $self->modem->disconnect;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 put_file( $filename )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub put_file {
    my $self = shift;
    my( $filename ) = @_;
    my $answer;

    die 'Filename is required' unless $filename;
    die 'Must have a ClaimsProcessor object' unless $self->claims_processor;

    unless( $self->modem ){
        warn 'put_file method stub' unless $eleMentalClinic::Base::TESTMODE > 0;
        return;
    }

    die 'Unable to connect with dial-up' unless $self->connect;

    $self->append_log( "Asking BBS to send files\n" );
    $self->modem->atsend( '1' . $self->at_eol ); # 1 = Transmit files in EDISS BBS menu

    $answer = $self->modem->answer( qr/rz/, 10000 );
    unless( $answer =~ qr/rz/ ){
        $self->append_log( "Timed out without seeing 'rz' response. Response:\n" );
        $self->append_log( "$answer\n" ) if $answer;
        die 'Connected to dial-up, but unable to start sending file. Login may have failed.';
    }

    $self->append_log( "Sending $filename\n" );
    my $serial_port = $self->serial_port;
    my $send_results = `sz $filename 2>&1 0<> $serial_port 1>&0`;

    if( $? ){
        $self->append_log( "Failed sz. Child Error: $?\nstd_err output:\n $send_results\n" );
        die 'Connected to dial-up, but unable to complete sending the file';
    }
    $self->append_log( "$send_results\nFinished sending.\n" );
    $self->modem->atsend( $self->at_eol );
   
    my $result = "Successfully sent billing file.\n"; # XXX this string used in controller to determine successful submission

    # Fetch the files that come in response -
    chdir $self->config->edi_in_root;

    # Make sure we receive at least 3 files. If not, sleep for a sec and try again.
    my @received_files;
    my $count = 1;
    do {
        sleep( 1 );
        $self->modem->atsend( '2' . $self->at_eol ); # 2 = Receive undelivered files in EDISS BBS menu

        $self->append_log( "Looking for 3 files in response.\n" );
        my( $files, $receive_files_result ) = $self->receive_files;
        $result .= " Receiving files, attempt $count: $receive_files_result";
        unless( defined $files ){
            $self->disconnect;
            return( \@received_files, $result );
        }
        push @received_files => @$files; 
      
    } while( @received_files < 3 and $count++ < 2);

    $self->disconnect;
    return ( \@received_files, $result );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_new_files

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_new_files {
    my $self = shift;

    die 'Must have a ClaimsProcessor object' unless $self->claims_processor;

    unless( $self->modem ){
        warn 'get_new_files method stub' unless $eleMentalClinic::Base::TESTMODE > 0;
        return;
    }

    return unless $self->connect;

    $self->modem->atsend( '2' . $self->at_eol ); # 2 = Receive undelivered files in EDISS BBS menu

    chdir $self->config->edi_in_root;

    my( $received_files, $result ) = $self->receive_files;
   
    $self->disconnect;
    return( $received_files, $result );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 receive_files

Object method. Receive files that they will send us.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub receive_files {
    my $self = shift;
    my $answer;
    my @filenames = ();
    my $result = 'Unable to download any files.';

    unless( $self->modem ){
        warn 'receive_files method stub' unless $eleMentalClinic::Base::TESTMODE > 0;
        return;
    }

    # file descriptors: 0 = stdin, 1 = stdout, 2 = stderr
    # so 2>&1 means: send stderr to stdout instead
    # and '0<> file' means: open file descriptor stdin to file in read-write mode
    # and 1>&0 means: send stdout to the same place as stdin

    do {
        $result = 'Unable to download all of the files.' if @filenames > 0;

        $self->append_log( "Receiving a file\n" );
        $answer = $self->modem->answer( qr/start your file transfer|All files processed/, 20000 );
        $self->append_log( "$answer\n" ) if $answer;

        if( $answer and $answer =~ qr/start your file transfer/ ){
            my $serial_port = $self->serial_port;
            my $receive_results = `rz -Z -a 2>&1 0<> $serial_port 1>&0`;
            if( $? ){
                $self->append_log( "Failed rz. Child Error: $?\nstd_err output:\n $receive_results" );
                return( \@filenames, $result );
            }
            $self->append_log( "$receive_results\nFinished Receiving\n" );

            if( $receive_results =~ /Transfer complete/ ){
                $receive_results =~ /Receiving: (.*)\s/;

                my $received;
                eval { $received = $self->record_file_receipt( $1 ); } if $1;
                push @filenames => $received if $received;
                return( \@filenames, "$result " . eleMentalClinic::Log::Log_tee( $@ )) if $@;
            }
        }
        elsif( !$answer or $answer !~ qr/All files processed/ ){
            $self->append_log( "Timed out while waiting to start file transfer. Response:\n" );
            return( \@filenames, $result );
        }

    } until ( $answer =~ qr/All files processed/ );

    $result = @filenames > 0 ? 'All files downloaded.' : 'No new files to download.';
    return( \@filenames, $result );
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Jon Dodson L<jdodson@opensourcery.com>

=item Josh Partlow L<jpartlow@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

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
