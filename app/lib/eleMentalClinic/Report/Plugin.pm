# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin;

use MooseX::Role::Parameterized;
use eleMentalClinic::DB;
use namespace::autoclean;

requires 'build_result';

parameter result_isa => (
    required => 1,
    isa      => 'Moose::Meta::TypeConstraint',
);

parameter type => (
    required => 1,
    isa      => 'Str',
);

parameter label => (
    required => 1,
    isa      => 'Str',
);

parameter admin => (
    isa      => 'Bool',
    default  => 0,
);

parameter op => (
    isa         => 'Str',
    default     => 'run_report',
    required    => 1,
);

sub db { eleMentalClinic::DB->new }

sub name {
    my ($self_or_class) = @_;
    my $class = blessed $self_or_class || $self_or_class;
    my $tail = (split /::/, $class)[-1];
    return join(
        '_', map { lc }
        split /(?<=\p{IsLower})(?=\p{IsUpper})/, $tail
    );
}

sub as_hash_for_list {
    my ($self) = @_;
    return { map {; $_ => $self->$_ } qw(name label admin op) };
}

sub report_args {
    my ($self) = @_;
    my %args;
    for my $attr ($self->meta->get_all_attributes) {
        next if $attr->name eq 'result';
        next unless $attr->init_arg;
        $args{$attr->name} = $attr->get_value($self);
    }
    return \%args;
}

role {
    my $p = shift;
    has result => (
        is      => 'ro',
        isa     => $p->result_isa,
        lazy    => 1,
        builder => 'build_result',
    );

    for my $method (qw( label admin type op )) {
        my $value = $p->$method;
        method $method => sub { $value };
    }
};


=head1 NAME

eleMentalClinic::Report::Plugin - Role to write new reports

=head1 DESCRIPTION

This is a role used to write new reports.

=head1 Requires

The role requires you implement the following method.

=head3 build_result

    my $result = $self->build_result;

Called by the report controller to get the data to be used in the
report.  The return value is used as the variable cunningly named
C<data> in your template.

Its return value must match the type of C<result_isa>.

=head1 Parameters

=head3 admin

Set true if this template is available only to administrators.

Default false.

=head3 label

The name of this report to be presented to the user.

Required, has no default.

=head3 op

The Report Controller method which will be called to generate the report.

Defaults to "run_report"

=head3 result_isa

The Moose type returned by C<build_result>.

Required, has no default.

=head3 type

The type or report this is.  Determines where on the site the report will appear.

Currently has two values.  C<client> is a report on a particular
client.  C<site> is a report about no one thing in particular.

Required, has no default.


=head1 Adding a new report

=head2 Writing the plugin

=head3 Use the eleMentalClinic::Report::Plugin role

You must give it a type and label.

    package eleMentalClinic::Report::Plugin::ClientCoffee;

    use Moose;
    use eleMentalClinic::Report::Labelled;
    use namespace::autoclean;

    with "eleMentalClinic::Report::Plugin" => {
        type   => "client",
        label  => "Cups of Coffee Per Hour"
    };


=head3 Write build_result()

Write a build_result() method.  It takes no arguments and returns
whatever data structure you want to have available as variables to the
template.  It will be available as "data".


=head2 Write your templates

The templates are Template Toolkit templates

=head3 Naming style

A plugin called C<Plugin::ClientCoffee> will use a template called
C<client_coffee>.  Its all lower cased and the CamelCasing is converted to
underscores.

=head3 Configuration template

The template for configuring a report, choosing options and such, is
F<$type/${name}.html>.  So if C<Plugin::ClientCoffee> is a C<client> type
then it has a template called F<client/client_coffee.html>.


=head3 Additional configuration variables

Additional variables can be passed to the configuration template by
defining a subroutine with the same name as the report's template in
C<eleMentalClinic::Controller::Base::Report> (or a theme specific
subclass).  So C<ClientCoffee> would define C<sub client_coffee>.

This method returns a data structure which will be available as
C<data> in the template.  For example:

    sub client_coffee {
        return {
            styles => ["cold press", "french press", "vacuum press"],
        }
    }

This would make C<data.styles> available to the configuration template
F<client_coffee.html>.

(Yes, this method should probably go in the plugin and not the controller)


=head3 Display template

The template for actually displaying the report is
F<$type/${name}_display.html>.  So if C<Plugin::ClientCoffee> is a C<client>
type then it has a template called F<client/client_coffee_display.html>.

=head3 Variables available to the template

To be written.


=head2 Add your report to the config files

=head3 Global config

Your report must be added to a few configuration files.

F<etc/report.yaml> contains a global list of allowed reports.  The
name used here is the same as the templates.  C<ClientCoffee> is
entered as C<client_coffee>.  The type is ignored here.

=head3 Theme config

Each theme has its own config file for what reports will be available.
You must add your new report to the theme(s) you want it to show up
in.

F<themes/$theme/theme.yaml> contains a theme's configuration.  Unlike
the global config, this does take the type into account.  So the name
of the report here is C<$type/$name>.  C<ClientCoffee> of the
C<client> type would be C<client/client_coffee>.

=cut

1;
