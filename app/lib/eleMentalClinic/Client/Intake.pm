=head1 NAME

eleMentalClinic::Client::Intake

=head1 SYNOPSIS

Client intake record.

=head1 METHODS

=cut

package eleMentalClinic::Client::Intake;

use strict;
use warnings;

use base qw/ eleMentalClinic::DB::Object /;


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_intake' }
    sub fields {[qw/
        rec_id client_id client_placement_event_id
        step assessment_id
    /]}
    sub primary_key { 'rec_id' }
}

sub accessors_retrieve_one {
    {
        client => { client_id => 'eleMentalClinic::Client' },
        placement => { client_placement_event_id => 'eleMentalClinic::Client::Placement' },
        _assessment => { assessment_id => 'eleMentalClinic::Client::Assessment' }
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# In case there is no assessment.
sub assessment {
    my $self = shift;
    return unless $self->assessment_id;
    return $self->_assessment;
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

=item Erik Hollensbe L<erikh@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see
L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for
known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at:
L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

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
