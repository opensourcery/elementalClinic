use strict;
use warnings;

package eleMentalClinic::Singleton;

my %I;

sub instance { 
  my $class = shift;
  return $I{$class} ||= $class->_new_instance(@_);
}

sub clear_instance {
  my $class = ref($_[0]) || $_[0];
  delete $I{$class};
}

1;
__END__

=head1 NAME

eleMentalClinic::Singleton - singleton objects (deprecated)

=head1 DESCRIPTION

Several eMC objects are singletons.  In the past, they all inherited from
Apache::Singleton::Process; this behavior is no different from any other
non-mod_perl singleton module.

This module exists only until the singletons can go away.

=cut
