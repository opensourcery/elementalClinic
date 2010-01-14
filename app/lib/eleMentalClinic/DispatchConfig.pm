=head1 eleMentalClinic::DispatchConfig

Provides one method (Exported), get_dispatch.

=cut

package eleMentalClinic::DispatchConfig;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT = qw(get_dispatch);
use constant DEBUG => 0;

use eleMentalClinic::Theme;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_dispatch {
    my ($str) = @_;

    # match dispatch names to object names
    my %dispatch = (
          admin                       => 'Admin',
          admin_assessment_templates  => 'AdminAssessmentTemplates',
          ajax                        => 'Ajax',
          allergies                   => 'Allergies',
          appointments                => 'Appointments',
          assessment                  => 'Assessment',
          calendar                    => 'Calendar',
          clientoverview              => 'ClientOverview',
          client_filter               => 'ClientFilter',
          client_scanned_record       => 'ClientScannedRecord',
          configurable_assessment     => 'ConfigurableAssessment',
          demographics                => 'Demographics',
          diagnosis                   => 'Diagnosis',
          discharge                   => 'Discharge',
          entitlements                => 'Entitlements',
          financial                   => 'Financial',
          group_notes                 => 'GroupNotes',
          groups                      => 'Groups',
          help                        => 'Help',
          hospitalizations            => 'Inpatient',
          income                      => 'Income',
          insurance                   => 'Insurance',
          intake                      => 'Intake',
          login                       => 'Login',
          legal                       => 'Legal',
          letter                      => 'Letter',
          menu                        => 'Menu',
          personnel                   => 'Personnel',
          placement                   => 'Placement',
          prescription                => 'Prescription',
          progress_notes              => 'ProgressNote',
          progress_notes_charge_codes => 'ProgressNotesChargeCodes',
          report                      => 'Report',
          roi                         => 'ROI',
          rolodex                     => 'Rolodex',
          rolodex_cleanup             => 'RolodexCleanup',
          rolodex_filter_roles        => 'RolodexFilter',
          schedule                    => 'Schedule',
          set_treaters                => 'TreaterSet',
          scanned_record              => 'ScannedRecord',
          test                        => 'Test',
          treatment                   => 'Treatment',
          user_prefs                  => 'PersonnelPrefs',
          valid_data                  => 'ValidData',
          verification                => 'Verification',
          notification                => 'Notification'
    );

    DEBUG && print STDERR __PACKAGE__." Original QS: $str\n";
    my $cgi = 'index';
    if ($str =~ s/^\/?(\w+)\.cgi\W*//) {
        $cgi = $1 || 'index';
        $cgi = 'index' if ($cgi eq 'dispatch');
    }

    DEBUG && print STDERR __PACKAGE__." New QS: $str\n";

    if ($cgi eq 'index') {
        my $index = eleMentalClinic::Theme->new->theme_index || "PersonnelHome";
        return $index;
    }

    return $dispatch{ $cgi };
}

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Erik Hollensbe L<erikh@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see
L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for
known bugs.

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

=cut
