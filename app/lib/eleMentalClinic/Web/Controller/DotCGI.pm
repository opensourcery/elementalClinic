# vim: ts=4 sts=4 sw=4:
package eleMentalClinic::Web::Controller::DotCGI;

use base 'Catalyst::Controller::WrapCGI';
use Moose;
has context => (
    is       => 'rw',
    isa      => 'eleMentalClinic::Web',
);
sub ACCEPT_CONTEXT { $_[0]->context( $_[1] ); $_[0] }

use CGI ();
use eleMentalClinic::Theme;
use eleMentalClinic::Config;
use eleMentalClinic::DB;
use eleMentalClinic::Watchdog;
use Encode ();

my %dispatch = (
    about                       => 'About',
    admin                       => 'Admin',
    admin_assessment_templates  => 'AdminAssessmentTemplates',
    ajax                        => 'Ajax',
    allergies                   => 'Allergies',
    appointments                => 'Appointments',
    assessment                  => 'Assessment',
    calendar                    => 'Calendar',
    clientoverview              => 'ClientOverview',
    client_filter               => 'ClientFilter',
    client_scanned_record       => 'ClientScannedRecord',
    clientpermissions           => 'ClientPermissions',
    configurable_assessment     => 'ConfigurableAssessment',
    demographics                => 'Demographics',
    diagnosis                   => 'Diagnosis',
    discharge                   => 'Discharge',
    entitlements                => 'Entitlements',
    error_page                  => 'Error',
    financial                   => 'Financial',
    group_notes                 => 'GroupNotes',
    groups                      => 'Groups',
    help                        => 'Help',
    hospitalizations            => 'Inpatient',
    income                      => 'Income',
    insurance                   => 'Insurance',
    intake                      => 'Intake',
    login                       => 'Login',
    legal                       => 'Legal',
    letter                      => 'Letter',
    menu                        => 'Menu',
    personnel                   => 'Personnel',
    placement                   => 'Placement',
    prescription                => 'Prescription',
    progress_notes              => 'ProgressNote',
    progress_notes_charge_codes => 'ProgressNotesChargeCodes',
    report                      => 'Report',
    roi                         => 'ROI',
    rolodex                     => 'Rolodex',
    rolodex_cleanup             => 'RolodexCleanup',
    rolodex_filter_roles        => 'RolodexFilter',
    schedule                    => 'Schedule',
    security_page               => 'SecurityError',
    set_treaters                => 'TreaterSet',
    scanned_record              => 'ScannedRecord',
    test                        => 'Test',
    treatment                   => 'Treatment',
    user_prefs                  => 'PersonnelPrefs',
    valid_data                  => 'ValidData',
    verification                => 'Verification',
    notification                => 'Notification'
);

sub emc_theme {
    my $self = shift;
    return $self->emc_config->Theme;
}

sub emc_config {
    my $self = shift;
    my $config = eleMentalClinic::Config->new;
    $config->request($self->context->apache) if $self->context->can('apache');
    return $config;
}

sub emc_db {
    return eleMentalClinic::DB->new;
}

sub controller_name_for {
    my ($self, $script) = @_;

    return $self->emc_theme->theme_index || 'PersonnelHome'
        if $script eq 'index';

    return $dispatch{$script};
}

sub controller_for {
    my ($self, $script) = @_;
    return unless my $name = $self->controller_name_for( $script );
    return unless my $class = $self->emc_theme->controller_can( $name );
    return $class;
}

sub res : Regex(^res/(\w+)/(.+)) {
    my ($self, $c) = @_;
    my ($theme_name, $file_path) = @{ $c->req->captures };
    my $file = $self->emc_theme->resource_path( $file_path );
    unless ( $file ) {
        $c->response->status(404);
        $c->response->body('not found');
        return;
    }
    $c->serve_static_file( $file );
    if ( $c->response->status == 404 ) {
        $c->response->body('not found');
        $c->response->content_type('text/plain');
    }
}

sub venus_login : Path(/login/login.cgi) {
    my ($self, $c) = @_;
    $c->go('/dotcgi/login_cgi');
}

for my $cgi ('index', keys %dispatch) {
    eval sprintf <<'END',
    sub %s_cgi : Path(/%s.cgi) { shift->run_cgi(%s => @_) }; 1;
END
        $cgi, $cgi, $cgi
        or die "Can't create action for $cgi: $@";
}

sub error_page : Path(/error.cgi) {
    my ($self, $c) = @_;
    $self->run_cgi( 'error_page', $c );
}

sub security_page : Path(/securityerror.cgi) {
    my ($self, $c) = @_;
    $self->run_cgi( 'security_page', $c );
}

sub index : Path(/) {
    my ($self, $c) = @_;
    $c->go('/dotcgi/index_cgi');
}

sub run_cgi {
    my ($self, $cgi_name, $c) = @_;
    my $controller_class = eval { $self->controller_for( $cgi_name ) };

    if ( my $error = $@ ) {

        # Loop prevention if error_page controller fails.
        if ( $cgi_name eq 'error_page' ) {
            print STDERR "$error\n";
            $c->response->status(500);
            $c->response->body('Internal Server Error');
            return;
        }

        # Otherwise throw an error
        return $self->throw(
            $c,
            'Controller Compile Error',
            $error,
            cgi_name => $cgi_name,
        );
    }

    # If the user tries to go to an invalid page.
    unless ( $controller_class ) {
        $c->response->status(404);
        $c->response->body('not found');
        return;
    }

    my $headers;
    my $path_query = $c->request->uri->path_query;
    # back compat with DispatchUtil::get_query_string
    $path_query =~ s{^/(\?|$)}{$1};

    # WrapCGI <= 0.0026 doesn't kill $ENV{MOD_PERL}, so this is a reasonable
    # workaround; later versions should have my patch that kills MOD_PERL by
    # default --hdp
    local $CGI::MOD_PERL = 0;

    $self->cgi_to_response( $c, sub {
        local $SIG{__DIE__} = sub {
            $c->log->error("@_");
        };
        local $SIG{__WARN__} = sub {
            $c->log->warn("@_");
        };

        # we don't upload any files, binary or not, so this isn't too dangerous
        local $CGI::PARAM_UTF8 = 1;

        my $cgi = CGI->new;
        use Data::Dumper;
        for my $key ( keys %$cgi ) {
#            print STDERR Dumper( $key, delete $cgi->{ $key }) if $key =~ m/^\./;
        }
        my $controller = eval {
            $controller_class->new({
                request    => $c->can('apache') && $c->apache,
                cgi_object => $cgi,
            });
        };
#       print STDERR Dumper( $controller );
        return $self->throw(
            $c,
            "Controller Init Error",
            ($@ || "Unknown error"),
            cgi_name => $cgi_name,
            controller_class => $controller_class
        ) if $@ || !$controller;

        $controller->catalyst_c( $c );

        my $watchdog = eleMentalClinic::Watchdog->new unless $self->emc_config->no_watchdog;
        if ( $watchdog ) {
            $watchdog->controller_class( $controller_class );
            $watchdog->start();
        }

        ( my $html, $headers ) = eval { $controller->run_cgi( $path_query ) };
        my $error = $@;
        $watchdog->clean_watchdog() if $watchdog;
        return $self->throw(
            $c,
            "Controller Runtime Error",
            $error,
            cgi_name => $cgi_name,
            controller_class => $controller_class
        ) if $error;

        print $cgi->header(-charset => 'UTF-8');
        print Encode::encode('utf-8', $html);
    } );

    my %override = map {; $_ => 1 } qw(
        content-type
    );
    for my $key ( keys %$headers ) {
        my @values = @{
            ref $headers->{$key} eq 'ARRAY'
            ? $headers->{$key}
            : [ $headers->{$key} ]
        };
        @values = map { $_->as_string } @values if $key eq 'Set-Cookie';
        my $method = $override{ lc $key } ? 'header' : 'push_header';
        $c->response->headers->$method( $key => \@values );
    }

    $c->response->status(302) if $c->response->header('Location');
}

sub throw {
    my $self = shift;
    my ( $c, $name, $exception, %params ) = @_;

    # If the error was catchable use it instead of the generic one.
    if ( my $file = eleMentalClinic::Log::ExceptionReport->message_is_catchable( $exception )) {
        push @{ $c->stash->{ _cgi_exceptions }}, $file;
        return $file;
    }
    else {
        my $report = eleMentalClinic::Log::ExceptionReport->new({
            catchable => 1,
            name => $name,
            message => $exception,
            params => \%params,
        });
        push @{ $c->stash->{ _cgi_exceptions }}, $report->save;
        return $report->file;
    }
}

sub end : Private {
    my ($self, $c ) = @_;

    my $exceptions = $c->stash->{ _cgi_exceptions } || [];
    if ( @$exceptions ) {
        my $page = ( grep { $_ =~ m/Security Violation/ } @$exceptions ) ? 'security_page'
                                                                         : 'error_page';

        if ( $self->emc_theme->controller_can( $dispatch{ $page })) {
            $self->$page( $c );
        }
        else {
            print STDERR join("\n", @$exceptions) . "\n";
        }
    }

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }

    $c->response->body('An error has occured.');

}


1;
