#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use autodie;
use Data::Dumper;

my ($infile, $outfile) = @ARGV;
open my $in_fh, "<", $infile;
open my $out_fh, ">", $outfile;

while (my $line = <$in_fh>) {
	chomp $line;
	my @array = split(" ",$line,2);
	say $out_fh "$array[0]|1|$array[1]|$array[0]";
}
close $in_fh;
close $out_fh;
