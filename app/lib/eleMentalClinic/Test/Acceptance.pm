# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.

=pod

This is a utility library for functions common to different Selenium acceptance tests.  I've chosen to extend Test::WWW::Selenium directly so that tests can initialize a single object and have access both to the core selenium testing methods, and to the helper methods I'm adding in to handle repeat test chunks like initialization and login.

Each helper method that uses test methods internally should return true if all internal test methods passed, or false if any internal test method fails.

Thus:

ok( $acceptance->internal_method() );

should provide a pointer to where the main test script fails, even if a failur is inside an internal method...

NOTE - Currently this library assumes that the workstation instance of emc has been deployed to $DEFAULT_ROOT_URL.
TODO - Either this needs to be standard, or we need to use a developer config file to set this.

TODO - Currently the $DEFAULT_BROWSER is set for firefox, with an Ubuntu Linux path to the binary.  This will probably need to be adjusted for OS X.  Perhaps with a check for OS and a switch on default type?

=head1 AUTHORS

=over 4

=item Josh Partlow L<jpartlow@opensourcery.com>

=back

=cut

package eleMentalClinic::Test::Acceptance;

use strict;
use warnings;
use Data::Dumper;
use Date::Calc qw/ Today Month_to_Text /;
use Test::More;
use eleMentalClinic::Test;

use base qw/ Test::WWW::Selenium Exporter /;
our @EXPORT_OK = qw/ %Test_Patients @Patient_Demographics_Fields @Patient_Intake_Fields @Patient_Header_Fields @Patient_Header_Intake_Fields /;

our $DEFAULT_HOST = $ENV{SELENIUM_HOST} || 'localhost';
our $DEFAULT_PORT = $ENV{SELENIUM_PORT} || '4444';
our $DEFAULT_BROWSER = $ENV{SELENIUM_BROWSER} || '*firefox /usr/lib/firefox/firefox-bin';
our $DEFAULT_ROOT_URL = $ENV{SELENIUM_ROOT_URL} || 'http://simple.elementalclinic.dev';
our %DEFAULT_ARGS = ( host => $DEFAULT_HOST, 
                      port => $DEFAULT_PORT, 
                      browser => $DEFAULT_BROWSER, 
                      browser_url => $DEFAULT_ROOT_URL, );
our $DEFAULT_LOGIN = 'clinic';
our $DEFAULT_PASSWORD = 'dba';
our $DEFAULT_TIMEOUT = $ENV{ SELENIUM_DEFAULT_TIMEOUT } || 5000;

#our $DB_HOST = $ENV{EMC_DB_HOST} || 'localhost';
#our $DB_PORT = $ENV{EMC_DB_PORT} || '5432';
#our $DATABASE = $ENV{EMC_DB} || 'elementalclinic_simple';
#our $USER = $ENV{EMC_USER};
#our $PASSWORD = $ENV{EMC_PASS};

my ($year, $month, $day) = Today;
$month = "0$month" if length($month) == 1;
$day = "0$day" if length($day) == 1;

#{{{ Test_Patients data
our %Test_Patients = (
    1 => {
        lname          => 'TP01Last',
        fname          => 'TP01First',
        dob            => "$year-$month-$day",
        mname          => 'TP01M',
        addr           => '123 Street',
        addr_2         => 'Office 32',
        city           => 'TestCity',
        state          => 'OR',
        post_code      => '12345',
        phone          => '123-456-7890',
        phone_2        => '503-123-4567',
        email          => 'test@test.com',
        sex            => 'Male',
        dont_call      => 1,
        last_called    => ($year - 2)."-$month-$day",
        renewal_date   => ($year - 3)."-$month-$day",
        last_doctor_id => 1001, 
        doctor         => $rolodex->{ $rolodex_treaters->{1001}->{rolodex_id} }->{name},
    },
    2 => {
        lname          => 'TP02Last',
        fname          => 'TP02First',
        dob            => ($year - 1)."-$month-$day",
        mname          => 'TP02M',
        addr           => '456 Way',
        addr_2         => 'Building 2',
        city           => 'City2',
        state          => 'CA',
        post_code      => '67890',
        phone          => '456-789-0123',
        phone_2        => '503-456-7890',
        email          => 'test.2@testing.com',
        sex            => 'Female',
        dont_call      => 0,
        last_called    => ($year - 4)."-$month-$day",
        renewal_date   => ($year - 5)."-$month-$day",
        last_doctor_id => 1002,
        doctor         => $rolodex->{ $rolodex_treaters->{1002}->{rolodex_id} }->{name},
    },
);
#}}}
#{{{ Patient_Demographics_Fields
# Those fields used in the demographics form
our @Patient_Demographics_Fields = (
    'lname',
    'fname',
    'dob',
    'mname', 
    'addr',
    'addr_2',
    'city',
    'state',
    'post_code',
    'phone',
    'phone_2', 
    'email',
    'sex',
    'dont_call',
    'renewal_date',
#    'last_called',
#    'last_doctor_id',
);
#}}}
#{{{ Patient_Intake_Fields
# Those fields used for patient intake.
our @Patient_Intake_Fields = ( 
    'lname',
    'fname',
    'dob',
    'mname', 
    'addr',
    'addr_2',
    'city',
    'state',
    'post_code',
    'phone',
    'phone_2', 
    'email',
    'sex',
    'dont_call',
);
#}}}
#{{{ Patient_Header_Fields
# Those fields that we expect to see data for in the patient header
our @Patient_Header_Fields = (
    'lname',
    'fname',
    'mname',
    'addr',
    'city',
    'state',
    'post_code',
    'phone',
    'renewal_date',
    'doctor',
#    'last_called',
);
#}}}
#{{{ Patient_Header_Intake_Fields
# Those fields that we expect to see data for in the patient header
# after intake
our @Patient_Header_Intake_Fields = (
    'lname',
    'fname',
    'mname',
    'addr',
    'city',
    'state',
    'post_code',
    'phone',
);
#}}}

our $DBH = undef;
our $TEST = undef;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %args = @_;

    my $self = $class->SUPER::new( 
        %DEFAULT_ARGS, 
        %args, #To allow overrideing
    );
    $TEST = eleMentalClinic::Test->new();
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 _new_selenium()

Class constructor method to return a Selenium object initialized with defaults.

Use this if you want an unadorned Test::WWW::Selenium object for some reason.

=cut

sub _new_selenium {
    my $class = shift;
    my %args = @_;
    
    return Test::WWW::Selenium->new(
        %DEFAULT_ARGS,
        %args, # to allow overriding
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 connect() 

Returns a DBI handle object to the eleMentalClinic database 
specified by the connection parameters.

=cut

sub connect {
    my $self = shift;

    unless (defined $DBH) {
        $DBH = $self->get_test->db->dbh;
    }
    return $DBH;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 get_test()

Accessor for the eleMentalClinic::Test object instance.

=cut

sub get_test {
    my $self = shift;

    return $TEST;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 delete_data()

Deletes all of the test data created by the acceptance tests.

=cut

sub delete_data {
    my $self = shift;

    my $dbh = $self->connect();
    my $client_ids = 
        $self->_get_ids("client_id",
            'client',
            "lname ~ 'TP[0-9]{2}Last'");
   
    if ($client_ids) {

        $self->_delete_emergency_contacts($client_ids);
        $self->_delete_table('client_placement_event', 'client_id', $client_ids);
        $self->_delete_table('client', 'client_id', $client_ids);

        $dbh->do("DELETE FROM client WHERE lname ~ 'TP[0-9]{2}Last'")
            or die 'Unable to delete client recs: '.DBI->errstr;
    }
    # otherwise, no client records to delete...
    
    return split /,/, $client_ids;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _delete_emergency_contacts {
    my $self = shift;
    my $client_ids = shift;
    $client_ids or die "Must have client_ids parameter";
    
    my $dbh = $self->connect;
    my $rolodex_contact_ids = 
        $self->_get_ids('rolodex_contacts_id',
            'v_emergency_contacts',
            "contact_for_client_id in ($client_ids)");
    my $rolodex_ids = 
        $self->_get_ids('rolodex_id',
            'v_emergency_contacts',
            "contact_for_client_id in ($client_ids)");

    $self->_delete_table('client_contacts', 'client_id', $client_ids);
    $self->_delete_table('rolodex_contacts', 'rec_id', $rolodex_contact_ids) if $rolodex_contact_ids;
    $self->_delete_table('rolodex', 'rec_id', $rolodex_ids) if $rolodex_ids;

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _get_ids {
    my $self = shift;
    my ($field, $table, $where) = @_;
    $field && $table && $where 
        or die "Must have field, table and where parameters.";

    my $dbh = $self->connect;
    my $id_refs = $dbh->selectcol_arrayref(
        "SELECT DISTINCT $field
         FROM $table
         WHERE $where")
        or die 'Unable to select ids for $field, $table, $where: '.DBI->errstr;

    my $ids = join(',', @$id_refs);
    return $ids;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _delete_table {
    my $self = shift;
    my ($table, $id_field, $ids) = @_;
    $table && $id_field && $ids or die 'Must have table, id_field and ids parameters';

    my $dbh = $self->connect;
    $dbh->do("DELETE FROM $table WHERE $id_field in ($ids)")
        or die "Unable to delete $table recs: ".DBI->errstr;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 login()

Handles logging in as a user of the system.  Also tests the action of logging in, and that login was successful.

=cut

sub login {
    my $self = shift;

    my $ok = 1;
    $self->login_without_verifying(@_) or $ok = 0;
    $self->is_element_present_ok('link=logout') or $ok = 0;
    return $ok;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 login_without_verifying() 

Logs in without checking that login was successful.  Used to simulate bad logins or logins as personnel not in the system.

=cut

sub login_without_verifying {
    my $self = shift;
    my $args = shift || {};
    my $login = $args->{login} || $DEFAULT_LOGIN;
    my $password = $args->{password} || $DEFAULT_PASSWORD;

    my $ok = 1;
    $self->open_ok($self->get_root_url."/gateway/") or $ok = 0;
    $self->title_like_ok(qr/eleMental Clinic/) or $ok = 0;
    $self->is_element_present_ok('xpath=//input[@name="login"]') or $ok = 0;
    $self->type_ok('id=login', $login) or $ok = 0;
    $self->type_ok('id=password', $password) or $ok = 0;
    $self->click_and_wait_ok('xpath=//input[@type="submit" and @name="op"]') or $ok = 0;
    return $ok;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 logout()

Forces a logout from the application and tests that it was successful.

=cut

sub logout {
    my $self = shift;
    
    my $ok = 1;
    $self->is_element_present_ok('link=logout') or $ok = 0;
    $self->click_and_wait_ok('link=logout') or $ok = 0;
    return $ok;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 click_and_wait_ok()

This is a convenience method that will perform the passed click and then wait for a default time.  Default may be overridden.

=cut

sub click_and_wait_ok {
    my $self = shift;
    my $locator = shift or die "Must pass a locator.";
    my $timeout = shift || $DEFAULT_TIMEOUT;

    my $ok = 1;
    $self->click_ok($locator) or $ok = 0;
    $self->wait_for_page_to_load($timeout) or $ok = 0;
    $self->check_internal_server_error or $ok = 0;
    return $ok;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 get_root_url()

Selenium's ROOT_URL parameter.  This defines the root url that all requests are related too and is necessary for Selenium's proxying to work correctly (L<see http://www.openqa.org/selenium-rc/tutorial.html>)

=cut

sub get_root_url {
    return $DEFAULT_ROOT_URL;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 new_patient()

Clicks New Patient, fills out form and adds a new patient
using the application.  The key to the patient data to be 
entered is passed in as a parameter to the method.  It must
correspond to a key in %Test_Patients.

=cut

sub new_patient {
    my $self = shift;
    my $patient_key = shift;

    my $patient = $self->get_patient($patient_key);

    my $ok = 1;
    $self->click_and_wait_ok('link=New client') or $ok = 0;
    $self->_set_patient($patient_key, \@Patient_Intake_Fields) or $ok = 0;
    $self->click_and_wait_ok('name=submit') or $ok = 0;    
    $self->is_text_present_ok($patient->{lname}.", ".$patient->{fname}) or $ok = 0;
    return $ok;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 save_patient()

Save edits to a patient and check that save returned back to
demographics without error.

=cut

sub save_patient {
    my $self = shift;

    my $ok = 1;
    $self->click_and_wait_ok('xpath=//input[@value="Save Patient"]') or $ok = 0;
    ok( ! $self->is_element_present('xpath=//div[@class="errors"]'), "no errors.")
        or $ok = 0;
    $self->is_element_present_ok('xpath=//input[@value="Save Patient"]') or $ok = 0;
    return $ok;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 set_patient()
Sets the current screens patient demographics fields to 
the values assocaited with the %Test_Patients record
for the passed key.  Expects that the current screen
is patient demographics for the patient to be edited.

=cut

sub set_patient {
    my $self = shift;
    my $patient_key = shift;

    my $patient = $self->get_patient($patient_key);

    my $ok = 1;
    $self->_set_patient($patient_key) or $ok = 0;
    $self->save_patient or $ok = 0;
    $self->is_text_present_ok($patient->{lname}.", ".$patient->{fname}, 'still in demographics page') or $ok = 0;
    return $ok;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 check_internal_server_error()

Fails test and halts if we hit an internal server error.

=cut
sub check_internal_server_error {
    my $self = shift;

    die '*****************  INTERNAL SERVER ERROR' if $self->is_text_present('Internal Server Error');
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _set_patient {
    my $self = shift;
    my $patient_key = shift;
    my $field_keys = shift || \@Patient_Demographics_Fields;
    
    my $patient = $self->get_patient($patient_key);
    
    my $ok = 1;
    foreach my $key (@$field_keys) {
        if ($key eq 'sex' || $key eq 'dont_call' || $key eq 'last_doctor_id' ) {
            $self->select_ok("id=$key","value=$patient->{$key}", "set select $key to option $patient->{$key}")
                or $ok = 0;
        }
        else {
            $self->type_ok("id=$key", $patient->{$key}, "set field $key to $patient->{$key}")
                or $ok = 0;
        }
    }
    return $ok;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 verify_patient_demographics()

Verifies all the fields of a client demographics screen
match the values of the patient record identified by
passed patient hash key.  Expects that current focus
is a patient demographics screen.

=cut

sub verify_patient_demographics() {
    my $self = shift;
    my $patient_key = shift;
    my $field_keys = shift || \@Patient_Demographics_Fields;

    my $patient = $self->get_patient($patient_key);

    my $ok = 1;
    foreach my $key (@$field_keys) {
        $self->value_is("id=$key", $patient->{$key}, "Found correct value for input $key") or $ok = 0;
    }
    return $ok;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 get_patient()

Returns the patient hash from %Test_Patients matching
the passed key or dies.

=cut

sub get_patient {
    my $self = shift;
    my $patient_key = shift;
    $patient_key or die "Patient key parameter is required.";

    my $patient = $Test_Patients{$patient_key}
        or die "No test patient for key: $patient_key";
    return $patient;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 verify_patient_header()

Verifies that patient header information matches  
the values of the patient record identified by
passed patient hash key.  Expects that current focus
is a client screen screen.

=cut

sub verify_patient_header {
    my $self = shift;
    my( $patient_key, $field_keys ) = @_;

    $field_keys ||= \@Patient_Header_Fields;

    my $patient = $self->get_patient($patient_key);
    
    my $header_text = $self->get_text('xpath=//div[@id="client_content"]//*');

    my $ok = 1;
    foreach my $key (@$field_keys) {
        like( $header_text, qr/$patient->{$key}/ ,
              "header contained data: $patient->{$key}" ) or $ok = 0;
    }
    return $ok;
}

1;
