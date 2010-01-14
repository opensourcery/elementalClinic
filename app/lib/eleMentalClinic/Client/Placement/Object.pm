package eleMentalClinic::Client::Placement::Object;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Placement::Object

=head1 SYNOPSIS

Parent for client placement objects:

=over 4

=item eleMentalClinic::Client::Referral

=item eleMentalClinic::Client::Discharge

=back

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;

    $self->SUPER::init( @_ );
    die q/Only objects with 'client_placement_event_id' properties can inherit from Client::Placement::Object/
        unless $self->can( 'client_placement_event_id' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub placement_event {
    my $self = shift;

    return unless $self->client_placement_event_id;
    my $event = eleMentalClinic::Client::Placement::Event->retrieve( $self->client_placement_event_id );
    return unless $event->id;
    return $event;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_by_placement_event_id {
    my $class = shift;
    my( $event_id ) = @_;

    return unless $event_id;
    return unless my $object = $class->new->db->select_one(
        $class->fields,
        $class->table,
        'client_placement_event_id = ' . $event_id
    );
    return $class->new( $object );
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
