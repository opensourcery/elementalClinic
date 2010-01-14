package elementalclinic::build;
use strict;
use warnings;

use Debian::Package::Builder;

my $checkout = param( 'checkout' );
my $addlib = param( 'addlib' );
die( "must specify an emC checkout directory (--checkout)\n" ) unless $checkout and -d $checkout;

my $dir = __FILE__;
$dir =~ s,/[^/]*$,,g;

require "$checkout/lib/eleMentalClinic.pm";

add_package(
    $dir,
    {
        debian => 'debian',
        source => $checkout,
        version => $eleMentalClinic::VERSION,
        run => sub {
            my ( $tempdir ) = @_;
            system("cp -r '$dir/Makefile' '$tempdir'");
            system(<<"END");
(echo "CHECKOUT := $checkout"; echo "ADDLIB := $addlib"; cat "$tempdir/Makefile") > "$tempdir/Makefile.new";
mv "$tempdir/Makefile.new" "$tempdir/Makefile"
END
            system("cp -r '$dir/INSTALL' '$tempdir'");
        },
    }
);

1;
