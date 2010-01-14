package eleMentalClinic::App::Setup;

use Moose;
with 'MooseX::Getopt';
use eleMentalClinic::Config::Defaults;
use File::Path;
use File::Find;
use File::Spec;
use IO::File;
use YAML::Syck;
use Cwd;

has dev => (
  is          => 'ro',
  isa         => 'Bool',
);

has dry_run  => (
  is          => 'ro',
  isa         => 'Bool',
  traits      => [ 'Getopt' ],
  cmd_flag    => 'dry-run',
  cmd_aliases => 'n',
);

has verbose => (
  is          => 'ro',
  isa         => 'Bool',
  traits      => [ 'Getopt' ],
  cmd_aliases => 'v',
);

has destdir => (
  is        => 'ro',
  isa       => 'Str',
  lazy      => 1,
  default   => sub { $_[0]->dev ? Cwd::cwd : '' },
);

has www_user => (
  is          => 'ro',
  isa         => 'Str',
  traits      => [ 'Getopt' ],
  cmd_flag    => 'www-user',
  cmd_aliases => 'U',
  ($< == 0)
  ? (required => 1)
  : (default  => scalar getpwuid($<)),
);

has www_group => (
  is          => 'ro',
  isa         => 'Str',
  traits      => [ 'Getopt' ],
  cmd_flag    => 'www-group',
  cmd_aliases => 'G',
  lazy        => 1,
  default     => sub { scalar getgrgid((getpwnam($_[0]->www_user))[3]) },
);

my %default = eleMentalClinic::Config::Defaults->new->stage1;

my %db = (
  user => 'dbuser',
  pass => 'passwd',
  host => 'host',
  port => 'port',
  name => 'dbname',
);

my @db_keys = qw(name host port user pass);

sub _prompt {
  my ($text, $valid) = @_;
  my $value;
  do {
    print "$text ";
    chomp($value = <STDIN>);
  } until ($valid->($value));
  return $value;
}

my %prompt = (
  user => sub {
    _prompt(
      "Database user name (default: elementalclinic):",
      sub { $_[0] ||= 'elementalclinic' },
    )
  },
  pass => sub {
    _prompt(
      "Database user password (default: ''):",
      sub { 1 },
    )
  },
);

for my $key (@db_keys) {
  my $default_val = $default{$db{$key}};
  my $default_sub;
  if (defined $default_val) {
    $default_sub = sub { $default_val };
  } else {
    $default_sub = $prompt{$key} || die "Don't have a prompt for $key!";
  }
  has "db_$key" => (
    is          => 'ro',
    isa         => 'Str',
    traits      => [ 'Getopt' ],
    cmd_flag    => "db-$key",
    lazy        => 1,
    default     => $default_sub,
  );
}

sub files_under {
  my ($dir, $filter) = @_;
  $filter ||= sub { 1 };
  my @files;
  File::Find::find(
    sub {
      push @files, substr($File::Find::name, length("$dir"))
        if $filter->($File::Find::name);
    },
    $dir,
  );
  return @files;
}

sub path_to {
  my ($self, $path) = @_;
  return File::Spec->rel2abs(
    File::Spec->canonpath(($self->destdir || '') . '/' . $path)
  );
}

sub _cmd {  
  my ($self, $cmd, @args) = @_;
  (my $printcmd = $cmd) =~ tr/_/-/;
  $printcmd =~ s/^-//;
  print STDERR ">>> $printcmd @args\n" if $self->verbose or $self->dry_run;
  return if $self->dry_run;
  $self->${\"_cmd_$cmd"}(@args);
}

sub _cmd_mkdir {
  my ($self, $path) = @_;
  return if -d $path;
  File::Path::mkpath($path) or die "Can't create $path: $!";
}

sub _cmd_chown {
  my ($self, $uid, $gid, @files) = @_;
  return unless @files;
  $uid = getpwnam($uid) if $uid =~ /\D/;
  $gid = getgrnam($gid) if $gid =~ /\D/;
  chown $uid, $gid, @files or die "Can't chown $uid:$gid @files: $!";
}

sub _cmd_dump {
  my ($self, $file, $data) = @_;
  YAML::Syck::DumpFile($file, $data);
}

sub _mkdir { shift->_cmd(mkdir => @_) }

sub _chown { shift->_cmd(chown => @_) }

sub _dump { shift->_cmd(dump => @_) }

sub run {
  my ($self) = @_;

  my $spool_dir = $self->path_to(
    $self->dev
    ? 'var/spool'
    : '/var/spool/elementalclinic'
  );
  my $log_dir   = $self->path_to(
    $self->dev
    ? 'var/log'
    : '/var/log/elementalclinic'
  );
  my $etc_dir   = $self->path_to(
    $self->dev
    ? '.'
    : '/etc/elementalclinic'
  );
  
  my @dirs = (
    (map { File::Spec->catdir($spool_dir, $_) }
      qw(edi_in edi_out pdf_out)
    ),
    File::Spec->catdir($log_dir, 'exceptions'),
    $etc_dir,
  );

  $self->_mkdir($_) for @dirs;
  $self->_chown(
    $self->www_user, $self->www_group,
    map {
      my $dir = $_;
      map { File::Spec->canonpath(File::Spec->catfile($dir, $_)) }
        files_under($dir)
    } $log_dir, $spool_dir,
  );

  my $config = IO::File->new("$etc_dir/config.yaml", "w")
    or die "Can't open $etc_dir/config.yaml: $!";

  $self->_dump(
    $config,
    { map {; $db{$_} => $self->${\"db_$_"} } @db_keys },
  );
}

1;
