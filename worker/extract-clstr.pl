#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use feature 'say';
use Getopt::Long;
use Pod::Usage;
use LWP::Simple;

main();

# --------------------------------------------------
sub main {
    my %args = get_args();

    if ($args{'help'} || $args{'man_page'}) {
        pod2usage({
            -exitval => 0,
            -verbose => $args{'man_page'} ? 2 : 1
        });
    }; 

	# get parameters
	my $infile = $args{'in'} or pod2usage('Missing input .clstr to be split');
	my $outfile = $args{'out'} or pod2usage('Missing outfile prefix');
	my $cutoff = $args{'cutoff'} || 3;

	# split .clstr to two files 
	my $total_cluster = `grep -c '>Cluster' $infile`;
	my $init = `grep '>Cluster' $infile | head -n1`;
	$init =~ s/^>Cluster //g;
	$init +=0;
	
	open my $out_fh, ">", $outfile;

	for (my $i=$init; $i < $init+$total_cluster; $i++) {
		my $j=$i+1;
		my $lines = `perl -ne "print if /^>Cluster $i\$/../^>Cluster $j\$/;" $infile`;
		my @clusters = split ("\n", $lines);
		if (scalar @clusters >= $cutoff+2) {
			foreach my $ele (@clusters) {
				if ($ele ne ">Cluster $j") {
					say $out_fh $ele;
				}
			}
		}
	
	}
	close $out_fh;
}
# --------------------------------------------------
sub get_args {
    my %args;
    GetOptions(
        \%args,
        'in=s',
		'threathold=s',
		'out=s',
		'help',
        'man',
    ) or pod2usage(2);

    return %args;
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

sort-cdhit-clstr.pl - a script

=head1 SYNOPSIS

  sort-cdhit-clstr.pl -i [input] -o [outfile prefix] -c [cutoff] 

Options:

  --in			input cd-hit ".clstr" file
  --out			out file prefix name
  --cutoff	cutoff (default:3) 
  --help   		Show brief help and exit
  --man    		Show full documentation
  
=head1 DESCRIPTION

This scripts extract clusters wchich ">= cutoff" from .clstr file.

=head1 SEE ALSO

perl.

=head1 AUTHOR

Xiang Liu E<lt>Xiang@email.arizona.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2018 Xiang

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
