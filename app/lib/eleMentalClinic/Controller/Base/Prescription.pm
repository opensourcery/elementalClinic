package eleMentalClinic::Controller::Base::Prescription;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Prescription

=head1 SYNOPSIS

Base Prescription Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Client::Medication;
use Data::Dumper;
use Date::Calc qw/ Today /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'prescription.cgi',
        styles => [ 'layout/6633', 'prescription', 'date_picker' ],
        print_styles => [ 'layout/6633', 'prescription' ],
        javascripts => [ 'jquery.js', 'date_picker.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias  => 'Cancel',
        },
        create => {},
        save => {
            -alias  => 'Save Prescription',
            client_id   => [ 'Client', 'required', 'number::integer' ],
            quantity    => [ 'Quantity', 'number::integer' ],
            num_refills => [ 'Refills', 'number::integer' ],
            start_date  => [ 'Date', 'required', 'date::iso' ],
        },
        edit => {
            prescription_id => [ 'Prescription', 'required' ],
        },
        view => {
            prescription_id => [ 'Prescription', 'required' ],
        },
        print => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $scrip, $op ) = @_;

    my $person = eleMentalClinic::Personnel->new({ staff_id => $self->current_user->id })->retrieve;

    $self->override_template_name( 'home' );
    return {
        current => $scrip,
        staff   => $person,
        op      => $op || $self->op,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
    my $self = shift;
    $self->home( undef, 'create' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    my $vars = $self->Vars;

    if( $self->errors ) {
        $self->home( $vars, 'create' );
    }
    else {
        #  is the user always the treater? 
        # yes. but we need to get the rolodex treaters id in a roundabout way.
        my $person = eleMentalClinic::Personnel->new({
            staff_id => $self->current_user->id
        })->retrieve;

        # TODO if there's no $person->rolodex_treaters_id that means
        # they aren't a treater, and so should not allowed to do this.
        $vars->{ rolodex_treaters_id } = $person->rolodex_treaters_id;
        my $scrip = eleMentalClinic::Client::Medication->new( $vars )->save;
        $self->home( $scrip );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;

    my $scrip = eleMentalClinic::Client::Medication->new({
        rec_id => $self->param( 'prescription_id' )})->retrieve;
    $self->home( $scrip, 'edit' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub view {
    my $self = shift;

    my $scrip = eleMentalClinic::Client::Medication->new({
        rec_id => $self->param( 'prescription_id' )
    })->retrieve;

    $self->override_template_name( 'home' );
    return {
        current => $scrip,
        op      => 'view',
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print {
    my $self = shift;

    my( @printscrips, $treater );
    my $vars = $self->Vars;
    my $client = $self->client;

    # loop through all the scrips checked to print
    for( keys %$vars ) {
        if( /print_(\d+)/ ) {
            my $scrip = eleMentalClinic::Client::Medication->new({ rec_id => $1 })->retrieve;
            next unless ( ( ! defined $scrip->print_date ) or $self->current_user->admin );
            # TODO : skip any scrip not written by current user. (??)
            push @printscrips, $scrip;
        }
    }

    # don't do a bunch of stuff if there's no scrips.
    if( @printscrips > 0 ) {
        # get the treater.  use first one, cuz
        # they're all gonna be the same cuz we're not letting
        # users print someone else's scrips.
        $treater = $printscrips[0]->rolodex;

        foreach ( @printscrips ) {
            $_->print_date( $self->today );
            $_->save();
        }
        
        my $printdata = {
            printscrips => \@printscrips,
            treater     => $treater,
            action  => 'Print',
        };
        # print_header may be null
        # TODO : look through the rest of the prescriptions for a header
        $printdata->{ print_header } = $printscrips[0]->print_header;
        
        $self->template->process_page( 'prescription/print', $printdata );
    }
    else {
        $self->home( undef, 'home' );
    }

}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

=item Ryan Whitehurst L<ryan@opensourcery.com>

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
