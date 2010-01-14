# vim: ts=4 sts=4 sw=4

use strict;
use warnings;
use Test::More tests => 6;
use File::Temp qw(tempdir);
use Path::Class;
use eleMentalClinic::Config::Defaults;

sub config_ok {
    my ($c, $want, $label) = @_;
    is_deeply(
        { map { $_, $c->$_ } keys %$want },
        $want,
        $label,
    );
}

my %dir =
  ( map { $_ => dir( tempdir( CLEANUP => 1 ) ) } qw(checkout installed) );

my $share = 'auto/share/dist/eleMentalClinic';

$dir{checkout}->file('Build.PL')->touch;
$dir{checkout}->file('config.yaml')->touch;
$dir{checkout}->subdir('etc')->mkpath;
$dir{checkout}->subdir("blib/arch/$share/etc")->mkpath;
$dir{checkout}->file("blib/arch/$share/etc/config.yaml")->touch;

$dir{installed}->subdir("lib/$share")->mkpath;

{
    my $c = eleMentalClinic::Config::Defaults->new( root => $dir{checkout} );
    my $have = { $c->stage1 };
    my $want = {
        dbtype      => 'postgres',
        theme       => 'Default',
        dbname      => 'elementalclinic',
        dbuser      => undef,
        passwd      => undef,
        host        => 'localhost',
        port        => 5432,
    };
    is_deeply(
        { map { $_, $have->{$_} } keys %$want },
        $want,
        "default defaults",
    );

    my %env = (
        ELEMENTALCLINIC_DB_NAME => 'emc',
        ELEMENTALCLINIC_DB_HOST => 'emc-host',
        ELEMENTALCLINIC_DB_PORT => '12345',
        ELEMENTALCLINIC_DB_USER => 'emc-user',
        ELEMENTALCLINIC_DB_PASS => 'emc-pass',
    );

    local %ENV = (%ENV, %env);
    $have = { $c->stage1 };
    is_deeply(
        { map { $_, $have->{$_} } keys %$want },
        {
            %$want,
            dbname => 'emc',
            host   => 'emc-host',
            port   => 12345,
            dbuser => 'emc-user',
            passwd => 'emc-pass',
        },
        "defaults with env overrides",
    );
}

{
    my $c = eleMentalClinic::Config::Defaults->new( root => $dir{checkout} );
    config_ok(
        $c,
        {
            in_checkout => 1,
            in_blib     => 0,
            config_file => $dir{checkout}->file('config.yaml'),
            log_path    => $dir{checkout}->subdir('var/log'),
        },
        'checkout',
    );
}

{
    local @INC = ( $dir{checkout}->subdir('blib/arch')->stringify, @INC );
    my $c = eleMentalClinic::Config::Defaults->new(
        root => $dir{checkout}->subdir('blib'),
    );
    config_ok(
        $c,
        {
            in_checkout => 0,
            in_blib     => 1,
            config_file => $dir{checkout}->file('config.yaml'),
            log_path    => $dir{checkout}->subdir('blib/var/log'),
        },
        "blib",
    );
    $dir{checkout}->file('config.yaml')->remove;
    config_ok(
        $c,
        {
            config_file =>
                $dir{checkout}->file("blib/arch/$share/etc/config.yaml"),
        },
        "blib (fallback config file)",
    );
}

{
    my $c = eleMentalClinic::Config::Defaults->new( root => $dir{installed} );
    config_ok(
        $c,
        {
            in_checkout => 0,
            in_blib     => 0,
            config_file => '/etc/elementalclinic/config.yaml',
            log_path    => '/var/log/elementalclinic',
        },
        "installed",
    );
}
