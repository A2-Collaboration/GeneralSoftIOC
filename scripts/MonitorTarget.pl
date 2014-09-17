#!/usr/bin/perl
use warnings;
use strict;

use LWP::Simple;
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use OCR::PerfectCR;
use GD;

my $CONFIG = [
              { 'PV' => 'TARGET:H2:Thall', 'Pos' => [917, 241, 960, 253] },
              { 'PV' => 'TARGET:H2:Pcible', 'Pos' => [917, 261, 960, 273] },
              { 'PV' => 'TARGET:H2:JPB', 'Pos' => [917, 283, 960, 295] },
              { 'PV' => 'TARGET:H2:Platine', 'Pos' => [917, 300, 960, 312] },
              { 'PV' => 'TARGET:H2:CLTS', 'Pos' => [917, 324, 960, 336] },
              { 'PV' => 'TARGET:H2:C2', 'Pos' => [917, 344, 960, 356] },
              { 'PV' => 'TARGET:H2:C3', 'Pos' => [917, 366, 960, 378] },
              { 'PV' => 'TARGET:H2:Ccible', 'Pos' => [917, 386, 960, 398] },
              { 'PV' => 'TARGET:H2:Tsi', 'Pos' => [917, 408, 960, 420] },
              { 'PV' => 'TARGET:H2:PTcomp', 'Pos' => [917, 426, 960, 438] },
              { 'PV' => 'TARGET:H2:Isovacuum', 'Pos' => [917, 451, 960, 463] },
              { 'PV' => 'TARGET:H2:Tcltsalu', 'Pos' => [917, 470, 960, 484] },
              { 'PV' => 'TARGET:H2:PTcond', 'Pos' => [917, 489, 960, 503] },
              { 'PV' => 'TARGET:H2:PTshield', 'Pos' => [917, 509, 960, 524] }
             ];

&main;

sub main {
  my $url = 'http://10.32.162.34:5080/.snap?hydrogen.vi';
  my $content = get($url);
  die "Couldn't get $url" unless defined $content;
  
  my $image = GD::Image->newFromJpegData($content) or die "Cannot create GD::Image: $!";
  my $recognizer = OCR::PerfectCR->new;
  $recognizer->load_charmap_file("$RealBin/lib/charmap");
  for my $c (@$CONFIG) {
    my $val = $recognizer->recognize(get_bw_image($image,$c->{Pos}));
    $val =~ s/\s//g;
    print $c->{PV}," => '",$val,"'\n";
  }
  $recognizer->save_charmap_file("$RealBin/lib/charmap");

}

sub get_bw_image {
  my $img = shift;
  my $pos = shift;
  my $x1 = $pos->[0];
  my $y1 = $pos->[1];
  my $x2 = $pos->[2];
  my $y2 = $pos->[3];
  my $height = $y2-$y1+1;
  my $width = $x2-$x1+1;

  my $bw = GD::Image->new($width, $height);
  $bw->copy($img, 0, 0, $x1, $y1, $width, $height);
  my $black = $bw->colorAllocate(0,0,0);
  my $white = $bw->colorAllocate(255,255,255);
  for my $x (0..$width-1) {
    for my $y (0..$height-1) {
      my ($r,$g,$b) = $bw->rgb($bw->getPixel($x,$y));
      if ($r+$g+$b>300) {
        $bw->setPixel($x, $y, $black);
      } else {
        $bw->setPixel($x, $y, $white);
      }
    }
  }

  return $bw;
}




  


