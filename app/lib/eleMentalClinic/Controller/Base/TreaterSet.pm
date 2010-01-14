package eleMentalClinic::Controller::Base::TreaterSet;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::TreaterSet

=head1 SYNOPSIS

Base TreaterSet Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Client;
use eleMentalClinic::Personnel;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'set_treaters.cgi',
        styles => [ 'layout/3366', ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        associate => {
            'treater_id'    => [ 'Treater ID', 'required', 'number::integer' ],
            'staff_id'      => [ 'Staff ID', 'required', 'number::integer' ],
        },
        delete_item => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;

    my $staff = $self->current_user->get_all();
    my $rolodex = eleMentalClinic::Rolodex->new();
    my $treaters = $rolodex->get_byrole('treaters');
    my @current_treaters;

    # TODO: get a list of staff who are treaters already.
    # we're going to have to iterate through all the users,
    # then check to see who of them are treaters already.
    my $new_staff;
    foreach (@$staff) {
        
        push @$new_staff, $_;
        next unless(defined $_->rolodex_treaters_id);
        
        my $rolo_treater = eleMentalClinic::DB->new();
        my $where = 'rec_id = ' . $_->rolodex_treaters_id;
        my $href = $rolo_treater->select_one(['rolodex_id'], 'rolodex_treaters', $where);
        next unless(my $rolo = eleMentalClinic::Rolodex->new()->get_one($href->{rolodex_id}));

        push @current_treaters, { staff_id => $_->staff_id,
                                    login   => $_->login,
                                    fname   => $_->fname,
                                    lname   => $_->lname,
                                    name    => $rolo->name_f,
                                };
    }

    $self->template->process_page( 'personnel/set_treaters', {
        staff => $new_staff,
        treaters => $treaters,
        current_treaters => \@current_treaters,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub associate {
    my $self = shift;
    
    unless( $self->errors ) {
        $self->home if $self->errors;
        # find the rolodex_treater record for the given treater
        my $rolo_treater = eleMentalClinic::DB->new();
        my $where = "rolodex_id = " . $self->param( 'treater_id' );
        my $href = $rolo_treater->select_one(['rec_id'], 'rolodex_treaters', $where);

        # now get the personnel object for the given user.
        # and set the rolodex_treaters_id field.
        my $person = eleMentalClinic::Personnel->new( {
                    staff_id => $self->param( 'staff_id'),
                    } );
        $person->retrieve;
        $person->rolodex_treaters_id($href->{rec_id});
        $person->save();
    }
    $self->home; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub delete_item {
    my $self = shift;

    # and set the rolodex_treaters_id field for the given staff person to NULL
    my $person = eleMentalClinic::Personnel->new( {
                    staff_id => $self->validop->param( 'staff_id'),
                    } );
    $person->retrieve;
    $person->rolodex_treaters_id('');
    $person->save();

    $self->home(); 
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
