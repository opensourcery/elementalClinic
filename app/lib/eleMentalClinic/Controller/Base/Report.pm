# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Controller::Base::Report;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Report

=head1 SYNOPSIS

Base Report Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Client;
use eleMentalClinic::Personnel;
use eleMentalClinic::Report;
use Moose::Util qw(find_meta);
use MooseX::Types::Moose qw(:all);
use namespace::autoclean;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    my $track = $self->param( 'report_track' );
    $self->security( 'reports' ) unless $track and $track eq 'client';
    $self->template->vars({
        script => 'report.cgi',
        styles => [ $self->styles ],
        use_new_date_picker => 1,
    });
    return $self;
}

sub styles { qw(layout/3366 report) }

sub report_styles { qw(layout/00 report email_report) }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        run_report => {
            start_date  => [ 'Start date', 'date::iso' ],
            end_date    => [ 'End date', 'date::iso' ],
            expires_in_days => [ 'Expires in days', 'number::integer', 'length(0,9)' ],
            schedule_id => [ 'ScheduleID', 'number::integer' ],
            zip_code => ['Zip code', 'number::integer'],
            area_code => ['Area code', 'number::integer'],
            state => ['State', 'demographics::us_state2' ],
        },
    )
}


# Populate the template with useful information for configuring a report.
sub home {
    my $self = shift;

    my $report_name = $self->param( 'report_name' );
    my $report_class;
    if ( $report_name ) {
        # TT doesn't seem to like calling class methods
        $report_class = $self->_report_class->as_hash_for_list;
    }

    # in case we were called from somewhere else
    $self->override_template_name( 'home' );

    return {
        client       => $self->client,
        data         => $report_name &&
                        $self->can( $report_name ) &&
                        $self->$report_name,
        report       => $report_class,
        report_track => $self->report_track,
        report_list  => $self->report_list,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ins_reauth {
    eleMentalClinic::Rolodex->new->list_byrole( 'mental_health_insurance' );
}


sub _get_all_treaters {
    return eleMentalClinic::Rolodex->new->get_byrole('treaters');
}


sub client_intake_forms {
    my $self = shift;
    return $self->attending_physician_statement;
}


# Extra data for configuring AttendingPhysicianStatement
sub attending_physician_statement {
    my $self = shift;

    return {
        treaters => $self->_get_all_treaters
    }
}


# Extra data for configuring MedicalRelease
sub medical_release {
    my $self = shift;

    return {
        treaters => $self->_get_all_treaters
    }
}


# Extra data for configuring ReviewPatientRecords
sub review_patient_records {
    my $self = shift;

    return {
        treaters => $self->_get_all_treaters
    }
}


# Extra data for configuring PhysicalExam
sub physical_exam {
    my $self = shift;

    return {
        treaters => $self->_get_all_treaters
    }
}



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_termination {
    my $self = shift;

    my @discharges;
    for my $episode( @{ $self->client->placement->episodes }) {
        next unless $episode->discharge and $episode->discharge->committed;
        push @discharges => $episode->discharge_date;
    }
    return \@discharges
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub site_prognote {
    my $self = shift;

    my $staff = eleMentalClinic::Department->new->get_writers;
    return {
        clients => eleMentalClinic::Client->new->get_all,
        staff   => $staff,
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub site_prognote_caseload {
    my $self = shift;

    { staff => eleMentalClinic::Department->new->get_service_coordinators }
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_prognote {
    my $staff = eleMentalClinic::Department->new->get_writers;
    return {
        clients => eleMentalClinic::Client->new->get_all,
        staff   => $staff,
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub last_visit_bystaff {
    my $self = shift;
    $self->staff_list;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_list {
    my $self = shift;
    $self->staff_list;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub appointments {
    my $self = shift;
    return {
        users => [ 'All Users', map { $_->login } @{ eleMentalClinic::Personnel->new->get_all }],
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub email {
    my $self = shift;
    return {
        clients => [ { name => 'ALL' }, @{eleMentalClinic::Client->get_all} ],
        'sort' => [qw/ date client address /],
        order => [
            {
                val => 'Ascending',
                key => 'ASC',
            },
            {
                val => 'Descending',
                key => 'DESC',
            }
        ],
        parts => [ qw/ subject body address /],
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub security_log {
    return {
        users => [ 'All Users', map { $_->login } @{ eleMentalClinic::Personnel->new->get_all }],
        'sort' => [
            {
                val => 'Ascending',
                key => 'ASC',
            },
            {
                val => 'Descending',
                key => 'DESC',
            },
        ],
        order => [
            {
                field => 'logged',
                label => 'Date/Time',
            },
            {
                field => 'login',
                label => 'Login Name',
            },
            {
                field => 'action',
                label => 'Event Type',
            },
        ],
        actions => [
            {
                action => 'login',
                label  => 'Login',
            },
            {
                action => 'logout',
                label  => 'Logout',
            },
            {
                action => 'failure',
                label  => 'Failed Login Attempt',
            },
        ],
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub access {
    my $self = shift;
    my $types = [{ name => 'All', class => '' }];
    for my $row ( @{ $self->access_distinct( 'object_type' )}) {
        my $class = $row->{object_type};
        my $name = $class;
        $name =~ s/^.*:://g;
        push( @$types, { name => $name, class => $class });
    }
    my $users = [{ name => 'All', id => '' }];
    for my $row ( @{ $self->access_distinct( 'staff_id' )}) {
        next unless my $id = $row->{staff_id};
        my $staff = eleMentalClinic::Personnel->retrieve( $id );
        push( @$users, { name => $staff->name, id => $id });
    }
    return {
        view_by => [ 'Session', 'Day', 'All Together' ],
        types => $types,
        users => $users,
    };
}

sub access_distinct {
    my $self = shift;
    my ( $field ) = @_;
    my $access_log_table = eleMentalClinic::Log::Access->table;
    return $self->db->do_sql( "SELECT DISTINCT $field FROM " . $access_log_table );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub encounter {
    my $self = shift;
    $self->staff_list;
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub staff_list {
    my $self = shift;
    if( $self->_report_class->admin and not $self->current_user->admin ){
        return [
            {
                name => $self->current_user->fname . ' ' . $self->current_user->lname,
                staff_id => $self->current_user->staff_id,
            }
        ];
    }
    else {
        return eleMentalClinic::Department->new->get_writers;
    }
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub clinic_schedule {
    my $self = shift;

    return $self->db->do_sql(qq%
        select schedule_availability.rec_id as sched_id,
        to_char(date,'Day') || to_char(date,'MM/DD/YY') || ' | ' || description || ' | ' || lname as details
        from schedule_availability, rolodex,valid_data_prognote_location
        where rolodex.rec_id = schedule_availability.rolodex_id
        and valid_data_prognote_location.rec_id = schedule_availability.location_id
        order by date desc, lname, description% );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_rolodex_name {
    my $self = shift;
    my( $rolodex_id ) = @_;
    eleMentalClinic::Rolodex->new({ rec_id => $rolodex_id })->retrieve->name;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_staff_name {
    my $self = shift;
    my( $staff_id ) = @_;
    eleMentalClinic::Personnel->new({ staff_id => $staff_id })->retrieve->name;
}

# TODO: refactor this
my %moose_to_validop = (
    Str => 'text::hippie',
    Int => 'number::integer',
);

sub get_all_ops {
    my ( $self, $cgi ) = @_;
    my %ops = $self->SUPER::get_all_ops( $cgi );
    return %ops unless $cgi and
        my $report_name = $cgi->param( 'report_name' );
    my $meta = find_meta(
        eleMentalClinic::Report->report_class_named( $report_name )
    );
    for my $attr ($meta->get_all_attributes) {
        next if $attr->name eq 'result';
        next unless $attr->has_type_constraint;
        next unless my $key = $attr->init_arg;
        my $tc = $attr->type_constraint;
        my $value = [ $attr->label ];
        if ($attr->is_required) {
            push @$value, 'required';
        }
        if ($moose_to_validop{$tc->name}) {
            push @$value, $moose_to_validop{$tc->name}
        } else {
            $value = [];
            warn "unhandled type constraint for $key: " . $tc->name;
        }

        #print STDERR "$key = @$value\n";
        $ops{run_report}{$key} = $value if @$value;
    }
    return %ops;
}


# Run and display the report
sub run_report {
    my $self = shift;
    my $type = $self->report_track;
    #my $report_track = $self->param( 'report_track' );
    my $report_name = $self->param( 'report_name' );
    my $vars = $self->Vars;

    $vars->{rolodex_name} = $self->Vars->{rolodex_id}
        ? $self->get_rolodex_name( $self->Vars->{rolodex_id})
        : undef;

    $vars->{staff_name} = $self->Vars->{staff_id}
        ? $self->get_staff_name( $self->Vars->{staff_id})
        : undef;

    $vars->{staff_name} = $self->Vars->{writer} if $self->Vars->{writer};
    $vars->{client_id} = $self->client if $self->client;

    $self->date_check( 'start_date', 'end_date' );
    for ( qw/ start_date end_date date /) {
      $vars->{$_ . "_facade"} ||= eleMentalClinic::Util::format_date( $vars->{$_} )
        if ( $vars->{$_} );
    }

    return $self->home if $self->errors;

    # get data so that explosions come from here instead of from the template
    my $report = $self->get_report->with_data;

    $self->template->vars({
        styles => [ $self->report_styles ],
        javascripts => [ 'email_report.js' ],
        print_styles => [ 'report_print_new', 'progress_note_print' ],
    });
    $self->template->process_page( 'report/display', {
        report  => $report,
        report_template => "report/$type/$report_name\_display.html",
        %$vars,
    });
}

=head2 get_report

Returns a new L<eleMentalClinic::Report> object for the current theme.

=cut 

sub get_report {
    my $self = shift;
    my $vars = $self->Vars || {};
    delete $vars->{$_} for grep { ! defined $vars->{$_} } keys %$vars;
    return eleMentalClinic::Report->new({
        %$vars,
        name => $self->param( 'report_name' ),
    });
}

=head2 report_track

Returns a string describing the type of report desired: 'client' or 'site'.

=cut

sub report_track {
    my $self = shift;

    return $self->param( 'report_track' ) || 'site';
}

=head2 report_list

    my $reports = $self->report_list($report_track);

Return a list of reports (from L<eleMentalClinic::Report>), filtered through
the theme's available reports and the report configuration.

=cut

sub report_list {
    my $self = shift;

    my %available = map { $_ => 1 } @{
        eleMentalClinic::Theme->new->available_reports(
            $self->report_track
        )
    };
    my $method = $self->report_track . '_report';
    my @reports = @{ eleMentalClinic::Report->$method };
    return [
        grep {
            $available{ $_->{name} }
        } @reports
    ];
}

sub _report_class {
    my $self = shift;
    return unless my $name = $self->param( 'report_name' );
    return eleMentalClinic::Report->report_class_named( $name );
}

1;

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

Copyright (C) 2004-2008 OpenSourcery, LLC

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
