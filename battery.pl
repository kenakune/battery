#! /usr/bin/env perl 

use Log::Log4perl qw(:easy);

Log::Log4perl::init("/home/ken/perl/log4perl.conf") or die "log4perl initialization error: $!";
my $logger = Log::Log4perl->get_logger('scripts');


my ($perc, $state);

undef $perc;
undef $state;
open(PSEF_PIPE,"/usr/bin/upower -i /org/freedesktop/UPower/devices/battery_BAT1 |");
while (<PSEF_PIPE>)
{
	chomp;
	next unless /(percentage|state)/;
	$perc = $1 if /percentage:\s+(\d+)%/ ;
	$state = $1 if /state:\s+(\w+(?:-\w+))/ ;
}
close(PSEF_PIPE);
$logger->info("battery percentage is $perc and state is $state");

exit if not defined $perc;

if ($state =~ /discharging/ && $perc < 10) {
  my $cmd = `/home/ken/wemo/wemo.py -s 1`;
  $logger->warn("$cmd");
}
