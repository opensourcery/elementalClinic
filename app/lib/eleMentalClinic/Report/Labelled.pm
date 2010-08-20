package eleMentalClinic::Report::Labelled;

use Moose::Exporter;
use eleMentalClinic::Report::Meta::Attribute;
use Moose::Util::MetaRole;
use namespace::autoclean;


=head1 NAME

eleMentalClinic::Report::Labelled

=head1 SYNOPSIS

    package eleMentalClinic::Report::Plugin::Foo;

    use Moose;
    use eleMentalClinic::Report::Labelled;


=head1 DESCRIPTION

Adds the C<eleMentalClinic::Report::Meta::Attribute> to a meta
role... or something.

All I know is if you're making a report plugin it has to use this.


=cut

Moose::Exporter->setup_import_methods;

sub init_meta {
  my $class = shift;
  my %p = @_;
  my $meta = Moose->init_meta(%p);

  # apply_metaclass_roles was deprecated in 0.94.
  # Avoid a deprecation warning, but still work with Moose pre-0.94.
  if( $Moose::Util::MetaRole::VERSION < 0.94 ) {
      Moose::Util::MetaRole::apply_metaclass_roles(
          for_class           => $p{for_class},
          attribute_metaclass_roles => [
              'eleMentalClinic::Report::Meta::Attribute'
          ],
      );
  }
  else {
      Moose::Util::MetaRole::apply_metaroles(
          for                 => $p{for} || $p{for_class},
          class_metaroles     => {
              attribute => [
                  'eleMentalClinic::Report::Meta::Attribute'
              ],
          }
      );
  }
}

1;
