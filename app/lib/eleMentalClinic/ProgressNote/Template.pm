package eleMentalClinic::ProgressNote::Template;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::ProgressNote::Template

=head1 SYNOPSIS

Template for progress notes; can be inserted into note and customized.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'prognote_valid_data' }
    sub fields { [ qw/
        rec_id data_label data_text
    /] }
    sub primary_key { 'rec_id' }
    #sequence { 'p_num' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all_TEMP {
    [
        {
            rec_id      => 1,
            data_label  => 'foo',
            data_text   => 'bar baz bang',
        },
        {
            rec_id      => 2,
            data_label  => 'i am a template',
            data_text   => 'this is a template.  no, really.',
        },
    ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my $self = shift;
    my $client_id = shift;
    my $class = ref $self;
    my $where = '';

    my $order_by = "ORDER BY note_date";

    if ($client_id) {
	$where = "WHERE client_id = $client_id";
    }
    my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where , $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_by_client_id {
    my $self = shift;
    return unless $self->client_id;
    
    my $class = ref $self;
    my $client_id = $self->client_id;
    my $order_by = "ORDER BY note_date";
	my $where = "WHERE client_id = $client_id";
    
    my $hashrefs = $self->db->select_many( $self->fields, $self->table, $where , $order_by );
    my @results;
    foreach my $hashref (@$hashrefs) {
        push @results, $class->new($hashref) if $hashref;
    }
    return \@results;
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
