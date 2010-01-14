package eleMentalClinic::ProgressNote::Bounced;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::ProgressNote::Bounced

=head1 SYNOPSIS

An L<eleMentalClinic::ProgressNote> object which has been bounced from the
billing cycle to the writer, for correction

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Util;
use eleMentalClinic::ProgressNote;
use Date::Calc qw/ Delta_Days /;
use Data::Dumper;
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'prognote_bounced' }
    sub fields {[ qw/
        rec_id prognote_id bounced_by_staff_id bounce_date bounce_message
        response_date response_message
    /]}
    sub fields_required {[ qw/
        prognote_id bounced_by_staff_id bounce_message
    /]}
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 prognote()

Object method.

Returns the L<eleMentalClinic::ProgressNote> object associated with the calling
object.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub prognote {
    my $self = shift;

    croak 'Must be called on a ProgressNote::Bounced object.'
        unless $self->id and $self->prognote_id;
    return eleMentalClinic::ProgressNote->retrieve( $self->prognote_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_by_prognote_id( $prognote_id )

Class method.

Returns the first active record associated with the given C<prognote_id>, or undef.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_by_prognote_id {
    my $class = shift;
    my( $prognote_id ) = @_;

    return unless $prognote_id;
    my $bounced = $class->db->select_one(
        $class->fields,
        $class->table,
        [ "prognote_id = ? AND response_date IS NULL", $prognote_id ]
    );
    return unless $bounced;
    return $class->new( $bounced );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_by_data_entry_id( $personnel_id )

Class method.

Returns all active records associated with notes written by the given
C<personnel_id>, or undef.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_by_data_entry_id {
    my $class = shift;
    my( $personnel_id ) = @_;

    return unless $personnel_id;

    my $results = $class->db->select_many(
      [ $class->fields_qualified ],
      'prognote_bounced, prognote',
      [
          'prognote_bounced.prognote_id = prognote.rec_id
          AND prognote_bounced.response_date IS NULL
          AND prognote.data_entry_id = ?',
          $personnel_id
      ],
      'ORDER BY prognote_bounced.bounce_date DESC'
    );

    return unless $results and @$results;
    return[ map { $class->new( $_ )} @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_active()

Class method.

Returns all active bounced progress notes, oldest first.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_active {
    my $class = shift;

    return unless my $results = $class->db->select_many(
        $class->fields,
        $class->table,
        'WHERE response_date IS NULL',
        'ORDER BY bounce_date'
    );
    return[ map { $class->new( $_ )} @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 overdue()

Object method.

Returns C<1> (true) if bounce is overdue (i.e. is older than the
C<prognote_bounce_grace> config variable), C<0> (false) otherwise.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub overdue {
    my $self = shift;

    croak 'Must be called on a ProgressNote::Bounced object.'
        unless $self->id;

    my $delta = Delta_Days(
        ( split /-/ => $self->bounce_date ),
        ( split /-/ => $self->today ),
    );
    return 0
        if $self->response_date
        or $delta <= $self->config->prognote_bounce_grace;
    return 1;
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

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
