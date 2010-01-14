# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

package Venus::Mechanize;

=head1 NAME

Venus::Mechanize - theme-specific Mechanize subclass for Venus

=head1 METHODS

=cut

use base 'eleMentalClinic::Test::Mechanize';
use Carp ();
use Test::More ();

=head2 theme_name

See L<eleMentalClinic::Test::Mechanize/theme_name>.  Uses the Venus theme.

=cut

sub theme_name { 'Venus' }

=head2 login_ok

    $mech->login_ok( $expected, [ $username, $password ] );

See L<eleMentalClinic::Test::Mechanize/login_ok>.  Venus uses different HTML
and the base login_ok fails for it.

=cut

sub login_ok {
    my $self = shift;
    my ($expected, $user, $pass) = @_;

    Carp::croak 'first argument to login_ok must be defined'
        unless defined $expected;

   $self->get_script_ok( 'login/login.cgi' );
   $self->set_fields(
        login    => $user,
        password => $pass,
    );
    $self->click_button( value => 'Login' );
    if ($expected) {
        $self->content_contains( 'logout' );
    } else {
        die 'unimplemented';
    }
}

1;
