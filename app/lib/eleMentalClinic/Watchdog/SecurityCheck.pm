# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Watchdog::SecurityCheck;
use strict;
use warnings;
use Package::Watchdog;
use eleMentalClinic::Controller;
use Carp;

use base 'eleMentalClinic::Base';

=head1 NAME

eleMentalClinic::Watchdog::SecurityCheck

=head1 DESCRIPTION

Does the actual security checking for the watchdog.

=head1 CACHING

For performance reasons security checks are cached. Some method cache by
instance, that is the values are remembered in $self. Other methods cache into
$self->cache. This is because some values are safe to remember for the entire
cgi process, others are specific to the check.

Cached methods are noted in pod. They will also note if they are cached by
instance, or by $obj->cache.

=head1 ACCESSORS

All these accessors are simple get/set accessors, they are all auto-generated.

=over 4

=item params()

The parameters provided by the watchdog

=item cache()

Stored values from previous security checks

=item watchdog()

The eleMentalClinic::Watchdog object

=item client_id()

Used if a client_id is specified instead of being deduced.

=back

=head1 METHODS

=over 4

=cut

sub methods {[ qw/ params cache watchdog client_id / ]}

=item $list = $obj->safe_subs()

Get the list of safe subs. Safe subs are susb that do not need a security
check.

=cut

sub safe_subs {[ qw/primary_key client_id table methods fields accessors_retrieve_many fields_required/ ]}

=item $set_value = $obj->cached_run( $staff_id, $client_id, $set_value )

$set_value is optional, if provided that will be set as the value.

returns the cached value of the permissions check for this client_id and staff_id.

=cut

sub cached_run {
    my $self = shift;
    my ( $staff_id, $client_id, $run ) = @_;
    return unless $staff_id and $client_id;

    # Note this is the same cache slot as valid_permissions
    # It makes sence to use the same for both as they mean the same thing.
    # One is just a shortcut.
    $self->cache->{ $staff_id }->{ $client_id } = $run if $run;

    return $self->cache->{ $staff_id }->{ $client_id };
}

=item $pass = run_checks( $watchdog, $cache, %params )

Returns a true value if the security check passes. $pass will be a string value
explaining why the check passed. If it passes by cache it will return the
cached reason preappended by 'Cached: '

Will throw a security exception if the check fails. There is no return value in
such cases.

*Caches the return by client_id and staff_id in $obj->cache*

NOTE: This may be refactored inthe future to return ( $bool, $msg ) leaving
whatever calls run_checks to throw the exception.

=cut

sub run_checks {
    my $self = shift;
    $self->parse_params( @_ ) if @_;

    my $client_id = $self->actual_client_id;
    return "no client" unless $client_id;
    my $staff_id = $self->user->id if $self->user;

    my $from_cache = $self->cached_run( $staff_id, $client_id );
    return "Cached: $from_cache" if $from_cache;

    my $run = $self->_do_checks;
    $self->cached_run( $staff_id, $client_id, $run );
    return $run;
}

=item $obj->_do_checks()

Used internally to run the checks.

=cut

sub _do_checks {
    my $self = shift;
    return "safe sub" if $self->safe_sub;
    return "no client" unless $self->actual_client_id;
    $self->security_exception( "No User" ) unless $self->user;
    return "all clients group" if $self->all_clients;
    $self->security_exception( "No Access" ) unless $self->valid_permissions;
    return "passed security";
}

=item $obj->parse_params( $watchdog, $cache, %params )

Sets the watchdog, cache, and params all at once.

=cut

sub parse_params {
    my $self = shift;
    $self->watchdog( shift( @_ ));
    $self->cache( shift( @_ ));
    $self->params({ @_ });
}

=item $obj->forbidden()

Shortcut to access the Package::Watchdog::Forbidden object relivant to this check.

=cut

sub forbidden {
    shift->params->{ forbidden };
}

=item $obj->sub()

Returns the name of the subroutine that was accessed triggering the check.

=cut

sub sub {
    shift->forbidden->sub;
}

=item $obj->controller()

Return the controller object.

NOTE: This assumes the controller is the first argument to the subroutine that
was watched in the controller. If a function is called instead of a method this
will be broken.

=cut

#FIXME - This does not make sure the watched sub was a method instead of a
#function.
sub controller {
    shift( @_ )->params->{ watched_params }->[0];
}

=item $obj->user()

Return the current user from the controller.

=cut

sub user {
    my $self = shift;
    return $self->controller->current_user if $self->controller;
    return;
}

=item $bool = $obj->safe_sub()

Returns the name of the forbidden sub if the sub is int he list of safe subs. Otherwise it returns false.

=cut

sub safe_sub {
    my $self = shift;
    return grep { $_ eq $self->sub } @{ $self->safe_subs };
}

=item $obj->all_clients()

Returns true if the current user is in the 'all clients' role.

=cut

sub all_clients {
    my $self = shift;

    return 0 unless $self->user;

    my $all_clients = eleMentalClinic::Role->all_clients_role;

    unless( $self->cache->{ $self->user->id } && defined $self->cache->{ $self->user->id }->{ all_users } ) {
        $self->cache->{ $self->user->id } ||= {};
        $self->cache->{ $self->user->id }->{ all_users }
            = $all_clients->has_personnel( $self->user ) ? 1 : 0;
    }

    return $self->cache->{ $self->user->id }->{ all_users };
}

=item $client_id = $obj->actual_client_id()

Try to deduce the client_id for this security check in this order:
If $obj->client_id() is set return that.
If sub is 'new' return the client_id from the forbidden sub params.
If sub is retrieve return the first argument to the forbidden sub.
If the sub is a method call return the id of the object the method was called on.
Return undef

*Return is cached in the instance*

=cut

sub actual_client_id {
    my $self = shift;

    return $self->client_id if $self->client_id;

    unless ( exists $self->{ actual_client_id }) {
        my $package = $self->params->{ forbidden }->package;
        my $params = $self->params->{ forbidden_params };
        ( my $obj, $params ) = $self->parse_sub_params( $package, $params );

        $self->{ actual_client_id } =
            ($self->sub eq 'new') ? $params->[0]->{ client_id }
          : ($self->sub eq 'retrieve' && $params->[0]) ? $params->[0]
          : ($obj && ref $obj) ? $obj->client_id
          : 0;
    }

    return $self->{ actual_client_id } || undef;
}

=item $obj->parse_sub_params( $package, $params )

$params should be an arrayref.

returns ( $object, $params );

If the first item in @$params is an instance of $package, or the name of the
package it will be shifted off the @$params array and returned as $object.
$params is returned without the object at the beginning.

If the first object is not a $package then $object is undef and $params is unchanged.

=cut

sub parse_sub_params {
    my $self = shift;
    my ( $package, $params ) = @_;

    my $obj = shift( @$params ) if $params->[0] && (
                                    $params->[0] eq $package ||
                                    eval { $params->[0]->isa( $package )}
                                );

    return ( $obj || undef, $params );
}

=item $obj->valid_permissions()

Validate the permissions of the curent staff member against the current
client_id.

*Return is cached in $obj->cache*

=cut

sub valid_permissions {
    my $self = shift;
    my $client_id = $self->actual_client_id;
    my $staff_id = $self->user->id;

    $self->cache->{ $staff_id } ||= {};
    unless ( exists $self->cache->{ $staff_id }->{ $client_id }) {
        $self->cache->{ $staff_id }->{ $client_id } =
            $self->user->primary_role->has_client_permission( $client_id ) || undef;
    }

    return $self->cache->{ $staff_id }->{ $client_id };
}

=item $obj->securty_exception( $message )

Throw a catchable security exception with the specified message.

NOTE: Turns off the watchdog for the rest of the cgi process.

=cut

sub security_exception {
    my $self = shift;
    my $msg = shift;

    # Security violated, kill the watchdog so we don't chain die.
    $self->watchdog->clean_watchdog();

    eleMentalClinic::Log::ExceptionReport->new({
        catchable => 1,
        name => "Security Violation",
        message => "Attempt to access client data without proper permissions: $msg",
        params => {
            staff_id => $self->user ? $self->user->id : undef,
            client_id => $self->actual_client_id || undef,
            controller_class => ref( $self->controller ) || undef,
            controller_sub => $self->params->{ watched }->sub,
            client_sub => $self->sub,
        }
    })->throw;
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
