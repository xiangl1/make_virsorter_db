#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use feature 'say';
use Getopt::Long;
use Pod::Usage;
use Bio::SeqIO;
use Bio::Seq::RichSeq;

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

    # get parameters (query,database,rettype, and output file)
    my $main_file = $args{'input'} or pod2usage('Missing input fasta to be filtered');
    my $out_prefix = $args{'out'} or pod2usage('Missing outfile name');
	my $type = $args{'type'} || 'off';
	my $db_header = $args{'ref_header'} || '0';
	my $seq_out = $out_prefix.".fasta";
	my $protein_out = $out_prefix. ".faa";

	# virsorter output .gb file use database id as /product name instead of protein name
	# so need to convert, use type "on" or "off" to convert or not
	# Step 1: store db haeder to a hash
	my %hash;
	if ($type eq 'on' and -e $db_header) {
		open my $header_fh, "<", $db_header;
		while (my $line = <$header_fh>) {
    		chomp $line;
    		my ($id,$protein) = split(" ", $line, 2);
   			$hash{$id}=$protein;
		}
		close $header_fh;
	}
	# Step 2: extrac
	my $seq_in = Bio::SeqIO -> new( -file => "$main_file",
								    -format => 'genbank',
								  );
	
	open my $seq_fh,">", $seq_out;
	open my $pro_fh,">",$protein_out;

	my $protein;
	while (my $seq_ob = $seq_in->next_seq) {	
		my $seq_id = $seq_ob->id();
		for my $fea_ob ($seq_ob->get_SeqFeatures) {
			if ($fea_ob->primary_tag eq "CDS") {
				my $seq = $fea_ob->spliced_seq->seq;
				for my $gene_name ($fea_ob->get_tag_values('gene')) {
					for my $product ($fea_ob->get_tag_values('product')) {
						if ($type eq 'on') {
							$product =~ s/^.*_PFAM/PFAM/;
							$protein = $hash{$product} if defined $hash{$product};
							$protein = $product unless defined $hash{$product};
						} else {
							$protein = $product;
						}

						for my $trans ( $fea_ob->get_tag_values('translation')) {
							if ($trans ne "") {
								say $pro_fh ">$seq_id"."_"."$gene_name $protein";
					   			say $pro_fh "$trans";
								say $seq_fh ">$seq_id"."_"."$gene_name $protein";
								say $seq_fh "$seq";
							}			
						}

					}

				}
			}
		}
	}
	close $seq_fh;
	close $pro_fh;

}

# --------------------------------------------------
sub get_args {
    my %args;
    GetOptions(
        \%args,
        'input=s',
		'out=s',
		'type=s',
		'ref_header=s',
		'help',
        'man',
    ) or pod2usage(2);

    return %args;
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

extract-seq.pl - a script

=head1 SYNOPSIS

  convert_gb_fasta.pl -i [.gb file] -o [output file prefix] -t ["on" or "off"]-r [original db header file]

Options:

  --input		genbank file to be convert
  --out			output file prefix
  --ref_header	original database header file contain ids and protein name (default:0)
  --help		Show brief help and exit
  --type		on: convert ids to protein name; off: not convert ids to protein name (default: off)
  --man			Show full documentation
  
=head1 DESCRIPTION

This scripts is used to convert virsorter .gb results to two gene .fasta and .faa files.

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
