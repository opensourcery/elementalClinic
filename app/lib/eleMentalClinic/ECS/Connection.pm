package eleMentalClinic::ECS::Connection;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::ECS::Connection

=head1 SYNOPSIS

Handles sending and receiving files for EDI.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::ECS::FileDownloaded;
use eleMentalClinic::ECS::SFTP;
use eleMentalClinic::ECS::DialUp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub fields { [ qw/ claims_processor_id /] }
    sub fields_required { [ qw/ claims_processor_id /] }
    sub accessors_retrieve_one { 
        {
            claims_processor => { claims_processor_id => 'eleMentalClinic::Financial::ClaimsProcessor' },
        }
    }
    sub methods {
        [ qw/ log / ]
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub connect  {
        die "You must subclass eleMentalClinic::ECS::Connection and override the 'connect' method.";
    }
    sub disconnect {
        die "You must subclass eleMentalClinic::ECS::Connection and override the 'disconnect' method.";
    }
    sub put_file {
        die "You must subclass eleMentalClinic::ECS::Connection and override the 'put_file' method.";
    }
    sub get_files {
        die "You must subclass eleMentalClinic::ECS::Connection and override the 'get_files' method.";
    }
    sub get_new_files {
        die "You must subclass eleMentalClinic::ECS::Connection and override the 'get_new_files' method.";
    }
    sub list_files {
        die "You must subclass eleMentalClinic::ECS::Connection and override the 'list_files' method.";
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_connection( $claims_processor_id )

Object method.

Returns an SFTP or DialUp object, depending on the claims processor's
settings.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_connection {
    my $self = shift;

    die "Claims Processor's password has expired."
        if $self->claims_processor->password_expired;

    if( $self->claims_processor->sftp_host ) {
        return eleMentalClinic::ECS::SFTP->new( $self );
    }
    elsif( $self->claims_processor->dialup_number ) {
        return eleMentalClinic::ECS::DialUp->new( $self );
    }

    die "No SFTP or dial-up host found for this claims processor.";
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 find_new_files( $files[, $seen_files] )

Class method.

Looks through $files and returns ones that are not in $seen_files.
If $seen_files is undef then will return all $files.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub find_new_files {
    my $class = shift;
    my( $files, $seen_files ) = @_;

    return unless $files;

    my %seen;
    $seen{ $_ } = 1
        for @$seen_files;

    return [ grep { ! $seen{ $_ } } @$files ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 append_log( $string )

Object method.

Appends the $string to $self->log.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub append_log {
    my $self = shift;
    my( $string ) = @_;

    return unless $string;

    my $current = $self->log || '';
    $self->log( $current . $string );

    # add the info to the error log as well
    warn $string unless $eleMentalClinic::Base::TESTMODE > 0;

    return $self->log;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 record_file_receipt( $filename )

Object method. Check that the file was able to be saved (it exists),
and then create a new record in the ecs_file_downloaded table for it. 
Config's edi_in_root is prepended to the filename to find the path.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub record_file_receipt {
    my $self = shift;
    my( $filename ) = @_;

    die 'Unable to save file, filename required.' unless $filename;

    if( open( EDIFILE, $self->config->edi_in_root . "/$filename" ) ){
        close EDIFILE;
        my $record = new eleMentalClinic::ECS::FileDownloaded({ claims_processor_id => $self->claims_processor->id, name => $filename, date_received => $self->timestamp });
        $record->save;
        return $filename;
    }
    else {
        $self->append_log( "Received the file [$filename], but unable to open it ($!). It may not have been saved!\n" );
        die "Received the file, but unable to open it ($!). It may not have been saved!\n";
    }
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

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
