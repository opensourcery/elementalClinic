# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
package eleMentalClinic::Controller::Base::ValidData;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::ValidData

=head1 SYNOPSIS

Base ValidData Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use Data::Dumper;
use eleMentalClinic::Lookup::Group;
use eleMentalClinic::Lookup::ChargeCodes;
use eleMentalClinic::Rolodex;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        save_item => {
            name => [ 'Name', 'required' ],
            active  => [ 'Active', 'checkbox::boolean' ],
            code => [ 'Code', 'length(0,3)'], # XXX two valid_data tables have 'code' columns, one has max 2 chars, one has max 3 chars
            visit_frequency => [ 'Visit Frequency', 'number::integer' ],
            number => [ 'Number', 'number::integer' ],
            is_married  => [ 'Married', 'checkbox::boolean' ],
            is_referral  => [ 'Referral', 'checkbox::boolean' ],
            facility_code => [ 'Facility Code', 'number::integer', 'length(0,2)'],
            min_allowable_time => [ 'Min allowable time', 'number::decimal' ],
            max_allowable_time => [ 'Max allowable time', 'number::decimal' ],
            minutes_per_unit => [ 'Minutes per unit', 'number::decimal' ],
            dollars_per_unit => [ 'Dollars per unit', 'number::decimal' ],
            max_units_allowed_per_encounter => [ 'Max units allowed per encounter', 'number::integer' ],
            max_units_allowed_per_day => [ 'Max units allowed per day', 'number::integer' ],
            is_default => [ 'Default', 'checkbox::boolean' ],
        },
        group_save => {
            -alias  => 'Save group',
            name    => [ 'Group name', 'required' ],
        },
        edit_item => {},
        filter_by_group => {},
        group_new => {
            -alias  => 'New group',
        },
        associate => {},
        associations_save => {
            -alias  => 'Save associations',
        },
        insurer_association_save => {
            rolodex_id          => [ 'Insurer', 'required' ],
            insurer_dollars_per_unit    => [ 'Dollars', 'number::decimal'],
            insurer_max_units_allowed_per_day   => [],
            insurer_max_units_allowed_per_encounter => [],
            insurer_acceptable => [ 'Acceptable',, 'required', 'number::integer' ],
        },
        show_groups => {},
        show_insurers => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles  => [ 'layout/00', 'valid_data' ],
        script  => 'valid_data.cgi',
    });
    $self;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $vars ) = @_;

    $vars = $self->get_common_vars( $vars );
    if( $self->op eq 'group_new' or( $self->op eq 'group_save' and $self->errors )) {
        my $new_group_stub = { name => 'New Group Name' };
        unshift @{ $vars->{ lookup_groups }} => $new_group_stub;
        $vars->{ current_group } = $new_group_stub;
    }
    $self->template->process_page( 'lookup/home', $vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_item {
    my $self = shift;

    if( $self->errors ) {
        return $self->edit_item({ $self->Vars });
    }

    my $table_name = $self->param( 'table_name' );
    my $return = $self->current_user->valid_data->copy_and_save(
      $table_name, { $self->Vars }
    );
    my $message = $return
        ? 'Save successful.'
        : 'Save failed.';
    $self->home({ message => $message });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_save {
    my $self = shift;

    my $group_id = $self->param( 'group_id' );
    my $group_name = $self->param( 'name' );
    my $system = 0;

    # test if the incoming group is a system group.  if so, don't let the
    # name be changed, and preserve the 'system' property
    if( $group_id ) {
        my $test_group = eleMentalClinic::Lookup::Group->new({
            rec_id      => $self->param( 'group_id' ),
        })->retrieve;
        if( $test_group->system ) {
            $group_name = $test_group->name;
            $system = 1;
        }
    }

    my $group = eleMentalClinic::Lookup::Group->new({
        name        => $group_name,
        rec_id      => $group_id,
        parent_id   => $self->param( 'table_id' ),
        active      => 1,
        system      => $system,
    });

    $self->add_error( 'name', 'name', 'Another group in this table already has that name; please use another.' )
        if $group->name_is_dup;

    unless( $self->errors ) {
        $group->save;
        $group->set_members( $self->get_item_ids({ $self->Vars }));

        # XXX is this even possible?
        $self->add_error( 'name', 'name', 'Save failed.' )
            unless $group->id;
        $self->home({ current_group => $group });
    }
    else {
        $self->home({ $self->Vars, current_group => $group });
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub filter_by_group {
    my $self = shift;
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub group_new {
    my $self = shift;
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit_item {
    my $self = shift;
    my( $item ) = @_;

    # TODO should be in get_common
    $item ||= $self->current_user->valid_data->get(
        $self->param( 'table_name' ),
        $self->param( 'rec_id' )
    );
    $self->home({ current_item => $item, edit => 1 });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub associate {
    my $self = shift;
    my( $vars ) = @_;

    $vars = $self->get_common_vars( $vars );
    $self->template->process_page( 'lookup/associate_home', $vars );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub associations_save {
    my $self = shift;

    my $vars = $self->get_common_vars;
    unless( $self->errors ) {
        my $group = $vars->{ associate_current_group };
        $group->set_lookup_associations(
            $vars->{ current_table }{ rec_id },
            $self->get_item_ids({ $self->Vars })
        );
    }
    # TODO return all vars to form so we have item ids on error
    $self->associate;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub insurer_association_save {
    my $self = shift;

    my $charge_code = $self->current_user->valid_data->get(
        $self->param( 'table_name' ),
        $self->param( 'rec_id' )
    );
    unless( $self->errors ) {
        my $insurer = $self->_get_rolodex;

        my $vars = $self->Vars;
        my %insurer_code = ();
        while( my( $key, $value ) = each %$vars ) {
            next unless 
                $key =~ s/^insurer_//;
            $insurer_code{ $key } = $value;
        }

        my $return = eleMentalClinic::Lookup::ChargeCodes->insurer_charge_code_save(
            $insurer->id,
            $self->param( 'rec_id' ),
            \%insurer_code
        );
        print STDERR Dumper[ $return, \%insurer_code ];
    }
    $self->home({ current_item => $charge_code, edit => 1 });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub show_groups {
    my $self = shift;

    $self->session->param( aux_tab => 'groups' );
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub show_insurers {
    my $self = shift;

    $self->session->param( aux_tab => 'insurers' );
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get data common to several runmodes; preserve incoming variables, if any
sub get_common_vars {
    my $self = shift;
    my( $incoming ) = @_;

    $incoming ||= {};
    my %vars = ();
    $vars{ aux_tab } = $self->session->param( 'aux_tab' ) || 'groups';

    $vars{ current_table } = $self->current_user->valid_data->get_table( $self->param( 'table_name' ));
    $vars{ lookup_groups } = eleMentalClinic::Lookup::Group->new->get_by_table( $vars{ current_table }{ rec_id })
        if $vars{ current_table } and $vars{ aux_tab } eq 'groups';
    $vars{ insurers } = eleMentalClinic::Rolodex->new->get_byrole( 'mental_health_insurance' )
        if $vars{ aux_tab } eq 'insurers';
    $vars{ current_insurer } = $self->_get_rolodex;

    # for editing
    my $group_id = $self->param( 'group_id' );
    undef $group_id
        unless $group_id and $group_id =~ /^\d*$/;

    $vars{ current_group } = eleMentalClinic::Lookup::Group->new({ rec_id => $group_id })->retrieve
        if $group_id;

    $vars{ associate_table } =
        $self->current_user->valid_data->get_table( $self->param( 'associate_table_name' ));
    # gets all groups except for system groups ( which at this point
    # means "Global" ) -- associating a lookup item with "Global" is
    # pointless, and has no effect, so we don't give them the option
    $vars{ associate_lookup_groups } = eleMentalClinic::Lookup::Group->new->get_by_table(
            $vars{ associate_table }{ rec_id },
            { system => 0 },
    )
        if $vars{ associate_table };

    # for associations
    my $associate_group_id = $self->param( 'associate_group_id' );
    if( $associate_group_id ) {
        my $group = eleMentalClinic::Lookup::Group->new({ rec_id => $associate_group_id })->retrieve;
        $vars{ lookup_associations_hash } =
            $group->lookup_associations_hash( $vars{ current_table }{ rec_id });
        $vars{ associate_current_group } = $group;
    }

    %vars = ( %vars, %$incoming );
    \%vars;
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
