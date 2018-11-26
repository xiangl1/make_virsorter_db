#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use feature 'say';
use Getopt::Long;
use Pod::Usage;
use Bio::SeqIO;

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
	my $filter_file = $args{'filter'} or pod2usage('Missing extract id list');
    my $outfile = $args{'out'} or pod2usage('Missing outfile name');
	my $type = $args{'type'} or pod2usage('Missing filter type: exclude or extract');

	# creat input and output objects
	my $seq_in = Bio::SeqIO -> new( -file => "$main_file",
								    -format => 'fasta',
								  );
	my $seq_out = Bio::SeqIO -> new( -file => ">$outfile",
									 -format => 'fasta',
								   );
	# creat id list hash
	open my $filter_fh, "<", $filter_file;
	my %id_hash;
	while (my $line = <$filter_fh>) {
		chomp $line;
		$id_hash{$line}++;
	}

	# extract by id list
	if ($type eq 'extract') {
		while (my $inseq = $seq_in -> next_seq) {
			my $seq_id = $inseq -> id();
			$seq_out -> write_seq($inseq) if (exists $id_hash{$seq_id}); 
		}
	}
	
	# exclude by id list
	if ($type eq 'exclude') {
		while (my $inseq = $seq_in -> next_seq) {
			my $seq_id = $inseq -> id();
			$seq_out -> write_seq($inseq) unless (exists $id_hash{$seq_id});
		}
	}
}

# --------------------------------------------------
sub get_args {
    my %args;
    GetOptions(
        \%args,
        'input=s',
		'filter=s',
		'out=s',
		'type=s',
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

  extract-seq.pl -i [fasta file] -f [id list file] -t [extract or excluede] -o [output file] 

Options:

  --input		fasta file to be filtered
  --filter		id list want to extract or exclude
  --out			output file name
  --type		extract: choose the seq match id list 
			exclude: choose the seq not match id list
  --help		Show brief help and exit
  --man			Show full documentation
  
=head1 DESCRIPTION

This scripts is used to extract sequence by id list. The output is fasta file match the ids or not match the ids

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
