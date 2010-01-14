package eleMentalClinic::CGI::SC23;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::CGI::SC23

=head1 SYNOPSIS

For working with the (legacy) SQLClinic 2.3 CGI scripts.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use CGI qw/ header /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->{ user } = $self->current_user;
    $self->{ module } = $args->{ module };
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub user {
    my $self = shift;
    $self->current_user;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print_header {
    my $self = shift;
    my( $title, $options ) = @_;

    my $in_root = 1 if defined $options->{ in_root };

    my %cookie = $self->bake_login_cookie;
    print header(
        -type    => 'text/html',
        -expires => '-1d',
        %cookie,
    );
    print $self->template->process_page( 'global/header', {
        current_user    => {
            id => $self->{ user }->{ staff_id },
            fname => $self->{ user }->{ fname },
            lname => $self->{ user }->{ lname },
            admin => $self->{ user }->{ admin },
        },
        sc23module  => $self->{ module },
        sc23title   => $title,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub secure {
    my $self = shift;
    return 1 if $self->{ user }->admin;

    $self->print_header;
    print $self->template->process_page('login/security_check');
    $self->print_footer;
    exit;
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
