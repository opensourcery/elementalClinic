package eleMentalClinic::Report::Labelled;

use Moose::Exporter;
use eleMentalClinic::Report::Meta::Attribute;
use Moose::Util::MetaRole;
use namespace::autoclean;

Moose::Exporter->setup_import_methods;

sub init_meta {
  my $class = shift;
  my %p = @_;
  my $meta = Moose->init_meta(%p);

  Moose::Util::MetaRole::apply_metaclass_roles(
    for_class => $p{for_class},
    attribute_metaclass_roles => [
      'eleMentalClinic::Report::Meta::Attribute'
    ],
  );
}

1;
