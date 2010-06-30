use strict;
use warnings;
use Module::Build;
use lib 'lib';
use eleMentalClinic;

my $class = Module::Build->subclass(code => <<'END');

use lib 'blib/lib';
use eleMentalClinic;

sub process_share_files {
  my ($self, $dir) = @_;
  # per File::ShareDir
  my $dist_share = "blib/lib/auto/share/dist/eleMentalClinic";
  my $share_files = $self->rscan_dir($dir, sub { -f $_ and ! m{/\.} });
  for my $file (@$share_files) {
    $self->copy_if_modified(
      from   => $file,
      to_dir => $dist_share,
    );
  }
}

sub process_themes_files   { shift->process_share_files('themes') }
sub process_fixtures_files { shift->process_share_files('fixtures') }
sub process_database_files { shift->process_share_files('database') }
sub process_etc_files      { shift->process_share_files('etc') }

sub ACTION_dev_setup {
  shift->do_system($^X, '-Ilib', 'script/elementalclinic_setup', '--dev')
    || die "elementalclinic_setup --dev failed\n";
}

sub ACTION_db_clean_dev {
  shift->do_system("make -C database import-or-dump")
    || die "import-or-dump failed\n";
}

sub ACTION_db_clean_dev_dump {
  my ($self) = @_;
  $self->depends_on('clean', 'db_clean_dev');
  $self->do_system("make -C database release-dump")
    || die "release-dump failed\n";
}

sub ACTION_db_clean_dev_test {
  shift->depends_on(qw(db_clean_dev test));
}

sub ACTION_db_testdata_jazz {
  my ($self) = @_;
  $self->depends_on('db_clean_dev');
  $self->do_system("$^X -Ilib script/elementalclinic_fixture_import -f fixtures/testdata-jazz")
    || die "fixture_import failed\n";
}

sub ACTION_db_connect {
  shift->do_system("make -C database dbconnect")
    || die "dbconnect failed\n";
}

my @build_depends = qw(clean manifest dist);

sub built_debs_ok {
  my ($self) = @_;
  print "Debian packages built under debs/\n";
}

sub ACTION_debs {
  my ($self) = @_;
  $self->depends_on(@build_depends);
  $self->do_system(
    "build_scripts/deps/debian", 
    "--archive", $self->dist_dir . '.tar.gz',
  ) || die "debs failed\n";
  $self->built_debs_ok;
}

sub ACTION_all_debs {
  my ($self) = @_;
  $self->add_to_cleanup(
    "debs/main/pool/*/e/*libelementalclinic-perl/*",
  );
  $self->depends_on(@build_depends);
  $self->do_system(
    "build_scripts/deps/debian",
    "--buildprereq",
    "--archive", $self->dist_dir . '.tar.gz',
  ) || die "all_debs failed\n";
  $self->built_debs_ok;
}

sub ACTION_installdebs {
  my ($self) = @_;
  $self->depends_on(@build_depends);
  $self->do_system(
    "build_scripts/deps/debian",
    '--install',
    '--archive', $self->dist_dir . '.tar.gz',
  ) || die "installdebs failed\n";
}

sub ACTION_installdeps {
  my ($self) = @_;
  $self->depends_on(@build_depends);
  $self->do_system(
    "build_scripts/deps/install",
    $self->dist_dir . '.tar.gz',
  ) || die "installdeps failed\n";
}

sub ACTION_deploy {
  my ($self) = @_;
  for (
    'mkdir -p "/usr/share/elementalclinic"',
    'mkdir -p "/usr/share/doc/elementalclinic"',
    'mkdir -p "/etc/elementalclinic/ecs"',
    'mkdir -p "/etc/elementalclinic/hcfa"',
    'cp -r "fixtures" "/usr/share/elementalclinic"',
    'cp "etc/startup.pl"  "/etc/elementalclinic/startup.pl"',
    'cp "etc/report.yaml" "/etc/elementalclinic/report.yaml"',
    'cp "etc/log.conf"    "/etc/elementalclinic/log.conf"',
    'cp -a etc/ecs/*      "/etc/elementalclinic/ecs"',
    'cp -a etc/hcfa/*     "/etc/elementalclinic/hcfa"',
    'ln -s "/etc/elementalclinic/config.yaml" "./config.yaml"',
  ) {
      $self->do_system( $_ ) || die "deploy failed\n";
  }
}

my @aliases;
# backwards compat names for Makefile stuff
for my $action (qw(
  db_clean_dev
  db_clean_dev_dump
  db_clean_dev_test
  db_testdata_jazz
  db_connect
  all_debs
  dev_setup
)) {
  (my $alias = $action) =~ tr/_/-/;
  no strict 'refs';
  *{"ACTION_$alias"} = __PACKAGE__->can("ACTION_$action");
  push @aliases, $alias;
}

sub known_actions {
  my $actions = shift->SUPER::known_actions;
  $actions->{$_}++ for @aliases;
  return wantarray ? (sort keys %$actions) : $actions;
}

sub process_localstate_files {
  my $self = shift;
  local @INC = ("blib/arch", "blib/lib", "lib", @INC);
  require eleMentalClinic::Config::Defaults;
  my $config = eleMentalClinic::Config::Defaults->new(
    root => Path::Class::Dir->new('blib'),
  );
  my %d = $config->stage1;
  for (qw(exception_log_path edi_out_root edi_in_root pdf_out_root)) {
    $d{$_}->mkpath;
  }
}

END

my $r = {
  'configure_requires' => {
    'Module::Build' => 0,
  },
  'test_requires' => {
    'Test::More' => 0,
    'Object::Quick' => 0,
    'Getopt::Long' => 0,
    'Test::Warn' => 0,
    'Test::Exception' => 0,
    'HTML::TreeBuilder' => 0,
    'Test::Deep' => 0,
    'Test::WWW::Mechanize' => 0,
    'String::Diff' => 0,
    'WWW::Selenium' => 0,
    'Class::MOP' => 0,
    'HTML::Entities' => 0,
    'Test::LongString' => 0,
    'Test::WWW::Selenium' => 0,
  },
  'requires' => {
    'CGI::Carp' => 0,
    'CGI::Session' => '4.0',
    'CGI::ValidOp' => '0.56',
    'Catalyst::Controller::WrapCGI' => '0.0026',
    'Catalyst::Engine::Apache' => 0,
    'Catalyst::Plugin::Static::Simple' => '0.20',
    'Catalyst::Runtime'  => '5.71001',
    'Class::Accessor::Fast' => 0,
    'Class::C3::Adopt::NEXT' => '0.05', # -no_warn
    'DBD::Pg' => 0,
    'DBI' => 0,
    'Data::Transformer' => 0,
    'Date::Calc' => 0,
    'Date::Manip' => 0,
    'Devel::StackTrace' => 0,
    'Device::Modem' => 0,
    'Digest::SHA' => 0,
    'File::Path' => 0,
    'File::ShareDir' => 0,
    'HTTP::Date' => 0,
    'JSON' => '2.00', # 1.x API is a pain
    'List::MoreUtils' => 0,
    'Log::Dispatch' => 0,
    'Log::Dispatch::FileRotate' => 0,
    'Log::Log4perl' => 0,
    'MRO::Compat' => 0,
    'Moose' => '0.65',
    'MooseX::ClassAttribute' => '0.08',
    'MooseX::Getopt' => '0.18',
    'MooseX::Role::Parameterized' => '0.06',
    'MooseX::Singleton' => '0.17',
    'MooseX::Types'  => '0.10',
    'MooseX::Types::Structured' => '0.13',
    'Net::SFTP::Foreign' => '1.36', # password auth
    'PDF::Reuse' => 0,
    'Package::Watchdog' => 0.08,
    'Path::Class' => 0,
    'Pod::Usage' => 0,
    'Sub::Exporter' => 0,
    'Sub::Name' => 0,
    'Template' => '2.10',
    'Time::HiRes' => 0,
    'URI' => 0,
    'URI::QueryParam' => 0,
    'X12::Parser' => '0.80',
    'YAML::Syck' => 0,
    'namespace::autoclean' => 0,
    'namespace::clean' => 0,
  }
};

my $build = $class->new(
  module_name => 'eleMentalClinic',
  license     => 'perl',
  script_files => 'script',
  meta_add => {
    configure_requires => $r->{configure_requires} || {},
  },
  build_requires => {
    %{ $r->{test_requires}  || {} },
    %{ $r->{build_requires} || {} },
  },
  requires => $r->{requires} || {},
  recursive_test_files => 1,
  create_makefile_pl => 'passthrough',
);
$build->add_build_element($_) for qw(themes fixtures database etc localstate);
$build->add_to_cleanup(
  'database/release/*.sql',
  'fixtures/*/*.compiled',
  'eleMentalClinic-*',
  'MANIFEST',
);
$build->create_build_script;
