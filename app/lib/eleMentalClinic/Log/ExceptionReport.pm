# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Log::ExceptionReport;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Log::ExceptionReport

=head1 SYNOPSIS

=head1 METHODS

=cut

use eleMentalClinic::Log;
use eleMentalClinic::Util;
use Data::Dumper;
use Carp;
use Devel::StackTrace;
use File::Temp qw/tempfile/;
use Date::Calc qw/Today_and_Now/;

use base qw/ eleMentalClinic::Base /;

sub methods {[qw/ stack params file catchable message name no_save /]}

=item report_path()

Returns the exception_log_path from config, defaults to /tmp.

=cut

sub report_path { shift->config->stage1->exception_log_path || '/tmp' }

=item init()

Override the default init() method to build the object properly from
parameters.

=cut

sub init {
    my $self = shift;
    my ( $args, $options ) = @_;
    $args = {
        catchable => 0,
        message => 'An error has occured',
        name => 'unnamed',
        params => {},
        stack => Devel::StackTrace->new( ignore_class => [ ref $self ] ),
        %{ $args || {}},
    };
    $self->SUPER::init( $args, $options );
    # WTF, why doesn't base do this for methods?
    $self->$_( $args->{ $_ }) for keys %$args;
    return $self;
}

=item save()

Saves the report file. Filename is auto-generated and returned. $self->file()
is also set.

=cut

sub save {
    my $self = shift;

    return if $self->no_save;
    return $self->file if $self->file;

    my $path = $self->report_path;
    my $template = join( "-", $self->name, (Today_and_Now()), 'XXXXXX');
    my ( $handle, $file ) = tempfile( $template, DIR => $path, CLEANUP => 0 );

    print $handle $self->report;

    $self->file( $file );
    return $file;
}

=item throw()

Throw an exception for the report. Saves the report.

=cut

sub throw {
    my $self = shift;
    $self->save;
    my $msg = $self->catchable ? 'Catchable Exception '
                               : 'Unhandled Exception ';
    $msg .= '(' . $self->file  . ') '
          . $self->name . ": "
          . $self->message;

    croak( $msg );
}

=item report()

Generates the report text.

=cut

sub report {
    my $self = shift;
    return $self->name
         . "\n----------------------------------\n"
         . $self->message . "\n\n"
         . Dumper( $self->params )
         . "\n----------------------------------\n"
         . "Stack Trace:\n" . $self->stack->as_string;
}

=item message_is_catchable( $message )

Check the text of an exception to see if it is catchable, returns the filename
if it is.

    eval { ...something that throws an exception... };
    my $file = eleMentalClinic::Log::ExceptionReport->message_is_catchable( $@ );

=cut

sub message_is_catchable {
    my $self = shift;
    my ( $message ) = @_;
    if ( $message =~ m/Catchable Exception \(([^\)]+)\)/ ) {
        return $1;
    }
    return;
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

=cut

