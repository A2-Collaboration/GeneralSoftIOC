#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{EPICS_BASE}/lib/perl";
use CA;
use LWP::Simple;

my $url = 'http://a2ortegapc.online.a2.kph:8080/slow_control/station/a2';
my $m = # the mapping from the silly webpage at $url to the EPICS records
  {
   'Temperature_top (C)' => 'CB:CB:MON:TEMP:Top',
   'Temperature_bot (C)' => 'CB:CB:MON:TEMP:Bot',
   'pressure_top (torr)' => 'CB:CB:MON:PRES:Top',
   'pressure_bottom (torr)' => 'CB:CB:MON:PRES:Bot'
  };

my $c; # holds the EPICS objects
foreach my $item (keys %$m) {
  my $pv = $m->{$item};
  my $chan = CA->new("$pv.A");
  $c->{$item} = $chan;
}

CA->pend_io(3);

my $data = get($url);
die "Could not fetch $url..." unless defined $data;


foreach my $line (split(/\n/, $data)) {
  my ($item, $val) = split(/=/,$line);
  if(exists $m->{$item}) {
    print $m->{$item}," => ",$val, "\n";
    $c->{$item}->put($val);
  }
}

CA->pend_io(3);
