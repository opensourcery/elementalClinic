#!/usr/bin/perl 

#
# Create a new theme
#
# usage: $0 <theme_name> <optional theme directory>
#
# Note: run this from the root of the tree, not bin/, if you plan to not
# provide a themes dir.
#

use strict;
use warnings;

use constant DIRS => qw(controllers res util templates);

my $THEME_NAME = $ARGV[0];
my $THEME_DIR = $ARGV[1] || "themes";

chdir $THEME_DIR;
mkdir $THEME_NAME;
chdir $THEME_NAME;

foreach my $dir (DIRS) {
    mkdir $dir
}

open(FILE, ">theme.yaml") || die "Could not open theme.yaml for writing: $!";
print FILE <<"EOF";
---
name: $THEME_NAME
description: 
allowed_controllers:
EOF

close(FILE);
