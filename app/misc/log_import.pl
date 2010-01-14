#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use eleMentalClinic::Personnel;
use eleMentalClinic::Client;
use eleMentalClinic::Log::Access;
use eleMentalClinic::Log::Security;
use eleMentalClinic::Mail::Recipient;
use eleMentalClinic::DB;
use Getopt::Long;

my $DEBUG = 0;
my $DIE = 0;
my $NOWARN = 0;

GetOptions(
     "help"     => \&help,
     "verbose+" => \$DEBUG,
     "x"        => \$DIE,
     "debug"    => sub { $DEBUG = 2 },
     "quiet"    => \$NOWARN,
);

sub help {
    print "Usage: $0 [options] /var/log/emc/emc.log /var/log/emc/emc.log.1 ...\n";
    print "Options:\n";
    print "-h       Display this help.\n";
    print "-q       Supress warnings\n";
    print "-v       Verbose\n";
    print "-d       More verbose debugging\n";
    print "-x       Die if there is an issue\n";
    print "         (normally generates a warning)\n";
    exit 0;
}

help() if ( not @ARGV );

$NOWARN = 0 if $DEBUG;

my $db = eleMentalClinic::DB->new;
print "Starting Transaction...\n";
$db->transaction_begin;

for my $log ( @ARGV ) {
    print "Log file '$log'\n";
    open( LOG, $log ) or die( $! );
    while ( my $entry = <LOG> ) {
        print '-' x 60 . "\n" . $entry if $DEBUG;
        my $data = parse( $entry );
        next unless check( $entry, $data );
        record( $data );
    }
    close( LOG );
}

print "Commiting Transaction...\n";
$db->transaction_commit;

sub parse {
    my ( $entry ) = @_;
    my $user;
    my $object;
    my $action;
    my $type;
    my @fields;

    # Clean and split the data
    chomp( $entry );
    @fields = split( m/[\[\]\s]{2,3}/, $entry );
    # Clean it up
    for my $value ( @fields ) {
        $value =~ s/[\[\]]//;
        $value =~ s/^\s|\s$//;
        $value = lc( $value );
    }

    # Get the type
    $type = $fields[2];
    $type = 'access' if $type eq 'client';

    if (( $user ) = grep { s/login failure:\s?(.*)/$1/ } @fields ) {
        $action = 'failure';
        $user ||= 'EMPTY LOGIN';
    }
    elsif (( $user ) = grep { s/user_id: (.+)/$1/ } @fields ) {
        # User might be 'NO USER'
        $user = ($user =~ m/^\d+$/) ? eleMentalClinic::Personnel->retrieve( $user )
                                    : undef;
        if (($object) = grep { s/client_id: (\d+)/$1/ } @fields ) {
            $object = eleMentalClinic::Client->retrieve( $object );
            $action = ( grep { m/session/ } @fields ) ? 'reload' : 'load';
        }
        else {
            ($action) = grep { m/login|logout/ } @fields;
            $user = "DELETED USER" unless $user and $user->id;
        }
    }
    else {
        warn( "Parsing Error on entry: $entry\n" ) unless $NOWARN;
        die if $DIE;
        return;
    }

    return {
        logged => $fields[0],
        type => $type,
        user => $user,
        action => $action,
        object => $object,
    };
}

sub check {
    my ( $entry, $data ) = @_;
    if ( $DEBUG > 1 ) {
        while ( my ( $key, $value ) = each %$data ) {
            print "$key: " if ( $key );
            print "$value" if ( $value and not ref $value );
            print $value->login if ( ref $value eq 'eleMentalClinic::Personnel' );
            print $value->name if ( ref $value eq 'eleMentalClinic::Client' );
            print "\n";
        }
        print "\n";
    };
    if ( $data->{ type } eq 'access' and not $data->{ object }->id ) {
        warn( $entry ) unless $DEBUG or $NOWARN; #Already displayed in debug mode
        warn( "Could not load object.\n" ) unless $NOWARN;
        die if $DIE;
        return 0;
    }
    return 1;
}

sub record {
    my ( $data ) = @_;
    print "recording\n" if $DEBUG;
    my $type = $data->{ type };

    my $class = 'eleMentalClinic::Log::' . ucfirst( $type );
    my $out = $class->new;
    $out->update_from_log( $data );
    return $out;
}
