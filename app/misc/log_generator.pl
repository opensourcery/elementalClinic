#!/usr/bin/perl
use strict;
use warnings;

use eleMentalClinic::Log::Access;
use eleMentalClinic::Log::Security;
use eleMentalClinic::Client;
use eleMentalClinic::Personnel;
use eleMentalClinic::Mail::Recipient;

my ( $fileA, $fileB ) = @ARGV;
print STDERR "$fileA, $fileB\n";

open( ACCESS, ">$fileA" ) || die( $! );
open( SECURITY, ">$fileB" ) || die( $! );

generate();

for my $log ( @{ eleMentalClinic::Log::Access->get_all }) {
    $log->rec_id( $log->rec_id + 1000 ) if ( $log->rec_id < 1000 );
    print ACCESS $log->rec_id . ":\n";
    for my $field ( @{ $log->fields }) {
        my $value = $log->$field || '~';
        print ACCESS "  $field: " . $value . "\n";
    }
}
close( ACCESS );

for my $log ( @{ eleMentalClinic::Log::Security->get_all }) {
    $log->rec_id( $log->rec_id + 1000 ) if ( $log->rec_id < 1000 );
    print SECURITY $log->rec_id . ":\n";
    for my $field ( @{ $log->fields }) {
        my $value = $log->$field || '~';
        print SECURITY "  $field: " . $value . "\n";
    }
}
close( SECURITY );

sub generate {
    my $clients = eleMentalClinic::Client->get_all;
    my $personnel = eleMentalClinic::Personnel->new->get_all;
    for my $day ( 5, 6, 10, 14 ) {
        for my $staff ( 1001, 1002, 1005 ) {
            for my $client ( @$clients ) { #, @$personnel ) {
                next unless grep { $_ eq $client->id } 1001, 1002, 1004;
                for ( 0 .. ( 2 + rand( 6 ))) {
                    eleMentalClinic::Log::Access->new({
                        logged       => "2008-11-$day 15:00:00",
                        from_session => ( $_ > 2 and rand( 15 ) > 9 ) ? 1 : undef,
                        object_id    => $client->id,
                        object_type  => ref $client,
                        staff_id     => $staff,
                    })->save;
                }
            }
        }
        for my $staff ( @$personnel, qw/ admini user guest fred user22 barney / ) {
            my $login = ref $staff ? $staff->login : $staff;
            eleMentalClinic::Log::Security->new({
                logged => "2008-11-$day 12:" . (10 + int(rand(49))) . ":00",
                login  => $login,
                action => 'failure',
            })->save;
            if ( ref $staff and $staff->id ) {
                eleMentalClinic::Log::Security->new({
                    logged => "2008-11-$day 14:" . (10 + int(rand(49))) . ":00",
                    login  => $login,
                    action => 'login',
                })->save;
                eleMentalClinic::Log::Security->new({
                    logged => "2008-11-$day 16:" . (10 + int(rand(49))) . ":00",
                    login  => $login,
                    action => 'logout',
                })->save;
            }
        }
    }
}
