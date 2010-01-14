use Module::Build;

use strict;

my $build = Module::Build->new(
    module_name => 'Algorithm::C3',
    license => 'perl',
    requires => {
        'Carp' => '0.01',
    },
    optional => {},
    build_requires => {
        'Test::More' => '0.47',
    },
    recursive_test_files => 1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL',
    ],
    create_makefile_pl => 'small',
);

$build->create_build_script;
#write_makefile();
