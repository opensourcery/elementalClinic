# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Server::Apache;

use Moose;
use MooseX::Types::Moose qw(:all);
use eleMentalClinic::Config;
use Path::Class;
use File::Spec;
use File::Temp;
use YAML::Syck;
use Cwd;
use Carp;
use namespace::autoclean;

my $config = eleMentalClinic::Config->new;

has httpd_conf => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        $config->defaults->etc_file('emc.httpd.conf')->stringify
    },
);

has config => (
    is      => 'ro',
    isa     => HashRef[Str],
    default => sub { {} },
);

has port => (
    is      => 'ro',
    isa     => Int,
    default => 8000,
);

has test_data => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has tmpdir => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => "/tmp",
);

has config_file => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub { File::Temp->new },
);

has stopped => (
    is => 'rw',
    isa     => Int,
    default => 0,
);

sub pid_file {
    my ($self) = @_;
    dir($_[0]->tmpdir)->file("httpd." . $_[0]->port . ".pid");
}

sub start {
    my ($self) = @_;

    $self->stop;
    $self->stopped( 0 );
    if (-e $self->pid_file) {
        unlink $self->pid_file;
    }

    my @cmd = ($^X, qw(bin/start_httpd -n));
    push @cmd, '--test' if $self->test_data;
    push @cmd, '--template', $self->httpd_conf;

    my %defaults = %{$config->stage1_data};
    $_ .= "" for values %defaults; # stringify Path::Classes

    YAML::Syck::DumpFile(
        $self->config_file,
        {
            %defaults,
            %{ $self->config },
        },
    );

    push @cmd, '--config', "" . $self->config_file;
    push @cmd, '--port', $self->port;
    push @cmd, cwd;
    if (system(@cmd)) {
        croak "Could not start apache:\n  @cmd\nsee error log for details";
    }
    my $i = 0;
    while (! -e $self->pid_file) {
        croak "Apache pid file @{[ $self->pid_file ]} does not exist after $i tries, giving up"
            if $i++ > 30;
        sleep 1;
    }
}

sub stop {
    my ($self) = @_;
    return if $self->stopped;

    return unless -e $self->pid_file;
    my @cmd = (qw(sh bin/kill_httpd --quiet), $self->port);
    if (system(@cmd)) {
        warn "Could not kill httpd on ${\$self->port}: not running?";
    }
    $self->stopped( 1 ) unless -e $self->pid_file;
}

sub DEMOLISH {
    my ($self) = @_;
    $self->stop;
}

__PACKAGE__->meta->make_immutable;
1;
