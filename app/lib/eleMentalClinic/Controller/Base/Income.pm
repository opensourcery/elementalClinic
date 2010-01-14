package eleMentalClinic::Controller::Base::Income;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Income

=head1 SYNOPSIS

Base Income Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Client::Income;
use eleMentalClinic::Client::IncomeMetadata;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/6633', 'income', 'date_picker' ],
        script => 'income.cgi',
        javascripts => [ 'jquery.js', 'date_picker.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias => 'Cancel',
        },
        save => {
            -alias => 'Save',
            income_amount => [ 'Income', 'number::decimal' ],
            has_direct_deposit => [ 'Direct Deposit?', 'checkbox::boolean' ],
            is_recurring_income => [ 'Recurring?', 'checkbox::boolean' ],
            start_date  => [ 'From date', 'date::iso' ],
            end_date  => [ 'To date', 'date::iso' ],
            certification_date  => [ 'Certification date', 'date::iso' ],
            recertification_date  => [ 'Recertification date', 'date::iso' ],
        },
        save_meta => {
            self_pay => [ 'Self pay', 'checkbox::boolean' ],
            rep_payee => [ 'Representative payee', 'checkbox::boolean' ],
        },
        edit => {
            rec_id  => [ 'Record ID', 'required' ],
        },
        view => {
            rec_id  => [ 'Record ID', 'required' ],
        },
        create => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $current ) = @_;

    $self->override_template_name( 'home' );
    return {
        current => $current,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub view {
    my $self = shift;
    my $current = $self->get_income;
    $self->home( $current );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;
    my $current = $self->get_income;
    return {
        %{ $self->home( $current ) },
        op => 'edit'
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
    my $self = shift;
    return {
        %{ $self->home },
        op => 'create'
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    $self->date_check( 'start_date', 'end_date' );
    $self->date_check( 'certification_date', 'recertification_date' );
    my $current = $self->Vars;
    unless( $self->errors ) {
        $current = eleMentalClinic::Client::Income->new( $current );
        $current->save;
    }
    return {
        %{ $self->home( $current )},
        op => 'save'
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_meta {
    my $self = shift;

    my $vars = $self->Vars;
    $vars->{ $_ } = $vars->{ $_ } ? 1 : 0
        for qw/ self_pay rep_payee /;
    eleMentalClinic::Client::IncomeMetadata->new( $vars )->save;
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_income {
    my $self = shift;

    eleMentalClinic::Client::Income->new({
        rec_id => $self->param( 'rec_id' ),
    })->retrieve;
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
