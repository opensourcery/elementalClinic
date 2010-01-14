package eleMentalClinic::Client::Release;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Client::Release

=head1 SYNOPSIS

Release of information letter and history.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::ValidData;
use eleMentalClinic::Rolodex;
use eleMentalClinic::Client;
use Data::Dumper;

# FIXME, nasty hack, fix will refactor valid_data tables
my @SENSITIVE = ( 1, 2, 3 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_release' }
    sub fields { [ qw/
        rec_id client_id rolodex_id
        print_date renewal_date release_list standard
        print_header_id release_from release_to
        active
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my $self = shift;
    my( $client_id ) = @_;

    $client_id ||= $self->client_id;
    return unless $client_id;
    my $class = ref $self;
    
    my $where = "WHERE client_id = $client_id";
    my $order_by = "ORDER BY print_date DESC, renewal_date";
    my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results if @results;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub history {
    my ( $self, $client_id, $show_expired ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;
    my $class = ref $self;
    
    my $where = "WHERE client_id = $client_id";
    unless( $show_expired ) {
        $where .= " AND renewal_date >= current_date";
    }
    my $order_by = "ORDER BY print_date DESC, renewal_date";
    my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results if @results;
    return;
}

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#sub rolodex {
#    my $self = shift;
#    my( $rolodex_release_id ) = @_;
#
#    $rolodex_release_id ||= $self->rolodex_release_id;
#    my $rec_id = $self->rec_id;
#    return unless $rolodex_release_id or $rec_id;
#
#    unless ( $rolodex_release_id ) {
#        my $where = "rec_id = $rec_id";
#        $rolodex_release_id = $self->db->select_one( $self->fields, $self->table, $where)->{ rolodex_release_id };
#    }
#
#    my $rolodex_id = $self->db->select_one( ['rolodex_id'], 'rolodex_release', "rec_id = $rolodex_release_id" )->{rolodex_id};
#    return unless $rolodex_id;
#
#    eleMentalClinic::Rolodex->new({
#        rec_id => $rolodex_id,
#    })->retrieve;
#}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub valid_data_release_list {
    my $self = shift;

    my $list = eleMentalClinic::ValidData->new({ dept_id => 1001 })->list( '_release' );
    return( undef ) unless $list;
    $list;
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# accepts an arrayref of integers (rec_ids)
# without it, uses internal release_list
# returns a sorted arrayref of names
sub release_list_names {
    my $self = shift;
    my( $ids ) = @_;

    $ids ||= [ split /,/ => $self->release_list ]
        if $self->release_list;

    return unless
        ref $ids eq 'ARRAY' and $ids->[ 0 ];
    my @names;
    for( @{ $self->valid_data_release_list }) {
        my $rec_id = $_->{ rec_id }; 
        push @names => $_->{ name }
            if( grep /^$rec_id$/ => @$ids );
    }
    return unless @names;
    [ sort @names ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub release_list_keyval {
    my $self = shift;

    return unless $self->release_list;
    my @list;
    for( @{ $self->valid_data_release_list }) {
        my $rec_id = $_->{ rec_id }; 
        push @list => { $rec_id => $_->{ name }}
            if( grep /^$rec_id$/, split /,/, $self->release_list );
    }
    return unless $list[0];
    \@list;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client {
    my $self = shift;

    eleMentalClinic::Client->new({ client_id => $self->client_id })->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO this could be generated automagically by base:
# (if the object has a field that is one of the valid_data fields, generate a sub like this)
sub print_header {
    my $self = shift;
    return unless $self->print_header_id;

    return unless my $hashref = eleMentalClinic::ValidData->new({dept_id => 1001})->get( '_print_header', $self->print_header_id );
    $hashref->{ description };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub rolodex {
    my $self = shift;
    return unless my $rolodex_id = $self->rolodex_id;

    eleMentalClinic::Rolodex->new->get_one( $rolodex_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub release_listref {
    my $self = shift;

    return unless $self->release_list;
    my @list = split /,/ => $self->release_list;
    [ sort { $a <=> $b } @list ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub release_list_sensitive {
    my $self = shift;
    $self->release_list_sensitive_and_normal->[ 0 ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub release_list_normal {
    my $self = shift;
    $self->release_list_sensitive_and_normal->[ 1 ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub release_list_sensitive_names {
    my $self = shift;

    return unless my $list = $self->release_list_sensitive_and_normal->[ 0 ];
    $self->release_list_names( $list );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub release_list_normal_names {
    my $self = shift;

    return unless my $list = $self->release_list_sensitive_and_normal->[ 1 ];
    $self->release_list_names( $list );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns ( $sensitive, $normal )
# where each variable is a sorted arrayref of ids, or undef
sub release_list_sensitive_and_normal {
    my $self = shift;

    return [ undef, undef ]
        unless my $releases = $self->release_listref;
    my( @sensitive, @normal );
    for my $r( @$releases ) {
        ( grep /^$r$/ => @SENSITIVE )
            ? push @sensitive   => $r
            : push @normal      => $r;
    }
    [ # return an arrayref or undef for each list
        @sensitive  ? \@sensitive   : undef,
        @normal     ? \@normal      : undef
    ]
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns ( $sensitive, $normal )
# where each variable is a sorted arrayref of ids, or undef
sub site_release_list_sensitive_and_normal {
    my $self = shift;

    return [ undef, undef ]
        unless my $releases = $self->valid_data_release_list;
    my( @sensitive, @normal );
    for my $r( @$releases ) {
        my $id = $r->{ rec_id };
        ( grep /^$id$/ => @SENSITIVE )
            ? push @sensitive   => $r
            : push @normal      => $r;
    }
    [ # return an arrayref or undef for each list
        @sensitive  ? \@sensitive   : undef,
        @normal     ? \@normal      : undef
    ]
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub site_release_list_sensitive {
    my $self = shift;
    $self->site_release_list_sensitive_and_normal->[ 0 ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub site_release_list_normal {
    my $self = shift;
    $self->site_release_list_sensitive_and_normal->[ 1 ];
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
