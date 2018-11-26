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
	my $infile = $args{'in'} or pod2usage('Missing input .clstr file from CD-HIT');
	my $header_list = $args{'list'} or pod2usage('Missing id list file to be update');
	my $outfile = $args{'out'} or pod2usage('Missing output file name');
	my $size = $args{'size'} || 3;
	my $keyword = $args{'keyword'} || "major cpsid protien|portal|terminase large subunit|spike|tail|virion formation|coat";

	# creat id updata hash 
	my %header;
	open my $header_fh,"<", $header_list;
	while (my $line = <$header_fh>) {
		chomp $line;
		$line =~ s/>//;
		my ($id, $protein) = split (" ", $line, 2);
		$protein =~ s/\s\[.*\]//g;
		$header{$id}= $protein;
	}
	# match pattern

	my $hallmark = qr/$keyword/;

	# creat info hash
	open my $in_fh, "<", $infile;	
	my $total_pc = `egrep -c '>Cluster' $infile`;
	
	open my $out_fh, ">", $outfile;
	for (my $i=0; $i < $total_pc; $i++) {
		my %pcs;
		my $j=$i+1;
		my $pc_id = "Cluster_$i";
		my $lines = `perl -ne "print if /^>Cluster $i\$/../^>Cluster $j\$/;" $infile`;
		my @clusters = split ("\n", $lines);
		my $cat;
		if (scalar(@clusters) >= $size+2){
			foreach my $id (@clusters) {
				if ($id ne ">Cluster $i" and  $id ne ">Cluster $j") {
					$id =~ s/^.*\>//g;
					$id =~ s/\.\.\..*//g;
					push @{$pcs{undefind}}, $id unless (exists $header{$id});
					push @{$pcs{$header{$id}}}, $id;
				}
			}

			my @p_column;
			my @s_column;
			my $protein_name;
			foreach my $p_id (sort keys %pcs) { 
				my $count = @{$pcs{$p_id}};
				push @p_column, "$p_id:$count";
				push @s_column, @{$pcs{$p_id}};
				$protein_name.="$p_id,"; 
			}
			if ($protein_name =~ $hallmark) {
				$cat = 0;
			} else { $cat = 1; }
			
			say $out_fh $pc_id."|$cat|".join (";", @p_column)
				."|".join (" ",@s_column);
		}
	}
}

# --------------------------------------------------
sub get_args {
    my %args;
    GetOptions(
        \%args,
        'in=s',
		'keyword',
		'out=s',
		'size=s',
		'list=s',
		'help',
        'man',
    ) or pod2usage(2);

    return %args;
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

cdhit-count.pl - a script

=head1 SYNOPSIS

	make_virsorter_clusters_tab.pl -i [.clstr file] -l [fasta header list] -k [hallmark protein keywords] -o [output file name] -s [minimum seqs number a cluster have]
Options:

  --in			input cd-hit ".clstr" file
  --out			out file prefix name
  --list		file contain list of reference fasta headers which includes ACC and protein name
  --keyword		hallmark protein keywords (default: major cpsid protien|portal|terminase large subunit|spike|tail|virion formation|coat)
  --size		minimun seqence number a cluster have (default: 3) 
  --help   		Show brief help and exit
  --man    		Show full documentation
  
=head1 DESCRIPTION

This script will creat Virsorter PCs tab file.

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
