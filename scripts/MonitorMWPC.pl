#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{EPICS_BASE}/lib/perl";
use CA;
use Time::HiRes qw(usleep nanosleep);
use Net::FTP;
use Data::Dumper;
use Scalar::Util 'blessed';

my $usleep = $ARGV[0] || 1e4; # by default, retry every 10ms

my $host = 'magrathea.online.a2.kph';
my $cwd = 'data/cde_ht';
my $file = 'cde_htd_monitor.log';

my @chambers = qw(1 2); # the available chambers 1,2
my $m = # the mapping from the silly file content from ftp to the EPICS records
  {
   'Voltage (V)(actual)' => 'MWPC:HV:CH$:VOLT:READ', # $ will be replaced by Chamber number
   'Voltage (V)(settings)' => 'MWPC:HV:CH$:VOLT:SET',
   'Current (nA)(actual)' => 'MWPC:HV:CH$:CURR:READ',
   'Current (nA)(settings)' => 'MWPC:HV:CH$:CURR:SET'
  };

my $c; # holds the EPICS objects
foreach my $item (keys %$m) {
  for my $i (@chambers) {
    my $pv = $m->{$item};
    $pv =~ s/\$/$i/;
    my $chan = CA->new("$pv.A");
    $c->{$pv}->[$i-1] = $chan;
  }
}

CA->pend_io(3);

my $ftp = Net::FTP->new($host, Debug => 0)
  or die "Cannot connect to $host: $@";
$ftp->login("mwpc",'a2messung')
  or die "Cannot login ", $ftp->message;
$ftp->cwd($cwd)
  or die "Cannot change working directory ", $ftp->message;
$ftp->binary;

my $tries = 100;
my $data = undef;
while($tries>0) {
  my $fh = $ftp->retr($file);
  if(defined blessed($fh) && $fh->opened) {
    $data = do { local $/; <$fh> };
    last if defined $data && length($data)>0;
  }
  $tries--;
  print "Retrying $tries...\n";
  die "Retrying too often..." if $tries==0;
  usleep($usleep);
}
$ftp->quit;



#print $data,"\n";
#print "===========\n";

my @lines = split(/\n/,$data);
my @hdr = split(/\t/, shift @lines); # first line contains column headers
print shift @lines, "\n"; # second tells timestamp, just print it

foreach my $line (@lines) {
  my ($ch, @vals) = split(/\s+/,$line);
  # check if we're interested in that chamber
  next unless grep /^$ch$/, @chambers;
  for(my $i=1;$i<@hdr;$i++) {
    #print $hdr[$i]," ",$ch,"\n";
    my $pv = $m->{$hdr[$i]};
    my $val = $vals[$i-1]; # don't forget the first column is the ch
    $pv =~ s/\$/$ch/;
    print $pv," => ",$val,"\n";
    $c->{$pv}->[$ch-1]->put($val);
  }
}

CA->pend_io(3);
