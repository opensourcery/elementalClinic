# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Role::Access;
use strict;
use warnings;
use eleMentalClinic::Role;
use eleMentalClinic::Client;
use eleMentalClinic::Personnel;

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Base::View;

=head1 NAME

eleMentalClinic::Role::Access

=head1 DESCRIPTION

A row in the client_user_role_map table. This is a single method by which a
staff member is able to view a client.

=head1 METHODS

=over 4

=cut

sub table  { 'client_user_role_map' }
sub fields { [ qw/ role_id client_id reason id staff_id / ] }
sub primary_key { undef }

sub accessors_retrieve_one {
    {
        role   => { role_id   => 'eleMentalClinic::Role' },
        client => { client_id => 'eleMentalClinic::Client' },
        staff  => { staff_id  => 'eleMentalClinic::Personnel' },
    };
}

# $self->id can be set via the object factory, replace it here, we do not need
# the factory one anyway (it doesn't apply)
{
    no warnings 'redefine';
    *id = sub {
        my $self = shift;
        return $self->{ id };
    }
}

sub fetch_reason {
    my $self = shift;
    my $sub = "_fetch_" . $self->reason;
    return $self->$sub if $self->can( $sub );
    return undef;
}

sub reason_name {
    my $self = shift;
    return 'Direct Access'
        if $self->reason eq 'direct';
    return "Service Coordinator (" . $self->fetch_reason->event_date . ")"
        if $self->reason eq 'coordinator';
    if ( $self->reason eq 'group' ) {
        my $group = $self->fetch_reason->name;
        $group =~ s/\s*group\s*$//;
        return "Writer ($group)";
    }
    if ( $self->reason eq 'membership' ) {
        my $name = $self->fetch_reason->name;
        return "Role Membership ($name)"
    }
    return $self->reason;
}

sub _fetch_direct {
    my $self = shift;
    return eleMentalClinic::Role::DirectClientPermission->retrieve( $self->id );
}

sub _fetch_membership {
    my $self = shift;
    return eleMentalClinic::Role::DirectMember->retrieve( $self->id )->role;
}

sub _fetch_group {
    my $self = shift;
    return eleMentalClinic::Group->retrieve( $self->id );
}

sub _fetch_coordinator {
    my $self = shift;
    return eleMentalClinic::Client::Placement::Event->retrieve( $self->id );
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
