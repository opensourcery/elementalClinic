# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

package eleMentalClinic::FixtureLoader;

use YAML::Syck;
use Test::Deep::NoTest;

sub new {
    my $class = shift;
    my ( $dir ) = @_;
    bless { dir => $dir } => $class;
}

sub match {
    my $self = shift;
    my ( $data, $query ) = @_;
    for my $key ( keys %$query ) {
        return unless exists $data->{$key}
            and eq_deeply( $data->{$key}, $query->{$key} );
    }
    return 1;
}

sub find {
    my $self = shift;
    my ( $table, $query ) = @_;

    $query ||= {};
    
    my $data = YAML::Syck::LoadFile(
        'fixtures/' . $self->{dir} . "/$table.yaml",
    );

    my @result;

    for my $id (keys %$data) {
        my $d = { KEY => $id, %{ $data->{$id} } };
        push @result, $d if $self->match($d, $query);
    }

    return @result;
}

sub find_one {
    my $self = shift;
    my @result = $self->find(@_);
    die "did not find exactly one result for query:" . YAML::Syck::Dump(\@_)
        unless @result == 1;
    return $result[0];
}

sub random {
    my $self = shift;
    my ( $table ) = @_;
    my @rows = $self->find( $table, {} );
    return $rows[rand @rows];
}

1;
