package eleMentalClinic::Controller::Base::RolodexCleanup;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::RolodexCleanup

=head1 SYNOPSIS

Base RolodexCleanup Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Rolodex;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'rolodex_cleanup.cgi',
        styles => [ "layout/3366", 'rolodex_cleanup' ],
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        cache_similar => {
            -alias => 'Refresh List',
        },
        plan_merge => {
            -alias => 'Cleanup Chosen Entries >>',
        },
        merge => {
            -alias => 'Merge >>',
            name => [ 'Name' ],
        }
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my $message = shift || '';
    my( @similar_rolodex, $rolodex_entries );

    if( $self->param( 'all_rolodex' ) ){
        $rolodex_entries = eleMentalClinic::Rolodex->new->get_all;
    }
    else {
        my $rolodex_ids = eleMentalClinic::Rolodex->new->similar_entries;
            for( keys %$rolodex_ids ){
            if( $rolodex_ids->{ $_ } > 1 ){
                my $rolodex = eleMentalClinic::Rolodex->new({ rec_id => $_ })->retrieve;
                $rolodex->{ num_match } = $rolodex_ids->{ $_ };
                push @similar_rolodex => $rolodex;
            }
        }
        
        my @rolodex_entries = sort { $b->{ num_match } <=> $a->{ num_match } } @similar_rolodex;
        $rolodex_entries = \@rolodex_entries;
    }
        
    $self->template->process_page( 'rolodex_cleanup/home', {
        rolodex_entries => $rolodex_entries,
        message => $message,
        err_note => 'Error',
        modified => eleMentalClinic::Rolodex->new->similar_modified,
        all_rolodex => $self->param( 'all_rolodex' ) || 0,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub plan_merge {
    my $self = shift;
    
    my $rolodex_id = $self->param( 'rolodex_id' );
    my $rolodex_ids;
    
    if( $self->param( 'custom' ) ){
        my @ids;
        for( $self->param ){
            push @ids => $1 if $_ =~ /plan_(\d*)/;
        }

        my @rolodex_matching;
        push @rolodex_matching => eleMentalClinic::Rolodex->new({ rec_id => $_ })->retrieve for @ids;

        $self->template->process_page( 'rolodex_cleanup/plan_merge', {
            rolodex_matching => \@rolodex_matching,
            custom => 1,
            dept_id => $self->current_user->dept_id,
        });
    }
    else {
        $rolodex_ids = eleMentalClinic::Rolodex->new->matching_ids( $rolodex_id ); 
    
        my @rolodex_matching;
        push @rolodex_matching => eleMentalClinic::Rolodex->new({ rec_id => $_ })->retrieve for @$rolodex_ids; 

        my $chosen = eleMentalClinic::Rolodex->new({ rec_id => $rolodex_id })->retrieve;
    
        $self->template->process_page( 'rolodex_cleanup/plan_merge', {
            rolodex_matching => \@rolodex_matching,
            rolodex => $chosen,
        });
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub merge {
    my $self = shift;
    my @merge_ids;
    

    for( $self->param ){
        push @merge_ids => $1 if $_ =~ /merge_(\d*)/;
    }
    
    my $vars = $self->Vars;
    $vars->{ 'rec_id' } = shift @merge_ids;
    
    my $rolodex = eleMentalClinic::Rolodex->new({
        %$vars,
        dept_id => 1001,
    });
    $rolodex->save;
            
    my $success = 'Merge rolodex entries succeeded.';
    unless( $rolodex->merge( \@merge_ids ) ) {
        # hack - add_error requires a parameter, so give it a random one
        $self->add_error( 'name', 'name', 'Merge rolodex entries failed.' );
        $success = '';
    }

    eleMentalClinic::Rolodex->new->cache_similar;
    $self->home( $success );
}    

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub cache_similar {
    my $self = shift;
    
    eleMentalClinic::Rolodex->new->cache_similar;
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
