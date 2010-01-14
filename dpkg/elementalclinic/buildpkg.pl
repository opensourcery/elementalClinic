#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;
#This script will build a debian package for elemental clinic

use Getopt::Long;
use Module::CoreList;

my ( $developer, $email, $version, $debversion, $dest, $lib );
my $checkout;
my @notifications;

$debversion = 1;

GetOptions(
     "--dev=s"        => \$developer,
     "--mail=s"       => \$email,
     "--version=s"    => \$version,
     "--debversion=s" => \$debversion,
     "--dest=s"       => \$dest,
     "--help"         => \&help,
     "--checkout=s"   => \$checkout,
     "--lib=s"        => \$lib,
);

sub help {
    print 'Usage: buildpkg.pl
    --dev=[Full Name]
    --mail=[user@domain.tld]
    --version=[VERSION]
    --checkout=[/path/to/checkout]

Other options:
    --dest        Destination for package
    --debversion  Debian package version (default: 1)
';
}

if ( $0 eq __FILE__ ) {
    $version ||= do {
        unshift @INC, "$checkout/lib";
        require eleMentalClinic;
        eleMentalClinic->VERSION;
    };
    unless ( $developer and $email and $version) {
        help();
        print "You must specify your name, e-mail address, and the version number\n";
        exit(1);
    }
    print ("Developer: $developer\nEmail: $email\n");

    unless ($checkout) {
        die "You must specify a checkout directory.\n";
    }
    print "Version: $version\n";

    $dest = "/tmp" unless ( $dest );
    print "Final package will be placed in: $dest\n";

    my $tempdir = "/tmp/elementalclinic-$version";
    die( "temporary directory already exists!" ) if ( -e $tempdir );

    to_temp( $tempdir );

    configure( $tempdir );

    build( $tempdir );

    cleanup( $tempdir );
}

sub to_temp {
    my ( $tempdir ) = @_;

    mkdir( $tempdir );
    system("cp -r debian Makefile config.yaml $checkout/etc \"$tempdir/\"");

    system('for i in `find "' . $tempdir . '" -name ".svn"`; do rm -rf "$i"; done');

    system(<<"END");
(echo "CHECKOUT := $checkout"; echo "ADDLIB := $lib"; cat "$tempdir/Makefile") > "$tempdir/Makefile.new";
mv "$tempdir/Makefile.new" "$tempdir/Makefile"
END
}

sub configure {
    my ( $tempdir ) = @_;
    my $file;
    my $date = `date "+%a, %d %b %Y %H:%M:%S %z"`;
    chomp( $date );
    opendir( TMP, "$tempdir/debian" ) || die("$!\n");
    foreach ( readdir( TMP )) {
        next unless ( -f "$tempdir/debian/$_" );
        $file = "";
        open( FILE, "<$tempdir/debian/$_" ) || die ("Cannot open file '$tempdir/debian/$_': $!\n");
        while ( my $line = <FILE> ) {
            $line =~ s/EMAIL/$email/g;
            $line =~ s/USER/$developer/g;
            $line =~ s/EMC_VERSION/$version/g;
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

sub build {
    my ( $tempdir ) = @_;
    system( "cd \"$tempdir\"; debuild" );
}

sub cleanup {
    my ( $tempdir ) = @_;
    #system("rm -rf \"$tempdir\"");
    system( "mv /tmp/elementalclinic_$version* \"$dest\"" );
    print "Package is ready and in $dest\n";
}

1;
