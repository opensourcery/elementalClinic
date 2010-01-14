# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Role::Cache;
use strict;
use warnings;
use Carp;

=head1 NAME

eleMentalClinic::Role::Cache

=head1 DESCRIPTION

Cache the process-intensive methods on roles.

=cut

#{{{ Exported Functions


=head1 EXPORTED FUNCTIONS

=over 4

=cut

use base 'Exporter';
our @EXPORT_OK = qw/cache_methods resets_role_cache/;

=item cache_methods( @sub_list )

Cache the return of the listed methods.

Only works on eleMentalClinic::Role methods. Will have no effect on non-role
subs.

=cut

sub cache_methods {
    my @methods = @_;
    my ( $package ) = caller();
    eval { _cache_method( $package, $_ ) for @methods };
    croak( $@ ) if $@;
}

=item resets_role_cache( @sub_list )

Make it so that whenever the specified subs are called the role cache will be
cleared. Works on any sub.

=cut

sub resets_role_cache {
    my @subs = @_;
    my ( $package ) = caller();

    eval { _make_reset( $package, $_ ) for @subs };
    croak( $@ ) if $@;
}

#}}}

#{{{ CLASS DATA

=back

=head1 CLASS DATA

=over 4

=item %DATA

Class variable. This is the core, this is where the cache data is kept.

=item DATA()

Returns a reference to %DATA.

=cut

# All instances share the same data.
our %DATA = ();
sub DATA { \%DATA }

#}}}

#{{{ CLASS METHODS

=back

=head1 CLASS METHODS

=over 4

=item new( $role_id, $method_name )

Create a new instance.

=cut

sub new {
    my $class = shift;
    my ( $role_id, $method ) = @_;
    croak( "Must provide both a role id and a method name" ) unless $role_id and $method;
    return bless(
        {
            role_id => $role_id,
            method => $method,
            data => DATA(),
        },
        $class,
    );
}

=item clear

Used to clear the cache.

if the return is not stored the cache will be cleared immedietly:

    eleMentalClinic::Role::Cache->clear;

If the return is captured the cache will be cleared as soon as it passes out of scope.

    sub do_stuff {
        my $tmp = eleMentalClinic::Role::Cache->clear;
        ... do stuff cache is not cleared ...
        return ...;
    }

    # $data is generated using the cache, but then the cache is cleared.
    my $data = do_stuff();
    ... cache is cleared ...

=cut

sub clear {
    my $sub = sub {
        my $data = DATA();
        delete $data->{ $_ } for keys %$data;
    };
    return eleMentalClinic::Role::Cache::_Clear->new( $sub );
}

#}}}

#{{{ OBJECT METHODS

=back

=head1 OBJECT METHODS

=over 4

=item data()

Returns the stored reference to the cache data.

=cut

sub data { shift->{ data }};

=item role_id()

Returns the role id.

=cut

sub role_id { shift->{ role_id }};

=item method()

Returns the method name.

=cut

sub method { shift->{ method }};

=item role_data()

Get the cache data for the current role id.

=cut

sub role_data {
    my $self = shift;
    return $self->data->{ $self->role_id } ||= {};
}

=item method_data()

Returns the cached data for the current method on the current role id.

=cut

sub method_data {
    my $self = shift;
    return $self->role_data( $self->role_id )->{ $self->method } ||= {};
}

=item get_result()

return the result for the current method on the current role id.

=cut

sub get_result {
    my $self = shift;
    return unless $self->has_result && $self->has_result ne 'empty';

    my $method_data = $self->method_data;
    return @{ $method_data->{ results }} if $method_data->{ result_type } eq 'array';
    return $method_data->{ results }->[0];
}

=item set_result( @results )

Sets the result for the current method on the current role.

=cut

sub set_result {
    my $self = shift;
    my @results = @_;
    my $method_data = $self->method_data;

    $method_data->{ results } = \@results if @results;
    $method_data->{ result_type } = @results ? @results > 1 ? 'array' : 'scalar'
                                             : 'empty';
    return $self->has_result;
}

=item clear_result()

Clear the result for the current method on the current role.

=cut

sub clear_result {
    my $self = shift;
    my $method_data = $self->method_data;
    delete $method_data->{ result_type };
    delete $method_data->{ results };
    return !$self->has_result;
}

=item has_result()

Returns true if there is a cached result for the current method on the current role.

=cut

sub has_result {
    my $self = shift;
    my $method_data = $self->method_data;
    return $method_data->{ result_type };
}

#}}}

#{{{ Helper Functions

=back

=head1 HELPER FUNCTIONS

=over 4

=item _cache_method( $package, $method_name )

Used by cache_methods() to re-write each method.

=cut

sub _cache_method {
    my ( $package, $sub ) = @_;
    my $original = $package->can( $sub );
    croak( "$package has no method $sub." ) unless $original;

    my $new = sub {
        my $role = shift;

        return $original->( $role, @_ )
            unless eval{ $role->isa( 'eleMentalClinic::Role' )};

        my $cache = __PACKAGE__->new( $role->id, $sub );

        $cache->set_result(
            $original->( $role, @_ )
        ) unless $cache->has_result;

        return $cache->get_result;
    };

    _replace_sub( $package, $sub, $new );
}

=item _make_reset( $package, $sub_name )

Used by resets_role_cache() to re-write each specified sub.

=cut

sub _make_reset {
    my ( $package, $sub ) = @_;
    my $original = $package->can( $sub );
    croak( "$package has no sub $sub." ) unless $original;

    my $new = sub {
        my $tmp = __PACKAGE__->clear;
        return $original->( @_ );
    };

    _replace_sub( $package, $sub, $new );
}

=item _replace_sub( $package, $sub_name, $new_sub )

Replaces $sub_name in $package with $newsub.

=cut

sub _replace_sub {
    my ( $package, $sub, $new ) = @_;
    my $original = $package->can( $sub );
    {
        no strict 'refs';
        no warnings 'redefine';
        *{ $package . '::' . $sub } = $new;
    }
    return $package->can( $sub ) == $new;
}
#}}}

#{{{ package _Clear

=back

=head1 eleMentalClinic::Role::Cache::_Clear

Instances of this class are returned by clear(). Once destroyed they run a
subroutine provided in their constructor that clears the cache.

=over 4

=item new( $sub )

Create a new instance that will run the provided sub upon destruction.

=item DESTROY()

Runs the sub provided in the constructor.

=cut

{
    package eleMentalClinic::Role::Cache::_Clear;
    use strict;
    use warnings;
    sub new {
        my $class = shift;
        my ( $sub ) = @_;
        return bless( { run => $sub }, $class );
    }

    sub DESTROY {
        my $self = shift;
        $self->{ run }->();
    }
}
#}}}

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
