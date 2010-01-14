package eleMentalClinic::Config::Defaults;

use Moose;
use eleMentalClinic;
use File::ShareDir;
use Path::Class;
use namespace::autoclean;

has root => (
  is      => 'ro',
  isa     => 'Path::Class::Dir',
  default => sub {
    file(__FILE__)->parent->parent->parent->parent->absolute
  },
);

sub in_checkout {
  -e $_[0]->root->file('Build.PL') ? 1 : 0;
}

sub in_blib {
  $_[0]->root->dir_list(-1) eq 'blib' ? 1 : 0;
}

sub share_root {
  my ($self) = @_;
  $self->in_checkout
  ? $self->root
  : dir(File::ShareDir::dist_dir('eleMentalClinic'))->absolute;
}

sub var_root {
  my ($self) = @_;
  $self->in_checkout || $self->in_blib
  ? $self->root->subdir('var')
  : dir('/var')
}

sub etc_root {
  my ($self) = @_;
  $self->in_checkout
  ? $self->root->subdir('etc')
  : $self->share_root->subdir('etc');
}

sub share_path {
  my $self = shift;
  return $self->share_root->subdir(@_);
}

sub var_path {
  my $self = shift;
  return $self->var_root->subdir(@_);
}

sub _add_name {
  my $self = shift;
  return @_ if $self->in_blib || $self->in_checkout;
  return 'elementalclinic', @_;
}

sub log_path {
  my $self = shift;
  return $self->var_path(log => $self->_add_name(@_));
}

sub spool_path {
  my $self = shift;
  return $self->var_path(spool => $self->_add_name(@_));
}

sub etc_file {
  my $self = shift;
  return $self->etc_root->file(@_);
}

# defaults for stage1 config
# in a checkout
#   $checkout/etc for bundled config files
#   $checkout/var for logs and storage
#   $checkout for config.yaml
# in blib
#   $blib/share/etc for bundled config files
#   $blib/var for logs and storage
#   $blib/share/etc for config.yaml
#     get database information from %ENV first
#     copy from $checkout
# in dist
#   same as checkout
#   DO NOT include $checkout/config.yaml (MANIFEST.SKIP)
# in dist/blib
#   same as blib
# installed
#   @INC/share/etc for bundled config files
#   /var for logs and storage
#   /etc/elementalclinic for config file

sub stage1 {
  my $self = shift;
  return (
    theme              => 'Default',

    dbtype             => 'postgres',
    dbname             => $ENV{ELEMENTALCLINIC_DB_NAME} || 'elementalclinic',
    host               => $ENV{ELEMENTALCLINIC_DB_HOST} || 'localhost',
    port               => $ENV{ELEMENTALCLINIC_DB_PORT} || 5432,
    dbuser             => $ENV{ELEMENTALCLINIC_DB_USER},
    passwd             => $ENV{ELEMENTALCLINIC_DB_PASS},

    themes_dir         => $self->share_path(qw(themes)),
    fixtures_dir       => $self->share_path(qw(fixtures)),
    exception_log_path => $self->log_path(qw(exceptions)),
    edi_out_root       => $self->spool_path(qw(edi_out)),
    edi_in_root        => $self->spool_path(qw(edi_in)),
    pdf_out_root       => $self->spool_path(qw(pdf_out)),
    log_conf_path      => $self->etc_file(qw(log.conf)),
    report_config      => $self->etc_file(qw(report.yaml)),
    ecs_fieldlimits    => $self->etc_file(qw(ecs fieldlimits_837.yaml)),
    hcfa_fieldlimits   => $self->etc_file(qw(hcfa fieldlimits_hcfa.yaml)),
    ecs835_cf_file     => $self->etc_file(qw(ecs 835_004010X091.cf)),
    ecs835_yaml_file   => $self->etc_file(qw(ecs read_835.yaml)),
    ecs997_cf_file     => $self->etc_file(qw(ecs 997.cf)),
    ecs997_yaml_file   => $self->etc_file(qw(ecs read_997.yaml)),
    ecsta1_cf_file     => $self->etc_file(qw(ecs ta1.cf)),
    ecsta1_yaml_file   => $self->etc_file(qw(ecs read_ta1.yaml)),

    revision           => eleMentalClinic->VERSION,
  );
}

sub config_file {
  my $self = shift;
  return file($ENV{ELEMENTALCLINIC_CONFIG})
    if $ENV{ELEMENTALCLINIC_CONFIG};
  $self->in_checkout
  ? $self->root->file('config.yaml')
  : $self->in_blib
  ? (
    # blib is special -- use the local one if it's there or the bundled one
    # otherwise; this means that we'll throw errors about bad database info
    # rather than "can't find config file"
    grep { -e $_ }
      $self->root->parent->file('config.yaml'),
      $self->etc_file('config.yaml')
  )[0]
  : file('/etc/elementalclinic/config.yaml')
}

__PACKAGE__->meta->make_immutable;
1;
