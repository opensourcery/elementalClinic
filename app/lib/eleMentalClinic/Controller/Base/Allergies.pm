package eleMentalClinic::Controller::Base::Allergies;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Allergies

=head1 SYNOPSIS

Base Allergies Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/5050', 'gateway' ],
        script => 'allergies.cgi',
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        save => {
            client_id => [ 'Client', 'required' ],
            allergy => [ 'Allergy', 'required', 'text::words' ],
            active  => [ 'Active', 'checkbox::boolean' ],
        },
        edit => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $current ) = @_;

    return {
        current => $current,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    my $current = $self->Vars;
    $self->override_template_name( 'home' );
    if( $self->errors ) {
        return $self->home( $current );
    }
    else {
        my $aid = $self->param( 'allergy_id' );
        my $allergy = $aid ? eleMentalClinic::Client::Allergy->retrieve( $aid )
                           : eleMentalClinic::Client::Allergy->new( $current );

        $allergy->allergy( $self->param( 'allergy' ));
        $allergy->created( $self->today ) unless $allergy->created;
        $allergy->active( $aid ? $self->param( 'active' ) : 1 );

        $allergy->save;
        return $self->home;
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;

    my $current = eleMentalClinic::Client::Allergy->retrieve( $self->param( 'allergy_id' ));
    $self->override_template_name( 'home' );
    return {
        %{ $self->home( $current ) },
        op => 'edit',
    }
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

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
