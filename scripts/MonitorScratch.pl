#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{EPICS_BASE}/lib/perl";
use CA;
use Linux::Inotify2;
use Data::Dumper;
use AnyEvent;

my $scratch = "$ENV{HOME}/acqu/scratch";

# create a new object
my $inotify = new Linux::Inotify2
  or die "unable to create new inotify object: $!";

my $c; # holds the EPICS objects
$c->{filesize} = CA->new("GEN:MON:Runfilesize_fast.A"); # use input A of calc record
$c->{filename} = CA->new("GEN:MON:Runfilename"); # just a stringin record...

CA->pend_io(3);


foreach my $pv (keys $c) {
  print "caput'ing to ",$c->{$pv}->name,"\n";
}
print "Watching $scratch...\n";

# add watcher for scratch
$inotify->watch ($scratch, IN_CREATE | IN_MODIFY,
                 sub {
                   my $e = shift;
                   my $fullname = $e->fullname;
                   print "Warning: $fullname is no longer mounted\n" if $e->IN_UNMOUNT;
                   print "Warning: $fullname is gone\n" if $e->IN_IGNORED;
                   print "Warning: events for $fullname have been lost\n" if $e->IN_Q_OVERFLOW;

                   my $name = $e->name; # relative to directory
		   return unless $name =~ /\.dat$/;
		   
                   if($e->IN_CREATE) {
		     $c->{filename}->put($name);
                   }
                   if($e->IN_MODIFY) {
		     my $filesize = -s $fullname; # in bytes
                     $filesize /= 2**20;
                     #print "Setting filesize to $filesize...\n";
                     $c->{filesize}->put($filesize);
                   }
                 })
  or die "unable to watch dir $scratch: $!";

my $inotify_w = AnyEvent->io (
                              fh => $inotify->fileno,
                              poll => 'r',
                              cb => sub { $inotify->poll; }
                             );

my $w = AnyEvent->timer(after => 0.5,
                        interval => 0.5,
                        cb => sub {
                          CA->pend_io(0.5);
                        });

# loop forever
AnyEvent->condvar->recv;
