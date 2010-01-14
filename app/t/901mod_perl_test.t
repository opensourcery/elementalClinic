# vim: ts=4 sts=4 sw=4
#
# tests CGI and display_page under mod_perl
#

use strict;
use warnings;

use Test::More tests => 8;

use eleMentalClinic::Test::Mechanize;

sub eleMentalClinic::Test::Mechanize::test_uri {
    my ($self, $op, $query) = @_;
    my $uri = $self->uri_for('/test.cgi');
    $query->{op} = $op;
    $uri->query_form($query);
    return $uri;
}

my $mech = eleMentalClinic::Test::Mechanize->new_with_server(
    undef, { theme => 'Test' },
);

# normal
$mech->response_code_ok(
    $mech->test_uri('test_normal'), 200,
    'test normal: status code',
);
$mech->content_like(qr/from: normal/, 'test normal: content');

# external redirect
$mech->response_code_ok(
    $mech->test_uri('test_external_redirect'), 302, 
    'test external redirect: status code',
);
is(
    $mech->res->header('Location'), '/test.cgi?op=test_normal;from=external%20redirect',
    'test external redirect: Location header',
);
$mech->get_ok(
    $mech->test_uri('test_external_redirect')
);
$mech->content_like(
    qr/from: external redirect/,
    'test external redirect: content'
);

# internal redirect
$mech->get_ok(
    $mech->test_uri('test_internal_redirect'),
    'test internal redirect: success',
);
$mech->content_like(
    qr/from: internal redirect/,
    'test internal redirect: content',
);
