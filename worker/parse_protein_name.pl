#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use autodie;
use Data::Dumper;

my ($infile1, $infile2, $outfile) = @ARGV;
open my $in_fh1, "<", $infile1;
open my $in_fh2, "<", $infile2;
open my $out_fh, ">", $outfile;


my %hash;
while (my $line = <$in_fh1>) {
	chomp $line;
	my ($id,$protein) = split(" ", $line, 2);
	$hash{$id}=$protein;
}
close $in_fh1;

my %protein_count;

while (my $line = <$in_fh2>) {
	chomp $line;
	$protein_count{$hash{$line}}++ if defined $hash{$line};
	$protein_count{$line}++ unless defined $hash{$line};
}

foreach my $key (keys %protein_count) {
	say $out_fh "$key\t$protein_count{$key}";
}
