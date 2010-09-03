# vim: ts=4 sts=4 sw=4
package eleMentalClinic::CGI;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::CGI

=head1 SYNOPSIS

Parent controller; all controllers subclass this object.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base /;
use eleMentalClinic::Template;
use eleMentalClinic::Personnel;
use eleMentalClinic::Client;
use eleMentalClinic::Department;
use eleMentalClinic::Log;
use eleMentalClinic::Help;
use HTTP::Date qw(time2str);
use Time::Local qw(timelocal_nocheck); 
use CGI::ValidOp;
use CGI qw/ referer cookie script_name /;
use CGI::Session 4.0;
use Date::Calc qw/ Today Today_and_Now Date_to_Days /;
use Data::Dumper;
use URI;
use URI::QueryParam;
#use Carp;
#use CGI::Carp;

# XXX MERGE maybe this should be commented
#BEGIN {
#    CGI::Carp::set_message( sub { eleMentalClinic::CGI->new->fatal_error( shift )})
#}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub methods {
        [ qw/ template template_vars html error
            validop cookie_value
            op security
            script variant styles
            session
            ajax
            mime_type
            request
            override_template_path override_template_name
            catalyst_c
        /]
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub default_vars {
    {
        script              => 'index.cgi',
        variant             => undef,
        styles              => undef,
    }
}

# this was originally refactored for tests; theoretically we might like it
# to be configurable someday
my %SESSION = (
    pg => {
        driver => 'PostgreSQL',
        args   => sub {
            return (
                Handle     => shift->db->connect('cgi_session'),
                ColumnType => 'binary',
            );
        },
    },
);

sub _new_session {
    my $self = shift;
    my ( $args ) = @_;

    my $session_type = 'pg';

    my $session = CGI::Session->new(
        "driver:$SESSION{ $session_type }{driver}",
        $args->{cgi_object},
        {
            $SESSION{ $session_type }{args}->( $self ),
        },
    )
    or die CGI::Session->errstr;

    return $session;
}

sub new_with_cgi_params {
    my $class = shift;
    my ( %params ) = @_;
    return $class->new({
        cgi_object => CGI->new( \%params ),
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME : this is really ugly :: Randall
sub init {
    my $self = shift;
    my( $args ) = @_;

    eleMentalClinic::Log->new;
    $self->SUPER::init( $args );
    $self->request($args->{request});

    # setup session management
    CGI::Session->name( 'eleMentalClinicSession' );

    $self->session( $self->_new_session( $args ) );

    $self->session->expire( '+'. ( $self->config->logout_time || 30 ) .'m' );

    #Put this here in case some vars need to be dynamic based on params.
    $self->get_ops($args->{cgi_object});

    # stuff to pass to ::Template
    my %vars;
    $vars{current_user} = $self->current_user;
    $vars{today_ymd}    = $self->today;
    $vars{department}   = eleMentalClinic::Department->new({ dept_id => 1001 });
    $vars{Config}       = $self->config;
    $vars{EMC_Version}  = $eleMentalClinic::VERSION;

    my %default_vars = %{ &default_vars };
    while( my( $key, $value ) = each %default_vars ) {
        my $val = defined $args->{ $key }
            ? $args->{ $key }
            : $value;
        $self->$key( $val );
        $vars{ $key } = $val;
    }

    # setup template
    $self->template( eleMentalClinic::Template->new({
        template_markers    => 1,
        controller          => $self,
        vars                => {
            %vars,
            eMC        => $self->context,
            Help       => eleMentalClinic::Help->new,
        }
    }));
    # Since we call get_ops before buildign a template we have these values here.
    $self->apply_template_vars;
    $self->client if $self->param( 'client_id' );

#    Log( 'query-variables', Dumper { $self->Vars } );
#    Log( 'session-variables-initial', Dumper $self->session->dataref );

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 fatal_error()

Object method.

Handler for fatal error messages.  Called by CGI::Carp.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub fatal_error {
    my $self = shift;
    my( $error_message ) = @_;

    $self->template->vars({
        styles => [ 'fatal_error' ],
    });
    return $self->template->process_page( 'global/header' ).
           $self->template->process_page( 'global/fatal_error', {
                message => $error_message,
           }).
           $self->print_footer( force => 1 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub context {
    my $self = shift;
    my( $vars ) = @_;

    my $controller = $1
        if script_name() =~ m#(\w+)(?:\.cgi)?#;
    my $referrer = $1
        if referer() and referer() =~ m#(\w+)\.cgi#;

    my %context = ();
    $context{ department } = eleMentalClinic::Department->new({ dept_id => 1001 });
    $context{ user       } = $self->current_user;
    $context{ config     } = $self->config;
    $context{ controller } = $controller;
    $context{ referrer   } = $referrer;
    return \%context;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
#     die "You must subclass eleMentalClinic::CGI; in particular, override eleMentalClinic::CGI::ops.";
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub objects {
    my $self = shift;
    my ($name) = @_;

    $self->{validop}->objects($name);
}

sub default_ops {
    my $self = shift;
    return (
        -default_op => 'home',
        -error_decoration   => [ '<strong>', '</strong>' ],
        -on_error_return_encoded    => 1,
    );
}

sub get_all_ops {
    my ($self, $cgi) = @_;

    return ( $self->default_ops, $self->ops );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_ops {
    my ($self, $cgi) = @_;

    my %ops = $self->get_all_ops( $cgi );

    $ops{'-cgi_object'} = $cgi if $cgi;

    $self->{ validop } = CGI::ValidOp->new( \%ops );
    # Use special method template_vars in case the template is not ready yet.
    $self->template_vars({ op => $self->op });
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# If the template is ready it acts just like $self->template->vars();
# If the template is not ready it will append the values to a list for use when
# the template is ready.
sub template_vars {
    my $self = shift;
    return $self->template->vars(@_) if $self->template;
    push( @{ $self->{ _template_vars }}, @_ );
}

# Apply any queued template vars and empty the queue
sub apply_template_vars {
    my $self = shift;
    $self->template->vars($_) for @{$self->{_template_vars}};
    $self->{_template_vars} = [];
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub param {
    my $self = shift;
    my( $name ) = @_;
    $self->{ validop }->param( $name );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub Vars {
    my $self = shift;
    my( $name ) = @_;
    $self->{ validop }->Vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 Vars_byprefix()

Convenience method to run extract_byprefix() on $self->Vars.

=cut

sub Vars_byprefix() {
    my $self = shift;
    my( $prefix ) = @_;

    return $self->extract_byprefix( { $self->Vars }, $prefix);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 extract_byprefix()

Takes a reference to a hash and a string prefix and returns a hash
with just those entries whose keys matched the given prefix.  The resultant
hash's keys will have the prefix removed.

=cut;

sub extract_byprefix {
    my $self = shift;
    my( $hash, $prefix ) = @_;

    return unless ref $hash eq 'HASH';

    my $results = {};
    foreach my $key (keys %$hash) {
        if ($key =~ qr/$prefix(.+)/) {
            $results->{$1} = $hash->{$key};
        }
    }
    return $results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub latest_date {
    my $self = shift;
    my ( @dates ) = @_;
    my $max;

    foreach my $date ( @dates ) {
        next unless $date;
        $date = (split( ' ', $date ))[0] if( $date =~ m/ / );  # strip off time if present.
        $date = sprintf "%4d-%02d-%02d", split( "-", $date );  # zero pad where needed.
        $max ||= $date;
        $max = $date if $max lt $date;
    }

    return $max;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub earliest_date {
    my $self = shift;
    my ( @dates ) = @_;
    my $min;

    foreach my $date ( @dates ) {
        next unless $date;
        $date = (split( ' ', $date ))[0] if( $date =~ m/ / );  # strip off time if present.
        $date = sprintf "%4d-%02d-%02d", split( "-", $date );  # zero pad where needed.
        $min ||= $date;
        $min = $date if $min gt $date;
    }

    return $min;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# if user is logged in displays the page they requested
# if not, redirects to login script
sub run_cgi {
    my ($self, $uri_and_path) = @_;

    return $self->redirect_to_login($uri_and_path)
        unless $self->login;
    return $self->security_denied unless $self->security_check;

    my ($html, $headers) = $self->display_page;
#    Log( 'session-variables-final', Dumper $self->session->dataref );
    # flush session here since no code will be called after this
    $self->session->flush;

    return ($html, $headers);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub login {
    my $self = shift;
    my( $user ) = @_;

    $user ||= $self->current_user;
    return unless $user;

    $self->session->param( user_id => $user->id );
    return $user->id;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub redirect_to_login {
    my ($self, $uri_tail) = @_;

    # if there's a client_id in the POST data and none in the URI:
    my $client_id = ( $self->client->id and not grep /client_id/ => $uri_tail )
        ? ';client_id='. $self->client->id
        : '';
    # if client_id is the only POST data other than the script:
    $client_id = "?$client_id" 
        if $client_id and $uri_tail =~ /\.cgi$/;

    # XXX the ternary op here concatenates nothing unless $uri_tail or $client_id
    # is set to something.
    return '', { Location => 
        "/login.cgi?previous="
        . ((!$uri_tail && !$client_id) ? '' : CGI::escape( "/${ uri_tail }${ client_id }" ))
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub logout {
    my $self = shift;

    $self->session->delete;
    delete $self->{ session };
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# if no current_user already get it from session
sub current_user {
    my $self = shift;
    my( $user ) = @_;

    $self->{ current_user } ||= $user;
    return $self->{ current_user }
        if $self->{ current_user };

    return unless
        my $id = $self->session->param( 'user_id' );

    $self->{ current_user } = eleMentalClinic::Personnel->retrieve( $id );
    return $self->{ current_user };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns true if no security
# dies if invalid security method specified
# returns true if security method passed
# returns false otherwise
sub security_check {
    my $self = shift;

    return 1 unless $self->security;
    my $security = $self->security;
    die "Invalid security method: '$security'"
        unless $self->current_user->can( $security );
    return $self->current_user->$security
        || $self->current_user->admin;
}

sub security_denied {
    my $self = shift;

    $self->{validop}->cgi_object->referer() =~ m#/(.*)#;
    my $previous = $1;
    my ($html, $header) = $self->print_header;

    return (
        $html .
        $self->template->process_page( 'login/security_denied', {
            previous    => '/'. ( $previous || '' ),
        }) .
        $self->print_footer( force => 1 ),
        $header
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print_header {
    my $self = shift;
    my( %extras ) = @_;

    # chop a day off the time for the expires header.
    
    my @localtime = localtime(time);

    $localtime[3]--; # day of month field

    my $expires = time2str(timelocal_nocheck(@localtime));

    # convert CGI headers to hash
    my $mime_type = $self->mime_type || $self->config->mime_type;
    # XXX this doesn't seem like the right place to do this; should it be in
    # the config instead?
    if ( $mime_type eq 'text/html' ) {
        $mime_type = "$mime_type; charset=UTF-8";
    }

    my $header_hash = { 
        'Content-Type' => $mime_type,
        'Set-Cookie'   => $self->bake_cookie,
        'Expires'      => $expires,
        %extras
    };
    
    my $html = $self->template->process_page( 'global/header' )
        unless $self->ajax or $self->mime_type;

    return ($html, $header_hash);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub footer {
    my $self = shift;
    $self->template->process_page( 'global/footer' );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print_footer {
    my $self = shift;
    my( %args ) = @_;

    return if
        $self->ajax and not $args{ force };
    return $self->footer;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub bake_cookie {
    my $self = shift;
    my( %vars ) = @_;

    my $cookie = $self->{validop}->cgi_object->cookie(
        -name       => $self->session->name,
        -value      => $self->session->id,
        -expires    => '+'. $self->session->expire .'s',
        %vars,
    );

    return $cookie;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# simulates an "internal redirect" which can be done inside a controller
# from one method to another. It currently cannot cross controllers.. Perhaps
# that's something I'll work on later.
#
# It's also recursive. $self->forward() in one controller will not break if
# $self->forward is called in the forwarded controller. This does increase
# the stack depth by *TWO* each time it's done though, so use it conservatively.
# 

sub forward { 
    my $self = shift;
    my ($page_name, @page_arguments) = @_;

    return undef, { forward => $page_name, forward_args => \@page_arguments };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# XXX: do not touch the following subroutine unless you are prepared to
#      break the whole application.
sub display_page {
    my $self = shift;
    my ($page_name) = shift; # XXX INTENTIONAL - randall please don't hurt me.

    my ($output, $redirect);
    
    # $page_name is first 'cause it may change data that appears in header
    $page_name ||= $self->op;

    # adding session here since something in the op may have changed it
    $self->template->vars({ Session => $self->session->dataref })
        if $self->session;

    my $error_sub;
    if ($self->errors || $self->object_errors) {
        $self->template->vars(
            {
                errors =>
                  [ @{ $self->errors || [] }, @{ $self->object_errors || [] } ],
                %{$self->Vars},
                objects => $self->objects
            }
        );
        my %ops = $self->ops;
        if ($ops{$page_name}{'-on_error'}) {
            $self->override_template_name( undef );
            $error_sub = $ops{$page_name}{'-on_error'};
            ($output, $redirect) = $self->$error_sub(@_);
        } else {
            ($output, $redirect) = $self->$page_name(@_);
        }
    } else { 
        ($output, $redirect) = $self->$page_name(@_);
    }

    if ($redirect && $redirect->{forward}) { # an internal redirect provided by forward()
        return $self->display_page($redirect->{forward}, @{$redirect->{forward_args}});
    }

    if( $redirect && $redirect->{Location} ) { # an actual redirect
        return '', $redirect;
    } elsif ( $redirect && $redirect->{'Content-Type'} ) { # send_file case
        return ($output, $redirect);
    } else { # normal content
        my ($html, $header) = $self->print_header;

        if ($redirect && $header) {
            $header = { %$header, %$redirect };
        }

        if (ref $output and ref $output eq 'HASH') {
            $self->template->vars($output);
            $output = $self->template->process_page( $self->create_template_path( $error_sub || $page_name ));
        } 

        return ($html || '').
        ($output || '').
        ($self->print_footer || ''), $header;
    }
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 create_template_path([ $page_name, $error_sub ])

Object method.  Sets or returns relative path to the template for this request.
Returns a concatenation of the C<path> and C<name> of the template.  Each of
those two elements can be determined several ways.

=over 4

=item C<path>

Uses (in order of preference) either C<override_template_path()> or the
lowercase of the last word of the current controller name.  In other words, for
C<eleMentalClinic::Controller::Default>, uses "default".

=item C<name>

Uses (in order of preference) either the incoming C<$error_sub>,
C<override_template_name()>, or the incoming C<$page_name>.

=back

This method exists in case you need to override the automatic template name
that would otherwise be generated.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub create_template_path {
    my $self = shift;
    my( $page_name ) = @_;

    my $name = $self->override_template_name || $page_name || '';
    my $path = $self->override_template_path;
    unless( $path ) {
        my $class = ref $self;
        my( $dir ) = $class =~ /::([^:]+)$/;
        $path = lc $dir;
    }
    return "$path/$name";
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns ( undef, $uri ), where $uri is constructed from the
# root URI, the named controller, and the optional client_id
# XXX this uses the hack in display_page of using a second parameter
# for redirection.  this is begging for a more robust solution, but
# that would entail a refactor of display_page
sub redirect_to {
    my $self = shift;
    my( $controller, $client_id ) = @_;

    die "'client_id' must be an integer"
        if $client_id and $client_id !~ /^\d*$/;

    my $uri;

    if( $controller or $client_id ) {
        $controller =~ s/\.cgi$//ig;
        $uri = '/'.$controller.".cgi"
            if $controller;
        $uri .= $client_id
            ? "?client_id=$client_id"
            : '';
    }

    $uri ||= '/';

    return( undef, { Location => $uri } );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns styles in order: layout ones first, then the rest
sub styles {
    my $self = shift;
    my( $styles ) = @_;

    my @styles = @{ $self->{ styles }}
        if $self->{ styles };

    # reset this since we're pushing styles onto it below
    $self->{ styles } = [];

    # add any incoming styles
    if( $styles ) {
        ref $styles eq 'ARRAY'
            ? push @styles => @$styles
            : push @styles => $styles;
    }

    # get the layout styles
    for( sort grep( /^layout/, @styles )) {
        push @{ $self->{ styles }} => $_;
    }

    # get the non-layout styles
    for( sort grep( !/^layout/, @styles )) {
        push @{ $self->{ styles }} => $_;
    }

    return @{ $self->{ styles }}
        ? $self->{ styles }
        : undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub javascripts {
    my $self = shift;
    my( $incoming ) = @_;

    return unless $self->{ javascripts } or $incoming;
    my $js = $self->{ javascripts };

    # add any incoming javascripts
    if( $incoming ) {
        ref $incoming eq 'ARRAY'
            ? push @$js => @$incoming
            : push @$js => $incoming;
    }

    $self->{ javascripts } = $js;
    return $self->{ javascripts };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub errors {
    my $self = shift;
    $self->validop->errors;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub object_errors {
    my $self = shift;
    my $hash = $self->validop->object_errors;

    my $errors = [];

    foreach my $key (keys %$hash) {
        # iterate over the object errors and append
        for (my $i = 0; $i < @{$hash->{$key}{object_errors}}; $i++) {
            foreach my $key2 (keys %{$hash->{$key}{object_errors}[$i]}) {
                my $object_error = $hash->{$key}{object_errors}[$i]{$key2};
                push @$errors, @$object_error if @$object_error; 
            }
        }
        # get the global errors for this class
        my $global_errors = $hash->{$key}{global_errors};
        push @$errors, @$global_errors if @$global_errors;
    }

    return $errors if @$errors;
    return undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub add_error {
    my $self = shift;
    my( $param_name, $errname, $errmsg ) = @_;
    return unless $param_name and $errname and $errmsg;

    my $param = $self->validop->Op->Param( $param_name );

    unless ($param) {
        die "Attempted to add errors for param '$param_name', message '$errmsg'"
    }

    $param->add_error( "eleMentalClinicCustomError_$errname", $errmsg );
    $self->template->vars({ errors => $self->errors });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# not used right now; have to figure out if they belong here or in Template
sub messages {
    my $self = shift;
    my( @messages ) = @_;
    @messages && push @{ $self->{ messages }}, $_ for @messages;
    return $self->{ messages }
        ? $self->{ messages }
        : undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Loads client from passed querystring parameters
# or the session, if available.  Otherwise returns a 
# new client.
sub client {
    my $self = shift;
    my( $client_id ) = @_;

    my $client;

    if ( $client_id ||= $self->param( 'client_id' ) ) {
        $client = eleMentalClinic::Client->retrieve( $client_id );
        if ($client && $client->id) {
            Log({
                type => 'access',
                object => $client,
                action => 'load',
                user => $self->current_user || undef,
            });
        }
    }
    elsif ( $self->session->param( 'client_id' )) {
        $client = eleMentalClinic::Client->new({
            client_id => $self->session->param( 'client_id' ),
        })->retrieve;
        Log({
            type => 'access',
            object => $client,
            action => 'reload',
            user => $self->current_user || undef,
        });
    }

    if ( $client ) {
        $self->template->vars({ client => $client });
        return $client;
    }

    if( $client = $self->template->vars->{ client }) {
        return $client;
    }

    $client = eleMentalClinic::Client->new;
    $self->template->vars({ client => $client });
    return $client;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_client {
    my $self = shift;
    $self->client;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub op {
    my $self = shift;
    return $self->validop->op( @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# succeeds unless end date is after start date; dies an ugly
# death unless both dates are ASNI format:  yyyy-m?-d?
sub date_compare {
    my $self = shift;
    my( $start_date, $end_date, $field ) = @_;
    return 1 unless $start_date and $end_date;

    return 1
        if Date_to_Days( split /-/, $start_date ) <=
        Date_to_Days( split /-/, $end_date );
    $self->add_error( $field, 'date_compare', 'End date must be after start date.' );
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_printer_list {
    my $self = shift;

    my @list = split( /\s+/, `lpstat -p | cut -d ' ' -f 2` );
    $self->add_error( "by_client", "Printer Failure",
                      "There are no printers configured on the server." .
                      "  Please notify the systems administrator." ) unless( @list );

    return \@list;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub date_check {
    my $self = shift;
    my( @fields ) = @_;
    return if grep {
        my $param = $self->validop->Op->Param( $_ );
        !$param or $param->errors
    } @fields;
    $self->date_compare( $self->param( $fields[0] ), $self->param( $fields[1] ), $fields[0]);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns arrayref of incoming item ids, stripped from, e.g.:
# optional $prefix
# ${ prefix }_1=on;${ prefix }_2=on
sub get_item_ids {
    my $self = shift;
    my( $vars, $prefix ) = @_;

    return unless $vars;
    $prefix ||= 'item';
    my @items;
    for( keys %$vars ) {
        next unless /^${ prefix }_(\d+)$/;
        push @items => $1;
    }
    \@items;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 send_file( \%args )

Object method.

Finds the file in C<< $args->{path} >> and send it to the browser with a header of
C<< $args->{mime_type} >> and a filename of C<< $args->{name} >>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub send_file {
    my $self = shift;
    my( $args ) = @_;

    die 'Path, MIME type, and file name are required'
        unless $args->{ path } and $args->{ mime_type } and $args->{ name };

    open FILE, $args->{ path }
        or die "Cannot open $$args{ path }: $!";

    $self->mime_type( $args->{ mime_type });
    my ($html, $headers) = $self->print_header( 'Content-Disposition' => qq/attachment; filename="$$args{ name }"/ );

    my $newbuf = "";
    my $buffer;
    $newbuf .= $buffer
        while read( FILE, $buffer, 32768 );
    close FILE;

    return ($newbuf, $headers);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 _get_rolodex()

Object method.

Looks for a C<rolodex_id> in the query string or session, and uses it to return
a L<eleMentalClinic::Rolodex> object.

TODO: these should be auto-generated, generalized, or B<something>.  Maybe even
manually created for each object.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub _get_rolodex {
    my $self = shift;

    my $id = $self->session->param( 'rolodex_id' )
            || $self->param( 'rolodex_id' );
    return unless $id;
    return eleMentalClinic::Rolodex->retrieve( $id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# this is only necessary because CGI::Session won't tell you if flush() fails
sub DESTROY {
    my $self = shift;

    $self->session->flush
        if $self->session;
    die 'CGI::Session error: ', CGI::Session->errstr
        if CGI::Session->errstr;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 make_select_options()

Makes an options hash suitable for consumption by util/select_new.html out of the passed rows of hashrefs (as would be delivered from a DBI data lookup).  List is sorted by option id.

make_select_options expects to be passed a hashref of parameters.

The allowed paramters are:

=over 4

=item rows (required)

Arrayref of row hashes to serve as the seed data.

=item id_column (required)

The column that is providing the id.

=item label_column (required)

The column that is providing the label.  Optionally, this may
be an array ref of column names if more than one column is 
needed to form the label.

=item label_separator (optional, default=', ')

If label_column is a list of columns, then label_separator will be used to separate them in the label.

=item id_key (optional, default='id')

The key for the id in the returned options (what the option will return).

=item label_key (optional, default='label');

The key for the label in the returned options (what the option will display).

=back

=cut

sub make_select_options {
    my $self = shift;
    my( $params ) = @_;

    die 'make_select_options expects a hashref of parameters'
        unless ref $params eq 'HASH';
    my $rows = $params->{rows};
    my $id_column = $params->{id_column};
    my $label_column = $params->{label_column};
    die 'Rows, id and label column parameters required.'
        unless ref $rows eq 'ARRAY' && $id_column && $label_column;
    my @label_columns = ref $label_column eq 'ARRAY' ? @$label_column : ( $label_column );
    my $label_separator = $params->{label_separator} || ', ';
    my $id_key = $params->{id_key} || 'id';
    my $label_key = $params->{label_key} || 'label';

    my $options = [];
    foreach my $row (@$rows) { 
        
        my $label = join $label_separator, (map $row->{$_}, @label_columns);
        my $option = { $id_key => $row->{$id_column}, $label_key => $label };
        push @$options,  $option ;
    }

    return [ sort { $a->{$id_key} <=> $b->{$id_key} } @$options ];
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 log_error()

Object method.  Logs an error, using the Apache request.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub log_error {
    my $self = shift;
    my( $error ) = @_;

    $error = Dumper $error;
    $error = <<EOT;
# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
$error
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EOT
    $self->request->log_error( $_ ) for split /\n/ => $error;
}

=head2 uri

=head2 uri_with

    my $uri = $cgi->uri;

    my $new_uri = $cgi->uri_with({ foo => 17 });

Return a new copy of the current request's URI, possibly with some changes.
C<uri_with> uses L<URI::QueryParam> internally and takes the same arguments as
L<URI::QueryParam/query_form_hash>, with one important difference; any keys
whose value is C<undef> are deleted.

=cut

sub uri {
    my $self = shift;
    URI->new( $self->validop->cgi_object->self_url );
}

sub uri_with {
    my $self = shift;
    my ( $vars ) = @_;
    local $URI::DEFAULT_QUERY_FORM_DELIMITER = ';';
    my $uri = $self->uri;
    my %param = (
        %{ $uri->query_form_hash },
        %$vars,
    );
    defined $param{$_} && length $param{$_} or delete $param{$_}
        for keys %param;
    $uri->query_form(\%param);
    return $uri;
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

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
