# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Test::Mechanize;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Test::Mechanize

=head1 SYNOPSIS

Base class for WWW::Mechanize-based acceptance tests; inherits from
L<Test::WWW::Mechanize>.

=head1 METHODS

=cut

use base 'Test::WWW::Mechanize';
use Test::LongString;
use Time::HiRes qw/ gettimeofday tv_interval /;
use Test::More;
use Test::Deep;
use HTML::TreeBuilder;
use Moose::Util qw(:all);
use Carp ();
use eleMentalClinic::Server::Apache;
use namespace::autoclean;

sub mech_args {
    return (
      autocheck => 1
    );
}

=head2 new

  my $mech = eleMentalClinic::Test::Mechanize->new(%args);

Instantiates a new Mechanize object.  See L<Test::WWW::Mechanize>,
L<WWW::Mechanize>, and L<LWP::UserAgent> for valid arguments.

eMC-specific arguments are:

=over

=item * base

the base URL for L</uri_for> (default: C<http://localhost/>)

=back

=cut

sub clone {
    my $self = shift;
    my %args = (
        server => undef,
        @_
    );

    my $clone = $self->SUPER::clone;
    $clone->{emc} = { %{ $clone->{emc} }, %args };
    $clone->cookie_jar({});
    return $clone;
}

sub new {
    my $class = shift;
    my %args  = ($class->mech_args, @_);

    my %emc_args = (
        base   => 'http://localhost/',
        port   => 80,
        server => undef,
    );

    for my $arg (keys %args) {
        $emc_args{$arg} = delete $args{$arg} if exists $emc_args{$arg};
    }
    
    my $self = $class->SUPER::new(%args);
    # use a separate namespace for our attributes so they don't collide with
    # mech
    $self->{emc} = \%emc_args;
    return $self;
}

sub new_at_port {
    my $class = shift;
    my ( $port, %args ) = @_;
    return $class->new(
        # FIXME: weird redundancy here; remove it when I'm sure what all the
        # arguments will end up being
        base => "http://localhost:$port",
        port => $port,
        %args,
    );
}

=head2 new_with_server

    my $mech = eleMentalClinic::Test::Mechanize->new_with_server(
        $httpd_conf, \%config, %args,
    );

Combine L</new> with L<eleMentalClinic::Test/start_server>.  The advantage of
using this over doing both steps manually is that a Mechanize object created
this way will automatically stop its associated server when it is destroyed.

=head2 theme_name

Override this method to change the default theme used ('Default').

=cut

sub theme_name { 'Default' }

sub new_with_server {
    my $class = shift;
    my ( $httpd_conf, $config, %args ) = @_;
    $config ||= {};
    $config->{ no_watchdog } = 1;
    $config->{theme} ||= $class->theme_name;
    my $server = eleMentalClinic::Server::Apache->new(
        $httpd_conf ? ( httpd_conf => $httpd_conf ) : (),
        config    => $config,
        test_data => 1,
    );
    $server->start;
    return $class->new_at_port( $server->port, %args, server => $server );
}

=head2 theme

Return the C<eleMentalClinic::Theme> object associated with the theme started
by this C<$mech>, instead of whatever the current config is.

=cut

sub theme {
    my $self = shift;
    require eleMentalClinic::Theme;
    return eleMentalClinic::Theme->load_theme( $self->theme_name );
}

=head2 tree

    my $tree = $mech->tree;

Uses L<HTML::TreeBuilder> to parse C<< $mech->content >> into a tree of
L<HTML::Element>s.

This caches the parsed tree; you do not need to call C<< $tree->delete >> when
finished with it, as this method wraps that up for you.

=cut

sub _deforest {
    my $self = shift;
    # delete old trees if there are any
    $_->delete for grep { defined } values %{ $self->{emc}{tree} || {} };
    $self->{emc}{tree} = {};
}

sub tree {
    my $self = shift;
    if ( $self->{emc}{tree}{ $self->content } ) {
        return $self->{emc}{tree}{ $self->content };
    } else {
        $self->_deforest;
        my $tree = HTML::TreeBuilder->new_from_content( $self->content );
        return $self->{emc}{tree}{ $self->content } = $tree;
    }
}

=head2 look_down

Shortcut for C<< $mech->tree->look_down >>.

=cut

sub look_down {
    my $self = shift;
    return $self->tree->look_down(@_);
}

=head2 content_errors

    my @errors = $mech->content_errors;

Return a list of <li> elements inside a <div class="errors">, as eMC commonly
returns them.  C<as_trimmed_text> is called on all of them, so this is actually
a list of strings.

In scalar context, returns the error messages joined with C<\n> instead.

=cut

sub content_errors {
    my $self = shift;
    return unless my $errors = $self->look_down(
        _tag => 'div', class => 'errors'
    );
    my @text = map { $_->as_trimmed_text } $errors->look_down(_tag => 'li');
    return wantarray ? @text : join("\n", @text);
}

=head2 content_errors_contain

=head2 content_errors_lack

=head2 content_errors_like

=head2 content_errors_unlike

    $mech->content_errors_contain('Thing is required.', $message);

Like C<< $mech->content_contains >>, but compared specifically to the result of
C<< $mech->content_errors >> (in scalar context).

=cut

# ignore protos on the tests from LongString so that we can pass @_ in
sub content_errors_contain {
    my $self = shift;
    &contains_string( scalar $self->content_errors, @_ );
}

sub content_errors_lack {
    my $self = shift;
    &lacks_string( scalar $self->content_errors, @_ );
}

sub content_errors_like {
    my $self = shift;
    &like_string( scalar $self->content_errors, @_ );
}

sub content_errors_unlike {
    my $self = shift;
    &unlike_string( scalar $self->content_errors, @_ );
}


=head2 uri_for

    my $uri = $mech->uri_for('/foo.cgi', { param => 'value' });

Builds a URI relative to the eMC server that C<$mech> points at.

The first argument is the path under the eMC root.

The (optional) second argument is a hashref of query form values; see
L<URI/query_form> for details.

=cut

sub uri_for {
    my $self = shift;
    my ($path, $query) = @_;
    $path =~ s{ ^ /+ }{}x;
    my $base = $self->{emc}{base};
    $base =~ s{ /+ $ }{}x;
    my $uri = URI->new( $self->{emc}{base} . '/' . $path );
    $uri->query_form( $query || {} );
    return $uri;
}
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_script_ok {
    my $self = shift;
    my( $script, %args ) = @_;

    $self->get_ok( $self->uri_for( $script || '', \%args ) );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub start_time {
    my $self = shift;
    my( $diag ) = @_;
    ok( 1, $diag )
        if defined $diag;
    $self->{emc}{time} = [ gettimeofday ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print_time {
    my $self = shift;
    my( $label ) = @_;

    return ok( 0, 'No timer started' )
        unless my $start_time = $self->{emc}{time};

    $label = $label
        ? ", $label"
        : '';
    my $time = sprintf "%.1f" => tv_interval( $start_time, [ gettimeofday ]);
    ok( 1, "${ time }s$label" );
    $self->{emc}{time} = 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 login_ok( $expected_to_pass, [ $username, $password ] )

Object method.

Tries to login to the system using C<$username> and C<$password>, both of which
are optional.  C<$expected_to_pass> is evaluated as true or false, and runns
different tests depending on where we expect the supplied credentials to pass
or fail. 

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub login_ok {
    my $self = shift;
    my( $expected_to_pass, $username, $password, $diag ) = @_;

    Carp::croak 'first argument to login_ok must be defined'
        unless defined $expected_to_pass;
    $self->start_time( $diag );

    $self->get( $self->uri_for( '/login.cgi' ) );

    $self->submit_form(
        fields => {
            login       => $username || '',
            password    => $password || '',
        },
        button => 'op',
    );

    if( $expected_to_pass ) {
        $self->content_contains( 'Select a client' );
        $self->content_contains( 'logout' );
    }
    else {
        $self->content_contains( 'correct these errors' );
        $self->content_contains( '<strong>Login</strong> is required' )
            unless defined $username;
        $self->content_contains( '<strong>Password</strong> is required' )
            unless defined $password;
        $self->content_contains( 'Login or password incorrect' )
            if defined $username and defined $password;
    }
    $self->print_time();
}

=head2 admin_login_ok

    $mech->admin_login_ok;

Use the test data's admin username and password to log in.

=cut

sub admin_login_ok {
    my $self = shift;
    $self->login_ok(1, 'clinic', 'dba');
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 logout_ok()

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub logout_ok {
    my $self = shift;
    my( $diag ) = @_;

    $self->start_time( $diag );
    $self->get_script_ok( '' );
    $self->content_contains( 'Select a client' );

    $self->follow_link( text => 'logout' );
    $self->content_contains( 'Login' );
    $self->content_contains( 'You have been <strong>logged out</strong>' );

    $self->content_contains( 'Login' );
    $self->print_time();
}

=head2 without_redirects

    my $res = $mech->without_redirects(sub {
        my $self = shift; 
        # do some stuff with $self without following redirects
    });

Encapsulate calling some code with Mechanize's normal redirect processing
turned off.

Returns the return value of the coderef that's passed in.

=cut

sub without_redirects {
    my $self = shift;
    my ($code) = @_;

    local $self->{requests_redirectable} = [];
    return $code->($self);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 header_ok($url, $header, $value, $expected, $name)

Does a request against url and checks several things:

=over

=item The header exists.

=item The header's value matches the expected value.

=back

This does not follow redirects. 

$url is polymorphic - check the docs for _prep_ua for more information.

This code generates multiple assertions.

If $expected is left out, only the header's existence is checked, which is nice
for things like session cookies which are very hard to test.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub header_ok {
    my $self = shift;
    my ($url, $header, $expected) = @_;

    $self->without_redirects(sub {
        my $self = shift;
        my $res = $self->get($url);
        ok($res->header($header), "Header $header exists");
        is($res->header($header), $expected, "Header $header is what's expected")
            if($expected);
    });
}


=head2 response_code_ok($url, $expected_code, $desc)

Checks the response code against the url via request. Succeeds only when the
codes match.

This code generates multiple assertions.

This does not follow redirects. 

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub response_code_ok {
    my $self = shift;
    my ($url, $expected_code, $desc) = @_;

    $self->without_redirects(sub {
        my $self = shift;
        $self->get($url);
        is( $self->status, $expected_code, $desc );
    });
}

=head2 get_and_return_ok

    my $res = $mech->get_and_return_ok(
        # parameters for get_ok
    );

As L<Test::WWW::Mechanize/get_ok>, but returns to the current page afterwards
on success.

Returns the response from getting the URL, not from returning.

=cut

sub get_and_return_ok {
    my $self = shift;
    my ( $url ) = @_;
    my $uri = $self->uri;
    if ( eval { $self->get_ok( @_ ) } ) {
        my $rv = $self->res;
        $self->get( $uri );
        return $rv;
    } else {
        is $@, '', "error: GET $url";
    }
}

=head2 follow_link_and_return_ok

    my $res = $mech->follow_link_and_return_ok(
        # parameters for follow_link_ok
    );

As L<Test::WWW::Mechanize/follow_link_ok>, but returns to the current page
afterwards on success.

Returns the response from following the link, not from returning.

=cut

sub follow_link_and_return_ok {
    my $self = shift;
    my ( $arg, $label ) = @_;
    my $uri = $self->uri;
    if ( eval { $self->follow_link_ok( $arg, $label ) } ) {
        my $rv = $self->res;
        $self->get( $uri );
        return $rv;
    } else {
        $label ||= "following link from $uri";
        is $@, '', "error: $label";
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

######
#The usefulness and complexity of this function are both questionable, I will finish it if
#I can find a case where it really is easier than hand-writing several tests.

=head2 complete_form_test({ prepare => sub, cleanup => sub, data => {}, form_name => 'NAME' })

***This function has not been finished yet***

Required Parameters:
    data => {
        field_a => {
            values => [ 'value 1', 'value 2', 'value 3' ],
            # Checks to run after the submit (all optional, but it is sill to run w/o at least one.)
            check => sub('field', 'value', 'submit_values') {} # Check sub.
        }
        field_b => 'xxx', #Quick syntax for a field where want a vlue, but nothing special done.
    }

Either/Or Parameters
    prepare => sub { return Test::WWW::Mechanize }
    agent => Test::WWW::Mechanize

Optional Parameters
    cleanup => sub { }
    form_name => 'NAME'

The Data structure should take the form of a hash, each key should be the name
of a field on the form. Each value should be an array of values to check.

The prepare function should take care of logging in, setting up anything that
is needed, and should end by returning a mechanized object for the test to work
with. Alternatively an agent can be specified.

The cleanup function will run after the test and take care of any cleanup you
need.

form_name should be used to specify the form to test, otherwise the first form
with all the specified fields will be used.

If a field is specified it will always have a value, if it is not specified it
will never have a value. If you want to test the form leaving the field empty
then add an empty '' value to the list.

Normally the test will check one field at a time. To do this it fills in all
other fields with the first value in their list, while iterating values on the
tested field. 

The test will return true or false for you to manually check with an ok(). If
the return is false then a second return value (anonymous array) will be
provided containing all the errors.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub complete_form_test {
    my $self = shift;
    my ( $params ) = @_;

    #### Check for required parameters.
    return (0, [ 'Missing a required parameter.' ])
        unless $params->{ data } and ( $params->{ agent } or $params->{ prepare } );

    #### Get some variables ready.
    my $data = $params->{ data };
    my $errors = [];
    my $default_values = _default_fields( $data );
    my $agent;

    #### Get some work done.
    # Iterate each field
    for my $field ( keys %$data ) {
        for my $value ( @{ $data->{ $field }} ) {
            my $submit_data = { %$default_values };
            $submit_data->{ $field } = $value;

            # Submit the data
            # Run the check.

        }
    }

    #### Cleanup and finish
    $params->{ cleanup }->() || push( @$errors, "Error in cleanup!" );
    # If there are errors return false, otherwise true, also return the errors array.
    return ( $errors->[0] ? 0 : 1, $errors );
}

# Take the data hash and strip out the extra values.
sub _default_fields {
    my $self = shift;
    my ( $data ) = @_;
    my $defaults = {};
    
    for ( keys %$data ) {
        $defaults->{ $_ } = $data->{ $_ }->[0];
    }

    return $defaults
}

=head2 id_match

    if ( $mech->id_match(\%id_to_value) ) { ... }

=head2 id_match_ok

    $mech->id_match_ok(\%id_to_value, [ $label ]);

Interpret the keys of C<%id_to_value> as element ids.  Each element in turn is
fetched, and either its C<value> or C<as_trimmed_text> (based on element type)
is compared to the corresponding value in C<%id_to_value>.

For C<id_match_ok>, the return value and optional C<$label> are passed to
C<ok()>.

=cut

sub _match_value {
    my ( $elem ) = @_;

    return 'ID NOT FOUND' unless $elem;

    if ( $elem->tag eq 'select' ) {
        my $selected = $elem->look_down(
            _tag => 'option', sub { shift->attr('selected') }
        );
        return undef unless $selected;
        return $selected->attr('value');
    }

    if ( $elem->tag eq 'input' and $elem->attr('type') eq 'checkbox' ) {
        return $elem->attr('checked') ? 1 : 0;
    }

    return defined $elem->attr('value')
        ? $elem->attr('value')
        : $elem->as_trimmed_text;
}

sub id_match {
    my $self = shift;
    my ( $want ) = @_;

    my $have = {
        map { $_ => _match_value($self->tree->look_down(id => $_)) }
            keys %$want
    };

    unless ( Test::Deep::eq_deeply( $have, $want ) ) {
        require Data::Dumper;
        Test::More::diag( Data::Dumper->Dump(
            [ $have, $want ],
            [qw(have want)],
        ) );
        return undef;
    }
    return 1;
}

sub id_match_ok {
    my $self = shift;
    my ( $want, $label ) = @_;
    $label ||= 'match ' . join(', ', sort keys %$want);
    ok( $self->id_match( $want ), $label )
}

=head2 set_personnel_password

    $mech->set_personnel_password( $staff_id, $password );

Uses the personnel configuration page to set the given user's password.

C<$mech> must already be logged in as an admin.

=cut

sub set_personnel_password {
    my $self = shift;
    my ( $staff_id, $password ) = @_;
    $self->get( $self->uri_for(
        'personnel.cgi', { staff_id => $staff_id }
    ) );
    $self->submit_form(
        form_name => 'personnel_security_form',
        fields => {
            password => $password,
            password2 => $password,
        },
        button => 'op',
    );
}

=head2 set_configuration

    $mech->set_configuration( \%config );

Uses the configuration page to set the given configuration values.  Keys are
configuration form input names, values are form input values.

C<$mech> must already be logged in as an admin.

=cut

sub set_configuration {
    my $self = shift;
    my ( $config ) = @_;
    $self->get( $self->uri_for(
        'admin.cgi', { op => 'configuration' }
    ) );
    $self->form_name('config_form');
    $self->set_fields(%$config);
    $self->click_button(value => 'Save configuration');
}

sub DESTROY {
    my $self = shift;
    $self->_deforest;
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Hans Dieter Pearcey L<hdp@opensourcery.com>

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
