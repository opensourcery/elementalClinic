# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

package eleMentalClinic::TestCase;

use eleMentalClinic::FixtureLoader;

sub new {
    my $class = shift;
    bless {@_} => $class;
}

sub default_fixture { 'testdata-jazz' }

sub fixture {
    my $self = shift;
    my ( $dir ) = @_;
    $dir ||= $self->default_fixture;
    return eleMentalClinic::FixtureLoader->new($dir);
}

sub default_mech_class { 'eleMentalClinic::Test::Mechanize' }

sub mech {
    my $self = shift;
    my $class = ref($self) || $self;
    my @caller = caller;
    my $mech_class = (
        ($caller[1] =~ m{t/theme/([^/]+)/})[0] ||
        ($class =~ m{^theme::([^:]+)})[0] 
    );
    $mech_class = $mech_class
        ? "$mech_class\::Mechanize"
        : $self->default_mech_class;
    eval "require $mech_class";
    die $@ if $@ and $@ !~ /Can't find.+in \@INC/;
    return $mech_class->new_with_server(@_);
}

1;
