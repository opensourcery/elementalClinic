# vim: ts=4 sts=4 sw=4

package eleMentalClinic::Theme;

=head1 NAME

eleMentalClinic::Theme

=head1 SYNOPSIS

Root-level Theme management class.

=head1 METHODS

=cut

use strict;
use warnings;

use eleMentalClinic::Config;
use YAML::Syck qw(LoadFile);
use Carp qw(croak);
use File::Spec;

use base qw(eleMentalClinic::Base eleMentalClinic::Singleton);

use constant MODULES => qw(Access);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 theme_config_methods()

Function.  Returns list of methods created for and from properties in the
theme.yaml config file.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub theme_config_methods {[ qw/
    name description theme_index
    allowed_controllers allowed_reports
    open_schedule
/]}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub methods {
    [
        qw/ modules /,
        @{ theme_config_methods() },
    ]
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
    my $self = shift;
    return $self->instance(@_);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 _new_instance

Our singleton new()

=cut

sub _new_instance {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless { }, $class;
    $self->init( @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 init()

Object method.  Our init routine. Gets our theme from the config, parses
theme.yaml and initializes our rights modules. 

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub init {
    my $self = shift;
    my ( $args, $options ) = @_;

    $self->SUPER::init( $args, $options );

    my $theme_config = $self->load_config(
        $args->{name} || $self->config->theme
    );
    for my $property( @{ theme_config_methods()}) {
        $self->$property( $theme_config->{ $property });
    }

    # build out the modules from our constant and obtain configuration objects for each of them.
    my @modules;
    for my $module( MODULES ) {
        my $package = "eleMentalClinic::Theme::$module";
        eval "require $package";
        push @modules => $package->new( $self );
    }
    $self->modules( \@modules );

    return $self;
}

=head2 theme_named

    my $theme = eleMentalClinic::Theme->load_theme($theme_name);

Load a specific theme, regardless of other loaded themes; used for testing.

=cut

sub load_theme {
    my $class = shift;
    my ( $name ) = @_;
    return $class->_new_instance({ name => $name });
}

=head2 load_config

    my $config = eleMentalClinic::Theme->load_config($theme_name);

Load a specific theme's config by name.

=cut

sub load_config {
    my $class = shift;
    my ( $name ) = @_;

    if (!$class->config->themes_dir ||
        ! -e $class->config->themes_dir ||
        ! -d $class->config->themes_dir ) {
        croak "themes_dir must exist (and point to the right spot) in config.yaml for serving to continue."
    }

    my $theme_config_file = File::Spec->catfile(
        $class->config->themes_dir, $name, 'theme.yaml'
    );

    croak "Theme configuration '$theme_config_file' does not exist\n"
        unless -f $theme_config_file;

    return YAML::Syck::LoadFile( $theme_config_file );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 controller_can($controller)

The magic happens here. Given a controller, The themes modules will be iterated
over deteremining whether or not this controller is allowed.

The controller will be required (and returned) if it is allowed. In the case
that the controller from the theme does not exist, if will attempt to require
the controller from the 'Default' theme. Returns the controller package
required if the controller is allowed, 0 if not.
=cut
sub controller_can {
    my ($self, $controller) = @_;

    foreach my $module_obj (@{$self->modules}) {
        return 0 unless $module_obj->controller_can($controller);
    }

    # XXX these changes to $SIG{__DIE__} really shouldn't be necessary, but
    # DispatchUtil's die handler makes a ton of noise otherwise; ideally, we
    # wouldn't use $SIG{__DIE__} at all, and this would be unnecessary.

    my $controller_class = sprintf(
        "eleMentalClinic::Controller::%s::%s",
        $self->name, $controller,
    );
    unless (eval "local \$SIG{__DIE__}; require $controller_class; 1") {
        my $e = $@;
        my $controller_file = File::Spec->catfile(
            split /::/, "$controller_class.pm"
        );
        die $e unless
            $e =~ /^Can't locate \Q$controller_file\E in \@INC/;

        $controller_class = "eleMentalClinic::Controller::Base::$controller";

        die $@ unless
            eval "local \$SIG{__DIE__}; require $controller_class; 1";
    }

    return $controller_class;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 resource_path

Returns the resource path. If given a filename, will cascade to the default
theme trying to find the file in the resource path, returning the first one
that it finds. Undef is returned in this situation.

If no filename is provided, will return the resource path.

=cut
sub resource_path {
    my $self = shift;

    my ($file) = @_;

    my $resource_path = join("/", $self->config->themes_dir, $self->config->theme, "res");

    return $resource_path unless $file;

    my $full_path = join("/", $resource_path, $file);

    return $full_path if (-f $full_path);

    $full_path = join("/", $self->config->themes_dir, "Default", "res", $file);

    return $full_path if (-f $full_path);

    return undef;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 available_reports

    my $array_ref = $theme->available_reports($report_track);

Returns the list of report names available for the current theme.
Report names match the C<name> attributes of hashrefs from
L<eleMentalClinic::Report>'s C<site_report> and C<client_report>
methods.

The C<$report_track> argument should be one of C<client> or C<site>.

=cut

sub available_reports {
    my $self = shift;
    my ($report_track) = @_;
    $self->{available_reports} ||= $self->_find_available_reports;
    die "invalid report track '$report_track'"
        unless exists $self->{ available_reports }->{ $report_track };
    return $self->{ available_reports }->{ $report_track };
}

sub _find_available_reports {
    my $self = shift;
    my %config_available = map { $_ => 1 } @{ $self->_report_config };
    my %report;
    for my $r (@{ $self->allowed_reports }) {
        my ($track, $name) = split m{/}, $r, 2;
        push @{ $report{$track} ||= [] }, $name;
    }
    for (keys %report) {
        @{ $report{$_} } = sort grep {
            $config_available{$_}
        } @{ $report{$_} };
    }
    return \%report;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 _load_report_config()

Object method.  Tries to load list of available reports from
Config->report_config.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub _load_report_config {
    my $self = shift;
    my $report_config;
    eval { $report_config = LoadFile( $self->config->report_config )};
    croak "Cannot read report config ($@)" if $@;
    return $report_config;
}

sub _report_config {
    my $self = shift;
    my ( $list ) = @_;
    $self->{ report_config } = $list if $list;
    $self->{ report_config } ||= $self->_load_report_config;
    return $self->{ report_config };
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

=item Erik Hollensbe L<erikh@opensourcery.com>

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
