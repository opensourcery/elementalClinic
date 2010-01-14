# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Base;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Base

=head1 SYNOPSIS

Base module from which all the project inherits.

=head1 METHODS

=cut

no warnings qw/ redefine /;

use eleMentalClinic::Util;
use eleMentalClinic::Base::Time -all;
use eleMentalClinic::Base::Util -all;
use eleMentalClinic::Base::Globals -all;
use Data::Dumper;
use Carp;

our $TESTMODE = 0;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
    my $proto = shift;
    my( $args, $options ) = @_;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    return $self->init( $args, $options );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 empty()

Class or Object method.

Constructs and returns an empty object.  Identical to C<new()> except that
C<fields_required> are ignored.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub empty {
    my $proto = shift;
    my( $args ) = @_;
    $proto->new( $args, { empty => 1 });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME define these for the class only
sub init {
    my $self = shift;

    my $class = ref $self;
    if ( $class->can( 'methods' ) ) {
        $class->attribute( $_ ) for( @{ $class->methods } );
    }
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub attribute {
    my( $pkg, $attribute ) = @_;
    $attribute =~ s/\w+\.//;

    return if $pkg->can($attribute);
    no strict 'refs';
    *{ "${ pkg }::$attribute" } =
        sub {
            my $self = shift;
            my( $value ) = @_;
            
            # Do we have a value to update?  $value == undef
            # is insufficient to tell since it doesn't handle
            # $self->attr( undef ) when we want to set a 
            # property to null
            my $mutator = scalar @_;

            if( $mutator ) {
                $self->{ $attribute } = 
                    ( not defined $value or $value eq '*NULL' )
                        ? undef
                        : $value;
                return $self;
            }
            else {
                # accessor
                return undef unless defined $self->{ $attribute };
                return undef if( $self->{ $attribute } eq '' );
                return $self->{ $attribute };
            }
        };
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
