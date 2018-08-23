#! /usr/bin/env perl 

use Log::Log4perl qw(:easy);
use Net::UPnP::ControlPoint;

Log::Log4perl::init("/home/ken/perl/log4perl.conf") or die "log4perl initialization error: $!";
my $logger = Log::Log4perl->get_logger('scripts');

my ($perc, $state);

$perc = $state = undef;

open(PSEF_PIPE,"/usr/bin/upower -i /org/freedesktop/UPower/devices/battery_BAT1 |");
while (<PSEF_PIPE>) {
	chomp;
	next unless /(percentage|state)/;
	$perc = $1 if /percentage:\s+(\d+)%/ ;
	$state = $1 if /state:\s+(\w+(?:-\w+|))/ ;
}
close(PSEF_PIPE);
$logger->debug("battery percentage is $perc and state is $state");

$logger->logdie("failed to get battery percentage") unless $perc;

if ($state =~ /discharging/ && $perc < 10) {
  wemo_on();
}

exit 0;

sub wemo_on {
    my $obj = Net::UPnP::ControlPoint->new();
    $logger->debug("searching wemo switch");
    my @dev_list = $obj->search(st =>'urn:Belkin:device:controllee:1', mx => 3);
    foreach my $device ( @dev_list ) {
	next unless $device->getfriendlyname() =~ /WeMo Switch/;

	my $service = $device->getservicebyname('urn:Belkin:service:basicevent:1');

	my %args =  ( 'BinaryState' => 1 );
	$logger->info("sending command to turn switch on");
	my $action_res = $service->postcontrol('SetBinaryState', \%args);
	$logger->logdie("failed to switch wemo on") unless ($action_res->getstatuscode() == 200);
	$logger->info("command ok");
	my $action_out_arg = $action_res->getargumentlist();
	if ($action_out_arg->{'BinaryState'} == 1) {
	    $logger->info("switch turned on");
	} else {
            $logger->info("switch already on");
	}
    }
}

