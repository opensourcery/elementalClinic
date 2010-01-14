package eleMentalClinic::Controller::Venus::Report;
use strict;
use warnings;
use Carp qw/ confess /;

=head1 NAME

eleMentalClinic::Controller::Venus::Report

=head1 SYNOPSIS

Report Controller for Venus theme.

=cut

use base qw/ eleMentalClinic::Controller::Base::Report /;

sub styles {
    my $self = shift;
    return $self->_mixin_gateway( $self->SUPER::styles );
}

sub report_styles {
    my $self = shift;
    return $self->_mixin_gateway( $self->SUPER::report_styles );
}

sub _mixin_gateway {
    my $self = shift;
    my @list = @_;
    my $track = eval { $self->report_track } || confess( $@ );
    return ( $track eq 'client' ) ? (@list, qw(gateway)) : @list;
}

sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );

    push( @{ $self->template->vars->{javascripts}}, 'client_filter.js', 'jquery.js'  )
        if ( $self->report_track eq 'client' );

    return $self;
}


1;
