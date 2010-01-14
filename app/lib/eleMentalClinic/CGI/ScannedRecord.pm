# vim: ts=4 sts=4 sw=4
package eleMentalClinic::CGI::ScannedRecord;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::CGI::ScannedRecord

=head1 SYNOPSIS

Abstract controller providing shared methods for the Scanned Records
functions.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;

# XXX this controller, eleMentalClinic::ScannedRecord, and the code that uses
# them both in Venus are not very consistent about using 'record' vs. 'file' to
# refer to either the scanned files or the database rows that go with them.

sub send_record_file {
    my $self = shift;
    my ( $record ) = @_;
    return $self->send_file({
        path      =>  $record->path,
        mime_type => $record->mime_type,
        name      => $record->filename,
    });
}

'eleMental';

=head1 AUTHORS

=over 4

=item Josh Partlow L<jpartlow@opensourcery.com>

=item Hans Dieter Pearcey L<hdp@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2008 OpenSourcery, LLC

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
