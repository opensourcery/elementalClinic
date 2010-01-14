package eleMentalClinic::Controller;

use strict;
use warnings;

use base 'eleMentalClinic::CGI';

1;
__END__

=head1 NAME

eleMentalClinic::Controller - base class for all web controllers

=head1 DESCRIPTION

eleMentalClinic::Controller is the parent of all generic and theme-specific
controllers.

Controllers are laid out underneath eleMentalClinic::Controller, like so:

=over

=item * eleMentalClinic::Controller::Base

Controllers under C<Base> are the default, base functionality.  Almost all code
should go into one of these modules, either directly, or indirectly through
imports/mixins/whatever.

=item * eleMentalClinic::Controller::C<$theme>

Controllers under a theme-specific namespace (will be) automatically loaded as
necessary.  They should only have the bare minimum of code required, for cases
when configuration options are insufficient.  (XXX -- this does not yet work)

=back

=cut
