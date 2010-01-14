# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Test::Selenium;

use base qw(Test::WWW::Selenium);
use strict;
use warnings;

use eleMentalClinic::Test ();
use HTML::TreeBuilder;
use Encode ();

sub new_with_server {
    my $class = shift;
    my ( %arg ) = @_;

    my $server_arg = delete $arg{server} || {};

    my $bin = qx(which xvfb-run 2>/dev/null);
    chomp $bin if $bin;

    my $pid = fork or do {
        my @cmd = qw( java -jar vendor/selenium/selenium-server.jar -port 4444 );
        unshift @cmd, ($bin, '-a') if $bin and not $ENV{EMC_NO_XVFB};
        exec @cmd;
    };
    my $port = eleMentalClinic::Test::start_server(
        undef, $server_arg,
    );
    my $self = $class->SUPER::new(
        host => 'localhost',
        port => 4444,
        browser => '*chrome',
        browser_url => "http://localhost:$port/",
        @_,
    );
    $self->{emc_port} = $port;
    $self->{server_pid} = $pid;
    $self->set_timeout(120_000);
    return $self;
}

sub DESTROY {
    my $self = shift;
    local( $@, $? );
    eleMentalClinic::Test::stop_server($self->{emc_port})
        if $self->{emc_port};
    # XXX these both mean that this kind of test is non-parallelizable (for
    # now)
    do {
        system("pkill -f Xvfb");
        system("pkill -f 'java -jar vendor/selenium/selenium-server.jar -port 4444'");
    } if $self->{server_pid};
}

sub run_file {
    my $self = shift;
    my ( $file ) = @_;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($file);

    my $tbody = $tree->look_down(_tag => 'tbody');

    for my $step ($tbody->look_down(_tag => 'tr')) {
        my ($method, @args) = map { $_->content_list }
            $step->look_down(_tag => 'td');
        warn ">>> $method (@args)\n";
        $method = $self->command_to_method( $method );
        my $wait = $method =~ s/_and_wait$//;
        $method .= "_ok";
        warn ">>> $method (@args)\n";
        $self->$method(map { Encode::decode('UTF-8', $_) } @args);
        $self->wait_for_page_to_load( 30_000 ) if $wait;
    }
}

sub command_to_method {
    my $self = shift;
    my ( $command ) = @_;
    my $method = lc(join('_', split /(?<=[a-z])(?=[A-Z])/, $command));
    return $method;
}

sub admin_login {
    my $self = shift;

    $self->open('/login.cgi');
    $self->type(login => 'clinic');
    $self->type(password => 'dba');
    $self->click('//input[@value="Login"]');
    $self->wait_for_page_to_load( 30_000 );
}

1;
