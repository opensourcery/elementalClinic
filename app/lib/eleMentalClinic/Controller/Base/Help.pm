# Copyright (C) 2004-2006 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
package eleMentalClinic::Controller::Base::Help;
use strict;
use warnings;

use base qw/ eleMentalClinic::CGI /;
use Data::Dumper;
use eleMentalClinic::Help;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->error( 'login' )
        unless $self->current_user->id;
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        helper => {
            name  => [ 'Controller', 'text::word', 'required' ],
        },
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub helper {
    my $self = shift;

    $self->ajax( 1 );
    my $helper = eleMentalClinic::Help->get_helper( $self->param( 'name' ));
    $self->template->process_page( 'help/content', {
        helper      => $helper,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub error {
    my $self = shift;
    my( $type ) = @_;

    print "Content-type:text/html\n\n";
    $_ = $type;
    /^login$/ and print "Please login";
    exit;
}


1;
