package Oompa;
use strict;
use warnings;

our $VERSION = '0.11';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# contruct a new object and take all incoming arguments as
# method/value pairs
sub new {
    my $class = shift;

    my $self = bless {}, $class;
    $self->make_methods;
    while( @_ ) {
        my $method = shift;
        die qq/Method "$method" not defined for object; caller: /
            . join ':' => caller
            unless $self->can( $method );
        $self->$method( shift );
    }
    $self->init;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# blank initializer; should be overridden
sub init {
    my $self = shift;
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# makes an accessor method for each item returned by a class's
# "fields" sub
sub make_methods {
    my $self = shift;
    return unless $self->can( 'fields' );

    $self->method( $_ )
        for $self->fields;
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create an accessor method $field in the calling package
sub method {
    my $self = shift;
    my( $property ) = @_;

    my $package = ref $self;
    return if defined &{ "${ package }::$property" };
    no strict 'refs';
    *{ "${ package }::$property" } = 
        sub {
            my $self = shift;
            return $self->{ $property } unless @_;
            $self->{ $property } = shift;
            $self->{ $property };
        }
}


1;

__DATA__

=head1 NAME 

Oompa - Object-Oriented (Miniature) Perl Assistant

=head1 SYNOPSIS

    package MyCat;
    use base qw/ Oompa /;

    sub fields {
        qw/ name color temperment /;
    }

    sub init {
        my $self = shift;
        $self->SUPER::init( @_ );
        $self->color( 'black' ) if $self->name eq 'Boris'; 
        return $self;
    }

    # in a nearby piece of code ...
    use MyCat;

    my $cat = MyCat->new(
        name        => 'Boris',
        temperment  => 'evil',
    );

    print $cat->name;       # "Boris"
    print $cat->temperment; # "evil"
    print $cat->color;      # "black"

=head1 DESCRIPTION

Using Oompa as a base class for your object gives you a constructor, automatic method (setter/getter) creation, and an optional "init" subroutine.

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006. Randall Hansen. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
