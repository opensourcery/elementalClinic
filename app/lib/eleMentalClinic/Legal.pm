package eleMentalClinic::Legal;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Legal

=head1 SYNOPSIS

Client legal history.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use eleMentalClinic::ValidData;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'client_legal_history' }
    sub fields { [ qw/
        rec_id client_id status_id location_id
        reason start_date end_date comment_text
    /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my $self = shift;
    my ( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    my $class = ref $self;
    
    my $where = "WHERE client_id = $client_id";
    my $order_by = "ORDER BY end_date";

    return unless my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub history {
    my $self = shift;
    $self->get_all(@_);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub location {
    my $self = shift;
    my( $dept_id ) = @_;
    return unless $self->location_id and $dept_id;
    
    return unless my $vd = eleMentalClinic::ValidData->new({
        dept_id => $dept_id,
    })->get( '_legal_location', $self->location_id );

    $vd->{ name };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub status {
    my $self = shift;
    my( $dept_id ) = @_;
    return unless $self->status_id and $dept_id;
    
    return unless my $vd = eleMentalClinic::ValidData->new({
        dept_id => $dept_id,
    })->get( '_legal_status', $self->status_id );

    $vd->{ name };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub past_issues {
    my $self = shift;
    my( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    my $class = ref $self;
    
    my $where = "WHERE client_id = $client_id and end_date < now()";
    my $order_by = "ORDER BY start_date IS NULL, start_date DESC, rec_id DESC";

    return unless my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub current_issues {
    my $self = shift;
    my( $client_id ) = @_;
    $client_id ||= $self->client_id;
    return unless $client_id;

    my $class = ref $self;
    
    my $where = "WHERE client_id = $client_id and (end_date > now() OR end_date IS NULL)";
    my $order_by = "ORDER BY start_date DESC";

    return unless my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where, $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_current {
    my $self = shift;
    my $start_date = $self->start_date;
    my $end_date = $self->end_date;
    return unless $start_date or $end_date;

    use Date::Calc qw/ Date_to_Days Today /;
    
    my( $starts_before, $ends_after );

    my $result;
    if( $start_date ){
        # TODO make this a method in base
        $start_date =~ m/(\d+)-(\d+)-(\d+)/;
        $starts_before = 1 
            if Date_to_Days( $1,$2,$3 ) 
            <= Date_to_Days( Today() );
    }
    if( $end_date ){
        $end_date =~ m/(\d+)-(\d+)-(\d+)/;
        $ends_after = 1 
            if Date_to_Days( $1,$2,$3 ) 
            >= Date_to_Days( Today() );
    }

    return 1 if( $starts_before and $ends_after )
        or ( $starts_before and not $end_date )
        or ( $ends_after and not $start_date );

    return;
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
