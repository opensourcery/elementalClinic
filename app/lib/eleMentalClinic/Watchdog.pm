# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Watchdog;
use strict;
use warnings;
use Package::Watchdog;
use Package::Watchdog::Util;
use eleMentalClinic::Watchdog::SecurityCheck;
use eleMentalClinic::CGI;
use eleMentalClinic::Controller;
use Data::Dumper;
use Scalar::Util;
use HTTP::Date;
use Carp;

use base 'eleMentalClinic::Base';

our $DEBUG = 0;

=head1 NAME

eleMentalClinic::Watchdog

=head1 DESCRIPTION

A watchdog that prevents controllers from accessing client data to which the
current_user does not have rights.

=head1 METHODS

=over 4

=cut

=item $value = $obj->constroller_class( $value )

Get/Set the constroller_class property

=cut

=item $value = $obj->watchdog( $value )

Get/Set the watchdog property.

$value should be a Package::Watchdog object.

=cut

sub methods {[ qw/controller_class watchdog/ ]}

=item $obj->start()

Begin the watch. The watchdog will not be in effect until this method is called.

=cut

sub start {
    my $self = shift;

    return if grep { $self->controller_class =~ m/::$_$/ }
        qw/Financial Report/;

    eval 'require ' . $self->controller_class . ';';

    $self->init_client_class;

    my $wd = Package::Watchdog->new();
    $self->watchdog( $wd );

    my @forbid = (
        qw/new retrieve/,
        grep { m/(get|save|delete)/ } get_all_subs( 'eleMentalClinic::Client' ),
    );

    #FIXME TODO: Cache per controller?
    my @no_override = qw/blessed time2str/;
    my $filter = sub { my ($in) = @_; !grep { $_ eq $in } @no_override };
    my @Constroller_subs = grep { $filter->( $_ )} 'client', 'get_client', get_all_subs( $self->controller_class );
    my @CGI_subs = grep { $filter->( $_ )} get_all_subs( 'eleMentalClinic::CGI' );

    $wd->watch(
        'name' => 'Controller-Client Protection',
        'package' => $self->controller_class,
        'react' => $self->client_reaction,
        subs => \@Constroller_subs,
    )->watch(
        'name' => 'CGI Protection',
        'package' => 'eleMentalClinic::CGI',
        'react' => $self->client_reaction,
        'subs' => \@CGI_subs,
    )->forbid(
        'eleMentalClinic::Client',
        \@forbid,
    );

    return $wd;
}

=item init_client_class()

Make sure all the client methods are defined.

class method

=cut

sub init_client_class {
    my $class = shift;

    require eleMentalClinic::Client;
    my $client = eleMentalClinic::Client->new({ map { $_ => 'fake'} qw/fname lname mname/});

    for my $sub ( @{ eleMentalClinic::Client->fields }) {
        die( "Failed to init client, $sub not found!" ) unless $client->can( $sub );
    }

    1;
}

=item $sub = $obj->client_reaction()

Returns the anonymous subroutine that should be used to react when a watch is
triggered for client access.

=cut

sub client_reaction {
    my $self = shift;
    my $cache = {};
    return sub {
        my $check = eleMentalClinic::Watchdog::SecurityCheck->new;
        eval {
            my $run = $check->run_checks( $self, $cache, @_ );
            if ( $DEBUG ) {
                local $Data::Dumper::Maxdepth = 2;
                print STDERR Dumper({
                    client_id => $check->actual_client_id,
                    staff_id => $check->user ? $check->user->id : undef,
                    params => $check->params->{forbidden_params} || undef,
                    watched_p => $check->params->{ watched }->package,
                    run => $run,
                    watched => $check->params->{ watched }->sub,
                    sub => $check->sub,
                });
            }
        };
        if ( $@ ) {
            #Terminate the watchdog before passing out.
            $self->clean_watchdog;
            croak( $@ );
        }
    }
}

=item $obj->clean_watchdog()

Uninitialises the watchdog.

=cut

sub clean_watchdog {
    my $self = shift;
    $self->watchdog->kill() if $self->watchdog;
    $self->watchdog( undef );
}

sub DESTROY {
    my $self = shift;
    $self->clean_watchdog;
}

'eleMental';

__END__

=back

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
