package eleMentalClinic::Log;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Log

=head1 SYNOPSIS

Logger object; exports C<Log> function.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base /;
use base qw/ Exporter /;
our @EXPORT = qw/ Log Log_defer Retrieve_deferred Log_tee /;

use Log::Log4perl qw/ :levels /;
use Data::Dumper;
use eleMentalClinic::Log::Access;
use eleMentalClinic::Log::Security;
use Carp;

our $one_true_Log;
my @DEFERRED_LOG;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $log_conf_path ) = @_;

    unless( defined $one_true_Log ) {
        $log_conf_path ||= $self->config->log_conf_path;
        if( defined $log_conf_path ) {
            eval { Log::Log4perl->init_once( "$log_conf_path" )};
            if( $@ ) {
                print STDERR "ERROR: cannot initialize logging engine: $@\n";
            }
            else {
                # prevent perl code in log.conf
                Log::Log4perl::Config->allow_code( 0 );
                # so that errors look like they're coming from the right caller
                $Log::Log4perl::caller_depth = 2;
                $one_true_Log = 1;
            }
        }
    }
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub write_log {
    my $class = shift;
    my( $tag, @messages ) = @_;

    return unless $tag and @messages;
    return unless my $logger = Log::Log4perl->get_logger;
    return unless $logger->is_info;

    $logger->info( join ' ' => "[\U$tag]", @messages );
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 Log()

takes:
{
    type => 'TYPE', # security, access
    user => ... # Login username string, or a personnel object
    action => 'ACTION', # load, reload, login, logout, failure
    object => OBJECT, #The actual object if this is an access log.
}

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub Log {
    my ( $input ) = @_;
    croak( "Log now requires a hash" ) unless ref $input eq 'HASH';

    # Make sure the file log is still written.
    __PACKAGE__->write_log( format_log( $input ));

    my $type = ucfirst( lc( $input->{ type }));
    my $class = 'eleMentalClinic::Log::' . $type;
    my $record = $class->new;
    $record->update_from_log( $input );
    return $record->id;
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 format_log()

Takes the Log() input hash and generates old-style logs:
    *ignore this half*       |     *Stuff we care about*
#[2008/11/18 10:41:13] [chad] [SECURITY] [user_id: 1] Login
#[2008/11/18 12:46:52] [chad] [SECURITY] [user_id: 1000] Logout
#[2008/11/18 13:51:41] [chad] [SECURITY] Login failure: foo
#[2008/11/18 10:43:45] [chad] [CLIENT] [client_id: 1002] [user_id: 1]
#[2008/11/18 10:44:19] [chad] [CLIENT] [client_id: 1002] [user_id: 1] (Loaded from session)

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub format_log {
    my ( $input ) = @_;
    my $tag = lc($input->{ type });
    my @messages;

    my $action = $input->{ action };
    my $object = $input->{ object };
    my $object_id = $object->id if $object;

    $tag = 'client' if $tag ne 'security'
                    and ref $object eq 'eleMentalClinic::Client';

    return unless $tag eq 'client' or $tag eq 'security';

    push( @messages, "[client_id: $object_id]" ) if $object_id;

    my $user = $input->{ user };
    if (( not $user ) or ref $user ) {
        my $user_id = $user ? $user->id : 'NO USER';
        push( @messages, "[user_id: $user_id]" ) if $user_id and lc( $action ) ne 'failure';
    }

    my %actionmap = (
        login => 'Login',
        logout => 'Logout',
        failure => "Login failure: " . ( $user ? $user : '(NO USER)' ),
        reload => "(Loaded from session)",
    );

    my $actionmsg = $actionmap{ lc( $action )};
    push( @messages, $actionmsg ) if $actionmsg;

    return ( $tag, @messages );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub Log_defer {
    my( $message ) = @_;

    return unless $message;
    push @DEFERRED_LOG => Log_tee( $message );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub Retrieve_deferred {

    return \@DEFERRED_LOG;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 Log_tee( $message )

Function. Returns the error message with " at /usr/local/lib/blah/File.pm line 122"
stripped off, and warns with the entire message.

Useful for outputting errors to the UI where the user doesn't need to 
see which file the error happened in.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub Log_tee {
    my $message = shift;

    return unless $message;
    warn $message unless $eleMentalClinic::Base::TESTMODE > 0;
    $message =~ s| at /.*$||; 
    return $message; 
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

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
