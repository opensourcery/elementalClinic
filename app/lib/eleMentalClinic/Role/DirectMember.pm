# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Role::DirectMember;
use strict;
use warnings;
use eleMentalClinic::Role;
use eleMentalClinic::Role::ActualMember;
use eleMentalClinic::Util;

use base qw/ eleMentalClinic::DB::Object /;

=head1 NAME

eleMentalClinic::Role::DirectMember

=head1 DESCRIPTION

A membership object making one role a member of another.

=head1 METHODS

=over 4

=item role()

Returns the parent role in this membership.

=item member()

Returns the member role in this membership.

=cut

sub table  { 'direct_role_member' }
sub fields { [ qw/ rec_id role_id member_id / ] }
sub primary_key { 'rec_id' }

sub accessors_retrieve_one {
    {
        role => { role_id => 'eleMentalClinic::Role' },
        member => { member_id => 'eleMentalClinic::Role' },
        _real => { rec_id => 'eleMentalClinic::Role::ActualMember' },
    };
}

for my $sub ( qw/ delete update / ) {
    my $code = sub {
        my $self = shift;
        $self->_real->$sub( @_ );
    };
    no strict 'refs';
    no warnings 'redefine';
    *{ $sub } = $code;
}

{
    no warnings 'redefine';
    *save = sub {
        my $self = shift;
        my $duplicate = __PACKAGE__->get_one_where(
            'WHERE member_id = ' . dbquote( $self->member_id ) . ' AND role_id = ' . dbquote( $self->role_id )
        );
        die( "Cannot duplicate membership" ) if $duplicate and $duplicate->id;
        eleMentalClinic::Role::ActualMember->new({ %$self })->save;
    }
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
