package eleMentalClinic::Controller::Base::ROI;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::ROI

=head1 SYNOPSIS

Base ROI Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Rolodex;
use eleMentalClinic::ValidData;
use Data::Dumper;
use Date::Calc qw/ Today Add_Delta_YM /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );

    $self->template->vars({
        styles => [ 'layout/5050', 'roi', 'date_picker' ],
        print_styles => [ 'roi', 'roi_print' ],
        script => 'roi.cgi',
        javascripts => [ 'jquery,js', 'date_picker.js' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias   => 'Cancel',
        },
        save => {
            -alias => 'Save Letter',
            release_to  => [ 'Release to', 'checkbox::boolean' ],
            release_from  => [ 'Release from', 'checkbox::boolean' ],
            renewal_date  => [ 'Renewal date', 'date::iso' ],
        },
        create => {
            -alias => 'New Letter',
        },
        edit => {
            -alias => 'Edit Letter',
        },
        view => {
            -alias => 'View Letter',
        },
        print => {
            roi_id  => [ 'Release history', 'required', 'number::integer' ],
            -alias  => [ 'Print Letter', 'Print Letters' ],
        },
        clone => {
            -alias  => 'Clone Letters',
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;

    my $release = $self->get_release;
    $self->template->process_page( 'roi/home', {
        current => $release,
        op      => $self->op,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $vars ) = @_;

    $vars->{ current } ||= $self->get_release;
    $self->template->process_page( 'roi/home', {
        %$vars,
        op      => $self->op,
        year_from_today => $self->year_from_today,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
    my $self = shift;

    my $rolodex = eleMentalClinic::Rolodex->new({
        rec_id => $self->param( 'rolodex_id' )})->retrieve;

    $self->home({
        rolodex => $rolodex,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    my( @release_ids );
    for( @{eleMentalClinic::ValidData->new({dept_id=>1001})->list( '_release' )}) { # FIXME dept_id
        push @release_ids, $_->{ rec_id } if defined $self->param( 'info_'.$_->{ rec_id } );
    }

    $self->add_error( 'release_to', 'release_to', 'You must select <strong>Release To</strong>, <strong>Release From</strong>, or both.' )
        unless $self->param( 'release_to' ) or $self->param( 'release_from' );

    my $release = eleMentalClinic::Client::Release->new({ $self->Vars });
    $release->rec_id( $self->param( 'roi_id' ));
    # TODO Why didn't this need to be here before?
    $release->active( 1 );
    unless( $self->errors ) {
        my $client = $self->client;
        my $rolodex = eleMentalClinic::Rolodex->new({
            rec_id => $self->param( 'rolodex_id' )})->retrieve;

        $release->release_list( join ',' => @release_ids );
        $release->save;
    }
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub view {
    my $self = shift;

    $self->home({ current => $self->get_release });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print {
    my $self = shift;

    return $self->home if $self->errors;

    my $releases = $self->get_releases;

    foreach my $release ( @$releases ) {
        $release->print_date( $self->today );
        $release->save;
    }
    
    $self->template->process_page( 'roi/print', {
        releases     => $releases,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub clone {
    my $self = shift;

    # get all the ones selected and clone
    my $releases = $self->get_releases;
    
    foreach my $release ( @$releases ) {
        $release->renewal_date( $self->param( 'clone_renewal_date' )) if $self->param( 'clone_renewal_date' );
        $release->print_date( '' );
        $release->rec_id( 0 );
        $release->save;
    }
    $self->edit; 
}    

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_release {
    my $self = shift;
    my( $release ) = @_;
    
    # catch if they've selected multiple releases
    my $rec_id = ref $self->param( 'roi_id' ) eq 'ARRAY' 
        ? $self->param( 'roi_id' )->[0] 
        : $self->param( 'roi_id' );

    $release ||= eleMentalClinic::Client::Release->new({
        rec_id => $rec_id,
    })->retrieve;

    if( $release->release_list ) {
        $release->{ "info_$_" } = 1
            for( split( /,/, $release->release_list ));
    }
    $release;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_releases {
    my $self = shift;
    
    my @ids = ref $self->param( 'roi_id' ) eq 'ARRAY'
        ? @{ $self->param( 'roi_id' )}
        : $self->param( 'roi_id' );

    my @releases;
    push @releases => eleMentalClinic::Client::Release->new({ rec_id => $_ })->retrieve
        for @ids;

    return \@releases;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub letter {
    my $self = shift;

    # loop over the list of active vd_release entries to find checked boxes
    my ( @release_names, @release_ids );
    for( @{eleMentalClinic::ValidData->new({dept_id=>1001})->list( '_release' )}) {
        push @release_names, $_->{ name } if defined $self->param( 'info_'.$_->{ rec_id } );
        push @release_ids, $_->{ rec_id } if defined $self->param( 'info_'.$_->{ rec_id } );
    }

    my $client = $self->client;
    my $rolodex = eleMentalClinic::Rolodex->new({
        rec_id => $self->param( 'rolodex_id' )})->retrieve;

    eleMentalClinic::Client::Release->new({
        client_id => $client->id,
        rolodex_id => $client->rolodex_getone( 'release', $rolodex->rec_id )->rolodex_id,
        release_list => \@release_ids,
        print_date => $self->today,
    })->save;
    
    $self->template->process_page( 'roi/letter', {
        rolodex  => $rolodex,
        releases => \@release_names,
    });
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub year_from_today {
    my $self = shift;
    my( $year, $month, $day ) = Add_Delta_YM( Today, 1, 0 );
    join( '-', $year, $month, $day );
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
