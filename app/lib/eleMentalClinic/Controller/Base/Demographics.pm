# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Controller::Base::Demographics;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Demographics

=head1 SYNOPSIS

Base Demographics Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI::Rolodex /;
use eleMentalClinic::Client;
use eleMentalClinic::Client::Referral;
use eleMentalClinic::Rolodex;
use eleMentalClinic::Contact::Address;
use eleMentalClinic::Contact::Phone;
use Data::Dumper;
use Scalar::Util qw(blessed);

# this isn't very robust, but it can be replaced once Moose is hooked deeper
# into emC's guts.
sub clone {
    my $self = shift;
    return bless { %$self, @_ }, blessed $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ 'layout/6633', 'demographics' ],
        javascripts => [ 'jquery.js', 'demographics.js' ],
        script => 'demographics.cgi',
        use_new_date_picker => 1,
    });
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {
            -alias => 'Cancel',
        },
        edit => {
            -alias => 'Edit',
        },
        save => {
            -alias => 'Save Client',
            -on_error => 'edit',
            client_id           => [ 'Client', 'required' ],
            ssn                 => [ 'Social Security number', 'demographics::us_ssn(integer)' ],
            dob                 => [ 'Birthdate', 'date::iso(past,present)' ],
            aka                 => [ 'Alias', 'length(0,25)' ],
            state_specific_id   => [ 'CPMS', 'number' ],
            send_notifications  => [ 'Send email notifications', 'checkbox::boolean' ],

            #XXX Once the validop object code is fixed this should be as well.
            addr_1_address1     => [ 'Primary street address' ],
            addr_1_city         => [ 'Primary city'  ],
            addr_1_state        => [ 'Primary state', 'demographics::us_state2' ],
            addr_1_post_code    => [ 'Primary zip code', 'number::integer' ],

            addr_2_address1     => [ 'Secondary street address' ],
            addr_2_city         => [ 'Secondary city'  ],
            addr_2_state        => [ 'Secondary state', 'demographics::us_state2' ],
            addr_2_post_code    => [ 'Secondary zip code', 'number::integer' ],

            addr_3_address1     => [ 'Tertiary street address' ],
            addr_3_city         => [ 'Tertiary city'  ],
            addr_3_state        => [ 'Tertiary state', 'demographics::us_state2' ],
            addr_3_post_code    => [ 'Tertiary zip code', 'number::integer' ],

            phn_1_phone_number  => [ 'Primary phone number', 'length(0,18)' ],
            phn_1_phone_type    => [ 'Primary phone number' ],
            phn_1_call_ok       => [ 'Primary call ok', 'checkbox::boolean' ],
            phn_1_message_ok    => [ 'Primary message ok', 'checkbox::boolean' ],

            phn_2_phone_number  => [ 'Secondary phone number', 'length(0,18)' ],
            phn_2_phone_type    => [ 'Secondary phone number' ],
            phn_2_call_ok       => [ 'Secondary call ok', 'checkbox::boolean' ],
            phn_2_message_ok    => [ 'Secondary message ok', 'checkbox::boolean' ],

            phn_3_phone_number  => [ 'Tertiary phone number', 'length(0,18)' ],
            phn_3_phone_type    => [ 'Tertiary phone number' ],
            phn_3_call_ok       => [ 'Tertiary call ok', 'checkbox::boolean' ],
            phn_3_message_ok    => [ 'Tertiary message ok', 'checkbox::boolean' ],
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;

    return {
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;
    my( $current ) = @_;

    $self->override_template_name( 'home' );
    return {
        op => 'edit',
        current         => $current,
        %{ $self->bad_params },
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;

    if( $self->errors ) {
        return $self->on_error;
    }
    else {
        my $rv;
        $self->db->transaction_do(sub { $rv = $self->on_success });
        return $rv;
    }
}

sub on_error {
    my $self = shift;
    $self->clone(
        client => $self->client->new({ $self->Vars }),
    )->edit;
}

sub on_success {
    my $self = shift;
    my $client = $self->client;
    $self->save_values_for_( 'addr' );
    $self->save_values_for_( 'phn' );
    $client->update({ $self->Vars });
    return $self->edit;
}

# Not provided by eleMentalClinic::CGI::Rolodex
sub save_values_for_ {
    my $self = shift;
    my ( $type ) = @_;

    $self->save_ord_( $type, $_ ) for 1 .. 3;
}

sub save_ord_ {
    my $self = shift;
    my ( $type, $ord ) = @_;
    return unless $type and $ord;

    my $obj_id = $self->Vars->{ "id_$ord" . "_$type" };
    my $values = $self->values_for_( $type, $ord ) || {};
    my $empty = $self->values_empty_for_( $type, $ord );

    # skip if we do not have an ID for the obj
    # and the fields are empty.
    return if ( $empty and !$obj_id );

    my $class = $type eq 'addr' ? 'eleMentalClinic::Contact::Address'
                                : 'eleMentalClinic::Contact::Phone';

    my $obj;
    if ( $obj_id ) {
        $obj = $class->retrieve( $obj_id );
        return $obj->delete if $empty;

        $obj->update( $values );
    }
    else {
        $obj = $class->new({
            %$values,
            client_id => $self->client->id,
            active => 1,
            primary_entry => $ord == 1 ? 1 : 0,
        });
    }
    $obj->save;
    return $obj;
}

sub values_empty_for_ {
    my $self = shift;
    my ( $type, $ord ) = @_;

    my $values = $self->values_for_( $type, $ord );

    # If phone_number is empty then all might as well be.
    return 1 if $type eq 'phn' and !$values->{ phone_number };

    for my $val ( values %$values ) {
        return if $val;
    }
    return 1;
}

sub values_for_ {
    my $self = shift;
    my ( $type, $ord ) = @_;

    my $out = {
        map {
            my $key = $_;
            $key =~ s/^$type _\d_ //x;
            $key => $self->Vars->{ $_ } # [type_ord_]key => value
        } grep { m/$type _$ord/x } #Filter to addre_ord keys
           keys %{ $self->Vars } #All keys
    };

    return $out;
}

sub bad_params {
    my $self = shift;
    return {} unless $self->errors;
    return {
        input_addrs => [ map { $self->values_for_( 'addr', $_ ) } 1 .. 3 ],
        input_phns => [ map { $self->values_for_( 'phn', $_ ) } 1 .. 3 ],
    };
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

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
