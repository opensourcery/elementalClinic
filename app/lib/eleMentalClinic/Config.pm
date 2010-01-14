# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Config;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Config

=head1 SYNOPSIS

Configures the application, using stage 1 config to connect to a database and stage 2 config to read the database-accessible configuration.

=head1 METHODS

=cut

use Data::Dumper;
use eleMentalClinic::DB;
use eleMentalClinic::Theme;
use eleMentalClinic::Config::Defaults;
use YAML::Syck qw/ LoadFile /;
use File::Spec;
use Cwd ();
use MooseX::Singleton;

sub reset { shift->_clear_instance }

has Theme => (
    is         => 'rw',
    isa        => 'eleMentalClinic::Theme',
    lazy       => 1,
    default    => sub { eleMentalClinic::Theme->new },
);

has request => (
    is         => 'rw',
);

has config_path => (
    is         => 'rw',
    lazy       => 1,
    default    => sub {
        $_[0]->request && $_[0]->request->dir_config('config_path')
        ? $_[0]->request->dir_config('config_path')
        : $_[0]->defaults->config_file
    },
);

has db => (
    is         => 'ro',
    isa        => 'eleMentalClinic::DB',
    lazy       => 1,
    default    => sub { eleMentalClinic::DB->new },
);

has defaults => (
    is         => 'ro',
    isa        => 'eleMentalClinic::Config::Defaults',
    lazy       => 1,
    default    => sub { eleMentalClinic::Config::Defaults->new },
);

has stage1_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    predicate  => 'stage1_complete',
    clearer    => '_clear_stage1_data',
);

sub has_stage1 {
    my ( $name, %opt ) = @_;
    has $name => (
        is      => 'rw',
        lazy    => 1,
        default => sub { $_[0]->stage1_data->{$name} },
        clearer => "_clear_$name",
        %opt,
    );
}

sub stage1_attributes { qw/
    dbname dbtype dbuser passwd host port
    template_root log_conf_path
    theme revision
    edi_in_root edi_out_root pdf_out_root
    ecs_fieldlimits hcfa_fieldlimits
    ecs835_cf_file ecs835_yaml_file
    ecs997_cf_file ecs997_yaml_file
    ecsta1_cf_file ecsta1_yaml_file
    themes_dir fixtures_dir
    scanned_record_root scanned_record_url
    stored_record_root stored_record_url
    invalid_scanned_record_root report_config
    exception_log_path no_watchdog
/ }

has_stage1( $_ ) for __PACKAGE__->stage1_attributes;

has stage2_data => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    clearer    => '_clear_stage2_data',
);

after stage2_data => sub { shift->do_callbacks };

sub has_stage2 {
    my ( $name, %opt ) = @_;
    has $name => (
        is      => 'rw',
        lazy    => 1,
        default => sub { $_[0]->stage2_data->{$name} },
        clearer => "_clear_$name",
        %opt,
    );
}

sub stage2_attributes { qw/
    form_method
    logout_time logout_inactive
    edit_prognote prognote_min_duration_minutes prognote_max_duration_minutes
    prognote_bounce_grace org_name
    org_medicaid_provider_number org_medicare_provider_number
    org_tax_id org_street1 org_street2 org_city org_state org_zip
    org_national_provider_id org_taxonomy_code cp_credentials_expire_warning
    show_revision edi_contact_staff_id
    ohp_rolodex_id medicare_rolodex_id generalfund_rolodex_id
    medicaid_rolodex_id clinic_first_appointment clinic_last_appointment
    mime_type pdf_move_x pdf_move_y modem_port silent_modem
    tx_plan_period_default
    cpe_credentials_expire_warning
    send_mail_as
    appointment_template renewal_template
    default_mail_template
    renewal_notification_days appointment_notification_days
    password_expiration_days
    enable_role_reports
    quick_schedule_availability
    send_errors_to
/ }

has_stage2( $_ ) for __PACKAGE__->stage2_attributes;

__PACKAGE__->reset;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table  { 'config' }
    sub fields { [ qw/ rec_id dept_id name value /] }
    sub primary_key { 'rec_id' }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 Theme([ $theme ])

Object method.  Reloads the current L<eleMentalClinic::Theme> object.  Creates
and caches that object the first time it's called, and then returns the same
object on subsequent calls.  If C<$theme> is supplied it must be an
L<eleMentalClinic::Theme> object, and it is then cached and returned.  See also
C<reload_theme> in this package.

=head2 reload_theme([ $theme_name ])

Object method.  Reloads the current theme or, if C<$theme> is given, tries to
load the theme with that name.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub reload_theme {
    my $self = shift;
    my( $theme_name ) = @_;

    $self->theme( $theme_name )
        if $theme_name;
    return $self->Theme( eleMentalClinic::Theme->_new_instance );
}

sub stage1 {
    my ( $self, $arg ) = @_;
    $self->clear_stage1 if $arg->{force_reload};
    # force building to make tests happy; not really necessary
    $self->stage1_data;
    return $self;
}

sub clear_stage1 {
    my ($self) = @_;
    $self->$_ for map { "_clear_$_" } 'stage1_data', $self->stage1_attributes;
}

sub _build_stage1_data {
    my $self = shift;

    my $stage1_data;
    eval { $stage1_data = LoadFile( $self->config_path ) };
    die 'Cannot read config file ('. $self->config_path .") : $@"
        if $@;

    my %defaults = $self->defaults->stage1;

    do {
        defined $stage1_data->{$_} or $stage1_data->{$_} = $defaults{$_}
    } for keys %defaults;

    return $stage1_data;
}

sub stage2 { $_[0] }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# after database is initialized, read config from it
sub _build_stage2_data {
    my $self = shift;

    my $config_data = $self->db->select_many(
        $self->fields,
        $self->table,
        'WHERE dept_id = 1001',
        'ORDER BY value',
    );

    my %config = map { $_->{name} => $_->{value} } @$config_data;

    return {
        map { $_ => $config{$_} }
        grep {
            exists  $config{$_} &&
            defined $config{$_} &&
            # the old code used eMC attributes, which pretend that setting to
            # '' is the same as setting to undef, so exclude anything that is
            # an empty string here
            length  $config{$_}
        }
        $self->stage2_attributes
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 template_path()

Object method.  Returns the path to the templates for the active theme.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub template_path {
    my $self = shift;

    return File::Spec->catfile( $self->themes_dir, $self->theme, 'templates' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 default_template_path()

Object method.  Returns the path to the templates for the Default theme.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub default_template_path {
    my $self = shift;

    return File::Spec->catfile( $self->themes_dir, 'Default', 'templates' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    my( $vars ) = @_;

    return unless $vars;
    die 'Hashref required'
        unless UNIVERSAL::isa( $vars, 'HASH' );

    while( my( $key, $value ) = each %$vars ) {
        next unless grep /^$key$/ => $self->stage2_attributes;
        my $dept_id = 1001;
        $self->db->update_or_insert_one(
            table         => $self->table,
            update_fields => [ 'value' ],
            update_values => [ $value ],
            conditions    => "dept_id = "   . $self->db->dbh->quote( $dept_id )
                            ." AND name = " . $self->db->dbh->quote( $key ),
            insert_fields => [ 'name', 'dept_id' ],
            insert_values => [ $key, $dept_id ],
        );
    }
    $self->$_ for map { "_clear_$_" } 'stage2_data', $self->stage2_attributes;
    return $self;
}

=head2 Callbacks

Some classes require database information in order to complete their build
process. In such cases these classes should add a callback subroutine to the
config class. This sub will be called after stage1 is complete allowing the
objects to finish construction.

    eleMentalClinic::Config::add_callback( sub {} );

=cut

our @CALLBACKS;
sub add_callback {
    my $callback = shift;
    if ( __PACKAGE__->new->stage1_complete ) {
        $callback->();
    }
    else {
        push( @CALLBACKS, $callback );
    }
}

sub do_callbacks {
    my $self = shift;
    while ( my $c = shift( @CALLBACKS )) {
        $c->();
    }
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
