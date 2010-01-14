package eleMentalClinic::Theme::Access;

=head1 NAME

eleMentalClinic::Theme

=head1 SYNOPSIS

Root-level Theme management class.

=head1 METHODS

=over

=cut

use strict;
use warnings;

use base qw(eleMentalClinic::Singleton);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
    my $self = shift;
    return $self->instance(@_);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=item _new_instance

Our singleton new()

=cut

sub _new_instance {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless { }, $class;
    $self->init( @_ );
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=item init

Our initialization routine - loads the allowed controllers from the theme
configuration. Will warn if there is any issue loading them.

=cut 
sub init {
    my ($self, $theme_config) = @_; 

    # we only need the 'allowed_controllers' section of the theme config

    $self->{allowed_controllers} = $theme_config->{allowed_controllers};

    if (ref $self->{allowed_controllers} ne "ARRAY") {
        warn "Allowed Controllers is malformed - defaulting to allowing none";
        $self->{allowed_controllers} = [];
    }

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=item allowed_controllers

Accessor for the allowed controllers. Returns array ref.

=cut
sub allowed_controllers { $_[0]->{allowed_controllers} }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=item controller_can($controller)

Returns existence of the controller in the allowed_controllers configuration.

=cut
sub controller_can {
    my ($self, $controller) = @_;

    return scalar grep lc($controller) eq lc($_), @{$self->{allowed_controllers}};
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

=item Erik Hollensbe L<erikh@opensourcery.com>

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
