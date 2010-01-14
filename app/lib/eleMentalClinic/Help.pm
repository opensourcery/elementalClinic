package eleMentalClinic::Help;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Help

=head1 SYNOPSIS

Provides a simple help system for the application.

=head1 DESCRIPTION

The package defines a data structure of online documentation and gives all
templates access to it.  The "Help" link is presented ob every page in the UI,
and may contain any elements the developer wants to add.  Adding help elements
shoud be done in the view layer, not the object or controller layers (although
default or global elements may be added in this package).

When the primary controller L<eleMentalClinic::CGI> is initialized, it creates
a new Help object and adds it as global template variable C<Help>.
This object is accessible from all templates as:

    [% Help %]

The "Help" icon in the UI looks like it is in the header, but is actually in
the footer as the last chunk of template markup to be parsed.  This means that
any changes made to C<Help> by any template are reflected in the UI.

Every Help object is initialized with a single C<helper>: "default."  This
helper contains generic advice about how to use the help system.  To add new
helpers, in any template, call:

    [% Help.add( '$helper', '$helper' ) %]

You can add a particular helper (e.g. C<patient_lookup>) as many times as you
like, but it will only be included once.  Also, the C<order> key of each
C<helper> element is consulted for how to order the elements in the UI.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base /;
use Data::Dumper;
use Carp qw/ confess /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME we should have a table, but this is Good Enough(tm)
our $HELP_PATH = 'res/help/';
our %HELPERS = (
    default => {
        order       => 1,
        label       => 'General Help',
        description => 'How to use the help system.',
        content     => <<HTML,
        <ol>
            <li>Available help topics are listed at the right.</li>
            <li>Click the one you want and follow the instructions.</li>
            <li>Click the <strong>"X"</strong> icon at the top right to close help.</li>
            <li>If there are instructions you don't see here, please ask your systems administrator.</li>
        </ol>
HTML
        resource    => 'test.swf',
    },
    patient_lookup => {
        order       => 2,
        label       => 'Patient Lookup',
        description => 'How to find a patient.',
        content     => <<HTML,
        <ol>
            <li>Click the <strong>"Patients"</strong> link on the top navigation bar.</li>
            <li>Click inside the <strong>"Patient Search"</strong> box and type in part of a <strong>first</strong> or <strong>last name</strong>.</li>
            <li>Press <strong><tt>Enter</tt></strong> to search.</li>
            <li>Choose the correct patient from the <strong>"Search Results"</strong> box and click <strong>"View Client."</strong></li>
        </ol>
HTML
        resource    => 'patient_lookup.swf',
    },
    patient_quick_intake => {
        order       => 3,
        label       => 'Patient Quick Intake',
        description => 'How to add a new patient with only basic information.',
        content     => <<HTML,
        <ol>
            <li>Click the <strong>"Patients"</strong> link on the top navigation bar.</li>
            <li>Under <strong>"Quick Patient"</strong> enter at least:</li>
                <li><ul>
                <li>First name,</li>
                <li>Last name,</li>
                <li>Gender.</li>
                </ul></li>
            <li>(Birthdate and phone are optional at this stage.)</li>
            <li>Click the <strong>"Add patient"</strong> button.</li>
        </ol>
HTML
        resource    => undef,
    },
    patient_appointment_new => {
        order       => 4,
        label       => 'New patient appointment',
        description => 'How to create new patient appointments.',
        content     => <<HTML,
        <ol>
            <li>Look up the patient you want to schedule (<a onclick="return show_help( 'patient_lookup' )">help me &#187;</a>).</li>
            <li>Click on the <strong>"Appointments."</strong></li>
            <li>Click on any <strong>green day</strong> in the calendar OR select a day from the <strong>"Appointments"</strong> drop-down box.</li>
                <li><ul>
                    <li>(You can filter the results by choosing a location and/or doctor.)</li>
                </ul></li>
            <li>Click on any available <strong>time slot</strong>.</li>
            <li>Fill out any optional information in the pop-up window and click the <strong>"Save"</strong> button.</li>
        </ol>
HTML
        resource    => undef,
    },
    patient_appointment_modify => {
        order       => 5,
        label       => 'Change a patient appointment',
        description => 'How to change existing patient appointments.',
        content     => <<HTML,
        <ol>
            <li>Look up the patient you want to schedule (<a onclick="return show_help( 'patient_lookup' )">help me &#187;</a>).</li>
            <li>Click on the <strong>"Appointments."</strong></li>
            <li>Click on any <strong>green day</strong> in the calendar OR select a day from the <strong>"Appointments"</strong> drop-down box.</li>
                <li><ul>
                    <li>(You can filter the results by choosing a location and/or doctor.)</li>
                </ul></li>
            <li>Click on any available <strong>time slot</strong>.</li>
            <li>Fill out any optional information in the pop-up window and click the <strong>"Save"</strong> button.</li>
        </ol>
HTML
        resource    => undef,
    },
    patient_verification => {
        order       => 6,
        label       => 'Patient Verifications',
        description => 'How to request a new patient verification.',
        content     => <<HTML,
        <ol>
            <li>Look up the patient you wish to verify (<a onclick="return show_help( 'patient_lookup' )">help me &#187;</a>).</li>
            <li>Click the <strong>"Verification"</strong> link.</li>
            <li>Under <strong>"New Verification Letter"</strong> enter the <strong>APID #</strong>.</li>
            <li>Choose a <strong>doctor</strong>.</li>
            <li>Adjust the <strong>date</strong> if necessary.</li>
            <li>Click the <strong>"Save"</strong> button.</li>
        </ol>
HTML
        resource    => undef,
    },
    clinic_schedule => {
        order       => 7,
        label       => 'Clinic schedule report',
        description => 'How tp print the clinic schedule report.',
        content     => <<HTML,
        <ol>
            <li>Click the <strong>"Reports"</strong> link on the top navigation bar.</li>
            <li>Under <strong>"Choose Report"</strong> click the <strong>"Clinic Schedule"</strong> report.</li>
            <li>Under <strong>"Clinic Schedule"</strong> choose the day and clinic with the drop-down box.</li>
            <li>Click the <strong>"Run Report"</strong> button.</li>
        </ol>
HTML
        resource    => undef,
    },
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub methods {
        [ qw/ helpers /]
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;

    $self->SUPER::init( @_ );
    $self->helpers( [ 'default' ] );
    return $self;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 add( @helpers )

Object method.

Adds C<@helpers> to the object's data store.  Validates incoming helpers to
make sure they exist.  Returns C<undef> since it's often called from templates,
and the return value will be echoed in the template.

TODO should perform duplicate detection.  Rewrite this after having more coffee.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub add {
    my $self = shift;
    my( @helpers ) = @_;

    return unless @helpers;
    $self->get_helper( $_ )
        for @helpers;
    $self->helpers([ @{ $self->helpers }, @helpers ]);
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_helper( $helper )

Class method.

If called in void context returns true.  If called by code checking its return
value, returns the helper data structure.  Dies if C<$helper> is invalid.

Valid helpers are defined in C<%HELPERS>, a nested data structure in this
package.  Incoming helpers are expected to use dot notation for levels of
reference.  Currently only one level is allowed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_helper {
    my $class = shift;
    my( $helper ) = @_;

    confess 'Helper is required'
        unless $helper;
    confess "Unknown helper '$helper'"
        unless $HELPERS{ $helper };
    return { %{ $HELPERS{ $helper }}, name => $helper }
        if defined wantarray;
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 help( $helper )

Object method.

Returns full help for C<$helper>, if provided, or for all current C<helpers>.
Accounts for C<order> key, if it exists.

NOTE that for one C<$helper> the output of this method is identical to
C<get_helper()>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub help {
    my $self = shift;
    my( $helper ) = shift;

    return $self->get_helper( $helper )
        if $helper;

    return unless
        my @helpers = @{ $self->helpers };

    my %uniques = map { $_ => 1 } @helpers;
    @helpers = sort { $a->{ order } <=> $b->{ order }   # sort the helpers by their 'order' key
                                    ||                  # or if that doesn't exist
                      $a->{ label } <=> $b->{ label } } # by their label
                map{ $self->get_helper( $_ )}           # getting each helper
                keys %uniques;                          # using list of unique names
    return \@helpers;
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

Copyright (C) 2006 OpenSourcery, LLC

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
