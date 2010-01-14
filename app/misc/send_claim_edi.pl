#! /usr/bin/perl
#
# send_claim_edi.pl - This script takes a EDI formatted text file and sends it
# to the a EDI dial up BBS for processing.  It then grabs the three return
# files automatically.  This script requires the Device::Modem
# (http://search.cpan.org/~cosimo/Device-Modem-1.47/docs/Modem.pod) Perl library
# and the UNIX package lrzsz(http://www.ohse.de/uwe/software/lrzsz.html).
# 
# Due to the Device::Modem library not waiting for output of its commands to the serial port
# to finish, this script hardcodes sleeping for certain activities so the script
# does not get ahead of itself prematurely.  At THE LEAST with all things working correctly,
# this script will take 70+ seconds to complete.  You can fiddle with the $dial_wait_seconds
# variable to make this less, but a bad phone line day might make a lower number useless as it
# might take longer to dial so the modem can renegotiate with the server for a lower BPS speed.
# Change at own risk obviously.
#
# Written By Jon Dodson (jdodson@opensourcery.com)
# 
# 11/22/2006

use strict;

use Device::Modem;

my $baud_rate = "38400";
my $serial_port = "/dev/ttyS4";
my $init_string = "AT S7=45 S0=0 L1 V1 X4 &c1 E1 Q0";

#seconds to wait while the phone dials before we do anything
my $dial_wait_seconds = 60;

my $at_eol = "\r";

my $username = "";
my $password = "";

my $modem = new Device::Modem( port => $serial_port );
my $answer;
my $ok;

#if no file passed in exit with message
if(!@ARGV[0]) {
	print "USAGE:\n";
	print "send_claim_edi.pl claim_to_send\n\n";
	exit(1);
}

my $claim_file = @ARGV[0];

if( $modem->connect( baudrate => $baud_rate, init_string => $init_string) ) {
      print "able to init modem!\n";
} else {
      print "sorry, no connection with serial port!\n";
}

$modem->echo(1);

$modem->send_init_string();

$modem->attention();          # send `attention' sequence (+++)

($ok, $answer) = $modem->dial('17012772356', $dial_wait_seconds);  # dial phone number
#$ok = $modem->dial(3);        # 1-digit parameter = dial number stored in memory 3

sleep($dial_wait_seconds);

print "dialed\n";

print "ok:" . $ok . "\n";
print "answer:" . $answer . "\n";

#login
$modem->atsend($username . $at_eol);

sleep(1);

$modem->atsend($password . $at_eol);

sleep(1);

#send the claim file
$modem->atsend("1" . $at_eol);
sleep(1);

print "Sending $claim_file\n";

`sz $claim_file <> $serial_port >&0`;

print "done sending.\n";

#exit(1);

sleep(1);

$modem->atsend($at_eol);

sleep(1);


print "Lets get the response files!\n";

#get the return files
$modem->atsend("2" . $at_eol);

sleep(1);

`rz -Z -a <> $serial_port 1>&0`;

sleep(1);

`rz -Z -a <> $serial_port 1>&0`;

sleep(1);

`rz -Z -a <> $serial_port 1>&0`;

sleep(1);

print "Disconnecting from host\n";
#disconnect
$modem->atsend("lo" . $at_eol);
