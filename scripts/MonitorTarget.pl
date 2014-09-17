#!/usr/bin/perl
use warnings;
use strict;

use lib 'lib';
use OCR::PerfectCR;
use GD;
    
my $image = GD::Image->new("snap.jpeg") or die "Can't open snap.jpeg: $!";
my $x1 = 917;
my $y1 = 261;
my $x2 = 960;
my $y2 = 273;

my $height = $y2-$y1+1;
my $width = $x2-$x1+1;

# foreach my $i (0..6) {

#   open(IMG, ">new$i.jpg") or die "Can't open output: $!";
#   binmode IMG;
#   print IMG $img->jpeg;
#   close IMG;
# }

my $img = GD::Image->new($width, $height);
$img->copy($image, 0, 0, $x1, $y1, $width, $height);
my $black = $img->colorAllocate(0,0,0);
my $white = $img->colorAllocate(255,255,255);
for my $x (0..$width-1) {
  for my $y (0..$height-1) {
    my $index = $img->getPixel($x,$y);
    my ($r,$g,$b) = $img->rgb($index);
    if($r+$g+$b>300) {
      $img->setPixel($x, $y, $black);
    }
    else {
      $img->setPixel($x, $y, $white);
    }
    #printf("%d %d %d\n", $x, $y, $r+$g+$b);
  }
}

  # open(IMG, ">new.jpg") or die "Can't open output: $!";
#   binmode IMG;
#   print IMG $img->jpeg;
#   close IMG;
  
# exit;
  
my $recognizer = OCR::PerfectCR->new;
$recognizer->load_charmap_file("charmap");
my $string = $recognizer->recognize($img);
$recognizer->save_charmap_file("charmap");
print $string,"\n";
