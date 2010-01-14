# vim: ts=4 sts=4 sw=4
package eleMentalClinic::ECS::SFTP;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::ECS::SFTP

=head1 SYNOPSIS

Handles sending and receiving files for EDI over SFTP.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::ECS::Connection /;
use Data::Dumper;
use Net::SFTP::Foreign;
use File::Basename ();
use JSON ();

sub sftp_die { 
    my $self = shift;
    die $self->sftp->error . "\n";
}

sub sftp { $_[0]->{sftp} }

sub connect {
    my $self = shift;
    $self->{sftp} ||= do {
        my %arg = (
            user     => $self->claims_processor->username,
            host     => $self->claims_processor->sftp_host,
            port     => $self->claims_processor->sftp_port,
            password => $self->claims_processor->password,
        );
        unless ( 4 == grep { defined } values %arg ) {
            $self->append_log(
                'Missing connection details for SFTP: '
                . 'username, password, host and/or port'
            ); 
            return undef;
        }
        eleMentalClinic::ECS::SFTP::Helper->new(
            %arg,
            more => [ qw(
                -oStrictHostKeyChecking=no
                -oCheckHostIP=no
                -oUserKnownHostsFile=/dev/null
            ) ],
        );
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 put_file( $filename )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub put_file {
    my $self = shift;
    my( $filename ) = @_;

    die 'Filename is required' unless $filename;
    die 'Must have a ClaimsProcessor object' unless $self->claims_processor;

    $self->connect;
    my $dir = $self->claims_processor->put_directory;

    eval {
        $self->sftp->setcwd( $dir )
            or $self->sftp_die;
        $self->sftp->put( $filename, File::Basename::basename($filename) )
            or $self->sftp_die;
    };

    die "Unable to send billing file: $@" if $@;

    # Fetch the files that come in response -
    my ( $received_files, $error );
    eval { ( $received_files, $error ) = $self->get_new_files; };
   
    my $result = "Successfully sent billing file.\n"; # XXX this string used in controller to determine successful submission
    $result .= $error if $error;
    $result .= eleMentalClinic::Log::Log_tee( $@ ) if $@;

    return( $received_files, $result );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_files( $filenames )

Object method. Get the files listed in $filenames.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_files {
    my $self = shift;
    my( $filenames ) = @_;

    die 'Filenames are required' unless $filenames and @$filenames;
    die 'Must have a ClaimsProcessor object' unless $self->claims_processor;
    $self->connect;

    my $remotedir = $self->claims_processor->get_directory;
    my $localdir = $self->config->edi_in_root;

    my ( @received, @not_received );
    for my $filename ( @$filenames ) {
        if (
            $self->sftp &&
            $self->sftp->get("$remotedir/$filename", "$localdir/$filename")
            ) {
            my $received = $self->record_file_receipt( $filename );
            push @received, $received if $received;
        } else {
            warn "Didn't receive '$filename': " . $self->sftp->error . "\n"
                if $self->sftp && $self->sftp->error;
            push @not_received, $filename;
        }
    }

    my( $error, $missing );
    $missing .= " $_" 
        for @not_received;

    $error = 'Unable to download all of the files. Missing:' . $missing unless @received == @$filenames;
    $error = 'Unable to download any files:' . $missing unless @received > 0;

    return ( \@received, $error );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 list_files

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub list_files {
    my $self = shift;
    
    die 'Must have a ClaimsProcessor object' unless $self->claims_processor;
    $self->connect;
    return undef unless $self->sftp;

    my $dir = $self->claims_processor->get_directory;

    return [
        grep { $_ ne '.' and $_ ne '..' }
        map { $_->{filename} }
        @{ $self->sftp->ls( $dir ) or $self->sftp_die }
    ];

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_new_files

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_new_files {
    my $self = shift;
    
    die 'Must have a ClaimsProcessor object' unless $self->claims_processor;
    $self->connect;

    my $seen_files = eleMentalClinic::ECS::FileDownloaded->get_by_( 'claims_processor_id', $self->claims_processor->id );
    @$seen_files = map { $_->name } @$seen_files;

    my $files = $self->list_files;
    die 'No files to download.' unless $files;

    $files = $self->find_new_files( $files, $seen_files );
    die 'No new files to download.' unless @$files;
    return $self->get_files( $files );
}

# Helper and Driver are compatibility shims to work around the fact that
# IPC::Open2 breaks under mod_perl2.  Google for 'open2 mod_perl' for details;
# the short version is that mod_perl 'helpfully' ties STDIN and STDOUT in a way
# that means they can't be untied.
package eleMentalClinic::ECS::SFTP::Helper;

use Config;
use constant PERLIO_IS_ENABLED => $Config{useperlio}; 

sub new {
    my $class = shift;
    my ( %arg ) = @_;

    bless { arg => \%arg } => $class;
}

# taken from http://perl.apache.org/docs/2.0/api/Apache2/SubProcess.html
sub read_data {
    my ($fh) = @_;
    my $data;
    if (PERLIO_IS_ENABLED || IO::Select->new($fh)->can_read(10)) {
        $data = <$fh>;
    }
    return $data;
} 

sub _spawn {
    my ($cmd, $args) = @_;
    if (my $r = $eleMentalClinic::Dispatch::request) {
        return $r->spawn_proc_prog($cmd, $args);
    }
    require IPC::Open3;
    IPC::Open3::open3(my ($in, $out, $err), $cmd, @$args);
    return ($in, $out, $err);
}

sub sftp {
    my $self = shift;
    $self->{sftp} ||= do{ 
        my ($in, $out, $err) = _spawn(
            '/usr/bin/perl',
            [
                '-MeleMentalClinic::ECS::SFTP',
                '-e',
                'eleMentalClinic::ECS::SFTP::Driver->run;'
            ],
        );
        print $in JSON::to_json($self->{arg}) . "\n";
        #print STDERR "$$: harnessing\n";
        # skip over initial warnings
        my $line;
        while ($line = read_data($out)) {
            last if $line =~ /^{/;
            warn $line;
        }
        my $res = JSON::from_json($line);
        die $res->{error} if $res->{error};

        $self->{io} = [ $in, $out, $err ];
    };
}

sub error { $_[0]->{error} }

sub AUTOLOAD {
    my $self = shift;
    my $sftp = $self->sftp;
    my ($in, $out, $err) = @{ $self->{io} };
    (my $method = our $AUTOLOAD) =~ s/.*:://;
    my $input = JSON::to_json({ method => $method, args => [@_] }) .  "\n";
    #print STDERR "> $input";
    print $in $input;
    
    my $r = JSON::from_json(read_data($out));

    if ($r->{error}) {
        $self->{error} = $r->{error};
        return;
    }
    #die $r->{error} if $r->{error};
    my @rv = @{ $r->{result} };
    return $rv[0] if ! wantarray;
    return @rv;
}    

sub DESTROY {
    if (my $out = $_[0]->{io}[0]) {
        print $out JSON::to_json({ quit => 1 }) . "\n";
    }
}

package eleMentalClinic::ECS::SFTP::Driver;

use File::Temp;
sub run {
    my $self = shift;
    my ($fh, $filename) = File::Temp::tempfile;

    # comment this out for debugging
    unlink($filename);

    close STDERR;
    open STDERR, '>&' . fileno($fh);
    my $arg = JSON::from_json(scalar <STDIN>);
    my $sftp = Net::SFTP::Foreign->new( %$arg );
    $|++;
    if ($sftp->error) {
        print JSON::to_json({ error => "$@" }) . "\n";
        exit 1;
    } else {
        print JSON::to_json({ start => 1 }) . "\n";
    }
    #print STDERR "$$: running\n";
    while (<STDIN>) {
        my $input = JSON::from_json($_);
        my $method = $input->{method};
        my @args   = @{ $input->{args} || [] };

        my @rv = eval { $sftp->$method(@args) || die $sftp->error };
        #use Data::Dumper; print STDERR Dumper({ method => $method, args =>
        #\@args, result => \@rv });
        my $output;
        if ($@) {
            $output = JSON::to_json({ error  => "$@" });
        } else {
            $output = JSON::to_json(
                { result => \@rv },
                { allow_blessed => 1 },
            );
        }
        #print STDERR $output . "\n";
        print $output . "\n";
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
