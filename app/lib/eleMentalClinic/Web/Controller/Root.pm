# vim: ts=4 sts=4 sw=4:
package eleMentalClinic::Web::Controller::Root;

use Moose;
BEGIN { extends 'Catalyst::Controller' }
__PACKAGE__->config->{namespace} = '';

sub default : Private {
    my ($self, $c, @args) = @_;
    $c->response->status(404);
    $c->response->body('not found');
}

1;
