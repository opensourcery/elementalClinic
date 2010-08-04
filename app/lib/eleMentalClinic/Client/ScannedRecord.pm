# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Client::ScannedRecord;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::ScannedRecord

=head1 SYNOPSIS

A record of a scanned in medical record file.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Util;
use Data::Dumper;
use File::Copy;
use File::Spec;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    use constant DEFAULT_GET_OLDEST_FILES => 20;

    sub table  { 'client_scanned_record' }
    sub fields { [ qw/
        rec_id client_id filename description created created_by
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_oldest_file

    my $file = $class->get_oldest_file;

Returns the oldest files in the scanned_record_root.

=head2 get_oldest_files

    my $files = $class->get_oldest_files;
    my $files = $class->get_oldest_files($howmany);

Returns the oldest files in the scanned_record_root.  Its limited to
$howmany or 25.

If there are no files it will return an empty array ref.

=cut

sub get_oldest_files {
    my $class = shift;
    my $howmany = shift || DEFAULT_GET_OLDEST_FILES;

    my $filepath = quotemeta $class->config->scanned_record_root;
  
    # look at all files, sort by oldest first
    # *.* will not pick up any files starting with dot
    my @files = map  { s/.*\/(.*)/$1/; $_ }  # strip off the leading path
                sort { -M $b <=> -M $a } <$filepath/*.*>;

    # Return only $howmany
    return [grep { defined $_ } @files[0..$howmany-1]];
}

sub get_oldest_file {
    my $class = shift;
    return $class->get_oldest_files(1)->[0];
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_history()

Class method. Returns the last 4 files associated, and their client names
and date associated.

=cut

# why doesn't this just get the last 4 actual records, instead of selecting
# part of the table and using a hashref?
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_history {
    my $class = shift;

    my $files = $class->db->select_many(
        [ qw/ client_id rec_id filename created /],
        $class->table,
        '',
        'ORDER BY created DESC LIMIT 4'
    );

    my @history;
    for my $file ( @$files ){
    
        my $client = eleMentalClinic::Client->retrieve( $file->{ client_id } );
        $file->{ client_name } = $client->name;
        push @history => $file;
    }

    return \@history;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_byclient( $client_id )

Class method. Gets a list of records for the client id.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_byclient {
    my $class = shift;
    my( $client_id ) = @_;
    return unless $client_id;

    return unless my $hashrefs = $class->new->db->select_many(
        $class->fields,
        $class->table,
        "WHERE client_id = $client_id",
        'ORDER BY rec_id'
    );

    my @results;
    push @results => $class->new( $_ ) for @$hashrefs;
    return \@results;
}

=head2 path
  
    my $path = $record->path;

Returns the full path to this file.

=cut

sub path {
    my $self = shift;
    return File::Spec->catfile(
        $self->client_id
        ? (
            $self->config->stored_record_root,
            'client' . $self->client_id,
        )
        : $self->config->scanned_record_root,
        $self->filename,
    );
}

=head2 mime_type

    print $record->mime_type; # image/jpg

Returns the MIME type of this file.

=cut

sub mime_type {
    my $self = shift;
    # XXX use File::MMagic or something?
    my $type = ($self->filename =~ /\.([^.]+)$/)[0];
    return $type;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 associate

Object method. Create a new record associating a client with a file.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub associate {
    my $self = shift;

    die 'client_id is required' unless $self->client_id;
    die 'filename is required' unless $self->filename;

    $self->created( $self->timestamp ) unless $self->created;
    
    my $old_file = $self->config->scanned_record_root . '/' . $self->filename;
    die "File $old_file does not exist" unless -f $old_file;

    # check if it's already in the database: send an error in case the file is different but has the same name
    my $client = $self->get_client_by_filename;
    if( $client ) {
        die 'A file with that name is already associated with ' . $client->name . ', client ' . $client->client_id;
    }

    $self->save or die "Saving client_scanned_record failed: $!";

    eval {
        # make a new directory if needed
        my $store_dir = $self->config->stored_record_root . '/client' . $self->client_id;
        unless( -d $store_dir ) {
            mkdir $store_dir or die "Mkdir of $store_dir failed: $!";
        }

        # move to the new directory
        my $moved_file = $store_dir . '/' . $self->filename;
        move( $old_file, $moved_file ) or die "Move of file $old_file failed: $!";
    };
    if( $@ ){
       
        # if there were errors while trying to remove the file, remove the database record we just created
        $self->db->delete_one( $self->table, 'rec_id = ' . $self->rec_id );
        die $@;
    }
    
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 disassociate()

Object method. Removes the record in the database for this object.
Moves the file back into the scanned_record_root.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub disassociate {
    my $self = shift;

    die 'record is not associated' unless $self->rec_id;
    die 'record is missing client_id' unless $self->client_id;

    my $old_file = $self->config->stored_record_root . '/client' . $self->client_id . '/' . $self->filename;
    die "File $old_file does not exist" unless -f $old_file;

    $self->db->transaction_do(sub {
        $self->db->delete_one( $self->table, 'rec_id = ' . $self->rec_id );
        
        # move back to the scanned_record_root
        my $moved_file = $self->config->scanned_record_root . '/' . $self->filename;
        move( $old_file, $moved_file ) or die "Move of file $old_file failed: $!";
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 invalid_file( $filename )

Class method. Moves the file from the scanned file directory to the invalid file directory.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub invalid_file {
    my $class = shift;
    my( $filename ) = @_;
    
    die 'filename is required' unless $filename;
    
    my $invalid = $class->config->scanned_record_root . '/' . $filename;
    die "file doesn't exist" unless -f $invalid;
  
    my $moved_file = $class->config->invalid_scanned_record_root . '/' . $filename;
    move( $invalid, $moved_file ) or die "Move of file $invalid failed: $!";
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_client_by_filename( $filename )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_client_by_filename {
    my $self = shift;

    die 'filename is required' unless $self->filename;

    my $client = $self->db->select_one(
        [ 'client.*' ],
        'client, client_scanned_record',
        [
            "filename = ?
                AND client.client_id = client_scanned_record.client_id",
            $self->filename
        ],
        'ORDER BY client_id'
    );
    return unless $client;
    return eleMentalClinic::Client->new( $client );
}

'eleMental';

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
