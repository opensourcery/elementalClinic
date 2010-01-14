use strict;
use warnings;

package eleMentalClinic::Base::Time;

use Sub::Exporter -setup => {
  exports => [qw(valid_date timestamp today)],
};

use Date::Calc ();

sub valid_date {
    my $self = shift;
    my( $date ) = @_;
    return unless $date;

    return unless my @date = split /-/ => $date;
    return unless @date == 3;
    return unless Date::Calc::check_date( @date );
    return 1;
}

sub timestamp {
    sprintf( "%4d-%02d-%02d %02d:%02d:%02d", Date::Calc::Today_and_Now );
}

sub today {
    sprintf( "%4d-%02d-%02d", Date::Calc::Today );
}

1;
