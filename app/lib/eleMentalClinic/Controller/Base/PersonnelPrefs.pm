package eleMentalClinic::Controller::Base::PersonnelPrefs;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Base::PersonnelPrefs

=head1 SYNOPSIS

Base PersonnelPrefs controller.

=head1 METHODS

=cut

use Data::Dumper;
use base qw/ eleMentalClinic::Controller /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        save_prefs => {
            active_date => [ 'Active date', 'checkbox::boolean' ],
            client_head_expand => [ 'Client head expand', 'checkbox::boolean' ],
            rolodex_show_inactive => [ 'Show inactive Rolodex relationships', 'checkbox::boolean' ],
            rolodex_show_private => [ 'Show private Rolodex relationships', 'checkbox::boolean' ],
            releases_show_expired => [ 'Show expired Releases', 'checkbox::boolean' ],
            user_home_show_visit_frequency_reminders => [ 'Show visit frequency', 'checkbox::boolean' ],
            use_popup => [ 'Use popup window for application', 'checkbox::boolean' ],
        },
        save_one => {},
        change_password => {
            password => [ 'Current password', 'required', 'text::liberal' ],
            new_password => [ 'New password', 'required', 'text::liberal', 'length(6,24)' ],
            new_password2 => [ 'Verify new password', 'required', 'text::liberal', 'length(6,24)' ],
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $save_successful ) = @_;
    
    my $script  = $self->param( 'ref_script' );
    my $client_id = $self->param( 'ref_client_id' ) || '';
    my $referer = "$script?client_id=$client_id";
    
    $self->template->vars({
        styles  => [ 'layout/6633', 'user_prefs' ],
        script  => 'user_prefs.cgi',
        referer => $referer,
    });
    $self->template->process_page( 'personnel/user_prefs', {
        save_successful => $save_successful,
        ref_script => $script,
        ref_client_id => $client_id,
        available_preferences => $self->available_preferences,
    });
}

# undef = don't check
sub available_preferences { undef }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_prefs {
    my $self = shift;

    my $prefs = $self->current_user->pref->pref_descriptions;
    for( @$prefs ) {
        my $method = $_->{ method };
        my $value = $self->param( $method );
        $self->current_user->pref->$method( $value );
    }
    $self->current_user->pref->save;
    $self->home( 1 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# this runmode is called from other scripts that need to change one pref
# and then return
sub save_one {
    my $self = shift;

    my $pref = $self->param( 'pref' );
    my $value = $self->param( 'value' );
    $self->current_user->pref->$pref( $value );
    $self->current_user->pref->save;

    if( my $return_to = $self->param( 'return_to' )) {
        return $self->redirect_to( $return_to, $self->client->id );
    }
    else {
        $self->home( 1 );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub change_password {
    my $self = shift;

    return $self->home
        if $self->errors;

    my $person = $self->current_user;
    my $crypt_current = $person->crypt_password(
        $person->login,
        $self->param( 'password' ),
    );
    my $crypt_new = $person->crypt_password(
        $person->login,
        $self->param( 'new_password' ),
    );

    $self->add_error( 'password', 'password',
        '<strong>Password</strong> must be your current login password.')
        unless( $crypt_current eq $person->password );

    $self->add_error( 'new_password', 'new_password',
        '<strong>Password</strong> and <strong>verify password</strong> must match.')
        unless( $self->param( 'new_password' ) eq $self->param( 'new_password2' ));

    return $self->home
        if $self->errors;
    $person->password( $crypt_new );
    $person->save;
    $self->home;
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
