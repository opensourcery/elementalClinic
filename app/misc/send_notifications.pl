#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Carp;
use eleMentalClinic::Client::Notification;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Send out appointment notifications.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GetOptions(
     "--help"        => \&help,
);

eleMentalClinic::Client::Notification->send_notifications;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub help {
    print STDERR <<"EOF";
Usage: $0 [options]

    This program will send out notifications to clients about upcomming
appointments or renewals. Notifications will be sent for all appointments
and renewals between now and a specified number of days. The number of days
is set in the configuration.

Options:
   -h   --help      Display this help message.
EOF
    exit( 0 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

