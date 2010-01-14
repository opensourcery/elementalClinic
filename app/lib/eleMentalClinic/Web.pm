# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Web;
use eleMentalClinic;

use Class::C3::Adopt::NEXT -no_warnings;
use Moose;
BEGIN { extends 'Catalyst' };

use Catalyst qw/
  Static::Simple
/;

# XXX backwards compat - the ECS SFTP connector needs the apache request to
# spawn a subprocess.  yuck.
around prepare => sub {
  my $next = shift;
  my $c    = shift->$next(@_);
  $eleMentalClinic::Dispatch::request = $c->apache if $c->can('apache');
  return $c;
};

__PACKAGE__->config( name => 'eleMentalClinic::Web' );

__PACKAGE__->config->{static}->{dirs} = [];

__PACKAGE__->setup;

1;
