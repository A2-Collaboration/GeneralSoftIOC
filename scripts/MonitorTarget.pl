#!/usr/bin/perl
use warnings;
use strict;

use FindBin qw($RealBin);
use lib "$RealBin/lib";
use OCR::PerfectCR;
use GD;

my $CONFIG = [
              {
               'PV' => 'TARGET:HallTemp',
               'Pos' => [917, 241, 960, 253]
              },
              {
               'PV' => 'TARGET:H2:Pres',
               'Pos' => [917, 261, 960, 273]
              }
             ];

&main;

sub main {

  my $image = GD::Image->new("snap.jpeg") or die "Can't open snap.jpeg: $!";
  my $recognizer = OCR::PerfectCR->new;
  $recognizer->load_charmap_file("$RealBin/lib/charmap");
  for my $c (@$CONFIG) {
    my $val = $recognizer->recognize(get_bw_image($image,$c->{Pos}));
    print $c->{PV}," => ",$val,"\n";
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




  


