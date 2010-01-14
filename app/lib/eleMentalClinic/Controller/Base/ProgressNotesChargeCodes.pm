=head1 eleMentalClinic::Dispatch

Client Filter controller

=cut

package eleMentalClinic::Controller::Base::ProgressNotesChargeCodes;

use base qw(eleMentalClinic::CGI);

use eleMentalClinic::Lookup::ChargeCodes;
use eleMentalClinic::ProgressNote;
use eleMentalClinic::Personnel;

use strict;
use warnings;

sub ops {
    (
        home => { },
    );
}

sub home {
    my $self = shift;

    $self->ajax(1);

    my ($valid_charge_codes, $prognote) = $self->get_charge_codes;

    if( $valid_charge_codes ) {
        no warnings 'uninitialized';
        my $output;
        for( @$valid_charge_codes ) {
            no warnings 'numeric';  # charge_code_id might be a string; we don't care
            my $sel = ' selected="selected"'
            if $_->{ rec_id } == $prognote->charge_code_id;
            $output .= qq(<option value="$$_{ rec_id }"$sel>$$_{ name }: $$_{ description }</option>);
        }
        return <<EOO;
<label for="charge_code_id">Code:</label>
<select name="charge_code_id" id="charge_code_id">
    <option value="">Select a code...</option>
    $output
</select>
EOO
    }
    else {
        return 'No valid codes';
    }
}

sub get_note {
    my $self = shift;

    my $prognote = eleMentalClinic::ProgressNote->new({ $self->Vars });
    my $writer = eleMentalClinic::Personnel->new({
        staff_id => $self->param( 'writer_id' ),
    })->retrieve;
    $prognote->staff_id( $writer->id );
    return $prognote;
}

sub get_charge_codes {
    my $self = shift;

    my $prognote = $self->get_note;

    return unless $prognote;

    my $cc = eleMentalClinic::Lookup::ChargeCodes->new;
    $cc->client_id( $prognote->client_id );
    $cc->staff_id( $prognote->staff_id );
    $cc->note_date( $prognote->note_date );
    $cc->prognote_location_id( $prognote->note_location_id );
    return (scalar $cc->valid_charge_codes, $prognote);
}

1;

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
