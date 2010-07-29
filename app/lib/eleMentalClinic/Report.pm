# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Report

=head1 SYNOPSIS

All reports.

=head1 METHODS

=cut

use Moose;
use MooseX::ClassAttribute;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use Module::Pluggable::Object;

use eleMentalClinic::Client;
use eleMentalClinic::Client::Insurance;
use eleMentalClinic::Client::Insurance::Authorization;
use eleMentalClinic::ValidData;
use eleMentalClinic::Department;
use eleMentalClinic::Util;
use eleMentalClinic::Mail;
use Date::Calc qw/ check_date Add_Delta_Days Days_in_Month /;
use namespace::clean -except => 'meta';

# namespace::autoclean would remove these; suffer through it for now
use eleMentalClinic::Base::Globals -all;
use eleMentalClinic::Base::Time -all;

class_has plugins => (
    is      => 'ro',
    isa     => ArrayRef[ClassName],
    default => sub {
        my $mpo = Module::Pluggable::Object->new(
            search_path => [ 'eleMentalClinic::Report::Plugin' ],
            require     => 1,
        );
        [ $mpo->plugins ];
    },
    auto_deref => 1,
);

for my $report_type (qw(client site financial)) {
    class_has "$report_type\_report" => (
        is => 'ro',
        isa => ArrayRef[
            Dict[
                name => Str,
                label => Str,
                admin => Bool,
            ],
        ],
        lazy => 1,
        default => sub {
            [
                map { $_->as_hash_for_list }
                sort { $a->label cmp $b->label }
                grep { $_->type eq $report_type }
                __PACKAGE__->plugins
            ]
        },
    );
}

has _report_name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    init_arg => 'name',
);

has args => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => undef,
    writer   => '_set_args',
);

# XXX horrible attribute name
has data => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    default  => sub { shift->report->result },
);

has report_class => (
    is         => 'ro',
    isa        => ClassName,
    lazy_build => 1,
);

has report => (
    is         => 'ro',
    does       => 'eleMentalClinic::Report::Plugin',
    lazy_build => 1,
    handles    => [qw( name label admin )],
);

sub BUILD {
    my ($self, $args) = @_;
    delete $args->{name};
    $self->_set_args($args);
    # eager build so that it dies on object construction if the report is
    # invalid
    $self->report;
}

sub report_class_named {
    my ($class, $name) = @_;
    my ($plugin) = grep { $_->name eq $name } $class->plugins;
    die "No report class found for '$name'" unless $plugin;
    return $plugin;
}

sub _build_report_class {
    return $_[0]->report_class_named( $_[0]->_report_name );
}

sub _build_report {
    return $_[0]->report_class->new( $_[0]->args );
}

sub run_report {
    my ($class, $name, $args) = @_;
    $class = blessed( $class ) || $class;
    $args ||= {};
    return $class->new({ name => $name, %$args })->report->result;
}

for my $report_class (__PACKAGE__->plugins) {
    my $name = $report_class->name;
    next if __PACKAGE__->can($name);
    __PACKAGE__->meta->add_method(
        $name,
        sub { $_[0]->run_report($name, $_[1]) },
    );
}

=head2 with_data

  my $report = $thing->get_report->with_data;

Run the report and get its data, returning the report with data already loaded.

Use this instead of just C<< $report->data >> when you want to make sure a
report has already run before passing to a template, e.g. for more convenient
error handling.

=cut

sub with_data { $_[0]->data; $_[0] }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _time_unit_calc {
    my( $formatted, $duration ) = @_;
    my $total_minutes;

    return '00:00' unless $duration;

    # TODO this should be added, but I'm not testing it now
    # return '00:00' unless $duration or $formatted;
    # return $formatted unless $duration;
    
    my( $minutes, $hours, $days ) = ( 0,0,0 );
    if( $formatted ) {
        ( $minutes, $hours, $days ) = reverse split ':', $formatted;
        $days ||= 0;
        $total_minutes = ($days * 86400) + ($hours * 3600) + ($minutes * 60);
    }

    $total_minutes += $duration;

    $days = int $total_minutes / 86400;
    $total_minutes = $total_minutes % 86400;
    
    $hours = int $total_minutes / 3600;
    $hours = $hours + $days * 24;
    $total_minutes = $total_minutes % 3600;

    $minutes = $total_minutes / 60;

    my $result = sprintf '%02d:%02d', $hours, $minutes;
   
    return $result;
}

# XXX make tests pass (for now)
sub _verifications_by_index_date {
    shift->eleMentalClinic::Report::Plugin::VerificationExpirations::_verifications_by_index_date(@_);
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
