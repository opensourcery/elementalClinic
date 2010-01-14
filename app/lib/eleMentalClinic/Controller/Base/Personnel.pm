package eleMentalClinic::Controller::Base::Personnel;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Personnel

=head1 SYNOPSIS

Base Personnel Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Personnel;
use Data::Dumper;

my @SECURITY_ONLY = qw/ login password security /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'personnel.cgi',
        styles => [ 'layout/6633', 'personnel', 'date_picker' ],
        javascripts => [ qw(jquery.js personnel.js date_picker.js) ],
    });
    $self->security( 'admin' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias  => 'Cancel',
        },
        create => {
            -alias  => 'New person',
        },
        view => {
            -alias  => 'View person',
        },
        edit => {},
        edit_security => {
            -alias  => 'Edit security',
        },
        save => {
            fname   => [ 'First name', 'required', 'length(0,30)' ],
            mname   => [ 'Middle name', 'length(0,30)' ],
            lname   => [ 'Last name', 'required', 'length(0,30)' ],
            national_provider_id => [ 'National Provider ID', 'text', 'length(2,80)' ],
            taxonomy_code => [ 'Taxonomy Code', 'text', 'length(2,30)' ],
            medicaid_provider_number => [ 'Medicaid Provider Number', 'text', 'length(2,30)' ],
            medicare_provider_number => [ 'Medicare Provider Number', 'text', 'length(2,30)' ],
            hours_week => [ 'Hours/week', 'number::integer' ],
            ssn => [ 'Social Security number', 'demographics::us_ssn(integer)' ],
            dob => [ 'Birth date', 'date::iso(past)' ],
        },
        save_security => {
            -alias  => 'Save security',
            login   => [ 'Login name', 'text::word', 'length(3,24)' ],
            password => [ 'Password', 'text::liberal', 'length(6,24)' ],
            password2 => [ 'Verify password', 'text::liberal', 'length(6,24)' ],
            home_page_type  => [ 'Home page type', 'text::word' ],
            password_expired => [ 'Password Expired', 'checkbox::boolean' ],

            map { 'role_' . $_->id => [ $_->name, 'checkbox::boolean' ]}
                @{ eleMentalClinic::Personnel->security_roles }
        },
        supervision_save => {
            staff_id        => [ 'Staff', 'required', 'number::integer' ],
            supervisor_id   => [ 'Supervisor', 'number::integer' ],
        },
        charge_code_associations_save => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $person ) = @_;

    my %vars;
    $vars{ current_table } = $self->get_lookup_table;
    # gets all groups except for system groups ( which at this point
    # means "Global" ) -- associating a staff member with "Global" is
    # pointless, and has no effect, so we don't give them the option
    $vars{ lookup_groups } = eleMentalClinic::Lookup::Group->new->get_by_table(
        $vars{ current_table }{ rec_id },
        { system => 0 },
    );
    $vars{ current } ||= $person || $self->get_personnel;
    $self->override_template_name( 'home' );
    return \%vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
    my $self = shift;

    $self->override_template_name( 'home' );
    return {
        op => 'create',
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub view {
    my $self = shift;
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;
    $self->override_template_name( 'home' );
    return {
        op => 'edit',
        current => $self->get_personnel,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit_security {
    my $self = shift;
    $self->override_template_name( 'home' );
    return {
        op => 'edit_security',
        current => $self->get_personnel,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    my $personnel = $self->get_personnel;
    if ( $self->errors ) {
        $self->override_template_name( 'home' );
        return {
            op => 'create',
        };
    }

    my $vars = $self->Vars;
    for my $field ( @{ $personnel->fields }) {
        next unless exists $vars->{ $field };
        next if grep { $field eq $_ } @SECURITY_ONLY;
        my $value = $vars->{ $field };
        $personnel->$field( $value );
    }
    $personnel->unit_id( 1 ) unless $personnel->unit_id;
    $personnel->dept_id( 1001 ) unless $personnel->dept_id;
    $personnel->home_page_type( 'service_coordinator' )
        unless $personnel->home_page_type;
    $personnel->save;
    return $self->home( $personnel );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save_security {
    my $self = shift;

    $self->add_error( 'password', 'password', '<strong>Password</strong> and <strong>verify password</strong> must match.' )
        if(
            ( $self->param( 'password' ) or $self->param( 'password2' ))
            and( $self->param( 'password' ) ne $self->param( 'password2' ))
        );

    unless( $self->errors ) {
        my $person = $self->get_personnel;
        $person->login( $self->param( 'login' ));

        if( $self->param( 'password' )) {
            $person->password( $person->crypt_password(
                $person->login,
                $self->param( 'password' ),
            ));
        }

        $person->password_expired( $self->param( 'password_expired' ));

        for my $role (@{ $person->security_roles }) {
            my $value = $self->param( 'role_' . $role->id );

            my $action = $value ? 'add_member' : 'del_member';

            $role->$action( $person->primary_role );
        }

        $person->home_page_type( $self->param( 'home_page_type' ))
            if $self->param( 'home_page_type' );
        $person->save;
    }

    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub supervision_save {
    my $self = shift;

    my $person = $self->get_personnel;
    $person->supervisor_id( $self->param( 'supervisor_id' ) || 0 );
    $person->save;
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit_charge_codes {
    my $self = shift;
    return $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub charge_code_associations_save {
    my $self = shift;

    unless( $self->errors ) {
        my $person = $self->get_personnel;
        my $table = $self->get_lookup_table;
        $person->set_lookup_associations(
            $table->{ rec_id },
            $self->get_item_ids({ $self->Vars }, 'item' ),
            $self->get_item_ids({ $self->Vars }, 'sticky' ),
        );
    }
    $self->home;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_personnel {
    my $self = shift;
    eleMentalClinic::Personnel->new({
        staff_id => $self->param( 'staff_id' ) || undef
    })->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_lookup_table {
    my $self = shift;

    my $table_name = $self->param( 'table_name' ) || 'valid_data_charge_code';
    $self->current_user->valid_data->get_table( $table_name );
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
