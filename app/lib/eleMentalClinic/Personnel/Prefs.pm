package eleMentalClinic::Personnel::Prefs;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Personnel::Prefs

=head1 SYNOPSIS

Preference object for personnel.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base /;
use Data::Dumper;
use YAML::Syck;

# TODO I commented out all date_format settings but 'sql' and the new 'mdy' because I don't have time to include validator's for the other settings.  This will cause problems when merging simple back into trunk, and we will need to address the remaining validation issues for dates entered as text fields. (not active_date)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add all new preferences to the "preferences" hash key
{
    sub methods { [ qw/ staff_id /] }
    sub preferences { [
        {
            method  => 'client_list_filter',
            name    => 'Client list filter',
            desc    => 'Filter for clients on gateway page.',
            default => 'caseload',
            type    => 'lookup',
            lookup  => [
                { key => 'caseload',                value => 'My Caseload', },
                { key => 'active',                  value => 'Active', },
                { key => 'inactive',                value => 'Inactive', },
            ],
        },
        {
            method  => 'client_program_list_filter',
            name    => 'Client program list filter',
            desc    => 'Filter for client programs on gateway page.',
            default => 0,
            type    => 'valid_data',
            valid_data => '_program',
            leading_hash => [ { value => '0', name => 'All', }, ],
        },
        {
            method  => 'rolodex_filter',
            name    => 'Rolodex filter',
            desc    => 'Show only entries of this type in the rolodex list.',
            default => 'contacts',
            type    => 'lookup',
            lookup  => [
                map {
                    { key => $_->{ name }, value => $_->{ description }}
                } @{ eleMentalClinic::Rolodex->new->roles }
            ],
        },
        {
            method  => 'active_date',
            name    => 'Active date',
            desc    => 'Use the active date widget, with pop-up calendar and keyboard shortcuts; otherwise, enter the date in plain text (e.g. "YYYY-MM-DD").',
            default => 1,
            type    => 'boolean',
        },
        {
            method  => 'date_format',
            name    => 'Date format',
            desc    => 'The format in which dates will appear.',
            default => 'mdy',
            type    => 'lookup',
            lookup  => [
                { key     => 'sql',         value   => '2004-03-31', },
                { key     => 'mdy',         value   => '3/31/2004', },
#                { key     => 'compact_mdy', value   => '3/31/04', },
#                { key     => 'compact_dmy', value   => '31/3/04', },
#                { key     => 'medium',      value   => '31 Mar 2004', },
#                { key     => 'long',        value   => 'March 31, 2004', }
            ],
        },
        {
            method  => 'recent_prognotes',
            name    => 'Recent progress notes',
            desc    => 'Number of recent progress notes to show for a client.',
            default => 10,
            type    => 'integer',
        },
        {
            method  => 'nav_home',
            name    => 'Navigation, home tab',
            desc    => 'Remembers tab.',
            default => 'demographics',
            type    => 'lookup',
            lookup  => [
                { key => 'demographics',value => 'Demographics', },
                { key => 'placement',   value => 'Placement', },
            ],
        },
        {
            method  => 'nav_clinical',
            name    => 'Navigation, clinical tab',
            desc    => 'Remembers tab.',
            default => 'assessment',
            type    => 'lookup',
            lookup  => [
                { key => 'assessment',      value => 'Assessment', },
                { key => 'diagnosis',       value => 'Diagnosis', },
                { key => 'treatment',       value => 'Treatment', },
                { key => 'progress_notes',  value => 'Progress Notes', },
                { key => 'allergies',       value => 'Allergies', },
                { key => 'prescription',    value => 'Prescriptions', },
            ],
        },
        {
            method  => 'nav_history',
            name    => 'Navigation, history tab',
            desc    => 'Remembers tab.',
            default => 'hospitalizations',
            type    => 'lookup',
            lookup  => [
                { key => 'hospitalizations',   value => 'Hospitalizations', },
                { key => 'income',      value => 'Income', },
                { key => 'legal',       value => 'Legal', },
            ],
        },
        {
            method  => 'nav_letters',
            name    => 'Navigation, letters tab',
            desc    => 'Remembers tab.',
            default => 'roi',
            type    => 'lookup',
            lookup  => [
                { key => 'roi',         value => 'Release of Information', },
                { key => 'letter',      value => 'General', },
            ],
        },
        {
            method  => 'rolodex_show_inactive',
            name    => 'Show inactive Rolodex relationships',
            desc    => 'You can mark any client relationship in Rolodex as "active" or "inactive."  Inactive relationships are not displayed by default.  Change this option to display them everywhere.',
            default => 0,
            type    => 'boolean',
        },
        {
            method  => 'rolodex_show_private',
            name    => 'Show private Rolodex relationships',
            desc    => 'Private relationships are not displayed by default.  Change this option to display them everywhere.',
            default => 0,
            type    => 'boolean',
        },
        {
            method  => 'releases_show_expired',
            name    => 'Show expired Release of Information letters',
            desc    => 'Expired Releases are not displayed by default.  Change this option to display them everywhere.',
            default => 0,
            type    => 'boolean',
        },
        {
            method  => 'user_home_show_visit_frequency_reminders',
            name    => 'Show visit frequency reminder.',
            desc    => 'Visit frequency reminders can slow down the user home page, and are not displayed by default.  Change this option to display them.',
            default => 0,
            type    => 'boolean',
        },
        {
            method  => 'client_transaction_limit',
            name    => 'Client transaction limit.',
            desc    => 'If set to a non-zero value, will limit the number of financial transactions displayed for a client.',
            default => 10,
            type    => 'integer',
        },
        {
            method  => 'group_filter',
            name    => 'Group Filter',
            desc    => 'Show all groups, or only active/inactive',
            default => 'active',
            type    => 'lookup',
            lookup  => [
                { key => 'active',      value => 'Active', },
                { key => 'inactive',    value => 'Inactive', },
                { key => 'all',         value => 'All', },
            ],
        },
    ] }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my $class = ref $self;
    my( $args ) = @_;

    $self->SUPER::init( $args );

    my $yaml = Load( $args->{ prefs }) if $args->{ prefs };
    $self->$_( $args->{ $_ }) for @{ $self->methods };

    my @preferences;

    for( @{ $self->preferences }) {
        my $method = $_->{ method };
        push @preferences => $method;
        eleMentalClinic::Base::attribute( $class, $method );

#         my $value = $args->{ $method } || $yaml->{ $method } || $_->{ default };
        my $value;
        for( $_->{ default }, $yaml->{ $method }, $args->{ $method }) {
            no warnings qw/ uninitialized /;
# print Dumper " $method : $_";
            $value = $_ if defined $_;
        }
        $self->$method( $value );
    }
    $self->{ preferences } = \@preferences;

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    $self->save_prefs;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# write only prefs to db; ignore rest of user
sub save_prefs {
    my $self = shift;
    return unless $self->staff_id;

    my $id = $self->staff_id;

    my %prefs;
    for( @{ $self->{ preferences }}) {
        $prefs{ $_ } = $self->$_;
    }
    my $prefs = Dump \%prefs; # Dump is a YAML function

    0 and print STDERR "UPDATE personnel set prefs = '$prefs' WHERE staff_id = $id\n\n";
    my $sth = $self->db->dbh->prepare( qq/
        UPDATE personnel set prefs = '$prefs' WHERE staff_id = $id
    /);
    $sth->execute; 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub pref_descriptions {
    my $self = shift;

    return $self->preferences;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub navpage {
    my $self = shift;
    my( $navsec ) = @_;
    return 'menu' unless $navsec;
    $navsec = 'nav_'. $navsec;
    $self->$navsec || 'menu';
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
