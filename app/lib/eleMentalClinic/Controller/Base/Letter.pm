package eleMentalClinic::Controller::Base::Letter;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Letter

=head1 SYNOPSIS

Base Letter Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/6633' ],
        script => 'letter.cgi',
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias  => 'Cancel',
        },
        rolodex_create_letter => {
            -alias  => 'Cancel',
        },
        save => {
            -alias => 'Save Letter',
            client_id  => [ 'Client', 'required', 'number::integer' ],
            relationship_info  => [ 'Relationship', 'required', ],
        },
        view => {
            -alias => 'View Letter',
        },
        print => {
            letter_id  => [ 'Letter', 'required', 'number::integer' ],
            -alias => [ 'Print Letter', 'Print Letters' ],
        },
        edit => {
            -alias => 'Edit Letter',
        }
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $letter ) = @_;

    $letter ||= $self->get_letter;
    $self->override_template_name( 'home' );
    return {
        current => $letter,
        relationships   => $self->get_relationships( $letter ),
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex_create_letter {
    my $self = shift;

    $self->home({
        relationship_role        => $self->param( 'relationship_role' ),
        rolodex_relationship_id  => $self->param( 'rolodex_relationship_id' ),
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;
    # FIXME -- doesn't know what do do if letter_id is missing
    my $letter = eleMentalClinic::Client::Letter->new({
        rec_id => $self->param( 'letter_id' )
    })->retrieve;

    #$self->template->vars({ styles => [ 'layout/5050', 'roi' ]});
    $self->override_template_name( 'home' );
    return {
        current => $letter,
        op      => $self->op,
        relationships   => $self->get_relationships( $letter ),
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    unless( $self->errors ) {
        my $letter = eleMentalClinic::Client::Letter->new({ $self->Vars });
        $letter->rec_id( $self->param( 'letter_id' ));
        $letter->sent_date( $self->today );

        # this is a bit of a hack, but it works (he types, before he's written the code ...)
        my( $relationship_role, $rolodex_relationship_id ) = split /-/ => $self->param( 'relationship_info' );
        $letter->relationship_role( $relationship_role );
        $letter->rolodex_relationship_id( $rolodex_relationship_id );

        $letter->save;
    }
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub view {
    my $self = shift;

    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print {
    my $self = shift;

    # FIXME -- ignores errors
    my @ids = ref $self->param( 'letter_id' ) eq 'ARRAY'
        ? @{ $self->param( 'letter_id' )}
        : $self->param( 'letter_id' );

    my @letters;
    push @letters => eleMentalClinic::Client::Letter->new({ rec_id => $_ })->retrieve
        for @ids;

    $self->template->vars({
        styles => [ 'layout/6633' ],
    });

    return {
        letters => \@letters,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_letter {
    my $self = shift;

    # FIXME -- doesn't know what do do if letter_id is missing
    # catch if they've selected multiple letters
    my $rec_id = ref $self->param( 'letter_id' ) eq 'ARRAY'
        ? $self->param( 'letter_id' )->[0]
        : $self->param( 'letter_id' );

    eleMentalClinic::Client::Letter->new({
        rec_id => $rec_id || undef
    })->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME
# need to find and insert current relationship, if one exists and
# it's not shown by current user preferences
#
# return a hash with all relationships by user preference
# key   = $relationship_role-$relationship_id
# value = $relationship.rolodex.formatted_name ($relationship_role)
sub get_relationships {
    my $self = shift;
    my( $letter ) = @_; # XXX do something with this

    my $all = $self->current_user->client_all_relationships_by_pref( $self->client->id );
    return unless $all;

    my @data;
    for my $type( keys %$all ) {
        for my $rel( @{ $all->{ $type }->{ relationships }}) {
            push @data => {
                key => $type .'-'. $rel->rec_id,
                val =>  $rel->rolodex->eman_company .' ['. $all->{ $type }->{ description } .']'
            };
        }
    }
    @data = sort { $b->{ val } cmp $a->{ val }} @data;
    \@data;
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
