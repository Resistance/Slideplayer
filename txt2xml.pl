#! /usr/bin/perl

use strict;
use warnings;

print join('', map {
	chomp;
	my ($timepart, $slidepart) = split ' ';
	my ($hour, $minute, $second) = split ':', $timepart;
	my $time = $hour * 3600 + $minute * 60 + $second;
	my $slide = $slidepart + 0;
	"\t\t<slide time=\"$time\" number=\"$slide\"/>\n";
} <>);
