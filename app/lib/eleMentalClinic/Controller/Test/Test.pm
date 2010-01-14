package eleMentalClinic::Controller::Test::Test;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Test::Test

=head1 SYNOPSIS

Test controller for Test theme

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        test_external_redirect => {},
        test_internal_redirect => undef,
        test_send_file => undef,
        test_error => undef,
        test_error_with_handler => {
            param => [ 'a', 'required' ],
            -on_error => sub { die 'do something useful' },
        },
        test_normal => {},
    )
}

sub run_cgi {
    my($self, $uri_and_path) = @_;
    # don't bother checking login
    return $self->display_page;
}

use Data::Dumper;
sub home {
    my $self = shift;
    my $req = $self->request;
    die "HOME: never get here;" . Dumper({
        map {( $_ => $req->$_ )} qw(uri hostname the_request)
    });
}

sub test_external_redirect {
    my $self = shift;
    return '', { Location => '/test.cgi?op=test_normal;from=external%20redirect' };
}

sub test_internal_redirect {
    my $self = shift;
    return '', {
        forward => 'test_normal',
        forward_args => [
            { from => 'internal redirect' },
        ]
    };
}

sub test_send_file {
    my $self = shift;
    return $self->send_file({
        path      => 'res/css/base.css',
        mime_type => 'text/css',
        name      => 'base.css',
    });
}

sub test_error {
    my $self = shift;
}

sub test_error_with_handler {
    my $self = shift;
}

sub test_normal {
    my $self = shift;
    my ($arg) = @_;
    return {
        from => $arg->{from} || $self->param('from') || 'normal',
    };
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Hans Dieter Pearcey L<hdp@weftsoar.net>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2007 OpenSourcery, LLC

This file is part of eleMental Clinic.

eleMental Clinic is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option) any
later version.

eleMental Clinic is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

eleMental Clinic is packaged with a copy of the GNU General Public License.
Please see docs/COPYING in this distribution.
