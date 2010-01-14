# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

package Earth::Mechanize;

=head1 NAME

Earth::Mechanize - theme-specific Mechanize subclass for Earth

=head1 METHODS

=cut

use base 'eleMentalClinic::Test::Mechanize';

=head2 theme_name

See L<eleMentalClinic::Test::Mechanize/theme_name>.  Uses the Earth theme.

=cut

sub theme_name { 'Earth' }

1;
