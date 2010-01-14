# vim: ts=4 sts=4 sw=4

use strict;
use warnings;

package eleMentalClinic::Base::Globals;

use Sub::Exporter -setup => {
  exports => [qw(db config)],
};

require eleMentalClinic::DB;
require eleMentalClinic::Config;

sub db     { eleMentalClinic::DB->new }
sub config { eleMentalClinic::Config->new->stage2 }

1;
