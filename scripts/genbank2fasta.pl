#! /usr/bin/perl
use Bio::SeqIO;
use Getopt::Long;
use File::Basename;

my $usage = qq{
Pasrse genbank file into fastA format. There are three options. Default is to parse 
genome sequences. The others are to parse CDSs' protein or nucleotide sequences.

Usage: $0 <options> Genbankfile
       Required Options:
            -translation:   get protein sequences 
            -CDS:           get CDS nucleotide sequences
            -genome:        (default) get genome sequences

};

            #-contig_len_table   get table shows the length of contig     
my ($get_translation, $get_gene, $contig_len, $list);
GetOptions('translation'=>\$get_translation,
	   'CDS'=>\$get_gene,
	   'genome'=>\$get_genome
	  # 'contig_len_table'=>\$contig_len_table,
   #        'list=s' =>\$list
	   )||die $usage;
die $usage if (!$ARGV[0]);

if ($get_translation && $get_gene){
   undef $get_translation;
}
if (!$get_translation && !$get_gene && !$get_genome) {
   $get_genome=1;
}

my $seqout;
if ($get_genome){
   $seqout = new Bio::SeqIO('-format' => 'fasta', -fh => \*STDOUT);
}

my ($basename,$dir,$ext)= fileparse($ARGV[0], qr/\.[^.]*/);

#if ($contig_len_table){
# open (OUT, ">${basename}_contigLen.txt");
#}

my $gb_file = $ARGV[0];
my %nt_seq;
my $inseq = Bio::SeqIO->new(-format => 'genbank', -file => $gb_file);
my $n;
my $protein_accession;
while (my $seq = $inseq->next_seq){ 
	if ($get_genome){
		$seqout->write_seq($seq);
		next;
	}
	my $Locus_id = $seq->display_id();
	my $contig_seq = $seq->seq();
	my $contig_len = $seq->length;
	my ($output_aa, $output_contig, $fig_id, $product, $aa_Seq, 
		$genome_id, $project, $fig_contig_id, $contig_id);
	for my $feat_object ($seq->get_SeqFeatures){
		my ($fig_id, $product, $aa_Seq);
		#if ($feat_object->primary_tag eq "CDS" or $feat_object->primary_tag  =~ /RNA/i){
		if ($feat_object->primary_tag eq "CDS"){
			$n++;
			my $start = $feat_object->location->start;       
			my $end = $feat_object->location->end;
 			my $strand = $feat_object->location->strand;
			#if ($end > $contig_len){
			#}else{
			#}
			
			#$nt_Seq = $feat_object->seq()->seq;
			$nt_Seq = substr($contig_seq,$start-1,$end-$start+1);
			$product = join('',$feat_object->get_tag_values("product"));
			eval {$aa_Seq = join('',$feat_object->get_tag_values("translation")) } if ($feat_object->primary_tag eq "CDS");
			#$protein_accession = join ('',$feat_object->get_tag_values("protein_id"));
			$protein_accession++;
			#$output_aa .= ">protein_756067_$n\t$Locus_id\t$product\n$aa_Seq\n";
			$nt_seq{$protein_accession}=$nt_Seq;
			print ">${start}_${end}_${strand}\t$product\n$nt_Seq\n" if ($get_gene);
			if ($get_translation){
				if (!$aa_Seq){
					#my $seq_obj = $feat_object->seq();
					my $seq_obj = Bio::Seq->new(-seq => $nt_Seq, -alphabet => 'dna' );
					$aa_Seq = ($strand >0)? $seq_obj->translate()->seq:$seq_obj->revcom()->translate()->seq;
				}
				print ">${start}_${end}_${strand}\t$product\n$aa_Seq\n";
			}
		}
    #if ($feat_object->primary_tag eq "source"){
      #$genome_id = join('',$feat_object->get_tag_values("genome_id"));
      #$project = join('',$feat_object->get_tag_values("project"));
      #($contig_id) = $Locus_id =~ /(\S+)/;
      #$fig_contig_id = "$genome_id.contig.$contig_id";
      #$output_contig = ">$fig_contig_id $project\n$contig_seq\n";
    #}
	}
  #if ($contig_len_table){
    #print OUT "$contig_id\t$contig_len\n";
  #}
}#while
#close OUT;

#open (IN,$list);

#while(<IN>)
#{
    #chomp;
    #print ">protein_id $_\n$nt_seq{$_}\n"  if ($nt_seq{$_});
#}
