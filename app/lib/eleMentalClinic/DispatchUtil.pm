=head1 eleMentalClinic::DispatchUtil

Utilities for dispatchers and other mod_perl handlers

=cut

package eleMentalClinic::DispatchUtil;

use strict;
use warnings;

use base qw(Exporter);
use Carp qw(confess);
use eleMentalClinic::Config;

# these are package definitions that are compared against
# the return value of caller. See perldoc -f caller for more
# information
#
# These are regular expressions, do not try to use strings here.
use constant HANDLE_ERRORS => [
    qr/^eleMentalClinic::/,
    qr/^CGI::ValidOp/,
    qr/^X12::Parser/,
];

use constant DEBUG_ERRORS => 1;

BEGIN {
    # XXX I think this is safe. If this module is being used, we're likely in a
    #     mod_perl handler and this shouldn't cause too many problems. Hell, even
    #     if it's on it probably won't cause too many problems.
   
    STDERR->autoflush(1);
    STDOUT->autoflush(1);
}

# put every method you want usable outside of this module here.
our @EXPORT = qw(
    configure_die_handler
    get_request_singletons
    is_controller
    get_query_string
);

sub configure_die_handler {
    my $r = shift;

    # this is kind of goofy.  it logs the errors and throws them up to the
    # handler in Dispatch.pm, which just returns a 500 when it sees an error.
    # theoretically this could mean that things dying outside of the namespaces
    # above won't get logged by apache.
    $SIG{__DIE__} = sub { 
        my $error = $_[0];

        # XXX this is a real hack, but not seeing errors in the log is worse.
        $eleMentalClinic::Dispatch::LAST_ERROR = $error;

        foreach my $error_regex (@{HANDLE_ERRORS()}) { # effing perl
            if ((caller)[0] =~ $error_regex) { 
                # a simple confess() implementation. confess() doesn't really work well here.
                $r->log_error("Died: $_") for (split(/\n/, $error));

                if (DEBUG_ERRORS) {
                    for (my $i = 1; caller($i); $i++) {
                        $r->log_error(join(" : ", map { defined $_ ? $_ : () } (caller($i))[0, 1, 2, 3]));
                    }
                }
            }
        }

        die $error;
    };
}

sub get_request_singletons {
    my $r = shift;

    my $CONFIG = eleMentalClinic::Config->new({ request => $r })->stage1;
    my $THEME  = $CONFIG->Theme;
    my $DB     = eleMentalClinic::DB->new;

    return ( DB => $DB, CONFIG => $CONFIG, THEME => $THEME );
}

sub is_controller {
    my $r = shift;

    # XXX the second check should never actually happen due to our apache
    #     configuration, but let's be sure.
    return (!length($r->uri) || $r->uri =~ /\.cgi$/ || $r->uri eq '/');
}

sub get_query_string {
    my $r = shift;

    # chop a trailing slash if there's one
    my ($uri) = $r->uri =~ /(^.*?)\/?$/;
   
    my $args = $r->args;
    $args = $args ? "?$args" : "";

    return $uri.$args;
}

'eleMental';

=head1 AUTHORS

=over 4

=item Erik Hollensbe L<erikh@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see
L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for
known bugs.

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

=cut
