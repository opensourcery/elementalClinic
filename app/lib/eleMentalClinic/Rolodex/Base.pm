#===============================================================================
#
#         FILE:  lib/eleMentalClinic/Rolodex/Base.pm
#
#  DESCRIPTION:  Rolodex::Base provides common methods for Client and Rolodex
#               (for now)
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erikh@opensourcery.com>
#      COMPANY:  OpenSourcery, LLC
#      VERSION:  1.0
#      CREATED:  01/21/2008 09:39:59 AM PST
#     REVISION:  $Id$
#===============================================================================

package eleMentalClinic::Rolodex::Base;

use strict;
use warnings;

use Carp qw(confess);

use eleMentalClinic::Util;
use eleMentalClinic::Contact::Address;
use eleMentalClinic::Contact::Phone;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub address {
    my $self = shift;

    return undef unless $self->primary_key and $self->id;
    return eleMentalClinic::Util->filter_contact_primary(
        eleMentalClinic::Contact::Address->get_by_(
            $self->primary_key, $self->id
        )
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub addresses {
    my $self = shift;
    my ($args) = @_;

    return [] unless $self->primary_key and $self->id;

    my $addresses =
      eleMentalClinic::Contact::Address->get_by_( $self->primary_key, $self->id, 'primary_entry', 'DESC, rec_id ASC' );

    return $addresses if ( $args->{inactive} );

    return eleMentalClinic::Util->filter_contact_active($addresses);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub phone {
    my $self = shift;

    return undef unless $self->primary_key and $self->id;

    return eleMentalClinic::Util->filter_contact_primary(
        eleMentalClinic::Contact::Phone->get_by_(
            $self->primary_key, $self->id
        )
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub phones {
    my $self = shift;
    my ($args) = @_;

    return [] unless $self->primary_key and $self->id;

    my $phones =
      eleMentalClinic::Contact::Phone->get_by_( $self->primary_key, $self->id, 'primary_entry', 'DESC, rec_id ASC' );

    return $phones if ( $args->{inactive} );

    return eleMentalClinic::Util->filter_contact_active($phones);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub phone_f {
    my $self = shift;
    my ($phone_f) = @_;

    return $self->phone_format( 'phone', $phone_f );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub phone2_f {
    my $self = shift;
    my ($phone_f) = @_;

    confess "deprecated - use eMC::Contact::Phone instead";

    return $self->phone_format( 'phone_2', $phone_f );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub phone_format {
    my $self      = shift;
    my $method    = shift;
    my ($phone_f) = @_;

    my $phone;

    die "You must pass the method name as the first parameter"
      unless $method;

    if ( defined $phone_f ) {
        $phone = $phone_f;
        $phone_f =~ s/\D//g;
        $self->$method->phone_number($phone_f);
        return $phone;
    }
    else {
        return unless defined $self->$method;
        return if ( $self->$method->phone_number eq '' );
        $phone = $self->$method->phone_number;
        $phone =~ s/(\d{3})(\d{3})(\d{4})/$1-$2-$3/;
        return $phone;
    }
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

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
