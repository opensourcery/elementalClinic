package eleMentalClinic::Controller::Base::Diagnosis;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Diagnosis

=head1 SYNOPSIS

Base Diagnosis Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Client::Diagnosis;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'diagnosis.cgi',
        styles => [ 'layout/6633', 'feature/selector', 'diagnosis', 'date_picker' ],
        javascripts  => [
            'diagnosis_codes.js',
            'client_filter.js',
            'jquery.js',
            'date_picker.js'
        ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias  => 'Cancel',
        },
        view => {},
        edit => {},
        create => {
            -alias  => 'New diagnosis',
        },
        display_edit => {},
        save => {
            -alias  => 'Save diagnosis',
            diagnosis_date  => [ 'Diagnosis date', 'date::iso', 'required' ],
            client_id       => [ 'Client', 'required' ]
        },
        clone => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $diagnosis ) = @_;

    my $history = $self->client->diagnosis_history;
    my $current_diagnosis = $diagnosis      ? $diagnosis
                          : $history        ? $history->[ 0 ]
                          :                 undef;

    return {
        diagnoses => $history,
        current_diagnosis => $current_diagnosis,
        op => 'view',
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub view {
    my $self = shift;

    $self->override_template_name( 'home' );
    $self->home( $self->get_diagnosis );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;

    $self->override_template_name( 'home' );
    return {
        %{ $self->home( $self->get_diagnosis )},
        op => 'edit',
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
    my $self = shift;
    return {
        %{ $self->display_edit },
        op => 'create',
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub clone {
    my $self = shift;

    my $diagnosis = $self->get_diagnosis;
    if( $diagnosis ) {
        $diagnosis->rec_id( '' );
        $diagnosis->diagnosis_date( '' );
    }
    return {
        %{ $self->display_edit( $diagnosis )},
        op => 'clone',
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub display_edit {
    my $self = shift;
    my( $diagnosis ) = @_;

    $self->override_template_name( 'home' );
    return {
        current_diagnosis     => $diagnosis || undef,
        diagnoses => $self->client->diagnosis_history || undef,
        op => 'edit',
    };
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    my $current = $self->Vars;
    unless( $self->errors ) {
        for( keys %$current ) {
            $current->{ $_ } = $current->{ $_ ."_manual" } if $current->{ $_ ."_manual" };
        }
        $current->{ rec_id } = $current->{ diagnosis_id };
        $current = eleMentalClinic::Client::Diagnosis->new( $current );
        $current->save;
    }
    $self->override_template_name( 'home' );
    $self->home( $current );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_diagnosis {
    my $self = shift;
    my( $diagnosis_id ) = @_;
    $diagnosis_id ||= $self->param( 'diagnosis_id' );

    return unless $diagnosis_id;
    my $diagnosis = eleMentalClinic::Client::Diagnosis->retrieve( $diagnosis_id );
    return unless $diagnosis->id;
    return $diagnosis;
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
