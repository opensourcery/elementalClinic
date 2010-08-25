# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Types;

use strict;
use warnings;

my %class_types;
BEGIN { %class_types = (
  Client          => 'eleMentalClinic::Client',
  ClientAllergy   => 'eleMentalClinic::Client::Allergy',
  Personnel       => 'eleMentalClinic::Personnel',
  Treater         => 'eleMentalClinic::Client::Treater',
  ClientInsurance => 'eleMentalClinic::Client::Insurance',
) }

use MooseX::Types -declare => [
  keys %class_types,
];

for my $name (keys %class_types) {
    my $tc = __PACKAGE__->can($name)->();
    class_type $tc, { class => $class_types{$name} };
}

1;
