# vim: ts=4 sts=4 sw=4

use strict;
use warnings;

package eleMentalClinic::DB::Object;

use base qw(eleMentalClinic::Base);
use eleMentalClinic::Base::DB -all;
use Carp ();

sub init {
    my $self = shift;
    my ( $args, $options ) = @_;
    $self->SUPER::init( @_ );

    my $class = ref($self);

    $class->build_db_accessors;

    for my $field( @{ $class->fields || [] } ) {
        $field =~ s/\w+\.//;
        $self->{ $field } = $args->{ $field };
        next if $options and $options->{ empty };
        Carp::confess "Missing required field: '$field', from ",
            join ' - ' => caller
            if not defined $self->{ $field }
            and grep /^$field$/ => @{ $class->fields_required };
    }
    return $self;
}

1;
__END__

=head1 NAME

eleMentalClinic::DB::Object - base class for persistant objects

=cut
