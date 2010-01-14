package eleMentalClinic::Controller::Base::Notification;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Venus::Notification

=head1 SYNOPSIS

Base Notification Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Mail::Template;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        script => 'notification.cgi',
        styles => [ 'notification' ],
    });
    $self->security( 'admin' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        save => {
            name    => [ 'Template Name', 'required', 'length(0,255)' ],
            subject => [ 'Email Subject', 'required', 'length(0,255)' ],
            message => [ 'Email Message', 'required' ],
            clinic_attach   => [ 'Clinic Attachment', 'required' ],
            subject_attach  => [ 'Subject Attachments', 'required' ],
            message_attach  => [ 'Message Attachments', 'required' ],
            -alias => 'Save',
        },
        home => {
            -alias => 'View Template',
        },
        edit => {},
        new_template => {
           -alias => 'New Template',
        }
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;

    return $self->gen_vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
    my $self = shift;

    $self->override_template_name('home');

    my $vars = $self->gen_vars;
    $vars->{ action } = 'edit';
    return $vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub normalized_save_hash {
    my $self = shift;
    my $out = {
        map {
            $_ => $self->normalized_save_value( $_ )
        } @{ eleMentalClinic::Mail::Template->fields }
    };
    delete $out->{ rec_id };
    return $out;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub normalized_save_value {
    my $self = shift;
    my ( $field ) = @_;

    my %MAP = ( Before => -1, No => 0, After => 1 );
    my $value = $self->param( $field );
    if ( $field eq 'message_attach' || $field eq 'subject_attach' ) {
        $value = $MAP{ $value };
    }
    $value = ( $value eq 'Yes' ? 1 : 0 ) if $field eq 'clinic_attach';
    return $value;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    my $current = $self->get_current_template;

    if ( $current ) {
        for my $field ( @{ $current->fields }) {
            next if $field eq 'rec_id';
            my $value = $self->normalized_save_value( $field );
            $current->$field( $value );
        }
    }
    else {
        $current = eleMentalClinic::Mail::Template->new(
            $self->normalized_save_hash
        );
    }

    $self->override_template_name('home');

    if ( $self->errors ) {
        return $self->gen_vars( current => $current, action => 'edit' );
    }

    $current->save;

    return $self->gen_vars( template_id => $current->rec_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_current_template {
    my $self = shift;
    my $params = { @_ };
    return unless my $template_id = $params->{ template_id } || $self->param( 'template_id' );
    return eleMentalClinic::Mail::Template->retrieve( $template_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new_template {
    my $self = shift;
    my $vars = $self->gen_vars( 'new' => 1 );

    $self->override_template_name('home');

    $vars->{ action } = 'edit';
    $vars->{ template_id } = undef;
    $vars->{ current } = undef;

    return $vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub gen_vars {
    my $self = shift;
    my $params = { @_ };
    my $vars = {};

    $vars->{ templates } = eleMentalClinic::Mail::Template->get_all;
    $vars->{ action } = $params->{ action } || 'display';
    my $current = $params->{ current } || $self->get_current_template( %$params );
    $vars->{ template_id } = $current->rec_id if $current and $current->rec_id; 
    # Templates should not go digging into objects internals, we will do that here.
    if ( $current and not $params->{ 'new' } ) {
        $vars = { %$vars, map { $_ => $current->$_ } @{ $current->fields }};
        delete $vars->{ rec_id }; #We do not want this
        #sub fields {[ qw/ rec_id name subject message subject_attach message_attach clinic_attach / ]}
        my %MAP = ( -1 => 'Before', 0 => 'No', 1 => 'After' );
        $vars->{ subject_attach } = $MAP{ $vars->{ subject_attach }};
        $vars->{ message_attach } = $MAP{ $vars->{ message_attach }};
        $vars->{ clinic_attach } = $vars->{ clinic_attach } ? 'Yes' : 'No';
        $vars->{ htmlmessage } = $vars->{ message };
        $vars->{ htmlmessage } =~ s/\n/<br \/>/g;
    }

    return $vars;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

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
