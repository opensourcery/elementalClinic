package eleMentalClinic::Base::View;
use strict;
use warnings;

my @EXPORT = qw/is_view/;

sub import {
    my $class = shift;
    my ( $caller ) = caller;
    for ( @EXPORT ) {
        no warnings 'redefine';
        no strict 'refs';
        *{ $caller . '::' . $_ } = \&{$_};
    }
}

sub is_view { 1 }

1;
