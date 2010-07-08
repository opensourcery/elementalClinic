# vim: ts=4 sts=4 sw=4

=head1 eleMentalClinic::Dispatch

Client Filter controller

=cut

package eleMentalClinic::Controller::Base::ClientFilter;

use eleMentalClinic::Client;
use base qw(eleMentalClinic::CGI);

use strict;
use warnings;

sub ops {
    (
        home => { },
        filter => { },
    )
}

sub get_current_user {
    my $self = shift;

    return $self->current_user;
}

sub filter {
    my $self = shift;

    $self->current_user->pref->client_list_filter( $self->param( 'client_list_filter' ));
    $self->current_user->pref->client_program_list_filter( $self->param( 'client_program_list_filter' ));
    $self->current_user->pref->save;

    $self->current_user->filter_clients;

    $self->home;
}

sub home {
    my $self = shift;

    $self->ajax(1);

    my $list_params = {
        search => $self->param('search') || '',
        program_id => $self->param( 'client_program_list_filter' ) || '',
    };
    if ( my $placement = $self->param( 'client_list_filter' )) {
        if ( $placement eq 'caseload' ) {
            $list_params->{ staff_id } = $self->current_user->id;
        }
        else {
            $list_params->{ active } = $placement eq 'active' ? 1 : 0;
        }
    }
    my $clients = [ grep { $self->current_user->primary_role->has_client_permissions( $_->{ client_id }) }
        @{ eleMentalClinic::Client->list_all( $list_params ) || [] }];

    if( $clients ) {
        no warnings 'uninitialized';

        my $output;

        for( @$clients ) {
            $output .= qq(<option value="$_->{ client_id }">);
            $output .= qq($_->{ lname }, $_->{ fname } $_->{ mname });
            if ( $self->param( 'extra' ) eq 'scanned_record' ) {
                my $c = eleMentalClinic::Client->new($_);
                $output .= sprintf qq/ (DOB: %s)/, $c->dob;
            }
            $output .= qq(</option>);
        }

        if( $self->param( 'extra' ) eq 'home' ) {
            return <<EOO;
        <select name="client_id" id="client_id" onchange="document.forms['clientform'].submit()">
            $output
        </select>
        <input type="hidden" name="op" id="op" value="home" />
        <input type="submit" id="view_client" value="View Client &#187;" />
EOO
        }
        elsif( $self->param( 'extra' ) eq 'groups' ) {
            return <<EO1;
        <select name="new_member_id" id="new_member_id" multiple="multiple" size="20">
            $output
        </select>
        <p class="edit add_member">
            <input type="submit" name="op" id="add" value="Add Members" /></p>
EO1
        }
        elsif( $self->param( 'extra' ) eq 'scanned_record' ) {
            return <<EO2;
        <select name="client_id" id="client_id">
            $output
        </select>
EO2
        }
        else {
            return 'Error: Invalid client filter parameter.';
        }
    }
    else {
        return 'No clients in this list.';
    }
}

1;

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

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
