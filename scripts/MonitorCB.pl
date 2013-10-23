#!/usr/bin/perl
use strict;
use warnings;

use lib '/home/epics/epics/base/lib/perl';
use CA;
use Time::HiRes qw(usleep nanosleep);
use LWP::Simple;

my $usleep = $ARGV[0] || 1e6; # by default, check every second

my $url = 'http://a2ortegapc.online.a2.kph:8080/slow_control/station/a2';
my $m = # the mapping from the silly webpage at $url to the EPICS records
  {
   'Temperature_top (C)' => 'CB:MON:TEMP:TOP',
   'Temperature_bot (C)' => 'CB:MON:TEMP:BOT',
   'pressure_top (torr)' => 'CB:MON:PRES:TOP',
   'pressure_bottom (torr)' => 'CB:MON:PRES:BOT'
  };

my $c; # holds the EPICS objects
foreach my $item (keys %$m) {
  my $pv = $m->{$item};
  my $chan = CA->new("$pv.A");
  $c->{$item} = $chan;
}

CA->pend_io(10);

my $data = get($url);
die "Could not fetch $url..." unless defined $data;


foreach my $line (split(/\n/, $data)) {
  my ($item, $val) = split(/=/,$line);
  if(exists $m->{$item}) {
    print $m->{$item}," => ",$val, "\n";
    $c->{$item}->put($val);
  }
}

CA->pend_io(10);
