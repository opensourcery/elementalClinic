# Copyright (C) 2004-2006 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl

=pod

Unit tests for the theme managment classes

=head1 AUTHORS

=over 4

=item Erik Hollensbe <erikh@opensourcery.com>

=back

=cut

use warnings;
use strict;

use Test::More tests => 33;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Theme;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);
BEGIN {
    *CLASS = \'eleMentalClinic::Theme';
    use_ok( $CLASS );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# methods
    ok( $one->can( $_ ))
        for qw/ config modules /;
    # refactored out
    ok( not $one->can( $_ ))
        for qw/ theme theme_config /;

    # don't usually test "config," but we're refactoring, so we make damn sure it works
    isa_ok( $one->config, 'eleMentalClinic::Config' );
    is( @{ $one->modules }, 1 );
    isa_ok( $one->modules->[ 0 ], 'eleMentalClinic::Theme::Access' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# theme config methods
    my @config_methods = qw/
        name description theme_index allowed_controllers
        allowed_reports
    /;
    is_deeply( $one->theme_config_methods, \@config_methods );
    can_ok($one, @config_methods);

    is( $one->name, 'Default' );
    is( $one->name, $test->config->theme );
    is( $one->description, undef );
    is_deeply( $one->allowed_controllers, [ qw/
        About Admin AdminAssessmentTemplates Ajax Allergies Assessment Calendar
        ClientFilter ClientPermissions Demographics Diagnosis Discharge
        Entitlements Error Financial GroupNotes Groups Income Inpatient
        Insurance Intake Legal Letter Login Menu PersonnelHome Personnel
        PersonnelPrefs Placement Prescription ProgressNote
        ProgressNotesChargeCodes Report ROI RolodexCleanup RolodexFilter
        Rolodex Schedule SecurityError TreaterSet Treatment ValidData
        Notification
    /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# load report config
    can_ok( $one, '_load_report_config' );
    ok( $one->_load_report_config );
    is_deeply( $one->_load_report_config, [ qw/
        allergy
        client_list
        client_prognote
        client_termination
        clinic_schedule
        cover_sheet
        data_sheet
        encounter
        hospital
        ins_reauth
        last_visit_bystaff
        legal
        medication
        mh_totals
        monthly_status
        renewals
        site_prognote
        site_prognote_caseload
        uncommitted_prognotes
        verification_expirations
        verifications
        zip_count
        email
        access
        security_log
        appointments
    /]);

    # config
    {
        my $orig = $one->config->report_config;
        ok( $one->config->report_config( 'foo' ));
        is( $one->config->report_config, 'foo' );
        throws_ok{ $one->_load_report_config } qr/Cannot read report config \(/;
        $one->config->report_config( $orig );
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# singleton check
    is( $one, $CLASS->new );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

is_deeply([map { ref $_ } @{$one->modules}], [ "eleMentalClinic::Theme::Access" ]);

SKIP: {
    skip( 'Mac OS X has a case-insensitive file system', 1 ) 
            if $^O eq 'darwin';
    throws_ok { $one->controller_can('admin') }
      qr/^Can't locate .+ in \@INC/, "Case sensitivity check";
}

ok($one->controller_can('Admin'), 'Case sensitivity check');
is($one->controller_can('Admin'), 'eleMentalClinic::Controller::Base::Admin');
ok(
  scalar(@eleMentalClinic::Controller::Base::Admin::ISA),
  'required module has ISA',
);
ok(! $one->controller_can('Monkeys'), 'Failure test');
is_deeply(
    $one->available_reports('site'),
    [ qw(
        appointments
        client_list
        email
        encounter
        hospital
        ins_reauth
        last_visit_bystaff
        mh_totals
        monthly_status
        site_prognote
        site_prognote_caseload
        uncommitted_prognotes
        zip_count
    ) ],
    'available site reports',
);

is_deeply( $one->available_reports( 'client' ), [ qw/
    allergy
    client_prognote
    client_termination
    data_sheet
    legal
    medication
/]);

# Venus has allowed_reports in its config
$one = eleMentalClinic::Theme->load_theme( 'Venus' );
is_deeply( $one->available_reports( 'site' ), [ qw/
  access
  appointments
  client_list
  clinic_schedule
  email
  encounter
  hospital
  ins_reauth
  last_visit_bystaff
  mh_totals
  monthly_status
  renewals
  security_log
  site_prognote
  site_prognote_caseload
  verification_expirations
  verifications
  zip_count
/ ] );
