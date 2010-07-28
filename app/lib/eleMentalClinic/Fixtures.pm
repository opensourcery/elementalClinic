=head1 eleMentalClinic::Fixtures -- fixture compiler and loader for eMC

=head1 METHODS

=over

=cut
package eleMentalClinic::Fixtures;

use strict;
use warnings;

use Data::Dumper;
use YAML::Syck;
use Template;
use DBI;
use Carp;

use eleMentalClinic::DB;

# TODO are these all necessary?
use eleMentalClinic::Client::Allergy;
use eleMentalClinic::Mail::Template;
use eleMentalClinic::Mail::Recipient;
use eleMentalClinic::Client::Notification;
use eleMentalClinic::Client::Release;
use eleMentalClinic::Client;
use eleMentalClinic::Department;
use eleMentalClinic::Schedule::Availability;
use eleMentalClinic::Schedule::Appointments;
use eleMentalClinic::Financial::ClaimsProcessor;
use eleMentalClinic::Financial::BillingCycle;
use eleMentalClinic::Financial::ValidationSet;
use eleMentalClinic::Financial::BillingFile;
use eleMentalClinic::Client::Insurance::Authorization;
use eleMentalClinic::Client::Insurance::Authorization::Request;
#use eleMentalClinic::AuditLog;
use eleMentalClinic::Client::AssessmentTemplate;

use base qw(Exporter);

use base qw/ eleMentalClinic::Base /;

use constant SECONDS_IN_DAY => 86400;

our @EXPORT_OK = qw( load_all_fixtures load_fixture compile_fixture );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 insert_order

Provides a list of fixture data to be inserted into the database

=cut

sub insert_order {
    # FIXME Can't test rolodex.client_id association
    # at the same time as testing client.last_doctor_id (rolodex_treater) association, since inseting clients requires rolodex which requires clients...
    # work around for Simple is not set client.last_doctor_id in the test data, and only test updating the field.
    return (
            'eleMentalClinic::Personnel',
            'eleMentalClinic::Client',
            'eleMentalClinic::Financial::ClaimsProcessor',
            'eleMentalClinic::Rolodex',
            'eleMentalClinic::Contact::Address',
            'eleMentalClinic::Contact::Phone',
            'rolodex_treaters',
            'eleMentalClinic::Client::Placement::Event',
            'eleMentalClinic::Client::Allergy',
            'eleMentalClinic::Client::Release',
            'eleMentalClinic::Client::Discharge',
            # XXX MERGE these next four may be out of order
            'rolodex_contacts',
            'eleMentalClinic::Client::Contact',
            'eleMentalClinic::Client::Insurance',
            'eleMentalClinic::TreatmentPlan',
             'eleMentalClinic::TreatmentGoal',
            'eleMentalClinic::ProgressNote',

             'eleMentalClinic::Client::Referral',

            'assessment_templates',
            'assessment_template_sections',
            'assessment_template_fields',
            'client_assessment',
            'client_assessment_field',
            'client_assessment_old',

            'client_intake',
             'eleMentalClinic::Client::Employment',
             'eleMentalClinic::Client::Diagnosis',
            'eleMentalClinic::Client::Income',
            'eleMentalClinic::Client::IncomeMetadata',
            'eleMentalClinic::Client::Inpatient',
             'eleMentalClinic::Client::Medication',
             'eleMentalClinic::Client::Treater',
            'eleMentalClinic::Client::Letter',
            'eleMentalClinic::Legal',
            'eleMentalClinic::Client::Verification',

            'rolodex_medical_insurance',
            'rolodex_mental_health_insurance',
            'rolodex_dental_insurance',
            'rolodex_employment',
            'rolodex_referral',
            'valid_data_living_arrangement',
            'valid_data_prognote_location',
            'valid_data_program',
            'valid_data_level_of_care',
            'valid_data_charge_code',
            'valid_data_marital_status',
            'valid_data_schedule_types',
            'valid_data_payment_codes',
            'valid_data_confirmation_codes',
            'lookup_groups',
            'lookup_group_entries',
            'personnel_lookup_associations',
            'lookup_associations',
            'eleMentalClinic::Client::Insurance::Authorization',
            'eleMentalClinic::Client::Insurance::Authorization::Request',

            'config',
            'valid_data_abuse',
            'valid_data_adjustment_group_codes',
            'valid_data_claim_adjustment_codes',
            'valid_data_claim_status_codes',
            'valid_data_contact_type',
            'valid_data_dsm4',
            'valid_data_element_errors',
            'valid_data_functional_group_ack_codes',
            'valid_data_functional_group_errors',
            'valid_data_income_sources',
            'valid_data_insurance_relationship',
            'valid_data_insurance_type',
            'valid_data_interchange_ack_codes',
            'valid_data_interchange_note_codes',
            'valid_data_language',
            'valid_data_legal_location',
            'valid_data_legal_status',
            'valid_data_medication',
            'valid_data_nationality',
            'valid_data_print_header',
            'valid_data_prognote_billing_status',
            'valid_data_race',
            'valid_data_release',
            'valid_data_religion',
            'valid_data_remittance_remark_codes',
            'valid_data_rolodex_roles',
            'valid_data_segment_errors',
            'valid_data_sexual_identity',
            'valid_data_sex',
            'valid_data_termination_reasons',
            'valid_data_transaction_handling',
            'valid_data_transaction_set_ack_codes',
            'valid_data_transaction_set_errors',
            'valid_data_treater_types',
            'valid_data_valid_data',

            'validation_rule',
            'validation_rule_last_used',
            'insurance_charge_code_association',
            'eleMentalClinic::ProgressNote::Bounced',
            'schedule_type_associations',
            'eleMentalClinic::Schedule::Availability',
            'eleMentalClinic::Schedule::Appointments',
            'eleMentalClinic::Mail',
            'eleMentalClinic::Mail::Template',
            'eleMentalClinic::Mail::Recipient',
            'eleMentalClinic::Client::Notification::Renewal',
            'eleMentalClinic::Client::Notification::Appointment',
            'eleMentalClinic::Group',
            'eleMentalClinic::Group::Member',
            'eleMentalClinic::Group::Note',
            'eleMentalClinic::Group::Attendee',
            'eleMentalClinic::Log::Access',
            'eleMentalClinic::Log::Security',
            'personnel_role',
            'role_membership',
            'direct_client_permission',
    );
}

=head2 tt_functions

Provides a hash of functions and variables to be allowed in the use of processing fixture datasets with Template Toolkit

Functions:

 * Date functions:
   * `now`: returns the current date
   * `n_ago`: returns the date ''n'' days ago, where ''n'' is a numeric parameter
   * `n_future`: returns the date ''n'' days from now, where ''n'' is a numeric parameter

=cut

sub tt_functions {
    return {
        'date' => {
            'now'       =>      sub {
                                    my @thetime = localtime( time );
                                    return ( ( 1900 + $thetime[5] ) . '-' . $thetime[4] . '-' . $thetime[3] );
                                },
            'n_ago'     =>      sub {
                                    my @thetime = localtime ( time - ( SECONDS_IN_DAY * $_[0] ));
                                    return ( ( 1900 + $thetime[5] ) . '-' . $thetime[4] . '-' . $thetime[3] );

                                },
            'n_future'  =>      sub {
                                    my @thetime = localtime ( time + ( SECONDS_IN_DAY * $_[0] ));
                                    return ( ( 1900 + $thetime[5] ) . '-' . $thetime[4] . '-' . $thetime[3] );
                                },
        },
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 load_fixtures( $path, $recompile )

Prepares a hash of fixtures from a given path, optionally recompiling .yaml files.
If not supplied a path, assumes fixtures/testdata-jazz.

Calls load_all_fixtures to compile fixtures from .yaml or .fixture files.

=cut

sub load_fixtures {
    my $self = shift;
    my( $path, $recompile ) = @_;
    return unless $path;

    return load_all_fixtures( $path, $recompile );
}

=head2 load_all_fixtures( $directory, $force_compile )

Function, not an object method.

Loads fixtures from a given directory.
.fixture fixture files are first run through Template Toolkit, then compiled.
.yaml fixture files are loaded, compiled to .yaml.compiled if they don't exist or $force_compile is true.
If both a .fixture and a .yaml file is found in a directory, the .fixture file is used.

Returns the dataset of the loaded fixtures as a hashref.

=cut

sub load_all_fixtures {
    my ( $directory, $force_compile ) = @_;

    my %fixtures = ();

    opendir( DIR, $directory ) or die( "Couldn't open directory '$directory': $!" );

    foreach my $entry ( readdir( DIR )) {
        my ( $fixture_name ) = $entry =~ /^(.*?)\.fixture$/ ? $entry =~/^(.*?)\.fixture/ : $entry =~ /^(.*?)\.yaml$/;
        next unless $fixture_name;

        my $path = join("/", $directory, $entry );

          if( $entry =~ /^(.*?)\.fixture$/ ) {
            $fixtures{ $fixture_name } = process_fixture( $path );
          }
          else {
            $fixtures{ $fixture_name } = load_fixture( $path, $force_compile );
          }
    }
    closedir( DIR );

    return \%fixtures;
}

=head2 load_fixture($filename, $force_compile)

Function, not an object method.

Loads a fixture (optionally compiling if it does not exist) of
"$filename.compiled". Will force a compile if $force_compile is set.

=cut

sub load_fixture {
    my ($filename, $force_compile) = @_;

    my $recompile = $force_compile || !-f "$filename.compiled";

    if( $recompile ) {
        return compile_fixture($filename);
    }
    else {
        return _retrieve("$filename.compiled");
    }
}

=head2 compile_fixture($filename)

Function, not an object method.

Unconditionally compiles a fixture. Stores it in a filename named
'$filename.compiled'.

=cut

sub compile_fixture {
    my $filename = shift;
    my $data = YAML::Syck::LoadFile( $filename ) or die( $! );
    _store($data, "$filename.compiled");
    return $data;
}

=head2 process_fixture( $file )

Function, not an object method.

Takes a path to a fixture file, not including the .fixture, and runs it through
Template Toolkit, writing it out to a YAML file.  In the future, it should be
refactored to have the output not be written to disk but rather compile it
straight from there.

The VARIABLES hash in Template->new provides functions useful to the fixture
data.

=cut

sub process_fixture {
    my( $file ) = @_;
    return unless $file;
    die( "File '$file' doesn't exist!" ) unless( -f "$file" );

    my $tt = Template->new( {
        VARIABLES => tt_functions,
    } );

    my $processed = '';
    $tt->process( $file, {}, \$processed );
    return unless _store( YAML::Syck::Load( $processed ), "$file.compiled" );
    return _retrieve( "$file.compiled" );
}


sub _retrieve {
    my $file = shift;

    open my $fh, "<", $file
      or croak "Can't open $file: $!";
    my $data = do { local $/; <$fh> };
    return eval $data;
}

sub _store {
    my $data = shift;
    my $file = shift;

    my $dumper = Data::Dumper->new( [$data] );

    open my $fh, ">", $file or
      croak "Can't open $file: $!";
    print $fh $dumper->Indent(1)->Terse(1)->Dump;

    return 1;
}

=head2 insert_fixture_data( $path, $data )

Begins the process of inserting sets of fixture data into the database. Takes
a path to fixture data and an arrayref to which items from the data set should
be loaded, both optional.

=cut

sub insert_fixture_data {
    my $self = shift;
    my ( $path, $dups, $data ) = @_;

    for( insert_order() ) {
        $self->insert_( $_, $path, $dups );
    }

    return 1;
}

=head2 insert_( $data, $path, $ids )

Calls insert_table with the correct parameters for the data types.
Requires a table to be inserted, optionally takes a path and specific
ids to be loaded.

=cut

sub insert_ {
    my $self = shift;
    my( $data, $path, $dups, $ids ) = @_;
    return unless $data;

    $data =~ /^eleMentalClinic::/
            ? $self->insert_table( $data->table, $path, $dups, $ids )
            : $self->insert_table( $data, $path, $dups, $ids );
}

=head2 insert_table( $table, $path, ids )

Takes a table and inserts it into the database. Requires the table to be
inserted and optionally a fixtures path and specific ids to be loaded.

unless() is a specific case for client yet to be implemented, if necessary.

=cut

sub insert_table {
    my $self = shift;
    my( $table, $path, $dups, $ids ) = @_;
    $dups = 1 unless defined $dups;
    my $result;

    my $load_table = $table;
    # XXX hack for insert_rolodex_dirty
    $table =~ s/_dirty$// if $table;

    if( $dups ) {
        my $data = $self->get_test_info( $load_table, $path, $ids );
        return unless $data;
        $result = $self->db->insert_one(
            $table,
            [ keys %$_ ],
            [ values %$_ ],
            undef,
            { no_currval => 1, },
        ) for @$data;
    }
    # if dups is 0, skip inserting rows where the primary key already is in use
    else {
        my $data = $self->get_test_info( $load_table, $path, $ids );
        return unless $data;
        my $pkey = $self->get_pkey_name( $table );
        for my $datum ( @$data ) {
            my $keylist = $self->db->select_one( [ $pkey ], $table, "$pkey = " . $datum->{ $pkey }, '' );
            $result = $self->db->insert_one(
                    $table,
                    [ keys %$datum ],
                    [ values %$datum ],
                    undef,
                    { no_currval => 1, },
            ) unless( $keylist->{ $pkey } eq $datum->{ $pkey });
        }
    }
    my %skip = (
        # XXX lame -- duplicating information in a test
        fake                    => 1,
    );
    $self->reset_pkey_seq( $table ) unless $skip{$table};

    return 1;
}

# TODO: POD
=head2 reset_pkey_seq( $table )
=cut

sub reset_pkey_seq {
    my $self = shift;
    my $table = $_[0];

    return unless $table;
    my $pkey = $self->get_pkey_name( $table );

    my $query = "SELECT setval((SELECT pg_get_serial_sequence('$table', '$pkey')), (SELECT MAX($pkey) FROM $table)+1)";
    return unless $self->db->do_sql( $query );
    return 1;
}

=head2 get_test_info( $table, $path, $ids )

Prepares table to be inserted into the database from a fixture data set.
Takes a required table to be inserted and an optional path to the fixtures
and a sets of ids to be inserted, must be an arrayref.

=cut

sub get_test_info {
    my $self = shift;
    my( $table, $path, $ids ) = @_;
    return unless $table;
    return unless !( $ids ) || ref $ids eq 'ARRAY';

    $table =~ s/(\w*), .*/$1/; # for client
    my $fixtures = $self->load_fixtures( $path );

    my $data = $fixtures->{$table};
    @$ids = sort keys %$data unless $ids;
    my @result = @{$data}{ @$ids };
    return \@result;
}

# TODO POD

sub get_table_names {
    my $self = shift;
    return $self->db->select_many_arrayref(
        [ 'table_name' ],
        'information_schema.tables',
        "WHERE table_type = 'BASE TABLE'",
        "AND table_schema NOT IN ('pg_catalog', 'information_schema') ORDER BY table_name"
    );
}

sub get_field_names {
    my $self = shift;
    my( $tablename ) = @_;
    die( "Table name required to get field names" ) unless $tablename;

    return $self->db->select_many_arrayref(
        [ 'column_name' ],
        'information_schema.columns',
        "WHERE table_name = '$tablename'",
        'ORDER BY column_name'
    );
    return [];
}

sub get_pkey_name {
    my $self = shift;
    my( $name ) = @_;
    my $primary_key = $self->db->select_many_arrayref(
        [ 'constraint_name' ],
        'information_schema.table_constraints',
        "WHERE table_name = '$name' AND constraint_type = 'PRIMARY KEY'",
        ''
    );
    my $table_key = $self->db->select_many_arrayref(
       [ 'column_name' ],
       'information_schema.constraint_column_usage',
       "WHERE table_name = '$name' AND constraint_name = '" . @$primary_key[0] . "'",
       ''
    );
    return @$table_key[0];
}

sub export_db {
    my $self = shift;
    my( $path, $clear, $table_list ) = @_;

    # these muck stuff up. require asking for explicitly
    $table_list->{ 'migration_information' } = 0       unless defined $table_list->{ 'migration_information' };

    $table_list->{ 'type' }                  = 'black' unless defined $table_list->{ 'type' };

    die( "Path to save directory needed!" ) unless $path;
    chop $path if $path =~ /\/$/;

    mkdir( $path ) unless -d $path;
    if( $clear ) {
        opendir( DIR, $path ) or die( "couldn't open $path" );
        for my $entry ( readdir( DIR )) {
            next unless $entry =~ /\.yaml$/;
            unlink( "$path/$entry" );
        }
        closedir( DIR );
    }

    my $tablenames = $self->get_table_names;

    for my $name ( @$tablenames ) {

        # white/black list
        if( $table_list->{ 'type' } eq 'white' ) {
            next unless defined $table_list->{ $name };
            next unless $table_list->{ $name };
        }
        elsif( $table_list->{ 'type' } eq 'black' ) {
            next if defined $table_list->{ $name } and not $table_list->{ $name };
        }

        my $table = {};
        my $table_key = $self->get_pkey_name( $name );

        my $row_ids = $self->db->select_many_arrayref( [ $table_key ], $name, '', '' );

        for my $row ( @$row_ids ) {
            $table->{ $row } = ${ $self->db->select_many( [ '*' ], "$name", "WHERE $table_key = '$row'" ) }[0];
        }

        return unless YAML::Syck::DumpFile( "$path/$name.yaml", $table );
    }
    return 1;
}



'eleMental';

=head1 AUTHORS

=over 4

=item Erik Hollensbe L<erikh@opensourcery.com>

=item Ryan Whitehurst L<ryan@opensourcery.com>

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

=cut
