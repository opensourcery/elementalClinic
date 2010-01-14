package Debian::Package::Builder;
use strict;
use warnings;

=pod

=head1 NAME

Debian::Package::Builder - Class to build debian packages out of dist dirs.

=head1 DESCRIPTION

If you havn't already then please look at dh_make_perl, Module::Build::Debian,
and CPANPLUS::Dist::Deb. Those utilities and modules are older, and work for
most cases and people. This module is meant to build packages for a much more
specific use case.

The main issues with perl and debian packaging are dependancy related. This
module attempts to use as few non-core dependencies as possible. Currently
there are no non-core deps.

I started writing this module after experiencing nothing but pain from the
afore mentioned utilites and modules. Modifying the existing tools to do what I
needed, and work on the systems I was not practical. If you think this is a
mistake and that I should have spent my time improving the existing tools then
you are free to protest by not using my module, I assure you I will be plenty
wounded and there will be no further action needed on your part.

=head1 USE CASE

The use case that prompted this module was an application that we needed 3
packages for. We needed a libs package for all the perl libs, and app package
for the main app that uses the libs, and a package that fullfilled the
dependencies.

This application requires about 30 modules that do not currently have debian
packages of sufficient version. Each of these modules in turn depends on more.
At first we tried using each of the existing tools to create packages for all
the dependencies, plus the applications lib package.

CPANPLUS::Dist::Deb was noteworthy as it initially did an excellent job.
Packages were build for all our dependencies. The issues with
CPANPLUS::Dist::Deb were that it was difficult to install on some ubuntu
machines, and that if a package was rebuilt it would not play nicely in a repo.
In the end CPANPLUS::Dist::Deb is a simple utility to quickly make a package
for a module, it does not provide the needeed control.

dh_make_perl could not (at the time) work with modules that use Module::Build.
Using it to maintain 30+ dpeendencies is also not practical.
Module::Build::Debian is only for modules that use Module::Build.

Debian::Package::Builder works by creating package specific build directories
that define a simple build.pm file. The build.pm file specifies how a folder
should be created for building that specific package. debuild will be run once
the folder is created.

=head1 SYNOPSIS

    PackageA/build.pm
    PackageB/build.pm

=head1 EXPORTED FUNCTIONS

=over 4

=cut

use base 'Exporter';

our @EXPORT = qw/ add_package build_packages param parse_params find_dists /;

our %PACKAGES;
our %PARAMS;
our @BUILD;

#{{{ find_dists()

=item find_dists()

Checks all the folders in the current folder to see if they are dists. All
dists that are found will be added to the list.

=cut

sub find_dists {
    distdir(".");
}
#}}}

#{{{ parse_params()

=item parse_params()

=cut

sub parse_params {
    my @list = @ARGV;
    for ( my $i = 0; $i <= @list ; $i++ ) {
        my ( $param, $value ) = ( $list[$i], $list[$i + 1] );
        next unless $param;
        if ( $param =~ m/^-/ ) {
            $param =~ s/^-+//g;
            param( $param, $value );
            $list[$i + 1] = undef;
        }
        else {
            push( @BUILD, $param );
        }
    }
}
#}}}

#{{{ param()

=item param()

=cut

sub param {
    my $param = shift;
    $PARAMS{ $param } = shift( @_ ) if @_;
    return $PARAMS{ $param };
}
#}}}

#{{{ add_package()

=item add_package()

=cut

sub add_package {
    my ( $dir, $proto ) = @_;
    $PACKAGES{ $dir } = {
        version => undef,
        run => undef,
        %$proto,
        source => _dest( $dir, $proto->{ source }),
        debian => _dest( $dir, $proto->{ debian }),
    };
}
#}}}

#{{{ build_packages()

=item build_packages()

=cut

sub build_packages {
    unless ( @BUILD ) {
        @BUILD = ( keys %PACKAGES );
    }
    build_package( $_ ) for @BUILD;
}
#}}}

=back

=head1 IMPORTABLE FUNCTIONS

=over 4

=cut

#{{{ distdir()

=item distdir()

=cut

sub distdir {
    my ( $dir ) = @_;
    opendir(my $DIR, $dir) || die("Cannot open $dir: $!\n");
    for my $subdir ( readdir( $DIR )) {
        my $file = "$subdir/build.pm";
        next unless -e $file;
        print "Found: $file\n";
        require $file;
    }
    closedir($DIR);
}
#}}}

#{{{ get_package()

=item get_package()

=cut

sub get_package {
    return $PACKAGES{ $_[0] };
}
#}}}

#{{{ build_package()

=item build_package()

=cut

sub build_package {
    my $package = get_package( $_[0] );
    die( "No automatic debian folder yet.\n" ) unless ( $package->{ source } and $package->{ debian });
    system( 'rm -rf _build' );
    system( 'cp -r "' . $package->{ source } . '" "_build/"' );
    system( 'cp -r "' . $package->{ debian } . '" "_build/"' );
    $package->{ run }->( '_build' ) if $package->{ run };
    system('for i in `find "_build" -name ".svn"`; do rm -rf "$i"; done');
    configure( '_build', $package );
    _build( $package, '_build' );
    #system( 'rm -rf "_build"' );
}
#}}}

#{{{ configure()

=item configure()

=cut

sub configure {
    my ( $tempdir, $package ) = @_;
    my $file;
    my $date = `date "+%a, %d %b %Y %H:%M:%S %z"`;
    chomp( $date );
    my $debversion = 1;
    my $email = param( 'email' ) || 'support@opensourcery.com';
    my $developer = param( 'developer' ) || 'emC Developer';
    my $version = param( 'version' ) || $package->{ version };

    opendir( TMP, "$tempdir/debian" ) || die("$!\n");
    foreach ( readdir( TMP )) {
        next unless ( -f "$tempdir/debian/$_" );
        $file = "";
        open( FILE, "<$tempdir/debian/$_" ) || die ("Cannot open file '$tempdir/debian/$_': $!\n");
        while ( my $line = <FILE> ) {
            $line =~ s/EMAIL/$email/g;
            $line =~ s/USER/$developer/g;
            $line =~ s/VERSION/$version-$debversion/g;
            $line =~ s/DATE/$date/g;
            $file .= $line;
        }
        close( FILE );

        open( FILE, ">$tempdir/debian/$_" ) || die ("$!\n");
        print FILE $file;
        close( FILE );
    }
    closedir( TMP );
}
#}}}

=back

=head1 INTERNAL FUNCTIONS

=over 4

=cut

#{{{ _dest()

=item _dest()

=cut

sub _dest {
    my ( $dir, $dest ) = @_;
    return undef unless $dest;

    return $dest =~ m,^/, ? $dest : "$dir/$dest";
}
#}}}

#{{{ _build()

=item _build()

=cut

sub _build {
    my ( $package, $tempdir ) = @_;
    system( "cd \"$tempdir\"; debuild" );
}
#}}}

1;

__END__

=back

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2007 OpenSourcery, LLC

Debian-Package-Builder is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option) any
later version.

Debian-Package-Builder is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

Debian-Package-Builder is packaged with a copy of the GNU General Public
License.  Please see docs/COPYING in this distribution.
