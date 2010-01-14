# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 318;
use Test::Exception;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp);

my $CLASS = 'eleMentalClinic::Report';
use eleMentalClinic::Report;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
    financial_reset_sequences();
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client_report
    can_ok( $CLASS, 'client_report' );
    is_deeply( $CLASS->client_report, [
        {
            admin => 0,
            name => 'allergy',
            label => 'Allergy'
        },
        {
            admin => 0,
            name => 'data_sheet',
            label => 'Data Sheet'
        },
        {
            name => 'income',
            label  => 'Income',
            admin => 0,
        },
        {
            admin => 0,
            name => 'legal',
            label => 'Legal History'
        },
        {
            admin => 0,
            name => 'medication',
            label => 'Medication History'
        },
        {
            admin => 0,
            name => 'client_prognote',
            label => 'Progress Notes'
        },
        {
            name => 'cover_sheet',
            label  => 'Records Review Sheet',
            admin => 0,
        },
        {
            admin => 0,
            name => 'client_termination',
            label => 'Termination'
        },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# site_report
    can_ok( $CLASS, 'site_report' );
    is_deeply( $CLASS->site_report, [
        {
            admin => 0,
            name => 'appointments',
            label => 'Appointments'
        },
        {
            admin => 0,
            name => 'client_list',
            label => 'Client List by Caseload'
        },
        {
            admin => 0,
            name => 'clinic_schedule',
            label => 'Clinic Schedule'
        },
        {
            name => 'access',
            label => 'Confidential Data Access',
            admin => 0,
        },
        {
            admin => 0,
            name => 'mh_totals',
            label => 'Count of Active Clients By Mental Health Coverage'
        },
        {
            admin => 0,
            name => 'encounter',
            label => 'Encounter Hours'
        },
        {
            admin => 0,
            name => 'hospital',
            label => 'Hospitalization History'
        },
        {
            admin => 0,
            name => 'ins_reauth',
            label => 'Insurance Reauthorization'
        },
        {
            admin => 0,
            name => 'last_visit_bystaff',
            label => 'Last Visits by Caseload'
        },
        {
            admin => 0,
            name => 'monthly_status',
            label => 'Monthly Status Report'
        },
        {
            name => 'email',
            label => 'Outgoing Email',
            admin => 0,
        },
        {
            admin => 0,
            name => 'site_prognote_caseload',
            label => 'Progress Notes by caseload'
        },
        {
            admin => 0,
            name => 'site_prognote',
            label => 'Progress Notes by writer'
        },   
        {
            admin => 0,
            name => 'renewals',
            label => 'Renewals Report',
        },
        {
            name => 'security_log',
            label => 'Security',
            admin => 0,
        },
        {
            admin => 0,
            name => 'uncommitted_prognotes',
            label => 'Uncommitted Progress Notes'
        },
        {
            admin => 0,
            name => 'verification_expirations',
            label => 'Verification Expirations Report',
        },
        {
            admin => 0,
            name => 'verifications',
            label => 'Verifications Report'
        },
        {
            admin => 0,
            name => 'zip_count',
            label => 'Zip Code Count'
        },
    ]);
 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    can_ok( $CLASS, 'financial_report' );
    is_deeply( $CLASS->financial_report, [
        {
            name => 'authorizations_over_budget',
            label  => 'Authorizations over budget',
            admin => 1,
        },
        {
            name    => 'services_by_client',
            label   => 'Billed services and payments',
            admin   => 0,
        },
        {
            name    => 'audit_trail_by_client',
            label   => 'Client, audit trail',
            admin   => 0,
        },
        {
            name    => 'monthly_summary_by_insurer',
            label   => 'Insurer, monthly summary',
            admin   => 0,
        },
        {
            name    => 'billing_totals_by_program',
            label   => 'Program billing totals',
            admin   => 0,
        },
        {
            name    => 'payment_totals_by_program',
            label   => 'Program payment totals',
            admin   => 0,
        },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# init

    throws_ok { $one = $CLASS->new({ name => 'foo' }) }
        qr/No report class found for 'foo'/;

    # zip count -- takes no args
    $tmp = $CLASS->site_report->[-1];
    $one = $CLASS->new({ name => $tmp->{name} });

    is( $one->name, $tmp->{name} );
    is( $one->label, $tmp->{label} );
    is( $one->admin, $tmp->{admin} );
    is_deeply( $one->args, {} );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# uncommitted_prognotes
    can_ok( $one, 'uncommitted_prognotes' );
    is_deeply( $one->uncommitted_prognotes, [] );

        eleMentalClinic::ProgressNote->retrieve( 1001 )->note_committed( 0 )->save;
    # have to handle this data with tongs ...
    is( scalar @{ $one->uncommitted_prognotes }, 1 );
    is( $one->uncommitted_prognotes->[ 0 ]{ writer }{ staff_id }, 1001 );
    is( scalar @{ $one->uncommitted_prognotes->[ 0 ]{ uncommitted_prognotes }}, 1 );
    is( $one->uncommitted_prognotes->[ 0 ]{ uncommitted_prognotes }[ 0 ]{ rec_id }, 1001 );

        eleMentalClinic::ProgressNote->retrieve( 1002 )->note_committed( 0 )->save;
        eleMentalClinic::ProgressNote->retrieve( 1003 )->note_committed( 0 )->save;

    is( scalar @{ $one->uncommitted_prognotes }, 2 );
    is( $one->uncommitted_prognotes->[ 0 ]{ writer }{ staff_id }, 1002 );
    is( $one->uncommitted_prognotes->[ 1 ]{ writer }{ staff_id }, 1001 );

    is( scalar @{ $one->uncommitted_prognotes->[ 0 ]{ uncommitted_prognotes }}, 2 );
    is( scalar @{ $one->uncommitted_prognotes->[ 1 ]{ uncommitted_prognotes }}, 1 );
    is_deeply( $one->uncommitted_prognotes->[ 0 ]{ uncommitted_prognotes }[ 0 ]{ rec_id }, 1002 );
    is_deeply( $one->uncommitted_prognotes->[ 0 ]{ uncommitted_prognotes }[ 1 ]{ rec_id }, 1003 );
    is_deeply( $one->uncommitted_prognotes->[ 1 ]{ uncommitted_prognotes }[ 0 ]{ rec_id }, 1001 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# data
    can_ok( $one, 'data' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# verifications
    can_ok($one,'verifications');
#    print Dumper $one->verifications( { start_date => '1/1/2006', end_date => '12/1/2006' });
    is_deeply($one->verifications( { start_date => '1/1/2006', end_date => '12/1/2006' }),  [
          {
            'apid_num' => '1002',
            'client_id' => '1001',
            'dob' => '1926-05-25',
            'doctor' => 'Batts',
            'fname' => 'Miles',
            'lname' => 'Davis',
            'mname' => 'D',
            'verif_date' => '2006-10-01'
          }
]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# verification_expirations
    can_ok($one,'_verifications_by_index_date');
    can_ok($one,'verification_expirations');

    is_deeply($one->_verifications_by_index_date( {index_date => '2008-01-01'} ),
        [
          {
            'client_id' => '1001',
            'dont_call' => '0',
            'email' => 'miles@davis.com',
            'fname' => 'Miles',
            'last_verification' => '2006-10-01',
            'lname' => 'Davis',
            'mname' => 'D',
            'phone' => '(212) 254-6436',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2007-10-01'
          },
          {
            'client_id' => '1002',
            'dont_call' => '1',
            'email' => 'charles@mingus.com',
            'fname' => 'Charles',
            'last_verification' => '2005-10-01',
            'lname' => 'Mingus',
            'mname' => undef,
            'phone' => '(212) 479-7888',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2006-10-01'
          },
          {
            'client_id' => '1003',
            'dont_call' => undef,
            'email' => 'thelonious@monk.org',
            'fname' => 'Thelonious',
            'last_verification' => '2006-11-01',
            'lname' => 'Monk',
            'mname' => undef,
            'phone' => '(212) 576-2232',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2007-11-01'
          }
        ], "Everyone who will expire by 2008-01-01");
    is_deeply($one->_verifications_by_index_date( {index_date => '2007-01-01'} ),
       [
          {
            'dont_call' => 1,
            'verification_expires' => '2006-10-01',
            'mname' => undef,
            'fname' => 'Charles',
            'client_id' => '1002',
            'phone' => '(212) 479-7888',
            'sex' => 'Male',
            'state' => 'NY',
            'email' => 'charles@mingus.com',
            'last_verification' => '2005-10-01',
            'lname' => 'Mingus'
          }
       ], "Everyone who will expire by 2007-01-01");
    is_deeply($one->_verifications_by_index_date( {index_date => '2007-01-01', expires_in_days => 365} ),
        [
          {
            'client_id' => '1001',
            'dont_call' => '0',
            'email' => 'miles@davis.com',
            'fname' => 'Miles',
            'last_verification' => '2006-10-01',
            'lname' => 'Davis',
            'mname' => 'D',
            'phone' => '(212) 254-6436',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2007-10-01'
          },
          {
            'client_id' => '1002',
            'dont_call' => '1',
            'email' => 'charles@mingus.com',
            'fname' => 'Charles',
            'last_verification' => '2005-10-01',
            'lname' => 'Mingus',
            'mname' => undef,
            'phone' => '(212) 479-7888',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2006-10-01'
          },
          {
            'client_id' => '1003',
            'dont_call' => undef,
            'email' => 'thelonious@monk.org',
            'fname' => 'Thelonious',
            'last_verification' => '2006-11-01',
            'lname' => 'Monk',
            'mname' => undef,
            'phone' => '(212) 576-2232',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2007-11-01'
          }
        ], "Everyone who has expired by 2007-01-01, or will expire in the next 365 days");
    is_deeply($one->_verifications_by_index_date( {index_date => '2006-01-01', expires_in_days => 350} ),
        [
          {
            'client_id' => '1002',
            'dont_call' => '1',
            'email' => 'charles@mingus.com',
            'fname' => 'Charles',
            'last_verification' => '2005-10-01',
            'lname' => 'Mingus',
            'mname' => undef,
            'phone' => '(212) 479-7888',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2006-10-01'
          },
        ], "Everyone who has expired by 2006-01-01, or who will expire in the next 350 days");
    is_deeply($one->_verifications_by_index_date( {index_date => '2007-01-01', expires_in_days => 365, start_date => '2007-01-01'} ),
        [
          {
            'client_id' => '1001',
            'dont_call' => '0',
            'email' => 'miles@davis.com',
            'fname' => 'Miles',
            'last_verification' => '2006-10-01',
            'lname' => 'Davis',
            'mname' => 'D',
            'phone' => '(212) 254-6436',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2007-10-01'
          },
          {
            'client_id' => '1003',
            'dont_call' => undef,
            'email' => 'thelonious@monk.org',
            'fname' => 'Thelonious',
            'last_verification' => '2006-11-01',
            'lname' => 'Monk',
            'mname' => undef,
            'phone' => '(212) 576-2232',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2007-11-01'
          }
        ], "Everyone who has expired by 2007-01-01, or will expire in the next 365 days, but not including people who expired before 2007-01-01.");
    is_deeply($one->_verifications_by_index_date( {index_date => '2007-10-10', expires_in_days => 30, start_date => '2007-10-01'} ),
        [
          {
            'client_id' => '1003',
            'dont_call' => undef,
            'email' => 'thelonious@monk.org',
            'fname' => 'Thelonious',
            'last_verification' => '2006-11-01',
            'lname' => 'Monk',
            'mname' => undef,
            'phone' => '(212) 576-2232',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2007-11-01'
          }
        ], "Everyone who has expired by 2007-10-10, or will expire in the next 30 days, but not including people who expired before 2007-10-01.");
    ok( $one->verification_expirations() );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clinic_schedule
    can_ok($one,'clinic_schedule');
#    print Dumper $one->clinic_schedule( { schedule_id => 1001 } );
    is_deeply($one->clinic_schedule( { schedule_id => 1001 }),
        {
          'schedule_appointments' => [
                                       {
                                         'appt_time' => '09:00:00',
                                         'c_fname' => 'Miles',
                                         'c_lname' => 'Davis',
                                         'c_mname' => 'D',
                                         'chart' => 'N',
                                         'confirm' => 'test-CXL',
                                         'fax' => 'N',
                                         'noshow' => '0',
                                         'notes' => '',
                                         'p_fname' => 'Ima',
                                         'payment' => '$960',
                                         'phone' => '(212) 254-6436'
                                       },
                                       {
                                         'appt_time' => '09:00:00',
                                         'c_fname' => 'Charles',
                                         'c_lname' => 'Mingus',
                                         'c_mname' => undef,
                                         'chart' => 'N',
                                         'confirm' => 'test-Walk-in',
                                         'fax' => 'N',
                                         'noshow' => '0',
                                         'notes' => '',
                                         'p_fname' => 'Betty',
                                         'payment' => '$950 PPD/Renew',
                                         'phone' => '(212) 479-7888'
                                       },
                                       {
                                         'appt_time' => '15:00:00',
                                         'c_fname' => 'Thelonious',
                                         'c_lname' => 'Monk',
                                         'c_mname' => undef,
                                         'chart' => 'N',
                                         'confirm' => 'test-Conf',
                                         'fax' => 'N',
                                         'noshow' => '0',
                                         'notes' => '',
                                         'p_fname' => 'Ima',
                                         'payment' => '$950 PPD/Renew',
                                         'phone' => '(212) 576-2232'
                                       }
                                     ],
          'schedule_details' => [
                                  {
                                    'dow' => 'Thursday ',
                                    'lname' => 'Clinician',
                                    'location' => 'The client lives here',
                                    'sa_date' => '06/01/06'
                                  }
                                ]
        } );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# cover_sheet
    can_ok( $one,'cover_sheet' );
#    print Dumper $one->cover_sheet( { client_id => 1001 } );
    is_deeply($one->cover_sheet( { client_id => 1001 } ),
        [ {
            'dob' => '1926-05-25',
            'fname' => 'Miles',
            'lname' => 'Davis',
            'mname' => 'D',
            'phone' => '(212) 254-6436',
            'received_date' => undef
          }
        ]);
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# data_sheet
    can_ok( $one, 'data_sheet' );
    ok( $one->data_sheet({ client_id => 1001 }));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# renewals
    can_ok($one,'renewals');
    is_deeply($one->renewals,
        [
          {
            'client_id' => '1002',
            'dont_call' => '1',
            'email' => 'charles@mingus.com',
            'fname' => 'Charles',
            'last_verification' => '2005-10-01',
            'lname' => 'Mingus',
            'mname' => undef,
            'phone' => '(212) 479-7888',
            'post_code' => '10001',
            'renewal_date' => '2006-01-01',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2006-10-01'
          },
          {
            'client_id' => '1001',
            'dont_call' => '0',
            'email' => 'miles@davis.com',
            'fname' => 'Miles',
            'last_verification' => '2006-10-01',
            'lname' => 'Davis',
            'mname' => 'D',
            'phone' => '(212) 254-6436',
            'post_code' => '10003',
            'renewal_date' => '2007-01-01',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2007-10-01'
          },
          {
            'client_id' => '1004',
            'dont_call' => undef,
            'email' => 'ella@fitzgerald.net',
            'fname' => 'Ella',
            'last_verification' => undef,
            'lname' => 'Fitzgerald',
            'mname' => undef,
            'phone' => '(212) 475-8592',
            'post_code' => '10012',
            'renewal_date' => undef,
            'sex' => 'Female',
            'state' => 'NY',
            'verification_expires' => undef
          },
          {
            'client_id' => '1003',
            'dont_call' => undef,
            'email' => 'thelonious@monk.org',
            'fname' => 'Thelonious',
            'last_verification' => '2006-11-01',
            'lname' => 'Monk',
            'mname' => undef,
            'phone' => '(212) 576-2232',
            'post_code' => '10016',
            'renewal_date' => undef,
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2007-11-01'
          },
          {
            'client_id' => '1005',
            'dont_call' => undef,
            'email' => undef,
            'fname' => 'Bud',
            'last_verification' => undef,
            'lname' => 'Powell',
            'mname' => 'J',
            'phone' => undef,
            'post_code' => '97215',
            'renewal_date' => undef,
            'sex' => 'Male',
            'state' => 'OR',
            'verification_expires' => undef
          },
          {
            'client_id' => '1006',
            'dont_call' => undef,
            'email' => undef,
            'fname' => 'Bad',
            'last_verification' => undef,
            'lname' => 'zData',
            'mname' => undef,
            'phone' => undef,
            'post_code' => undef,
            'renewal_date' => undef,
            'sex' => undef,
            'state' => undef,
            'verification_expires' => undef
          }
        ]);
#    print $one->renewals({ end_date => '2007-01-01' });
    is_deeply($one->renewals({ end_date => '2007-01-01' }),
        [
          {
            'client_id' => '1002',
            'dont_call' => '1',
            'email' => 'charles@mingus.com',
            'fname' => 'Charles',
            'last_verification' => '2005-10-01',
            'lname' => 'Mingus',
            'mname' => undef,
            'phone' => '(212) 479-7888',
            'post_code' => '10001',
            'renewal_date' => '2006-01-01',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2006-10-01'
          },
          {
            'client_id' => '1001',
            'dont_call' => '0',
            'email' => 'miles@davis.com',
            'fname' => 'Miles',
            'last_verification' => '2006-10-01',
            'lname' => 'Davis',
            'mname' => 'D',
            'phone' => '(212) 254-6436',
            'post_code' => '10003',
            'renewal_date' => '2007-01-01',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2007-10-01'
          },
        ]);
    is_deeply($one->renewals({ end_date => '2007-01-01', zip_code => '10001' }),
        [
          {
            'client_id' => '1002',
            'dont_call' => '1',
            'email' => 'charles@mingus.com',
            'fname' => 'Charles',
            'last_verification' => '2005-10-01',
            'lname' => 'Mingus',
            'mname' => undef,
            'phone' => '(212) 479-7888',
            'post_code' => '10001',
            'renewal_date' => '2006-01-01',
            'sex' => 'Male',
            'state' => 'NY',
            'verification_expires' => '2006-10-01'
          },
        ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# _time_unit_calc
    can_ok( $one, '_time_unit_calc' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# legal
    can_ok( $one, 'legal' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# medication
    can_ok( $one, 'medication' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# allergy
    can_ok( $one, 'allergy' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# hospital
    can_ok( $one, 'hospital' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ins_reauth

    # setup
    eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 )->end_date( '2006-05-31' )->save;
    eleMentalClinic::Client::Insurance::Authorization->retrieve( 1007 )->end_date( '2006-06-01' )->save;
    eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 )->end_date( '2006-06-15' )->save;
    eleMentalClinic::Client::Insurance::Authorization->retrieve( 1013 )->end_date( '2006-06-30' )->save;
    eleMentalClinic::Client::Insurance::Authorization->retrieve( 1014 )->end_date( '2006-07-01' )->save;

    can_ok( $one, 'ins_reauth' );
    throws_ok{ $one->ins_reauth } qr/required/;

    is_deeply( $one->ins_reauth({ start_date => '2000-01-01' }), [] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prognote
    can_ok( $one, 'client_prognote' );
    is_deeply( $one->client_prognote, { data => [] } );

    is_deeply( $one->client_prognote({ client_id => 1004 }), { data => [] } );

    # case 1: client_id, end_date
    is_deeply( $one->client_prognote({
        client_id => 6666,
        end_date  => '2005-05-13',
    }), { data => [] } );

    ok( $tmp = $one->client_prognote({
        client_id => 1004,
        end_date  => '2005-05-13',
    }) );
    is( $tmp->{ client }, $client->{ 1004 }->{ fname } . ' ' . $client->{ 1004 }->{ lname } );

    is_deeply( $tmp->{ data }, [
    # 1012
        {
            duration => '01:00',
            date     => '2000-01-02',
            location => 'Office',
            code     => 'N/A',
            note     => $prognote->{ 1012 }->{ note_body },
            staff    => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1012 }->{ staff_id } })->retrieve,
            writer   => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1012 }->{ data_entry_id } })->retrieve,
            client   => $tmp->{ client },
            goal     => $prognote->{ 1012 }->{ goal },
            group    => undef,
            signature => undef,
        },
    # 1011
        {
            duration => '01:00',
            date     => '1999-07-05',
            location => 'Office',
            code     => 'N/A',
            note     => $prognote->{ 1011 }->{ note_body },
            staff    => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1011 }->{ staff_id } })->retrieve,
            writer   => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1011 }->{ data_entry_id } })->retrieve,
            client   => $tmp->{ client },
            goal     => $prognote->{ 1011 }->{ goal },
            group    => undef,
            signature => undef,
        },
    # 1013
        {
            duration => '00:15',
            date     => '1999-01-31',
            location => 'Office',
            code     => 'N/A',
            note     => $prognote->{ 1013 }->{ note_body },
            staff    => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1013 }->{ staff_id } })->retrieve,
            writer   => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1013 }->{ data_entry_id } })->retrieve,
            client   => $tmp->{ client },
            goal     => $prognote->{ 1013 }->{ goal },
            group    => undef,
            signature => undef,
        },
    ] );

    # case 2: client_id, start_date, end_date
    # case 3: client_id, start_date, end_date
    # case 4: staff_id, end_date

    # case 5: staff_id, start_date, end_date
    is_deeply( $one->client_prognote({
        staff_id   => 6666,
        start_date => '2000-01-02',
        end_date   => '2005-05-13',
    }), { data => [] } );

    ok( $tmp = $one->client_prognote({
        staff_id   => 1001,
        start_date => '1999-01-02',
        end_date   => '2005-05-13',
    }) );
    is( $tmp->{ staff }, $personnel->{ 1001 }->{ fname } . ' ' . $personnel->{ 1001 }->{ lname } );

# FIXME : This is fixed now; I set a p.start_date DESC into the order clause for report calls without $client_id set, but I don't know if that's the desired order - ASC might be preferred?
# not ok 43
#     Failed test (t_new/800report.t at line 338)
#     Structures begin differing at:
#          $got->[1][0]{date} = '1999-01-31'
#     $expected->[1][0]{date} = '1999-07-05'

#    print Dumper $tmp->{ data };
    is_deeply( $tmp->{ data }, [
        [
            # 1018
            {
                duration => '03:00',
                date     => '2005-05-13',
                location => 'Office',
                code     => 'N/A',
                note     => $prognote->{ 1018 }->{ note_body },
                staff    => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1018 }->{ staff_id } })->retrieve,
                writer   => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1018 }->{ data_entry_id } })->retrieve,
                client   => $client->{ 1001 }->{ fname } . ' ' . $client->{ 1001 }->{ lname },
                group    => undef,
                goal     => $prognote->{ 1018 }->{ goal },
                signature => undef,
            },
        ],
        [
            # 1011
            {
                duration => '01:00',
                date     => '1999-07-05',
                location => 'Office',
                code     => 'N/A',
                note     => $prognote->{ 1011 }->{ note_body },
                staff    => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1011 }->{ staff_id } })->retrieve,
                writer   => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1011 }->{ data_entry_id } })->retrieve,
                client   => $client->{ 1004 }->{ fname } . ' ' . $client->{ 1004 }->{ lname },
                group    => undef,
                goal     => $prognote->{ 1011 }->{ goal },
                signature => undef,
            },
            # 1013
            {
                duration => '00:15',
                date     => '1999-01-31',
                location => 'Office',
                code     => 'N/A',
                note     => $prognote->{ 1013 }->{ note_body },
                staff    => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1013 }->{ staff_id } })->retrieve,
                writer   => eleMentalClinic::Personnel->new({ staff_id => $prognote->{ 1013 }->{ data_entry_id } })->retrieve,
                client   => $client->{ 1004 }->{ fname } . ' ' . $client->{ 1004 }->{ lname },
                group    => undef,
                goal     => $prognote->{ 1013 }->{ goal },
                signature => undef,
            },
        ],
    ] );

    # case 6: staff_id, start_date, end_date
    # case 7: client_id, staff_id, start_date, end_date

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# site_prognote
    can_ok( $one, 'site_prognote' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# site_prognote_caseload
    can_ok( $one, 'site_prognote_caseload' );
#     die Dumper( $one->site_prognote_caseload );

    ok( $tmp = $one->site_prognote_caseload );
    is( @$tmp, 5 );
    is( $tmp->[ 0 ]->staff_id, 1000 );
    is( $tmp->[ 1 ]->staff_id, 1002 );
    is( $tmp->[ 2 ]->staff_id, 1 );
    is( $tmp->[ 3 ]->staff_id, 1001 );
    is( $tmp->[ 4 ]->staff_id, 1003 );

    ok( $tmp = $one->site_prognote_caseload({ staff_id => 1001 }));
    is( @$tmp, 1 );
    is( $tmp->[ 0 ]->staff_id, 1001 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# zip_count
    can_ok( $one, 'zip_count' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# encounter
    can_ok( $one, 'encounter' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# monthly_status
    can_ok( $one, 'monthly_status' );

    is_deeply( $one->monthly_status({ date => '1993-01-01' })->{ hospitalizations }, [{
        client          => $client->{ 1003 },
        inpatient       => $client_inpatient->{ 1001 },
    }]);

    is_deeply( $one->monthly_status({ date => '2006-03-15' }), {
        hospitalizations => [],
        intakes                 => [{ 
            client          => $client->{ 1004 },
            input_by        => 'Admin Jr., Site',
            input_date      => '2006-03-06 09:15:00',
            admit_date      => '2006-03-06',
            referral        => undef,
            referral_date   => undef,
        }],
        terminations            => [{
            client          => $client->{ 1001 },
            event_date      => '2006-03-15',
            termination_reason => 'Client deceased',
            input_date      => '2005-05-05 08:00:00',
            admit_date      => '2005-05-04',
        }],
        total_active_clients    => 4,   # 1003, 1004, 1005, 1006
        program_totals          => [{
            name    => 'Inpatient',
            count   => 1,
        }, {
            name    => 'Referral',
            count   => 1,
        }, {
            name    => 'Substance abuse',
            count   => 2,
        }],
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# mh_totals
    can_ok( $one, 'mh_totals' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client_list
    can_ok( $one, 'client_list' );

    throws_ok { $one->client_list } qr/Attribute \(staff_id\) is required/;

    is_deeply( $one->client_list({ staff_id => 1001 }), [
        {
            %{ $client->{ 1004 }},
            mh_coverage => $rolodex->{ 1015 }->{ name },
            ssn         => eleMentalClinic::Client->retrieve( 1004 )->ssn_f,
        },
        {
            %{ $client->{ 1005 }},
            mh_coverage => $rolodex->{ 1009 }->{ name },
        },
    ]);

    is_deeply( $one->client_list({ staff_id => 1002 }), [
        {
            %{ $client->{ 1003 }},
            mh_coverage => $rolodex->{ 1015 }->{ name },
            ssn         => eleMentalClinic::Client->retrieve( 1003 )->ssn_f,
        },
    ]);

    is_deeply( $one->client_list({ staff_id => 1003 }), [
        {
            %{ $client->{ 1006 }},
            mh_coverage => undef,
        },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# last_visit_bystaff
    can_ok( $one, 'last_visit_bystaff' );
    throws_ok { $one->last_visit_bystaff } qr/Attribute \(staff_id\) is required/;
    is_deeply( $one->last_visit_bystaff({ staff_id => 999 }), [] );

    # Note that we get the clients assigned to this staff member
    # and then find each client's latest prognote 
    # -- even if that prognote is not by this staff member.
    is_deeply( $one->last_visit_bystaff({ staff_id => 1002 }), [{
        charge_code => '90806',
        client      => 'Monk, Thelonious',
        date        => '2008-08-07',
        duration    => '04:00',
        writer      => 'Ima Therapist',
    }]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# client_termination
# stub, doesn't need any more than this
    can_ok( $one, 'client_termination' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# verifications
    can_ok($one,'verifications');
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# clinic_schedule
    can_ok($one,'clinic_schedule');

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Financial Reports
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# authorizations_over_budget
# XXX these tests change data
    can_ok( $one, 'authorizations_over_budget' );
    is_deeply( $one->authorizations_over_budget, [] );

        # client 1003, insurance 1003
        $tmp = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1004 );
        $tmp->update({
            capitation_amount       => 1000,
            capitation_last_date    => $one->today,
            end_date                => $one->today,
        });
    is( $tmp->capitation_time_percent, 100 );
    is( $tmp->capitation_amount_percent, 100 );

    is_deeply( $one->authorizations_over_budget, [] );

        $tmp->update({
            capitation_amount       => 999,
        });
    is_deeply( $one->authorizations_over_budget, [] );

        $tmp->update({
            capitation_amount       => 1001,
        });
    is( $tmp->capitation_time_percent, 100 );
    is( $tmp->capitation_amount_percent, 100 );
    is_deeply( $one->authorizations_over_budget, [] );

        $tmp->update({
            capitation_amount       => 1006,
        });
    is( $tmp->capitation_time_percent, 100 );
    is( $tmp->capitation_amount_percent, 101 );
    is_deeply( $one->authorizations_over_budget, [] );
#    is_deeply( $one->authorizations_over_budget, [
#        {
#            client      => $client->{ 1003 },
#            insurers    => [
#                $client_insurance->{ 1017 },
#                $client_insurance->{ 1003 },
#            ],
#        }
#    ]);

        $tmp = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1006 );
        $tmp->update({
            capitation_amount       => 1000,
            capitation_last_date    => $one->today,
            end_date                => $one->today,
        });
     is_deeply( $one->authorizations_over_budget, [] );
#    is_deeply( $one->authorizations_over_budget, [
#        {
#            client      => $client->{ 1003 },
#            insurers    => [
#                $client_insurance->{ 1017 },
#                $client_insurance->{ 1003 },
#            ],
#        }
#    ]);

        $tmp->update({
            capitation_amount       => 1006,
        });

    is_deeply( $one->authorizations_over_budget, [
        {
            client      => $client->{ 1003 },
            insurers    => [
                $client_insurance->{ 1004 },
            ],
        }
    ]);

        $tmp = eleMentalClinic::Client::Insurance::Authorization->retrieve( 1009 );
        $tmp->update({
            capitation_amount       => 900,
            capitation_last_date    => $one->today,
            end_date                => $one->today,
        });
    is_deeply( $one->authorizations_over_budget, [
        {
            client      => $client->{ 1003 },
            insurers    => [
                $client_insurance->{ 1004 },
            ],
        }
    ]);

        $tmp->update({
            capitation_amount       => 1010,
            capitation_last_date    => $one->today,
            end_date                => $one->today,
        });
    is_deeply( $one->authorizations_over_budget, [
        {
            client      => $client->{ 1004 },
            insurers    => [
                $client_insurance->{ 1007 },
            ],
        },
        {
            client      => $client->{ 1003 },
            insurers    => [
                $client_insurance->{ 1004 },
            ],
        }
    ]);

    # programs
    is_deeply( $one->authorizations_over_budget({ program_id => 1002 }), [] );
    is_deeply( $one->authorizations_over_budget({ program_id => 1001 }), [
        {
            client      => $client->{ 1004 },
            insurers    => [
                $client_insurance->{ 1007 },
            ],
        },
        {
            client      => $client->{ 1003 },
            insurers    => [
                $client_insurance->{ 1004 },
            ],
        }
    ]);

    # level of care
    is_deeply( $one->authorizations_over_budget({ level_of_care_id => 1003 }), [] );
    is_deeply( $one->authorizations_over_budget({ level_of_care_id => 1001 }), [
        {
            client      => $client->{ 1004 },
            insurers    => [
                $client_insurance->{ 1007 },
            ],
        },
    ]);
    is_deeply( $one->authorizations_over_budget({ level_of_care_id => 1002 }), [
        {
            client      => $client->{ 1003 },
            insurers    => [
                $client_insurance->{ 1004 },
            ],
        }
    ]);

    # both
    is_deeply( $one->authorizations_over_budget({ level_of_care_id => 1001, program_id => 1001 }), [
        {
            client      => $client->{ 1004 },
            insurers    => [
                $client_insurance->{ 1007 },
            ],
        },
    ]);
    is_deeply( $one->authorizations_over_budget({ level_of_care_id => 1002, program_id => 1001 }), [
        {
            client      => $client->{ 1003 },
            insurers    => [
                $client_insurance->{ 1004 },
            ],
        }
    ]);
    is_deeply( $one->authorizations_over_budget({ level_of_care_id => 1001, program_id => 1002 }), [] );
    is_deeply( $one->authorizations_over_budget({ level_of_care_id => 1002, program_id => 1002 }), [] );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# services_by_client
    can_ok( $one, 'services_by_client' );
    throws_ok{ $one->services_by_client } qr/Attribute \(client_id\) is required/;
    ok( $one->services_by_client({ client_id => 1003 }) );

    # This report is generated with nested object methods in the view
    # so there's nothing to test here.
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# audit_trail_by_client
    can_ok( $one, 'audit_trail_by_client' );
    throws_ok{ $one->audit_trail_by_client } qr/Attribute \(date\) is required/;
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' }), [
        {
            client_id                   => 1001,
            client_name                 => 'Davis, Miles D',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1002,
            client_name                 => 'Mingus, Charles',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1003,
            client_name                 => 'Monk, Thelonious',
            level_of_care               => 'Rehabilitation',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1005,
            client_name                 => 'Powell Jr., Bud J',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1006,
            client_name                 => 'zData, Bad',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
    ]);

        # Test that billings that aren't billed yet are not counted
        my $billing_cycle = $test->financial_setup_billingcycle;
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' })->[3], 
        {
            client_id                   => 1003,
            client_name                 => 'Monk, Thelonious',
            level_of_care               => 'Rehabilitation',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
    );

    dbinit( 1 );
    $test->financial_setup( 1 );
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' }), [
        {
            client_id                   => 1001,
            client_name                 => 'Davis, Miles D',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => '525.76',
            previous_payments_total     => 0,
            previous_balance            => '525.76',
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => '25.76',
            this_month_balance          => '500.00',
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1002,
            client_name                 => 'Mingus, Charles',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1003,
            client_name                 => 'Monk, Thelonious',
            level_of_care               => 'Rehabilitation',
            previous_billings_total     => 775.04,
            previous_payments_total     => 0,
            previous_balance            => 775.04,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 657.88,
            this_month_balance          => 117.16,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1005,
            client_name                 => 'Powell Jr., Bud J',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 262.88,
            previous_payments_total     => 0,
            previous_balance            => 262.88,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 262.88,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1006,
            client_name                 => 'zData, Bad',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
    ]);

        # test that payments are not included if they are entered_in_error or refunded
    is( eleMentalClinic::Financial::Transaction->retrieve( 1001 )->entered_in_error, 0 );
        eleMentalClinic::Financial::Transaction->retrieve( 1001 )->entered_in_error( 1 )->save; # $7.48 payment
    is( eleMentalClinic::Financial::Transaction->retrieve( 1002 )->refunded, 0 );
        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->refunded( 1 )->save; # $131.44 payment
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' })->[3], 
        {
            client_id                   => 1003,
            client_name                 => 'Monk, Thelonious',
            level_of_care               => 'Rehabilitation',
            previous_billings_total     => 775.04,
            previous_payments_total     => 0,
            previous_balance            => 775.04,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 518.96,
            this_month_balance          => 256.08,
            this_month_writeoffs_total  => 0,
        },
    );

    is( eleMentalClinic::Financial::Transaction->retrieve( 1001 )->entered_in_error, 1 );
        eleMentalClinic::Financial::Transaction->retrieve( 1001 )->entered_in_error( 0 )->save;
    is( eleMentalClinic::Financial::Transaction->retrieve( 1002 )->refunded, 1 );
        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->refunded( 0 )->save;

    $test->financial_setup( 2 );
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' }), [
        {
            client_id                   => 1001,
            client_name                 => 'Davis, Miles D',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => '525.76',
            previous_payments_total     => 0,
            previous_balance            => '525.76',
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => '25.76',
            this_month_balance          => '500.00',
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1002,
            client_name                 => 'Mingus, Charles',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1003,
            client_name                 => 'Monk, Thelonious',
            level_of_care               => 'Rehabilitation',
            previous_billings_total     => '775.04',
            previous_payments_total     => 0,
            previous_balance            => '775.04',
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 775.04,
            this_month_balance          => '0.00', # TODO would be nice if returned 0 instead
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1005,
            client_name                 => 'Powell Jr., Bud J',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 262.88,
            previous_payments_total     => 0,
            previous_balance            => 262.88,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 262.88,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1006,
            client_name                 => 'zData, Bad',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
    ]);

    $one->db->do_sql( q/ UPDATE prognote SET billing_status = 'Unbillable' WHERE rec_id IN ( 1056, 1057, 1058 ) /, 'just execute it' );
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' }), [
        {
            client_id                   => 1001,
            client_name                 => 'Davis, Miles D',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => '525.76',
            previous_payments_total     => 0,
            previous_balance            => '525.76',
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => '25.76',
            this_month_balance          => 105.68,
            this_month_writeoffs_total  => 394.32,
        },
        {
            client_id                   => 1002,
            client_name                 => 'Mingus, Charles',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1003,
            client_name                 => 'Monk, Thelonious',
            level_of_care               => 'Rehabilitation',
            previous_billings_total     => '775.04',
            previous_payments_total     => 0,
            previous_balance            => '775.04',
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 775.04,
            this_month_balance          => '0.00',
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1005,
            client_name                 => 'Powell Jr., Bud J',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 262.88,
            previous_payments_total     => 0,
            previous_balance            => 262.88,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 262.88,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1006,
            client_name                 => 'zData, Bad',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
    ]);

        # test that payments are not included if they are entered_in_error or refunded
    is( eleMentalClinic::Financial::Transaction->retrieve( 1010 )->entered_in_error, 0 );
        eleMentalClinic::Financial::Transaction->retrieve( 1010 )->entered_in_error( 1 )->save; # $25.76 payment
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' })->[1], 
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => '525.76',
            previous_payments_total     => 0,
            previous_balance            => '525.76',
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => '0.00',
            this_month_balance          => 131.44,
            this_month_writeoffs_total  => 394.32,
        },
    );
    is( eleMentalClinic::Financial::Transaction->retrieve( 1010 )->entered_in_error, 1 );
        eleMentalClinic::Financial::Transaction->retrieve( 1010 )->entered_in_error( 0 )->save;

    is( eleMentalClinic::Financial::Transaction->retrieve( 1010 )->refunded, 0 );
        eleMentalClinic::Financial::Transaction->retrieve( 1010 )->refunded( 1 )->save; # $25.76 payment
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' })->[1], 
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => '525.76',
            previous_payments_total     => 0,
            previous_balance            => '525.76',
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => '0.00',
            this_month_balance          => 131.44,
            this_month_writeoffs_total  => 394.32,
        },
    );
    is( eleMentalClinic::Financial::Transaction->retrieve( 1010 )->refunded, 1 );
        eleMentalClinic::Financial::Transaction->retrieve( 1010 )->refunded( 0 )->save;


    $test->financial_setup( 3 );
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' }), [
        {
            client_id                   => 1001,
            client_name                 => 'Davis, Miles D',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => '525.76',
            previous_payments_total     => 0,
            previous_balance            => '525.76',
            previous_writeoffs_total    => 0,
            this_month_billings_total   => '657.20',
            this_month_payments_total   => 25.76,
            this_month_balance          => 762.88,
            this_month_writeoffs_total  => 394.32,
        },
        {
            client_id                   => 1002,
            client_name                 => 'Mingus, Charles',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1003,
            client_name                 => 'Monk, Thelonious',
            level_of_care               => 'Rehabilitation',
            previous_billings_total     => '775.04',
            previous_payments_total     => 0,
            previous_balance            => '775.04',
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 1169.36,
            this_month_payments_total   => 775.04,
            this_month_balance          => 1169.36,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1005,
            client_name                 => 'Powell Jr., Bud J',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 262.88,
            previous_payments_total     => 0,
            previous_balance            => 262.88,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 262.88,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1006,
            client_name                 => 'zData, Bad',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
    ]);

    $test->financial_setup( 4 );
    is_deeply( $one->audit_trail_by_client({ date => '2006-09-15' }), [
        {
            client_id                   => 1001,
            client_name                 => 'Davis, Miles D',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => 1182.96,
            previous_payments_total     => 25.76,
            previous_balance            => 762.88,
            previous_writeoffs_total    => 394.32,
            this_month_billings_total   => 0,
            this_month_payments_total   => '657.20',
            this_month_balance          => 105.68,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1002,
            client_name                 => 'Mingus, Charles',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1003,
            client_name                 => 'Monk, Thelonious',
            level_of_care               => 'Rehabilitation',
            previous_billings_total     => '1944.40',
            previous_payments_total     => 775.04,
            previous_balance            => 1169.36,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 1169.36,
            this_month_balance          => '0.00',
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1005,
            client_name                 => 'Powell Jr., Bud J',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 262.88,
            previous_payments_total     => 0,
            previous_balance            => 262.88,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 262.88,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1006,
            client_name                 => 'zData, Bad',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
    ]);

        # test that writeoffs are calculated correctly when a note is part of a combined note
        # see ticket #596 - both notes must be marked unbillable.
        $one->db->do_sql( q/ UPDATE prognote SET billing_status = 'Unbillable' WHERE rec_id IN ( 1051, 1351 ) /, 'just execute it' );
        # need to pretend that this note wasn't fully paid
    is( eleMentalClinic::Financial::Transaction->retrieve( 1026 )->paid_amount, 152.88 );
        $one->db->do_sql( q/ UPDATE transaction SET paid_amount = 52.88 WHERE rec_id = 1026 /, 'just execute it' );
    is_deeply( $one->audit_trail_by_client({ date => '2006-09-15' }), [
        {
            client_id                   => 1001,
            client_name                 => 'Davis, Miles D',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => 1182.96,
            previous_payments_total     => 25.76,
            previous_balance            => 762.88,
            previous_writeoffs_total    => 394.32,
            this_month_billings_total   => 0,
            this_month_payments_total   => '657.20',
            this_month_balance          => 105.68,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1002,
            client_name                 => 'Mingus, Charles',
            level_of_care               => 'Discharged',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1003,
            client_name                 => 'Monk, Thelonious',
            level_of_care               => 'Rehabilitation',
            previous_billings_total     => '1944.40',
            previous_payments_total     => 775.04,
            previous_balance            => 1169.36,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 1069.36,
            this_month_balance          => '0.00',
            this_month_writeoffs_total  => '100.00',
        },
        {
            client_id                   => 1005,
            client_name                 => 'Powell Jr., Bud J',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 262.88,
            previous_payments_total     => 0,
            previous_balance            => 262.88,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 262.88,
            this_month_writeoffs_total  => 0,
        },
        {
            client_id                   => 1006,
            client_name                 => 'zData, Bad',
            level_of_care               => 'Residential Treatment Home',
            previous_billings_total     => 0,
            previous_payments_total     => 0,
            previous_balance            => 0,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 0,
            this_month_writeoffs_total  => 0,
        },
    ]);

        # demonstrate that if a note is marked unbillable, it won't show up as written off until 
        # it's been processed by the first payer
        dbinit( 1 );
        $test->financial_setup( 1, undef, { no_payment => 1 } );
        $one->db->do_sql( q/ UPDATE prognote SET billing_status = 'Unbillable' WHERE rec_id IN ( 1056, 1057, 1058 ) /, 'just execute it' );
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' })->[1], 
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => 525.76,
            previous_payments_total     => 0,
            previous_balance            => 525.76,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 0,
            this_month_balance          => 525.76,
            this_month_writeoffs_total  => 0,
        },
    );

        # now, after payment, the writeoff should show up
        dbinit( 1 );
        $test->financial_setup( 1 );
        $one->db->do_sql( q/ UPDATE prognote SET billing_status = 'Unbillable' WHERE rec_id IN ( 1056, 1057, 1058 ) /, 'just execute it' );
    is_deeply( $one->audit_trail_by_client({ date => '2006-08-15' })->[1], 
        {
            client_id                   => 1004,
            client_name                 => 'Fitzgerald, Ella',
            level_of_care               => 'Maintenance',
            previous_billings_total     => 525.76,
            previous_payments_total     => 0,
            previous_balance            => 525.76,
            previous_writeoffs_total    => 0,
            this_month_billings_total   => 0,
            this_month_payments_total   => 25.76,
            this_month_balance          => 105.68,
            this_month_writeoffs_total  => 394.32,
        },
    );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# payment_totals_by_program
    can_ok( $one, 'payment_totals_by_program' );
    throws_ok{ $one->payment_totals_by_program } qr/Payment OR payment number is required/;

    is_deeply( $one->payment_totals_by_program({ billing_payment_id => 666 }), [] );
    is_deeply( $one->payment_totals_by_program({ billing_payment_id => 1001 }), [] );
    is_deeply( $one->payment_totals_by_program({ billing_payment_id => 1002 }), [] );

    is_deeply( $one->payment_totals_by_program({ payment_number => 666 }), [] );
    is_deeply( $one->payment_totals_by_program({ payment_number => 12345 }), [] ); # 1001
    is_deeply( $one->payment_totals_by_program({ payment_number => 12350 }), [] ); # 1002

    # ---
    $test->financial_setup( 1 );
    is( scalar@{ $one->payment_totals_by_program({ billing_payment_id => 1001 })}, 1 );
    is_deeply( $one->payment_totals_by_program({ billing_payment_id => 1002 }), [] );
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ program_id }, 1001 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ program_name }, 'Substance abuse' );
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ total_paid }, 683.64 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ total_billed }, '1300.80' );
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ total_deductions }, 617.16 );

    is( $one->payment_totals_by_program({ payment_number => 12345 })->[ 0 ]->{ program_id }, 1001 );
    is( $one->payment_totals_by_program({ payment_number => 12345 })->[ 0 ]->{ program_name }, 'Substance abuse' );
    is( $one->payment_totals_by_program({ payment_number => 12345 })->[ 0 ]->{ total_paid }, 683.64 );
    is( $one->payment_totals_by_program({ payment_number => 12345 })->[ 0 ]->{ total_billed }, '1300.80' );
    is( $one->payment_totals_by_program({ payment_number => 12345 })->[ 0 ]->{ total_deductions }, 617.16 );

        # test that payments are not included if they are entered_in_error or refunded
    is( eleMentalClinic::Financial::Transaction->retrieve( 1001 )->entered_in_error, 0 );
        eleMentalClinic::Financial::Transaction->retrieve( 1001 )->entered_in_error( 1 )->save; # $7.48 payment
    is( eleMentalClinic::Financial::Transaction->retrieve( 1002 )->refunded, 0 );
        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->refunded( 1 )->save; # $131.44 payment
    
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ total_paid }, 544.72 );
    
    is( eleMentalClinic::Financial::Transaction->retrieve( 1001 )->entered_in_error, 1 );
        eleMentalClinic::Financial::Transaction->retrieve( 1001 )->entered_in_error( 0 )->save;
    is( eleMentalClinic::Financial::Transaction->retrieve( 1002 )->refunded, 1 );
        eleMentalClinic::Financial::Transaction->retrieve( 1002 )->refunded( 0 )->save;

    # ---
    $test->financial_setup( 2 );
    is( scalar@{ $one->payment_totals_by_program({ billing_payment_id => 1001 })}, 1 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ program_id }, 1001 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ program_name }, 'Substance abuse' );
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ total_paid }, 683.64 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ total_billed }, '1300.80' );
    is( $one->payment_totals_by_program({ billing_payment_id => 1001 })->[ 0 ]->{ total_deductions }, 617.16 );

    is( scalar@{ $one->payment_totals_by_program({ billing_payment_id => 1002 })}, 1 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1002 })->[ 0 ]->{ program_id }, 1001 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1002 })->[ 0 ]->{ program_name }, 'Substance abuse' );
    is( $one->payment_totals_by_program({ billing_payment_id => 1002 })->[ 0 ]->{ total_paid }, 117.16 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1002 })->[ 0 ]->{ total_billed }, 124.64 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1002 })->[ 0 ]->{ total_deductions }, 7.48 );

    is( $one->payment_totals_by_program({ payment_number => 12350 })->[ 0 ]->{ program_id }, 1001 );
    is( $one->payment_totals_by_program({ payment_number => 12350 })->[ 0 ]->{ program_name }, 'Substance abuse' );
    is( $one->payment_totals_by_program({ payment_number => 12350 })->[ 0 ]->{ total_paid }, 117.16 );
    is( $one->payment_totals_by_program({ payment_number => 12350 })->[ 0 ]->{ total_billed }, 124.64 );
    is( $one->payment_totals_by_program({ payment_number => 12350 })->[ 0 ]->{ total_deductions }, 7.48 );

    # ---
    $test->financial_setup( 3 );
    is( scalar@{ $one->payment_totals_by_program({ billing_payment_id => 1001 })}, 1 );
    is( scalar@{ $one->payment_totals_by_program({ billing_payment_id => 1002 })}, 1 );

    is( scalar@{ $one->payment_totals_by_program({ billing_payment_id => 1003 })}, 1 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1003 })->[ 0 ]->{ program_id }, 1001 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1003 })->[ 0 ]->{ program_name }, 'Substance abuse' );
    is( $one->payment_totals_by_program({ billing_payment_id => 1003 })->[ 0 ]->{ total_paid }, 1393.43 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1003 })->[ 0 ]->{ total_billed }, 1826.56 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1003 })->[ 0 ]->{ total_deductions }, 433.13 );

    is( $one->payment_totals_by_program({ payment_number => '060905' })->[ 0 ]->{ program_id }, 1001 );
    is( $one->payment_totals_by_program({ payment_number => '060905' })->[ 0 ]->{ program_name }, 'Substance abuse' );
    is( $one->payment_totals_by_program({ payment_number => '060905' })->[ 0 ]->{ total_paid }, 1393.43 );
    is( $one->payment_totals_by_program({ payment_number => '060905' })->[ 0 ]->{ total_billed }, 1826.56 );
    is( $one->payment_totals_by_program({ payment_number => '060905' })->[ 0 ]->{ total_deductions }, 433.13 );

    # ---
    $test->financial_setup( 4 );
    is( scalar@{ $one->payment_totals_by_program({ billing_payment_id => 1001 })}, 1 );
    is( scalar@{ $one->payment_totals_by_program({ billing_payment_id => 1002 })}, 1 );
    is( scalar@{ $one->payment_totals_by_program({ billing_payment_id => 1003 })}, 1 );

    is( scalar@{ $one->payment_totals_by_program({ billing_payment_id => 1004 })}, 1 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1004 })->[ 0 ]->{ program_id }, 1001 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1004 })->[ 0 ]->{ program_name }, 'Substance abuse' );
    is( $one->payment_totals_by_program({ billing_payment_id => 1004 })->[ 0 ]->{ total_paid }, 433.13 );
    is( $one->payment_totals_by_program({ billing_payment_id => 1004 })->[ 0 ]->{ total_billed }, '643.60' );
    is( $one->payment_totals_by_program({ billing_payment_id => 1004 })->[ 0 ]->{ total_deductions }, 210.47 );

    is( $one->payment_totals_by_program({ payment_number => '070712' })->[ 0 ]->{ program_id }, 1001 );
    is( $one->payment_totals_by_program({ payment_number => '070712' })->[ 0 ]->{ program_name }, 'Substance abuse' );
    is( $one->payment_totals_by_program({ payment_number => '070712' })->[ 0 ]->{ total_paid }, 433.13 );
    is( $one->payment_totals_by_program({ payment_number => '070712' })->[ 0 ]->{ total_billed }, '643.60' );
    is( $one->payment_totals_by_program({ payment_number => '070712' })->[ 0 ]->{ total_deductions }, 210.47 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# monthly_summary_by_insurer
    can_ok( $one, 'monthly_summary_by_insurer' );
    throws_ok { $one->monthly_summary_by_insurer } qr/Attribute \(date\) is required/;
    throws_ok { $one->monthly_summary_by_insurer({ date => '2100-01-01' }) }
        qr/Attribute \(rolodex_id\) is required/;

    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 666, date => '2100-01-01' }), [] );

    # --- billing records but they're not billed yet
        dbinit( 1 );
        $billing_cycle = $test->financial_setup_billingcycle;
        $test->financial_setup_system_validation( $billing_cycle );
        $test->financial_setup_payer_validation( $billing_cycle );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1015, date => '2100-01-01' }), [] );

    # --- billed but not paid yet 
        dbinit( 1 );
        $test->financial_setup( 1, undef, { no_payment => 1 });
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 666, date => '2100-01-01' }), [] );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1015, date => '2100-01-01' }), [
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 124.64, billing_date => '2006-07-15', prognote_date => '2006-07-03', },
        { client_name => 'Fitzgerald, Ella', state_specific_id => undef, client_id => 1004, billed_units => 2, billed_amount => 131.44, billing_date => '2006-07-15', prognote_date => '2006-07-03', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-07-15', prognote_date => '2006-07-05', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-07-15', prognote_date => '2006-07-07', },
        { client_name => 'Fitzgerald, Ella', state_specific_id => undef, client_id => 1004, billed_units => 2, billed_amount => 131.44, billing_date => '2006-07-15', prognote_date => '2006-07-07', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-07-15', prognote_date => '2006-07-10', },
        { client_name => 'Fitzgerald, Ella', state_specific_id => undef, client_id => 1004, billed_units => 2, billed_amount => 131.44, billing_date => '2006-07-15', prognote_date => '2006-07-10', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-07-15', prognote_date => '2006-07-12', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 124.64, billing_date => '2006-07-15', prognote_date => '2006-07-14', },
        { client_name => 'Fitzgerald, Ella', state_specific_id => undef, client_id => 1004, billed_units => 2, billed_amount => 131.44, billing_date => '2006-07-15', prognote_date => '2006-07-14', },
    ]);

    # ---
        dbinit( 1 );
        $test->financial_setup( 1 );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1015, date => '2100-01-01' }), [] );

        $test->financial_setup( 2, undef, { no_payment => 1 } );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1015, date => '2100-01-01' }), [] );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1014, date => '2100-01-01' }), [
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 124.64, billing_date => '2006-08-31', prognote_date => '2006-07-03', },
    ]);

    # ---
        dbinit( 1 );
        $test->financial_setup( 1 );
        $test->financial_setup( 2 );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1015, date => '2100-01-01' }), [] );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1014, date => '2100-01-01' }), [] );

        $test->financial_setup( 3, undef, { no_payment => 1 } );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1015, date => '2100-01-01' }), [
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-17', },
        { client_name => 'Fitzgerald, Ella', state_specific_id => undef, client_id => 1004, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-17', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 4, billed_amount => 249.28, billing_date => '2006-08-15', prognote_date => '2006-07-19', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-21', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-21', },
        { client_name => 'Fitzgerald, Ella', state_specific_id => undef, client_id => 1004, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-21', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-24', },
        { client_name => 'Fitzgerald, Ella', state_specific_id => undef, client_id => 1004, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-24', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-26', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-28', },
        { client_name => 'Fitzgerald, Ella', state_specific_id => undef, client_id => 1004, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-28', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-31', },
        { client_name => 'Fitzgerald, Ella', state_specific_id => undef, client_id => 1004, billed_units => 2, billed_amount => 131.44, billing_date => '2006-08-15', prognote_date => '2006-07-31', },
    ]);

    # ---
        dbinit( 1 );
        $test->financial_setup( 1 );
        $test->financial_setup( 2 );
        $test->financial_setup( 3 );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1015, date => '2100-01-01' }), [] );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1014, date => '2100-01-01' }), [] );
    
        $test->financial_setup( 4, undef, { no_payment => 1 } );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1014, date => '2100-01-01' }), [
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 4, billed_amount => 249.28, billing_date => '2006-09-06', prognote_date => '2006-07-19', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 3, billed_amount => 262.88, billing_date => '2006-09-06', prognote_date => '2006-07-21', },
        { client_name => 'Monk, Thelonious', state_specific_id => 64127, client_id => 1003, billed_units => 2, billed_amount => 131.44, billing_date => '2006-09-06', prognote_date => '2006-07-24', },
    ]);

    # ---
        dbinit( 1 );
        $test->financial_setup( 1 );
        $test->financial_setup( 2 );
        $test->financial_setup( 3 );
        $test->financial_setup( 4 );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1015, date => '2100-01-01' }), [] );
    is_deeply( $one->monthly_summary_by_insurer({ rolodex_id => 1014, date => '2100-01-01' }), [] );
 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit( 1 );
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# billing_totals_by_program
    can_ok( $one, 'billing_totals_by_program' );
    throws_ok{ $one->billing_totals_by_program }
        qr/Attribute \(billing_file_id\) is required/;

    is_deeply( $one->billing_totals_by_program({ billing_file_id => 666 }), [] );
    is_deeply( $one->billing_totals_by_program({ billing_file_id => 1001 }), [] );
    is_deeply( $one->billing_totals_by_program({ billing_file_id => 1002 }), [] );

    $test->financial_setup( 1 );
    is_deeply( $one->billing_totals_by_program({ billing_file_id => 666 }), [] );

    is_deeply( $one->billing_totals_by_program({ billing_file_id => 1001 }), [
        {
            program_id      => 1,
            program_name    => 'Referral',
            client_id       => 1005,
            state_specific_id => undef,
            total_billed    => 262.88,
            client_name     => 'Powell Jr., Bud J',
        },
    ]);

    is_deeply( $one->billing_totals_by_program({ billing_file_id => 1002 }), [
        {
            program_id      => 1001,
            program_name    => 'Substance abuse',
            client_id       => 1004,
            state_specific_id => undef,
            total_billed    => 525.76,
            client_name     => 'Fitzgerald, Ella',
        },
        {
            program_id      => 1001,
            program_name    => 'Substance abuse',
            client_id       => 1003,
            state_specific_id => 64127,
            total_billed    => 775.04,
            client_name     => 'Monk, Thelonious',
        },
    ]);

    $test->financial_setup( 2 );
    is_deeply( $one->billing_totals_by_program({ billing_file_id => 1003 }), [
        {
            program_id      => 1001,
            program_name    => 'Substance abuse',
            client_id       => 1003,
            state_specific_id => 64127,
            total_billed    => 124.64,
            client_name     => 'Monk, Thelonious',
        },
    ]);

    $test->financial_setup( 3 );
    is_deeply( $one->billing_totals_by_program({ billing_file_id => 1004 }), [
        {
            program_id      => 1001,
            program_name    => 'Substance abuse',
            client_id       => 1004,
            state_specific_id => undef,
            total_billed    => '657.20',
            client_name     => 'Fitzgerald, Ella',
        },
        {
            program_id      => 1001,
            program_name    => 'Substance abuse',
            client_id       => 1003,
            state_specific_id => 64127,
            total_billed    => 1169.36,
            client_name     => 'Monk, Thelonious',
        },
    ]);

    $test->financial_setup( 4 );
    is_deeply( $one->billing_totals_by_program({ billing_file_id => 1005 }), [
        {
            program_id      => 1001,
            program_name    => 'Substance abuse',
            client_id       => 1003,
            state_specific_id => 64127,
            total_billed    => '643.60',
            client_name     => 'Monk, Thelonious',
        },
    ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dbinit();

    for my $report_class (eleMentalClinic::Report->plugins) {
        for my $attribute ($report_class->meta->get_all_attributes) {
            # XXX gross hack
            next if $attribute->name eq 'result' or
                $attribute->name eq 'personnel' or
                $attribute->name eq 'client' or
                $attribute->name =~ /^_/;
            ok( $attribute->label,
                $attribute->name . " in $report_class has a label"
            );
        }
    }
