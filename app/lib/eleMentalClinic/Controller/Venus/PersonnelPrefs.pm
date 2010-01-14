package eleMentalClinic::Controller::Venus::PersonnelPrefs;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Venus::PersonnelPrefs

=head1 SYNOPSIS

PersonnelPrefs Controller for Venus theme.

=cut

use base qw/ eleMentalClinic::Controller::Base::PersonnelPrefs /;

sub available_preferences {
    {
        'active_date' => 1,
        'date_format' => 1,
    }
};

1;
