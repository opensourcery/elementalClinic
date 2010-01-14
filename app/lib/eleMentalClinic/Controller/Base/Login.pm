package eleMentalClinic::Controller::Base::Login;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Login

=head1 SYNOPSIS

Base Login Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use CGI qw/ redirect /; # FIXME rather not use this
use eleMentalClinic::Personnel;
use eleMentalClinic::Log;
use Data::Dumper;


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'login' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home  => { previous => [ undef, 'text::liberal' ], },
        login => {
            login    => [ 'Login',    'required' ],
            password => [ 'Password', 'required' ],
            previous => [ undef,      'text::liberal' ],
        },
        expired => { 
            -alias => [ 'Save Password' ],
            new_password_a => [ 'New Password', 'required', 'text::liberal', 'length(6,24)' ],
            new_password_b => [ 'Verify New Password', 'required', 'text::liberal', 'length(6,24)' ],
            previous => [ undef,      'text::liberal' ],
        },
        logout     => { previous => [ undef, 'text::liberal' ], },
        check      => { previous => [ undef, 'text::liberal' ], },
        logged_out => {},
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# over ride parent's method since it does login checking
sub run_cgi {
    my($self, $uri_and_path) = @_;
    return $self->display_page;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;

    $self->override_template_name( 'login' );
    return {
            previous    => $self->param( 'previous' ),
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub login {
    my $self = shift;

    my $user = eleMentalClinic::Personnel->authenticate(
        $self->param( 'login' ),
        $self->param( 'password' ),
    );

    $self->add_error( 'login', 'credentials', 'Login or password incorrect.' )
    unless $user or $self->errors;

    if( $self->errors ) {
        my $label = $self->param( 'login' ) || '';
        Log({
            type => 'security',
            user => $label,
            action => 'failure',
        });
        return $self->home;
    }

    if ( $user->pass_has_expired ) {
        $self->session->param( expired_id => $user->id );
        return $self->expired( $user );
    }
    return $self->finish( $user );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub expired {
    my $self = shift;
    my ( $user ) = @_;
    my $user_id = $self->session->param( 'expired_id' );
    return $self->home unless $user or $user_id;
    $user ||= eleMentalClinic::Personnel->retrieve( $user_id );

    if ( my $new_pass = $self->param( 'new_password_a' )) {
        my $crypt_new = $user->crypt_password(
            $user->login,
            $new_pass,
        );

        $self->add_error( 'new_password_a', 'new_password_a',
            '<strong>New Password</strong> and <strong>Verify New Password</strong> must match.')
            unless( $self->param( 'new_password_a' ) eq $self->param( 'new_password_b' ));

        $self->add_error( 'new_password_a', 'new_password_a',
            'New password cannot be the same as your old password.')
            if ( $crypt_new eq $user->password );

        unless ( $self->errors ) {
            $user->update_password( $crypt_new );
            return $self->finish( $user );
        }
    }

    $self->override_template_name( 'expired' );
    return {
        previous => $self->param( 'previous' ),
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub finish {
    my $self = shift;
    my ( $user ) = @_;
    $self->SUPER::login( $user );
    Log({
        type => 'security',
        user => $user,
        action => 'Login',
    });
    return(
        undef,
        {
            Location => '/login.cgi?op=check&previous='
            . ( CGI::escape( $self->param( 'previous' ))
                || '' )
        }
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub check {
    my ($self) = @_;

    return $self->home
        unless $self->SUPER::login;

    my $previous = $self->param( 'previous' ) || '/index.cgi';
    $previous = $self->validop->cgi_object->url(-base => 1) . $previous;

    return '', { Location => $previous }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub logout {
    my $self = shift;

    # baking cookie now since SUPER::logout kills session
    my $cookie = $self->bake_cookie( -expires => '-1y' );
    if( $self->current_user ) {
        my $user = $self->current_user;
        $self->SUPER::logout;
        Log({
            type => 'security',
            user => $user,
            action => 'Logout',
        });
    }

    return '', { 
        Location => '/login.cgi?op=logged_out',
        'Set-Cookie' => $cookie
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub logged_out {
    my $self = shift;
    $self->template->process_page( 'login/login', {
            full_screen => 1, # FIXME should be in template
            logged_out  => 1,
        });
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

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
