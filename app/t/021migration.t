# vim: ts=4 sts=4 sw=4
use strict;
use warnings;
use Test::More 'no_plan';

use File::Temp qw(tempdir);
use eleMentalClinic::DB::Migration;

my $m = eleMentalClinic::DB::Migration->new;

my $dir = tempdir(CLEANUP => 1);

my @files = qw(
    10.sql
    10.z.sql.upgrade
    20.sql
    10.sql.down
    20.sql.down
);
for my $file (@files) {
    open my $fh, '>', "$dir/$file" or die "Can't open $dir/$file: $!";
}

my $get_up = sub {
    $m->migration_files(
        dir => $dir,
        up => 1,
        from_version => 0,
        to_version => 9999,
        tag => [ '' ],
        @_,
    );
};

my $get_down = sub {
    $m->migration_files(
        dir => $dir,
        up => 0,
        from_version => 9999,
        to_version => 0,
        tag => [ 'down' ],
        @_,
    );
};

is_deeply(
    [ map { $_->[1] } $get_up->() ],
    [ map { "$dir/$_" } grep { /sql$/ } @files ],
    'simple case: migrate up, no extra tag',
);

is_deeply(
    [ map { $_->[1] } $get_up->(tag => [ '', 'upgrade' ]) ],
    [ map { "$dir/$_" } grep { /sql(\.upgrade)?$/ } @files ],
    'migrate up, extra tag',
);

is_deeply(
    [ map { $_->[1] } $get_down->() ],
    [ map { "$dir/$_" } grep { /down$/ } reverse @files ],
    'migrate down',
);
